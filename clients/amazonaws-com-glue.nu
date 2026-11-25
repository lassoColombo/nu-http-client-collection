# Auto-generated client for AWS Glue v2017-03-31
# Source: https://api.apis.guru/v2/specs/amazonaws.com/glue/2017-03-31/openapi.json
# Auth: --token flag or $env.AWS_GLUE_TOKEN

const CLIENT = {
  base_url: "http://glue.us-east-1.amazonaws.com"
  token_env_var: "AWS_GLUE_TOKEN"
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

def base-url-completer [] { ["http://glue.us-east-1.amazonaws.com" "http://glue.us-east-2.amazonaws.com" "http://glue.us-west-1.amazonaws.com" "http://glue.us-west-2.amazonaws.com" "http://glue.us-gov-west-1.amazonaws.com" "http://glue.us-gov-east-1.amazonaws.com" "http://glue.ca-central-1.amazonaws.com" "http://glue.eu-north-1.amazonaws.com" "http://glue.eu-west-1.amazonaws.com" "http://glue.eu-west-2.amazonaws.com" "http://glue.eu-west-3.amazonaws.com" "http://glue.eu-central-1.amazonaws.com" "http://glue.eu-south-1.amazonaws.com" "http://glue.af-south-1.amazonaws.com" "http://glue.ap-northeast-1.amazonaws.com" "http://glue.ap-northeast-2.amazonaws.com" "http://glue.ap-northeast-3.amazonaws.com" "http://glue.ap-southeast-1.amazonaws.com" "http://glue.ap-southeast-2.amazonaws.com" "http://glue.ap-east-1.amazonaws.com" "http://glue.ap-south-1.amazonaws.com" "http://glue.sa-east-1.amazonaws.com" "http://glue.me-south-1.amazonaws.com" "https://glue.us-east-1.amazonaws.com" "https://glue.us-east-2.amazonaws.com" "https://glue.us-west-1.amazonaws.com" "https://glue.us-west-2.amazonaws.com" "https://glue.us-gov-west-1.amazonaws.com" "https://glue.us-gov-east-1.amazonaws.com" "https://glue.ca-central-1.amazonaws.com" "https://glue.eu-north-1.amazonaws.com" "https://glue.eu-west-1.amazonaws.com" "https://glue.eu-west-2.amazonaws.com" "https://glue.eu-west-3.amazonaws.com" "https://glue.eu-central-1.amazonaws.com" "https://glue.eu-south-1.amazonaws.com" "https://glue.af-south-1.amazonaws.com" "https://glue.ap-northeast-1.amazonaws.com" "https://glue.ap-northeast-2.amazonaws.com" "https://glue.ap-northeast-3.amazonaws.com" "https://glue.ap-southeast-1.amazonaws.com" "https://glue.ap-southeast-2.amazonaws.com" "https://glue.ap-east-1.amazonaws.com" "https://glue.ap-south-1.amazonaws.com" "https://glue.sa-east-1.amazonaws.com" "https://glue.me-south-1.amazonaws.com" "http://glue.cn-north-1.amazonaws.com.cn" "http://glue.cn-northwest-1.amazonaws.com.cn" "https://glue.cn-north-1.amazonaws.com.cn" "https://glue.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSGlue.BatchCreatePartition"] }
def x-amz-target-completer-1 [] { ["AWSGlue.BatchDeleteConnection"] }
def x-amz-target-completer-2 [] { ["AWSGlue.BatchDeletePartition"] }
def x-amz-target-completer-3 [] { ["AWSGlue.BatchDeleteTable"] }
def x-amz-target-completer-4 [] { ["AWSGlue.BatchDeleteTableVersion"] }
def x-amz-target-completer-5 [] { ["AWSGlue.BatchGetBlueprints"] }
def x-amz-target-completer-6 [] { ["AWSGlue.BatchGetCrawlers"] }
def x-amz-target-completer-7 [] { ["AWSGlue.BatchGetCustomEntityTypes"] }
def x-amz-target-completer-8 [] { ["AWSGlue.BatchGetDataQualityResult"] }
def x-amz-target-completer-9 [] { ["AWSGlue.BatchGetDevEndpoints"] }
def x-amz-target-completer-10 [] { ["AWSGlue.BatchGetJobs"] }
def x-amz-target-completer-11 [] { ["AWSGlue.BatchGetPartition"] }
def x-amz-target-completer-12 [] { ["AWSGlue.BatchGetTriggers"] }
def x-amz-target-completer-13 [] { ["AWSGlue.BatchGetWorkflows"] }
def x-amz-target-completer-14 [] { ["AWSGlue.BatchStopJobRun"] }
def x-amz-target-completer-15 [] { ["AWSGlue.BatchUpdatePartition"] }
def x-amz-target-completer-16 [] { ["AWSGlue.CancelDataQualityRuleRecommendationRun"] }
def x-amz-target-completer-17 [] { ["AWSGlue.CancelDataQualityRulesetEvaluationRun"] }
def x-amz-target-completer-18 [] { ["AWSGlue.CancelMLTaskRun"] }
def x-amz-target-completer-19 [] { ["AWSGlue.CancelStatement"] }
def data-format-completer [] { ["AVRO" "JSON" "PROTOBUF"] }
def x-amz-target-completer-20 [] { ["AWSGlue.CheckSchemaVersionValidity"] }
def x-amz-target-completer-21 [] { ["AWSGlue.CreateBlueprint"] }
def x-amz-target-completer-22 [] { ["AWSGlue.CreateClassifier"] }
def x-amz-target-completer-23 [] { ["AWSGlue.CreateConnection"] }
def x-amz-target-completer-24 [] { ["AWSGlue.CreateCrawler"] }
def x-amz-target-completer-25 [] { ["AWSGlue.CreateCustomEntityType"] }
def x-amz-target-completer-26 [] { ["AWSGlue.CreateDataQualityRuleset"] }
def x-amz-target-completer-27 [] { ["AWSGlue.CreateDatabase"] }
def worker-type-completer [] { ["G.025X" "G.1X" "G.2X" "Standard"] }
def x-amz-target-completer-28 [] { ["AWSGlue.CreateDevEndpoint"] }
def execution-class-completer [] { ["FLEX" "STANDARD"] }
def x-amz-target-completer-29 [] { ["AWSGlue.CreateJob"] }
def x-amz-target-completer-30 [] { ["AWSGlue.CreateMLTransform"] }
def x-amz-target-completer-31 [] { ["AWSGlue.CreatePartition"] }
def x-amz-target-completer-32 [] { ["AWSGlue.CreatePartitionIndex"] }
def x-amz-target-completer-33 [] { ["AWSGlue.CreateRegistry"] }
def compatibility-completer [] { ["BACKWARD" "BACKWARD_ALL" "DISABLED" "FORWARD" "FORWARD_ALL" "FULL" "FULL_ALL" "NONE"] }
def x-amz-target-completer-34 [] { ["AWSGlue.CreateSchema"] }
def language-completer [] { ["PYTHON" "SCALA"] }
def x-amz-target-completer-35 [] { ["AWSGlue.CreateScript"] }
def x-amz-target-completer-36 [] { ["AWSGlue.CreateSecurityConfiguration"] }
def x-amz-target-completer-37 [] { ["AWSGlue.CreateSession"] }
def x-amz-target-completer-38 [] { ["AWSGlue.CreateTable"] }
def type-completer [] { ["CONDITIONAL" "EVENT" "ON_DEMAND" "SCHEDULED"] }
def x-amz-target-completer-39 [] { ["AWSGlue.CreateTrigger"] }
def x-amz-target-completer-40 [] { ["AWSGlue.CreateUserDefinedFunction"] }
def x-amz-target-completer-41 [] { ["AWSGlue.CreateWorkflow"] }
def x-amz-target-completer-42 [] { ["AWSGlue.DeleteBlueprint"] }
def x-amz-target-completer-43 [] { ["AWSGlue.DeleteClassifier"] }
def x-amz-target-completer-44 [] { ["AWSGlue.DeleteColumnStatisticsForPartition"] }
def x-amz-target-completer-45 [] { ["AWSGlue.DeleteColumnStatisticsForTable"] }
def x-amz-target-completer-46 [] { ["AWSGlue.DeleteConnection"] }
def x-amz-target-completer-47 [] { ["AWSGlue.DeleteCrawler"] }
def x-amz-target-completer-48 [] { ["AWSGlue.DeleteCustomEntityType"] }
def x-amz-target-completer-49 [] { ["AWSGlue.DeleteDataQualityRuleset"] }
def x-amz-target-completer-50 [] { ["AWSGlue.DeleteDatabase"] }
def x-amz-target-completer-51 [] { ["AWSGlue.DeleteDevEndpoint"] }
def x-amz-target-completer-52 [] { ["AWSGlue.DeleteJob"] }
def x-amz-target-completer-53 [] { ["AWSGlue.DeleteMLTransform"] }
def x-amz-target-completer-54 [] { ["AWSGlue.DeletePartition"] }
def x-amz-target-completer-55 [] { ["AWSGlue.DeletePartitionIndex"] }
def x-amz-target-completer-56 [] { ["AWSGlue.DeleteRegistry"] }
def x-amz-target-completer-57 [] { ["AWSGlue.DeleteResourcePolicy"] }
def x-amz-target-completer-58 [] { ["AWSGlue.DeleteSchema"] }
def x-amz-target-completer-59 [] { ["AWSGlue.DeleteSchemaVersions"] }
def x-amz-target-completer-60 [] { ["AWSGlue.DeleteSecurityConfiguration"] }
def x-amz-target-completer-61 [] { ["AWSGlue.DeleteSession"] }
def x-amz-target-completer-62 [] { ["AWSGlue.DeleteTable"] }
def x-amz-target-completer-63 [] { ["AWSGlue.DeleteTableVersion"] }
def x-amz-target-completer-64 [] { ["AWSGlue.DeleteTrigger"] }
def x-amz-target-completer-65 [] { ["AWSGlue.DeleteUserDefinedFunction"] }
def x-amz-target-completer-66 [] { ["AWSGlue.DeleteWorkflow"] }
def x-amz-target-completer-67 [] { ["AWSGlue.GetBlueprint"] }
def x-amz-target-completer-68 [] { ["AWSGlue.GetBlueprintRun"] }
def x-amz-target-completer-69 [] { ["AWSGlue.GetBlueprintRuns"] }
def x-amz-target-completer-70 [] { ["AWSGlue.GetCatalogImportStatus"] }
def x-amz-target-completer-71 [] { ["AWSGlue.GetClassifier"] }
def x-amz-target-completer-72 [] { ["AWSGlue.GetClassifiers"] }
def x-amz-target-completer-73 [] { ["AWSGlue.GetColumnStatisticsForPartition"] }
def x-amz-target-completer-74 [] { ["AWSGlue.GetColumnStatisticsForTable"] }
def x-amz-target-completer-75 [] { ["AWSGlue.GetConnection"] }
def x-amz-target-completer-76 [] { ["AWSGlue.GetConnections"] }
def x-amz-target-completer-77 [] { ["AWSGlue.GetCrawler"] }
def x-amz-target-completer-78 [] { ["AWSGlue.GetCrawlerMetrics"] }
def x-amz-target-completer-79 [] { ["AWSGlue.GetCrawlers"] }
def x-amz-target-completer-80 [] { ["AWSGlue.GetCustomEntityType"] }
def x-amz-target-completer-81 [] { ["AWSGlue.GetDataCatalogEncryptionSettings"] }
def x-amz-target-completer-82 [] { ["AWSGlue.GetDataQualityResult"] }
def x-amz-target-completer-83 [] { ["AWSGlue.GetDataQualityRuleRecommendationRun"] }
def x-amz-target-completer-84 [] { ["AWSGlue.GetDataQualityRuleset"] }
def x-amz-target-completer-85 [] { ["AWSGlue.GetDataQualityRulesetEvaluationRun"] }
def x-amz-target-completer-86 [] { ["AWSGlue.GetDatabase"] }
def resource-share-type-completer [] { ["ALL" "FEDERATED" "FOREIGN"] }
def x-amz-target-completer-87 [] { ["AWSGlue.GetDatabases"] }
def x-amz-target-completer-88 [] { ["AWSGlue.GetDataflowGraph"] }
def x-amz-target-completer-89 [] { ["AWSGlue.GetDevEndpoint"] }
def x-amz-target-completer-90 [] { ["AWSGlue.GetDevEndpoints"] }
def x-amz-target-completer-91 [] { ["AWSGlue.GetJob"] }
def x-amz-target-completer-92 [] { ["AWSGlue.GetJobBookmark"] }
def x-amz-target-completer-93 [] { ["AWSGlue.GetJobRun"] }
def x-amz-target-completer-94 [] { ["AWSGlue.GetJobRuns"] }
def x-amz-target-completer-95 [] { ["AWSGlue.GetJobs"] }
def x-amz-target-completer-96 [] { ["AWSGlue.GetMLTaskRun"] }
def x-amz-target-completer-97 [] { ["AWSGlue.GetMLTaskRuns"] }
def x-amz-target-completer-98 [] { ["AWSGlue.GetMLTransform"] }
def x-amz-target-completer-99 [] { ["AWSGlue.GetMLTransforms"] }
def x-amz-target-completer-100 [] { ["AWSGlue.GetMapping"] }
def x-amz-target-completer-101 [] { ["AWSGlue.GetPartition"] }
def x-amz-target-completer-102 [] { ["AWSGlue.GetPartitionIndexes"] }
def x-amz-target-completer-103 [] { ["AWSGlue.GetPartitions"] }
def x-amz-target-completer-104 [] { ["AWSGlue.GetPlan"] }
def x-amz-target-completer-105 [] { ["AWSGlue.GetRegistry"] }
def x-amz-target-completer-106 [] { ["AWSGlue.GetResourcePolicies"] }
def x-amz-target-completer-107 [] { ["AWSGlue.GetResourcePolicy"] }
def x-amz-target-completer-108 [] { ["AWSGlue.GetSchema"] }
def x-amz-target-completer-109 [] { ["AWSGlue.GetSchemaByDefinition"] }
def x-amz-target-completer-110 [] { ["AWSGlue.GetSchemaVersion"] }
def schema-diff-type-completer [] { ["SYNTAX_DIFF"] }
def x-amz-target-completer-111 [] { ["AWSGlue.GetSchemaVersionsDiff"] }
def x-amz-target-completer-112 [] { ["AWSGlue.GetSecurityConfiguration"] }
def x-amz-target-completer-113 [] { ["AWSGlue.GetSecurityConfigurations"] }
def x-amz-target-completer-114 [] { ["AWSGlue.GetSession"] }
def x-amz-target-completer-115 [] { ["AWSGlue.GetStatement"] }
def x-amz-target-completer-116 [] { ["AWSGlue.GetTable"] }
def x-amz-target-completer-117 [] { ["AWSGlue.GetTableVersion"] }
def x-amz-target-completer-118 [] { ["AWSGlue.GetTableVersions"] }
def x-amz-target-completer-119 [] { ["AWSGlue.GetTables"] }
def x-amz-target-completer-120 [] { ["AWSGlue.GetTags"] }
def x-amz-target-completer-121 [] { ["AWSGlue.GetTrigger"] }
def x-amz-target-completer-122 [] { ["AWSGlue.GetTriggers"] }
def x-amz-target-completer-123 [] { ["AWSGlue.GetUnfilteredPartitionMetadata"] }
def x-amz-target-completer-124 [] { ["AWSGlue.GetUnfilteredPartitionsMetadata"] }
def x-amz-target-completer-125 [] { ["AWSGlue.GetUnfilteredTableMetadata"] }
def x-amz-target-completer-126 [] { ["AWSGlue.GetUserDefinedFunction"] }
def x-amz-target-completer-127 [] { ["AWSGlue.GetUserDefinedFunctions"] }
def x-amz-target-completer-128 [] { ["AWSGlue.GetWorkflow"] }
def x-amz-target-completer-129 [] { ["AWSGlue.GetWorkflowRun"] }
def x-amz-target-completer-130 [] { ["AWSGlue.GetWorkflowRunProperties"] }
def x-amz-target-completer-131 [] { ["AWSGlue.GetWorkflowRuns"] }
def x-amz-target-completer-132 [] { ["AWSGlue.ImportCatalogToGlue"] }
def x-amz-target-completer-133 [] { ["AWSGlue.ListBlueprints"] }
def x-amz-target-completer-134 [] { ["AWSGlue.ListCrawlers"] }
def x-amz-target-completer-135 [] { ["AWSGlue.ListCrawls"] }
def x-amz-target-completer-136 [] { ["AWSGlue.ListCustomEntityTypes"] }
def x-amz-target-completer-137 [] { ["AWSGlue.ListDataQualityResults"] }
def x-amz-target-completer-138 [] { ["AWSGlue.ListDataQualityRuleRecommendationRuns"] }
def x-amz-target-completer-139 [] { ["AWSGlue.ListDataQualityRulesetEvaluationRuns"] }
def x-amz-target-completer-140 [] { ["AWSGlue.ListDataQualityRulesets"] }
def x-amz-target-completer-141 [] { ["AWSGlue.ListDevEndpoints"] }
def x-amz-target-completer-142 [] { ["AWSGlue.ListJobs"] }
def x-amz-target-completer-143 [] { ["AWSGlue.ListMLTransforms"] }
def x-amz-target-completer-144 [] { ["AWSGlue.ListRegistries"] }
def x-amz-target-completer-145 [] { ["AWSGlue.ListSchemaVersions"] }
def x-amz-target-completer-146 [] { ["AWSGlue.ListSchemas"] }
def x-amz-target-completer-147 [] { ["AWSGlue.ListSessions"] }
def x-amz-target-completer-148 [] { ["AWSGlue.ListStatements"] }
def x-amz-target-completer-149 [] { ["AWSGlue.ListTriggers"] }
def x-amz-target-completer-150 [] { ["AWSGlue.ListWorkflows"] }
def x-amz-target-completer-151 [] { ["AWSGlue.PutDataCatalogEncryptionSettings"] }
def policy-exists-condition-completer [] { ["MUST_EXIST" "NONE" "NOT_EXIST"] }
def enable-hybrid-completer [] { ["FALSE" "TRUE"] }
def x-amz-target-completer-152 [] { ["AWSGlue.PutResourcePolicy"] }
def x-amz-target-completer-153 [] { ["AWSGlue.PutSchemaVersionMetadata"] }
def x-amz-target-completer-154 [] { ["AWSGlue.PutWorkflowRunProperties"] }
def x-amz-target-completer-155 [] { ["AWSGlue.QuerySchemaVersionMetadata"] }
def x-amz-target-completer-156 [] { ["AWSGlue.RegisterSchemaVersion"] }
def x-amz-target-completer-157 [] { ["AWSGlue.RemoveSchemaVersionMetadata"] }
def x-amz-target-completer-158 [] { ["AWSGlue.ResetJobBookmark"] }
def x-amz-target-completer-159 [] { ["AWSGlue.ResumeWorkflowRun"] }
def x-amz-target-completer-160 [] { ["AWSGlue.RunStatement"] }
def x-amz-target-completer-161 [] { ["AWSGlue.SearchTables"] }
def x-amz-target-completer-162 [] { ["AWSGlue.StartBlueprintRun"] }
def x-amz-target-completer-163 [] { ["AWSGlue.StartCrawler"] }
def x-amz-target-completer-164 [] { ["AWSGlue.StartCrawlerSchedule"] }
def x-amz-target-completer-165 [] { ["AWSGlue.StartDataQualityRuleRecommendationRun"] }
def x-amz-target-completer-166 [] { ["AWSGlue.StartDataQualityRulesetEvaluationRun"] }
def x-amz-target-completer-167 [] { ["AWSGlue.StartExportLabelsTaskRun"] }
def x-amz-target-completer-168 [] { ["AWSGlue.StartImportLabelsTaskRun"] }
def x-amz-target-completer-169 [] { ["AWSGlue.StartJobRun"] }
def x-amz-target-completer-170 [] { ["AWSGlue.StartMLEvaluationTaskRun"] }
def x-amz-target-completer-171 [] { ["AWSGlue.StartMLLabelingSetGenerationTaskRun"] }
def x-amz-target-completer-172 [] { ["AWSGlue.StartTrigger"] }
def x-amz-target-completer-173 [] { ["AWSGlue.StartWorkflowRun"] }
def x-amz-target-completer-174 [] { ["AWSGlue.StopCrawler"] }
def x-amz-target-completer-175 [] { ["AWSGlue.StopCrawlerSchedule"] }
def x-amz-target-completer-176 [] { ["AWSGlue.StopSession"] }
def x-amz-target-completer-177 [] { ["AWSGlue.StopTrigger"] }
def x-amz-target-completer-178 [] { ["AWSGlue.StopWorkflowRun"] }
def x-amz-target-completer-179 [] { ["AWSGlue.TagResource"] }
def x-amz-target-completer-180 [] { ["AWSGlue.UntagResource"] }
def x-amz-target-completer-181 [] { ["AWSGlue.UpdateBlueprint"] }
def x-amz-target-completer-182 [] { ["AWSGlue.UpdateClassifier"] }
def x-amz-target-completer-183 [] { ["AWSGlue.UpdateColumnStatisticsForPartition"] }
def x-amz-target-completer-184 [] { ["AWSGlue.UpdateColumnStatisticsForTable"] }
def x-amz-target-completer-185 [] { ["AWSGlue.UpdateConnection"] }
def x-amz-target-completer-186 [] { ["AWSGlue.UpdateCrawler"] }
def x-amz-target-completer-187 [] { ["AWSGlue.UpdateCrawlerSchedule"] }
def x-amz-target-completer-188 [] { ["AWSGlue.UpdateDataQualityRuleset"] }
def x-amz-target-completer-189 [] { ["AWSGlue.UpdateDatabase"] }
def x-amz-target-completer-190 [] { ["AWSGlue.UpdateDevEndpoint"] }
def x-amz-target-completer-191 [] { ["AWSGlue.UpdateJob"] }
def provider-completer [] { ["AWS_CODE_COMMIT" "GITHUB"] }
def auth-strategy-completer [] { ["AWS_SECRETS_MANAGER" "PERSONAL_ACCESS_TOKEN"] }
def x-amz-target-completer-192 [] { ["AWSGlue.UpdateJobFromSourceControl"] }
def x-amz-target-completer-193 [] { ["AWSGlue.UpdateMLTransform"] }
def x-amz-target-completer-194 [] { ["AWSGlue.UpdatePartition"] }
def x-amz-target-completer-195 [] { ["AWSGlue.UpdateRegistry"] }
def x-amz-target-completer-196 [] { ["AWSGlue.UpdateSchema"] }
def x-amz-target-completer-197 [] { ["AWSGlue.UpdateSourceControlFromJob"] }
def x-amz-target-completer-198 [] { ["AWSGlue.UpdateTable"] }
def x-amz-target-completer-199 [] { ["AWSGlue.UpdateTrigger"] }
def x-amz-target-completer-200 [] { ["AWSGlue.UpdateUserDefinedFunction"] }
def x-amz-target-completer-201 [] { ["AWSGlue.UpdateWorkflow"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    batch-create-partition: "record<Errors: table<PartitionValues: list, ErrorDetail: record>>"
    batch-delete-connection: "record<Succeeded: list<string>, Errors: record>"
    batch-delete-partition: "record<Errors: table<PartitionValues: list, ErrorDetail: record>>"
    batch-delete-table: "record<Errors: table<TableName: string, ErrorDetail: record>>"
    batch-delete-table-version: "record<Errors: table<TableName: string, VersionId: string, ErrorDetail: record>>"
    batch-get-blueprints: "record<Blueprints: table<Name: string, Description: string, CreatedOn: string, LastModifiedOn: string, ParameterSpec: string, BlueprintLocation: string, BlueprintServiceLocation: string, Status: string, ErrorMessage: string, LastActiveDefinition: record>, MissingBlueprints: list<string>>"
    batch-get-crawlers: "record<Crawlers: table<Name: string, Role: string, Targets: record, DatabaseName: string, Description: string, Classifiers: list, RecrawlPolicy: record, SchemaChangePolicy: record, LineageConfiguration: record, State: string, TablePrefix: string, Schedule: record, CrawlElapsedTime: int, CreationTime: string, LastUpdated: string, LastCrawl: record, Version: int, Configuration: string, CrawlerSecurityConfiguration: string, LakeFormationConfiguration: record>, CrawlersNotFound: list<string>>"
    batch-get-custom-entity-types: "record<CustomEntityTypes: table<Name: string, RegexString: string, ContextWords: list>, CustomEntityTypesNotFound: list<string>>"
    batch-get-data-quality-result: "record<Results: table<ResultId: string, Score: float, DataSource: record, RulesetName: string, EvaluationContext: string, StartedOn: string, CompletedOn: string, JobName: string, JobRunId: string, RulesetEvaluationRunId: string, RuleResults: list>, ResultsNotFound: list<string>>"
    batch-get-dev-endpoints: "record<DevEndpoints: table<EndpointName: string, RoleArn: string, SecurityGroupIds: list, SubnetId: string, YarnEndpointAddress: string, PrivateAddress: string, ZeppelinRemoteSparkInterpreterPort: int, PublicAddress: string, Status: string, WorkerType: string, GlueVersion: string, NumberOfWorkers: int, NumberOfNodes: int, AvailabilityZone: string, VpcId: string, ExtraPythonLibsS3Path: string, ExtraJarsS3Path: string, FailureReason: string, LastUpdateStatus: string, CreatedTimestamp: string, LastModifiedTimestamp: string, PublicKey: string, PublicKeys: list, SecurityConfiguration: string, Arguments: record>, DevEndpointsNotFound: list<string>>"
    batch-get-jobs: "record<Jobs: table<Name: string, Description: string, LogUri: string, Role: string, CreatedOn: string, LastModifiedOn: string, ExecutionProperty: record, Command: record, DefaultArguments: record, NonOverridableArguments: record, Connections: record, MaxRetries: int, AllocatedCapacity: int, Timeout: int, MaxCapacity: float, WorkerType: string, NumberOfWorkers: int, SecurityConfiguration: string, NotificationProperty: record, GlueVersion: string, CodeGenConfigurationNodes: record, ExecutionClass: string, SourceControlDetails: record>, JobsNotFound: list<string>>"
    batch-get-partition: "record<Partitions: table<Values: list, DatabaseName: string, TableName: string, CreationTime: string, LastAccessTime: string, StorageDescriptor: record, Parameters: record, LastAnalyzedTime: string, CatalogId: string>, UnprocessedKeys: table<Values: list>>"
    batch-get-triggers: "record<Triggers: table<Name: string, WorkflowName: string, Id: string, Type: string, State: string, Description: string, Schedule: string, Actions: list, Predicate: record, EventBatchingCondition: record>, TriggersNotFound: list<string>>"
    batch-get-workflows: "record<Workflows: table<Name: string, Description: string, DefaultRunProperties: record, CreatedOn: string, LastModifiedOn: string, LastRun: record, Graph: record, MaxConcurrentRuns: int, BlueprintDetails: record>, MissingWorkflows: list<string>>"
    batch-stop-job-run: "record<SuccessfulSubmissions: table<JobName: string, JobRunId: string>, Errors: table<JobName: string, JobRunId: string, ErrorDetail: record>>"
    batch-update-partition: "record<Errors: table<PartitionValueList: list, ErrorDetail: record>>"
    cancel-data-quality-rule-recommendation-run: "record"
    cancel-data-quality-ruleset-evaluation-run: "record"
    cancel-ml-task-run: "record<TransformId: string, TaskRunId: string, Status: string>"
    cancel-statement: "record"
    check-schema-version-validity: "record<Valid: bool, Error: string>"
    create-blueprint: "record<Name: string>"
    create-classifier: "record"
    create-connection: "record"
    create-crawler: "record"
    create-custom-entity-type: "record<Name: string>"
    create-data-quality-ruleset: "record<Name: string>"
    create-database: "record"
    create-dev-endpoint: "record<EndpointName: string, Status: string, SecurityGroupIds: list<string>, SubnetId: string, RoleArn: string, YarnEndpointAddress: string, ZeppelinRemoteSparkInterpreterPort: int, NumberOfNodes: int, WorkerType: string, GlueVersion: string, NumberOfWorkers: int, AvailabilityZone: string, VpcId: string, ExtraPythonLibsS3Path: string, ExtraJarsS3Path: string, FailureReason: string, SecurityConfiguration: string, CreatedTimestamp: string, Arguments: record>"
    create-job: "record<Name: string>"
    create-ml-transform: "record<TransformId: string>"
    create-partition: "record"
    create-partition-index: "record"
    create-registry: "record<RegistryArn: string, RegistryName: string, Description: string, Tags: record>"
    create-schema: "record<RegistryName: string, RegistryArn: string, SchemaName: string, SchemaArn: string, Description: string, DataFormat: string, Compatibility: string, SchemaCheckpoint: int, LatestSchemaVersion: int, NextSchemaVersion: int, SchemaStatus: string, Tags: record, SchemaVersionId: string, SchemaVersionStatus: string>"
    create-script: "record<PythonScript: string, ScalaCode: string>"
    create-security-configuration: "record<Name: string, CreatedTimestamp: string>"
    create-session: "record<Session: record<Id: string, CreatedOn: string, Status: string, ErrorMessage: string, Description: string, Role: string, Command: record<Name: string, PythonVersion: string>, DefaultArguments: record, Connections: record<Connections: list>, Progress: float, MaxCapacity: float, SecurityConfiguration: string, GlueVersion: string>>"
    create-table: "record"
    create-trigger: "record<Name: string>"
    create-user-defined-function: "record"
    create-workflow: "record<Name: string>"
    delete-blueprint: "record<Name: string>"
    delete-classifier: "record"
    delete-column-statistics-for-partition: "record"
    delete-column-statistics-for-table: "record"
    delete-connection: "record"
    delete-crawler: "record"
    delete-custom-entity-type: "record<Name: string>"
    delete-data-quality-ruleset: "record"
    delete-database: "record"
    delete-dev-endpoint: "record"
    delete-job: "record<JobName: string>"
    delete-ml-transform: "record<TransformId: string>"
    delete-partition: "record"
    delete-partition-index: "record"
    delete-registry: "record<RegistryName: string, RegistryArn: string, Status: string>"
    delete-resource-policy: "record"
    delete-schema: "record<SchemaArn: string, SchemaName: string, Status: string>"
    delete-schema-versions: "record<SchemaVersionErrors: table<VersionNumber: int, ErrorDetails: record>>"
    delete-security-configuration: "record"
    delete-session: "record<Id: string>"
    delete-table: "record"
    delete-table-version: "record"
    delete-trigger: "record<Name: string>"
    delete-user-defined-function: "record"
    delete-workflow: "record<Name: string>"
    get-blueprint: "record<Blueprint: record<Name: string, Description: string, CreatedOn: string, LastModifiedOn: string, ParameterSpec: string, BlueprintLocation: string, BlueprintServiceLocation: string, Status: string, ErrorMessage: string, LastActiveDefinition: record<Description: string, LastModifiedOn: string, ParameterSpec: string, BlueprintLocation: string, BlueprintServiceLocation: string>>>"
    get-blueprint-run: "record<BlueprintRun: record<BlueprintName: string, RunId: string, WorkflowName: string, State: string, StartedOn: string, CompletedOn: string, ErrorMessage: string, RollbackErrorMessage: string, Parameters: string, RoleArn: string>>"
    get-blueprint-runs: "record<BlueprintRuns: table<BlueprintName: string, RunId: string, WorkflowName: string, State: string, StartedOn: string, CompletedOn: string, ErrorMessage: string, RollbackErrorMessage: string, Parameters: string, RoleArn: string>, NextToken: string>"
    get-catalog-import-status: "record<ImportStatus: record<ImportCompleted: bool, ImportTime: string, ImportedBy: string>>"
    get-classifier: "record<Classifier: record<GrokClassifier: record<Name: string, Classification: string, CreationTime: string, LastUpdated: string, Version: int, GrokPattern: string, CustomPatterns: string>, XMLClassifier: record<Name: string, Classification: string, CreationTime: string, LastUpdated: string, Version: int, RowTag: string>, JsonClassifier: record<Name: string, CreationTime: string, LastUpdated: string, Version: int, JsonPath: string>, CsvClassifier: record<Name: string, CreationTime: string, LastUpdated: string, Version: int, Delimiter: string, QuoteSymbol: string, ContainsHeader: string, Header: list, DisableValueTrimming: bool, AllowSingleColumn: bool, CustomDatatypeConfigured: bool, CustomDatatypes: list>>>"
    get-classifiers: "record<Classifiers: table<GrokClassifier: record, XMLClassifier: record, JsonClassifier: record, CsvClassifier: record>, NextToken: string>"
    get-column-statistics-for-partition: "record<ColumnStatisticsList: table<ColumnName: string, ColumnType: string, AnalyzedTime: string, StatisticsData: record>, Errors: table<ColumnName: string, Error: record>>"
    get-column-statistics-for-table: "record<ColumnStatisticsList: table<ColumnName: string, ColumnType: string, AnalyzedTime: string, StatisticsData: record>, Errors: table<ColumnName: string, Error: record>>"
    get-connection: "record<Connection: record<Name: string, Description: string, ConnectionType: string, MatchCriteria: list<string>, ConnectionProperties: record, PhysicalConnectionRequirements: record<SubnetId: string, SecurityGroupIdList: list, AvailabilityZone: string>, CreationTime: string, LastUpdatedTime: string, LastUpdatedBy: string>>"
    get-connections: "record<ConnectionList: table<Name: string, Description: string, ConnectionType: string, MatchCriteria: list, ConnectionProperties: record, PhysicalConnectionRequirements: record, CreationTime: string, LastUpdatedTime: string, LastUpdatedBy: string>, NextToken: string>"
    get-crawler: "record<Crawler: record<Name: string, Role: string, Targets: record<S3Targets: list, JdbcTargets: list, MongoDBTargets: list, DynamoDBTargets: list, CatalogTargets: list, DeltaTargets: list>, DatabaseName: string, Description: string, Classifiers: list<string>, RecrawlPolicy: record<RecrawlBehavior: string>, SchemaChangePolicy: record<UpdateBehavior: string, DeleteBehavior: string>, LineageConfiguration: record<CrawlerLineageSettings: string>, State: string, TablePrefix: string, Schedule: record<ScheduleExpression: string, State: string>, CrawlElapsedTime: int, CreationTime: string, LastUpdated: string, LastCrawl: record<Status: string, ErrorMessage: string, LogGroup: string, LogStream: string, MessagePrefix: string, StartTime: string>, Version: int, Configuration: string, CrawlerSecurityConfiguration: string, LakeFormationConfiguration: record<UseLakeFormationCredentials: bool, AccountId: string>>>"
    get-crawler-metrics: "record<CrawlerMetricsList: table<CrawlerName: string, TimeLeftSeconds: float, StillEstimating: bool, LastRuntimeSeconds: float, MedianRuntimeSeconds: float, TablesCreated: int, TablesUpdated: int, TablesDeleted: int>, NextToken: string>"
    get-crawlers: "record<Crawlers: table<Name: string, Role: string, Targets: record, DatabaseName: string, Description: string, Classifiers: list, RecrawlPolicy: record, SchemaChangePolicy: record, LineageConfiguration: record, State: string, TablePrefix: string, Schedule: record, CrawlElapsedTime: int, CreationTime: string, LastUpdated: string, LastCrawl: record, Version: int, Configuration: string, CrawlerSecurityConfiguration: string, LakeFormationConfiguration: record>, NextToken: string>"
    get-custom-entity-type: "record<Name: string, RegexString: string, ContextWords: list<string>>"
    get-data-catalog-encryption-settings: "record<DataCatalogEncryptionSettings: record<EncryptionAtRest: record<CatalogEncryptionMode: string, SseAwsKmsKeyId: string>, ConnectionPasswordEncryption: record<ReturnConnectionPasswordEncrypted: bool, AwsKmsKeyId: string>>>"
    get-data-quality-result: "record<ResultId: string, Score: float, DataSource: record<GlueTable: record<DatabaseName: string, TableName: string, CatalogId: string, ConnectionName: string, AdditionalOptions: record>>, RulesetName: string, EvaluationContext: string, StartedOn: string, CompletedOn: string, JobName: string, JobRunId: string, RulesetEvaluationRunId: string, RuleResults: table<Name: string, Description: string, EvaluationMessage: string, Result: string>>"
    get-data-quality-rule-recommendation-run: "record<RunId: string, DataSource: record<GlueTable: record<DatabaseName: string, TableName: string, CatalogId: string, ConnectionName: string, AdditionalOptions: record>>, Role: string, NumberOfWorkers: int, Timeout: int, Status: string, ErrorString: string, StartedOn: string, LastModifiedOn: string, CompletedOn: string, ExecutionTime: int, RecommendedRuleset: string, CreatedRulesetName: string>"
    get-data-quality-ruleset: "record<Name: string, Description: string, Ruleset: string, TargetTable: record<TableName: string, DatabaseName: string>, CreatedOn: string, LastModifiedOn: string, RecommendationRunId: string>"
    get-data-quality-ruleset-evaluation-run: "record<RunId: string, DataSource: record<GlueTable: record<DatabaseName: string, TableName: string, CatalogId: string, ConnectionName: string, AdditionalOptions: record>>, Role: string, NumberOfWorkers: int, Timeout: int, AdditionalRunOptions: record<CloudWatchMetricsEnabled: bool, ResultsS3Prefix: string>, Status: string, ErrorString: string, StartedOn: string, LastModifiedOn: string, CompletedOn: string, ExecutionTime: int, RulesetNames: list<string>, ResultIds: list<string>>"
    get-database: "record<Database: record<Name: string, Description: string, LocationUri: string, Parameters: record, CreateTime: string, CreateTableDefaultPermissions: list<record>, TargetDatabase: record<CatalogId: string, DatabaseName: string>, CatalogId: string, FederatedDatabase: record<Identifier: string, ConnectionName: string>>>"
    get-databases: "record<DatabaseList: table<Name: string, Description: string, LocationUri: string, Parameters: record, CreateTime: string, CreateTableDefaultPermissions: list, TargetDatabase: record, CatalogId: string, FederatedDatabase: record>, NextToken: string>"
    get-dataflow-graph: "record<DagNodes: table<Id: string, NodeType: string, Args: list, LineNumber: int>, DagEdges: table<Source: string, Target: string, TargetParameter: string>>"
    get-dev-endpoint: "record<DevEndpoint: record<EndpointName: string, RoleArn: string, SecurityGroupIds: list<string>, SubnetId: string, YarnEndpointAddress: string, PrivateAddress: string, ZeppelinRemoteSparkInterpreterPort: int, PublicAddress: string, Status: string, WorkerType: string, GlueVersion: string, NumberOfWorkers: int, NumberOfNodes: int, AvailabilityZone: string, VpcId: string, ExtraPythonLibsS3Path: string, ExtraJarsS3Path: string, FailureReason: string, LastUpdateStatus: string, CreatedTimestamp: string, LastModifiedTimestamp: string, PublicKey: string, PublicKeys: list<string>, SecurityConfiguration: string, Arguments: record>>"
    get-dev-endpoints: "record<DevEndpoints: table<EndpointName: string, RoleArn: string, SecurityGroupIds: list, SubnetId: string, YarnEndpointAddress: string, PrivateAddress: string, ZeppelinRemoteSparkInterpreterPort: int, PublicAddress: string, Status: string, WorkerType: string, GlueVersion: string, NumberOfWorkers: int, NumberOfNodes: int, AvailabilityZone: string, VpcId: string, ExtraPythonLibsS3Path: string, ExtraJarsS3Path: string, FailureReason: string, LastUpdateStatus: string, CreatedTimestamp: string, LastModifiedTimestamp: string, PublicKey: string, PublicKeys: list, SecurityConfiguration: string, Arguments: record>, NextToken: string>"
    get-job: "record<Job: record<Name: string, Description: string, LogUri: string, Role: string, CreatedOn: string, LastModifiedOn: string, ExecutionProperty: record<MaxConcurrentRuns: int>, Command: record<Name: string, ScriptLocation: string, PythonVersion: string>, DefaultArguments: record, NonOverridableArguments: record, Connections: record<Connections: list>, MaxRetries: int, AllocatedCapacity: int, Timeout: int, MaxCapacity: float, WorkerType: string, NumberOfWorkers: int, SecurityConfiguration: string, NotificationProperty: record<NotifyDelayAfter: int>, GlueVersion: string, CodeGenConfigurationNodes: record, ExecutionClass: string, SourceControlDetails: record<Provider: string, Repository: string, Owner: string, Branch: string, Folder: string, LastCommitId: string, AuthStrategy: string, AuthToken: string>>>"
    get-job-bookmark: "record<JobBookmarkEntry: record<JobName: string, Version: int, Run: int, Attempt: int, PreviousRunId: string, RunId: string, JobBookmark: string>>"
    get-job-run: "record<JobRun: record<Id: string, Attempt: int, PreviousRunId: string, TriggerName: string, JobName: string, StartedOn: string, LastModifiedOn: string, CompletedOn: string, JobRunState: string, Arguments: record, ErrorMessage: string, PredecessorRuns: list<record>, AllocatedCapacity: int, ExecutionTime: int, Timeout: int, MaxCapacity: float, WorkerType: string, NumberOfWorkers: int, SecurityConfiguration: string, LogGroupName: string, NotificationProperty: record<NotifyDelayAfter: int>, GlueVersion: string, DPUSeconds: float, ExecutionClass: string>>"
    get-job-runs: "record<JobRuns: table<Id: string, Attempt: int, PreviousRunId: string, TriggerName: string, JobName: string, StartedOn: string, LastModifiedOn: string, CompletedOn: string, JobRunState: string, Arguments: record, ErrorMessage: string, PredecessorRuns: list, AllocatedCapacity: int, ExecutionTime: int, Timeout: int, MaxCapacity: float, WorkerType: string, NumberOfWorkers: int, SecurityConfiguration: string, LogGroupName: string, NotificationProperty: record, GlueVersion: string, DPUSeconds: float, ExecutionClass: string>, NextToken: string>"
    get-jobs: "record<Jobs: table<Name: string, Description: string, LogUri: string, Role: string, CreatedOn: string, LastModifiedOn: string, ExecutionProperty: record, Command: record, DefaultArguments: record, NonOverridableArguments: record, Connections: record, MaxRetries: int, AllocatedCapacity: int, Timeout: int, MaxCapacity: float, WorkerType: string, NumberOfWorkers: int, SecurityConfiguration: string, NotificationProperty: record, GlueVersion: string, CodeGenConfigurationNodes: record, ExecutionClass: string, SourceControlDetails: record>, NextToken: string>"
    get-ml-task-run: "record<TransformId: string, TaskRunId: string, Status: string, LogGroupName: string, Properties: record<TaskType: string, ImportLabelsTaskRunProperties: record<InputS3Path: string, Replace: bool>, ExportLabelsTaskRunProperties: record<OutputS3Path: string>, LabelingSetGenerationTaskRunProperties: record<OutputS3Path: string>, FindMatchesTaskRunProperties: record<JobId: string, JobName: string, JobRunId: string>>, ErrorString: string, StartedOn: string, LastModifiedOn: string, CompletedOn: string, ExecutionTime: int>"
    get-ml-task-runs: "record<TaskRuns: table<TransformId: string, TaskRunId: string, Status: string, LogGroupName: string, Properties: record, ErrorString: string, StartedOn: string, LastModifiedOn: string, CompletedOn: string, ExecutionTime: int>, NextToken: string>"
    get-ml-transform: "record<TransformId: string, Name: string, Description: string, Status: string, CreatedOn: string, LastModifiedOn: string, InputRecordTables: table<DatabaseName: string, TableName: string, CatalogId: string, ConnectionName: string, AdditionalOptions: record>, Parameters: record<TransformType: string, FindMatchesParameters: record<PrimaryKeyColumnName: string, PrecisionRecallTradeoff: float, AccuracyCostTradeoff: float, EnforceProvidedLabels: bool>>, EvaluationMetrics: record<TransformType: string, FindMatchesMetrics: record<AreaUnderPRCurve: float, Precision: float, Recall: float, F1: float, ConfusionMatrix: record, ColumnImportances: list>>, LabelCount: int, Schema: table<Name: string, DataType: string>, Role: string, GlueVersion: string, MaxCapacity: float, WorkerType: string, NumberOfWorkers: int, Timeout: int, MaxRetries: int, TransformEncryption: record<MlUserDataEncryption: record<MlUserDataEncryptionMode: string, KmsKeyId: string>, TaskRunSecurityConfigurationName: string>>"
    get-ml-transforms: "record<Transforms: table<TransformId: string, Name: string, Description: string, Status: string, CreatedOn: string, LastModifiedOn: string, InputRecordTables: list, Parameters: record, EvaluationMetrics: record, LabelCount: int, Schema: list, Role: string, GlueVersion: string, MaxCapacity: float, WorkerType: string, NumberOfWorkers: int, Timeout: int, MaxRetries: int, TransformEncryption: record>, NextToken: string>"
    get-mapping: "record<Mapping: table<SourceTable: string, SourcePath: string, SourceType: string, TargetTable: string, TargetPath: string, TargetType: string>>"
    get-partition: "record<Partition: record<Values: list<string>, DatabaseName: string, TableName: string, CreationTime: string, LastAccessTime: string, StorageDescriptor: record<Columns: list, Location: string, AdditionalLocations: list, InputFormat: string, OutputFormat: string, Compressed: bool, NumberOfBuckets: int, SerdeInfo: record, BucketColumns: list, SortColumns: list, Parameters: record, SkewedInfo: record, StoredAsSubDirectories: bool, SchemaReference: record>, Parameters: record, LastAnalyzedTime: string, CatalogId: string>>"
    get-partition-indexes: "record<PartitionIndexDescriptorList: table<IndexName: string, Keys: list, IndexStatus: string, BackfillErrors: list>, NextToken: string>"
    get-partitions: "record<Partitions: table<Values: list, DatabaseName: string, TableName: string, CreationTime: string, LastAccessTime: string, StorageDescriptor: record, Parameters: record, LastAnalyzedTime: string, CatalogId: string>, NextToken: string>"
    get-plan: "record<PythonScript: string, ScalaCode: string>"
    get-registry: "record<RegistryName: string, RegistryArn: string, Description: string, Status: string, CreatedTime: string, UpdatedTime: string>"
    get-resource-policies: "record<GetResourcePoliciesResponseList: table<PolicyInJson: string, PolicyHash: string, CreateTime: string, UpdateTime: string>, NextToken: string>"
    get-resource-policy: "record<PolicyInJson: string, PolicyHash: string, CreateTime: string, UpdateTime: string>"
    get-schema: "record<RegistryName: string, RegistryArn: string, SchemaName: string, SchemaArn: string, Description: string, DataFormat: string, Compatibility: string, SchemaCheckpoint: int, LatestSchemaVersion: int, NextSchemaVersion: int, SchemaStatus: string, CreatedTime: string, UpdatedTime: string>"
    get-schema-by-definition: "record<SchemaVersionId: string, SchemaArn: string, DataFormat: string, Status: string, CreatedTime: string>"
    get-schema-version: "record<SchemaVersionId: string, SchemaDefinition: string, DataFormat: string, SchemaArn: string, VersionNumber: int, Status: string, CreatedTime: string>"
    get-schema-versions-diff: "record<Diff: string>"
    get-security-configuration: "record<SecurityConfiguration: record<Name: string, CreatedTimeStamp: string, EncryptionConfiguration: record<S3Encryption: list, CloudWatchEncryption: record, JobBookmarksEncryption: record>>>"
    get-security-configurations: "record<SecurityConfigurations: table<Name: string, CreatedTimeStamp: string, EncryptionConfiguration: record>, NextToken: string>"
    get-session: "record<Session: record<Id: string, CreatedOn: string, Status: string, ErrorMessage: string, Description: string, Role: string, Command: record<Name: string, PythonVersion: string>, DefaultArguments: record, Connections: record<Connections: list>, Progress: float, MaxCapacity: float, SecurityConfiguration: string, GlueVersion: string>>"
    get-statement: "record<Statement: record<Id: int, Code: string, State: string, Output: record<Data: record, ExecutionCount: int, Status: string, ErrorName: string, ErrorValue: string, Traceback: list>, Progress: float, StartedOn: int, CompletedOn: int>>"
    get-table: "record<Table: record<Name: string, DatabaseName: string, Description: string, Owner: string, CreateTime: string, UpdateTime: string, LastAccessTime: string, LastAnalyzedTime: string, Retention: int, StorageDescriptor: record<Columns: list, Location: string, AdditionalLocations: list, InputFormat: string, OutputFormat: string, Compressed: bool, NumberOfBuckets: int, SerdeInfo: record, BucketColumns: list, SortColumns: list, Parameters: record, SkewedInfo: record, StoredAsSubDirectories: bool, SchemaReference: record>, PartitionKeys: list<record>, ViewOriginalText: string, ViewExpandedText: string, TableType: string, Parameters: record, CreatedBy: string, IsRegisteredWithLakeFormation: bool, TargetTable: record<CatalogId: string, DatabaseName: string, Name: string>, CatalogId: string, VersionId: string, FederatedTable: record<Identifier: string, DatabaseIdentifier: string, ConnectionName: string>>>"
    get-table-version: "record<TableVersion: record<Table: record<Name: string, DatabaseName: string, Description: string, Owner: string, CreateTime: string, UpdateTime: string, LastAccessTime: string, LastAnalyzedTime: string, Retention: int, StorageDescriptor: record, PartitionKeys: list, ViewOriginalText: string, ViewExpandedText: string, TableType: string, Parameters: record, CreatedBy: string, IsRegisteredWithLakeFormation: bool, TargetTable: record, CatalogId: string, VersionId: string, FederatedTable: record>, VersionId: string>>"
    get-table-versions: "record<TableVersions: table<Table: record, VersionId: string>, NextToken: string>"
    get-tables: "record<TableList: table<Name: string, DatabaseName: string, Description: string, Owner: string, CreateTime: string, UpdateTime: string, LastAccessTime: string, LastAnalyzedTime: string, Retention: int, StorageDescriptor: record, PartitionKeys: list, ViewOriginalText: string, ViewExpandedText: string, TableType: string, Parameters: record, CreatedBy: string, IsRegisteredWithLakeFormation: bool, TargetTable: record, CatalogId: string, VersionId: string, FederatedTable: record>, NextToken: string>"
    get-tags: "record<Tags: record>"
    get-trigger: "record<Trigger: record<Name: string, WorkflowName: string, Id: string, Type: string, State: string, Description: string, Schedule: string, Actions: list<record>, Predicate: record<Logical: string, Conditions: list>, EventBatchingCondition: record<BatchSize: int, BatchWindow: int>>>"
    get-triggers: "record<Triggers: table<Name: string, WorkflowName: string, Id: string, Type: string, State: string, Description: string, Schedule: string, Actions: list, Predicate: record, EventBatchingCondition: record>, NextToken: string>"
    get-unfiltered-partition-metadata: "record<Partition: record<Values: list<string>, DatabaseName: string, TableName: string, CreationTime: string, LastAccessTime: string, StorageDescriptor: record<Columns: list, Location: string, AdditionalLocations: list, InputFormat: string, OutputFormat: string, Compressed: bool, NumberOfBuckets: int, SerdeInfo: record, BucketColumns: list, SortColumns: list, Parameters: record, SkewedInfo: record, StoredAsSubDirectories: bool, SchemaReference: record>, Parameters: record, LastAnalyzedTime: string, CatalogId: string>, AuthorizedColumns: list<string>, IsRegisteredWithLakeFormation: bool>"
    get-unfiltered-partitions-metadata: "record<UnfilteredPartitions: table<Partition: record, AuthorizedColumns: list, IsRegisteredWithLakeFormation: bool>, NextToken: string>"
    get-unfiltered-table-metadata: "record<Table: record<Name: string, DatabaseName: string, Description: string, Owner: string, CreateTime: string, UpdateTime: string, LastAccessTime: string, LastAnalyzedTime: string, Retention: int, StorageDescriptor: record<Columns: list, Location: string, AdditionalLocations: list, InputFormat: string, OutputFormat: string, Compressed: bool, NumberOfBuckets: int, SerdeInfo: record, BucketColumns: list, SortColumns: list, Parameters: record, SkewedInfo: record, StoredAsSubDirectories: bool, SchemaReference: record>, PartitionKeys: list<record>, ViewOriginalText: string, ViewExpandedText: string, TableType: string, Parameters: record, CreatedBy: string, IsRegisteredWithLakeFormation: bool, TargetTable: record<CatalogId: string, DatabaseName: string, Name: string>, CatalogId: string, VersionId: string, FederatedTable: record<Identifier: string, DatabaseIdentifier: string, ConnectionName: string>>, AuthorizedColumns: list<string>, IsRegisteredWithLakeFormation: bool, CellFilters: table<ColumnName: string, RowFilterExpression: string>>"
    get-user-defined-function: "record<UserDefinedFunction: record<FunctionName: string, DatabaseName: string, ClassName: string, OwnerName: string, OwnerType: string, CreateTime: string, ResourceUris: list<record>, CatalogId: string>>"
    get-user-defined-functions: "record<UserDefinedFunctions: table<FunctionName: string, DatabaseName: string, ClassName: string, OwnerName: string, OwnerType: string, CreateTime: string, ResourceUris: list, CatalogId: string>, NextToken: string>"
    get-workflow: "record<Workflow: record<Name: string, Description: string, DefaultRunProperties: record, CreatedOn: string, LastModifiedOn: string, LastRun: record<Name: string, WorkflowRunId: string, PreviousRunId: string, WorkflowRunProperties: record, StartedOn: string, CompletedOn: string, Status: string, ErrorMessage: string, Statistics: record, Graph: record, StartingEventBatchCondition: record>, Graph: record<Nodes: list, Edges: list>, MaxConcurrentRuns: int, BlueprintDetails: record<BlueprintName: string, RunId: string>>>"
    get-workflow-run: "record<Run: record<Name: string, WorkflowRunId: string, PreviousRunId: string, WorkflowRunProperties: record, StartedOn: string, CompletedOn: string, Status: string, ErrorMessage: string, Statistics: record<TotalActions: int, TimeoutActions: int, FailedActions: int, StoppedActions: int, SucceededActions: int, RunningActions: int, ErroredActions: int, WaitingActions: int>, Graph: record<Nodes: list, Edges: list>, StartingEventBatchCondition: record<BatchSize: int, BatchWindow: int>>>"
    get-workflow-run-properties: "record<RunProperties: record>"
    get-workflow-runs: "record<Runs: table<Name: string, WorkflowRunId: string, PreviousRunId: string, WorkflowRunProperties: record, StartedOn: string, CompletedOn: string, Status: string, ErrorMessage: string, Statistics: record, Graph: record, StartingEventBatchCondition: record>, NextToken: string>"
    import-catalog-to-glue: "record"
    list-blueprints: "record<Blueprints: list<string>, NextToken: string>"
    list-crawlers: "record<CrawlerNames: list<string>, NextToken: string>"
    list-crawls: "record<Crawls: table<CrawlId: string, State: string, StartTime: string, EndTime: string, Summary: string, ErrorMessage: string, LogGroup: string, LogStream: string, MessagePrefix: string, DPUHour: float>, NextToken: string>"
    list-custom-entity-types: "record<CustomEntityTypes: table<Name: string, RegexString: string, ContextWords: list>, NextToken: string>"
    list-data-quality-results: "record<Results: table<ResultId: string, DataSource: record, JobName: string, JobRunId: string, StartedOn: string>, NextToken: string>"
    list-data-quality-rule-recommendation-runs: "record<Runs: table<RunId: string, Status: string, StartedOn: string, DataSource: record>, NextToken: string>"
    list-data-quality-ruleset-evaluation-runs: "record<Runs: table<RunId: string, Status: string, StartedOn: string, DataSource: record>, NextToken: string>"
    list-data-quality-rulesets: "record<Rulesets: table<Name: string, Description: string, CreatedOn: string, LastModifiedOn: string, TargetTable: record, RecommendationRunId: string, RuleCount: int>, NextToken: string>"
    list-dev-endpoints: "record<DevEndpointNames: list<string>, NextToken: string>"
    list-jobs: "record<JobNames: list<string>, NextToken: string>"
    list-ml-transforms: "record<TransformIds: list<string>, NextToken: string>"
    list-registries: "record<Registries: table<RegistryName: string, RegistryArn: string, Description: string, Status: string, CreatedTime: string, UpdatedTime: string>, NextToken: string>"
    list-schema-versions: "record<Schemas: table<SchemaArn: string, SchemaVersionId: string, VersionNumber: int, Status: string, CreatedTime: string>, NextToken: string>"
    list-schemas: "record<Schemas: table<RegistryName: string, SchemaName: string, SchemaArn: string, Description: string, SchemaStatus: string, CreatedTime: string, UpdatedTime: string>, NextToken: string>"
    list-sessions: "record<Ids: list<string>, Sessions: table<Id: string, CreatedOn: string, Status: string, ErrorMessage: string, Description: string, Role: string, Command: record, DefaultArguments: record, Connections: record, Progress: float, MaxCapacity: float, SecurityConfiguration: string, GlueVersion: string>, NextToken: string>"
    list-statements: "record<Statements: table<Id: int, Code: string, State: string, Output: record, Progress: float, StartedOn: int, CompletedOn: int>, NextToken: string>"
    list-triggers: "record<TriggerNames: list<string>, NextToken: string>"
    list-workflows: "record<Workflows: list<string>, NextToken: string>"
    put-data-catalog-encryption-settings: "record"
    put-resource-policy: "record<PolicyHash: string>"
    put-schema-version-metadata: "record<SchemaArn: string, SchemaName: string, RegistryName: string, LatestVersion: bool, VersionNumber: int, SchemaVersionId: string, MetadataKey: string, MetadataValue: string>"
    put-workflow-run-properties: "record"
    query-schema-version-metadata: "record<MetadataInfoMap: record, SchemaVersionId: string, NextToken: string>"
    register-schema-version: "record<SchemaVersionId: string, VersionNumber: int, Status: string>"
    remove-schema-version-metadata: "record<SchemaArn: string, SchemaName: string, RegistryName: string, LatestVersion: bool, VersionNumber: int, SchemaVersionId: string, MetadataKey: string, MetadataValue: string>"
    reset-job-bookmark: "record<JobBookmarkEntry: record<JobName: string, Version: int, Run: int, Attempt: int, PreviousRunId: string, RunId: string, JobBookmark: string>>"
    resume-workflow-run: "record<RunId: string, NodeIds: list<string>>"
    run-statement: "record<Id: int>"
    search-tables: "record<NextToken: string, TableList: table<Name: string, DatabaseName: string, Description: string, Owner: string, CreateTime: string, UpdateTime: string, LastAccessTime: string, LastAnalyzedTime: string, Retention: int, StorageDescriptor: record, PartitionKeys: list, ViewOriginalText: string, ViewExpandedText: string, TableType: string, Parameters: record, CreatedBy: string, IsRegisteredWithLakeFormation: bool, TargetTable: record, CatalogId: string, VersionId: string, FederatedTable: record>>"
    start-blueprint-run: "record<RunId: string>"
    start-crawler: "record"
    start-crawler-schedule: "record"
    start-data-quality-rule-recommendation-run: "record<RunId: string>"
    start-data-quality-ruleset-evaluation-run: "record<RunId: string>"
    start-export-labels-task-run: "record<TaskRunId: string>"
    start-import-labels-task-run: "record<TaskRunId: string>"
    start-job-run: "record<JobRunId: string>"
    start-ml-evaluation-task-run: "record<TaskRunId: string>"
    start-ml-labeling-set-generation-task-run: "record<TaskRunId: string>"
    start-trigger: "record<Name: string>"
    start-workflow-run: "record<RunId: string>"
    stop-crawler: "record"
    stop-crawler-schedule: "record"
    stop-session: "record<Id: string>"
    stop-trigger: "record<Name: string>"
    stop-workflow-run: "record"
    tag-resource: "record"
    untag-resource: "record"
    update-blueprint: "record<Name: string>"
    update-classifier: "record"
    update-column-statistics-for-partition: "record<Errors: table<ColumnStatistics: record, Error: record>>"
    update-column-statistics-for-table: "record<Errors: table<ColumnStatistics: record, Error: record>>"
    update-connection: "record"
    update-crawler: "record"
    update-crawler-schedule: "record"
    update-data-quality-ruleset: "record<Name: string, Description: string, Ruleset: string>"
    update-database: "record"
    update-dev-endpoint: "record"
    update-job: "record<JobName: string>"
    update-job-from-source-control: "record<JobName: string>"
    update-ml-transform: "record<TransformId: string>"
    update-partition: "record"
    update-registry: "record<RegistryName: string, RegistryArn: string>"
    update-schema: "record<SchemaArn: string, SchemaName: string, RegistryName: string>"
    update-source-control-from-job: "record<JobName: string>"
    update-table: "record"
    update-trigger: "record<Trigger: record<Name: string, WorkflowName: string, Id: string, Type: string, State: string, Description: string, Schedule: string, Actions: list<record>, Predicate: record<Logical: string, Conditions: list>, EventBatchingCondition: record<BatchSize: int, BatchWindow: int>>>"
    update-user-defined-function: "record"
    update-workflow: "record<Name: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["batch-create-partition" "batch-delete-connection" "batch-delete-partition" "batch-delete-table" "batch-delete-table-version" "batch-get-blueprints" "batch-get-crawlers" "batch-get-custom-entity-types" "batch-get-data-quality-result" "batch-get-dev-endpoints" "batch-get-jobs" "batch-get-partition" "batch-get-triggers" "batch-get-workflows" "batch-stop-job-run" "batch-update-partition" "cancel-data-quality-rule-recommendation-run" "cancel-data-quality-ruleset-evaluation-run" "cancel-ml-task-run" "cancel-statement" "check-schema-version-validity" "create-blueprint" "create-classifier" "create-connection" "create-crawler" "create-custom-entity-type" "create-data-quality-ruleset" "create-database" "create-dev-endpoint" "create-job" "create-ml-transform" "create-partition" "create-partition-index" "create-registry" "create-schema" "create-script" "create-security-configuration" "create-session" "create-table" "create-trigger" "create-user-defined-function" "create-workflow" "delete-blueprint" "delete-classifier" "delete-column-statistics-for-partition" "delete-column-statistics-for-table" "delete-connection" "delete-crawler" "delete-custom-entity-type" "delete-data-quality-ruleset" "delete-database" "delete-dev-endpoint" "delete-job" "delete-ml-transform" "delete-partition" "delete-partition-index" "delete-registry" "delete-resource-policy" "delete-schema" "delete-schema-versions" "delete-security-configuration" "delete-session" "delete-table" "delete-table-version" "delete-trigger" "delete-user-defined-function" "delete-workflow" "get-blueprint" "get-blueprint-run" "get-blueprint-runs" "get-catalog-import-status" "get-classifier" "get-classifiers" "get-column-statistics-for-partition" "get-column-statistics-for-table" "get-connection" "get-connections" "get-crawler" "get-crawler-metrics" "get-crawlers" "get-custom-entity-type" "get-data-catalog-encryption-settings" "get-data-quality-result" "get-data-quality-rule-recommendation-run" "get-data-quality-ruleset" "get-data-quality-ruleset-evaluation-run" "get-database" "get-databases" "get-dataflow-graph" "get-dev-endpoint" "get-dev-endpoints" "get-job" "get-job-bookmark" "get-job-run" "get-job-runs" "get-jobs" "get-ml-task-run" "get-ml-task-runs" "get-ml-transform" "get-ml-transforms" "get-mapping" "get-partition" "get-partition-indexes" "get-partitions" "get-plan" "get-registry" "get-resource-policies" "get-resource-policy" "get-schema" "get-schema-by-definition" "get-schema-version" "get-schema-versions-diff" "get-security-configuration" "get-security-configurations" "get-session" "get-statement" "get-table" "get-table-version" "get-table-versions" "get-tables" "get-tags" "get-trigger" "get-triggers" "get-unfiltered-partition-metadata" "get-unfiltered-partitions-metadata" "get-unfiltered-table-metadata" "get-user-defined-function" "get-user-defined-functions" "get-workflow" "get-workflow-run" "get-workflow-run-properties" "get-workflow-runs" "import-catalog-to-glue" "list-blueprints" "list-crawlers" "list-crawls" "list-custom-entity-types" "list-data-quality-results" "list-data-quality-rule-recommendation-runs" "list-data-quality-ruleset-evaluation-runs" "list-data-quality-rulesets" "list-dev-endpoints" "list-jobs" "list-ml-transforms" "list-registries" "list-schema-versions" "list-schemas" "list-sessions" "list-statements" "list-triggers" "list-workflows" "put-data-catalog-encryption-settings" "put-resource-policy" "put-schema-version-metadata" "put-workflow-run-properties" "query-schema-version-metadata" "register-schema-version" "remove-schema-version-metadata" "reset-job-bookmark" "resume-workflow-run" "run-statement" "search-tables" "start-blueprint-run" "start-crawler" "start-crawler-schedule" "start-data-quality-rule-recommendation-run" "start-data-quality-ruleset-evaluation-run" "start-export-labels-task-run" "start-import-labels-task-run" "start-job-run" "start-ml-evaluation-task-run" "start-ml-labeling-set-generation-task-run" "start-trigger" "start-workflow-run" "stop-crawler" "stop-crawler-schedule" "stop-session" "stop-trigger" "stop-workflow-run" "tag-resource" "untag-resource" "update-blueprint" "update-classifier" "update-column-statistics-for-partition" "update-column-statistics-for-table" "update-connection" "update-crawler" "update-crawler-schedule" "update-data-quality-ruleset" "update-database" "update-dev-endpoint" "update-job" "update-job-from-source-control" "update-ml-transform" "update-partition" "update-registry" "update-schema" "update-source-control-from-job" "update-table" "update-trigger" "update-user-defined-function" "update-workflow" "commands"] | sort) } | get name | first)
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

# Creates one or more partitions in a batch operation.
#
# POST /
# Returns: record<Errors: table<PartitionValues: list, ErrorDetail: record>>
# operationId: BatchCreatePartition
export def "batch-create-partition" [
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
  --catalog-id: string # The ID of the catalog in which the partition is to be created. Currently, this should be the Amazon Web Services account ID.
  database_name: string # The name of the metadata database in which the partition is to be created.
  table_name: string # The name of the metadata table in which the partition is to be created.
  partition_input_list: list # A list of PartitionInput structures that define the partitions to be created. — item shape: {Values?: list<string>, LastAccessTime?: string, StorageDescriptor?: record, Parameters?: record, LastAnalyzedTime?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.BatchCreatePartition"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: PartitionInputList, var: partition_input_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, partition_input_list: $partition_input_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a list of connection definitions from the Data Catalog.
#
# POST /
# Returns: record<Succeeded: list<string>, Errors: record>
# operationId: BatchDeleteConnection
export def "batch-delete-connection" [
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
  --catalog-id: string # The ID of the Data Catalog in which the connections reside. If none is provided, the Amazon Web Services account ID is used by default.
  connection_name_list: list<string> # A list of names of the connections to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.BatchDeleteConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: ConnectionNameList, var: connection_name_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, connection_name_list: $connection_name_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes one or more partitions in a batch operation.
#
# POST /
# Returns: record<Errors: table<PartitionValues: list, ErrorDetail: record>>
# operationId: BatchDeletePartition
export def "batch-delete-partition" [
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
  --catalog-id: string # The ID of the Data Catalog where the partition to be deleted resides. If none is provided, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database in which the table in question resides.
  table_name: string # The name of the table that contains the partitions to be deleted.
  partitions_to_delete: list # A list of PartitionInput structures that define the partitions to be deleted. — item shape: {Values: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.BatchDeletePartition"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: PartitionsToDelete, var: partitions_to_delete}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, partitions_to_delete: $partitions_to_delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes multiple tables at once. After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service. To ensure the immediate deletion of all related resources, before calling BatchDeleteTable, use DeleteTableVersion or BatchDeleteTableVersion, and DeletePartition or BatchDeletePartition, to delete any resources that belong to the table.
#
# POST /
# Returns: record<Errors: table<TableName: string, ErrorDetail: record>>
# operationId: BatchDeleteTable
export def "batch-delete-table" [
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
  --catalog-id: string # The ID of the Data Catalog where the table resides. If none is provided, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database in which the tables to delete reside. For Hive compatibility, this name is entirely lowercase.
  tables_to_delete: list<string> # A list of the table to delete.
  --transaction-id: string # The transaction ID at which to delete the table contents.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.BatchDeleteTable"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TablesToDelete, var: tables_to_delete}, {name: TransactionId, var: transaction_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, tables_to_delete: $tables_to_delete, transaction_id: $transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified batch of versions of a table.
#
# POST /
# Returns: record<Errors: table<TableName: string, VersionId: string, ErrorDetail: record>>
# operationId: BatchDeleteTableVersion
export def "batch-delete-table-version" [
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
  --catalog-id: string # The ID of the Data Catalog where the tables reside. If none is provided, the Amazon Web Services account ID is used by default.
  database_name: string # The database in the catalog in which the table resides. For Hive compatibility, this name is entirely lowercase.
  table_name: string # The name of the table. For Hive compatibility, this name is entirely lowercase.
  version_ids: list<string> # A list of the IDs of versions to be deleted. A VersionId is a string representation of an integer. Each version is incremented by 1.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.BatchDeleteTableVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: VersionIds, var: version_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, version_ids: $version_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a list of blueprints.
#
# POST /
# Returns: record<Blueprints: table<Name: string, Description: string, CreatedOn: string, LastModifiedOn: string, ParameterSpec: string, BlueprintLocation: string, BlueprintServiceLocation: string, Status: string, ErrorMessage: string, LastActiveDefinition: record>, MissingBlueprints: list<string>>
# operationId: BatchGetBlueprints
export def "batch-get-blueprints" [
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
  names: list<string> # A list of blueprint names.
  --include-blueprint: oneof<nothing, bool> # Specifies whether or not to include the blueprint in the response.
  --include-parameter-spec: oneof<nothing, bool> # Specifies whether or not to include the parameters, as a JSON string, for the blueprint in the response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.BatchGetBlueprints"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Names, var: names}, {name: IncludeBlueprint, var: include_blueprint}, {name: IncludeParameterSpec, var: include_parameter_spec}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, names: $names, include_blueprint: $include_blueprint, include_parameter_spec: $include_parameter_spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of resource metadata for a given list of crawler names. After calling the ListCrawlers operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
#
# POST /
# Returns: record<Crawlers: table<Name: string, Role: string, Targets: record, DatabaseName: string, Description: string, Classifiers: list, RecrawlPolicy: record, SchemaChangePolicy: record, LineageConfiguration: record, State: string, TablePrefix: string, Schedule: record, CrawlElapsedTime: int, CreationTime: string, LastUpdated: string, LastCrawl: record, Version: int, Configuration: string, CrawlerSecurityConfiguration: string, LakeFormationConfiguration: record>, CrawlersNotFound: list<string>>
# operationId: BatchGetCrawlers
export def "batch-get-crawlers" [
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
  crawler_names: list<string> # A list of crawler names, which might be the names returned from the ListCrawlers operation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.BatchGetCrawlers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CrawlerNames, var: crawler_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, crawler_names: $crawler_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details for the custom patterns specified by a list of names.
#
# POST /
# Returns: record<CustomEntityTypes: table<Name: string, RegexString: string, ContextWords: list>, CustomEntityTypesNotFound: list<string>>
# operationId: BatchGetCustomEntityTypes
export def "batch-get-custom-entity-types" [
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
  names: list<string> # A list of names of the custom patterns that you want to retrieve.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.BatchGetCustomEntityTypes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Names, var: names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, names: $names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of data quality results for the specified result IDs.
#
# POST /
# Returns: record<Results: table<ResultId: string, Score: float, DataSource: record, RulesetName: string, EvaluationContext: string, StartedOn: string, CompletedOn: string, JobName: string, JobRunId: string, RulesetEvaluationRunId: string, RuleResults: list>, ResultsNotFound: list<string>>
# operationId: BatchGetDataQualityResult
export def "batch-get-data-quality-result" [
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
  result_ids: list<string> # A list of unique result IDs for the data quality results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.BatchGetDataQualityResult"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResultIds, var: result_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, result_ids: $result_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of resource metadata for a given list of development endpoint names. After calling the ListDevEndpoints operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
#
# POST /
# Returns: record<DevEndpoints: table<EndpointName: string, RoleArn: string, SecurityGroupIds: list, SubnetId: string, YarnEndpointAddress: string, PrivateAddress: string, ZeppelinRemoteSparkInterpreterPort: int, PublicAddress: string, Status: string, WorkerType: string, GlueVersion: string, NumberOfWorkers: int, NumberOfNodes: int, AvailabilityZone: string, VpcId: string, ExtraPythonLibsS3Path: string, ExtraJarsS3Path: string, FailureReason: string, LastUpdateStatus: string, CreatedTimestamp: string, LastModifiedTimestamp: string, PublicKey: string, PublicKeys: list, SecurityConfiguration: string, Arguments: record>, DevEndpointsNotFound: list<string>>
# operationId: BatchGetDevEndpoints
export def "batch-get-dev-endpoints" [
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
  dev_endpoint_names: list<string> # The list of DevEndpoint names, which might be the names returned from the ListDevEndpoint operation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.BatchGetDevEndpoints"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DevEndpointNames, var: dev_endpoint_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dev_endpoint_names: $dev_endpoint_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of resource metadata for a given list of job names. After calling the ListJobs operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
#
# POST /
# Returns: record<Jobs: table<Name: string, Description: string, LogUri: string, Role: string, CreatedOn: string, LastModifiedOn: string, ExecutionProperty: record, Command: record, DefaultArguments: record, NonOverridableArguments: record, Connections: record, MaxRetries: int, AllocatedCapacity: int, Timeout: int, MaxCapacity: float, WorkerType: string, NumberOfWorkers: int, SecurityConfiguration: string, NotificationProperty: record, GlueVersion: string, CodeGenConfigurationNodes: record, ExecutionClass: string, SourceControlDetails: record>, JobsNotFound: list<string>>
# operationId: BatchGetJobs
export def "batch-get-jobs" [
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
  job_names: list<string> # A list of job names, which might be the names returned from the ListJobs operation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.BatchGetJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobNames, var: job_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_names: $job_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves partitions in a batch request.
#
# POST /
# Returns: record<Partitions: table<Values: list, DatabaseName: string, TableName: string, CreationTime: string, LastAccessTime: string, StorageDescriptor: record, Parameters: record, LastAnalyzedTime: string, CatalogId: string>, UnprocessedKeys: table<Values: list>>
# operationId: BatchGetPartition
export def "batch-get-partition" [
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
  --catalog-id: string # The ID of the Data Catalog where the partitions in question reside. If none is supplied, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database where the partitions reside.
  table_name: string # The name of the partitions' table.
  partitions_to_get: list # A list of partition values identifying the partitions to retrieve. — item shape: {Values: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.BatchGetPartition"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: PartitionsToGet, var: partitions_to_get}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, partitions_to_get: $partitions_to_get
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of resource metadata for a given list of trigger names. After calling the ListTriggers operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
#
# POST /
# Returns: record<Triggers: table<Name: string, WorkflowName: string, Id: string, Type: string, State: string, Description: string, Schedule: string, Actions: list, Predicate: record, EventBatchingCondition: record>, TriggersNotFound: list<string>>
# operationId: BatchGetTriggers
export def "batch-get-triggers" [
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
  trigger_names: list<string> # A list of trigger names, which may be the names returned from the ListTriggers operation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.BatchGetTriggers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TriggerNames, var: trigger_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, trigger_names: $trigger_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of resource metadata for a given list of workflow names. After calling the ListWorkflows operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
#
# POST /
# Returns: record<Workflows: table<Name: string, Description: string, DefaultRunProperties: record, CreatedOn: string, LastModifiedOn: string, LastRun: record, Graph: record, MaxConcurrentRuns: int, BlueprintDetails: record>, MissingWorkflows: list<string>>
# operationId: BatchGetWorkflows
export def "batch-get-workflows" [
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
  names: list<string> # A list of workflow names, which may be the names returned from the ListWorkflows operation.
  --include-graph: oneof<nothing, bool> # Specifies whether to include a graph when returning the workflow resource metadata.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.BatchGetWorkflows"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Names, var: names}, {name: IncludeGraph, var: include_graph}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, names: $names, include_graph: $include_graph
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops one or more job runs for a specified job definition.
#
# POST /
# Returns: record<SuccessfulSubmissions: table<JobName: string, JobRunId: string>, Errors: table<JobName: string, JobRunId: string, ErrorDetail: record>>
# operationId: BatchStopJobRun
export def "batch-stop-job-run" [
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
  job_name: string # The name of the job definition for which to stop job runs.
  job_run_ids: list<string> # A list of the JobRunIds that should be stopped for that job definition.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.BatchStopJobRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobName, var: job_name}, {name: JobRunIds, var: job_run_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_name: $job_name, job_run_ids: $job_run_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates one or more partitions in a batch operation.
#
# POST /
# Returns: record<Errors: table<PartitionValueList: list, ErrorDetail: record>>
# operationId: BatchUpdatePartition
export def "batch-update-partition" [
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
  --catalog-id: string # The ID of the catalog in which the partition is to be updated. Currently, this should be the Amazon Web Services account ID.
  database_name: string # The name of the metadata database in which the partition is to be updated.
  table_name: string # The name of the metadata table in which the partition is to be updated.
  entries: list # A list of up to 100 BatchUpdatePartitionRequestEntry objects to update. — item shape: {PartitionValueList: list<string>, PartitionInput: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.BatchUpdatePartition"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: Entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels the specified recommendation run that was being used to generate rules.
#
# POST /
# Returns: record
# operationId: CancelDataQualityRuleRecommendationRun
export def "cancel-data-quality-rule-recommendation-run" [
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
  run_id: string # The unique run identifier associated with this run.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CancelDataQualityRuleRecommendationRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: RunId, var: run_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, run_id: $run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a run where a ruleset is being evaluated against a data source.
#
# POST /
# Returns: record
# operationId: CancelDataQualityRulesetEvaluationRun
export def "cancel-data-quality-ruleset-evaluation-run" [
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
  run_id: string # The unique run identifier associated with this run.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CancelDataQualityRulesetEvaluationRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: RunId, var: run_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, run_id: $run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling CancelMLTaskRun with a task run's parent transform's TransformID and the task run's TaskRunId.
#
# POST /
# Returns: record<TransformId: string, TaskRunId: string, Status: string>
# operationId: CancelMLTaskRun
export def "cancel-ml-task-run" [
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
  transform_id: string # The unique identifier of the machine learning transform.
  task_run_id: string # A unique identifier for the task run.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CancelMLTaskRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TransformId, var: transform_id}, {name: TaskRunId, var: task_run_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, transform_id: $transform_id, task_run_id: $task_run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels the statement.
#
# POST /
# Returns: record
# operationId: CancelStatement
export def "cancel-statement" [
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
  session_id: string # The Session ID of the statement to be cancelled.
  id: int # The ID of the statement to be cancelled.
  --request-origin: string # The origin of the request to cancel the statement.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CancelStatement"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SessionId, var: session_id}, {name: Id, var: id}, {name: RequestOrigin, var: request_origin}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, session_id: $session_id, id: $id, request_origin: $request_origin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates the supplied schema. This call has no side effects, it simply validates using the supplied schema using DataFormat as the format. Since it does not take a schema set name, no compatibility checks are performed.
#
# POST /
# Returns: record<Valid: bool, Error: string>
# operationId: CheckSchemaVersionValidity
export def "check-schema-version-validity" [
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
  data_format: string@data-format-completer # The data format of the schema definition. Currently AVRO, JSON and PROTOBUF are supported.
  schema_definition: string # The definition of the schema that has to be validated.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CheckSchemaVersionValidity"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DataFormat, var: data_format}, {name: SchemaDefinition, var: schema_definition}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, data_format: $data_format, schema_definition: $schema_definition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a blueprint with Glue.
#
# POST /
# Returns: record<Name: string>
# operationId: CreateBlueprint
export def "create-blueprint" [
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
  name: string # The name of the blueprint.
  --description: string # A description of the blueprint.
  blueprint_location: string # Specifies a path in Amazon S3 where the blueprint is published.
  --tags: record # The tags to be applied to this blueprint.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateBlueprint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: BlueprintLocation, var: blueprint_location}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, blueprint_location: $blueprint_location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a classifier in the user's account. This can be a GrokClassifier, an XMLClassifier, a JsonClassifier, or a CsvClassifier, depending on which field of the request is present.
#
# POST /
# Returns: record
# operationId: CreateClassifier
export def "create-classifier" [
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
  --grok-classifier: record # Specifies a grok classifier for CreateClassifier to create. — shape: {Classification: string, Name: string, GrokPattern: string, CustomPatterns?: string}
  --xml-classifier: record # Specifies an XML classifier for CreateClassifier to create. — shape: {Classification: string, Name: string, RowTag?: string}
  --json-classifier: record # Specifies a JSON classifier for CreateClassifier to create. — shape: {Name: string, JsonPath: string}
  --csv-classifier: record # Specifies a custom CSV classifier for CreateClassifier to create. — shape: {Name: string, Delimiter?: string, QuoteSymbol?: string, ContainsHeader?: "UNKNOWN"|"PRESENT"|"ABSENT", Header?: list<string>, DisableValueTrimming?: bool, AllowSingleColumn?: bool, CustomDatatypeConfigured?: bool, CustomDatatypes?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateClassifier"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GrokClassifier, var: grok_classifier}, {name: XMLClassifier, var: xml_classifier}, {name: JsonClassifier, var: json_classifier}, {name: CsvClassifier, var: csv_classifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, grok_classifier: $grok_classifier, xml_classifier: $xml_classifier, json_classifier: $json_classifier, csv_classifier: $csv_classifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a connection definition in the Data Catalog.
#
# POST /
# Returns: record
# operationId: CreateConnection
export def "create-connection" [
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
  --catalog-id: string # The ID of the Data Catalog in which to create the connection. If none is provided, the Amazon Web Services account ID is used by default.
  connection_input: record # A structure that is used to specify a connection to create or update. — shape: {Name: string, Description?: string, ConnectionType: "JDBC"|"SFTP"|"MONGODB"|"KAFKA"|"NETWORK"|"MARKETPLACE"|"CUSTOM", MatchCriteria?: list<string>, ConnectionProperties: record, PhysicalConnectionRequirements?: record}
  --tags: record # The tags you assign to the connection.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: ConnectionInput, var: connection_input}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, connection_input: $connection_input, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the s3Targets field, the jdbcTargets field, or the DynamoDBTargets field.
#
# POST /
# Returns: record
# operationId: CreateCrawler
export def "create-crawler" [
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
  name: string # Name of the new crawler.
  role: string # The IAM role or Amazon Resource Name (ARN) of an IAM role used by the new crawler to access customer resources.
  --database-name: string # The Glue database where results are written, such as: arn:aws:daylight:us-east-1::database/sometable/*.
  --description: string # A description of the new crawler.
  targets: record # Specifies data stores to crawl. — shape: {S3Targets?: list, JdbcTargets?: list, MongoDBTargets?: list, DynamoDBTargets?: list, CatalogTargets?: list, DeltaTargets?: list}
  --schedule: string # A cron expression used to specify the schedule (see Time-Based Schedules for Jobs and Crawlers (https://docs.aws.amazon.com/glue/latest/dg/monitor-data-warehouse-schedule.html). For example, to run something every day at 12:15 UTC, you would specify: cron(15 12 * * ? *).
  --classifiers: list<string> # A list of custom classifiers that the user has registered. By default, all built-in classifiers are included in a crawl, but these custom classifiers always override the default classifiers for a given classification.
  --table-prefix: string # The table prefix used for catalog tables that are created.
  --schema-change-policy: record # A policy that specifies update and deletion behaviors for the crawler. — shape: {UpdateBehavior?: "LOG"|"UPDATE_IN_DATABASE", DeleteBehavior?: "LOG"|"DELETE_FROM_DATABASE"|"DEPRECATE_IN_DATABASE"}
  --recrawl-policy: record # When crawling an Amazon S3 data source after the first crawl is complete, specifies whether to crawl the entire dataset again or to crawl only folders that were added since the last crawler run. For more information, see Incremental Crawls in Glue (https://docs.aws.amazon.com/glue/latest/dg/incremental-crawls.html) in the developer guide. — shape: {RecrawlBehavior?: "CRAWL_EVERYTHING"|"CRAWL_NEW_FOLDERS_ONLY"|"CRAWL_EVENT_MODE"}
  --lineage-configuration: record # Specifies data lineage configuration settings for the crawler. — shape: {CrawlerLineageSettings?: "ENABLE"|"DISABLE"}
  --lake-formation-configuration: record # Specifies Lake Formation configuration settings for the crawler. — shape: {UseLakeFormationCredentials?: bool, AccountId?: string}
  --configuration: string # Crawler configuration information. This versioned JSON string allows users to specify aspects of a crawler's behavior. For more information, see Setting crawler configuration options (https://docs.aws.amazon.com/glue/latest/dg/crawler-configuration.html).
  --crawler-security-configuration: string # The name of the SecurityConfiguration structure to be used by this crawler.
  --tags: record # The tags to use with this crawler request. You may use tags to limit access to the crawler. For more information about tags in Glue, see Amazon Web Services Tags in Glue (https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html) in the developer guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateCrawler"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Role, var: role}, {name: DatabaseName, var: database_name}, {name: Description, var: description}, {name: Targets, var: targets}, {name: Schedule, var: schedule}, {name: Classifiers, var: classifiers}, {name: TablePrefix, var: table_prefix}, {name: SchemaChangePolicy, var: schema_change_policy}, {name: RecrawlPolicy, var: recrawl_policy}, {name: LineageConfiguration, var: lineage_configuration}, {name: LakeFormationConfiguration, var: lake_formation_configuration}, {name: Configuration, var: configuration}, {name: CrawlerSecurityConfiguration, var: crawler_security_configuration}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, role: $role, database_name: $database_name, description: $description, targets: $targets, schedule: $schedule, classifiers: $classifiers, table_prefix: $table_prefix, schema_change_policy: $schema_change_policy, recrawl_policy: $recrawl_policy, lineage_configuration: $lineage_configuration, lake_formation_configuration: $lake_formation_configuration, configuration: $configuration, crawler_security_configuration: $crawler_security_configuration, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a custom pattern that is used to detect sensitive data across the columns and rows of your structured data. Each custom pattern you create specifies a regular expression and an optional list of context words. If no context words are passed only a regular expression is checked.
#
# POST /
# Returns: record<Name: string>
# operationId: CreateCustomEntityType
export def "create-custom-entity-type" [
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
  name: string # A name for the custom pattern that allows it to be retrieved or deleted later. This name must be unique per Amazon Web Services account.
  regex_string: string # A regular expression string that is used for detecting sensitive data in a custom pattern.
  --context-words: list<string> # A list of context words. If none of these context words are found within the vicinity of the regular expression the data will not be detected as sensitive data. If no context words are passed only a regular expression is checked.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateCustomEntityType"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: RegexString, var: regex_string}, {name: ContextWords, var: context_words}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, regex_string: $regex_string, context_words: $context_words
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a data quality ruleset with DQDL rules applied to a specified Glue table. You create the ruleset using the Data Quality Definition Language (DQDL). For more information, see the Glue developer guide.
#
# POST /
# Returns: record<Name: string>
# operationId: CreateDataQualityRuleset
export def "create-data-quality-ruleset" [
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
  name: string # A unique name for the data quality ruleset.
  --description: string # A description of the data quality ruleset.
  ruleset: string # A Data Quality Definition Language (DQDL) ruleset. For more information, see the Glue developer guide.
  --tags: record # A list of tags applied to the data quality ruleset.
  --target-table: record # An object representing an Glue table. — shape: {TableName: string, DatabaseName: string}
  --client-token: string # Used for idempotency and is recommended to be set to a random ID (such as a UUID) to avoid creating or starting multiple instances of the same resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateDataQualityRuleset"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: Ruleset, var: ruleset}, {name: Tags, var: tags}, {name: TargetTable, var: target_table}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, ruleset: $ruleset, tags: $tags, target_table: $target_table, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new database in a Data Catalog.
#
# POST /
# Returns: record
# operationId: CreateDatabase
export def "create-database" [
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
  --catalog-id: string # The ID of the Data Catalog in which to create the database. If none is provided, the Amazon Web Services account ID is used by default.
  database_input: record # The structure used to create or update a database. — shape: {Name: string, Description?: string, LocationUri?: string, Parameters?: record, CreateTableDefaultPermissions?: list, TargetDatabase?: record, FederatedDatabase?: record}
  --tags: record # The tags you assign to the database.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateDatabase"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseInput, var: database_input}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_input: $database_input, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new development endpoint.
#
# POST /
# Returns: record<EndpointName: string, Status: string, SecurityGroupIds: list<string>, SubnetId: string, RoleArn: string, YarnEndpointAddress: string, ZeppelinRemoteSparkInterpreterPort: int, NumberOfNodes: int, WorkerType: string, GlueVersion: string, NumberOfWorkers: int, AvailabilityZone: string, VpcId: string, ExtraPythonLibsS3Path: string, ExtraJarsS3Path: string, FailureReason: string, SecurityConfiguration: string, CreatedTimestamp: string, Arguments: record>
# operationId: CreateDevEndpoint
export def "create-dev-endpoint" [
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
  endpoint_name: string # The name to be assigned to the new DevEndpoint.
  role_arn: string # The IAM role for the DevEndpoint.
  --security-group-ids: list<string> # Security group IDs for the security groups to be used by the new DevEndpoint.
  --subnet-id: string # The subnet ID for the new DevEndpoint to use.
  --public-key: string # The public key to be used by this DevEndpoint for authentication. This attribute is provided for backward compatibility because the recommended attribute to use is public keys.
  --public-keys: list<string> # A list of public keys to be used by the development endpoints for authentication. The use of this attribute is preferred over a single public key because the public keys allow you to have a different private key per client. If you previously created an endpoint with a public key, you must remove that key to be able to set a list of public keys. Call the UpdateDevEndpoint API with the public key content in the deletePublicKeys attribute, and the list of new keys in the addPublicKeys attribute.
  --number-of-nodes: int # The number of Glue Data Processing Units (DPUs) to allocate to this DevEndpoint.
  --worker-type: string@worker-type-completer # The type of predefined worker that is allocated to the development endpoint. Accepts a value of Standard, G.1X, or G.2X. For the Standard worker type, each worker provides 4 vCPU, 16 GB of memory and a 50GB disk, and 2 executors per worker. For the G.1X worker type, each worker maps to 1 DPU (4 vCPU, 16 GB of memory, 64 GB disk), and provides 1 executor per worker. We recommend this worker type for memory-intensive jobs. For the G.2X worker type, each worker maps to 2 DPU (8 vCPU, 32 GB of memory, 128 GB disk), and provides 1 executor per worker. We recommend this worker type for memory-intensive jobs. Known issue: when a development endpoint is created with the G.2X WorkerType configuration, the Spark drivers for the development endpoint will run on 4 vCPU, 16 GB of memory, and a 64 GB disk.
  --glue-version: string # Glue version determines the versions of Apache Spark and Python that Glue supports. The Python version indicates the version supported for running your ETL scripts on development endpoints. For more information about the available Glue versions and corresponding Spark and Python versions, see Glue version (https://docs.aws.amazon.com/glue/latest/dg/add-job.html) in the developer guide. Development endpoints that are created without specifying a Glue version default to Glue 0.9. You can specify a version of Python support for development endpoints by using the Arguments parameter in the CreateDevEndpoint or UpdateDevEndpoint APIs. If no arguments are provided, the version defaults to Python 2.
  --number-of-workers: int # The number of workers of a defined workerType that are allocated to the development endpoint. The maximum number of workers you can define are 299 for G.1X, and 149 for G.2X.
  --extra-python-libs-s3-path: string # The paths to one or more Python libraries in an Amazon S3 bucket that should be loaded in your DevEndpoint. Multiple values must be complete paths separated by a comma. You can only use pure Python libraries with a DevEndpoint. Libraries that rely on C extensions, such as the pandas (http://pandas.pydata.org/) Python data analysis library, are not yet supported.
  --extra-jars-s3-path: string # The path to one or more Java .jar files in an S3 bucket that should be loaded in your DevEndpoint.
  --security-configuration: string # The name of the SecurityConfiguration structure to be used with this DevEndpoint.
  --tags: record # The tags to use with this DevEndpoint. You may use tags to limit access to the DevEndpoint. For more information about tags in Glue, see Amazon Web Services Tags in Glue (https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html) in the developer guide.
  --arguments: record # A map of arguments used to configure the DevEndpoint.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateDevEndpoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointName, var: endpoint_name}, {name: RoleArn, var: role_arn}, {name: SecurityGroupIds, var: security_group_ids}, {name: SubnetId, var: subnet_id}, {name: PublicKey, var: public_key}, {name: PublicKeys, var: public_keys}, {name: NumberOfNodes, var: number_of_nodes}, {name: WorkerType, var: worker_type}, {name: GlueVersion, var: glue_version}, {name: NumberOfWorkers, var: number_of_workers}, {name: ExtraPythonLibsS3Path, var: extra_python_libs_s3_path}, {name: ExtraJarsS3Path, var: extra_jars_s3_path}, {name: SecurityConfiguration, var: security_configuration}, {name: Tags, var: tags}, {name: Arguments, var: arguments}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_name: $endpoint_name, role_arn: $role_arn, security_group_ids: $security_group_ids, subnet_id: $subnet_id, public_key: $public_key, public_keys: $public_keys, number_of_nodes: $number_of_nodes, worker_type: $worker_type, glue_version: $glue_version, number_of_workers: $number_of_workers, extra_python_libs_s3_path: $extra_python_libs_s3_path, extra_jars_s3_path: $extra_jars_s3_path, security_configuration: $security_configuration, tags: $tags, arguments: $arguments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new job definition.
#
# POST /
# Returns: record<Name: string>
# operationId: CreateJob
export def "create-job" [
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
  name: string # The name you assign to this job definition. It must be unique in your account.
  --description: string # Description of the job being defined.
  --log-uri: string # This field is reserved for future use.
  role: string # The name or Amazon Resource Name (ARN) of the IAM role associated with this job.
  --execution-property: record # An execution property of a job. — shape: {MaxConcurrentRuns?: int}
  command: record # Specifies code that runs when a job is run. — shape: {Name?: string, ScriptLocation?: string, PythonVersion?: string}
  --default-arguments: record # The default arguments for this job. You can specify arguments here that your own job-execution script consumes, as well as arguments that Glue itself consumes. Job arguments may be logged. Do not pass plaintext secrets as arguments. Retrieve secrets from a Glue Connection, Secrets Manager or other secret management mechanism if you intend to keep them within the Job. For information about how to specify and consume your own Job arguments, see the Calling Glue APIs in Python (https://docs.aws.amazon.com/glue/latest/dg/aws-glue-programming-python-calling.html) topic in the developer guide. For information about the key-value pairs that Glue consumes to set up your job, see the Special Parameters Used by Glue (https://docs.aws.amazon.com/glue/latest/dg/aws-glue-programming-etl-glue-arguments.html) topic in the developer guide.
  --non-overridable-arguments: record # Non-overridable arguments for this job, specified as name-value pairs.
  --connections: record # Specifies the connections used by a job. — shape: {Connections?: list<string>}
  --max-retries: int # The maximum number of times to retry this job if it fails.
  --allocated-capacity: int # This parameter is deprecated. Use MaxCapacity instead. The number of Glue data processing units (DPUs) to allocate to this Job. You can allocate a minimum of 2 DPUs; the default is 10. A DPU is a relative measure of processing power that consists of 4 vCPUs of compute capacity and 16 GB of memory. For more information, see the Glue pricing page (https://aws.amazon.com/glue/pricing/).This property is deprecated, use MaxCapacity instead.
  --timeout: int # The job timeout in minutes. This is the maximum time that a job run can consume resources before it is terminated and enters TIMEOUT status. The default is 2,880 minutes (48 hours).
  --max-capacity: float # For Glue version 1.0 or earlier jobs, using the standard worker type, the number of Glue data processing units (DPUs) that can be allocated when this job runs. A DPU is a relative measure of processing power that consists of 4 vCPUs of compute capacity and 16 GB of memory. For more information, see the Glue pricing page (https://aws.amazon.com/glue/pricing/). Do not set Max Capacity if using WorkerType and NumberOfWorkers. The value that can be allocated for MaxCapacity depends on whether you are running a Python shell job or an Apache Spark ETL job: When you specify a Python shell job (JobCommand.Name="pythonshell"), you can allocate either 0.0625 or 1 DPU. The default is 0.0625 DPU. When you specify an Apache Spark ETL job (JobCommand.Name="glueetl") or Apache Spark streaming ETL job (JobCommand.Name="gluestreaming"), you can allocate a minimum of 2 DPUs. The default is 10 DPUs. This job type cannot have a fractional DPU allocation. For Glue version 2.0 jobs, you cannot instead specify a Maximum capacity. Instead, you should specify a Worker type and the Number of workers. (format: double)
  --security-configuration: string # The name of the SecurityConfiguration structure to be used with this job.
  --tags: record # The tags to use with this job. You may use tags to limit access to the job. For more information about tags in Glue, see Amazon Web Services Tags in Glue (https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html) in the developer guide.
  --notification-property: record # Specifies configuration properties of a notification. — shape: {NotifyDelayAfter?: int}
  --glue-version: string # Glue version determines the versions of Apache Spark and Python that Glue supports. The Python version indicates the version supported for jobs of type Spark. For more information about the available Glue versions and corresponding Spark and Python versions, see Glue version (https://docs.aws.amazon.com/glue/latest/dg/add-job.html) in the developer guide. Jobs that are created without specifying a Glue version default to Glue 0.9.
  --number-of-workers: int # The number of workers of a defined workerType that are allocated when a job runs.
  --worker-type: string@worker-type-completer # The type of predefined worker that is allocated when a job runs. Accepts a value of Standard, G.1X, G.2X, or G.025X. For the Standard worker type, each worker provides 4 vCPU, 16 GB of memory and a 50GB disk, and 2 executors per worker. For the G.1X worker type, each worker maps to 1 DPU (4 vCPU, 16 GB of memory, 64 GB disk), and provides 1 executor per worker. We recommend this worker type for memory-intensive jobs. For the G.2X worker type, each worker maps to 2 DPU (8 vCPU, 32 GB of memory, 128 GB disk), and provides 1 executor per worker. We recommend this worker type for memory-intensive jobs. For the G.025X worker type, each worker maps to 0.25 DPU (2 vCPU, 4 GB of memory, 64 GB disk), and provides 1 executor per worker. We recommend this worker type for low volume streaming jobs. This worker type is only available for Glue version 3.0 streaming jobs.
  --code-gen-configuration-nodes: record # The representation of a directed acyclic graph on which both the Glue Studio visual component and Glue Studio code generation is based.
  --execution-class: string@execution-class-completer # Indicates whether the job is run with a standard or flexible execution class. The standard execution-class is ideal for time-sensitive workloads that require fast job startup and dedicated resources. The flexible execution class is appropriate for time-insensitive jobs whose start and completion times may vary. Only jobs with Glue version 3.0 and above and command type glueetl will be allowed to set ExecutionClass to FLEX. The flexible execution class is available for Spark jobs.
  --source-control-details: record # The details for a source control configuration for a job, allowing synchronization of job artifacts to or from a remote repository. — shape: {Provider?: "GITHUB"|"AWS_CODE_COMMIT", Repository?: string, Owner?: string, Branch?: string, Folder?: string, LastCommitId?: string, AuthStrategy?: "PERSONAL_ACCESS_TOKEN"|"AWS_SECRETS_MANAGER", AuthToken?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: LogUri, var: log_uri}, {name: Role, var: role}, {name: ExecutionProperty, var: execution_property}, {name: Command, var: command}, {name: DefaultArguments, var: default_arguments}, {name: NonOverridableArguments, var: non_overridable_arguments}, {name: Connections, var: connections}, {name: MaxRetries, var: max_retries}, {name: AllocatedCapacity, var: allocated_capacity}, {name: Timeout, var: timeout}, {name: MaxCapacity, var: max_capacity}, {name: SecurityConfiguration, var: security_configuration}, {name: Tags, var: tags}, {name: NotificationProperty, var: notification_property}, {name: GlueVersion, var: glue_version}, {name: NumberOfWorkers, var: number_of_workers}, {name: WorkerType, var: worker_type}, {name: CodeGenConfigurationNodes, var: code_gen_configuration_nodes}, {name: ExecutionClass, var: execution_class}, {name: SourceControlDetails, var: source_control_details}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, log_uri: $log_uri, role: $role, execution_property: $execution_property, command: $command, default_arguments: $default_arguments, non_overridable_arguments: $non_overridable_arguments, connections: $connections, max_retries: $max_retries, allocated_capacity: $allocated_capacity, timeout: $timeout, max_capacity: $max_capacity, security_configuration: $security_configuration, tags: $tags, notification_property: $notification_property, glue_version: $glue_version, number_of_workers: $number_of_workers, worker_type: $worker_type, code_gen_configuration_nodes: $code_gen_configuration_nodes, execution_class: $execution_class, source_control_details: $source_control_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it. Call this operation as the first step in the process of using a machine learning transform (such as the FindMatches transform) for deduplicating data. You can provide an optional Description, in addition to the parameters that you want to use for your algorithm. You must also specify certain parameters for the tasks that Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include Role, and optionally, AllocatedCapacity, Timeout, and MaxRetries. For more information, see Jobs (https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html).
#
# POST /
# Returns: record<TransformId: string>
# operationId: CreateMLTransform
export def "create-ml-transform" [
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
  name: string # The unique name that you give the transform when you create it.
  --description: string # A description of the machine learning transform that is being defined. The default is an empty string.
  input_record_tables: list # A list of Glue table definitions used by the transform. — item shape: {DatabaseName: string, TableName: string, CatalogId?: string, ConnectionName?: string, AdditionalOptions?: record}
  parameters: record # The algorithm-specific parameters that are associated with the machine learning transform. — shape: {TransformType: "FIND_MATCHES", FindMatchesParameters?: record}
  role: string # The name or Amazon Resource Name (ARN) of the IAM role with the required permissions. The required permissions include both Glue service role permissions to Glue resources, and Amazon S3 permissions required by the transform. This role needs Glue service role permissions to allow access to resources in Glue. See Attach a Policy to IAM Users That Access Glue (https://docs.aws.amazon.com/glue/latest/dg/attach-policy-iam-user.html). This role needs permission to your Amazon Simple Storage Service (Amazon S3) sources, targets, temporary directory, scripts, and any libraries used by the task run for this transform.
  --glue-version: string # This value determines which version of Glue this machine learning transform is compatible with. Glue 1.0 is recommended for most customers. If the value is not set, the Glue compatibility defaults to Glue 0.9. For more information, see Glue Versions (https://docs.aws.amazon.com/glue/latest/dg/release-notes.html#release-notes-versions) in the developer guide.
  --max-capacity: float # The number of Glue data processing units (DPUs) that are allocated to task runs for this transform. You can allocate from 2 to 100 DPUs; the default is 10. A DPU is a relative measure of processing power that consists of 4 vCPUs of compute capacity and 16 GB of memory. For more information, see the Glue pricing page (https://aws.amazon.com/glue/pricing/). MaxCapacity is a mutually exclusive option with NumberOfWorkers and WorkerType. If either NumberOfWorkers or WorkerType is set, then MaxCapacity cannot be set. If MaxCapacity is set then neither NumberOfWorkers or WorkerType can be set. If WorkerType is set, then NumberOfWorkers is required (and vice versa). MaxCapacity and NumberOfWorkers must both be at least 1. When the WorkerType field is set to a value other than Standard, the MaxCapacity field is set automatically and becomes read-only. When the WorkerType field is set to a value other than Standard, the MaxCapacity field is set automatically and becomes read-only. (format: double)
  --worker-type: string@worker-type-completer # The type of predefined worker that is allocated when this task runs. Accepts a value of Standard, G.1X, or G.2X. For the Standard worker type, each worker provides 4 vCPU, 16 GB of memory and a 50GB disk, and 2 executors per worker. For the G.1X worker type, each worker provides 4 vCPU, 16 GB of memory and a 64GB disk, and 1 executor per worker. For the G.2X worker type, each worker provides 8 vCPU, 32 GB of memory and a 128GB disk, and 1 executor per worker. MaxCapacity is a mutually exclusive option with NumberOfWorkers and WorkerType. If either NumberOfWorkers or WorkerType is set, then MaxCapacity cannot be set. If MaxCapacity is set then neither NumberOfWorkers or WorkerType can be set. If WorkerType is set, then NumberOfWorkers is required (and vice versa). MaxCapacity and NumberOfWorkers must both be at least 1.
  --number-of-workers: int # The number of workers of a defined workerType that are allocated when this task runs. If WorkerType is set, then NumberOfWorkers is required (and vice versa).
  --timeout: int # The timeout of the task run for this transform in minutes. This is the maximum time that a task run for this transform can consume resources before it is terminated and enters TIMEOUT status. The default is 2,880 minutes (48 hours).
  --max-retries: int # The maximum number of times to retry a task for this transform after a task run fails.
  --tags: record # The tags to use with this machine learning transform. You may use tags to limit access to the machine learning transform. For more information about tags in Glue, see Amazon Web Services Tags in Glue (https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html) in the developer guide.
  --transform-encryption: record # The encryption-at-rest settings of the transform that apply to accessing user data. Machine learning transforms can access user data encrypted in Amazon S3 using KMS. Additionally, imported labels and trained transforms can now be encrypted using a customer provided KMS key. — shape: {MlUserDataEncryption?: record, TaskRunSecurityConfigurationName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateMLTransform"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: InputRecordTables, var: input_record_tables}, {name: Parameters, var: parameters}, {name: Role, var: role}, {name: GlueVersion, var: glue_version}, {name: MaxCapacity, var: max_capacity}, {name: WorkerType, var: worker_type}, {name: NumberOfWorkers, var: number_of_workers}, {name: Timeout, var: timeout}, {name: MaxRetries, var: max_retries}, {name: Tags, var: tags}, {name: TransformEncryption, var: transform_encryption}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, input_record_tables: $input_record_tables, parameters: $parameters, role: $role, glue_version: $glue_version, max_capacity: $max_capacity, worker_type: $worker_type, number_of_workers: $number_of_workers, timeout: $timeout, max_retries: $max_retries, tags: $tags, transform_encryption: $transform_encryption
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new partition.
#
# POST /
# Returns: record
# operationId: CreatePartition
export def "create-partition" [
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
  --catalog-id: string # The Amazon Web Services account ID of the catalog in which the partition is to be created.
  database_name: string # The name of the metadata database in which the partition is to be created.
  table_name: string # The name of the metadata table in which the partition is to be created.
  partition_input: record # The structure used to create and update a partition. — shape: {Values?: list<string>, LastAccessTime?: string, StorageDescriptor?: record, Parameters?: record, LastAnalyzedTime?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreatePartition"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: PartitionInput, var: partition_input}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, partition_input: $partition_input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a specified partition index in an existing table.
#
# POST /
# Returns: record
# operationId: CreatePartitionIndex
export def "create-partition-index" [
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
  --catalog-id: string # The catalog ID where the table resides.
  database_name: string # Specifies the name of a database in which you want to create a partition index.
  table_name: string # Specifies the name of a table in which you want to create a partition index.
  partition_index: record # A structure for a partition index. — shape: {Keys: list<string>, IndexName: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreatePartitionIndex"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: PartitionIndex, var: partition_index}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, partition_index: $partition_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new registry which may be used to hold a collection of schemas.
#
# POST /
# Returns: record<RegistryArn: string, RegistryName: string, Description: string, Tags: record>
# operationId: CreateRegistry
export def "create-registry" [
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
  registry_name: string # Name of the registry to be created of max length of 255, and may only contain letters, numbers, hyphen, underscore, dollar sign, or hash mark. No whitespace.
  --description: string # A description of the registry. If description is not provided, there will not be any default value for this.
  --tags: record # Amazon Web Services tags that contain a key value pair and may be searched by console, command line, or API.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateRegistry"}]
    body: {content_type: "application/json", kind: json, fields: [{name: RegistryName, var: registry_name}, {name: Description, var: description}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, registry_name: $registry_name, description: $description, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new schema set and registers the schema definition. Returns an error if the schema set already exists without actually registering the version. When the schema set is created, a version checkpoint will be set to the first version. Compatibility mode "DISABLED" restricts any additional schema versions from being added after the first schema version. For all other compatibility modes, validation of compatibility settings will be applied only from the second version onwards when the RegisterSchemaVersion API is used. When this API is called without a RegistryId, this will create an entry for a "default-registry" in the registry database tables, if it is not already present.
#
# POST /
# Returns: record<RegistryName: string, RegistryArn: string, SchemaName: string, SchemaArn: string, Description: string, DataFormat: string, Compatibility: string, SchemaCheckpoint: int, LatestSchemaVersion: int, NextSchemaVersion: int, SchemaStatus: string, Tags: record, SchemaVersionId: string, SchemaVersionStatus: string>
# operationId: CreateSchema
export def "create-schema" [
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
  --registry-id: record # A wrapper structure that may contain the registry name and Amazon Resource Name (ARN). — shape: {RegistryName?: string, RegistryArn?: string}
  schema_name: string # Name of the schema to be created of max length of 255, and may only contain letters, numbers, hyphen, underscore, dollar sign, or hash mark. No whitespace.
  data_format: string@data-format-completer # The data format of the schema definition. Currently AVRO, JSON and PROTOBUF are supported.
  --compatibility: string@compatibility-completer # The compatibility mode of the schema. The possible values are: NONE: No compatibility mode applies. You can use this choice in development scenarios or if you do not know the compatibility mode that you want to apply to schemas. Any new version added will be accepted without undergoing a compatibility check. DISABLED: This compatibility choice prevents versioning for a particular schema. You can use this choice to prevent future versioning of a schema. BACKWARD: This compatibility choice is recommended as it allows data receivers to read both the current and one previous schema version. This means that for instance, a new schema version cannot drop data fields or change the type of these fields, so they can't be read by readers using the previous version. BACKWARD_ALL: This compatibility choice allows data receivers to read both the current and all previous schema versions. You can use this choice when you need to delete fields or add optional fields, and check compatibility against all previous schema versions. FORWARD: This compatibility choice allows data receivers to read both the current and one next schema version, but not necessarily later versions. You can use this choice when you need to add fields or delete optional fields, but only check compatibility against the last schema version. FORWARD_ALL: This compatibility choice allows data receivers to read written by producers of any new registered schema. You can use this choice when you need to add fields or delete optional fields, and check compatibility against all previous schema versions. FULL: This compatibility choice allows data receivers to read data written by producers using the previous or next version of the schema, but not necessarily earlier or later versions. You can use this choice when you need to add or remove optional fields, but only check compatibility against the last schema version. FULL_ALL: This compatibility choice allows data receivers to read data written by producers using all previous schema versions. You can use this choice when you need to add or remove optional fields, and check compatibility against all previous schema versions.
  --description: string # An optional description of the schema. If description is not provided, there will not be any automatic default value for this.
  --tags: record # Amazon Web Services tags that contain a key value pair and may be searched by console, command line, or API. If specified, follows the Amazon Web Services tags-on-create pattern.
  --schema-definition: string # The schema definition using the DataFormat setting for SchemaName.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateSchema"}]
    body: {content_type: "application/json", kind: json, fields: [{name: RegistryId, var: registry_id}, {name: SchemaName, var: schema_name}, {name: DataFormat, var: data_format}, {name: Compatibility, var: compatibility}, {name: Description, var: description}, {name: Tags, var: tags}, {name: SchemaDefinition, var: schema_definition}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, registry_id: $registry_id, schema_name: $schema_name, data_format: $data_format, compatibility: $compatibility, description: $description, tags: $tags, schema_definition: $schema_definition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transforms a directed acyclic graph (DAG) into code.
#
# POST /
# Returns: record<PythonScript: string, ScalaCode: string>
# operationId: CreateScript
export def "create-script" [
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
  --dag-nodes: list # A list of the nodes in the DAG. — item shape: {Id: string, NodeType: string, Args: list, LineNumber?: int}
  --dag-edges: list # A list of the edges in the DAG. — item shape: {Source: string, Target: string, TargetParameter?: string}
  --language: string@language-completer # The programming language of the resulting code from the DAG.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateScript"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DagNodes, var: dag_nodes}, {name: DagEdges, var: dag_edges}, {name: Language, var: language}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dag_nodes: $dag_nodes, dag_edges: $dag_edges, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new security configuration. A security configuration is a set of security properties that can be used by Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in Glue, see Encrypting Data Written by Crawlers, Jobs, and Development Endpoints (https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html).
#
# POST /
# Returns: record<Name: string, CreatedTimestamp: string>
# operationId: CreateSecurityConfiguration
export def "create-security-configuration" [
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
  name: string # The name for the new security configuration.
  encryption_configuration: record # Specifies an encryption configuration. — shape: {S3Encryption?: list, CloudWatchEncryption?: record, JobBookmarksEncryption?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateSecurityConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: EncryptionConfiguration, var: encryption_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, encryption_configuration: $encryption_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new session.
#
# POST /
# Returns: record<Session: record<Id: string, CreatedOn: string, Status: string, ErrorMessage: string, Description: string, Role: string, Command: record<Name: string, PythonVersion: string>, DefaultArguments: record, Connections: record<Connections: list>, Progress: float, MaxCapacity: float, SecurityConfiguration: string, GlueVersion: string>>
# operationId: CreateSession
export def "create-session" [
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
  id: string # The ID of the session request.
  --description: string # The description of the session.
  role: string # The IAM Role ARN
  command: record # The SessionCommand that runs the job. — shape: {Name?: string, PythonVersion?: string}
  --timeout: int # The number of minutes before session times out. Default for Spark ETL jobs is 48 hours (2880 minutes), the maximum session lifetime for this job type. Consult the documentation for other job types.
  --idle-timeout: int # The number of minutes when idle before session times out. Default for Spark ETL jobs is value of Timeout. Consult the documentation for other job types.
  --default-arguments: record # A map array of key-value pairs. Max is 75 pairs.
  --connections: record # Specifies the connections used by a job. — shape: {Connections?: list<string>}
  --max-capacity: float # The number of Glue data processing units (DPUs) that can be allocated when the job runs. A DPU is a relative measure of processing power that consists of 4 vCPUs of compute capacity and 16 GB memory. (format: double)
  --number-of-workers: int # The number of workers of a defined WorkerType to use for the session.
  --worker-type: string@worker-type-completer # The type of predefined worker that is allocated to use for the session. Accepts a value of Standard, G.1X, G.2X, or G.025X. For the Standard worker type, each worker provides 4 vCPU, 16 GB of memory and a 50GB disk, and 2 executors per worker. For the G.1X worker type, each worker maps to 1 DPU (4 vCPU, 16 GB of memory, 64 GB disk), and provides 1 executor per worker. We recommend this worker type for memory-intensive jobs. For the G.2X worker type, each worker maps to 2 DPU (8 vCPU, 32 GB of memory, 128 GB disk), and provides 1 executor per worker. We recommend this worker type for memory-intensive jobs. For the G.025X worker type, each worker maps to 0.25 DPU (2 vCPU, 4 GB of memory, 64 GB disk), and provides 1 executor per worker. We recommend this worker type for low volume streaming jobs. This worker type is only available for Glue version 3.0 streaming jobs.
  --security-configuration: string # The name of the SecurityConfiguration structure to be used with the session
  --glue-version: string # The Glue version determines the versions of Apache Spark and Python that Glue supports. The GlueVersion must be greater than 2.0.
  --tags: record # The map of key value pairs (tags) belonging to the session.
  --request-origin: string # The origin of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateSession"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Description, var: description}, {name: Role, var: role}, {name: Command, var: command}, {name: Timeout, var: timeout}, {name: IdleTimeout, var: idle_timeout}, {name: DefaultArguments, var: default_arguments}, {name: Connections, var: connections}, {name: MaxCapacity, var: max_capacity}, {name: NumberOfWorkers, var: number_of_workers}, {name: WorkerType, var: worker_type}, {name: SecurityConfiguration, var: security_configuration}, {name: GlueVersion, var: glue_version}, {name: Tags, var: tags}, {name: RequestOrigin, var: request_origin}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, description: $description, role: $role, command: $command, timeout: $timeout, idle_timeout: $idle_timeout, default_arguments: $default_arguments, connections: $connections, max_capacity: $max_capacity, number_of_workers: $number_of_workers, worker_type: $worker_type, security_configuration: $security_configuration, glue_version: $glue_version, tags: $tags, request_origin: $request_origin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new table definition in the Data Catalog.
#
# POST /
# Returns: record
# operationId: CreateTable
export def "create-table" [
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
  --catalog-id: string # The ID of the Data Catalog in which to create the Table. If none is supplied, the Amazon Web Services account ID is used by default.
  database_name: string # The catalog database in which to create the new table. For Hive compatibility, this name is entirely lowercase.
  table_input: record # A structure used to define a table. — shape: {Name: string, Description?: string, Owner?: string, LastAccessTime?: string, LastAnalyzedTime?: string, Retention?: int, StorageDescriptor?: record, PartitionKeys?: list, ViewOriginalText?: string, ViewExpandedText?: string, TableType?: string, Parameters?: record, TargetTable?: record}
  --partition-indexes: list # A list of partition indexes, PartitionIndex structures, to create in the table. — item shape: {Keys: list<string>, IndexName: string}
  --transaction-id: string # The ID of the transaction.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateTable"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableInput, var: table_input}, {name: PartitionIndexes, var: partition_indexes}, {name: TransactionId, var: transaction_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_input: $table_input, partition_indexes: $partition_indexes, transaction_id: $transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new trigger.
#
# POST /
# Returns: record<Name: string>
# operationId: CreateTrigger
export def "create-trigger" [
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
  name: string # The name of the trigger.
  --workflow-name: string # The name of the workflow associated with the trigger.
  type: string@type-completer # The type of the new trigger.
  --schedule: string # A cron expression used to specify the schedule (see Time-Based Schedules for Jobs and Crawlers (https://docs.aws.amazon.com/glue/latest/dg/monitor-data-warehouse-schedule.html). For example, to run something every day at 12:15 UTC, you would specify: cron(15 12 * * ? *). This field is required when the trigger type is SCHEDULED.
  --predicate: record # Defines the predicate of the trigger, which determines when it fires. — shape: {Logical?: "AND"|"ANY", Conditions?: list}
  actions: list # The actions initiated by this trigger when it fires. — item shape: {JobName?: string, Arguments?: record, Timeout?: int, SecurityConfiguration?: string, NotificationProperty?: record, CrawlerName?: string}
  --description: string # A description of the new trigger.
  --start-on-creation: oneof<nothing, bool> # Set to true to start SCHEDULED and CONDITIONAL triggers when created. True is not supported for ON_DEMAND triggers.
  --tags: record # The tags to use with this trigger. You may use tags to limit access to the trigger. For more information about tags in Glue, see Amazon Web Services Tags in Glue (https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html) in the developer guide.
  --event-batching-condition: record # Batch condition that must be met (specified number of events received or batch time window expired) before EventBridge event trigger fires. — shape: {BatchSize: int, BatchWindow?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateTrigger"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: WorkflowName, var: workflow_name}, {name: Type, var: type}, {name: Schedule, var: schedule}, {name: Predicate, var: predicate}, {name: Actions, var: actions}, {name: Description, var: description}, {name: StartOnCreation, var: start_on_creation}, {name: Tags, var: tags}, {name: EventBatchingCondition, var: event_batching_condition}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, workflow_name: $workflow_name, type: $type, schedule: $schedule, predicate: $predicate, actions: $actions, description: $description, start_on_creation: $start_on_creation, tags: $tags, event_batching_condition: $event_batching_condition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new function definition in the Data Catalog.
#
# POST /
# Returns: record
# operationId: CreateUserDefinedFunction
export def "create-user-defined-function" [
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
  --catalog-id: string # The ID of the Data Catalog in which to create the function. If none is provided, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database in which to create the function.
  function_input: record # A structure used to create or update a user-defined function. — shape: {FunctionName?: string, ClassName?: string, OwnerName?: string, OwnerType?: "USER"|"ROLE"|"GROUP", ResourceUris?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateUserDefinedFunction"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: FunctionInput, var: function_input}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, function_input: $function_input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new workflow.
#
# POST /
# Returns: record<Name: string>
# operationId: CreateWorkflow
export def "create-workflow" [
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
  name: string # The name to be assigned to the workflow. It should be unique within your account.
  --description: string # A description of the workflow.
  --default-run-properties: record # A collection of properties to be used as part of each execution of the workflow.
  --tags: record # The tags to be used with this workflow.
  --max-concurrent-runs: int # You can use this parameter to prevent unwanted multiple updates to data, to control costs, or in some cases, to prevent exceeding the maximum number of concurrent runs of any of the component jobs. If you leave this parameter blank, there is no limit to the number of concurrent workflow runs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.CreateWorkflow"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: DefaultRunProperties, var: default_run_properties}, {name: Tags, var: tags}, {name: MaxConcurrentRuns, var: max_concurrent_runs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, default_run_properties: $default_run_properties, tags: $tags, max_concurrent_runs: $max_concurrent_runs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing blueprint.
#
# POST /
# Returns: record<Name: string>
# operationId: DeleteBlueprint
export def "delete-blueprint" [
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
  name: string # The name of the blueprint to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteBlueprint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a classifier from the Data Catalog.
#
# POST /
# Returns: record
# operationId: DeleteClassifier
export def "delete-classifier" [
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
  name: string # Name of the classifier to remove.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteClassifier"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the partition column statistics of a column. The Identity and Access Management (IAM) permission required for this operation is DeletePartition.
#
# POST /
# Returns: record
# operationId: DeleteColumnStatisticsForPartition
export def "delete-column-statistics-for-partition" [
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
  --catalog-id: string # The ID of the Data Catalog where the partitions in question reside. If none is supplied, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database where the partitions reside.
  table_name: string # The name of the partitions' table.
  partition_values: list<string> # A list of partition values identifying the partition.
  column_name: string # Name of the column.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteColumnStatisticsForPartition"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: PartitionValues, var: partition_values}, {name: ColumnName, var: column_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, partition_values: $partition_values, column_name: $column_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves table statistics of columns. The Identity and Access Management (IAM) permission required for this operation is DeleteTable.
#
# POST /
# Returns: record
# operationId: DeleteColumnStatisticsForTable
export def "delete-column-statistics-for-table" [
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
  --catalog-id: string # The ID of the Data Catalog where the partitions in question reside. If none is supplied, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database where the partitions reside.
  table_name: string # The name of the partitions' table.
  column_name: string # The name of the column.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteColumnStatisticsForTable"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: ColumnName, var: column_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, column_name: $column_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a connection from the Data Catalog.
#
# POST /
# Returns: record
# operationId: DeleteConnection
export def "delete-connection" [
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
  --x-amz-target: string@x-amz-target-completer-46 # required
  --catalog-id: string # The ID of the Data Catalog in which the connection resides. If none is provided, the Amazon Web Services account ID is used by default.
  connection_name: string # The name of the connection to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: ConnectionName, var: connection_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, connection_name: $connection_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a specified crawler from the Glue Data Catalog, unless the crawler state is RUNNING.
#
# POST /
# Returns: record
# operationId: DeleteCrawler
export def "delete-crawler" [
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
  --x-amz-target: string@x-amz-target-completer-47 # required
  name: string # The name of the crawler to remove.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteCrawler"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a custom pattern by specifying its name.
#
# POST /
# Returns: record<Name: string>
# operationId: DeleteCustomEntityType
export def "delete-custom-entity-type" [
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
  --x-amz-target: string@x-amz-target-completer-48 # required
  name: string # The name of the custom pattern that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteCustomEntityType"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a data quality ruleset.
#
# POST /
# Returns: record
# operationId: DeleteDataQualityRuleset
export def "delete-data-quality-ruleset" [
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
  --x-amz-target: string@x-amz-target-completer-49 # required
  name: string # A name for the data quality ruleset.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteDataQualityRuleset"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a specified database from a Data Catalog. After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service. To ensure the immediate deletion of all related resources, before calling DeleteDatabase, use DeleteTableVersion or BatchDeleteTableVersion, DeletePartition or BatchDeletePartition, DeleteUserDefinedFunction, and DeleteTable or BatchDeleteTable, to delete any resources that belong to the database.
#
# POST /
# Returns: record
# operationId: DeleteDatabase
export def "delete-database" [
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
  --x-amz-target: string@x-amz-target-completer-50 # required
  --catalog-id: string # The ID of the Data Catalog in which the database resides. If none is provided, the Amazon Web Services account ID is used by default.
  name: string # The name of the database to delete. For Hive compatibility, this must be all lowercase.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteDatabase"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified development endpoint.
#
# POST /
# Returns: record
# operationId: DeleteDevEndpoint
export def "delete-dev-endpoint" [
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
  --x-amz-target: string@x-amz-target-completer-51 # required
  endpoint_name: string # The name of the DevEndpoint.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteDevEndpoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointName, var: endpoint_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_name: $endpoint_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified job definition. If the job definition is not found, no exception is thrown.
#
# POST /
# Returns: record<JobName: string>
# operationId: DeleteJob
export def "delete-job" [
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
  --x-amz-target: string@x-amz-target-completer-52 # required
  job_name: string # The name of the job definition to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobName, var: job_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_name: $job_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by Glue. If you no longer need a transform, you can delete it by calling DeleteMLTransforms. However, any Glue jobs that still reference the deleted transform will no longer succeed.
#
# POST /
# Returns: record<TransformId: string>
# operationId: DeleteMLTransform
export def "delete-ml-transform" [
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
  --x-amz-target: string@x-amz-target-completer-53 # required
  transform_id: string # The unique identifier of the transform to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteMLTransform"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TransformId, var: transform_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, transform_id: $transform_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified partition.
#
# POST /
# Returns: record
# operationId: DeletePartition
export def "delete-partition" [
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
  --x-amz-target: string@x-amz-target-completer-54 # required
  --catalog-id: string # The ID of the Data Catalog where the partition to be deleted resides. If none is provided, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database in which the table in question resides.
  table_name: string # The name of the table that contains the partition to be deleted.
  partition_values: list<string> # The values that define the partition.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeletePartition"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: PartitionValues, var: partition_values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, partition_values: $partition_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified partition index from an existing table.
#
# POST /
# Returns: record
# operationId: DeletePartitionIndex
export def "delete-partition-index" [
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
  --x-amz-target: string@x-amz-target-completer-55 # required
  --catalog-id: string # The catalog ID where the table resides.
  database_name: string # Specifies the name of a database from which you want to delete a partition index.
  table_name: string # Specifies the name of a table from which you want to delete a partition index.
  index_name: string # The name of the partition index to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeletePartitionIndex"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: IndexName, var: index_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, index_name: $index_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the entire registry including schema and all of its versions. To get the status of the delete operation, you can call the GetRegistry API after the asynchronous call. Deleting a registry will deactivate all online operations for the registry such as the UpdateRegistry, CreateSchema, UpdateSchema, and RegisterSchemaVersion APIs.
#
# POST /
# Returns: record<RegistryName: string, RegistryArn: string, Status: string>
# operationId: DeleteRegistry
export def "delete-registry" [
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
  --x-amz-target: string@x-amz-target-completer-56 # required
  registry_id: record # A wrapper structure that may contain the registry name and Amazon Resource Name (ARN). — shape: {RegistryName?: string, RegistryArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteRegistry"}]
    body: {content_type: "application/json", kind: json, fields: [{name: RegistryId, var: registry_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, registry_id: $registry_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified policy.
#
# POST /
# Returns: record
# operationId: DeleteResourcePolicy
export def "delete-resource-policy" [
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
  --x-amz-target: string@x-amz-target-completer-57 # required
  --policy-hash-condition: string # The hash value returned when this policy was set.
  --resource-arn: string # The ARN of the Glue resource for the resource policy to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteResourcePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PolicyHashCondition, var: policy_hash_condition}, {name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, policy_hash_condition: $policy_hash_condition, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the entire schema set, including the schema set and all of its versions. To get the status of the delete operation, you can call GetSchema API after the asynchronous call. Deleting a registry will deactivate all online operations for the schema, such as the GetSchemaByDefinition, and RegisterSchemaVersion APIs.
#
# POST /
# Returns: record<SchemaArn: string, SchemaName: string, Status: string>
# operationId: DeleteSchema
export def "delete-schema" [
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
  --x-amz-target: string@x-amz-target-completer-58 # required
  schema_id: record # The unique ID of the schema in the Glue schema registry. — shape: {SchemaArn?: string, SchemaName?: string, RegistryName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteSchema"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaId, var: schema_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, schema_id: $schema_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove versions from the specified schema. A version number or range may be supplied. If the compatibility mode forbids deleting of a version that is necessary, such as BACKWARDS_FULL, an error is returned. Calling the GetSchemaVersions API after this call will list the status of the deleted versions. When the range of version numbers contain check pointed version, the API will return a 409 conflict and will not proceed with the deletion. You have to remove the checkpoint first using the DeleteSchemaCheckpoint API before using this API. You cannot use the DeleteSchemaVersions API to delete the first schema version in the schema set. The first schema version can only be deleted by the DeleteSchema API. This operation will also delete the attached SchemaVersionMetadata under the schema versions. Hard deletes will be enforced on the database. If the compatibility mode forbids deleting of a version that is necessary, such as BACKWARDS_FULL, an error is returned.
#
# POST /
# Returns: record<SchemaVersionErrors: table<VersionNumber: int, ErrorDetails: record>>
# operationId: DeleteSchemaVersions
export def "delete-schema-versions" [
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
  --x-amz-target: string@x-amz-target-completer-59 # required
  schema_id: record # The unique ID of the schema in the Glue schema registry. — shape: {SchemaArn?: string, SchemaName?: string, RegistryName?: string}
  versions: string # A version range may be supplied which may be of the format: a single version number, 5 a range, 5-8 : deletes versions 5, 6, 7, 8
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteSchemaVersions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaId, var: schema_id}, {name: Versions, var: versions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, schema_id: $schema_id, versions: $versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified security configuration.
#
# POST /
# Returns: record
# operationId: DeleteSecurityConfiguration
export def "delete-security-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-60 # required
  name: string # The name of the security configuration to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteSecurityConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the session.
#
# POST /
# Returns: record<Id: string>
# operationId: DeleteSession
export def "delete-session" [
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
  --x-amz-target: string@x-amz-target-completer-61 # required
  id: string # The ID of the session to be deleted.
  --request-origin: string # The name of the origin of the delete session request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteSession"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: RequestOrigin, var: request_origin}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, request_origin: $request_origin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a table definition from the Data Catalog. After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service. To ensure the immediate deletion of all related resources, before calling DeleteTable, use DeleteTableVersion or BatchDeleteTableVersion, and DeletePartition or BatchDeletePartition, to delete any resources that belong to the table.
#
# POST /
# Returns: record
# operationId: DeleteTable
export def "delete-table" [
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
  --x-amz-target: string@x-amz-target-completer-62 # required
  --catalog-id: string # The ID of the Data Catalog where the table resides. If none is provided, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database in which the table resides. For Hive compatibility, this name is entirely lowercase.
  name: string # The name of the table to be deleted. For Hive compatibility, this name is entirely lowercase.
  --transaction-id: string # The transaction ID at which to delete the table contents.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteTable"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: Name, var: name}, {name: TransactionId, var: transaction_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, name: $name, transaction_id: $transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified version of a table.
#
# POST /
# Returns: record
# operationId: DeleteTableVersion
export def "delete-table-version" [
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
  --x-amz-target: string@x-amz-target-completer-63 # required
  --catalog-id: string # The ID of the Data Catalog where the tables reside. If none is provided, the Amazon Web Services account ID is used by default.
  database_name: string # The database in the catalog in which the table resides. For Hive compatibility, this name is entirely lowercase.
  table_name: string # The name of the table. For Hive compatibility, this name is entirely lowercase.
  version_id: string # The ID of the table version to be deleted. A VersionID is a string representation of an integer. Each version is incremented by 1.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteTableVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: VersionId, var: version_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified trigger. If the trigger is not found, no exception is thrown.
#
# POST /
# Returns: record<Name: string>
# operationId: DeleteTrigger
export def "delete-trigger" [
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
  --x-amz-target: string@x-amz-target-completer-64 # required
  name: string # The name of the trigger to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteTrigger"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing function definition from the Data Catalog.
#
# POST /
# Returns: record
# operationId: DeleteUserDefinedFunction
export def "delete-user-defined-function" [
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
  --x-amz-target: string@x-amz-target-completer-65 # required
  --catalog-id: string # The ID of the Data Catalog where the function to be deleted is located. If none is supplied, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database where the function is located.
  function_name: string # The name of the function definition to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteUserDefinedFunction"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: FunctionName, var: function_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, function_name: $function_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a workflow.
#
# POST /
# Returns: record<Name: string>
# operationId: DeleteWorkflow
export def "delete-workflow" [
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
  name: string # Name of the workflow to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.DeleteWorkflow"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details of a blueprint.
#
# POST /
# Returns: record<Blueprint: record<Name: string, Description: string, CreatedOn: string, LastModifiedOn: string, ParameterSpec: string, BlueprintLocation: string, BlueprintServiceLocation: string, Status: string, ErrorMessage: string, LastActiveDefinition: record<Description: string, LastModifiedOn: string, ParameterSpec: string, BlueprintLocation: string, BlueprintServiceLocation: string>>>
# operationId: GetBlueprint
export def "get-blueprint" [
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
  name: string # The name of the blueprint.
  --include-blueprint: oneof<nothing, bool> # Specifies whether or not to include the blueprint in the response.
  --include-parameter-spec: oneof<nothing, bool> # Specifies whether or not to include the parameter specification.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetBlueprint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: IncludeBlueprint, var: include_blueprint}, {name: IncludeParameterSpec, var: include_parameter_spec}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, include_blueprint: $include_blueprint, include_parameter_spec: $include_parameter_spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details of a blueprint run.
#
# POST /
# Returns: record<BlueprintRun: record<BlueprintName: string, RunId: string, WorkflowName: string, State: string, StartedOn: string, CompletedOn: string, ErrorMessage: string, RollbackErrorMessage: string, Parameters: string, RoleArn: string>>
# operationId: GetBlueprintRun
export def "get-blueprint-run" [
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
  blueprint_name: string # The name of the blueprint.
  run_id: string # The run ID for the blueprint run you want to retrieve.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetBlueprintRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BlueprintName, var: blueprint_name}, {name: RunId, var: run_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, blueprint_name: $blueprint_name, run_id: $run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details of blueprint runs for a specified blueprint.
#
# POST /
# Returns: record<BlueprintRuns: table<BlueprintName: string, RunId: string, WorkflowName: string, State: string, StartedOn: string, CompletedOn: string, ErrorMessage: string, RollbackErrorMessage: string, Parameters: string, RoleArn: string>, NextToken: string>
# operationId: GetBlueprintRuns
export def "get-blueprint-runs" [
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
  --x-amz-target: string@x-amz-target-completer-69 # required
  blueprint_name: string # The name of the blueprint.
  --body-next-token: string # A continuation token, if this is a continuation request. (spec name: NextToken)
  --body-max-results: int # The maximum size of a list to return. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetBlueprintRuns"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BlueprintName, var: blueprint_name}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, blueprint_name: $blueprint_name, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the status of a migration operation.
#
# POST /
# Returns: record<ImportStatus: record<ImportCompleted: bool, ImportTime: string, ImportedBy: string>>
# operationId: GetCatalogImportStatus
export def "get-catalog-import-status" [
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
  --catalog-id: string # The ID of the catalog to migrate. Currently, this should be the Amazon Web Services account ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetCatalogImportStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a classifier by name.
#
# POST /
# Returns: record<Classifier: record<GrokClassifier: record<Name: string, Classification: string, CreationTime: string, LastUpdated: string, Version: int, GrokPattern: string, CustomPatterns: string>, XMLClassifier: record<Name: string, Classification: string, CreationTime: string, LastUpdated: string, Version: int, RowTag: string>, JsonClassifier: record<Name: string, CreationTime: string, LastUpdated: string, Version: int, JsonPath: string>, CsvClassifier: record<Name: string, CreationTime: string, LastUpdated: string, Version: int, Delimiter: string, QuoteSymbol: string, ContainsHeader: string, Header: list, DisableValueTrimming: bool, AllowSingleColumn: bool, CustomDatatypeConfigured: bool, CustomDatatypes: list>>>
# operationId: GetClassifier
export def "get-classifier" [
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
  name: string # Name of the classifier to retrieve.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetClassifier"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all classifier objects in the Data Catalog.
#
# POST /
# Returns: record<Classifiers: table<GrokClassifier: record, XMLClassifier: record, JsonClassifier: record, CsvClassifier: record>, NextToken: string>
# operationId: GetClassifiers
export def "get-classifiers" [
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
  --x-amz-target: string@x-amz-target-completer-72 # required
  --body-max-results: int # The size of the list to return (optional). (spec name: MaxResults)
  --body-next-token: string # An optional continuation token. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetClassifiers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves partition statistics of columns. The Identity and Access Management (IAM) permission required for this operation is GetPartition.
#
# POST /
# Returns: record<ColumnStatisticsList: table<ColumnName: string, ColumnType: string, AnalyzedTime: string, StatisticsData: record>, Errors: table<ColumnName: string, Error: record>>
# operationId: GetColumnStatisticsForPartition
export def "get-column-statistics-for-partition" [
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
  --catalog-id: string # The ID of the Data Catalog where the partitions in question reside. If none is supplied, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database where the partitions reside.
  table_name: string # The name of the partitions' table.
  partition_values: list<string> # A list of partition values identifying the partition.
  column_names: list<string> # A list of the column names.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetColumnStatisticsForPartition"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: PartitionValues, var: partition_values}, {name: ColumnNames, var: column_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, partition_values: $partition_values, column_names: $column_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves table statistics of columns. The Identity and Access Management (IAM) permission required for this operation is GetTable.
#
# POST /
# Returns: record<ColumnStatisticsList: table<ColumnName: string, ColumnType: string, AnalyzedTime: string, StatisticsData: record>, Errors: table<ColumnName: string, Error: record>>
# operationId: GetColumnStatisticsForTable
export def "get-column-statistics-for-table" [
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
  --catalog-id: string # The ID of the Data Catalog where the partitions in question reside. If none is supplied, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database where the partitions reside.
  table_name: string # The name of the partitions' table.
  column_names: list<string> # A list of the column names.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetColumnStatisticsForTable"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: ColumnNames, var: column_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, column_names: $column_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a connection definition from the Data Catalog.
#
# POST /
# Returns: record<Connection: record<Name: string, Description: string, ConnectionType: string, MatchCriteria: list<string>, ConnectionProperties: record, PhysicalConnectionRequirements: record<SubnetId: string, SecurityGroupIdList: list, AvailabilityZone: string>, CreationTime: string, LastUpdatedTime: string, LastUpdatedBy: string>>
# operationId: GetConnection
export def "get-connection" [
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
  --catalog-id: string # The ID of the Data Catalog in which the connection resides. If none is provided, the Amazon Web Services account ID is used by default.
  name: string # The name of the connection definition to retrieve.
  --hide-password: oneof<nothing, bool> # Allows you to retrieve the connection metadata without returning the password. For instance, the Glue console uses this flag to retrieve the connection, and does not display the password. Set this parameter when the caller might not have permission to use the KMS key to decrypt the password, but it does have permission to access the rest of the connection properties.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: Name, var: name}, {name: HidePassword, var: hide_password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, name: $name, hide_password: $hide_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of connection definitions from the Data Catalog.
#
# POST /
# Returns: record<ConnectionList: table<Name: string, Description: string, ConnectionType: string, MatchCriteria: list, ConnectionProperties: record, PhysicalConnectionRequirements: record, CreationTime: string, LastUpdatedTime: string, LastUpdatedBy: string>, NextToken: string>
# operationId: GetConnections
export def "get-connections" [
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
  --x-amz-target: string@x-amz-target-completer-76 # required
  --catalog-id: string # The ID of the Data Catalog in which the connections reside. If none is provided, the Amazon Web Services account ID is used by default.
  --filter: record # Filters the connection definitions that are returned by the GetConnections API operation. — shape: {MatchCriteria?: list<string>, ConnectionType?: "JDBC"|"SFTP"|"MONGODB"|"KAFKA"|"NETWORK"|"MARKETPLACE"|"CUSTOM"}
  --hide-password: oneof<nothing, bool> # Allows you to retrieve the connection metadata without returning the password. For instance, the Glue console uses this flag to retrieve the connection, and does not display the password. Set this parameter when the caller might not have permission to use the KMS key to decrypt the password, but it does have permission to access the rest of the connection properties.
  --body-next-token: string # A continuation token, if this is a continuation call. (spec name: NextToken)
  --body-max-results: int # The maximum number of connections to return in one response. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetConnections"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: Filter, var: filter}, {name: HidePassword, var: hide_password}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, filter: $filter, hide_password: $hide_password, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves metadata for a specified crawler.
#
# POST /
# Returns: record<Crawler: record<Name: string, Role: string, Targets: record<S3Targets: list, JdbcTargets: list, MongoDBTargets: list, DynamoDBTargets: list, CatalogTargets: list, DeltaTargets: list>, DatabaseName: string, Description: string, Classifiers: list<string>, RecrawlPolicy: record<RecrawlBehavior: string>, SchemaChangePolicy: record<UpdateBehavior: string, DeleteBehavior: string>, LineageConfiguration: record<CrawlerLineageSettings: string>, State: string, TablePrefix: string, Schedule: record<ScheduleExpression: string, State: string>, CrawlElapsedTime: int, CreationTime: string, LastUpdated: string, LastCrawl: record<Status: string, ErrorMessage: string, LogGroup: string, LogStream: string, MessagePrefix: string, StartTime: string>, Version: int, Configuration: string, CrawlerSecurityConfiguration: string, LakeFormationConfiguration: record<UseLakeFormationCredentials: bool, AccountId: string>>>
# operationId: GetCrawler
export def "get-crawler" [
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
  name: string # The name of the crawler to retrieve metadata for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetCrawler"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves metrics about specified crawlers.
#
# POST /
# Returns: record<CrawlerMetricsList: table<CrawlerName: string, TimeLeftSeconds: float, StillEstimating: bool, LastRuntimeSeconds: float, MedianRuntimeSeconds: float, TablesCreated: int, TablesUpdated: int, TablesDeleted: int>, NextToken: string>
# operationId: GetCrawlerMetrics
export def "get-crawler-metrics" [
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
  --x-amz-target: string@x-amz-target-completer-78 # required
  --crawler-name-list: list<string> # A list of the names of crawlers about which to retrieve metrics.
  --body-max-results: int # The maximum size of a list to return. (spec name: MaxResults)
  --body-next-token: string # A continuation token, if this is a continuation call. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetCrawlerMetrics"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CrawlerNameList, var: crawler_name_list}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, crawler_name_list: $crawler_name_list, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves metadata for all crawlers defined in the customer account.
#
# POST /
# Returns: record<Crawlers: table<Name: string, Role: string, Targets: record, DatabaseName: string, Description: string, Classifiers: list, RecrawlPolicy: record, SchemaChangePolicy: record, LineageConfiguration: record, State: string, TablePrefix: string, Schedule: record, CrawlElapsedTime: int, CreationTime: string, LastUpdated: string, LastCrawl: record, Version: int, Configuration: string, CrawlerSecurityConfiguration: string, LakeFormationConfiguration: record>, NextToken: string>
# operationId: GetCrawlers
export def "get-crawlers" [
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
  --x-amz-target: string@x-amz-target-completer-79 # required
  --body-max-results: int # The number of crawlers to return on each call. (spec name: MaxResults)
  --body-next-token: string # A continuation token, if this is a continuation request. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetCrawlers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details of a custom pattern by specifying its name.
#
# POST /
# Returns: record<Name: string, RegexString: string, ContextWords: list<string>>
# operationId: GetCustomEntityType
export def "get-custom-entity-type" [
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
  name: string # The name of the custom pattern that you want to retrieve.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetCustomEntityType"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the security configuration for a specified catalog.
#
# POST /
# Returns: record<DataCatalogEncryptionSettings: record<EncryptionAtRest: record<CatalogEncryptionMode: string, SseAwsKmsKeyId: string>, ConnectionPasswordEncryption: record<ReturnConnectionPasswordEncrypted: bool, AwsKmsKeyId: string>>>
# operationId: GetDataCatalogEncryptionSettings
export def "get-data-catalog-encryption-settings" [
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
  --catalog-id: string # The ID of the Data Catalog to retrieve the security configuration for. If none is provided, the Amazon Web Services account ID is used by default.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetDataCatalogEncryptionSettings"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the result of a data quality rule evaluation.
#
# POST /
# Returns: record<ResultId: string, Score: float, DataSource: record<GlueTable: record<DatabaseName: string, TableName: string, CatalogId: string, ConnectionName: string, AdditionalOptions: record>>, RulesetName: string, EvaluationContext: string, StartedOn: string, CompletedOn: string, JobName: string, JobRunId: string, RulesetEvaluationRunId: string, RuleResults: table<Name: string, Description: string, EvaluationMessage: string, Result: string>>
# operationId: GetDataQualityResult
export def "get-data-quality-result" [
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
  result_id: string # A unique result ID for the data quality result.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetDataQualityResult"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResultId, var: result_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, result_id: $result_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified recommendation run that was used to generate rules.
#
# POST /
# Returns: record<RunId: string, DataSource: record<GlueTable: record<DatabaseName: string, TableName: string, CatalogId: string, ConnectionName: string, AdditionalOptions: record>>, Role: string, NumberOfWorkers: int, Timeout: int, Status: string, ErrorString: string, StartedOn: string, LastModifiedOn: string, CompletedOn: string, ExecutionTime: int, RecommendedRuleset: string, CreatedRulesetName: string>
# operationId: GetDataQualityRuleRecommendationRun
export def "get-data-quality-rule-recommendation-run" [
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
  run_id: string # The unique run identifier associated with this run.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetDataQualityRuleRecommendationRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: RunId, var: run_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, run_id: $run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an existing ruleset by identifier or name.
#
# POST /
# Returns: record<Name: string, Description: string, Ruleset: string, TargetTable: record<TableName: string, DatabaseName: string>, CreatedOn: string, LastModifiedOn: string, RecommendationRunId: string>
# operationId: GetDataQualityRuleset
export def "get-data-quality-ruleset" [
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
  --x-amz-target: string@x-amz-target-completer-84 # required
  name: string # The name of the ruleset.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetDataQualityRuleset"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific run where a ruleset is evaluated against a data source.
#
# POST /
# Returns: record<RunId: string, DataSource: record<GlueTable: record<DatabaseName: string, TableName: string, CatalogId: string, ConnectionName: string, AdditionalOptions: record>>, Role: string, NumberOfWorkers: int, Timeout: int, AdditionalRunOptions: record<CloudWatchMetricsEnabled: bool, ResultsS3Prefix: string>, Status: string, ErrorString: string, StartedOn: string, LastModifiedOn: string, CompletedOn: string, ExecutionTime: int, RulesetNames: list<string>, ResultIds: list<string>>
# operationId: GetDataQualityRulesetEvaluationRun
export def "get-data-quality-ruleset-evaluation-run" [
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
  --x-amz-target: string@x-amz-target-completer-85 # required
  run_id: string # The unique run identifier associated with this run.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetDataQualityRulesetEvaluationRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: RunId, var: run_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, run_id: $run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the definition of a specified database.
#
# POST /
# Returns: record<Database: record<Name: string, Description: string, LocationUri: string, Parameters: record, CreateTime: string, CreateTableDefaultPermissions: list<record>, TargetDatabase: record<CatalogId: string, DatabaseName: string>, CatalogId: string, FederatedDatabase: record<Identifier: string, ConnectionName: string>>>
# operationId: GetDatabase
export def "get-database" [
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
  --x-amz-target: string@x-amz-target-completer-86 # required
  --catalog-id: string # The ID of the Data Catalog in which the database resides. If none is provided, the Amazon Web Services account ID is used by default.
  name: string # The name of the database to retrieve. For Hive compatibility, this should be all lowercase.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetDatabase"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all databases defined in a given Data Catalog.
#
# POST /
# Returns: record<DatabaseList: table<Name: string, Description: string, LocationUri: string, Parameters: record, CreateTime: string, CreateTableDefaultPermissions: list, TargetDatabase: record, CatalogId: string, FederatedDatabase: record>, NextToken: string>
# operationId: GetDatabases
export def "get-databases" [
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
  --x-amz-target: string@x-amz-target-completer-87 # required
  --catalog-id: string # The ID of the Data Catalog from which to retrieve Databases. If none is provided, the Amazon Web Services account ID is used by default.
  --body-next-token: string # A continuation token, if this is a continuation call. (spec name: NextToken)
  --body-max-results: int # The maximum number of databases to return in one response. (spec name: MaxResults)
  --resource-share-type: string@resource-share-type-completer # Allows you to specify that you want to list the databases shared with your account. The allowable values are FEDERATED, FOREIGN or ALL. If set to FEDERATED, will list the federated databases (referencing an external entity) shared with your account. If set to FOREIGN, will list the databases shared with your account. If set to ALL, will list the databases shared with your account, as well as the databases in yor local account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetDatabases"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: ResourceShareType, var: resource_share_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, body_next_token: $body_next_token, body_max_results: $body_max_results, resource_share_type: $resource_share_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transforms a Python script into a directed acyclic graph (DAG).
#
# POST /
# Returns: record<DagNodes: table<Id: string, NodeType: string, Args: list, LineNumber: int>, DagEdges: table<Source: string, Target: string, TargetParameter: string>>
# operationId: GetDataflowGraph
export def "get-dataflow-graph" [
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
  --x-amz-target: string@x-amz-target-completer-88 # required
  --python-script: string # The Python script to transform.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetDataflowGraph"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PythonScript, var: python_script}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, python_script: $python_script
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a specified development endpoint. When you create a development endpoint in a virtual private cloud (VPC), Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, Glue returns only a public IP address.
#
# POST /
# Returns: record<DevEndpoint: record<EndpointName: string, RoleArn: string, SecurityGroupIds: list<string>, SubnetId: string, YarnEndpointAddress: string, PrivateAddress: string, ZeppelinRemoteSparkInterpreterPort: int, PublicAddress: string, Status: string, WorkerType: string, GlueVersion: string, NumberOfWorkers: int, NumberOfNodes: int, AvailabilityZone: string, VpcId: string, ExtraPythonLibsS3Path: string, ExtraJarsS3Path: string, FailureReason: string, LastUpdateStatus: string, CreatedTimestamp: string, LastModifiedTimestamp: string, PublicKey: string, PublicKeys: list<string>, SecurityConfiguration: string, Arguments: record>>
# operationId: GetDevEndpoint
export def "get-dev-endpoint" [
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
  --x-amz-target: string@x-amz-target-completer-89 # required
  endpoint_name: string # Name of the DevEndpoint to retrieve information for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetDevEndpoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointName, var: endpoint_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_name: $endpoint_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all the development endpoints in this Amazon Web Services account. When you create a development endpoint in a virtual private cloud (VPC), Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, Glue returns only a public IP address.
#
# POST /
# Returns: record<DevEndpoints: table<EndpointName: string, RoleArn: string, SecurityGroupIds: list, SubnetId: string, YarnEndpointAddress: string, PrivateAddress: string, ZeppelinRemoteSparkInterpreterPort: int, PublicAddress: string, Status: string, WorkerType: string, GlueVersion: string, NumberOfWorkers: int, NumberOfNodes: int, AvailabilityZone: string, VpcId: string, ExtraPythonLibsS3Path: string, ExtraJarsS3Path: string, FailureReason: string, LastUpdateStatus: string, CreatedTimestamp: string, LastModifiedTimestamp: string, PublicKey: string, PublicKeys: list, SecurityConfiguration: string, Arguments: record>, NextToken: string>
# operationId: GetDevEndpoints
export def "get-dev-endpoints" [
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
  --x-amz-target: string@x-amz-target-completer-90 # required
  --body-max-results: int # The maximum size of information to return. (spec name: MaxResults)
  --body-next-token: string # A continuation token, if this is a continuation call. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetDevEndpoints"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an existing job definition.
#
# POST /
# Returns: record<Job: record<Name: string, Description: string, LogUri: string, Role: string, CreatedOn: string, LastModifiedOn: string, ExecutionProperty: record<MaxConcurrentRuns: int>, Command: record<Name: string, ScriptLocation: string, PythonVersion: string>, DefaultArguments: record, NonOverridableArguments: record, Connections: record<Connections: list>, MaxRetries: int, AllocatedCapacity: int, Timeout: int, MaxCapacity: float, WorkerType: string, NumberOfWorkers: int, SecurityConfiguration: string, NotificationProperty: record<NotifyDelayAfter: int>, GlueVersion: string, CodeGenConfigurationNodes: record, ExecutionClass: string, SourceControlDetails: record<Provider: string, Repository: string, Owner: string, Branch: string, Folder: string, LastCommitId: string, AuthStrategy: string, AuthToken: string>>>
# operationId: GetJob
export def "get-job" [
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
  --x-amz-target: string@x-amz-target-completer-91 # required
  job_name: string # The name of the job definition to retrieve.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobName, var: job_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_name: $job_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information on a job bookmark entry. For more information about enabling and using job bookmarks, see: Tracking processed data using job bookmarks (https://docs.aws.amazon.com/glue/latest/dg/monitor-continuations.html) Job parameters used by Glue (https://docs.aws.amazon.com/glue/latest/dg/aws-glue-programming-etl-glue-arguments.html) Job structure (https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html#aws-glue-api-jobs-job-Job)
#
# POST /
# Returns: record<JobBookmarkEntry: record<JobName: string, Version: int, Run: int, Attempt: int, PreviousRunId: string, RunId: string, JobBookmark: string>>
# operationId: GetJobBookmark
export def "get-job-bookmark" [
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
  --x-amz-target: string@x-amz-target-completer-92 # required
  job_name: string # The name of the job in question.
  --run-id: string # The unique run identifier associated with this job run.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetJobBookmark"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobName, var: job_name}, {name: RunId, var: run_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_name: $job_name, run_id: $run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the metadata for a given job run.
#
# POST /
# Returns: record<JobRun: record<Id: string, Attempt: int, PreviousRunId: string, TriggerName: string, JobName: string, StartedOn: string, LastModifiedOn: string, CompletedOn: string, JobRunState: string, Arguments: record, ErrorMessage: string, PredecessorRuns: list<record>, AllocatedCapacity: int, ExecutionTime: int, Timeout: int, MaxCapacity: float, WorkerType: string, NumberOfWorkers: int, SecurityConfiguration: string, LogGroupName: string, NotificationProperty: record<NotifyDelayAfter: int>, GlueVersion: string, DPUSeconds: float, ExecutionClass: string>>
# operationId: GetJobRun
export def "get-job-run" [
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
  --x-amz-target: string@x-amz-target-completer-93 # required
  job_name: string # Name of the job definition being run.
  run_id: string # The ID of the job run.
  --predecessors-included: oneof<nothing, bool> # True if a list of predecessor runs should be returned.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetJobRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobName, var: job_name}, {name: RunId, var: run_id}, {name: PredecessorsIncluded, var: predecessors_included}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_name: $job_name, run_id: $run_id, predecessors_included: $predecessors_included
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves metadata for all runs of a given job definition.
#
# POST /
# Returns: record<JobRuns: table<Id: string, Attempt: int, PreviousRunId: string, TriggerName: string, JobName: string, StartedOn: string, LastModifiedOn: string, CompletedOn: string, JobRunState: string, Arguments: record, ErrorMessage: string, PredecessorRuns: list, AllocatedCapacity: int, ExecutionTime: int, Timeout: int, MaxCapacity: float, WorkerType: string, NumberOfWorkers: int, SecurityConfiguration: string, LogGroupName: string, NotificationProperty: record, GlueVersion: string, DPUSeconds: float, ExecutionClass: string>, NextToken: string>
# operationId: GetJobRuns
export def "get-job-runs" [
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
  --x-amz-target: string@x-amz-target-completer-94 # required
  job_name: string # The name of the job definition for which to retrieve all job runs.
  --body-next-token: string # A continuation token, if this is a continuation call. (spec name: NextToken)
  --body-max-results: int # The maximum size of the response. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetJobRuns"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobName, var: job_name}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_name: $job_name, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all current job definitions.
#
# POST /
# Returns: record<Jobs: table<Name: string, Description: string, LogUri: string, Role: string, CreatedOn: string, LastModifiedOn: string, ExecutionProperty: record, Command: record, DefaultArguments: record, NonOverridableArguments: record, Connections: record, MaxRetries: int, AllocatedCapacity: int, Timeout: int, MaxCapacity: float, WorkerType: string, NumberOfWorkers: int, SecurityConfiguration: string, NotificationProperty: record, GlueVersion: string, CodeGenConfigurationNodes: record, ExecutionClass: string, SourceControlDetails: record>, NextToken: string>
# operationId: GetJobs
export def "get-jobs" [
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
  --x-amz-target: string@x-amz-target-completer-95 # required
  --body-next-token: string # A continuation token, if this is a continuation call. (spec name: NextToken)
  --body-max-results: int # The maximum size of the response. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling GetMLTaskRun with the TaskRunID and its parent transform's TransformID.
#
# POST /
# Returns: record<TransformId: string, TaskRunId: string, Status: string, LogGroupName: string, Properties: record<TaskType: string, ImportLabelsTaskRunProperties: record<InputS3Path: string, Replace: bool>, ExportLabelsTaskRunProperties: record<OutputS3Path: string>, LabelingSetGenerationTaskRunProperties: record<OutputS3Path: string>, FindMatchesTaskRunProperties: record<JobId: string, JobName: string, JobRunId: string>>, ErrorString: string, StartedOn: string, LastModifiedOn: string, CompletedOn: string, ExecutionTime: int>
# operationId: GetMLTaskRun
export def "get-ml-task-run" [
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
  --x-amz-target: string@x-amz-target-completer-96 # required
  transform_id: string # The unique identifier of the machine learning transform.
  task_run_id: string # The unique identifier of the task run.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetMLTaskRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TransformId, var: transform_id}, {name: TaskRunId, var: task_run_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, transform_id: $transform_id, task_run_id: $task_run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling GetMLTaskRuns with their parent transform's TransformID and other optional parameters as documented in this section. This operation returns a list of historic runs and must be paginated.
#
# POST /
# Returns: record<TaskRuns: table<TransformId: string, TaskRunId: string, Status: string, LogGroupName: string, Properties: record, ErrorString: string, StartedOn: string, LastModifiedOn: string, CompletedOn: string, ExecutionTime: int>, NextToken: string>
# operationId: GetMLTaskRuns
export def "get-ml-task-runs" [
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
  --x-amz-target: string@x-amz-target-completer-97 # required
  transform_id: string # The unique identifier of the machine learning transform.
  --body-next-token: string # A token for pagination of the results. The default is empty. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return. (spec name: MaxResults)
  --filter: record # The criteria that are used to filter the task runs for the machine learning transform. — shape: {TaskRunType?: "EVALUATION"|"LABELING_SET_GENERATION"|"IMPORT_LABELS"|"EXPORT_LABELS"|"FIND_MATCHES", Status?: "STARTING"|"RUNNING"|"STOPPING"|"STOPPED"|"SUCCEEDED"|"FAILED"|"TIMEOUT", StartedBefore?: string, StartedAfter?: string}
  --sort: record # The sorting criteria that are used to sort the list of task runs for the machine learning transform. — shape: {Column: "TASK_RUN_TYPE"|"STATUS"|"STARTED", SortDirection: "DESCENDING"|"ASCENDING"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetMLTaskRuns"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TransformId, var: transform_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filter, var: filter}, {name: Sort, var: sort}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, transform_id: $transform_id, body_next_token: $body_next_token, body_max_results: $body_max_results, filter: $filter, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by Glue. You can retrieve their metadata by calling GetMLTransform.
#
# POST /
# Returns: record<TransformId: string, Name: string, Description: string, Status: string, CreatedOn: string, LastModifiedOn: string, InputRecordTables: table<DatabaseName: string, TableName: string, CatalogId: string, ConnectionName: string, AdditionalOptions: record>, Parameters: record<TransformType: string, FindMatchesParameters: record<PrimaryKeyColumnName: string, PrecisionRecallTradeoff: float, AccuracyCostTradeoff: float, EnforceProvidedLabels: bool>>, EvaluationMetrics: record<TransformType: string, FindMatchesMetrics: record<AreaUnderPRCurve: float, Precision: float, Recall: float, F1: float, ConfusionMatrix: record, ColumnImportances: list>>, LabelCount: int, Schema: table<Name: string, DataType: string>, Role: string, GlueVersion: string, MaxCapacity: float, WorkerType: string, NumberOfWorkers: int, Timeout: int, MaxRetries: int, TransformEncryption: record<MlUserDataEncryption: record<MlUserDataEncryptionMode: string, KmsKeyId: string>, TaskRunSecurityConfigurationName: string>>
# operationId: GetMLTransform
export def "get-ml-transform" [
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
  --x-amz-target: string@x-amz-target-completer-98 # required
  transform_id: string # The unique identifier of the transform, generated at the time that the transform was created.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetMLTransform"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TransformId, var: transform_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, transform_id: $transform_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a sortable, filterable list of existing Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by Glue, and you can retrieve their metadata by calling GetMLTransforms.
#
# POST /
# Returns: record<Transforms: table<TransformId: string, Name: string, Description: string, Status: string, CreatedOn: string, LastModifiedOn: string, InputRecordTables: list, Parameters: record, EvaluationMetrics: record, LabelCount: int, Schema: list, Role: string, GlueVersion: string, MaxCapacity: float, WorkerType: string, NumberOfWorkers: int, Timeout: int, MaxRetries: int, TransformEncryption: record>, NextToken: string>
# operationId: GetMLTransforms
export def "get-ml-transforms" [
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
  --x-amz-target: string@x-amz-target-completer-99 # required
  --body-next-token: string # A paginated token to offset the results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return. (spec name: MaxResults)
  --filter: record # The criteria used to filter the machine learning transforms. — shape: {Name?: string, TransformType?: "FIND_MATCHES", Status?: "NOT_READY"|"READY"|"DELETING", GlueVersion?: string, CreatedBefore?: string, CreatedAfter?: string, LastModifiedBefore?: string, LastModifiedAfter?: string, Schema?: list}
  --sort: record # The sorting criteria that are associated with the machine learning transform. — shape: {Column: "NAME"|"TRANSFORM_TYPE"|"STATUS"|"CREATED"|"LAST_MODIFIED", SortDirection: "DESCENDING"|"ASCENDING"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetMLTransforms"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filter, var: filter}, {name: Sort, var: sort}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, filter: $filter, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates mappings.
#
# POST /
# Returns: record<Mapping: table<SourceTable: string, SourcePath: string, SourceType: string, TargetTable: string, TargetPath: string, TargetType: string>>
# operationId: GetMapping
export def "get-mapping" [
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
  --x-amz-target: string@x-amz-target-completer-100 # required
  source: record # Specifies a table definition in the Glue Data Catalog. — shape: {DatabaseName: string, TableName: string}
  --sinks: list # A list of target tables. — item shape: {DatabaseName: string, TableName: string}
  --location: record # The location of resources. — shape: {Jdbc?: list, S3?: list, DynamoDB?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetMapping"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Source, var: source}, {name: Sinks, var: sinks}, {name: Location, var: location}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, source: $source, sinks: $sinks, location: $location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a specified partition.
#
# POST /
# Returns: record<Partition: record<Values: list<string>, DatabaseName: string, TableName: string, CreationTime: string, LastAccessTime: string, StorageDescriptor: record<Columns: list, Location: string, AdditionalLocations: list, InputFormat: string, OutputFormat: string, Compressed: bool, NumberOfBuckets: int, SerdeInfo: record, BucketColumns: list, SortColumns: list, Parameters: record, SkewedInfo: record, StoredAsSubDirectories: bool, SchemaReference: record>, Parameters: record, LastAnalyzedTime: string, CatalogId: string>>
# operationId: GetPartition
export def "get-partition" [
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
  --x-amz-target: string@x-amz-target-completer-101 # required
  --catalog-id: string # The ID of the Data Catalog where the partition in question resides. If none is provided, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database where the partition resides.
  table_name: string # The name of the partition's table.
  partition_values: list<string> # The values that define the partition.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetPartition"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: PartitionValues, var: partition_values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, partition_values: $partition_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the partition indexes associated with a table.
#
# POST /
# Returns: record<PartitionIndexDescriptorList: table<IndexName: string, Keys: list, IndexStatus: string, BackfillErrors: list>, NextToken: string>
# operationId: GetPartitionIndexes
export def "get-partition-indexes" [
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
  --x-amz-target: string@x-amz-target-completer-102 # required
  --catalog-id: string # The catalog ID where the table resides.
  database_name: string # Specifies the name of a database from which you want to retrieve partition indexes.
  table_name: string # Specifies the name of a table for which you want to retrieve the partition indexes.
  --body-next-token: string # A continuation token, included if this is a continuation call. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetPartitionIndexes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the partitions in a table.
#
# POST /
# Returns: record<Partitions: table<Values: list, DatabaseName: string, TableName: string, CreationTime: string, LastAccessTime: string, StorageDescriptor: record, Parameters: record, LastAnalyzedTime: string, CatalogId: string>, NextToken: string>
# operationId: GetPartitions
export def "get-partitions" [
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
  --x-amz-target: string@x-amz-target-completer-103 # required
  --catalog-id: string # The ID of the Data Catalog where the partitions in question reside. If none is provided, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database where the partitions reside.
  table_name: string # The name of the partitions' table.
  --expression: string # An expression that filters the partitions to be returned. The expression uses SQL syntax similar to the SQL WHERE filter clause. The SQL statement parser JSQLParser (http://jsqlparser.sourceforge.net/home.php) parses the expression. Operators: The following are the operators that you can use in the Expression API call: = Checks whether the values of the two operands are equal; if yes, then the condition becomes true. Example: Assume 'variable a' holds 10 and 'variable b' holds 20. (a = b) is not true. < > Checks whether the values of two operands are equal; if the values are not equal, then the condition becomes true. Example: (a < > b) is true. > Checks whether the value of the left operand is greater than the value of the right operand; if yes, then the condition becomes true. Example: (a > b) is not true. < Checks whether the value of the left operand is less than the value of the right operand; if yes, then the condition becomes true. Example: (a < b) is true. >= Checks whether the value of the left operand is greater than or equal to the value of the right operand; if yes, then the condition becomes true. Example: (a >= b) is not true. <= Checks whether the value of the left operand is less than or equal to the value of the right operand; if yes, then the condition becomes true. Example: (a <= b) is true. AND, OR, IN, BETWEEN, LIKE, NOT, IS NULL Logical operators. Supported Partition Key Types: The following are the supported partition keys. string date timestamp int bigint long tinyint smallint decimal If an type is encountered that is not valid, an exception is thrown. The following list shows the valid operators on each type. When you define a crawler, the partitionKey type is created as a STRING, to be compatible with the catalog partitions. Sample API Call:
  --body-next-token: string # A continuation token, if this is not the first call to retrieve these partitions. (spec name: NextToken)
  --segment: record # Defines a non-overlapping region of a table's partitions, allowing multiple requests to be run in parallel. — shape: {SegmentNumber: int, TotalSegments: int}
  --body-max-results: int # The maximum number of partitions to return in a single response. (spec name: MaxResults)
  --exclude-column-schema: oneof<nothing, bool> # When true, specifies not returning the partition column schema. Useful when you are interested only in other partition attributes such as partition values or location. This approach avoids the problem of a large response by not returning duplicate data.
  --transaction-id: string # The transaction ID at which to read the partition contents.
  --query-as-of-time: string # The time as of when to read the partition contents. If not set, the most recent transaction commit time will be used. Cannot be specified along with TransactionId. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetPartitions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: Expression, var: expression}, {name: NextToken, var: body_next_token}, {name: Segment, var: segment}, {name: MaxResults, var: body_max_results}, {name: ExcludeColumnSchema, var: exclude_column_schema}, {name: TransactionId, var: transaction_id}, {name: QueryAsOfTime, var: query_as_of_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, expression: $expression, body_next_token: $body_next_token, segment: $segment, body_max_results: $body_max_results, exclude_column_schema: $exclude_column_schema, transaction_id: $transaction_id, query_as_of_time: $query_as_of_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets code to perform a specified mapping.
#
# POST /
# Returns: record<PythonScript: string, ScalaCode: string>
# operationId: GetPlan
export def "get-plan" [
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
  --x-amz-target: string@x-amz-target-completer-104 # required
  mapping: list # The list of mappings from a source table to target tables. — item shape: {SourceTable?: string, SourcePath?: string, SourceType?: string, TargetTable?: string, TargetPath?: string, TargetType?: string}
  source: record # Specifies a table definition in the Glue Data Catalog. — shape: {DatabaseName: string, TableName: string}
  --sinks: list # The target tables. — item shape: {DatabaseName: string, TableName: string}
  --location: record # The location of resources. — shape: {Jdbc?: list, S3?: list, DynamoDB?: list}
  --language: string@language-completer # The programming language of the code to perform the mapping.
  --additional-plan-options-map: record # A map to hold additional optional key-value parameters. Currently, these key-value pairs are supported: inferSchema — Specifies whether to set inferSchema to true or false for the default script generated by an Glue job. For example, to set inferSchema to true, pass the following key value pair: --additional-plan-options-map '{"inferSchema":"true"}'
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetPlan"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Mapping, var: mapping}, {name: Source, var: source}, {name: Sinks, var: sinks}, {name: Location, var: location}, {name: Language, var: language}, {name: AdditionalPlanOptionsMap, var: additional_plan_options_map}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, mapping: $mapping, source: $source, sinks: $sinks, location: $location, language: $language, additional_plan_options_map: $additional_plan_options_map
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the specified registry in detail.
#
# POST /
# Returns: record<RegistryName: string, RegistryArn: string, Description: string, Status: string, CreatedTime: string, UpdatedTime: string>
# operationId: GetRegistry
export def "get-registry" [
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
  --x-amz-target: string@x-amz-target-completer-105 # required
  registry_id: record # A wrapper structure that may contain the registry name and Amazon Resource Name (ARN). — shape: {RegistryName?: string, RegistryArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetRegistry"}]
    body: {content_type: "application/json", kind: json, fields: [{name: RegistryId, var: registry_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, registry_id: $registry_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the resource policies set on individual resources by Resource Access Manager during cross-account permission grants. Also retrieves the Data Catalog resource policy. If you enabled metadata encryption in Data Catalog settings, and you do not have permission on the KMS key, the operation can't return the Data Catalog resource policy.
#
# POST /
# Returns: record<GetResourcePoliciesResponseList: table<PolicyInJson: string, PolicyHash: string, CreateTime: string, UpdateTime: string>, NextToken: string>
# operationId: GetResourcePolicies
export def "get-resource-policies" [
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
  --x-amz-target: string@x-amz-target-completer-106 # required
  --body-next-token: string # A continuation token, if this is a continuation request. (spec name: NextToken)
  --body-max-results: int # The maximum size of a list to return. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetResourcePolicies"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specified resource policy.
#
# POST /
# Returns: record<PolicyInJson: string, PolicyHash: string, CreateTime: string, UpdateTime: string>
# operationId: GetResourcePolicy
export def "get-resource-policy" [
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
  --x-amz-target: string@x-amz-target-completer-107 # required
  --resource-arn: string # The ARN of the Glue resource for which to retrieve the resource policy. If not supplied, the Data Catalog resource policy is returned. Use GetResourcePolicies to view all existing resource policies. For more information see Specifying Glue Resource ARNs (https://docs.aws.amazon.com/glue/latest/dg/glue-specifying-resource-arns.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetResourcePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the specified schema in detail.
#
# POST /
# Returns: record<RegistryName: string, RegistryArn: string, SchemaName: string, SchemaArn: string, Description: string, DataFormat: string, Compatibility: string, SchemaCheckpoint: int, LatestSchemaVersion: int, NextSchemaVersion: int, SchemaStatus: string, CreatedTime: string, UpdatedTime: string>
# operationId: GetSchema
export def "get-schema" [
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
  --x-amz-target: string@x-amz-target-completer-108 # required
  schema_id: record # The unique ID of the schema in the Glue schema registry. — shape: {SchemaArn?: string, SchemaName?: string, RegistryName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetSchema"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaId, var: schema_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, schema_id: $schema_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a schema by the SchemaDefinition. The schema definition is sent to the Schema Registry, canonicalized, and hashed. If the hash is matched within the scope of the SchemaName or ARN (or the default registry, if none is supplied), that schema’s metadata is returned. Otherwise, a 404 or NotFound error is returned. Schema versions in Deleted statuses will not be included in the results.
#
# POST /
# Returns: record<SchemaVersionId: string, SchemaArn: string, DataFormat: string, Status: string, CreatedTime: string>
# operationId: GetSchemaByDefinition
export def "get-schema-by-definition" [
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
  --x-amz-target: string@x-amz-target-completer-109 # required
  schema_id: record # The unique ID of the schema in the Glue schema registry. — shape: {SchemaArn?: string, SchemaName?: string, RegistryName?: string}
  schema_definition: string # The definition of the schema for which schema details are required.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetSchemaByDefinition"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaId, var: schema_id}, {name: SchemaDefinition, var: schema_definition}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, schema_id: $schema_id, schema_definition: $schema_definition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the specified schema by its unique ID assigned when a version of the schema is created or registered. Schema versions in Deleted status will not be included in the results.
#
# POST /
# Returns: record<SchemaVersionId: string, SchemaDefinition: string, DataFormat: string, SchemaArn: string, VersionNumber: int, Status: string, CreatedTime: string>
# operationId: GetSchemaVersion
export def "get-schema-version" [
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
  --x-amz-target: string@x-amz-target-completer-110 # required
  --schema-id: record # The unique ID of the schema in the Glue schema registry. — shape: {SchemaArn?: string, SchemaName?: string, RegistryName?: string}
  --schema-version-id: string # The SchemaVersionId of the schema version. This field is required for fetching by schema ID. Either this or the SchemaId wrapper has to be provided.
  --schema-version-number: record # A structure containing the schema version information. — shape: {LatestVersion?: bool, VersionNumber?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetSchemaVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaId, var: schema_id}, {name: SchemaVersionId, var: schema_version_id}, {name: SchemaVersionNumber, var: schema_version_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, schema_id: $schema_id, schema_version_id: $schema_version_id, schema_version_number: $schema_version_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the schema version difference in the specified difference type between two stored schema versions in the Schema Registry. This API allows you to compare two schema versions between two schema definitions under the same schema.
#
# POST /
# Returns: record<Diff: string>
# operationId: GetSchemaVersionsDiff
export def "get-schema-versions-diff" [
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
  --x-amz-target: string@x-amz-target-completer-111 # required
  schema_id: record # The unique ID of the schema in the Glue schema registry. — shape: {SchemaArn?: string, SchemaName?: string, RegistryName?: string}
  first_schema_version_number: record # A structure containing the schema version information. — shape: {LatestVersion?: bool, VersionNumber?: int}
  second_schema_version_number: record # A structure containing the schema version information. — shape: {LatestVersion?: bool, VersionNumber?: int}
  schema_diff_type: string@schema-diff-type-completer # Refers to SYNTAX_DIFF, which is the currently supported diff type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetSchemaVersionsDiff"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaId, var: schema_id}, {name: FirstSchemaVersionNumber, var: first_schema_version_number}, {name: SecondSchemaVersionNumber, var: second_schema_version_number}, {name: SchemaDiffType, var: schema_diff_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, schema_id: $schema_id, first_schema_version_number: $first_schema_version_number, second_schema_version_number: $second_schema_version_number, schema_diff_type: $schema_diff_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specified security configuration.
#
# POST /
# Returns: record<SecurityConfiguration: record<Name: string, CreatedTimeStamp: string, EncryptionConfiguration: record<S3Encryption: list, CloudWatchEncryption: record, JobBookmarksEncryption: record>>>
# operationId: GetSecurityConfiguration
export def "get-security-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-112 # required
  name: string # The name of the security configuration to retrieve.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetSecurityConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of all security configurations.
#
# POST /
# Returns: record<SecurityConfigurations: table<Name: string, CreatedTimeStamp: string, EncryptionConfiguration: record>, NextToken: string>
# operationId: GetSecurityConfigurations
export def "get-security-configurations" [
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
  --x-amz-target: string@x-amz-target-completer-113 # required
  --body-max-results: int # The maximum number of results to return. (spec name: MaxResults)
  --body-next-token: string # A continuation token, if this is a continuation call. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetSecurityConfigurations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the session.
#
# POST /
# Returns: record<Session: record<Id: string, CreatedOn: string, Status: string, ErrorMessage: string, Description: string, Role: string, Command: record<Name: string, PythonVersion: string>, DefaultArguments: record, Connections: record<Connections: list>, Progress: float, MaxCapacity: float, SecurityConfiguration: string, GlueVersion: string>>
# operationId: GetSession
export def "get-session" [
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
  --x-amz-target: string@x-amz-target-completer-114 # required
  id: string # The ID of the session.
  --request-origin: string # The origin of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetSession"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: RequestOrigin, var: request_origin}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, request_origin: $request_origin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the statement.
#
# POST /
# Returns: record<Statement: record<Id: int, Code: string, State: string, Output: record<Data: record, ExecutionCount: int, Status: string, ErrorName: string, ErrorValue: string, Traceback: list>, Progress: float, StartedOn: int, CompletedOn: int>>
# operationId: GetStatement
export def "get-statement" [
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
  --x-amz-target: string@x-amz-target-completer-115 # required
  session_id: string # The Session ID of the statement.
  id: int # The Id of the statement.
  --request-origin: string # The origin of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetStatement"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SessionId, var: session_id}, {name: Id, var: id}, {name: RequestOrigin, var: request_origin}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, session_id: $session_id, id: $id, request_origin: $request_origin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the Table definition in a Data Catalog for a specified table.
#
# POST /
# Returns: record<Table: record<Name: string, DatabaseName: string, Description: string, Owner: string, CreateTime: string, UpdateTime: string, LastAccessTime: string, LastAnalyzedTime: string, Retention: int, StorageDescriptor: record<Columns: list, Location: string, AdditionalLocations: list, InputFormat: string, OutputFormat: string, Compressed: bool, NumberOfBuckets: int, SerdeInfo: record, BucketColumns: list, SortColumns: list, Parameters: record, SkewedInfo: record, StoredAsSubDirectories: bool, SchemaReference: record>, PartitionKeys: list<record>, ViewOriginalText: string, ViewExpandedText: string, TableType: string, Parameters: record, CreatedBy: string, IsRegisteredWithLakeFormation: bool, TargetTable: record<CatalogId: string, DatabaseName: string, Name: string>, CatalogId: string, VersionId: string, FederatedTable: record<Identifier: string, DatabaseIdentifier: string, ConnectionName: string>>>
# operationId: GetTable
export def "get-table" [
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
  --x-amz-target: string@x-amz-target-completer-116 # required
  --catalog-id: string # The ID of the Data Catalog where the table resides. If none is provided, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the database in the catalog in which the table resides. For Hive compatibility, this name is entirely lowercase.
  name: string # The name of the table for which to retrieve the definition. For Hive compatibility, this name is entirely lowercase.
  --transaction-id: string # The transaction ID at which to read the table contents.
  --query-as-of-time: string # The time as of when to read the table contents. If not set, the most recent transaction commit time will be used. Cannot be specified along with TransactionId. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetTable"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: Name, var: name}, {name: TransactionId, var: transaction_id}, {name: QueryAsOfTime, var: query_as_of_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, name: $name, transaction_id: $transaction_id, query_as_of_time: $query_as_of_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specified version of a table.
#
# POST /
# Returns: record<TableVersion: record<Table: record<Name: string, DatabaseName: string, Description: string, Owner: string, CreateTime: string, UpdateTime: string, LastAccessTime: string, LastAnalyzedTime: string, Retention: int, StorageDescriptor: record, PartitionKeys: list, ViewOriginalText: string, ViewExpandedText: string, TableType: string, Parameters: record, CreatedBy: string, IsRegisteredWithLakeFormation: bool, TargetTable: record, CatalogId: string, VersionId: string, FederatedTable: record>, VersionId: string>>
# operationId: GetTableVersion
export def "get-table-version" [
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
  --x-amz-target: string@x-amz-target-completer-117 # required
  --catalog-id: string # The ID of the Data Catalog where the tables reside. If none is provided, the Amazon Web Services account ID is used by default.
  database_name: string # The database in the catalog in which the table resides. For Hive compatibility, this name is entirely lowercase.
  table_name: string # The name of the table. For Hive compatibility, this name is entirely lowercase.
  --version-id: string # The ID value of the table version to be retrieved. A VersionID is a string representation of an integer. Each version is incremented by 1.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetTableVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: VersionId, var: version_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of strings that identify available versions of a specified table.
#
# POST /
# Returns: record<TableVersions: table<Table: record, VersionId: string>, NextToken: string>
# operationId: GetTableVersions
export def "get-table-versions" [
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
  --x-amz-target: string@x-amz-target-completer-118 # required
  --catalog-id: string # The ID of the Data Catalog where the tables reside. If none is provided, the Amazon Web Services account ID is used by default.
  database_name: string # The database in the catalog in which the table resides. For Hive compatibility, this name is entirely lowercase.
  table_name: string # The name of the table. For Hive compatibility, this name is entirely lowercase.
  --body-next-token: string # A continuation token, if this is not the first call. (spec name: NextToken)
  --body-max-results: int # The maximum number of table versions to return in one response. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetTableVersions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the definitions of some or all of the tables in a given Database.
#
# POST /
# Returns: record<TableList: table<Name: string, DatabaseName: string, Description: string, Owner: string, CreateTime: string, UpdateTime: string, LastAccessTime: string, LastAnalyzedTime: string, Retention: int, StorageDescriptor: record, PartitionKeys: list, ViewOriginalText: string, ViewExpandedText: string, TableType: string, Parameters: record, CreatedBy: string, IsRegisteredWithLakeFormation: bool, TargetTable: record, CatalogId: string, VersionId: string, FederatedTable: record>, NextToken: string>
# operationId: GetTables
export def "get-tables" [
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
  --x-amz-target: string@x-amz-target-completer-119 # required
  --catalog-id: string # The ID of the Data Catalog where the tables reside. If none is provided, the Amazon Web Services account ID is used by default.
  database_name: string # The database in the catalog whose tables to list. For Hive compatibility, this name is entirely lowercase.
  --expression: string # A regular expression pattern. If present, only those tables whose names match the pattern are returned.
  --body-next-token: string # A continuation token, included if this is a continuation call. (spec name: NextToken)
  --body-max-results: int # The maximum number of tables to return in a single response. (spec name: MaxResults)
  --transaction-id: string # The transaction ID at which to read the table contents.
  --query-as-of-time: string # The time as of when to read the table contents. If not set, the most recent transaction commit time will be used. Cannot be specified along with TransactionId. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetTables"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: Expression, var: expression}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: TransactionId, var: transaction_id}, {name: QueryAsOfTime, var: query_as_of_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, expression: $expression, body_next_token: $body_next_token, body_max_results: $body_max_results, transaction_id: $transaction_id, query_as_of_time: $query_as_of_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of tags associated with a resource.
#
# POST /
# Returns: record<Tags: record>
# operationId: GetTags
export def "get-tags" [
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
  --x-amz-target: string@x-amz-target-completer-120 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource for which to retrieve tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetTags"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the definition of a trigger.
#
# POST /
# Returns: record<Trigger: record<Name: string, WorkflowName: string, Id: string, Type: string, State: string, Description: string, Schedule: string, Actions: list<record>, Predicate: record<Logical: string, Conditions: list>, EventBatchingCondition: record<BatchSize: int, BatchWindow: int>>>
# operationId: GetTrigger
export def "get-trigger" [
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
  --x-amz-target: string@x-amz-target-completer-121 # required
  name: string # The name of the trigger to retrieve.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetTrigger"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the triggers associated with a job.
#
# POST /
# Returns: record<Triggers: table<Name: string, WorkflowName: string, Id: string, Type: string, State: string, Description: string, Schedule: string, Actions: list, Predicate: record, EventBatchingCondition: record>, NextToken: string>
# operationId: GetTriggers
export def "get-triggers" [
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
  --x-amz-target: string@x-amz-target-completer-122 # required
  --body-next-token: string # A continuation token, if this is a continuation call. (spec name: NextToken)
  --dependent-job-name: string # The name of the job to retrieve triggers for. The trigger that can start this job is returned, and if there is no such trigger, all triggers are returned.
  --body-max-results: int # The maximum size of the response. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetTriggers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: DependentJobName, var: dependent_job_name}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, dependent_job_name: $dependent_job_name, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves partition metadata from the Data Catalog that contains unfiltered metadata. For IAM authorization, the public IAM action associated with this API is glue:GetPartition.
#
# POST /
# Returns: record<Partition: record<Values: list<string>, DatabaseName: string, TableName: string, CreationTime: string, LastAccessTime: string, StorageDescriptor: record<Columns: list, Location: string, AdditionalLocations: list, InputFormat: string, OutputFormat: string, Compressed: bool, NumberOfBuckets: int, SerdeInfo: record, BucketColumns: list, SortColumns: list, Parameters: record, SkewedInfo: record, StoredAsSubDirectories: bool, SchemaReference: record>, Parameters: record, LastAnalyzedTime: string, CatalogId: string>, AuthorizedColumns: list<string>, IsRegisteredWithLakeFormation: bool>
# operationId: GetUnfilteredPartitionMetadata
export def "get-unfiltered-partition-metadata" [
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
  --x-amz-target: string@x-amz-target-completer-123 # required
  catalog_id: string # The catalog ID where the partition resides.
  database_name: string # (Required) Specifies the name of a database that contains the partition.
  table_name: string # (Required) Specifies the name of a table that contains the partition.
  partition_values: list<string> # (Required) A list of partition key values.
  --audit-context: record # A structure containing the Lake Formation audit context. — shape: {AdditionalAuditContext?: string, RequestedColumns?: list<string>, AllColumnsRequested?: bool}
  supported_permission_types: list<string> # (Required) A list of supported permission types.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetUnfilteredPartitionMetadata"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: PartitionValues, var: partition_values}, {name: AuditContext, var: audit_context}, {name: SupportedPermissionTypes, var: supported_permission_types}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, partition_values: $partition_values, audit_context: $audit_context, supported_permission_types: $supported_permission_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves partition metadata from the Data Catalog that contains unfiltered metadata. For IAM authorization, the public IAM action associated with this API is glue:GetPartitions.
#
# POST /
# Returns: record<UnfilteredPartitions: table<Partition: record, AuthorizedColumns: list, IsRegisteredWithLakeFormation: bool>, NextToken: string>
# operationId: GetUnfilteredPartitionsMetadata
export def "get-unfiltered-partitions-metadata" [
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
  --x-amz-target: string@x-amz-target-completer-124 # required
  catalog_id: string # The ID of the Data Catalog where the partitions in question reside. If none is provided, the AWS account ID is used by default.
  database_name: string # The name of the catalog database where the partitions reside.
  table_name: string # The name of the table that contains the partition.
  --expression: string # An expression that filters the partitions to be returned. The expression uses SQL syntax similar to the SQL WHERE filter clause. The SQL statement parser JSQLParser (http://jsqlparser.sourceforge.net/home.php) parses the expression. Operators: The following are the operators that you can use in the Expression API call: = Checks whether the values of the two operands are equal; if yes, then the condition becomes true. Example: Assume 'variable a' holds 10 and 'variable b' holds 20. (a = b) is not true. < > Checks whether the values of two operands are equal; if the values are not equal, then the condition becomes true. Example: (a < > b) is true. > Checks whether the value of the left operand is greater than the value of the right operand; if yes, then the condition becomes true. Example: (a > b) is not true. < Checks whether the value of the left operand is less than the value of the right operand; if yes, then the condition becomes true. Example: (a < b) is true. >= Checks whether the value of the left operand is greater than or equal to the value of the right operand; if yes, then the condition becomes true. Example: (a >= b) is not true. <= Checks whether the value of the left operand is less than or equal to the value of the right operand; if yes, then the condition becomes true. Example: (a <= b) is true. AND, OR, IN, BETWEEN, LIKE, NOT, IS NULL Logical operators. Supported Partition Key Types: The following are the supported partition keys. string date timestamp int bigint long tinyint smallint decimal If an type is encountered that is not valid, an exception is thrown.
  --audit-context: record # A structure containing the Lake Formation audit context. — shape: {AdditionalAuditContext?: string, RequestedColumns?: list<string>, AllColumnsRequested?: bool}
  supported_permission_types: list<string> # A list of supported permission types.
  --body-next-token: string # A continuation token, if this is not the first call to retrieve these partitions. (spec name: NextToken)
  --segment: record # Defines a non-overlapping region of a table's partitions, allowing multiple requests to be run in parallel. — shape: {SegmentNumber: int, TotalSegments: int}
  --body-max-results: int # The maximum number of partitions to return in a single response. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetUnfilteredPartitionsMetadata"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: Expression, var: expression}, {name: AuditContext, var: audit_context}, {name: SupportedPermissionTypes, var: supported_permission_types}, {name: NextToken, var: body_next_token}, {name: Segment, var: segment}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, expression: $expression, audit_context: $audit_context, supported_permission_types: $supported_permission_types, body_next_token: $body_next_token, segment: $segment, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves table metadata from the Data Catalog that contains unfiltered metadata. For IAM authorization, the public IAM action associated with this API is glue:GetTable.
#
# POST /
# Returns: record<Table: record<Name: string, DatabaseName: string, Description: string, Owner: string, CreateTime: string, UpdateTime: string, LastAccessTime: string, LastAnalyzedTime: string, Retention: int, StorageDescriptor: record<Columns: list, Location: string, AdditionalLocations: list, InputFormat: string, OutputFormat: string, Compressed: bool, NumberOfBuckets: int, SerdeInfo: record, BucketColumns: list, SortColumns: list, Parameters: record, SkewedInfo: record, StoredAsSubDirectories: bool, SchemaReference: record>, PartitionKeys: list<record>, ViewOriginalText: string, ViewExpandedText: string, TableType: string, Parameters: record, CreatedBy: string, IsRegisteredWithLakeFormation: bool, TargetTable: record<CatalogId: string, DatabaseName: string, Name: string>, CatalogId: string, VersionId: string, FederatedTable: record<Identifier: string, DatabaseIdentifier: string, ConnectionName: string>>, AuthorizedColumns: list<string>, IsRegisteredWithLakeFormation: bool, CellFilters: table<ColumnName: string, RowFilterExpression: string>>
# operationId: GetUnfilteredTableMetadata
export def "get-unfiltered-table-metadata" [
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
  --x-amz-target: string@x-amz-target-completer-125 # required
  catalog_id: string # The catalog ID where the table resides.
  database_name: string # (Required) Specifies the name of a database that contains the table.
  name: string # (Required) Specifies the name of a table for which you are requesting metadata.
  --audit-context: record # A structure containing the Lake Formation audit context. — shape: {AdditionalAuditContext?: string, RequestedColumns?: list<string>, AllColumnsRequested?: bool}
  supported_permission_types: list<string> # (Required) A list of supported permission types.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetUnfilteredTableMetadata"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: Name, var: name}, {name: AuditContext, var: audit_context}, {name: SupportedPermissionTypes, var: supported_permission_types}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, name: $name, audit_context: $audit_context, supported_permission_types: $supported_permission_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specified function definition from the Data Catalog.
#
# POST /
# Returns: record<UserDefinedFunction: record<FunctionName: string, DatabaseName: string, ClassName: string, OwnerName: string, OwnerType: string, CreateTime: string, ResourceUris: list<record>, CatalogId: string>>
# operationId: GetUserDefinedFunction
export def "get-user-defined-function" [
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
  --x-amz-target: string@x-amz-target-completer-126 # required
  --catalog-id: string # The ID of the Data Catalog where the function to be retrieved is located. If none is provided, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database where the function is located.
  function_name: string # The name of the function.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetUserDefinedFunction"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: FunctionName, var: function_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, function_name: $function_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves multiple function definitions from the Data Catalog.
#
# POST /
# Returns: record<UserDefinedFunctions: table<FunctionName: string, DatabaseName: string, ClassName: string, OwnerName: string, OwnerType: string, CreateTime: string, ResourceUris: list, CatalogId: string>, NextToken: string>
# operationId: GetUserDefinedFunctions
export def "get-user-defined-functions" [
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
  --x-amz-target: string@x-amz-target-completer-127 # required
  --catalog-id: string # The ID of the Data Catalog where the functions to be retrieved are located. If none is provided, the Amazon Web Services account ID is used by default.
  --database-name: string # The name of the catalog database where the functions are located. If none is provided, functions from all the databases across the catalog will be returned.
  pattern: string # An optional function-name pattern string that filters the function definitions returned.
  --body-next-token: string # A continuation token, if this is a continuation call. (spec name: NextToken)
  --body-max-results: int # The maximum number of functions to return in one response. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetUserDefinedFunctions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: Pattern, var: pattern}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, pattern: $pattern, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves resource metadata for a workflow.
#
# POST /
# Returns: record<Workflow: record<Name: string, Description: string, DefaultRunProperties: record, CreatedOn: string, LastModifiedOn: string, LastRun: record<Name: string, WorkflowRunId: string, PreviousRunId: string, WorkflowRunProperties: record, StartedOn: string, CompletedOn: string, Status: string, ErrorMessage: string, Statistics: record, Graph: record, StartingEventBatchCondition: record>, Graph: record<Nodes: list, Edges: list>, MaxConcurrentRuns: int, BlueprintDetails: record<BlueprintName: string, RunId: string>>>
# operationId: GetWorkflow
export def "get-workflow" [
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
  --x-amz-target: string@x-amz-target-completer-128 # required
  name: string # The name of the workflow to retrieve.
  --include-graph: oneof<nothing, bool> # Specifies whether to include a graph when returning the workflow resource metadata.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetWorkflow"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: IncludeGraph, var: include_graph}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, include_graph: $include_graph
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the metadata for a given workflow run.
#
# POST /
# Returns: record<Run: record<Name: string, WorkflowRunId: string, PreviousRunId: string, WorkflowRunProperties: record, StartedOn: string, CompletedOn: string, Status: string, ErrorMessage: string, Statistics: record<TotalActions: int, TimeoutActions: int, FailedActions: int, StoppedActions: int, SucceededActions: int, RunningActions: int, ErroredActions: int, WaitingActions: int>, Graph: record<Nodes: list, Edges: list>, StartingEventBatchCondition: record<BatchSize: int, BatchWindow: int>>>
# operationId: GetWorkflowRun
export def "get-workflow-run" [
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
  --x-amz-target: string@x-amz-target-completer-129 # required
  name: string # Name of the workflow being run.
  run_id: string # The ID of the workflow run.
  --include-graph: oneof<nothing, bool> # Specifies whether to include the workflow graph in response or not.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetWorkflowRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: RunId, var: run_id}, {name: IncludeGraph, var: include_graph}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, run_id: $run_id, include_graph: $include_graph
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the workflow run properties which were set during the run.
#
# POST /
# Returns: record<RunProperties: record>
# operationId: GetWorkflowRunProperties
export def "get-workflow-run-properties" [
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
  --x-amz-target: string@x-amz-target-completer-130 # required
  name: string # Name of the workflow which was run.
  run_id: string # The ID of the workflow run whose run properties should be returned.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetWorkflowRunProperties"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: RunId, var: run_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, run_id: $run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves metadata for all runs of a given workflow.
#
# POST /
# Returns: record<Runs: table<Name: string, WorkflowRunId: string, PreviousRunId: string, WorkflowRunProperties: record, StartedOn: string, CompletedOn: string, Status: string, ErrorMessage: string, Statistics: record, Graph: record, StartingEventBatchCondition: record>, NextToken: string>
# operationId: GetWorkflowRuns
export def "get-workflow-runs" [
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
  --x-amz-target: string@x-amz-target-completer-131 # required
  name: string # Name of the workflow whose metadata of runs should be returned.
  --include-graph: oneof<nothing, bool> # Specifies whether to include the workflow graph in response or not.
  --body-next-token: string # The maximum size of the response. (spec name: NextToken)
  --body-max-results: int # The maximum number of workflow runs to be included in the response. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.GetWorkflowRuns"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: IncludeGraph, var: include_graph}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, include_graph: $include_graph, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Imports an existing Amazon Athena Data Catalog to Glue.
#
# POST /
# Returns: record
# operationId: ImportCatalogToGlue
export def "import-catalog-to-glue" [
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
  --x-amz-target: string@x-amz-target-completer-132 # required
  --catalog-id: string # The ID of the catalog to import. Currently, this should be the Amazon Web Services account ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ImportCatalogToGlue"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the blueprint names in an account.
#
# POST /
# Returns: record<Blueprints: list<string>, NextToken: string>
# operationId: ListBlueprints
export def "list-blueprints" [
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
  --x-amz-target: string@x-amz-target-completer-133 # required
  --body-next-token: string # A continuation token, if this is a continuation request. (spec name: NextToken)
  --body-max-results: int # The maximum size of a list to return. (spec name: MaxResults)
  --tags: record # Filters the list by an Amazon Web Services resource tag.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListBlueprints"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the names of all crawler resources in this Amazon Web Services account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names. This operation takes the optional Tags field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.
#
# POST /
# Returns: record<CrawlerNames: list<string>, NextToken: string>
# operationId: ListCrawlers
export def "list-crawlers" [
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
  --x-amz-target: string@x-amz-target-completer-134 # required
  --body-max-results: int # The maximum size of a list to return. (spec name: MaxResults)
  --body-next-token: string # A continuation token, if this is a continuation request. (spec name: NextToken)
  --tags: record # Specifies to return only these tagged resources.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListCrawlers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all the crawls of a specified crawler. Returns only the crawls that have occurred since the launch date of the crawler history feature, and only retains up to 12 months of crawls. Older crawls will not be returned. You may use this API to: Retrive all the crawls of a specified crawler. Retrieve all the crawls of a specified crawler within a limited count. Retrieve all the crawls of a specified crawler in a specific time range. Retrieve all the crawls of a specified crawler with a particular state, crawl ID, or DPU hour value.
#
# POST /
# Returns: record<Crawls: table<CrawlId: string, State: string, StartTime: string, EndTime: string, Summary: string, ErrorMessage: string, LogGroup: string, LogStream: string, MessagePrefix: string, DPUHour: float>, NextToken: string>
# operationId: ListCrawls
export def "list-crawls" [
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
  --x-amz-target: string@x-amz-target-completer-135 # required
  crawler_name: string # The name of the crawler whose runs you want to retrieve.
  --max-results: int # The maximum number of results to return. The default is 20, and maximum is 100.
  --filters: list # Filters the crawls by the criteria you specify in a list of CrawlsFilter objects. — item shape: {FieldName?: "CRAWL_ID"|"STATE"|"START_TIME"|"END_TIME"|"DPU_HOUR", FilterOperator?: "GT"|"GE"|"LT"|"LE"|"EQ"|"NE", FieldValue?: string}
  --next-token: string # A continuation token, if this is a continuation call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListCrawls"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CrawlerName, var: crawler_name}, {name: MaxResults, var: max_results}, {name: Filters, var: filters}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, crawler_name: $crawler_name, max_results: $max_results, filters: $filters, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the custom patterns that have been created.
#
# POST /
# Returns: record<CustomEntityTypes: table<Name: string, RegexString: string, ContextWords: list>, NextToken: string>
# operationId: ListCustomEntityTypes
export def "list-custom-entity-types" [
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
  --x-amz-target: string@x-amz-target-completer-136 # required
  --body-next-token: string # A paginated token to offset the results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListCustomEntityTypes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all data quality execution results for your account.
#
# POST /
# Returns: record<Results: table<ResultId: string, DataSource: record, JobName: string, JobRunId: string, StartedOn: string>, NextToken: string>
# operationId: ListDataQualityResults
export def "list-data-quality-results" [
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
  --x-amz-target: string@x-amz-target-completer-137 # required
  --filter: record # Criteria used to return data quality results. — shape: {DataSource?: record, JobName?: string, JobRunId?: string, StartedAfter?: string, StartedBefore?: string}
  --body-next-token: string # A paginated token to offset the results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListDataQualityResults"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the recommendation runs meeting the filter criteria.
#
# POST /
# Returns: record<Runs: table<RunId: string, Status: string, StartedOn: string, DataSource: record>, NextToken: string>
# operationId: ListDataQualityRuleRecommendationRuns
export def "list-data-quality-rule-recommendation-runs" [
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
  --x-amz-target: string@x-amz-target-completer-138 # required
  --filter: record # A filter for listing data quality recommendation runs. — shape: {DataSource: record, StartedBefore?: string, StartedAfter?: string}
  --body-next-token: string # A paginated token to offset the results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListDataQualityRuleRecommendationRuns"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the runs meeting the filter criteria, where a ruleset is evaluated against a data source.
#
# POST /
# Returns: record<Runs: table<RunId: string, Status: string, StartedOn: string, DataSource: record>, NextToken: string>
# operationId: ListDataQualityRulesetEvaluationRuns
export def "list-data-quality-ruleset-evaluation-runs" [
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
  --x-amz-target: string@x-amz-target-completer-139 # required
  --filter: record # The filter criteria. — shape: {DataSource: record, StartedBefore?: string, StartedAfter?: string}
  --body-next-token: string # A paginated token to offset the results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListDataQualityRulesetEvaluationRuns"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of rulesets for the specified list of Glue tables.
#
# POST /
# Returns: record<Rulesets: table<Name: string, Description: string, CreatedOn: string, LastModifiedOn: string, TargetTable: record, RecommendationRunId: string, RuleCount: int>, NextToken: string>
# operationId: ListDataQualityRulesets
export def "list-data-quality-rulesets" [
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
  --x-amz-target: string@x-amz-target-completer-140 # required
  --body-next-token: string # A paginated token to offset the results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return. (spec name: MaxResults)
  --filter: record # The criteria used to filter data quality rulesets. — shape: {Name?: string, Description?: string, CreatedBefore?: string, CreatedAfter?: string, LastModifiedBefore?: string, LastModifiedAfter?: string, TargetTable?: record}
  --tags: record # A list of key-value pair tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListDataQualityRulesets"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filter, var: filter}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, filter: $filter, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the names of all DevEndpoint resources in this Amazon Web Services account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names. This operation takes the optional Tags field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.
#
# POST /
# Returns: record<DevEndpointNames: list<string>, NextToken: string>
# operationId: ListDevEndpoints
export def "list-dev-endpoints" [
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
  --x-amz-target: string@x-amz-target-completer-141 # required
  --body-next-token: string # A continuation token, if this is a continuation request. (spec name: NextToken)
  --body-max-results: int # The maximum size of a list to return. (spec name: MaxResults)
  --tags: record # Specifies to return only these tagged resources.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListDevEndpoints"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the names of all job resources in this Amazon Web Services account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names. This operation takes the optional Tags field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.
#
# POST /
# Returns: record<JobNames: list<string>, NextToken: string>
# operationId: ListJobs
export def "list-jobs" [
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
  --x-amz-target: string@x-amz-target-completer-142 # required
  --body-next-token: string # A continuation token, if this is a continuation request. (spec name: NextToken)
  --body-max-results: int # The maximum size of a list to return. (spec name: MaxResults)
  --tags: record # Specifies to return only these tagged resources.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a sortable, filterable list of existing Glue machine learning transforms in this Amazon Web Services account, or the resources with the specified tag. This operation takes the optional Tags field, which you can use as a filter of the responses so that tagged resources can be retrieved as a group. If you choose to use tag filtering, only resources with the tags are retrieved.
#
# POST /
# Returns: record<TransformIds: list<string>, NextToken: string>
# operationId: ListMLTransforms
export def "list-ml-transforms" [
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
  --x-amz-target: string@x-amz-target-completer-143 # required
  --body-next-token: string # A continuation token, if this is a continuation request. (spec name: NextToken)
  --body-max-results: int # The maximum size of a list to return. (spec name: MaxResults)
  --filter: record # The criteria used to filter the machine learning transforms. — shape: {Name?: string, TransformType?: "FIND_MATCHES", Status?: "NOT_READY"|"READY"|"DELETING", GlueVersion?: string, CreatedBefore?: string, CreatedAfter?: string, LastModifiedBefore?: string, LastModifiedAfter?: string, Schema?: list}
  --sort: record # The sorting criteria that are associated with the machine learning transform. — shape: {Column: "NAME"|"TRANSFORM_TYPE"|"STATUS"|"CREATED"|"LAST_MODIFIED", SortDirection: "DESCENDING"|"ASCENDING"}
  --tags: record # Specifies to return only these tagged resources.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListMLTransforms"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filter, var: filter}, {name: Sort, var: sort}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, filter: $filter, sort: $sort, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of registries that you have created, with minimal registry information. Registries in the Deleting status will not be included in the results. Empty results will be returned if there are no registries available.
#
# POST /
# Returns: record<Registries: table<RegistryName: string, RegistryArn: string, Description: string, Status: string, CreatedTime: string, UpdatedTime: string>, NextToken: string>
# operationId: ListRegistries
export def "list-registries" [
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
  --x-amz-target: string@x-amz-target-completer-144 # required
  --body-max-results: int # Maximum number of results required per page. If the value is not supplied, this will be defaulted to 25 per page. (spec name: MaxResults)
  --body-next-token: string # A continuation token, if this is a continuation call. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListRegistries"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of schema versions that you have created, with minimal information. Schema versions in Deleted status will not be included in the results. Empty results will be returned if there are no schema versions available.
#
# POST /
# Returns: record<Schemas: table<SchemaArn: string, SchemaVersionId: string, VersionNumber: int, Status: string, CreatedTime: string>, NextToken: string>
# operationId: ListSchemaVersions
export def "list-schema-versions" [
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
  --x-amz-target: string@x-amz-target-completer-145 # required
  schema_id: record # The unique ID of the schema in the Glue schema registry. — shape: {SchemaArn?: string, SchemaName?: string, RegistryName?: string}
  --body-max-results: int # Maximum number of results required per page. If the value is not supplied, this will be defaulted to 25 per page. (spec name: MaxResults)
  --body-next-token: string # A continuation token, if this is a continuation call. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListSchemaVersions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaId, var: schema_id}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, schema_id: $schema_id, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of schemas with minimal details. Schemas in Deleting status will not be included in the results. Empty results will be returned if there are no schemas available. When the RegistryId is not provided, all the schemas across registries will be part of the API response.
#
# POST /
# Returns: record<Schemas: table<RegistryName: string, SchemaName: string, SchemaArn: string, Description: string, SchemaStatus: string, CreatedTime: string, UpdatedTime: string>, NextToken: string>
# operationId: ListSchemas
export def "list-schemas" [
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
  --x-amz-target: string@x-amz-target-completer-146 # required
  --registry-id: record # A wrapper structure that may contain the registry name and Amazon Resource Name (ARN). — shape: {RegistryName?: string, RegistryArn?: string}
  --body-max-results: int # Maximum number of results required per page. If the value is not supplied, this will be defaulted to 25 per page. (spec name: MaxResults)
  --body-next-token: string # A continuation token, if this is a continuation call. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListSchemas"}]
    body: {content_type: "application/json", kind: json, fields: [{name: RegistryId, var: registry_id}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, registry_id: $registry_id, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of sessions.
#
# POST /
# Returns: record<Ids: list<string>, Sessions: table<Id: string, CreatedOn: string, Status: string, ErrorMessage: string, Description: string, Role: string, Command: record, DefaultArguments: record, Connections: record, Progress: float, MaxCapacity: float, SecurityConfiguration: string, GlueVersion: string>, NextToken: string>
# operationId: ListSessions
export def "list-sessions" [
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
  --x-amz-target: string@x-amz-target-completer-147 # required
  --body-next-token: string # The token for the next set of results, or null if there are no more result. (spec name: NextToken)
  --body-max-results: int # The maximum number of results. (spec name: MaxResults)
  --tags: record # Tags belonging to the session.
  --request-origin: string # The origin of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListSessions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Tags, var: tags}, {name: RequestOrigin, var: request_origin}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, tags: $tags, request_origin: $request_origin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists statements for the session.
#
# POST /
# Returns: record<Statements: table<Id: int, Code: string, State: string, Output: record, Progress: float, StartedOn: int, CompletedOn: int>, NextToken: string>
# operationId: ListStatements
export def "list-statements" [
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
  --x-amz-target: string@x-amz-target-completer-148 # required
  session_id: string # The Session ID of the statements.
  --request-origin: string # The origin of the request to list statements.
  --next-token: string # A continuation token, if this is a continuation call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListStatements"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SessionId, var: session_id}, {name: RequestOrigin, var: request_origin}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, session_id: $session_id, request_origin: $request_origin, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the names of all trigger resources in this Amazon Web Services account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names. This operation takes the optional Tags field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.
#
# POST /
# Returns: record<TriggerNames: list<string>, NextToken: string>
# operationId: ListTriggers
export def "list-triggers" [
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
  --x-amz-target: string@x-amz-target-completer-149 # required
  --body-next-token: string # A continuation token, if this is a continuation request. (spec name: NextToken)
  --dependent-job-name: string # The name of the job for which to retrieve triggers. The trigger that can start this job is returned. If there is no such trigger, all triggers are returned.
  --body-max-results: int # The maximum size of a list to return. (spec name: MaxResults)
  --tags: record # Specifies to return only these tagged resources.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListTriggers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: DependentJobName, var: dependent_job_name}, {name: MaxResults, var: body_max_results}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, dependent_job_name: $dependent_job_name, body_max_results: $body_max_results, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists names of workflows created in the account.
#
# POST /
# Returns: record<Workflows: list<string>, NextToken: string>
# operationId: ListWorkflows
export def "list-workflows" [
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
  --x-amz-target: string@x-amz-target-completer-150 # required
  --body-next-token: string # A continuation token, if this is a continuation request. (spec name: NextToken)
  --body-max-results: int # The maximum size of a list to return. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ListWorkflows"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
#
# POST /
# Returns: record
# operationId: PutDataCatalogEncryptionSettings
export def "put-data-catalog-encryption-settings" [
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
  --x-amz-target: string@x-amz-target-completer-151 # required
  --catalog-id: string # The ID of the Data Catalog to set the security configuration for. If none is provided, the Amazon Web Services account ID is used by default.
  data_catalog_encryption_settings: record # Contains configuration information for maintaining Data Catalog security. — shape: {EncryptionAtRest?: record, ConnectionPasswordEncryption?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.PutDataCatalogEncryptionSettings"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DataCatalogEncryptionSettings, var: data_catalog_encryption_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, data_catalog_encryption_settings: $data_catalog_encryption_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the Data Catalog resource policy for access control.
#
# POST /
# Returns: record<PolicyHash: string>
# operationId: PutResourcePolicy
export def "put-resource-policy" [
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
  --x-amz-target: string@x-amz-target-completer-152 # required
  policy_in_json: string # Contains the policy document to set, in JSON format.
  --resource-arn: string # Do not use. For internal use only.
  --policy-hash-condition: string # The hash value returned when the previous policy was set using PutResourcePolicy. Its purpose is to prevent concurrent modifications of a policy. Do not use this parameter if no previous policy has been set.
  --policy-exists-condition: string@policy-exists-condition-completer # A value of MUST_EXIST is used to update a policy. A value of NOT_EXIST is used to create a new policy. If a value of NONE or a null value is used, the call does not depend on the existence of a policy.
  --enable-hybrid: string@enable-hybrid-completer # If 'TRUE', indicates that you are using both methods to grant cross-account access to Data Catalog resources: By directly updating the resource policy with PutResourePolicy By using the Grant permissions command on the Amazon Web Services Management Console. Must be set to 'TRUE' if you have already used the Management Console to grant cross-account access, otherwise the call fails. Default is 'FALSE'.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.PutResourcePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PolicyInJson, var: policy_in_json}, {name: ResourceArn, var: resource_arn}, {name: PolicyHashCondition, var: policy_hash_condition}, {name: PolicyExistsCondition, var: policy_exists_condition}, {name: EnableHybrid, var: enable_hybrid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, policy_in_json: $policy_in_json, resource_arn: $resource_arn, policy_hash_condition: $policy_hash_condition, policy_exists_condition: $policy_exists_condition, enable_hybrid: $enable_hybrid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Puts the metadata key value pair for a specified schema version ID. A maximum of 10 key value pairs will be allowed per schema version. They can be added over one or more calls.
#
# POST /
# Returns: record<SchemaArn: string, SchemaName: string, RegistryName: string, LatestVersion: bool, VersionNumber: int, SchemaVersionId: string, MetadataKey: string, MetadataValue: string>
# operationId: PutSchemaVersionMetadata
export def "put-schema-version-metadata" [
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
  --x-amz-target: string@x-amz-target-completer-153 # required
  --schema-id: record # The unique ID of the schema in the Glue schema registry. — shape: {SchemaArn?: string, SchemaName?: string, RegistryName?: string}
  --schema-version-number: record # A structure containing the schema version information. — shape: {LatestVersion?: bool, VersionNumber?: int}
  --schema-version-id: string # The unique version ID of the schema version.
  metadata_key_value: record # A structure containing a key value pair for metadata. — shape: {MetadataKey?: string, MetadataValue?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.PutSchemaVersionMetadata"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaId, var: schema_id}, {name: SchemaVersionNumber, var: schema_version_number}, {name: SchemaVersionId, var: schema_version_id}, {name: MetadataKeyValue, var: metadata_key_value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, schema_id: $schema_id, schema_version_number: $schema_version_number, schema_version_id: $schema_version_id, metadata_key_value: $metadata_key_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
#
# POST /
# Returns: record
# operationId: PutWorkflowRunProperties
export def "put-workflow-run-properties" [
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
  --x-amz-target: string@x-amz-target-completer-154 # required
  name: string # Name of the workflow which was run.
  run_id: string # The ID of the workflow run for which the run properties should be updated.
  run_properties: record # The properties to put for the specified run.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.PutWorkflowRunProperties"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: RunId, var: run_id}, {name: RunProperties, var: run_properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, run_id: $run_id, run_properties: $run_properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Queries for the schema version metadata information.
#
# POST /
# Returns: record<MetadataInfoMap: record, SchemaVersionId: string, NextToken: string>
# operationId: QuerySchemaVersionMetadata
export def "query-schema-version-metadata" [
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
  --x-amz-target: string@x-amz-target-completer-155 # required
  --schema-id: record # The unique ID of the schema in the Glue schema registry. — shape: {SchemaArn?: string, SchemaName?: string, RegistryName?: string}
  --schema-version-number: record # A structure containing the schema version information. — shape: {LatestVersion?: bool, VersionNumber?: int}
  --schema-version-id: string # The unique version ID of the schema version.
  --metadata-list: list # Search key-value pairs for metadata, if they are not provided all the metadata information will be fetched. — item shape: {MetadataKey?: string, MetadataValue?: string}
  --max-results: int # Maximum number of results required per page. If the value is not supplied, this will be defaulted to 25 per page.
  --next-token: string # A continuation token, if this is a continuation call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.QuerySchemaVersionMetadata"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaId, var: schema_id}, {name: SchemaVersionNumber, var: schema_version_number}, {name: SchemaVersionId, var: schema_version_id}, {name: MetadataList, var: metadata_list}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, schema_id: $schema_id, schema_version_number: $schema_version_number, schema_version_id: $schema_version_id, metadata_list: $metadata_list, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new version to the existing schema. Returns an error if new version of schema does not meet the compatibility requirements of the schema set. This API will not create a new schema set and will return a 404 error if the schema set is not already present in the Schema Registry. If this is the first schema definition to be registered in the Schema Registry, this API will store the schema version and return immediately. Otherwise, this call has the potential to run longer than other operations due to compatibility modes. You can call the GetSchemaVersion API with the SchemaVersionId to check compatibility modes. If the same schema definition is already stored in Schema Registry as a version, the schema ID of the existing schema is returned to the caller.
#
# POST /
# Returns: record<SchemaVersionId: string, VersionNumber: int, Status: string>
# operationId: RegisterSchemaVersion
export def "register-schema-version" [
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
  --x-amz-target: string@x-amz-target-completer-156 # required
  schema_id: record # The unique ID of the schema in the Glue schema registry. — shape: {SchemaArn?: string, SchemaName?: string, RegistryName?: string}
  schema_definition: string # The schema definition using the DataFormat setting for the SchemaName.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.RegisterSchemaVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaId, var: schema_id}, {name: SchemaDefinition, var: schema_definition}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, schema_id: $schema_id, schema_definition: $schema_definition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a key value pair from the schema version metadata for the specified schema version ID.
#
# POST /
# Returns: record<SchemaArn: string, SchemaName: string, RegistryName: string, LatestVersion: bool, VersionNumber: int, SchemaVersionId: string, MetadataKey: string, MetadataValue: string>
# operationId: RemoveSchemaVersionMetadata
export def "remove-schema-version-metadata" [
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
  --x-amz-target: string@x-amz-target-completer-157 # required
  --schema-id: record # The unique ID of the schema in the Glue schema registry. — shape: {SchemaArn?: string, SchemaName?: string, RegistryName?: string}
  --schema-version-number: record # A structure containing the schema version information. — shape: {LatestVersion?: bool, VersionNumber?: int}
  --schema-version-id: string # The unique version ID of the schema version.
  metadata_key_value: record # A structure containing a key value pair for metadata. — shape: {MetadataKey?: string, MetadataValue?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.RemoveSchemaVersionMetadata"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaId, var: schema_id}, {name: SchemaVersionNumber, var: schema_version_number}, {name: SchemaVersionId, var: schema_version_id}, {name: MetadataKeyValue, var: metadata_key_value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, schema_id: $schema_id, schema_version_number: $schema_version_number, schema_version_id: $schema_version_id, metadata_key_value: $metadata_key_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resets a bookmark entry. For more information about enabling and using job bookmarks, see: Tracking processed data using job bookmarks (https://docs.aws.amazon.com/glue/latest/dg/monitor-continuations.html) Job parameters used by Glue (https://docs.aws.amazon.com/glue/latest/dg/aws-glue-programming-etl-glue-arguments.html) Job structure (https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html#aws-glue-api-jobs-job-Job)
#
# POST /
# Returns: record<JobBookmarkEntry: record<JobName: string, Version: int, Run: int, Attempt: int, PreviousRunId: string, RunId: string, JobBookmark: string>>
# operationId: ResetJobBookmark
export def "reset-job-bookmark" [
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
  --x-amz-target: string@x-amz-target-completer-158 # required
  job_name: string # The name of the job in question.
  --run-id: string # The unique run identifier associated with this job run.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ResetJobBookmark"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobName, var: job_name}, {name: RunId, var: run_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_name: $job_name, run_id: $run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restarts selected nodes of a previous partially completed workflow run and resumes the workflow run. The selected nodes and all nodes that are downstream from the selected nodes are run.
#
# POST /
# Returns: record<RunId: string, NodeIds: list<string>>
# operationId: ResumeWorkflowRun
export def "resume-workflow-run" [
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
  --x-amz-target: string@x-amz-target-completer-159 # required
  name: string # The name of the workflow to resume.
  run_id: string # The ID of the workflow run to resume.
  node_ids: list<string> # A list of the node IDs for the nodes you want to restart. The nodes that are to be restarted must have a run attempt in the original run.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.ResumeWorkflowRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: RunId, var: run_id}, {name: NodeIds, var: node_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, run_id: $run_id, node_ids: $node_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Executes the statement.
#
# POST /
# Returns: record<Id: int>
# operationId: RunStatement
export def "run-statement" [
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
  --x-amz-target: string@x-amz-target-completer-160 # required
  session_id: string # The Session Id of the statement to be run.
  code: string # The statement code to be run.
  --request-origin: string # The origin of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.RunStatement"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SessionId, var: session_id}, {name: Code, var: code}, {name: RequestOrigin, var: request_origin}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, session_id: $session_id, code: $code, request_origin: $request_origin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search.
#
# POST /
# Returns: record<NextToken: string, TableList: table<Name: string, DatabaseName: string, Description: string, Owner: string, CreateTime: string, UpdateTime: string, LastAccessTime: string, LastAnalyzedTime: string, Retention: int, StorageDescriptor: record, PartitionKeys: list, ViewOriginalText: string, ViewExpandedText: string, TableType: string, Parameters: record, CreatedBy: string, IsRegisteredWithLakeFormation: bool, TargetTable: record, CatalogId: string, VersionId: string, FederatedTable: record>>
# operationId: SearchTables
export def "search-tables" [
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
  --x-amz-target: string@x-amz-target-completer-161 # required
  --catalog-id: string # A unique identifier, consisting of account_id .
  --body-next-token: string # A continuation token, included if this is a continuation call. (spec name: NextToken)
  --filters: list # A list of key-value pairs, and a comparator used to filter the search results. Returns all entities matching the predicate. The Comparator member of the PropertyPredicate struct is used only for time fields, and can be omitted for other field types. Also, when comparing string values, such as when Key=Name, a fuzzy match algorithm is used. The Key field (for example, the value of the Name field) is split on certain punctuation characters, for example, -, :, #, etc. into tokens. Then each token is exact-match compared with the Value member of PropertyPredicate. For example, if Key=Name and Value=link, tables named customer-link and xx-link-yy are returned, but xxlinkyy is not returned. — item shape: {Key?: string, Value?: string, Comparator?: "EQUALS"|"GREATER_THAN"|"LESS_THAN"|"GREATER_THAN_EQUALS"|"LESS_THAN_EQUALS"}
  --search-text: string # A string used for a text search. Specifying a value in quotes filters based on an exact match to the value.
  --sort-criteria: list # A list of criteria for sorting the results by a field name, in an ascending or descending order. — item shape: {FieldName?: string, Sort?: "ASC"|"DESC"}
  --body-max-results: int # The maximum number of tables to return in a single response. (spec name: MaxResults)
  --resource-share-type: string@resource-share-type-completer # Allows you to specify that you want to search the tables shared with your account. The allowable values are FOREIGN or ALL. If set to FOREIGN, will search the tables shared with your account. If set to ALL, will search the tables shared with your account, as well as the tables in yor local account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.SearchTables"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: NextToken, var: body_next_token}, {name: Filters, var: filters}, {name: SearchText, var: search_text}, {name: SortCriteria, var: sort_criteria}, {name: MaxResults, var: body_max_results}, {name: ResourceShareType, var: resource_share_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, body_next_token: $body_next_token, filters: $filters, search_text: $search_text, sort_criteria: $sort_criteria, body_max_results: $body_max_results, resource_share_type: $resource_share_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a new run of the specified blueprint.
#
# POST /
# Returns: record<RunId: string>
# operationId: StartBlueprintRun
export def "start-blueprint-run" [
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
  --x-amz-target: string@x-amz-target-completer-162 # required
  blueprint_name: string # The name of the blueprint.
  --parameters: string # Specifies the parameters as a BlueprintParameters object.
  role_arn: string # Specifies the IAM role used to create the workflow.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.StartBlueprintRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BlueprintName, var: blueprint_name}, {name: Parameters, var: parameters}, {name: RoleArn, var: role_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, blueprint_name: $blueprint_name, parameters: $parameters, role_arn: $role_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a CrawlerRunningException (https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException).
#
# POST /
# Returns: record
# operationId: StartCrawler
export def "start-crawler" [
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
  --x-amz-target: string@x-amz-target-completer-163 # required
  name: string # Name of the crawler to start.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.StartCrawler"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the schedule state of the specified crawler to SCHEDULED, unless the crawler is already running or the schedule state is already SCHEDULED.
#
# POST /
# Returns: record
# operationId: StartCrawlerSchedule
export def "start-crawler-schedule" [
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
  --x-amz-target: string@x-amz-target-completer-164 # required
  crawler_name: string # Name of the crawler to schedule.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.StartCrawlerSchedule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CrawlerName, var: crawler_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, crawler_name: $crawler_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a recommendation run that is used to generate rules when you don't know what rules to write. Glue Data Quality analyzes the data and comes up with recommendations for a potential ruleset. You can then triage the ruleset and modify the generated ruleset to your liking.
#
# POST /
# Returns: record<RunId: string>
# operationId: StartDataQualityRuleRecommendationRun
export def "start-data-quality-rule-recommendation-run" [
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
  --x-amz-target: string@x-amz-target-completer-165 # required
  data_source: record # A data source (an Glue table) for which you want data quality results. — shape: {GlueTable: record}
  role: string # An IAM role supplied to encrypt the results of the run.
  --number-of-workers: int # The number of G.1X workers to be used in the run. The default is 5.
  --timeout: int # The timeout for a run in minutes. This is the maximum time that a run can consume resources before it is terminated and enters TIMEOUT status. The default is 2,880 minutes (48 hours).
  --created-ruleset-name: string # A name for the ruleset.
  --client-token: string # Used for idempotency and is recommended to be set to a random ID (such as a UUID) to avoid creating or starting multiple instances of the same resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.StartDataQualityRuleRecommendationRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DataSource, var: data_source}, {name: Role, var: role}, {name: NumberOfWorkers, var: number_of_workers}, {name: Timeout, var: timeout}, {name: CreatedRulesetName, var: created_ruleset_name}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, data_source: $data_source, role: $role, number_of_workers: $number_of_workers, timeout: $timeout, created_ruleset_name: $created_ruleset_name, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Once you have a ruleset definition (either recommended or your own), you call this operation to evaluate the ruleset against a data source (Glue table). The evaluation computes results which you can retrieve with the GetDataQualityResult API.
#
# POST /
# Returns: record<RunId: string>
# operationId: StartDataQualityRulesetEvaluationRun
export def "start-data-quality-ruleset-evaluation-run" [
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
  --x-amz-target: string@x-amz-target-completer-166 # required
  data_source: record # A data source (an Glue table) for which you want data quality results. — shape: {GlueTable: record}
  role: string # An IAM role supplied to encrypt the results of the run.
  --number-of-workers: int # The number of G.1X workers to be used in the run. The default is 5.
  --timeout: int # The timeout for a run in minutes. This is the maximum time that a run can consume resources before it is terminated and enters TIMEOUT status. The default is 2,880 minutes (48 hours).
  --client-token: string # Used for idempotency and is recommended to be set to a random ID (such as a UUID) to avoid creating or starting multiple instances of the same resource.
  --additional-run-options: record # Additional run options you can specify for an evaluation run. — shape: {CloudWatchMetricsEnabled?: bool, ResultsS3Prefix?: string}
  ruleset_names: list<string> # A list of ruleset names.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.StartDataQualityRulesetEvaluationRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DataSource, var: data_source}, {name: Role, var: role}, {name: NumberOfWorkers, var: number_of_workers}, {name: Timeout, var: timeout}, {name: ClientToken, var: client_token}, {name: AdditionalRunOptions, var: additional_run_options}, {name: RulesetNames, var: ruleset_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, data_source: $data_source, role: $role, number_of_workers: $number_of_workers, timeout: $timeout, client_token: $client_token, additional_run_options: $additional_run_options, ruleset_names: $ruleset_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use StartExportLabelsTaskRun when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the TransformId whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a TaskRunId. You can check on the status of your task run by calling the GetMLTaskRun API.
#
# POST /
# Returns: record<TaskRunId: string>
# operationId: StartExportLabelsTaskRun
export def "start-export-labels-task-run" [
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
  --x-amz-target: string@x-amz-target-completer-167 # required
  transform_id: string # The unique identifier of the machine learning transform.
  output_s3_path: string # The Amazon S3 path where you export the labels.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.StartExportLabelsTaskRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TransformId, var: transform_id}, {name: OutputS3Path, var: output_s3_path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, transform_id: $transform_id, output_s3_path: $output_s3_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the StartMLLabelingSetGenerationTaskRun call and that ultimately results in improving the quality of your machine learning transform. After the StartMLLabelingSetGenerationTaskRun finishes, Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the FindMatches transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to StartImportLabelsTaskRun. After StartImportLabelsTaskRun finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation. By default, StartMLLabelingSetGenerationTaskRun continually learns from and combines all labels that you upload unless you set Replace to true. If you set Replace to true, StartImportLabelsTaskRun deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality. You can check on the status of your task run by calling the GetMLTaskRun operation.
#
# POST /
# Returns: record<TaskRunId: string>
# operationId: StartImportLabelsTaskRun
export def "start-import-labels-task-run" [
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
  --x-amz-target: string@x-amz-target-completer-168 # required
  transform_id: string # The unique identifier of the machine learning transform.
  input_s3_path: string # The Amazon Simple Storage Service (Amazon S3) path from where you import the labels.
  --replace-all-labels: oneof<nothing, bool> # Indicates whether to overwrite your existing labels.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.StartImportLabelsTaskRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TransformId, var: transform_id}, {name: InputS3Path, var: input_s3_path}, {name: ReplaceAllLabels, var: replace_all_labels}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, transform_id: $transform_id, input_s3_path: $input_s3_path, replace_all_labels: $replace_all_labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a job run using a job definition.
#
# POST /
# Returns: record<JobRunId: string>
# operationId: StartJobRun
export def "start-job-run" [
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
  --x-amz-target: string@x-amz-target-completer-169 # required
  job_name: string # The name of the job definition to use.
  --job-run-id: string # The ID of a previous JobRun to retry.
  --arguments: record # The job arguments specifically for this run. For this job run, they replace the default arguments set in the job definition itself. You can specify arguments here that your own job-execution script consumes, as well as arguments that Glue itself consumes. Job arguments may be logged. Do not pass plaintext secrets as arguments. Retrieve secrets from a Glue Connection, Secrets Manager or other secret management mechanism if you intend to keep them within the Job. For information about how to specify and consume your own Job arguments, see the Calling Glue APIs in Python (https://docs.aws.amazon.com/glue/latest/dg/aws-glue-programming-python-calling.html) topic in the developer guide. For information about the key-value pairs that Glue consumes to set up your job, see the Special Parameters Used by Glue (https://docs.aws.amazon.com/glue/latest/dg/aws-glue-programming-etl-glue-arguments.html) topic in the developer guide.
  --allocated-capacity: int # This field is deprecated. Use MaxCapacity instead. The number of Glue data processing units (DPUs) to allocate to this JobRun. You can allocate a minimum of 2 DPUs; the default is 10. A DPU is a relative measure of processing power that consists of 4 vCPUs of compute capacity and 16 GB of memory. For more information, see the Glue pricing page (https://aws.amazon.com/glue/pricing/).This property is deprecated, use MaxCapacity instead.
  --timeout: int # The JobRun timeout in minutes. This is the maximum time that a job run can consume resources before it is terminated and enters TIMEOUT status. This value overrides the timeout value set in the parent job. Streaming jobs do not have a timeout. The default for non-streaming jobs is 2,880 minutes (48 hours).
  --max-capacity: float # The number of Glue data processing units (DPUs) that can be allocated when this job runs. A DPU is a relative measure of processing power that consists of 4 vCPUs of compute capacity and 16 GB of memory. For more information, see the Glue pricing page (https://aws.amazon.com/glue/pricing/). Do not set Max Capacity if using WorkerType and NumberOfWorkers. The value that can be allocated for MaxCapacity depends on whether you are running a Python shell job, or an Apache Spark ETL job: When you specify a Python shell job (JobCommand.Name="pythonshell"), you can allocate either 0.0625 or 1 DPU. The default is 0.0625 DPU. When you specify an Apache Spark ETL job (JobCommand.Name="glueetl"), you can allocate a minimum of 2 DPUs. The default is 10 DPUs. This job type cannot have a fractional DPU allocation. (format: double)
  --security-configuration: string # The name of the SecurityConfiguration structure to be used with this job run.
  --notification-property: record # Specifies configuration properties of a notification. — shape: {NotifyDelayAfter?: int}
  --worker-type: string@worker-type-completer # The type of predefined worker that is allocated when a job runs. Accepts a value of Standard, G.1X, G.2X, or G.025X. For the Standard worker type, each worker provides 4 vCPU, 16 GB of memory and a 50GB disk, and 2 executors per worker. For the G.1X worker type, each worker provides 4 vCPU, 16 GB of memory and a 64GB disk, and 1 executor per worker. For the G.2X worker type, each worker provides 8 vCPU, 32 GB of memory and a 128GB disk, and 1 executor per worker. For the G.025X worker type, each worker maps to 0.25 DPU (2 vCPU, 4 GB of memory, 64 GB disk), and provides 1 executor per worker. We recommend this worker type for low volume streaming jobs. This worker type is only available for Glue version 3.0 streaming jobs.
  --number-of-workers: int # The number of workers of a defined workerType that are allocated when a job runs.
  --execution-class: string@execution-class-completer # Indicates whether the job is run with a standard or flexible execution class. The standard execution-class is ideal for time-sensitive workloads that require fast job startup and dedicated resources. The flexible execution class is appropriate for time-insensitive jobs whose start and completion times may vary. Only jobs with Glue version 3.0 and above and command type glueetl will be allowed to set ExecutionClass to FLEX. The flexible execution class is available for Spark jobs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.StartJobRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobName, var: job_name}, {name: JobRunId, var: job_run_id}, {name: Arguments, var: arguments}, {name: AllocatedCapacity, var: allocated_capacity}, {name: Timeout, var: timeout}, {name: MaxCapacity, var: max_capacity}, {name: SecurityConfiguration, var: security_configuration}, {name: NotificationProperty, var: notification_property}, {name: WorkerType, var: worker_type}, {name: NumberOfWorkers, var: number_of_workers}, {name: ExecutionClass, var: execution_class}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_name: $job_name, job_run_id: $job_run_id, arguments: $arguments, allocated_capacity: $allocated_capacity, timeout: $timeout, max_capacity: $max_capacity, security_configuration: $security_configuration, notification_property: $notification_property, worker_type: $worker_type, number_of_workers: $number_of_workers, execution_class: $execution_class
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a task to estimate the quality of the transform. When you provide label sets as examples of truth, Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality. Returns a unique identifier for the run. You can call GetMLTaskRun to get more information about the stats of the EvaluationTaskRun.
#
# POST /
# Returns: record<TaskRunId: string>
# operationId: StartMLEvaluationTaskRun
export def "start-ml-evaluation-task-run" [
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
  --x-amz-target: string@x-amz-target-completer-170 # required
  transform_id: string # The unique identifier of the machine learning transform.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.StartMLEvaluationTaskRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TransformId, var: transform_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, transform_id: $transform_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels. When the StartMLLabelingSetGenerationTaskRun finishes, Glue will have generated a "labeling set" or a set of questions for humans to answer. In the case of the FindMatches transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, you can upload your labels with a call to StartImportLabelsTaskRun. After StartImportLabelsTaskRun finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.
#
# POST /
# Returns: record<TaskRunId: string>
# operationId: StartMLLabelingSetGenerationTaskRun
export def "start-ml-labeling-set-generation-task-run" [
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
  --x-amz-target: string@x-amz-target-completer-171 # required
  transform_id: string # The unique identifier of the machine learning transform.
  output_s3_path: string # The Amazon Simple Storage Service (Amazon S3) path where you generate the labeling set.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.StartMLLabelingSetGenerationTaskRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TransformId, var: transform_id}, {name: OutputS3Path, var: output_s3_path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, transform_id: $transform_id, output_s3_path: $output_s3_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an existing trigger. See Triggering Jobs (https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html) for information about how different types of trigger are started.
#
# POST /
# Returns: record<Name: string>
# operationId: StartTrigger
export def "start-trigger" [
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
  --x-amz-target: string@x-amz-target-completer-172 # required
  name: string # The name of the trigger to start.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.StartTrigger"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a new run of the specified workflow.
#
# POST /
# Returns: record<RunId: string>
# operationId: StartWorkflowRun
export def "start-workflow-run" [
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
  --x-amz-target: string@x-amz-target-completer-173 # required
  name: string # The name of the workflow to start.
  --run-properties: record # The workflow run properties for the new workflow run.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.StartWorkflowRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: RunProperties, var: run_properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, run_properties: $run_properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# If the specified crawler is running, stops the crawl.
#
# POST /
# Returns: record
# operationId: StopCrawler
export def "stop-crawler" [
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
  --x-amz-target: string@x-amz-target-completer-174 # required
  name: string # Name of the crawler to stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.StopCrawler"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the schedule state of the specified crawler to NOT_SCHEDULED, but does not stop the crawler if it is already running.
#
# POST /
# Returns: record
# operationId: StopCrawlerSchedule
export def "stop-crawler-schedule" [
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
  --x-amz-target: string@x-amz-target-completer-175 # required
  crawler_name: string # Name of the crawler whose schedule state to set.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.StopCrawlerSchedule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CrawlerName, var: crawler_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, crawler_name: $crawler_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops the session.
#
# POST /
# Returns: record<Id: string>
# operationId: StopSession
export def "stop-session" [
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
  --x-amz-target: string@x-amz-target-completer-176 # required
  id: string # The ID of the session to be stopped.
  --request-origin: string # The origin of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.StopSession"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: RequestOrigin, var: request_origin}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, request_origin: $request_origin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a specified trigger.
#
# POST /
# Returns: record<Name: string>
# operationId: StopTrigger
export def "stop-trigger" [
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
  --x-amz-target: string@x-amz-target-completer-177 # required
  name: string # The name of the trigger to stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.StopTrigger"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops the execution of the specified workflow run.
#
# POST /
# Returns: record
# operationId: StopWorkflowRun
export def "stop-workflow-run" [
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
  --x-amz-target: string@x-amz-target-completer-178 # required
  name: string # The name of the workflow to stop.
  run_id: string # The ID of the workflow run to stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.StopWorkflowRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: RunId, var: run_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, run_id: $run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds tags to a resource. A tag is a label you can assign to an Amazon Web Services resource. In Glue, you can tag only certain resources. For information about what resources you can tag, see Amazon Web Services Tags in Glue (https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html).
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
  --x-amz-target: string@x-amz-target-completer-179 # required
  resource_arn: string # The ARN of the Glue resource to which to add the tags. For more information about Glue resource ARNs, see the Glue ARN string pattern (https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-common.html#aws-glue-api-regex-aws-glue-arn-id).
  tags_to_add: record # Tags to add to this resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: TagsToAdd, var: tags_to_add}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags_to_add: $tags_to_add
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes tags from a resource.
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
  --x-amz-target: string@x-amz-target-completer-180 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource from which to remove the tags.
  tags_to_remove: list<string> # Tags to remove from this resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: TagsToRemove, var: tags_to_remove}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags_to_remove: $tags_to_remove
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a registered blueprint.
#
# POST /
# Returns: record<Name: string>
# operationId: UpdateBlueprint
export def "update-blueprint" [
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
  --x-amz-target: string@x-amz-target-completer-181 # required
  name: string # The name of the blueprint.
  --description: string # A description of the blueprint.
  blueprint_location: string # Specifies a path in Amazon S3 where the blueprint is published.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateBlueprint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: BlueprintLocation, var: blueprint_location}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, blueprint_location: $blueprint_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies an existing classifier (a GrokClassifier, an XMLClassifier, a JsonClassifier, or a CsvClassifier, depending on which field is present).
#
# POST /
# Returns: record
# operationId: UpdateClassifier
export def "update-classifier" [
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
  --x-amz-target: string@x-amz-target-completer-182 # required
  --grok-classifier: record # Specifies a grok classifier to update when passed to UpdateClassifier. — shape: {Name: string, Classification?: string, GrokPattern?: string, CustomPatterns?: string}
  --xml-classifier: record # Specifies an XML classifier to be updated. — shape: {Name: string, Classification?: string, RowTag?: string}
  --json-classifier: record # Specifies a JSON classifier to be updated. — shape: {Name: string, JsonPath?: string}
  --csv-classifier: record # Specifies a custom CSV classifier to be updated. — shape: {Name: string, Delimiter?: string, QuoteSymbol?: string, ContainsHeader?: "UNKNOWN"|"PRESENT"|"ABSENT", Header?: list<string>, DisableValueTrimming?: bool, AllowSingleColumn?: bool, CustomDatatypeConfigured?: bool, CustomDatatypes?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateClassifier"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GrokClassifier, var: grok_classifier}, {name: XMLClassifier, var: xml_classifier}, {name: JsonClassifier, var: json_classifier}, {name: CsvClassifier, var: csv_classifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, grok_classifier: $grok_classifier, xml_classifier: $xml_classifier, json_classifier: $json_classifier, csv_classifier: $csv_classifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates partition statistics of columns. The Identity and Access Management (IAM) permission required for this operation is UpdatePartition.
#
# POST /
# Returns: record<Errors: table<ColumnStatistics: record, Error: record>>
# operationId: UpdateColumnStatisticsForPartition
export def "update-column-statistics-for-partition" [
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
  --x-amz-target: string@x-amz-target-completer-183 # required
  --catalog-id: string # The ID of the Data Catalog where the partitions in question reside. If none is supplied, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database where the partitions reside.
  table_name: string # The name of the partitions' table.
  partition_values: list<string> # A list of partition values identifying the partition.
  column_statistics_list: list # A list of the column statistics. — item shape: {ColumnName: string, ColumnType: string, AnalyzedTime: string, StatisticsData: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateColumnStatisticsForPartition"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: PartitionValues, var: partition_values}, {name: ColumnStatisticsList, var: column_statistics_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, partition_values: $partition_values, column_statistics_list: $column_statistics_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates table statistics of columns. The Identity and Access Management (IAM) permission required for this operation is UpdateTable.
#
# POST /
# Returns: record<Errors: table<ColumnStatistics: record, Error: record>>
# operationId: UpdateColumnStatisticsForTable
export def "update-column-statistics-for-table" [
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
  --x-amz-target: string@x-amz-target-completer-184 # required
  --catalog-id: string # The ID of the Data Catalog where the partitions in question reside. If none is supplied, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database where the partitions reside.
  table_name: string # The name of the partitions' table.
  column_statistics_list: list # A list of the column statistics. — item shape: {ColumnName: string, ColumnType: string, AnalyzedTime: string, StatisticsData: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateColumnStatisticsForTable"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: ColumnStatisticsList, var: column_statistics_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, column_statistics_list: $column_statistics_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a connection definition in the Data Catalog.
#
# POST /
# Returns: record
# operationId: UpdateConnection
export def "update-connection" [
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
  --x-amz-target: string@x-amz-target-completer-185 # required
  --catalog-id: string # The ID of the Data Catalog in which the connection resides. If none is provided, the Amazon Web Services account ID is used by default.
  name: string # The name of the connection definition to update.
  connection_input: record # A structure that is used to specify a connection to create or update. — shape: {Name: string, Description?: string, ConnectionType: "JDBC"|"SFTP"|"MONGODB"|"KAFKA"|"NETWORK"|"MARKETPLACE"|"CUSTOM", MatchCriteria?: list<string>, ConnectionProperties: record, PhysicalConnectionRequirements?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: Name, var: name}, {name: ConnectionInput, var: connection_input}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, name: $name, connection_input: $connection_input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a crawler. If a crawler is running, you must stop it using StopCrawler before updating it.
#
# POST /
# Returns: record
# operationId: UpdateCrawler
export def "update-crawler" [
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
  --x-amz-target: string@x-amz-target-completer-186 # required
  name: string # Name of the new crawler.
  --role: string # The IAM role or Amazon Resource Name (ARN) of an IAM role that is used by the new crawler to access customer resources.
  --database-name: string # The Glue database where results are stored, such as: arn:aws:daylight:us-east-1::database/sometable/*.
  --description: string # A description of the new crawler.
  --targets: record # Specifies data stores to crawl. — shape: {S3Targets?: list, JdbcTargets?: list, MongoDBTargets?: list, DynamoDBTargets?: list, CatalogTargets?: list, DeltaTargets?: list}
  --schedule: string # A cron expression used to specify the schedule (see Time-Based Schedules for Jobs and Crawlers (https://docs.aws.amazon.com/glue/latest/dg/monitor-data-warehouse-schedule.html). For example, to run something every day at 12:15 UTC, you would specify: cron(15 12 * * ? *).
  --classifiers: list<string> # A list of custom classifiers that the user has registered. By default, all built-in classifiers are included in a crawl, but these custom classifiers always override the default classifiers for a given classification.
  --table-prefix: string # The table prefix used for catalog tables that are created.
  --schema-change-policy: record # A policy that specifies update and deletion behaviors for the crawler. — shape: {UpdateBehavior?: "LOG"|"UPDATE_IN_DATABASE", DeleteBehavior?: "LOG"|"DELETE_FROM_DATABASE"|"DEPRECATE_IN_DATABASE"}
  --recrawl-policy: record # When crawling an Amazon S3 data source after the first crawl is complete, specifies whether to crawl the entire dataset again or to crawl only folders that were added since the last crawler run. For more information, see Incremental Crawls in Glue (https://docs.aws.amazon.com/glue/latest/dg/incremental-crawls.html) in the developer guide. — shape: {RecrawlBehavior?: "CRAWL_EVERYTHING"|"CRAWL_NEW_FOLDERS_ONLY"|"CRAWL_EVENT_MODE"}
  --lineage-configuration: record # Specifies data lineage configuration settings for the crawler. — shape: {CrawlerLineageSettings?: "ENABLE"|"DISABLE"}
  --lake-formation-configuration: record # Specifies Lake Formation configuration settings for the crawler. — shape: {UseLakeFormationCredentials?: bool, AccountId?: string}
  --configuration: string # Crawler configuration information. This versioned JSON string allows users to specify aspects of a crawler's behavior. For more information, see Setting crawler configuration options (https://docs.aws.amazon.com/glue/latest/dg/crawler-configuration.html).
  --crawler-security-configuration: string # The name of the SecurityConfiguration structure to be used by this crawler.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateCrawler"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Role, var: role}, {name: DatabaseName, var: database_name}, {name: Description, var: description}, {name: Targets, var: targets}, {name: Schedule, var: schedule}, {name: Classifiers, var: classifiers}, {name: TablePrefix, var: table_prefix}, {name: SchemaChangePolicy, var: schema_change_policy}, {name: RecrawlPolicy, var: recrawl_policy}, {name: LineageConfiguration, var: lineage_configuration}, {name: LakeFormationConfiguration, var: lake_formation_configuration}, {name: Configuration, var: configuration}, {name: CrawlerSecurityConfiguration, var: crawler_security_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, role: $role, database_name: $database_name, description: $description, targets: $targets, schedule: $schedule, classifiers: $classifiers, table_prefix: $table_prefix, schema_change_policy: $schema_change_policy, recrawl_policy: $recrawl_policy, lineage_configuration: $lineage_configuration, lake_formation_configuration: $lake_formation_configuration, configuration: $configuration, crawler_security_configuration: $crawler_security_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the schedule of a crawler using a cron expression.
#
# POST /
# Returns: record
# operationId: UpdateCrawlerSchedule
export def "update-crawler-schedule" [
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
  --x-amz-target: string@x-amz-target-completer-187 # required
  crawler_name: string # The name of the crawler whose schedule to update.
  --schedule: string # The updated cron expression used to specify the schedule (see Time-Based Schedules for Jobs and Crawlers (https://docs.aws.amazon.com/glue/latest/dg/monitor-data-warehouse-schedule.html). For example, to run something every day at 12:15 UTC, you would specify: cron(15 12 * * ? *).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateCrawlerSchedule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CrawlerName, var: crawler_name}, {name: Schedule, var: schedule}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, crawler_name: $crawler_name, schedule: $schedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified data quality ruleset.
#
# POST /
# Returns: record<Name: string, Description: string, Ruleset: string>
# operationId: UpdateDataQualityRuleset
export def "update-data-quality-ruleset" [
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
  --x-amz-target: string@x-amz-target-completer-188 # required
  name: string # The name of the data quality ruleset.
  --description: string # A description of the ruleset.
  --ruleset: string # A Data Quality Definition Language (DQDL) ruleset. For more information, see the Glue developer guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateDataQualityRuleset"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: Ruleset, var: ruleset}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, ruleset: $ruleset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing database definition in a Data Catalog.
#
# POST /
# Returns: record
# operationId: UpdateDatabase
export def "update-database" [
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
  --x-amz-target: string@x-amz-target-completer-189 # required
  --catalog-id: string # The ID of the Data Catalog in which the metadata database resides. If none is provided, the Amazon Web Services account ID is used by default.
  name: string # The name of the database to update in the catalog. For Hive compatibility, this is folded to lowercase.
  database_input: record # The structure used to create or update a database. — shape: {Name: string, Description?: string, LocationUri?: string, Parameters?: record, CreateTableDefaultPermissions?: list, TargetDatabase?: record, FederatedDatabase?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateDatabase"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: Name, var: name}, {name: DatabaseInput, var: database_input}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, name: $name, database_input: $database_input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specified development endpoint.
#
# POST /
# Returns: record
# operationId: UpdateDevEndpoint
export def "update-dev-endpoint" [
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
  --x-amz-target: string@x-amz-target-completer-190 # required
  endpoint_name: string # The name of the DevEndpoint to be updated.
  --public-key: string # The public key for the DevEndpoint to use.
  --add-public-keys: list<string> # The list of public keys for the DevEndpoint to use.
  --delete-public-keys: list<string> # The list of public keys to be deleted from the DevEndpoint.
  --custom-libraries: record # Custom libraries to be loaded into a development endpoint. — shape: {ExtraPythonLibsS3Path?: string, ExtraJarsS3Path?: string}
  --update-etl-libraries: oneof<nothing, bool> # True if the list of custom libraries to be loaded in the development endpoint needs to be updated, or False if otherwise.
  --delete-arguments: list<string> # The list of argument keys to be deleted from the map of arguments used to configure the DevEndpoint.
  --add-arguments: record # The map of arguments to add the map of arguments used to configure the DevEndpoint. Valid arguments are: "--enable-glue-datacatalog": "" You can specify a version of Python support for development endpoints by using the Arguments parameter in the CreateDevEndpoint or UpdateDevEndpoint APIs. If no arguments are provided, the version defaults to Python 2.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateDevEndpoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointName, var: endpoint_name}, {name: PublicKey, var: public_key}, {name: AddPublicKeys, var: add_public_keys}, {name: DeletePublicKeys, var: delete_public_keys}, {name: CustomLibraries, var: custom_libraries}, {name: UpdateEtlLibraries, var: update_etl_libraries}, {name: DeleteArguments, var: delete_arguments}, {name: AddArguments, var: add_arguments}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_name: $endpoint_name, public_key: $public_key, add_public_keys: $add_public_keys, delete_public_keys: $delete_public_keys, custom_libraries: $custom_libraries, update_etl_libraries: $update_etl_libraries, delete_arguments: $delete_arguments, add_arguments: $add_arguments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing job definition. The previous job definition is completely overwritten by this information.
#
# POST /
# Returns: record<JobName: string>
# operationId: UpdateJob
export def "update-job" [
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
  --x-amz-target: string@x-amz-target-completer-191 # required
  job_name: string # The name of the job definition to update.
  job_update: record # Specifies information used to update an existing job definition. The previous job definition is completely overwritten by this information. — shape: {Description?: string, LogUri?: string, Role?: string, ExecutionProperty?: record, Command?: record, DefaultArguments?: record, NonOverridableArguments?: record, Connections?: record, MaxRetries?: int, AllocatedCapacity?: int, Timeout?: int, MaxCapacity?: float, WorkerType?: "Standard"|"G.1X"|"G.2X"|"G.025X", NumberOfWorkers?: int, SecurityConfiguration?: string, NotificationProperty?: record, GlueVersion?: string, CodeGenConfigurationNodes?: record, ExecutionClass?: "FLEX"|"STANDARD", ... (1 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobName, var: job_name}, {name: JobUpdate, var: job_update}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_name: $job_name, job_update: $job_update
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Synchronizes a job from the source control repository. This operation takes the job artifacts that are located in the remote repository and updates the Glue internal stores with these artifacts. This API supports optional parameters which take in the repository information.
#
# POST /
# Returns: record<JobName: string>
# operationId: UpdateJobFromSourceControl
export def "update-job-from-source-control" [
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
  --x-amz-target: string@x-amz-target-completer-192 # required
  --job-name: string # The name of the Glue job to be synchronized to or from the remote repository.
  --provider: string@provider-completer # The provider for the remote repository.
  --repository-name: string # The name of the remote repository that contains the job artifacts.
  --repository-owner: string # The owner of the remote repository that contains the job artifacts.
  --branch-name: string # An optional branch in the remote repository.
  --folder: string # An optional folder in the remote repository.
  --commit-id: string # A commit ID for a commit in the remote repository.
  --auth-strategy: string@auth-strategy-completer # The type of authentication, which can be an authentication token stored in Amazon Web Services Secrets Manager, or a personal access token.
  --auth-token: string # The value of the authorization token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateJobFromSourceControl"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobName, var: job_name}, {name: Provider, var: provider}, {name: RepositoryName, var: repository_name}, {name: RepositoryOwner, var: repository_owner}, {name: BranchName, var: branch_name}, {name: Folder, var: folder}, {name: CommitId, var: commit_id}, {name: AuthStrategy, var: auth_strategy}, {name: AuthToken, var: auth_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_name: $job_name, provider: $provider, repository_name: $repository_name, repository_owner: $repository_owner, branch_name: $branch_name, folder: $folder, commit_id: $commit_id, auth_strategy: $auth_strategy, auth_token: $auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results. After calling this operation, you can call the StartMLEvaluationTaskRun operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).
#
# POST /
# Returns: record<TransformId: string>
# operationId: UpdateMLTransform
export def "update-ml-transform" [
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
  --x-amz-target: string@x-amz-target-completer-193 # required
  transform_id: string # A unique identifier that was generated when the transform was created.
  --name: string # The unique name that you gave the transform when you created it.
  --description: string # A description of the transform. The default is an empty string.
  --parameters: record # The algorithm-specific parameters that are associated with the machine learning transform. — shape: {TransformType: "FIND_MATCHES", FindMatchesParameters?: record}
  --role: string # The name or Amazon Resource Name (ARN) of the IAM role with the required permissions.
  --glue-version: string # This value determines which version of Glue this machine learning transform is compatible with. Glue 1.0 is recommended for most customers. If the value is not set, the Glue compatibility defaults to Glue 0.9. For more information, see Glue Versions (https://docs.aws.amazon.com/glue/latest/dg/release-notes.html#release-notes-versions) in the developer guide.
  --max-capacity: float # The number of Glue data processing units (DPUs) that are allocated to task runs for this transform. You can allocate from 2 to 100 DPUs; the default is 10. A DPU is a relative measure of processing power that consists of 4 vCPUs of compute capacity and 16 GB of memory. For more information, see the Glue pricing page (https://aws.amazon.com/glue/pricing/). When the WorkerType field is set to a value other than Standard, the MaxCapacity field is set automatically and becomes read-only. (format: double)
  --worker-type: string@worker-type-completer # The type of predefined worker that is allocated when this task runs. Accepts a value of Standard, G.1X, or G.2X. For the Standard worker type, each worker provides 4 vCPU, 16 GB of memory and a 50GB disk, and 2 executors per worker. For the G.1X worker type, each worker provides 4 vCPU, 16 GB of memory and a 64GB disk, and 1 executor per worker. For the G.2X worker type, each worker provides 8 vCPU, 32 GB of memory and a 128GB disk, and 1 executor per worker.
  --number-of-workers: int # The number of workers of a defined workerType that are allocated when this task runs.
  --timeout: int # The timeout for a task run for this transform in minutes. This is the maximum time that a task run for this transform can consume resources before it is terminated and enters TIMEOUT status. The default is 2,880 minutes (48 hours).
  --max-retries: int # The maximum number of times to retry a task for this transform after a task run fails.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateMLTransform"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TransformId, var: transform_id}, {name: Name, var: name}, {name: Description, var: description}, {name: Parameters, var: parameters}, {name: Role, var: role}, {name: GlueVersion, var: glue_version}, {name: MaxCapacity, var: max_capacity}, {name: WorkerType, var: worker_type}, {name: NumberOfWorkers, var: number_of_workers}, {name: Timeout, var: timeout}, {name: MaxRetries, var: max_retries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, transform_id: $transform_id, name: $name, description: $description, parameters: $parameters, role: $role, glue_version: $glue_version, max_capacity: $max_capacity, worker_type: $worker_type, number_of_workers: $number_of_workers, timeout: $timeout, max_retries: $max_retries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a partition.
#
# POST /
# Returns: record
# operationId: UpdatePartition
export def "update-partition" [
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
  --x-amz-target: string@x-amz-target-completer-194 # required
  --catalog-id: string # The ID of the Data Catalog where the partition to be updated resides. If none is provided, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database in which the table in question resides.
  table_name: string # The name of the table in which the partition to be updated is located.
  partition_value_list: list<string> # List of partition key values that define the partition to update.
  partition_input: record # The structure used to create and update a partition. — shape: {Values?: list<string>, LastAccessTime?: string, StorageDescriptor?: record, Parameters?: record, LastAnalyzedTime?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdatePartition"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableName, var: table_name}, {name: PartitionValueList, var: partition_value_list}, {name: PartitionInput, var: partition_input}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_name: $table_name, partition_value_list: $partition_value_list, partition_input: $partition_input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing registry which is used to hold a collection of schemas. The updated properties relate to the registry, and do not modify any of the schemas within the registry.
#
# POST /
# Returns: record<RegistryName: string, RegistryArn: string>
# operationId: UpdateRegistry
export def "update-registry" [
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
  --x-amz-target: string@x-amz-target-completer-195 # required
  registry_id: record # A wrapper structure that may contain the registry name and Amazon Resource Name (ARN). — shape: {RegistryName?: string, RegistryArn?: string}
  description: string # A description of the registry. If description is not provided, this field will not be updated.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateRegistry"}]
    body: {content_type: "application/json", kind: json, fields: [{name: RegistryId, var: registry_id}, {name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, registry_id: $registry_id, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the description, compatibility setting, or version checkpoint for a schema set. For updating the compatibility setting, the call will not validate compatibility for the entire set of schema versions with the new compatibility setting. If the value for Compatibility is provided, the VersionNumber (a checkpoint) is also required. The API will validate the checkpoint version number for consistency. If the value for the VersionNumber (checkpoint) is provided, Compatibility is optional and this can be used to set/reset a checkpoint for the schema. This update will happen only if the schema is in the AVAILABLE state.
#
# POST /
# Returns: record<SchemaArn: string, SchemaName: string, RegistryName: string>
# operationId: UpdateSchema
export def "update-schema" [
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
  --x-amz-target: string@x-amz-target-completer-196 # required
  schema_id: record # The unique ID of the schema in the Glue schema registry. — shape: {SchemaArn?: string, SchemaName?: string, RegistryName?: string}
  --schema-version-number: record # A structure containing the schema version information. — shape: {LatestVersion?: bool, VersionNumber?: int}
  --compatibility: string@compatibility-completer # The new compatibility setting for the schema.
  --description: string # The new description for the schema.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateSchema"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaId, var: schema_id}, {name: SchemaVersionNumber, var: schema_version_number}, {name: Compatibility, var: compatibility}, {name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, schema_id: $schema_id, schema_version_number: $schema_version_number, compatibility: $compatibility, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Synchronizes a job to the source control repository. This operation takes the job artifacts from the Glue internal stores and makes a commit to the remote repository that is configured on the job. This API supports optional parameters which take in the repository information.
#
# POST /
# Returns: record<JobName: string>
# operationId: UpdateSourceControlFromJob
export def "update-source-control-from-job" [
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
  --x-amz-target: string@x-amz-target-completer-197 # required
  --job-name: string # The name of the Glue job to be synchronized to or from the remote repository.
  --provider: string@provider-completer # The provider for the remote repository.
  --repository-name: string # The name of the remote repository that contains the job artifacts.
  --repository-owner: string # The owner of the remote repository that contains the job artifacts.
  --branch-name: string # An optional branch in the remote repository.
  --folder: string # An optional folder in the remote repository.
  --commit-id: string # A commit ID for a commit in the remote repository.
  --auth-strategy: string@auth-strategy-completer # The type of authentication, which can be an authentication token stored in Amazon Web Services Secrets Manager, or a personal access token.
  --auth-token: string # The value of the authorization token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateSourceControlFromJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobName, var: job_name}, {name: Provider, var: provider}, {name: RepositoryName, var: repository_name}, {name: RepositoryOwner, var: repository_owner}, {name: BranchName, var: branch_name}, {name: Folder, var: folder}, {name: CommitId, var: commit_id}, {name: AuthStrategy, var: auth_strategy}, {name: AuthToken, var: auth_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_name: $job_name, provider: $provider, repository_name: $repository_name, repository_owner: $repository_owner, branch_name: $branch_name, folder: $folder, commit_id: $commit_id, auth_strategy: $auth_strategy, auth_token: $auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a metadata table in the Data Catalog.
#
# POST /
# Returns: record
# operationId: UpdateTable
export def "update-table" [
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
  --x-amz-target: string@x-amz-target-completer-198 # required
  --catalog-id: string # The ID of the Data Catalog where the table resides. If none is provided, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database in which the table resides. For Hive compatibility, this name is entirely lowercase.
  table_input: record # A structure used to define a table. — shape: {Name: string, Description?: string, Owner?: string, LastAccessTime?: string, LastAnalyzedTime?: string, Retention?: int, StorageDescriptor?: record, PartitionKeys?: list, ViewOriginalText?: string, ViewExpandedText?: string, TableType?: string, Parameters?: record, TargetTable?: record}
  --skip-archive: oneof<nothing, bool> # By default, UpdateTable always creates an archived version of the table before updating it. However, if skipArchive is set to true, UpdateTable does not create the archived version.
  --transaction-id: string # The transaction ID at which to update the table contents.
  --version-id: string # The version ID at which to update the table contents.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateTable"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: TableInput, var: table_input}, {name: SkipArchive, var: skip_archive}, {name: TransactionId, var: transaction_id}, {name: VersionId, var: version_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, table_input: $table_input, skip_archive: $skip_archive, transaction_id: $transaction_id, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a trigger definition.
#
# POST /
# Returns: record<Trigger: record<Name: string, WorkflowName: string, Id: string, Type: string, State: string, Description: string, Schedule: string, Actions: list<record>, Predicate: record<Logical: string, Conditions: list>, EventBatchingCondition: record<BatchSize: int, BatchWindow: int>>>
# operationId: UpdateTrigger
export def "update-trigger" [
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
  --x-amz-target: string@x-amz-target-completer-199 # required
  name: string # The name of the trigger to update.
  trigger_update: record # A structure used to provide information used to update a trigger. This object updates the previous trigger definition by overwriting it completely. — shape: {Name?: string, Description?: string, Schedule?: string, Actions?: list, Predicate?: record, EventBatchingCondition?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateTrigger"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: TriggerUpdate, var: trigger_update}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, trigger_update: $trigger_update
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing function definition in the Data Catalog.
#
# POST /
# Returns: record
# operationId: UpdateUserDefinedFunction
export def "update-user-defined-function" [
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
  --x-amz-target: string@x-amz-target-completer-200 # required
  --catalog-id: string # The ID of the Data Catalog where the function to be updated is located. If none is provided, the Amazon Web Services account ID is used by default.
  database_name: string # The name of the catalog database where the function to be updated is located.
  function_name: string # The name of the function.
  function_input: record # A structure used to create or update a user-defined function. — shape: {FunctionName?: string, ClassName?: string, OwnerName?: string, OwnerType?: "USER"|"ROLE"|"GROUP", ResourceUris?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateUserDefinedFunction"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CatalogId, var: catalog_id}, {name: DatabaseName, var: database_name}, {name: FunctionName, var: function_name}, {name: FunctionInput, var: function_input}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, catalog_id: $catalog_id, database_name: $database_name, function_name: $function_name, function_input: $function_input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing workflow.
#
# POST /
# Returns: record<Name: string>
# operationId: UpdateWorkflow
export def "update-workflow" [
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
  --x-amz-target: string@x-amz-target-completer-201 # required
  name: string # Name of the workflow to be updated.
  --description: string # The description of the workflow.
  --default-run-properties: record # A collection of properties to be used as part of each execution of the workflow.
  --max-concurrent-runs: int # You can use this parameter to prevent unwanted multiple updates to data, to control costs, or in some cases, to prevent exceeding the maximum number of concurrent runs of any of the component jobs. If you leave this parameter blank, there is no limit to the number of concurrent workflow runs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSGlue.UpdateWorkflow"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: DefaultRunProperties, var: default_run_properties}, {name: MaxConcurrentRuns, var: max_concurrent_runs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, default_run_properties: $default_run_properties, max_concurrent_runs: $max_concurrent_runs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
