# Auto-generated client for AWS DataSync v2018-11-09
# Source: https://api.apis.guru/v2/specs/amazonaws.com/datasync/2018-11-09/openapi.json
# Auth: --token flag or $env.AWS_DATASYNC_TOKEN

const CLIENT = {
  base_url: "http://datasync.us-east-1.amazonaws.com"
  token_env_var: "AWS_DATASYNC_TOKEN"
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

def base-url-completer [] { ["http://datasync.us-east-1.amazonaws.com" "http://datasync.us-east-2.amazonaws.com" "http://datasync.us-west-1.amazonaws.com" "http://datasync.us-west-2.amazonaws.com" "http://datasync.us-gov-west-1.amazonaws.com" "http://datasync.us-gov-east-1.amazonaws.com" "http://datasync.ca-central-1.amazonaws.com" "http://datasync.eu-north-1.amazonaws.com" "http://datasync.eu-west-1.amazonaws.com" "http://datasync.eu-west-2.amazonaws.com" "http://datasync.eu-west-3.amazonaws.com" "http://datasync.eu-central-1.amazonaws.com" "http://datasync.eu-south-1.amazonaws.com" "http://datasync.af-south-1.amazonaws.com" "http://datasync.ap-northeast-1.amazonaws.com" "http://datasync.ap-northeast-2.amazonaws.com" "http://datasync.ap-northeast-3.amazonaws.com" "http://datasync.ap-southeast-1.amazonaws.com" "http://datasync.ap-southeast-2.amazonaws.com" "http://datasync.ap-east-1.amazonaws.com" "http://datasync.ap-south-1.amazonaws.com" "http://datasync.sa-east-1.amazonaws.com" "http://datasync.me-south-1.amazonaws.com" "https://datasync.us-east-1.amazonaws.com" "https://datasync.us-east-2.amazonaws.com" "https://datasync.us-west-1.amazonaws.com" "https://datasync.us-west-2.amazonaws.com" "https://datasync.us-gov-west-1.amazonaws.com" "https://datasync.us-gov-east-1.amazonaws.com" "https://datasync.ca-central-1.amazonaws.com" "https://datasync.eu-north-1.amazonaws.com" "https://datasync.eu-west-1.amazonaws.com" "https://datasync.eu-west-2.amazonaws.com" "https://datasync.eu-west-3.amazonaws.com" "https://datasync.eu-central-1.amazonaws.com" "https://datasync.eu-south-1.amazonaws.com" "https://datasync.af-south-1.amazonaws.com" "https://datasync.ap-northeast-1.amazonaws.com" "https://datasync.ap-northeast-2.amazonaws.com" "https://datasync.ap-northeast-3.amazonaws.com" "https://datasync.ap-southeast-1.amazonaws.com" "https://datasync.ap-southeast-2.amazonaws.com" "https://datasync.ap-east-1.amazonaws.com" "https://datasync.ap-south-1.amazonaws.com" "https://datasync.sa-east-1.amazonaws.com" "https://datasync.me-south-1.amazonaws.com" "http://datasync.cn-north-1.amazonaws.com.cn" "http://datasync.cn-northwest-1.amazonaws.com.cn" "https://datasync.cn-north-1.amazonaws.com.cn" "https://datasync.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["FmrsService.CancelTaskExecution"] }
def x-amz-target-completer-1 [] { ["FmrsService.CreateAgent"] }
def in-transit-encryption-completer [] { ["NONE" "TLS1_2"] }
def x-amz-target-completer-2 [] { ["FmrsService.CreateLocationEfs"] }
def x-amz-target-completer-3 [] { ["FmrsService.CreateLocationFsxLustre"] }
def x-amz-target-completer-4 [] { ["FmrsService.CreateLocationFsxOntap"] }
def x-amz-target-completer-5 [] { ["FmrsService.CreateLocationFsxOpenZfs"] }
def x-amz-target-completer-6 [] { ["FmrsService.CreateLocationFsxWindows"] }
def authentication-type-completer [] { ["KERBEROS" "SIMPLE"] }
def x-amz-target-completer-7 [] { ["FmrsService.CreateLocationHdfs"] }
def x-amz-target-completer-8 [] { ["FmrsService.CreateLocationNfs"] }
def server-protocol-completer [] { ["HTTP" "HTTPS"] }
def x-amz-target-completer-9 [] { ["FmrsService.CreateLocationObjectStorage"] }
def s3-storage-class-completer [] { ["DEEP_ARCHIVE" "GLACIER" "GLACIER_INSTANT_RETRIEVAL" "INTELLIGENT_TIERING" "ONEZONE_IA" "OUTPOSTS" "STANDARD" "STANDARD_IA"] }
def x-amz-target-completer-10 [] { ["FmrsService.CreateLocationS3"] }
def x-amz-target-completer-11 [] { ["FmrsService.CreateLocationSmb"] }
def x-amz-target-completer-12 [] { ["FmrsService.CreateTask"] }
def x-amz-target-completer-13 [] { ["FmrsService.DeleteAgent"] }
def x-amz-target-completer-14 [] { ["FmrsService.DeleteLocation"] }
def x-amz-target-completer-15 [] { ["FmrsService.DeleteTask"] }
def x-amz-target-completer-16 [] { ["FmrsService.DescribeAgent"] }
def x-amz-target-completer-17 [] { ["FmrsService.DescribeLocationEfs"] }
def x-amz-target-completer-18 [] { ["FmrsService.DescribeLocationFsxLustre"] }
def x-amz-target-completer-19 [] { ["FmrsService.DescribeLocationFsxOntap"] }
def x-amz-target-completer-20 [] { ["FmrsService.DescribeLocationFsxOpenZfs"] }
def x-amz-target-completer-21 [] { ["FmrsService.DescribeLocationFsxWindows"] }
def x-amz-target-completer-22 [] { ["FmrsService.DescribeLocationHdfs"] }
def x-amz-target-completer-23 [] { ["FmrsService.DescribeLocationNfs"] }
def x-amz-target-completer-24 [] { ["FmrsService.DescribeLocationObjectStorage"] }
def x-amz-target-completer-25 [] { ["FmrsService.DescribeLocationS3"] }
def x-amz-target-completer-26 [] { ["FmrsService.DescribeLocationSmb"] }
def x-amz-target-completer-27 [] { ["FmrsService.DescribeTask"] }
def x-amz-target-completer-28 [] { ["FmrsService.DescribeTaskExecution"] }
def x-amz-target-completer-29 [] { ["FmrsService.ListAgents"] }
def x-amz-target-completer-30 [] { ["FmrsService.ListLocations"] }
def x-amz-target-completer-31 [] { ["FmrsService.ListTagsForResource"] }
def x-amz-target-completer-32 [] { ["FmrsService.ListTaskExecutions"] }
def x-amz-target-completer-33 [] { ["FmrsService.ListTasks"] }
def x-amz-target-completer-34 [] { ["FmrsService.StartTaskExecution"] }
def x-amz-target-completer-35 [] { ["FmrsService.TagResource"] }
def x-amz-target-completer-36 [] { ["FmrsService.UntagResource"] }
def x-amz-target-completer-37 [] { ["FmrsService.UpdateAgent"] }
def x-amz-target-completer-38 [] { ["FmrsService.UpdateLocationHdfs"] }
def x-amz-target-completer-39 [] { ["FmrsService.UpdateLocationNfs"] }
def x-amz-target-completer-40 [] { ["FmrsService.UpdateLocationObjectStorage"] }
def x-amz-target-completer-41 [] { ["FmrsService.UpdateLocationSmb"] }
def x-amz-target-completer-42 [] { ["FmrsService.UpdateTask"] }
def x-amz-target-completer-43 [] { ["FmrsService.UpdateTaskExecution"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    cancel-task-execution: "record"
    create-agent: "record<AgentArn: string>"
    create-location-efs: "record<LocationArn: string>"
    create-location-fsx-lustre: "record<LocationArn: string>"
    create-location-fsx-ontap: "record<LocationArn: string>"
    create-location-fsx-open-zfs: "record<LocationArn: string>"
    create-location-fsx-windows: "record<LocationArn: string>"
    create-location-hdfs: "record<LocationArn: string>"
    create-location-nfs: "record<LocationArn: string>"
    create-location-object-storage: "record<LocationArn: string>"
    create-location-s3: "record<LocationArn: string>"
    create-location-smb: "record<LocationArn: string>"
    create-task: "record<TaskArn: string>"
    delete-agent: "record"
    delete-location: "record"
    delete-task: "record"
    describe-agent: "record<AgentArn: string, Name: string, Status: string, LastConnectionTime: string, CreationTime: string, EndpointType: string, PrivateLinkConfig: record<VpcEndpointId: string, PrivateLinkEndpoint: string, SubnetArns: list<string>, SecurityGroupArns: list<string>>>"
    describe-location-efs: "record<LocationArn: string, LocationUri: string, Ec2Config: record<SubnetArn: string, SecurityGroupArns: list<string>>, CreationTime: string, AccessPointArn: string, FileSystemAccessRoleArn: string, InTransitEncryption: string>"
    describe-location-fsx-lustre: "record<LocationArn: string, LocationUri: string, SecurityGroupArns: list<string>, CreationTime: string>"
    describe-location-fsx-ontap: "record<CreationTime: string, LocationArn: string, LocationUri: string, Protocol: record<NFS: record<MountOptions: record>, SMB: record<Domain: string, MountOptions: record, Password: string, User: string>>, SecurityGroupArns: list<string>, StorageVirtualMachineArn: string, FsxFilesystemArn: string>"
    describe-location-fsx-open-zfs: "record<LocationArn: string, LocationUri: string, SecurityGroupArns: list<string>, Protocol: record<NFS: record<MountOptions: record>, SMB: record<Domain: string, MountOptions: record, Password: string, User: string>>, CreationTime: string>"
    describe-location-fsx-windows: "record<LocationArn: string, LocationUri: string, SecurityGroupArns: list<string>, CreationTime: string, User: string, Domain: string>"
    describe-location-hdfs: "record<LocationArn: string, LocationUri: string, NameNodes: table<Hostname: string, Port: int>, BlockSize: int, ReplicationFactor: int, KmsKeyProviderUri: string, QopConfiguration: record<RpcProtection: string, DataTransferProtection: string>, AuthenticationType: string, SimpleUser: string, KerberosPrincipal: string, AgentArns: list<string>, CreationTime: string>"
    describe-location-nfs: "record<LocationArn: string, LocationUri: string, OnPremConfig: record<AgentArns: list<string>>, MountOptions: record<Version: string>, CreationTime: string>"
    describe-location-object-storage: "record<LocationArn: string, LocationUri: string, AccessKey: string, ServerPort: int, ServerProtocol: string, AgentArns: list<string>, CreationTime: string, ServerCertificate: string>"
    describe-location-s3: "record<LocationArn: string, LocationUri: string, S3StorageClass: string, S3Config: record<BucketAccessRoleArn: string>, AgentArns: list<string>, CreationTime: string>"
    describe-location-smb: "record<LocationArn: string, LocationUri: string, AgentArns: list<string>, User: string, Domain: string, MountOptions: record<Version: string>, CreationTime: string>"
    describe-task: "record<TaskArn: string, Status: string, Name: string, CurrentTaskExecutionArn: string, SourceLocationArn: string, DestinationLocationArn: string, CloudWatchLogGroupArn: string, SourceNetworkInterfaceArns: list<string>, DestinationNetworkInterfaceArns: list<string>, Options: record<VerifyMode: string, OverwriteMode: string, Atime: string, Mtime: string, Uid: string, Gid: string, PreserveDeletedFiles: string, PreserveDevices: string, PosixPermissions: string, BytesPerSecond: int, TaskQueueing: string, LogLevel: string, TransferMode: string, SecurityDescriptorCopyFlags: string, ObjectTags: string>, Excludes: table<FilterType: string, Value: string>, Schedule: record<ScheduleExpression: string>, ErrorCode: string, ErrorDetail: string, CreationTime: string, Includes: table<FilterType: string, Value: string>>"
    describe-task-execution: "record<TaskExecutionArn: string, Status: string, Options: record<VerifyMode: string, OverwriteMode: string, Atime: string, Mtime: string, Uid: string, Gid: string, PreserveDeletedFiles: string, PreserveDevices: string, PosixPermissions: string, BytesPerSecond: int, TaskQueueing: string, LogLevel: string, TransferMode: string, SecurityDescriptorCopyFlags: string, ObjectTags: string>, Excludes: table<FilterType: string, Value: string>, Includes: table<FilterType: string, Value: string>, StartTime: string, EstimatedFilesToTransfer: int, EstimatedBytesToTransfer: int, FilesTransferred: int, BytesWritten: int, BytesTransferred: int, Result: record<PrepareDuration: int, PrepareStatus: string, TotalDuration: int, TransferDuration: int, TransferStatus: string, VerifyDuration: int, VerifyStatus: string, ErrorCode: string, ErrorDetail: string>, BytesCompressed: int>"
    list-agents: "record<Agents: table<AgentArn: string, Name: string, Status: string>, NextToken: string>"
    list-locations: "record<Locations: table<LocationArn: string, LocationUri: string>, NextToken: string>"
    list-tags-for-resource: "record<Tags: table<Key: string, Value: string>, NextToken: string>"
    list-task-executions: "record<TaskExecutions: table<TaskExecutionArn: string, Status: string>, NextToken: string>"
    list-tasks: "record<Tasks: table<TaskArn: string, Status: string, Name: string>, NextToken: string>"
    start-task-execution: "record<TaskExecutionArn: string>"
    tag-resource: "record"
    untag-resource: "record"
    update-agent: "record"
    update-location-hdfs: "record"
    update-location-nfs: "record"
    update-location-object-storage: "record"
    update-location-smb: "record"
    update-task: "record"
    update-task-execution: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["cancel-task-execution" "create-agent" "create-location-efs" "create-location-fsx-lustre" "create-location-fsx-ontap" "create-location-fsx-open-zfs" "create-location-fsx-windows" "create-location-hdfs" "create-location-nfs" "create-location-object-storage" "create-location-s3" "create-location-smb" "create-task" "delete-agent" "delete-location" "delete-task" "describe-agent" "describe-location-efs" "describe-location-fsx-lustre" "describe-location-fsx-ontap" "describe-location-fsx-open-zfs" "describe-location-fsx-windows" "describe-location-hdfs" "describe-location-nfs" "describe-location-object-storage" "describe-location-s3" "describe-location-smb" "describe-task" "describe-task-execution" "list-agents" "list-locations" "list-tags-for-resource" "list-task-executions" "list-tasks" "start-task-execution" "tag-resource" "untag-resource" "update-agent" "update-location-hdfs" "update-location-nfs" "update-location-object-storage" "update-location-smb" "update-task" "update-task-execution" "commands"] | sort) } | get name | first)
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

# Stops an DataSync task execution that's in progress. The transfer of some files are abruptly interrupted. File contents that're transferred to the destination might be incomplete or inconsistent with the source files. However, if you start a new task execution using the same task and allow it to finish, file content on the destination will be complete and consistent. This applies to other unexpected failures that interrupt a task execution. In all of these cases, DataSync successfully completes the transfer when you start the next task execution.
#
# POST /
# Returns: record
# operationId: CancelTaskExecution
export def "cancel-task-execution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  task_execution_arn: string # The Amazon Resource Name (ARN) of the task execution to stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.CancelTaskExecution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TaskExecutionArn, var: task_execution_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, task_execution_arn: $task_execution_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activates an DataSync agent that you have deployed in your storage environment. The activation process associates your agent with your account. In the activation process, you specify information such as the Amazon Web Services Region that you want to activate the agent in. You activate the agent in the Amazon Web Services Region where your target locations (in Amazon S3 or Amazon EFS) reside. Your tasks are created in this Amazon Web Services Region. You can activate the agent in a VPC (virtual private cloud) or provide the agent access to a VPC endpoint so you can run tasks without going over the public internet. You can use an agent for more than one location. If a task uses multiple agents, all of them need to have status AVAILABLE for the task to run. If you use multiple agents for a source location, the status of all the agents must be AVAILABLE for the task to run. Agents are automatically updated by Amazon Web Services on a regular basis, using a mechanism that ensures minimal interruption to your tasks.
#
# POST /
# Returns: record<AgentArn: string>
# operationId: CreateAgent
export def "create-agent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  activation_key: string # Your agent activation key. You can get the activation key either by sending an HTTP GET request with redirects that enable you to get the agent IP address (port 80). Alternatively, you can get it from the DataSync console. The redirect URL returned in the response provides you the activation key for your agent in the query string parameter activationKey. It might also include other activation-related parameters; however, these are merely defaults. The arguments you pass to this API call determine the actual configuration of your agent. For more information, see Activating an Agent in the DataSync User Guide.
  --agent-name: string # The name you configured for your agent. This value is a text reference that is used to identify the agent in the console.
  --tags: list # The key-value pair that represents the tag that you want to associate with the agent. The value can be an empty string. This value helps you manage, filter, and search for your agents. Valid characters for key and value are letters, spaces, and numbers representable in UTF-8 format, and the following special characters: + - = . _ : / @. — item shape: {Key: string, Value?: string}
  --vpc-endpoint-id: string # The ID of the VPC (virtual private cloud) endpoint that the agent has access to. This is the client-side VPC endpoint, also called a PrivateLink. If you don't have a PrivateLink VPC endpoint, see Creating a VPC Endpoint Service Configuration (https://docs.aws.amazon.com/vpc/latest/userguide/endpoint-service.html#create-endpoint-service) in the Amazon VPC User Guide. VPC endpoint ID looks like this: vpce-01234d5aff67890e1.
  --subnet-arns: list<string> # The Amazon Resource Names (ARNs) of the subnets in which DataSync will create elastic network interfaces for each data transfer task. The agent that runs a task must be private. When you start a task that is associated with an agent created in a VPC, or one that has access to an IP address in a VPC, then the task is also private. In this case, DataSync creates four network interfaces for each task in your subnet. For a data transfer to work, the agent must be able to route to all these four network interfaces.
  --security-group-arns: list<string> # The ARNs of the security groups used to protect your data transfer task subnets. See SecurityGroupArns (https://docs.aws.amazon.com/datasync/latest/userguide/API_Ec2Config.html#DataSync-Type-Ec2Config-SecurityGroupArns).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.CreateAgent"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ActivationKey, var: activation_key}, {name: AgentName, var: agent_name}, {name: Tags, var: tags}, {name: VpcEndpointId, var: vpc_endpoint_id}, {name: SubnetArns, var: subnet_arns}, {name: SecurityGroupArns, var: security_group_arns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, activation_key: $activation_key, agent_name: $agent_name, tags: $tags, vpc_endpoint_id: $vpc_endpoint_id, subnet_arns: $subnet_arns, security_group_arns: $security_group_arns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an endpoint for an Amazon EFS file system that DataSync can access for a transfer. For more information, see Creating a location for Amazon EFS (https://docs.aws.amazon.com/datasync/latest/userguide/create-efs-location.html).
#
# POST /
# Returns: record<LocationArn: string>
# operationId: CreateLocationEfs
export def "create-location-efs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --subdirectory: string # Specifies a mount path for your Amazon EFS file system. This is where DataSync reads or writes data (depending on if this is a source or destination location). By default, DataSync uses the root directory, but you can also include subdirectories. You must specify a value with forward slashes (for example, /path/to/folder).
  efs_filesystem_arn: string # Specifies the ARN for the Amazon EFS file system.
  ec2_config: record # The subnet and security groups that DataSync uses to access your Amazon EFS file system. — shape: {SubnetArn: string, SecurityGroupArns: list<string>}
  --tags: list # Specifies the key-value pair that represents a tag that you want to add to the resource. The value can be an empty string. This value helps you manage, filter, and search for your resources. We recommend that you create a name tag for your location. — item shape: {Key: string, Value?: string}
  --access-point-arn: string # Specifies the Amazon Resource Name (ARN) of the access point that DataSync uses to access the Amazon EFS file system.
  --file-system-access-role-arn: string # Specifies an Identity and Access Management (IAM) role that DataSync assumes when mounting the Amazon EFS file system.
  --in-transit-encryption: string@in-transit-encryption-completer # Specifies whether you want DataSync to use Transport Layer Security (TLS) 1.2 encryption when it copies data to or from the Amazon EFS file system. If you specify an access point using AccessPointArn or an IAM role using FileSystemAccessRoleArn, you must set this parameter to TLS1_2.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.CreateLocationEfs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Subdirectory, var: subdirectory}, {name: EfsFilesystemArn, var: efs_filesystem_arn}, {name: Ec2Config, var: ec2_config}, {name: Tags, var: tags}, {name: AccessPointArn, var: access_point_arn}, {name: FileSystemAccessRoleArn, var: file_system_access_role_arn}, {name: InTransitEncryption, var: in_transit_encryption}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subdirectory: $subdirectory, efs_filesystem_arn: $efs_filesystem_arn, ec2_config: $ec2_config, tags: $tags, access_point_arn: $access_point_arn, file_system_access_role_arn: $file_system_access_role_arn, in_transit_encryption: $in_transit_encryption
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an endpoint for an Amazon FSx for Lustre file system.
#
# POST /
# Returns: record<LocationArn: string>
# operationId: CreateLocationFsxLustre
export def "create-location-fsx-lustre" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  fsx_filesystem_arn: string # The Amazon Resource Name (ARN) for the FSx for Lustre file system.
  security_group_arns: list<string> # The Amazon Resource Names (ARNs) of the security groups that are used to configure the FSx for Lustre file system.
  --subdirectory: string # A subdirectory in the location's path. This subdirectory in the FSx for Lustre file system is used to read data from the FSx for Lustre source location or write data to the FSx for Lustre destination.
  --tags: list # The key-value pair that represents a tag that you want to add to the resource. The value can be an empty string. This value helps you manage, filter, and search for your resources. We recommend that you create a name tag for your location. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.CreateLocationFsxLustre"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FsxFilesystemArn, var: fsx_filesystem_arn}, {name: SecurityGroupArns, var: security_group_arns}, {name: Subdirectory, var: subdirectory}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, fsx_filesystem_arn: $fsx_filesystem_arn, security_group_arns: $security_group_arns, subdirectory: $subdirectory, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an endpoint for an Amazon FSx for NetApp ONTAP file system that DataSync can access for a transfer. For more information, see Creating a location for FSx for ONTAP (https://docs.aws.amazon.com/datasync/latest/userguide/create-ontap-location.html).
#
# POST /
# Returns: record<LocationArn: string>
# operationId: CreateLocationFsxOntap
export def "create-location-fsx-ontap" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  protocol: record # Specifies the data transfer protocol that DataSync uses to access your Amazon FSx file system. — shape: {NFS?: record, SMB?: record}
  security_group_arns: list<string> # Specifies the Amazon EC2 security groups that provide access to your file system's preferred subnet. The security groups must allow outbound traffic on the following ports (depending on the protocol you use): Network File System (NFS): TCP ports 111, 635, and 2049 Server Message Block (SMB): TCP port 445 Your file system's security groups must also allow inbound traffic on the same ports.
  storage_virtual_machine_arn: string # Specifies the ARN of the storage virtual machine (SVM) in your file system where you want to copy data to or from.
  --subdirectory: string # Specifies a path to the file share in the SVM where you'll copy your data. You can specify a junction path (also known as a mount point), qtree path (for NFS file shares), or share name (for SMB file shares). For example, your mount path might be /vol1, /vol1/tree1, or /share1. Don't specify a junction path in the SVM's root volume. For more information, see Managing FSx for ONTAP storage virtual machines (https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/managing-svms.html) in the Amazon FSx for NetApp ONTAP User Guide.
  --tags: list # Specifies labels that help you categorize, filter, and search for your Amazon Web Services resources. We recommend creating at least a name tag for your location. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.CreateLocationFsxOntap"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Protocol, var: protocol}, {name: SecurityGroupArns, var: security_group_arns}, {name: StorageVirtualMachineArn, var: storage_virtual_machine_arn}, {name: Subdirectory, var: subdirectory}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, protocol: $protocol, security_group_arns: $security_group_arns, storage_virtual_machine_arn: $storage_virtual_machine_arn, subdirectory: $subdirectory, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an endpoint for an Amazon FSx for OpenZFS file system that DataSync can access for a transfer. For more information, see Creating a location for FSx for OpenZFS (https://docs.aws.amazon.com/datasync/latest/userguide/create-openzfs-location.html). Request parameters related to SMB aren't supported with the CreateLocationFsxOpenZfs operation.
#
# POST /
# Returns: record<LocationArn: string>
# operationId: CreateLocationFsxOpenZfs
export def "create-location-fsx-open-zfs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  fsx_filesystem_arn: string # The Amazon Resource Name (ARN) of the FSx for OpenZFS file system.
  protocol: record # Specifies the data transfer protocol that DataSync uses to access your Amazon FSx file system. — shape: {NFS?: record, SMB?: record}
  security_group_arns: list<string> # The ARNs of the security groups that are used to configure the FSx for OpenZFS file system.
  --subdirectory: string # A subdirectory in the location's path that must begin with /fsx. DataSync uses this subdirectory to read or write data (depending on whether the file system is a source or destination location).
  --tags: list # The key-value pair that represents a tag that you want to add to the resource. The value can be an empty string. This value helps you manage, filter, and search for your resources. We recommend that you create a name tag for your location. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.CreateLocationFsxOpenZfs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FsxFilesystemArn, var: fsx_filesystem_arn}, {name: Protocol, var: protocol}, {name: SecurityGroupArns, var: security_group_arns}, {name: Subdirectory, var: subdirectory}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, fsx_filesystem_arn: $fsx_filesystem_arn, protocol: $protocol, security_group_arns: $security_group_arns, subdirectory: $subdirectory, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an endpoint for an Amazon FSx for Windows File Server file system.
#
# POST /
# Returns: record<LocationArn: string>
# operationId: CreateLocationFsxWindows
export def "create-location-fsx-windows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --subdirectory: string # Specifies a mount path for your file system using forward slashes. This is where DataSync reads or writes data (depending on if this is a source or destination location).
  fsx_filesystem_arn: string # Specifies the Amazon Resource Name (ARN) for the FSx for Windows File Server file system.
  security_group_arns: list<string> # Specifies the ARNs of the security groups that provide access to your file system's preferred subnet. If you choose a security group that doesn't allow connections from within itself, do one of the following: Configure the security group to allow it to communicate within itself. Choose a different security group that can communicate with the mount target's security group.
  --tags: list # Specifies labels that help you categorize, filter, and search for your Amazon Web Services resources. We recommend creating at least a name tag for your location. — item shape: {Key: string, Value?: string}
  user: string # Specifies the user who has the permissions to access files and folders in the file system. For information about choosing a user name that ensures sufficient permissions to files, folders, and metadata, see user (create-fsx-location.html#FSxWuser).
  --domain: string # Specifies the name of the Windows domain that the FSx for Windows File Server belongs to.
  password: string # Specifies the password of the user who has the permissions to access files and folders in the file system. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.CreateLocationFsxWindows"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Subdirectory, var: subdirectory}, {name: FsxFilesystemArn, var: fsx_filesystem_arn}, {name: SecurityGroupArns, var: security_group_arns}, {name: Tags, var: tags}, {name: User, var: user}, {name: Domain, var: domain}, {name: Password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subdirectory: $subdirectory, fsx_filesystem_arn: $fsx_filesystem_arn, security_group_arns: $security_group_arns, tags: $tags, user: $user, domain: $domain, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an endpoint for a Hadoop Distributed File System (HDFS).
#
# POST /
# Returns: record<LocationArn: string>
# operationId: CreateLocationHdfs
export def "create-location-hdfs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --subdirectory: string # A subdirectory in the HDFS cluster. This subdirectory is used to read data from or write data to the HDFS cluster. If the subdirectory isn't specified, it will default to /.
  name_nodes: list # The NameNode that manages the HDFS namespace. The NameNode performs operations such as opening, closing, and renaming files and directories. The NameNode contains the information to map blocks of data to the DataNodes. You can use only one NameNode. — item shape: {Hostname: string, Port: int}
  --block-size: int # The size of data blocks to write into the HDFS cluster. The block size must be a multiple of 512 bytes. The default block size is 128 mebibytes (MiB).
  --replication-factor: int # The number of DataNodes to replicate the data to when writing to the HDFS cluster. By default, data is replicated to three DataNodes.
  --kms-key-provider-uri: string # The URI of the HDFS cluster's Key Management Server (KMS).
  --qop-configuration: record # The Quality of Protection (QOP) configuration specifies the Remote Procedure Call (RPC) and data transfer privacy settings configured on the Hadoop Distributed File System (HDFS) cluster. — shape: {RpcProtection?: "DISABLED"|"AUTHENTICATION"|"INTEGRITY"|"PRIVACY", DataTransferProtection?: "DISABLED"|"AUTHENTICATION"|"INTEGRITY"|"PRIVACY"}
  authentication_type: string@authentication-type-completer # The type of authentication used to determine the identity of the user.
  --simple-user: string # The user name used to identify the client on the host operating system. If SIMPLE is specified for AuthenticationType, this parameter is required.
  --kerberos-principal: string # The Kerberos principal with access to the files and folders on the HDFS cluster. If KERBEROS is specified for AuthenticationType, this parameter is required.
  --kerberos-keytab: string # The Kerberos key table (keytab) that contains mappings between the defined Kerberos principal and the encrypted keys. You can load the keytab from a file by providing the file's address. If you're using the CLI, it performs base64 encoding for you. Otherwise, provide the base64-encoded text. If KERBEROS is specified for AuthenticationType, this parameter is required.
  --kerberos-krb5-conf: string # The krb5.conf file that contains the Kerberos configuration information. You can load the krb5.conf file by providing the file's address. If you're using the CLI, it performs the base64 encoding for you. Otherwise, provide the base64-encoded text. If KERBEROS is specified for AuthenticationType, this parameter is required.
  agent_arns: list<string> # The Amazon Resource Names (ARNs) of the agents that are used to connect to the HDFS cluster.
  --tags: list # The key-value pair that represents the tag that you want to add to the location. The value can be an empty string. We recommend using tags to name your resources. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.CreateLocationHdfs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Subdirectory, var: subdirectory}, {name: NameNodes, var: name_nodes}, {name: BlockSize, var: block_size}, {name: ReplicationFactor, var: replication_factor}, {name: KmsKeyProviderUri, var: kms_key_provider_uri}, {name: QopConfiguration, var: qop_configuration}, {name: AuthenticationType, var: authentication_type}, {name: SimpleUser, var: simple_user}, {name: KerberosPrincipal, var: kerberos_principal}, {name: KerberosKeytab, var: kerberos_keytab}, {name: KerberosKrb5Conf, var: kerberos_krb5_conf}, {name: AgentArns, var: agent_arns}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subdirectory: $subdirectory, name_nodes: $name_nodes, block_size: $block_size, replication_factor: $replication_factor, kms_key_provider_uri: $kms_key_provider_uri, qop_configuration: $qop_configuration, authentication_type: $authentication_type, simple_user: $simple_user, kerberos_principal: $kerberos_principal, kerberos_keytab: $kerberos_keytab, kerberos_krb5_conf: $kerberos_krb5_conf, agent_arns: $agent_arns, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Defines a file system on a Network File System (NFS) server that can be read from or written to.
#
# POST /
# Returns: record<LocationArn: string>
# operationId: CreateLocationNfs
export def "create-location-nfs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  subdirectory: string # The subdirectory in the NFS file system that is used to read data from the NFS source location or write data to the NFS destination. The NFS path should be a path that's exported by the NFS server, or a subdirectory of that path. The path should be such that it can be mounted by other NFS clients in your network. To see all the paths exported by your NFS server, run "showmount -e nfs-server-name" from an NFS client that has access to your server. You can specify any directory that appears in the results, and any subdirectory of that directory. Ensure that the NFS export is accessible without Kerberos authentication. To transfer all the data in the folder you specified, DataSync needs to have permissions to read all the data. To ensure this, either configure the NFS export with no_root_squash, or ensure that the permissions for all of the files that you want DataSync allow read access for all users. Doing either enables the agent to read the files. For the agent to access directories, you must additionally enable all execute access. If you are copying data to or from your Snowcone device, see NFS Server on Snowcone (https://docs.aws.amazon.com/datasync/latest/userguide/create-nfs-location.html#nfs-on-snowcone) for more information. For information about NFS export configuration, see 18.7. The /etc/exports Configuration File in the Red Hat Enterprise Linux documentation.
  server_hostname: string # The name of the NFS server. This value is the IP address or Domain Name Service (DNS) name of the NFS server. An agent that is installed on-premises uses this hostname to mount the NFS server in a network. If you are copying data to or from your Snowcone device, see NFS Server on Snowcone (https://docs.aws.amazon.com/datasync/latest/userguide/create-nfs-location.html#nfs-on-snowcone) for more information. This name must either be DNS-compliant or must be an IP version 4 (IPv4) address.
  on_prem_config: record # A list of Amazon Resource Names (ARNs) of agents to use for a Network File System (NFS) location. — shape: {AgentArns: list<string>}
  --mount-options: record # Specifies how DataSync can access a location using the NFS protocol. — shape: {Version?: "AUTOMATIC"|"NFS3"|"NFS4_0"|"NFS4_1"}
  --tags: list # The key-value pair that represents the tag that you want to add to the location. The value can be an empty string. We recommend using tags to name your resources. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.CreateLocationNfs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Subdirectory, var: subdirectory}, {name: ServerHostname, var: server_hostname}, {name: OnPremConfig, var: on_prem_config}, {name: MountOptions, var: mount_options}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subdirectory: $subdirectory, server_hostname: $server_hostname, on_prem_config: $on_prem_config, mount_options: $mount_options, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an endpoint for an object storage system that DataSync can access for a transfer. For more information, see Creating a location for object storage (https://docs.aws.amazon.com/datasync/latest/userguide/create-object-location.html).
#
# POST /
# Returns: record<LocationArn: string>
# operationId: CreateLocationObjectStorage
export def "create-location-object-storage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  server_hostname: string # Specifies the domain name or IP address of the object storage server. A DataSync agent uses this hostname to mount the object storage server in a network.
  --server-port: int # Specifies the port that your object storage server accepts inbound network traffic on (for example, port 443).
  --server-protocol: string@server-protocol-completer # Specifies the protocol that your object storage server uses to communicate.
  --subdirectory: string # Specifies the object prefix for your object storage server. If this is a source location, DataSync only copies objects with this prefix. If this is a destination location, DataSync writes all objects with this prefix.
  bucket_name: string # Specifies the name of the object storage bucket involved in the transfer.
  --access-key: string # Specifies the access key (for example, a user name) if credentials are required to authenticate with the object storage server.
  --secret-key: string # Specifies the secret key (for example, a password) if credentials are required to authenticate with the object storage server. (format: password)
  agent_arns: list<string> # Specifies the Amazon Resource Names (ARNs) of the DataSync agents that can securely connect with your location.
  --tags: list # Specifies the key-value pair that represents a tag that you want to add to the resource. Tags can help you manage, filter, and search for your resources. We recommend creating a name tag for your location. — item shape: {Key: string, Value?: string}
  --server-certificate: string # Specifies a certificate to authenticate with an object storage system that uses a private or self-signed certificate authority (CA). You must specify a Base64-encoded .pem file (for example, file:///home/user/.ssh/storage_sys_certificate.pem). The certificate can be up to 32768 bytes (before Base64 encoding). To use this parameter, configure ServerProtocol to HTTPS.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.CreateLocationObjectStorage"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServerHostname, var: server_hostname}, {name: ServerPort, var: server_port}, {name: ServerProtocol, var: server_protocol}, {name: Subdirectory, var: subdirectory}, {name: BucketName, var: bucket_name}, {name: AccessKey, var: access_key}, {name: SecretKey, var: secret_key}, {name: AgentArns, var: agent_arns}, {name: Tags, var: tags}, {name: ServerCertificate, var: server_certificate}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, server_hostname: $server_hostname, server_port: $server_port, server_protocol: $server_protocol, subdirectory: $subdirectory, bucket_name: $bucket_name, access_key: $access_key, secret_key: $secret_key, agent_arns: $agent_arns, tags: $tags, server_certificate: $server_certificate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an endpoint for an Amazon S3 bucket that DataSync can access for a transfer. For more information, see Create an Amazon S3 location (https://docs.aws.amazon.com/datasync/latest/userguide/create-locations-cli.html#create-location-s3-cli).
#
# POST /
# Returns: record<LocationArn: string>
# operationId: CreateLocationS3
export def "create-location-s3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --subdirectory: string # A subdirectory in the Amazon S3 bucket. This subdirectory in Amazon S3 is used to read data from the S3 source location or write data to the S3 destination.
  s3_bucket_arn: string # The ARN of the Amazon S3 bucket. If the bucket is on an Amazon Web Services Outpost, this must be an access point ARN.
  --s3-storage-class: string@s3-storage-class-completer # The Amazon S3 storage class that you want to store your files in when this location is used as a task destination. For buckets in Amazon Web Services Regions, the storage class defaults to Standard. For buckets on Outposts, the storage class defaults to Amazon Web Services S3 Outposts. For more information about S3 storage classes, see Amazon S3 Storage Classes (http://aws.amazon.com/s3/storage-classes/). Some storage classes have behaviors that can affect your S3 storage cost. For detailed information, see Considerations when working with S3 storage classes in DataSync (https://docs.aws.amazon.com/datasync/latest/userguide/create-s3-location.html#using-storage-classes).
  s3_config: record # The Amazon Resource Name (ARN) of the Identity and Access Management (IAM) role used to access an Amazon S3 bucket. For detailed information about using such a role, see Creating a Location for Amazon S3 in the DataSync User Guide. — shape: {BucketAccessRoleArn: string}
  --agent-arns: list<string> # If you're using DataSync on an Amazon Web Services Outpost, specify the Amazon Resource Names (ARNs) of the DataSync agents deployed on your Outpost. For more information about launching a DataSync agent on an Amazon Web Services Outpost, see Deploy your DataSync agent on Outposts (https://docs.aws.amazon.com/datasync/latest/userguide/deploy-agents.html#outposts-agent).
  --tags: list # The key-value pair that represents the tag that you want to add to the location. The value can be an empty string. We recommend using tags to name your resources. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.CreateLocationS3"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Subdirectory, var: subdirectory}, {name: S3BucketArn, var: s3_bucket_arn}, {name: S3StorageClass, var: s3_storage_class}, {name: S3Config, var: s3_config}, {name: AgentArns, var: agent_arns}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subdirectory: $subdirectory, s3_bucket_arn: $s3_bucket_arn, s3_storage_class: $s3_storage_class, s3_config: $s3_config, agent_arns: $agent_arns, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an endpoint for a Server Message Block (SMB) file server that DataSync can access for a transfer. For more information, see Creating an SMB location (https://docs.aws.amazon.com/datasync/latest/userguide/create-smb-location.html).
#
# POST /
# Returns: record<LocationArn: string>
# operationId: CreateLocationSmb
export def "create-location-smb" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  subdirectory: string # Specifies the name of the share exported by your SMB file server where DataSync will read or write data. You can include a subdirectory in the share path (for example, /path/to/subdirectory). Make sure that other SMB clients in your network can also mount this path. To copy all data in the specified subdirectory, DataSync must be able to mount the SMB share and access all of its data. For more information, see required permissions (https://docs.aws.amazon.com/datasync/latest/userguide/create-smb-location.html#configuring-smb-permissions) for SMB locations.
  server_hostname: string # Specifies the Domain Name Service (DNS) name or IP address of the SMB file server that your DataSync agent will mount. You can't specify an IP version 6 (IPv6) address.
  user: string # Specifies the user name that can mount your SMB file server and has permission to access the files and folders involved in your transfer. For information about choosing a user with the right level of access for your transfer, see required permissions (https://docs.aws.amazon.com/datasync/latest/userguide/create-smb-location.html#configuring-smb-permissions) for SMB locations.
  --domain: string # Specifies the Windows domain name that your SMB file server belongs to. For more information, see required permissions (https://docs.aws.amazon.com/datasync/latest/userguide/create-smb-location.html#configuring-smb-permissions) for SMB locations.
  password: string # Specifies the password of the user who can mount your SMB file server and has permission to access the files and folders involved in your transfer. For more information, see required permissions (https://docs.aws.amazon.com/datasync/latest/userguide/create-smb-location.html#configuring-smb-permissions) for SMB locations. (format: password)
  agent_arns: list<string> # Specifies the DataSync agent (or agents) which you want to connect to your SMB file server. You specify an agent by using its Amazon Resource Name (ARN).
  --mount-options: record # Specifies the version of the Server Message Block (SMB) protocol that DataSync uses to access an SMB file server. — shape: {Version?: "AUTOMATIC"|"SMB2"|"SMB3"|"SMB1"|"SMB2_0"}
  --tags: list # Specifies labels that help you categorize, filter, and search for your Amazon Web Services resources. We recommend creating at least a name tag for your location. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.CreateLocationSmb"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Subdirectory, var: subdirectory}, {name: ServerHostname, var: server_hostname}, {name: User, var: user}, {name: Domain, var: domain}, {name: Password, var: password}, {name: AgentArns, var: agent_arns}, {name: MountOptions, var: mount_options}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subdirectory: $subdirectory, server_hostname: $server_hostname, user: $user, domain: $domain, password: $password, agent_arns: $agent_arns, mount_options: $mount_options, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configures a task, which defines where and how DataSync transfers your data. A task includes a source location, a destination location, and the preferences for how and when you want to transfer your data (such as bandwidth limits, scheduling, among other options).
#
# POST /
# Returns: record<TaskArn: string>
# operationId: CreateTask
export def "create-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  source_location_arn: string # The Amazon Resource Name (ARN) of the source location for the task.
  destination_location_arn: string # The Amazon Resource Name (ARN) of an Amazon Web Services storage resource's location.
  --cloud-watch-log-group-arn: string # The Amazon Resource Name (ARN) of the Amazon CloudWatch log group that is used to monitor and log events in the task.
  --name: string # The name of a task. This value is a text reference that is used to identify the task in the console.
  --options: record # Configures your DataSync task settings. These options include how DataSync handles files, objects, and their associated metadata. You also can specify how DataSync verifies data integrity, set bandwidth limits for your task, among other options. Each task setting has a default value. Unless you need to, you don't have to configure any of these Options before starting your task. — shape: {VerifyMode?: "POINT_IN_TIME_CONSISTENT"|"ONLY_FILES_TRANSFERRED"|"NONE", OverwriteMode?: "ALWAYS"|"NEVER", Atime?: "NONE"|"BEST_EFFORT", Mtime?: "NONE"|"PRESERVE", Uid?: "NONE"|"INT_VALUE"|"NAME"|"BOTH", Gid?: "NONE"|"INT_VALUE"|"NAME"|"BOTH", PreserveDeletedFiles?: "PRESERVE"|"REMOVE", PreserveDevices?: "NONE"|"PRESERVE", PosixPermissions?: "NONE"|"PRESERVE", BytesPerSecond?: int, TaskQueueing?: "ENABLED"|"DISABLED", LogLevel?: "OFF"|"BASIC"|"TRANSFER", TransferMode?: "CHANGED"|"ALL", ... (2 more fields)}
  --excludes: list # Specifies a list of filter rules that exclude specific data during your transfer. For more information and examples, see Filtering data transferred by DataSync (https://docs.aws.amazon.com/datasync/latest/userguide/filtering.html). — item shape: {FilterType?: "SIMPLE_PATTERN", Value?: string}
  --schedule: record # Specifies the schedule you want your task to use for repeated executions. For more information, see Schedule Expressions for Rules (https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html). — shape: {ScheduleExpression: string}
  --tags: list # Specifies the tags that you want to apply to the Amazon Resource Name (ARN) representing the task. Tags are key-value pairs that help you manage, filter, and search for your DataSync resources. — item shape: {Key: string, Value?: string}
  --includes: list # Specifies a list of filter rules that include specific data during your transfer. For more information and examples, see Filtering data transferred by DataSync (https://docs.aws.amazon.com/datasync/latest/userguide/filtering.html). — item shape: {FilterType?: "SIMPLE_PATTERN", Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.CreateTask"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SourceLocationArn, var: source_location_arn}, {name: DestinationLocationArn, var: destination_location_arn}, {name: CloudWatchLogGroupArn, var: cloud_watch_log_group_arn}, {name: Name, var: name}, {name: Options, var: options}, {name: Excludes, var: excludes}, {name: Schedule, var: schedule}, {name: Tags, var: tags}, {name: Includes, var: includes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, source_location_arn: $source_location_arn, destination_location_arn: $destination_location_arn, cloud_watch_log_group_arn: $cloud_watch_log_group_arn, name: $name, options: $options, excludes: $excludes, schedule: $schedule, tags: $tags, includes: $includes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an agent. To specify which agent to delete, use the Amazon Resource Name (ARN) of the agent in your request. The operation disassociates the agent from your Amazon Web Services account. However, it doesn't delete the agent virtual machine (VM) from your on-premises environment.
#
# POST /
# Returns: record
# operationId: DeleteAgent
export def "delete-agent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  agent_arn: string # The Amazon Resource Name (ARN) of the agent to delete. Use the ListAgents operation to return a list of agents for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.DeleteAgent"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AgentArn, var: agent_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, agent_arn: $agent_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the configuration of a location used by DataSync.
#
# POST /
# Returns: record
# operationId: DeleteLocation
export def "delete-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  location_arn: string # The Amazon Resource Name (ARN) of the location to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.DeleteLocation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LocationArn, var: location_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, location_arn: $location_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an DataSync task.
#
# POST /
# Returns: record
# operationId: DeleteTask
export def "delete-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  task_arn: string # Specifies the Amazon Resource Name (ARN) of the task that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.DeleteTask"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TaskArn, var: task_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, task_arn: $task_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns metadata about an DataSync agent, such as its name, endpoint type, and status.
#
# POST /
# Returns: record<AgentArn: string, Name: string, Status: string, LastConnectionTime: string, CreationTime: string, EndpointType: string, PrivateLinkConfig: record<VpcEndpointId: string, PrivateLinkEndpoint: string, SubnetArns: list<string>, SecurityGroupArns: list<string>>>
# operationId: DescribeAgent
export def "describe-agent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  agent_arn: string # Specifies the Amazon Resource Name (ARN) of the DataSync agent to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.DescribeAgent"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AgentArn, var: agent_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, agent_arn: $agent_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns metadata about your DataSync location for an Amazon EFS file system.
#
# POST /
# Returns: record<LocationArn: string, LocationUri: string, Ec2Config: record<SubnetArn: string, SecurityGroupArns: list<string>>, CreationTime: string, AccessPointArn: string, FileSystemAccessRoleArn: string, InTransitEncryption: string>
# operationId: DescribeLocationEfs
export def "describe-location-efs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  location_arn: string # The Amazon Resource Name (ARN) of the Amazon EFS file system location that you want information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.DescribeLocationEfs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LocationArn, var: location_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, location_arn: $location_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides details about how an DataSync location for an Amazon FSx for Lustre file system is configured.
#
# POST /
# Returns: record<LocationArn: string, LocationUri: string, SecurityGroupArns: list<string>, CreationTime: string>
# operationId: DescribeLocationFsxLustre
export def "describe-location-fsx-lustre" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  location_arn: string # The Amazon Resource Name (ARN) of the FSx for Lustre location to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.DescribeLocationFsxLustre"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LocationArn, var: location_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, location_arn: $location_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides details about how an DataSync location for an Amazon FSx for NetApp ONTAP file system is configured. If your location uses SMB, the DescribeLocationFsxOntap operation doesn't actually return a Password.
#
# POST /
# Returns: record<CreationTime: string, LocationArn: string, LocationUri: string, Protocol: record<NFS: record<MountOptions: record>, SMB: record<Domain: string, MountOptions: record, Password: string, User: string>>, SecurityGroupArns: list<string>, StorageVirtualMachineArn: string, FsxFilesystemArn: string>
# operationId: DescribeLocationFsxOntap
export def "describe-location-fsx-ontap" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  location_arn: string # Specifies the Amazon Resource Name (ARN) of the FSx for ONTAP file system location that you want information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.DescribeLocationFsxOntap"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LocationArn, var: location_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, location_arn: $location_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides details about how an DataSync location for an Amazon FSx for OpenZFS file system is configured. Response elements related to SMB aren't supported with the DescribeLocationFsxOpenZfs operation.
#
# POST /
# Returns: record<LocationArn: string, LocationUri: string, SecurityGroupArns: list<string>, Protocol: record<NFS: record<MountOptions: record>, SMB: record<Domain: string, MountOptions: record, Password: string, User: string>>, CreationTime: string>
# operationId: DescribeLocationFsxOpenZfs
export def "describe-location-fsx-open-zfs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  location_arn: string # The Amazon Resource Name (ARN) of the FSx for OpenZFS location to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.DescribeLocationFsxOpenZfs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LocationArn, var: location_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, location_arn: $location_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns metadata about an Amazon FSx for Windows File Server location, such as information about its path.
#
# POST /
# Returns: record<LocationArn: string, LocationUri: string, SecurityGroupArns: list<string>, CreationTime: string, User: string, Domain: string>
# operationId: DescribeLocationFsxWindows
export def "describe-location-fsx-windows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  location_arn: string # The Amazon Resource Name (ARN) of the FSx for Windows File Server location to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.DescribeLocationFsxWindows"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LocationArn, var: location_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, location_arn: $location_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns metadata, such as the authentication information about the Hadoop Distributed File System (HDFS) location.
#
# POST /
# Returns: record<LocationArn: string, LocationUri: string, NameNodes: table<Hostname: string, Port: int>, BlockSize: int, ReplicationFactor: int, KmsKeyProviderUri: string, QopConfiguration: record<RpcProtection: string, DataTransferProtection: string>, AuthenticationType: string, SimpleUser: string, KerberosPrincipal: string, AgentArns: list<string>, CreationTime: string>
# operationId: DescribeLocationHdfs
export def "describe-location-hdfs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  location_arn: string # The Amazon Resource Name (ARN) of the HDFS cluster location to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.DescribeLocationHdfs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LocationArn, var: location_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, location_arn: $location_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns metadata, such as the path information, about an NFS location.
#
# POST /
# Returns: record<LocationArn: string, LocationUri: string, OnPremConfig: record<AgentArns: list<string>>, MountOptions: record<Version: string>, CreationTime: string>
# operationId: DescribeLocationNfs
export def "describe-location-nfs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  location_arn: string # The Amazon Resource Name (ARN) of the NFS location to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.DescribeLocationNfs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LocationArn, var: location_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, location_arn: $location_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns metadata about your DataSync location for an object storage system.
#
# POST /
# Returns: record<LocationArn: string, LocationUri: string, AccessKey: string, ServerPort: int, ServerProtocol: string, AgentArns: list<string>, CreationTime: string, ServerCertificate: string>
# operationId: DescribeLocationObjectStorage
export def "describe-location-object-storage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  location_arn: string # The Amazon Resource Name (ARN) of the object storage system location that you want information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.DescribeLocationObjectStorage"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LocationArn, var: location_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, location_arn: $location_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns metadata, such as bucket name, about an Amazon S3 bucket location.
#
# POST /
# Returns: record<LocationArn: string, LocationUri: string, S3StorageClass: string, S3Config: record<BucketAccessRoleArn: string>, AgentArns: list<string>, CreationTime: string>
# operationId: DescribeLocationS3
export def "describe-location-s3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  location_arn: string # The Amazon Resource Name (ARN) of the Amazon S3 bucket location to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.DescribeLocationS3"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LocationArn, var: location_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, location_arn: $location_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns metadata, such as the path and user information about an SMB location.
#
# POST /
# Returns: record<LocationArn: string, LocationUri: string, AgentArns: list<string>, User: string, Domain: string, MountOptions: record<Version: string>, CreationTime: string>
# operationId: DescribeLocationSmb
export def "describe-location-smb" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  location_arn: string # The Amazon Resource Name (ARN) of the SMB location to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.DescribeLocationSmb"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LocationArn, var: location_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, location_arn: $location_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns metadata about a task.
#
# POST /
# Returns: record<TaskArn: string, Status: string, Name: string, CurrentTaskExecutionArn: string, SourceLocationArn: string, DestinationLocationArn: string, CloudWatchLogGroupArn: string, SourceNetworkInterfaceArns: list<string>, DestinationNetworkInterfaceArns: list<string>, Options: record<VerifyMode: string, OverwriteMode: string, Atime: string, Mtime: string, Uid: string, Gid: string, PreserveDeletedFiles: string, PreserveDevices: string, PosixPermissions: string, BytesPerSecond: int, TaskQueueing: string, LogLevel: string, TransferMode: string, SecurityDescriptorCopyFlags: string, ObjectTags: string>, Excludes: table<FilterType: string, Value: string>, Schedule: record<ScheduleExpression: string>, ErrorCode: string, ErrorDetail: string, CreationTime: string, Includes: table<FilterType: string, Value: string>>
# operationId: DescribeTask
export def "describe-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  task_arn: string # The Amazon Resource Name (ARN) of the task to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.DescribeTask"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TaskArn, var: task_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, task_arn: $task_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns detailed metadata about a task that is being executed.
#
# POST /
# Returns: record<TaskExecutionArn: string, Status: string, Options: record<VerifyMode: string, OverwriteMode: string, Atime: string, Mtime: string, Uid: string, Gid: string, PreserveDeletedFiles: string, PreserveDevices: string, PosixPermissions: string, BytesPerSecond: int, TaskQueueing: string, LogLevel: string, TransferMode: string, SecurityDescriptorCopyFlags: string, ObjectTags: string>, Excludes: table<FilterType: string, Value: string>, Includes: table<FilterType: string, Value: string>, StartTime: string, EstimatedFilesToTransfer: int, EstimatedBytesToTransfer: int, FilesTransferred: int, BytesWritten: int, BytesTransferred: int, Result: record<PrepareDuration: int, PrepareStatus: string, TotalDuration: int, TransferDuration: int, TransferStatus: string, VerifyDuration: int, VerifyStatus: string, ErrorCode: string, ErrorDetail: string>, BytesCompressed: int>
# operationId: DescribeTaskExecution
export def "describe-task-execution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  task_execution_arn: string # The Amazon Resource Name (ARN) of the task that is being executed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.DescribeTaskExecution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TaskExecutionArn, var: task_execution_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, task_execution_arn: $task_execution_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of DataSync agents that belong to an Amazon Web Services account in the Amazon Web Services Region specified in the request. With pagination, you can reduce the number of agents returned in a response. If you get a truncated list of agents in a response, the response contains a marker that you can specify in your next request to fetch the next page of agents. ListAgents is eventually consistent. This means the result of running the operation might not reflect that you just created or deleted an agent. For example, if you create an agent with CreateAgent (https://docs.aws.amazon.com/datasync/latest/userguide/API_CreateAgent.html) and then immediately run ListAgents, that agent might not show up in the list right away. In situations like this, you can always confirm whether an agent has been created (or deleted) by using DescribeAgent (https://docs.aws.amazon.com/datasync/latest/userguide/API_DescribeAgent.html).
#
# POST /
# Returns: record<Agents: table<AgentArn: string, Name: string, Status: string>, NextToken: string>
# operationId: ListAgents
export def "list-agents" [
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
  --x-amz-target: string@x-amz-target-completer-29 # required
  --body-max-results: int # Specifies the maximum number of DataSync agents to list in a response. By default, a response shows a maximum of 100 agents. (spec name: MaxResults)
  --body-next-token: string # Specifies an opaque string that indicates the position to begin the next list of results in the response. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.ListAgents"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of source and destination locations. If you have more locations than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a token that you can specify in your next request to fetch the next page of locations.
#
# POST /
# Returns: record<Locations: table<LocationArn: string, LocationUri: string>, NextToken: string>
# operationId: ListLocations
export def "list-locations" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  --body-max-results: int # The maximum number of locations to return. (spec name: MaxResults)
  --body-next-token: string # An opaque string that indicates the position at which to begin the next list of locations. (spec name: NextToken)
  --filters: list # You can use API filters to narrow down the list of resources returned by ListLocations. For example, to retrieve all tasks on a specific source location, you can use ListLocations with filter name LocationType S3 and Operator Equals. — item shape: {Name: "LocationUri"|"LocationType"|"CreationTime", Values: list<string>, Operator: "Equals"|"NotEquals"|"In"|"LessThanOrEqual"|"LessThan"|"GreaterThanOrEqual"|"GreaterThan"|"Contains"|"NotContains"|"BeginsWith"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.ListLocations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all the tags associated with an Amazon Web Services resource.
#
# POST /
# Returns: record<Tags: table<Key: string, Value: string>, NextToken: string>
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  resource_arn: string # Specifies the Amazon Resource Name (ARN) of the resource that you want tag information on.
  --body-max-results: int # Specifies how many results that you want in the response. (spec name: MaxResults)
  --body-next-token: string # Specifies an opaque string that indicates the position to begin the next list of results in the response. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of executed tasks.
#
# POST /
# Returns: record<TaskExecutions: table<TaskExecutionArn: string, Status: string>, NextToken: string>
# operationId: ListTaskExecutions
export def "list-task-executions" [
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  --task-arn: string # The Amazon Resource Name (ARN) of the task whose tasks you want to list.
  --body-max-results: int # The maximum number of executed tasks to list. (spec name: MaxResults)
  --body-next-token: string # An opaque string that indicates the position at which to begin the next list of the executed tasks. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.ListTaskExecutions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TaskArn, var: task_arn}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, task_arn: $task_arn, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the DataSync tasks you created.
#
# POST /
# Returns: record<Tasks: table<TaskArn: string, Status: string, Name: string>, NextToken: string>
# operationId: ListTasks
export def "list-tasks" [
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  --body-max-results: int # The maximum number of tasks to return. (spec name: MaxResults)
  --body-next-token: string # An opaque string that indicates the position at which to begin the next list of tasks. (spec name: NextToken)
  --filters: list # You can use API filters to narrow down the list of resources returned by ListTasks. For example, to retrieve all tasks on a specific source location, you can use ListTasks with filter name LocationId and Operator Equals with the ARN for the location. — item shape: {Name: "LocationId"|"CreationTime", Values: list<string>, Operator: "Equals"|"NotEquals"|"In"|"LessThanOrEqual"|"LessThan"|"GreaterThanOrEqual"|"GreaterThan"|"Contains"|"NotContains"|"BeginsWith"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.ListTasks"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an DataSync task. For each task, you can only run one task execution at a time. There are several phases to a task execution. For more information, see Task execution statuses (https://docs.aws.amazon.com/datasync/latest/userguide/working-with-task-executions.html#understand-task-execution-statuses).
#
# POST /
# Returns: record<TaskExecutionArn: string>
# operationId: StartTaskExecution
export def "start-task-execution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  task_arn: string # Specifies the Amazon Resource Name (ARN) of the task that you want to start.
  --override-options: record # Configures your DataSync task settings. These options include how DataSync handles files, objects, and their associated metadata. You also can specify how DataSync verifies data integrity, set bandwidth limits for your task, among other options. Each task setting has a default value. Unless you need to, you don't have to configure any of these Options before starting your task. — shape: {VerifyMode?: "POINT_IN_TIME_CONSISTENT"|"ONLY_FILES_TRANSFERRED"|"NONE", OverwriteMode?: "ALWAYS"|"NEVER", Atime?: "NONE"|"BEST_EFFORT", Mtime?: "NONE"|"PRESERVE", Uid?: "NONE"|"INT_VALUE"|"NAME"|"BOTH", Gid?: "NONE"|"INT_VALUE"|"NAME"|"BOTH", PreserveDeletedFiles?: "PRESERVE"|"REMOVE", PreserveDevices?: "NONE"|"PRESERVE", PosixPermissions?: "NONE"|"PRESERVE", BytesPerSecond?: int, TaskQueueing?: "ENABLED"|"DISABLED", LogLevel?: "OFF"|"BASIC"|"TRANSFER", TransferMode?: "CHANGED"|"ALL", ... (2 more fields)}
  --includes: list # Specifies a list of filter rules that determines which files to include when running a task. The pattern should contain a single filter string that consists of the patterns to include. The patterns are delimited by "|" (that is, a pipe), for example, "/folder1|/folder2". — item shape: {FilterType?: "SIMPLE_PATTERN", Value?: string}
  --excludes: list # Specifies a list of filter rules that determines which files to exclude from a task. The list contains a single filter string that consists of the patterns to exclude. The patterns are delimited by "|" (that is, a pipe), for example, "/folder1|/folder2". — item shape: {FilterType?: "SIMPLE_PATTERN", Value?: string}
  --tags: list # Specifies the tags that you want to apply to the Amazon Resource Name (ARN) representing the task execution. Tags are key-value pairs that help you manage, filter, and search for your DataSync resources. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.StartTaskExecution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TaskArn, var: task_arn}, {name: OverrideOptions, var: override_options}, {name: Includes, var: includes}, {name: Excludes, var: excludes}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, task_arn: $task_arn, override_options: $override_options, includes: $includes, excludes: $excludes, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applies a tag to an Amazon Web Services resource. Tags are key-value pairs that can help you manage, filter, and search for your resources. These include DataSync resources, such as locations, tasks, and task executions.
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
  --x-amz-target: string@x-amz-target-completer-35 # required
  resource_arn: string # Specifies the Amazon Resource Name (ARN) of the resource to apply the tag to.
  tags: list # Specifies the tags that you want to apply to the resource. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes tags from an Amazon Web Services resource.
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  resource_arn: string # Specifies the Amazon Resource Name (ARN) of the resource to remove the tags from.
  keys: list<string> # Specifies the keys in the tags that you want to remove.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: Keys, var: keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, keys: $keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the name of an agent.
#
# POST /
# Returns: record
# operationId: UpdateAgent
export def "update-agent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  agent_arn: string # The Amazon Resource Name (ARN) of the agent to update.
  --name: string # The name that you want to use to configure the agent.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.UpdateAgent"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AgentArn, var: agent_arn}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, agent_arn: $agent_arn, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates some parameters of a previously created location for a Hadoop Distributed File System cluster.
#
# POST /
# Returns: record
# operationId: UpdateLocationHdfs
export def "update-location-hdfs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  location_arn: string # The Amazon Resource Name (ARN) of the source HDFS cluster location.
  --subdirectory: string # A subdirectory in the HDFS cluster. This subdirectory is used to read data from or write data to the HDFS cluster.
  --name-nodes: list # The NameNode that manages the HDFS namespace. The NameNode performs operations such as opening, closing, and renaming files and directories. The NameNode contains the information to map blocks of data to the DataNodes. You can use only one NameNode. — item shape: {Hostname: string, Port: int}
  --block-size: int # The size of the data blocks to write into the HDFS cluster.
  --replication-factor: int # The number of DataNodes to replicate the data to when writing to the HDFS cluster.
  --kms-key-provider-uri: string # The URI of the HDFS cluster's Key Management Server (KMS).
  --qop-configuration: record # The Quality of Protection (QOP) configuration specifies the Remote Procedure Call (RPC) and data transfer privacy settings configured on the Hadoop Distributed File System (HDFS) cluster. — shape: {RpcProtection?: "DISABLED"|"AUTHENTICATION"|"INTEGRITY"|"PRIVACY", DataTransferProtection?: "DISABLED"|"AUTHENTICATION"|"INTEGRITY"|"PRIVACY"}
  --authentication-type: string@authentication-type-completer # The type of authentication used to determine the identity of the user.
  --simple-user: string # The user name used to identify the client on the host operating system.
  --kerberos-principal: string # The Kerberos principal with access to the files and folders on the HDFS cluster.
  --kerberos-keytab: string # The Kerberos key table (keytab) that contains mappings between the defined Kerberos principal and the encrypted keys. You can load the keytab from a file by providing the file's address. If you use the CLI, it performs base64 encoding for you. Otherwise, provide the base64-encoded text.
  --kerberos-krb5-conf: string # The krb5.conf file that contains the Kerberos configuration information. You can load the krb5.conf file by providing the file's address. If you're using the CLI, it performs the base64 encoding for you. Otherwise, provide the base64-encoded text.
  --agent-arns: list<string> # The ARNs of the agents that are used to connect to the HDFS cluster.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.UpdateLocationHdfs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LocationArn, var: location_arn}, {name: Subdirectory, var: subdirectory}, {name: NameNodes, var: name_nodes}, {name: BlockSize, var: block_size}, {name: ReplicationFactor, var: replication_factor}, {name: KmsKeyProviderUri, var: kms_key_provider_uri}, {name: QopConfiguration, var: qop_configuration}, {name: AuthenticationType, var: authentication_type}, {name: SimpleUser, var: simple_user}, {name: KerberosPrincipal, var: kerberos_principal}, {name: KerberosKeytab, var: kerberos_keytab}, {name: KerberosKrb5Conf, var: kerberos_krb5_conf}, {name: AgentArns, var: agent_arns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, location_arn: $location_arn, subdirectory: $subdirectory, name_nodes: $name_nodes, block_size: $block_size, replication_factor: $replication_factor, kms_key_provider_uri: $kms_key_provider_uri, qop_configuration: $qop_configuration, authentication_type: $authentication_type, simple_user: $simple_user, kerberos_principal: $kerberos_principal, kerberos_keytab: $kerberos_keytab, kerberos_krb5_conf: $kerberos_krb5_conf, agent_arns: $agent_arns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates some of the parameters of a previously created location for Network File System (NFS) access. For information about creating an NFS location, see Creating a location for NFS (https://docs.aws.amazon.com/datasync/latest/userguide/create-nfs-location.html).
#
# POST /
# Returns: record
# operationId: UpdateLocationNfs
export def "update-location-nfs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  location_arn: string # The Amazon Resource Name (ARN) of the NFS location to update.
  --subdirectory: string # The subdirectory in the NFS file system that is used to read data from the NFS source location or write data to the NFS destination. The NFS path should be a path that's exported by the NFS server, or a subdirectory of that path. The path should be such that it can be mounted by other NFS clients in your network. To see all the paths exported by your NFS server, run "showmount -e nfs-server-name" from an NFS client that has access to your server. You can specify any directory that appears in the results, and any subdirectory of that directory. Ensure that the NFS export is accessible without Kerberos authentication. To transfer all the data in the folder that you specified, DataSync must have permissions to read all the data. To ensure this, either configure the NFS export with no_root_squash, or ensure that the files you want DataSync to access have permissions that allow read access for all users. Doing either option enables the agent to read the files. For the agent to access directories, you must additionally enable all execute access. If you are copying data to or from your Snowcone device, see NFS Server on Snowcone (https://docs.aws.amazon.com/datasync/latest/userguide/create-nfs-location.html#nfs-on-snowcone) for more information. For information about NFS export configuration, see 18.7. The /etc/exports Configuration File in the Red Hat Enterprise Linux documentation.
  --on-prem-config: record # A list of Amazon Resource Names (ARNs) of agents to use for a Network File System (NFS) location. — shape: {AgentArns: list<string>}
  --mount-options: record # Specifies how DataSync can access a location using the NFS protocol. — shape: {Version?: "AUTOMATIC"|"NFS3"|"NFS4_0"|"NFS4_1"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.UpdateLocationNfs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LocationArn, var: location_arn}, {name: Subdirectory, var: subdirectory}, {name: OnPremConfig, var: on_prem_config}, {name: MountOptions, var: mount_options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, location_arn: $location_arn, subdirectory: $subdirectory, on_prem_config: $on_prem_config, mount_options: $mount_options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates some parameters of an existing object storage location that DataSync accesses for a transfer. For information about creating a self-managed object storage location, see Creating a location for object storage (https://docs.aws.amazon.com/datasync/latest/userguide/create-object-location.html).
#
# POST /
# Returns: record
# operationId: UpdateLocationObjectStorage
export def "update-location-object-storage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  location_arn: string # Specifies the ARN of the object storage system location that you're updating.
  --server-port: int # Specifies the port that your object storage server accepts inbound network traffic on (for example, port 443).
  --server-protocol: string@server-protocol-completer # Specifies the protocol that your object storage server uses to communicate.
  --subdirectory: string # Specifies the object prefix for your object storage server. If this is a source location, DataSync only copies objects with this prefix. If this is a destination location, DataSync writes all objects with this prefix.
  --access-key: string # Specifies the access key (for example, a user name) if credentials are required to authenticate with the object storage server.
  --secret-key: string # Specifies the secret key (for example, a password) if credentials are required to authenticate with the object storage server. (format: password)
  --agent-arns: list<string> # Specifies the Amazon Resource Names (ARNs) of the DataSync agents that can securely connect with your location.
  --server-certificate: string # Specifies a certificate to authenticate with an object storage system that uses a private or self-signed certificate authority (CA). You must specify a Base64-encoded .pem file (for example, file:///home/user/.ssh/storage_sys_certificate.pem). The certificate can be up to 32768 bytes (before Base64 encoding). To use this parameter, configure ServerProtocol to HTTPS. Updating the certificate doesn't interfere with tasks that you have in progress.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.UpdateLocationObjectStorage"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LocationArn, var: location_arn}, {name: ServerPort, var: server_port}, {name: ServerProtocol, var: server_protocol}, {name: Subdirectory, var: subdirectory}, {name: AccessKey, var: access_key}, {name: SecretKey, var: secret_key}, {name: AgentArns, var: agent_arns}, {name: ServerCertificate, var: server_certificate}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, location_arn: $location_arn, server_port: $server_port, server_protocol: $server_protocol, subdirectory: $subdirectory, access_key: $access_key, secret_key: $secret_key, agent_arns: $agent_arns, server_certificate: $server_certificate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates some of the parameters of a previously created location for Server Message Block (SMB) file system access. For information about creating an SMB location, see Creating a location for SMB (https://docs.aws.amazon.com/datasync/latest/userguide/create-smb-location.html).
#
# POST /
# Returns: record
# operationId: UpdateLocationSmb
export def "update-location-smb" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  location_arn: string # The Amazon Resource Name (ARN) of the SMB location to update.
  --subdirectory: string # The subdirectory in the SMB file system that is used to read data from the SMB source location or write data to the SMB destination. The SMB path should be a path that's exported by the SMB server, or a subdirectory of that path. The path should be such that it can be mounted by other SMB clients in your network. Subdirectory must be specified with forward slashes. For example, /path/to/folder. To transfer all the data in the folder that you specified, DataSync must have permissions to mount the SMB share and to access all the data in that share. To ensure this, do either of the following: Ensure that the user/password specified belongs to the user who can mount the share and who has the appropriate permissions for all of the files and directories that you want DataSync to access. Use credentials of a member of the Backup Operators group to mount the share. Doing either of these options enables the agent to access the data. For the agent to access directories, you must also enable all execute access.
  --user: string # The user who can mount the share has the permissions to access files and folders in the SMB share.
  --domain: string # The name of the Windows domain that the SMB server belongs to.
  --password: string # The password of the user who can mount the share has the permissions to access files and folders in the SMB share. (format: password)
  --agent-arns: list<string> # The Amazon Resource Names (ARNs) of agents to use for a Simple Message Block (SMB) location.
  --mount-options: record # Specifies the version of the Server Message Block (SMB) protocol that DataSync uses to access an SMB file server. — shape: {Version?: "AUTOMATIC"|"SMB2"|"SMB3"|"SMB1"|"SMB2_0"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.UpdateLocationSmb"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LocationArn, var: location_arn}, {name: Subdirectory, var: subdirectory}, {name: User, var: user}, {name: Domain, var: domain}, {name: Password, var: password}, {name: AgentArns, var: agent_arns}, {name: MountOptions, var: mount_options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, location_arn: $location_arn, subdirectory: $subdirectory, user: $user, domain: $domain, password: $password, agent_arns: $agent_arns, mount_options: $mount_options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the metadata associated with a task.
#
# POST /
# Returns: record
# operationId: UpdateTask
export def "update-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  task_arn: string # The Amazon Resource Name (ARN) of the resource name of the task to update.
  --options: record # Configures your DataSync task settings. These options include how DataSync handles files, objects, and their associated metadata. You also can specify how DataSync verifies data integrity, set bandwidth limits for your task, among other options. Each task setting has a default value. Unless you need to, you don't have to configure any of these Options before starting your task. — shape: {VerifyMode?: "POINT_IN_TIME_CONSISTENT"|"ONLY_FILES_TRANSFERRED"|"NONE", OverwriteMode?: "ALWAYS"|"NEVER", Atime?: "NONE"|"BEST_EFFORT", Mtime?: "NONE"|"PRESERVE", Uid?: "NONE"|"INT_VALUE"|"NAME"|"BOTH", Gid?: "NONE"|"INT_VALUE"|"NAME"|"BOTH", PreserveDeletedFiles?: "PRESERVE"|"REMOVE", PreserveDevices?: "NONE"|"PRESERVE", PosixPermissions?: "NONE"|"PRESERVE", BytesPerSecond?: int, TaskQueueing?: "ENABLED"|"DISABLED", LogLevel?: "OFF"|"BASIC"|"TRANSFER", TransferMode?: "CHANGED"|"ALL", ... (2 more fields)}
  --excludes: list # Specifies a list of filter rules that exclude specific data during your transfer. For more information and examples, see Filtering data transferred by DataSync (https://docs.aws.amazon.com/datasync/latest/userguide/filtering.html). — item shape: {FilterType?: "SIMPLE_PATTERN", Value?: string}
  --schedule: record # Specifies the schedule you want your task to use for repeated executions. For more information, see Schedule Expressions for Rules (https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html). — shape: {ScheduleExpression: string}
  --name: string # The name of the task to update.
  --cloud-watch-log-group-arn: string # The Amazon Resource Name (ARN) of the resource name of the Amazon CloudWatch log group.
  --includes: list # Specifies a list of filter rules that include specific data during your transfer. For more information and examples, see Filtering data transferred by DataSync (https://docs.aws.amazon.com/datasync/latest/userguide/filtering.html). — item shape: {FilterType?: "SIMPLE_PATTERN", Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.UpdateTask"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TaskArn, var: task_arn}, {name: Options, var: options}, {name: Excludes, var: excludes}, {name: Schedule, var: schedule}, {name: Name, var: name}, {name: CloudWatchLogGroupArn, var: cloud_watch_log_group_arn}, {name: Includes, var: includes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, task_arn: $task_arn, options: $options, excludes: $excludes, schedule: $schedule, name: $name, cloud_watch_log_group_arn: $cloud_watch_log_group_arn, includes: $includes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates execution of a task. You can modify bandwidth throttling for a task execution that is running or queued. For more information, see Adjusting Bandwidth Throttling for a Task Execution (https://docs.aws.amazon.com/datasync/latest/userguide/working-with-task-executions.html#adjust-bandwidth-throttling). The only Option that can be modified by UpdateTaskExecution is BytesPerSecond (https://docs.aws.amazon.com/datasync/latest/userguide/API_Options.html#DataSync-Type-Options-BytesPerSecond) .
#
# POST /
# Returns: record
# operationId: UpdateTaskExecution
export def "update-task-execution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  task_execution_arn: string # The Amazon Resource Name (ARN) of the specific task execution that is being updated.
  options: record # Configures your DataSync task settings. These options include how DataSync handles files, objects, and their associated metadata. You also can specify how DataSync verifies data integrity, set bandwidth limits for your task, among other options. Each task setting has a default value. Unless you need to, you don't have to configure any of these Options before starting your task. — shape: {VerifyMode?: "POINT_IN_TIME_CONSISTENT"|"ONLY_FILES_TRANSFERRED"|"NONE", OverwriteMode?: "ALWAYS"|"NEVER", Atime?: "NONE"|"BEST_EFFORT", Mtime?: "NONE"|"PRESERVE", Uid?: "NONE"|"INT_VALUE"|"NAME"|"BOTH", Gid?: "NONE"|"INT_VALUE"|"NAME"|"BOTH", PreserveDeletedFiles?: "PRESERVE"|"REMOVE", PreserveDevices?: "NONE"|"PRESERVE", PosixPermissions?: "NONE"|"PRESERVE", BytesPerSecond?: int, TaskQueueing?: "ENABLED"|"DISABLED", LogLevel?: "OFF"|"BASIC"|"TRANSFER", TransferMode?: "CHANGED"|"ALL", ... (2 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "FmrsService.UpdateTaskExecution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TaskExecutionArn, var: task_execution_arn}, {name: Options, var: options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, task_execution_arn: $task_execution_arn, options: $options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
