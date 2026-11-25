# Auto-generated client for Amazon AppStream v2016-12-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/appstream/2016-12-01/openapi.json
# Auth: --token flag or $env.AMAZON_APPSTREAM_TOKEN

const CLIENT = {
  base_url: "http://appstream2.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_APPSTREAM_TOKEN"
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

def base-url-completer [] { ["http://appstream2.us-east-1.amazonaws.com" "http://appstream2.us-east-2.amazonaws.com" "http://appstream2.us-west-1.amazonaws.com" "http://appstream2.us-west-2.amazonaws.com" "http://appstream2.us-gov-west-1.amazonaws.com" "http://appstream2.us-gov-east-1.amazonaws.com" "http://appstream2.ca-central-1.amazonaws.com" "http://appstream2.eu-north-1.amazonaws.com" "http://appstream2.eu-west-1.amazonaws.com" "http://appstream2.eu-west-2.amazonaws.com" "http://appstream2.eu-west-3.amazonaws.com" "http://appstream2.eu-central-1.amazonaws.com" "http://appstream2.eu-south-1.amazonaws.com" "http://appstream2.af-south-1.amazonaws.com" "http://appstream2.ap-northeast-1.amazonaws.com" "http://appstream2.ap-northeast-2.amazonaws.com" "http://appstream2.ap-northeast-3.amazonaws.com" "http://appstream2.ap-southeast-1.amazonaws.com" "http://appstream2.ap-southeast-2.amazonaws.com" "http://appstream2.ap-east-1.amazonaws.com" "http://appstream2.ap-south-1.amazonaws.com" "http://appstream2.sa-east-1.amazonaws.com" "http://appstream2.me-south-1.amazonaws.com" "https://appstream2.us-east-1.amazonaws.com" "https://appstream2.us-east-2.amazonaws.com" "https://appstream2.us-west-1.amazonaws.com" "https://appstream2.us-west-2.amazonaws.com" "https://appstream2.us-gov-west-1.amazonaws.com" "https://appstream2.us-gov-east-1.amazonaws.com" "https://appstream2.ca-central-1.amazonaws.com" "https://appstream2.eu-north-1.amazonaws.com" "https://appstream2.eu-west-1.amazonaws.com" "https://appstream2.eu-west-2.amazonaws.com" "https://appstream2.eu-west-3.amazonaws.com" "https://appstream2.eu-central-1.amazonaws.com" "https://appstream2.eu-south-1.amazonaws.com" "https://appstream2.af-south-1.amazonaws.com" "https://appstream2.ap-northeast-1.amazonaws.com" "https://appstream2.ap-northeast-2.amazonaws.com" "https://appstream2.ap-northeast-3.amazonaws.com" "https://appstream2.ap-southeast-1.amazonaws.com" "https://appstream2.ap-southeast-2.amazonaws.com" "https://appstream2.ap-east-1.amazonaws.com" "https://appstream2.ap-south-1.amazonaws.com" "https://appstream2.sa-east-1.amazonaws.com" "https://appstream2.me-south-1.amazonaws.com" "http://appstream2.cn-north-1.amazonaws.com.cn" "http://appstream2.cn-northwest-1.amazonaws.com.cn" "https://appstream2.cn-north-1.amazonaws.com.cn" "https://appstream2.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["PhotonAdminProxyService.AssociateApplicationFleet"] }
def x-amz-target-completer-1 [] { ["PhotonAdminProxyService.AssociateApplicationToEntitlement"] }
def x-amz-target-completer-2 [] { ["PhotonAdminProxyService.AssociateFleet"] }
def x-amz-target-completer-3 [] { ["PhotonAdminProxyService.BatchAssociateUserStack"] }
def x-amz-target-completer-4 [] { ["PhotonAdminProxyService.BatchDisassociateUserStack"] }
def x-amz-target-completer-5 [] { ["PhotonAdminProxyService.CopyImage"] }
def x-amz-target-completer-6 [] { ["PhotonAdminProxyService.CreateAppBlock"] }
def x-amz-target-completer-7 [] { ["PhotonAdminProxyService.CreateApplication"] }
def x-amz-target-completer-8 [] { ["PhotonAdminProxyService.CreateDirectoryConfig"] }
def app-visibility-completer [] { ["ALL" "ASSOCIATED"] }
def x-amz-target-completer-9 [] { ["PhotonAdminProxyService.CreateEntitlement"] }
def fleet-type-completer [] { ["ALWAYS_ON" "ELASTIC" "ON_DEMAND"] }
def stream-view-completer [] { ["APP" "DESKTOP"] }
def platform-completer [] { ["AMAZON_LINUX2" "WINDOWS" "WINDOWS_SERVER_2016" "WINDOWS_SERVER_2019"] }
def x-amz-target-completer-10 [] { ["PhotonAdminProxyService.CreateFleet"] }
def x-amz-target-completer-11 [] { ["PhotonAdminProxyService.CreateImageBuilder"] }
def x-amz-target-completer-12 [] { ["PhotonAdminProxyService.CreateImageBuilderStreamingURL"] }
def x-amz-target-completer-13 [] { ["PhotonAdminProxyService.CreateStack"] }
def x-amz-target-completer-14 [] { ["PhotonAdminProxyService.CreateStreamingURL"] }
def x-amz-target-completer-15 [] { ["PhotonAdminProxyService.CreateUpdatedImage"] }
def x-amz-target-completer-16 [] { ["PhotonAdminProxyService.CreateUsageReportSubscription"] }
def message-action-completer [] { ["RESEND" "SUPPRESS"] }
def authentication-type-completer [] { ["API" "AWS_AD" "SAML" "USERPOOL"] }
def x-amz-target-completer-17 [] { ["PhotonAdminProxyService.CreateUser"] }
def x-amz-target-completer-18 [] { ["PhotonAdminProxyService.DeleteAppBlock"] }
def x-amz-target-completer-19 [] { ["PhotonAdminProxyService.DeleteApplication"] }
def x-amz-target-completer-20 [] { ["PhotonAdminProxyService.DeleteDirectoryConfig"] }
def x-amz-target-completer-21 [] { ["PhotonAdminProxyService.DeleteEntitlement"] }
def x-amz-target-completer-22 [] { ["PhotonAdminProxyService.DeleteFleet"] }
def x-amz-target-completer-23 [] { ["PhotonAdminProxyService.DeleteImage"] }
def x-amz-target-completer-24 [] { ["PhotonAdminProxyService.DeleteImageBuilder"] }
def x-amz-target-completer-25 [] { ["PhotonAdminProxyService.DeleteImagePermissions"] }
def x-amz-target-completer-26 [] { ["PhotonAdminProxyService.DeleteStack"] }
def x-amz-target-completer-27 [] { ["PhotonAdminProxyService.DeleteUsageReportSubscription"] }
def x-amz-target-completer-28 [] { ["PhotonAdminProxyService.DeleteUser"] }
def x-amz-target-completer-29 [] { ["PhotonAdminProxyService.DescribeAppBlocks"] }
def x-amz-target-completer-30 [] { ["PhotonAdminProxyService.DescribeApplicationFleetAssociations"] }
def x-amz-target-completer-31 [] { ["PhotonAdminProxyService.DescribeApplications"] }
def x-amz-target-completer-32 [] { ["PhotonAdminProxyService.DescribeDirectoryConfigs"] }
def x-amz-target-completer-33 [] { ["PhotonAdminProxyService.DescribeEntitlements"] }
def x-amz-target-completer-34 [] { ["PhotonAdminProxyService.DescribeFleets"] }
def x-amz-target-completer-35 [] { ["PhotonAdminProxyService.DescribeImageBuilders"] }
def x-amz-target-completer-36 [] { ["PhotonAdminProxyService.DescribeImagePermissions"] }
def type-completer [] { ["PRIVATE" "PUBLIC" "SHARED"] }
def x-amz-target-completer-37 [] { ["PhotonAdminProxyService.DescribeImages"] }
def x-amz-target-completer-38 [] { ["PhotonAdminProxyService.DescribeSessions"] }
def x-amz-target-completer-39 [] { ["PhotonAdminProxyService.DescribeStacks"] }
def x-amz-target-completer-40 [] { ["PhotonAdminProxyService.DescribeUsageReportSubscriptions"] }
def x-amz-target-completer-41 [] { ["PhotonAdminProxyService.DescribeUserStackAssociations"] }
def x-amz-target-completer-42 [] { ["PhotonAdminProxyService.DescribeUsers"] }
def x-amz-target-completer-43 [] { ["PhotonAdminProxyService.DisableUser"] }
def x-amz-target-completer-44 [] { ["PhotonAdminProxyService.DisassociateApplicationFleet"] }
def x-amz-target-completer-45 [] { ["PhotonAdminProxyService.DisassociateApplicationFromEntitlement"] }
def x-amz-target-completer-46 [] { ["PhotonAdminProxyService.DisassociateFleet"] }
def x-amz-target-completer-47 [] { ["PhotonAdminProxyService.EnableUser"] }
def x-amz-target-completer-48 [] { ["PhotonAdminProxyService.ExpireSession"] }
def x-amz-target-completer-49 [] { ["PhotonAdminProxyService.ListAssociatedFleets"] }
def x-amz-target-completer-50 [] { ["PhotonAdminProxyService.ListAssociatedStacks"] }
def x-amz-target-completer-51 [] { ["PhotonAdminProxyService.ListEntitledApplications"] }
def x-amz-target-completer-52 [] { ["PhotonAdminProxyService.ListTagsForResource"] }
def x-amz-target-completer-53 [] { ["PhotonAdminProxyService.StartFleet"] }
def x-amz-target-completer-54 [] { ["PhotonAdminProxyService.StartImageBuilder"] }
def x-amz-target-completer-55 [] { ["PhotonAdminProxyService.StopFleet"] }
def x-amz-target-completer-56 [] { ["PhotonAdminProxyService.StopImageBuilder"] }
def x-amz-target-completer-57 [] { ["PhotonAdminProxyService.TagResource"] }
def x-amz-target-completer-58 [] { ["PhotonAdminProxyService.UntagResource"] }
def x-amz-target-completer-59 [] { ["PhotonAdminProxyService.UpdateApplication"] }
def x-amz-target-completer-60 [] { ["PhotonAdminProxyService.UpdateDirectoryConfig"] }
def x-amz-target-completer-61 [] { ["PhotonAdminProxyService.UpdateEntitlement"] }
def x-amz-target-completer-62 [] { ["PhotonAdminProxyService.UpdateFleet"] }
def x-amz-target-completer-63 [] { ["PhotonAdminProxyService.UpdateImagePermissions"] }
def x-amz-target-completer-64 [] { ["PhotonAdminProxyService.UpdateStack"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    associate-application-fleet: "record<ApplicationFleetAssociation: record<FleetName: string, ApplicationArn: string>>"
    associate-application-to-entitlement: "record"
    associate-fleet: "record"
    batch-associate-user-stack: "record<errors: table<UserStackAssociation: record, ErrorCode: string, ErrorMessage: string>>"
    batch-disassociate-user-stack: "record<errors: table<UserStackAssociation: record, ErrorCode: string, ErrorMessage: string>>"
    copy-image: "record<DestinationImageName: string>"
    create-app-block: "record<AppBlock: record<Name: string, Arn: string, Description: string, DisplayName: string, SourceS3Location: record<S3Bucket: string, S3Key: string>, SetupScriptDetails: record<ScriptS3Location: record, ExecutablePath: string, ExecutableParameters: string, TimeoutInSeconds: int>, CreatedTime: string>>"
    create-application: "record<Application: record<Name: string, DisplayName: string, IconURL: string, LaunchPath: string, LaunchParameters: string, Enabled: bool, Metadata: record, WorkingDirectory: string, Description: string, Arn: string, AppBlockArn: string, IconS3Location: record<S3Bucket: string, S3Key: string>, Platforms: list<string>, InstanceFamilies: list<string>, CreatedTime: string>>"
    create-directory-config: "record<DirectoryConfig: record<DirectoryName: string, OrganizationalUnitDistinguishedNames: list<string>, ServiceAccountCredentials: record<AccountName: string, AccountPassword: string>, CreatedTime: string, CertificateBasedAuthProperties: record<Status: string, CertificateAuthorityArn: string>>>"
    create-entitlement: "record<Entitlement: record<Name: string, StackName: string, Description: string, AppVisibility: string, Attributes: list<record>, CreatedTime: string, LastModifiedTime: string>>"
    create-fleet: "record<Fleet: record<Arn: string, Name: string, DisplayName: string, Description: string, ImageName: string, ImageArn: string, InstanceType: string, FleetType: string, ComputeCapacityStatus: record<Desired: int, Running: int, InUse: int, Available: int>, MaxUserDurationInSeconds: int, DisconnectTimeoutInSeconds: int, State: string, VpcConfig: record<SubnetIds: list, SecurityGroupIds: list>, CreatedTime: string, FleetErrors: list<record>, EnableDefaultInternetAccess: bool, DomainJoinInfo: record<DirectoryName: string, OrganizationalUnitDistinguishedName: string>, IdleDisconnectTimeoutInSeconds: int, IamRoleArn: string, StreamView: string, Platform: string, MaxConcurrentSessions: int, UsbDeviceFilterStrings: list<string>, SessionScriptS3Location: record<S3Bucket: string, S3Key: string>>>"
    create-image-builder: "record<ImageBuilder: record<Name: string, Arn: string, ImageArn: string, Description: string, DisplayName: string, VpcConfig: record<SubnetIds: list, SecurityGroupIds: list>, InstanceType: string, Platform: string, IamRoleArn: string, State: string, StateChangeReason: record<Code: string, Message: string>, CreatedTime: string, EnableDefaultInternetAccess: bool, DomainJoinInfo: record<DirectoryName: string, OrganizationalUnitDistinguishedName: string>, NetworkAccessConfiguration: record<EniPrivateIpAddress: string, EniId: string>, ImageBuilderErrors: list<record>, AppstreamAgentVersion: string, AccessEndpoints: list<record>>>"
    create-image-builder-streaming-url: "record<StreamingURL: string, Expires: string>"
    create-stack: "record<Stack: record<Arn: string, Name: string, Description: string, DisplayName: string, CreatedTime: string, StorageConnectors: list<record>, RedirectURL: string, FeedbackURL: string, StackErrors: list<record>, UserSettings: list<record>, ApplicationSettings: record<Enabled: bool, SettingsGroup: string, S3BucketName: string>, AccessEndpoints: list<record>, EmbedHostDomains: list<string>, StreamingExperienceSettings: record<PreferredProtocol: string>>>"
    create-streaming-url: "record<StreamingURL: string, Expires: string>"
    create-updated-image: "record<image: record<Name: string, Arn: string, BaseImageArn: string, DisplayName: string, State: string, Visibility: string, ImageBuilderSupported: bool, ImageBuilderName: string, Platform: string, Description: string, StateChangeReason: record<Code: string, Message: string>, Applications: list<record>, CreatedTime: string, PublicBaseImageReleasedDate: string, AppstreamAgentVersion: string, ImagePermissions: record<allowFleet: bool, allowImageBuilder: bool>, ImageErrors: list<record>>, canUpdateImage: bool>"
    create-usage-report-subscription: "record<S3BucketName: string, Schedule: string>"
    create-user: "record"
    delete-app-block: "record"
    delete-application: "record"
    delete-directory-config: "record"
    delete-entitlement: "record"
    delete-fleet: "record"
    delete-image: "record<Image: record<Name: string, Arn: string, BaseImageArn: string, DisplayName: string, State: string, Visibility: string, ImageBuilderSupported: bool, ImageBuilderName: string, Platform: string, Description: string, StateChangeReason: record<Code: string, Message: string>, Applications: list<record>, CreatedTime: string, PublicBaseImageReleasedDate: string, AppstreamAgentVersion: string, ImagePermissions: record<allowFleet: bool, allowImageBuilder: bool>, ImageErrors: list<record>>>"
    delete-image-builder: "record<ImageBuilder: record<Name: string, Arn: string, ImageArn: string, Description: string, DisplayName: string, VpcConfig: record<SubnetIds: list, SecurityGroupIds: list>, InstanceType: string, Platform: string, IamRoleArn: string, State: string, StateChangeReason: record<Code: string, Message: string>, CreatedTime: string, EnableDefaultInternetAccess: bool, DomainJoinInfo: record<DirectoryName: string, OrganizationalUnitDistinguishedName: string>, NetworkAccessConfiguration: record<EniPrivateIpAddress: string, EniId: string>, ImageBuilderErrors: list<record>, AppstreamAgentVersion: string, AccessEndpoints: list<record>>>"
    delete-image-permissions: "record"
    delete-stack: "record"
    delete-usage-report-subscription: "record"
    delete-user: "record"
    describe-app-blocks: "record<AppBlocks: table<Name: string, Arn: string, Description: string, DisplayName: string, SourceS3Location: record, SetupScriptDetails: record, CreatedTime: string>, NextToken: string>"
    describe-application-fleet-associations: "record<ApplicationFleetAssociations: table<FleetName: string, ApplicationArn: string>, NextToken: string>"
    describe-applications: "record<Applications: table<Name: string, DisplayName: string, IconURL: string, LaunchPath: string, LaunchParameters: string, Enabled: bool, Metadata: record, WorkingDirectory: string, Description: string, Arn: string, AppBlockArn: string, IconS3Location: record, Platforms: list, InstanceFamilies: list, CreatedTime: string>, NextToken: string>"
    describe-directory-configs: "record<DirectoryConfigs: table<DirectoryName: string, OrganizationalUnitDistinguishedNames: list, ServiceAccountCredentials: record, CreatedTime: string, CertificateBasedAuthProperties: record>, NextToken: string>"
    describe-entitlements: "record<Entitlements: table<Name: string, StackName: string, Description: string, AppVisibility: string, Attributes: list, CreatedTime: string, LastModifiedTime: string>, NextToken: string>"
    describe-fleets: "record<Fleets: table<Arn: string, Name: string, DisplayName: string, Description: string, ImageName: string, ImageArn: string, InstanceType: string, FleetType: string, ComputeCapacityStatus: record, MaxUserDurationInSeconds: int, DisconnectTimeoutInSeconds: int, State: string, VpcConfig: record, CreatedTime: string, FleetErrors: list, EnableDefaultInternetAccess: bool, DomainJoinInfo: record, IdleDisconnectTimeoutInSeconds: int, IamRoleArn: string, StreamView: string, Platform: string, MaxConcurrentSessions: int, UsbDeviceFilterStrings: list, SessionScriptS3Location: record>, NextToken: string>"
    describe-image-builders: "record<ImageBuilders: table<Name: string, Arn: string, ImageArn: string, Description: string, DisplayName: string, VpcConfig: record, InstanceType: string, Platform: string, IamRoleArn: string, State: string, StateChangeReason: record, CreatedTime: string, EnableDefaultInternetAccess: bool, DomainJoinInfo: record, NetworkAccessConfiguration: record, ImageBuilderErrors: list, AppstreamAgentVersion: string, AccessEndpoints: list>, NextToken: string>"
    describe-image-permissions: "record<Name: string, SharedImagePermissionsList: table<sharedAccountId: string, imagePermissions: record>, NextToken: string>"
    describe-images: "record<Images: table<Name: string, Arn: string, BaseImageArn: string, DisplayName: string, State: string, Visibility: string, ImageBuilderSupported: bool, ImageBuilderName: string, Platform: string, Description: string, StateChangeReason: record, Applications: list, CreatedTime: string, PublicBaseImageReleasedDate: string, AppstreamAgentVersion: string, ImagePermissions: record, ImageErrors: list>, NextToken: string>"
    describe-sessions: "record<Sessions: table<Id: string, UserId: string, StackName: string, FleetName: string, State: string, ConnectionState: string, StartTime: string, MaxExpirationTime: string, AuthenticationType: string, NetworkAccessConfiguration: record>, NextToken: string>"
    describe-stacks: "record<Stacks: table<Arn: string, Name: string, Description: string, DisplayName: string, CreatedTime: string, StorageConnectors: list, RedirectURL: string, FeedbackURL: string, StackErrors: list, UserSettings: list, ApplicationSettings: record, AccessEndpoints: list, EmbedHostDomains: list, StreamingExperienceSettings: record>, NextToken: string>"
    describe-usage-report-subscriptions: "record<UsageReportSubscriptions: table<S3BucketName: string, Schedule: string, LastGeneratedReportDate: string, SubscriptionErrors: list>, NextToken: string>"
    describe-user-stack-associations: "record<UserStackAssociations: table<StackName: string, UserName: string, AuthenticationType: string, SendEmailNotification: bool>, NextToken: string>"
    describe-users: "record<Users: table<Arn: string, UserName: string, Enabled: bool, Status: string, FirstName: string, LastName: string, CreatedTime: string, AuthenticationType: string>, NextToken: string>"
    disable-user: "record"
    disassociate-application-fleet: "record"
    disassociate-application-from-entitlement: "record"
    disassociate-fleet: "record"
    enable-user: "record"
    expire-session: "record"
    list-associated-fleets: "record<Names: list<string>, NextToken: string>"
    list-associated-stacks: "record<Names: list<string>, NextToken: string>"
    list-entitled-applications: "record<EntitledApplications: table<ApplicationIdentifier: string>, NextToken: string>"
    list-tags-for-resource: "record<Tags: record>"
    start-fleet: "record"
    start-image-builder: "record<ImageBuilder: record<Name: string, Arn: string, ImageArn: string, Description: string, DisplayName: string, VpcConfig: record<SubnetIds: list, SecurityGroupIds: list>, InstanceType: string, Platform: string, IamRoleArn: string, State: string, StateChangeReason: record<Code: string, Message: string>, CreatedTime: string, EnableDefaultInternetAccess: bool, DomainJoinInfo: record<DirectoryName: string, OrganizationalUnitDistinguishedName: string>, NetworkAccessConfiguration: record<EniPrivateIpAddress: string, EniId: string>, ImageBuilderErrors: list<record>, AppstreamAgentVersion: string, AccessEndpoints: list<record>>>"
    stop-fleet: "record"
    stop-image-builder: "record<ImageBuilder: record<Name: string, Arn: string, ImageArn: string, Description: string, DisplayName: string, VpcConfig: record<SubnetIds: list, SecurityGroupIds: list>, InstanceType: string, Platform: string, IamRoleArn: string, State: string, StateChangeReason: record<Code: string, Message: string>, CreatedTime: string, EnableDefaultInternetAccess: bool, DomainJoinInfo: record<DirectoryName: string, OrganizationalUnitDistinguishedName: string>, NetworkAccessConfiguration: record<EniPrivateIpAddress: string, EniId: string>, ImageBuilderErrors: list<record>, AppstreamAgentVersion: string, AccessEndpoints: list<record>>>"
    tag-resource: "record"
    untag-resource: "record"
    update-application: "record<Application: record<Name: string, DisplayName: string, IconURL: string, LaunchPath: string, LaunchParameters: string, Enabled: bool, Metadata: record, WorkingDirectory: string, Description: string, Arn: string, AppBlockArn: string, IconS3Location: record<S3Bucket: string, S3Key: string>, Platforms: list<string>, InstanceFamilies: list<string>, CreatedTime: string>>"
    update-directory-config: "record<DirectoryConfig: record<DirectoryName: string, OrganizationalUnitDistinguishedNames: list<string>, ServiceAccountCredentials: record<AccountName: string, AccountPassword: string>, CreatedTime: string, CertificateBasedAuthProperties: record<Status: string, CertificateAuthorityArn: string>>>"
    update-entitlement: "record<Entitlement: record<Name: string, StackName: string, Description: string, AppVisibility: string, Attributes: list<record>, CreatedTime: string, LastModifiedTime: string>>"
    update-fleet: "record<Fleet: record<Arn: string, Name: string, DisplayName: string, Description: string, ImageName: string, ImageArn: string, InstanceType: string, FleetType: string, ComputeCapacityStatus: record<Desired: int, Running: int, InUse: int, Available: int>, MaxUserDurationInSeconds: int, DisconnectTimeoutInSeconds: int, State: string, VpcConfig: record<SubnetIds: list, SecurityGroupIds: list>, CreatedTime: string, FleetErrors: list<record>, EnableDefaultInternetAccess: bool, DomainJoinInfo: record<DirectoryName: string, OrganizationalUnitDistinguishedName: string>, IdleDisconnectTimeoutInSeconds: int, IamRoleArn: string, StreamView: string, Platform: string, MaxConcurrentSessions: int, UsbDeviceFilterStrings: list<string>, SessionScriptS3Location: record<S3Bucket: string, S3Key: string>>>"
    update-image-permissions: "record"
    update-stack: "record<Stack: record<Arn: string, Name: string, Description: string, DisplayName: string, CreatedTime: string, StorageConnectors: list<record>, RedirectURL: string, FeedbackURL: string, StackErrors: list<record>, UserSettings: list<record>, ApplicationSettings: record<Enabled: bool, SettingsGroup: string, S3BucketName: string>, AccessEndpoints: list<record>, EmbedHostDomains: list<string>, StreamingExperienceSettings: record<PreferredProtocol: string>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["associate-application-fleet" "associate-application-to-entitlement" "associate-fleet" "batch-associate-user-stack" "batch-disassociate-user-stack" "copy-image" "create-app-block" "create-application" "create-directory-config" "create-entitlement" "create-fleet" "create-image-builder" "create-image-builder-streaming-url" "create-stack" "create-streaming-url" "create-updated-image" "create-usage-report-subscription" "create-user" "delete-app-block" "delete-application" "delete-directory-config" "delete-entitlement" "delete-fleet" "delete-image" "delete-image-builder" "delete-image-permissions" "delete-stack" "delete-usage-report-subscription" "delete-user" "describe-app-blocks" "describe-application-fleet-associations" "describe-applications" "describe-directory-configs" "describe-entitlements" "describe-fleets" "describe-image-builders" "describe-image-permissions" "describe-images" "describe-sessions" "describe-stacks" "describe-usage-report-subscriptions" "describe-user-stack-associations" "describe-users" "disable-user" "disassociate-application-fleet" "disassociate-application-from-entitlement" "disassociate-fleet" "enable-user" "expire-session" "list-associated-fleets" "list-associated-stacks" "list-entitled-applications" "list-tags-for-resource" "start-fleet" "start-image-builder" "stop-fleet" "stop-image-builder" "tag-resource" "untag-resource" "update-application" "update-directory-config" "update-entitlement" "update-fleet" "update-image-permissions" "update-stack" "commands"] | sort) } | get name | first)
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

# Associates the specified application with the specified fleet. This is only supported for Elastic fleets.
#
# POST /
# Returns: record<ApplicationFleetAssociation: record<FleetName: string, ApplicationArn: string>>
# operationId: AssociateApplicationFleet
export def "associate-application-fleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  fleet_name: string # The name of the fleet.
  application_arn: string # The ARN of the application.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.AssociateApplicationFleet"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FleetName, var: fleet_name}, {name: ApplicationArn, var: application_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, fleet_name: $fleet_name, application_arn: $application_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates an application to entitle.
#
# POST /
# Returns: record
# operationId: AssociateApplicationToEntitlement
export def "associate-application-to-entitlement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  stack_name: string # The name of the stack.
  entitlement_name: string # The name of the entitlement.
  application_identifier: string # The identifier of the application.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.AssociateApplicationToEntitlement"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackName, var: stack_name}, {name: EntitlementName, var: entitlement_name}, {name: ApplicationIdentifier, var: application_identifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_name: $stack_name, entitlement_name: $entitlement_name, application_identifier: $application_identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates the specified fleet with the specified stack.
#
# POST /
# Returns: record
# operationId: AssociateFleet
export def "associate-fleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  fleet_name: string # The name of the fleet.
  stack_name: string # The name of the stack.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.AssociateFleet"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FleetName, var: fleet_name}, {name: StackName, var: stack_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, fleet_name: $fleet_name, stack_name: $stack_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates the specified users with the specified stacks. Users in a user pool cannot be assigned to stacks with fleets that are joined to an Active Directory domain.
#
# POST /
# Returns: record<errors: table<UserStackAssociation: record, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchAssociateUserStack
export def "batch-associate-user-stack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  user_stack_associations: list # The list of UserStackAssociation objects. — item shape: {StackName: string, UserName: string, AuthenticationType: "API"|"SAML"|"USERPOOL"|"AWS_AD", SendEmailNotification?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.BatchAssociateUserStack"}]
    body: {content_type: "application/json", kind: json, fields: [{name: UserStackAssociations, var: user_stack_associations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, user_stack_associations: $user_stack_associations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates the specified users from the specified stacks.
#
# POST /
# Returns: record<errors: table<UserStackAssociation: record, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchDisassociateUserStack
export def "batch-disassociate-user-stack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  user_stack_associations: list # The list of UserStackAssociation objects. — item shape: {StackName: string, UserName: string, AuthenticationType: "API"|"SAML"|"USERPOOL"|"AWS_AD", SendEmailNotification?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.BatchDisassociateUserStack"}]
    body: {content_type: "application/json", kind: json, fields: [{name: UserStackAssociations, var: user_stack_associations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, user_stack_associations: $user_stack_associations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copies the image within the same region or to a new region within the same AWS account. Note that any tags you added to the image will not be copied.
#
# POST /
# Returns: record<DestinationImageName: string>
# operationId: CopyImage
export def "copy-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  source_image_name: string # The name of the image to copy.
  destination_image_name: string # The name that the image will have when it is copied to the destination.
  destination_region: string # The destination region to which the image will be copied. This parameter is required, even if you are copying an image within the same region.
  --destination-image-description: string # The description that the image will have when it is copied to the destination.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.CopyImage"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SourceImageName, var: source_image_name}, {name: DestinationImageName, var: destination_image_name}, {name: DestinationRegion, var: destination_region}, {name: DestinationImageDescription, var: destination_image_description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, source_image_name: $source_image_name, destination_image_name: $destination_image_name, destination_region: $destination_region, destination_image_description: $destination_image_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an app block. App blocks are an Amazon AppStream 2.0 resource that stores the details about the virtual hard disk in an S3 bucket. It also stores the setup script with details about how to mount the virtual hard disk. The virtual hard disk includes the application binaries and other files necessary to launch your applications. Multiple applications can be assigned to a single app block. This is only supported for Elastic fleets.
#
# POST /
# Returns: record<AppBlock: record<Name: string, Arn: string, Description: string, DisplayName: string, SourceS3Location: record<S3Bucket: string, S3Key: string>, SetupScriptDetails: record<ScriptS3Location: record, ExecutablePath: string, ExecutableParameters: string, TimeoutInSeconds: int>, CreatedTime: string>>
# operationId: CreateAppBlock
export def "create-app-block" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the app block.
  --description: string # The description of the app block.
  --display-name: string # The display name of the app block. This is not displayed to the user.
  source_s3_location: record # Describes the S3 location. — shape: {S3Bucket: string, S3Key: string}
  setup_script_details: record # Describes the details of the script. — shape: {ScriptS3Location: record, ExecutablePath: string, ExecutableParameters?: string, TimeoutInSeconds: int}
  --tags: record # The tags assigned to the app block.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.CreateAppBlock"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: DisplayName, var: display_name}, {name: SourceS3Location, var: source_s3_location}, {name: SetupScriptDetails, var: setup_script_details}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, display_name: $display_name, source_s3_location: $source_s3_location, setup_script_details: $setup_script_details, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an application. Applications are an Amazon AppStream 2.0 resource that stores the details about how to launch applications on Elastic fleet streaming instances. An application consists of the launch details, icon, and display name. Applications are associated with an app block that contains the application binaries and other files. The applications assigned to an Elastic fleet are the applications users can launch. This is only supported for Elastic fleets.
#
# POST /
# Returns: record<Application: record<Name: string, DisplayName: string, IconURL: string, LaunchPath: string, LaunchParameters: string, Enabled: bool, Metadata: record, WorkingDirectory: string, Description: string, Arn: string, AppBlockArn: string, IconS3Location: record<S3Bucket: string, S3Key: string>, Platforms: list<string>, InstanceFamilies: list<string>, CreatedTime: string>>
# operationId: CreateApplication
export def "create-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the application. This name is visible to users when display name is not specified.
  --display-name: string # The display name of the application. This name is visible to users in the application catalog.
  --description: string # The description of the application.
  icon_s3_location: record # Describes the S3 location. — shape: {S3Bucket: string, S3Key: string}
  launch_path: string # The launch path of the application.
  --working-directory: string # The working directory of the application.
  --launch-parameters: string # The launch parameters of the application.
  platforms: list<string> # The platforms the application supports. WINDOWS_SERVER_2019 and AMAZON_LINUX2 are supported for Elastic fleets.
  instance_families: list<string> # The instance families the application supports. Valid values are GENERAL_PURPOSE and GRAPHICS_G4.
  app_block_arn: string # The app block ARN to which the application should be associated
  --tags: record # The tags assigned to the application.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.CreateApplication"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: DisplayName, var: display_name}, {name: Description, var: description}, {name: IconS3Location, var: icon_s3_location}, {name: LaunchPath, var: launch_path}, {name: WorkingDirectory, var: working_directory}, {name: LaunchParameters, var: launch_parameters}, {name: Platforms, var: platforms}, {name: InstanceFamilies, var: instance_families}, {name: AppBlockArn, var: app_block_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, display_name: $display_name, description: $description, icon_s3_location: $icon_s3_location, launch_path: $launch_path, working_directory: $working_directory, launch_parameters: $launch_parameters, platforms: $platforms, instance_families: $instance_families, app_block_arn: $app_block_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
#
# POST /
# Returns: record<DirectoryConfig: record<DirectoryName: string, OrganizationalUnitDistinguishedNames: list<string>, ServiceAccountCredentials: record<AccountName: string, AccountPassword: string>, CreatedTime: string, CertificateBasedAuthProperties: record<Status: string, CertificateAuthorityArn: string>>>
# operationId: CreateDirectoryConfig
export def "create-directory-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  directory_name: string # The fully qualified name of the directory (for example, corp.example.com).
  organizational_unit_distinguished_names: list<string> # The distinguished names of the organizational units for computer accounts.
  --service-account-credentials: record # Describes the credentials for the service account used by the fleet or image builder to connect to the directory. — shape: {AccountName: string, AccountPassword: string}
  --certificate-based-auth-properties: record # The certificate-based authentication properties used to authenticate SAML 2.0 Identity Provider (IdP) user identities to Active Directory domain-joined streaming instances. Fallback is turned on by default when certificate-based authentication is Enabled . Fallback allows users to log in using their AD domain password if certificate-based authentication is unsuccessful, or to unlock a desktop lock screen. Enabled_no_directory_login_fallback enables certificate-based authentication, but does not allow users to log in using their AD domain password. Users will be disconnected to re-authenticate using certificates. — shape: {Status?: "DISABLED"|"ENABLED"|"ENABLED_NO_DIRECTORY_LOGIN_FALLBACK", CertificateAuthorityArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.CreateDirectoryConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DirectoryName, var: directory_name}, {name: OrganizationalUnitDistinguishedNames, var: organizational_unit_distinguished_names}, {name: ServiceAccountCredentials, var: service_account_credentials}, {name: CertificateBasedAuthProperties, var: certificate_based_auth_properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, directory_name: $directory_name, organizational_unit_distinguished_names: $organizational_unit_distinguished_names, service_account_credentials: $service_account_credentials, certificate_based_auth_properties: $certificate_based_auth_properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new entitlement. Entitlements control access to specific applications within a stack, based on user attributes. Entitlements apply to SAML 2.0 federated user identities. Amazon AppStream 2.0 user pool and streaming URL users are entitled to all applications in a stack. Entitlements don't apply to the desktop stream view application, or to applications managed by a dynamic app provider using the Dynamic Application Framework.
#
# POST /
# Returns: record<Entitlement: record<Name: string, StackName: string, Description: string, AppVisibility: string, Attributes: list<record>, CreatedTime: string, LastModifiedTime: string>>
# operationId: CreateEntitlement
export def "create-entitlement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the entitlement.
  stack_name: string # The name of the stack with which the entitlement is associated.
  --description: string # The description of the entitlement.
  app_visibility: string@app-visibility-completer # Specifies whether all or selected apps are entitled.
  attributes: list # The attributes of the entitlement. — item shape: {Name: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.CreateEntitlement"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: StackName, var: stack_name}, {name: Description, var: description}, {name: AppVisibility, var: app_visibility}, {name: Attributes, var: attributes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, stack_name: $stack_name, description: $description, app_visibility: $app_visibility, attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a fleet. A fleet consists of streaming instances that your users access for their applications and desktops.
#
# POST /
# Returns: record<Fleet: record<Arn: string, Name: string, DisplayName: string, Description: string, ImageName: string, ImageArn: string, InstanceType: string, FleetType: string, ComputeCapacityStatus: record<Desired: int, Running: int, InUse: int, Available: int>, MaxUserDurationInSeconds: int, DisconnectTimeoutInSeconds: int, State: string, VpcConfig: record<SubnetIds: list, SecurityGroupIds: list>, CreatedTime: string, FleetErrors: list<record>, EnableDefaultInternetAccess: bool, DomainJoinInfo: record<DirectoryName: string, OrganizationalUnitDistinguishedName: string>, IdleDisconnectTimeoutInSeconds: int, IamRoleArn: string, StreamView: string, Platform: string, MaxConcurrentSessions: int, UsbDeviceFilterStrings: list<string>, SessionScriptS3Location: record<S3Bucket: string, S3Key: string>>>
# operationId: CreateFleet
export def "create-fleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # A unique name for the fleet.
  --image-name: string # The name of the image used to create the fleet.
  --image-arn: string # The ARN of the public, private, or shared image to use.
  instance_type: string # The instance type to use when launching fleet instances. The following instance types are available: stream.standard.small stream.standard.medium stream.standard.large stream.standard.xlarge stream.standard.2xlarge stream.compute.large stream.compute.xlarge stream.compute.2xlarge stream.compute.4xlarge stream.compute.8xlarge stream.memory.large stream.memory.xlarge stream.memory.2xlarge stream.memory.4xlarge stream.memory.8xlarge stream.memory.z1d.large stream.memory.z1d.xlarge stream.memory.z1d.2xlarge stream.memory.z1d.3xlarge stream.memory.z1d.6xlarge stream.memory.z1d.12xlarge stream.graphics-design.large stream.graphics-design.xlarge stream.graphics-design.2xlarge stream.graphics-design.4xlarge stream.graphics-desktop.2xlarge stream.graphics.g4dn.xlarge stream.graphics.g4dn.2xlarge stream.graphics.g4dn.4xlarge stream.graphics.g4dn.8xlarge stream.graphics.g4dn.12xlarge stream.graphics.g4dn.16xlarge stream.graphics-pro.4xlarge stream.graphics-pro.8xlarge stream.graphics-pro.16xlarge The following instance types are available for Elastic fleets: stream.standard.small stream.standard.medium stream.standard.large stream.standard.xlarge stream.standard.2xlarge
  --fleet-type: string@fleet-type-completer # The fleet type. ALWAYS_ON Provides users with instant-on access to their apps. You are charged for all running instances in your fleet, even if no users are streaming apps. ON_DEMAND Provide users with access to applications after they connect, which takes one to two minutes. You are charged for instance streaming when users are connected and a small hourly fee for instances that are not streaming apps.
  --compute-capacity: record # Describes the capacity for a fleet. — shape: {DesiredInstances: int}
  --vpc-config: record # Describes VPC configuration information for fleets and image builders. — shape: {SubnetIds?: list<string>, SecurityGroupIds?: list<string>}
  --max-user-duration-in-seconds: int # The maximum amount of time that a streaming session can remain active, in seconds. If users are still connected to a streaming instance five minutes before this limit is reached, they are prompted to save any open documents before being disconnected. After this time elapses, the instance is terminated and replaced by a new instance. Specify a value between 600 and 360000.
  --disconnect-timeout-in-seconds: int # The amount of time that a streaming session remains active after users disconnect. If users try to reconnect to the streaming session after a disconnection or network interruption within this time interval, they are connected to their previous session. Otherwise, they are connected to a new session with a new streaming instance. Specify a value between 60 and 360000.
  --description: string # The description to display.
  --display-name: string # The fleet name to display.
  --enable-default-internet-access: oneof<nothing, bool> # Enables or disables default internet access for the fleet.
  --domain-join-info: record # Describes the configuration information required to join fleets and image builders to Microsoft Active Directory domains. — shape: {DirectoryName?: string, OrganizationalUnitDistinguishedName?: string}
  --tags: record # The tags to associate with the fleet. A tag is a key-value pair, and the value is optional. For example, Environment=Test. If you do not specify a value, Environment=. If you do not specify a value, the value is set to an empty string. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following special characters: _ . : / = + \ - @ For more information, see Tagging Your Resources (https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html) in the Amazon AppStream 2.0 Administration Guide.
  --idle-disconnect-timeout-in-seconds: int # The amount of time that users can be idle (inactive) before they are disconnected from their streaming session and the DisconnectTimeoutInSeconds time interval begins. Users are notified before they are disconnected due to inactivity. If they try to reconnect to the streaming session before the time interval specified in DisconnectTimeoutInSeconds elapses, they are connected to their previous session. Users are considered idle when they stop providing keyboard or mouse input during their streaming session. File uploads and downloads, audio in, audio out, and pixels changing do not qualify as user activity. If users continue to be idle after the time interval in IdleDisconnectTimeoutInSeconds elapses, they are disconnected. To prevent users from being disconnected due to inactivity, specify a value of 0. Otherwise, specify a value between 60 and 3600. The default value is 0. If you enable this feature, we recommend that you specify a value that corresponds exactly to a whole number of minutes (for example, 60, 120, and 180). If you don't do this, the value is rounded to the nearest minute. For example, if you specify a value of 70, users are disconnected after 1 minute of inactivity. If you specify a value that is at the midpoint between two different minutes, the value is rounded up. For example, if you specify a value of 90, users are disconnected after 2 minutes of inactivity.
  --iam-role-arn: string # The Amazon Resource Name (ARN) of the IAM role to apply to the fleet. To assume a role, a fleet instance calls the AWS Security Token Service (STS) AssumeRole API operation and passes the ARN of the role to use. The operation creates a new session with temporary credentials. AppStream 2.0 retrieves the temporary credentials and creates the appstream_machine_role credential profile on the instance. For more information, see Using an IAM Role to Grant Permissions to Applications and Scripts Running on AppStream 2.0 Streaming Instances (https://docs.aws.amazon.com/appstream2/latest/developerguide/using-iam-roles-to-grant-permissions-to-applications-scripts-streaming-instances.html) in the Amazon AppStream 2.0 Administration Guide.
  --stream-view: string@stream-view-completer # The AppStream 2.0 view that is displayed to your users when they stream from the fleet. When APP is specified, only the windows of applications opened by users display. When DESKTOP is specified, the standard desktop that is provided by the operating system displays. The default value is APP.
  --platform: string@platform-completer # The fleet platform. WINDOWS_SERVER_2019 and AMAZON_LINUX2 are supported for Elastic fleets.
  --max-concurrent-sessions: int # The maximum concurrent sessions of the Elastic fleet. This is required for Elastic fleets, and not allowed for other fleet types.
  --usb-device-filter-strings: list<string> # The USB device filter strings that specify which USB devices a user can redirect to the fleet streaming session, when using the Windows native client. This is allowed but not required for Elastic fleets.
  --session-script-s3-location: record # Describes the S3 location. — shape: {S3Bucket: string, S3Key: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.CreateFleet"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: ImageName, var: image_name}, {name: ImageArn, var: image_arn}, {name: InstanceType, var: instance_type}, {name: FleetType, var: fleet_type}, {name: ComputeCapacity, var: compute_capacity}, {name: VpcConfig, var: vpc_config}, {name: MaxUserDurationInSeconds, var: max_user_duration_in_seconds}, {name: DisconnectTimeoutInSeconds, var: disconnect_timeout_in_seconds}, {name: Description, var: description}, {name: DisplayName, var: display_name}, {name: EnableDefaultInternetAccess, var: enable_default_internet_access}, {name: DomainJoinInfo, var: domain_join_info}, {name: Tags, var: tags}, {name: IdleDisconnectTimeoutInSeconds, var: idle_disconnect_timeout_in_seconds}, {name: IamRoleArn, var: iam_role_arn}, {name: StreamView, var: stream_view}, {name: Platform, var: platform}, {name: MaxConcurrentSessions, var: max_concurrent_sessions}, {name: UsbDeviceFilterStrings, var: usb_device_filter_strings}, {name: SessionScriptS3Location, var: session_script_s3_location}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, image_name: $image_name, image_arn: $image_arn, instance_type: $instance_type, fleet_type: $fleet_type, compute_capacity: $compute_capacity, vpc_config: $vpc_config, max_user_duration_in_seconds: $max_user_duration_in_seconds, disconnect_timeout_in_seconds: $disconnect_timeout_in_seconds, description: $description, display_name: $display_name, enable_default_internet_access: $enable_default_internet_access, domain_join_info: $domain_join_info, tags: $tags, idle_disconnect_timeout_in_seconds: $idle_disconnect_timeout_in_seconds, iam_role_arn: $iam_role_arn, stream_view: $stream_view, platform: $platform, max_concurrent_sessions: $max_concurrent_sessions, usb_device_filter_strings: $usb_device_filter_strings, session_script_s3_location: $session_script_s3_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an image builder. An image builder is a virtual machine that is used to create an image. The initial state of the builder is PENDING. When it is ready, the state is RUNNING.
#
# POST /
# Returns: record<ImageBuilder: record<Name: string, Arn: string, ImageArn: string, Description: string, DisplayName: string, VpcConfig: record<SubnetIds: list, SecurityGroupIds: list>, InstanceType: string, Platform: string, IamRoleArn: string, State: string, StateChangeReason: record<Code: string, Message: string>, CreatedTime: string, EnableDefaultInternetAccess: bool, DomainJoinInfo: record<DirectoryName: string, OrganizationalUnitDistinguishedName: string>, NetworkAccessConfiguration: record<EniPrivateIpAddress: string, EniId: string>, ImageBuilderErrors: list<record>, AppstreamAgentVersion: string, AccessEndpoints: list<record>>>
# operationId: CreateImageBuilder
export def "create-image-builder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # A unique name for the image builder.
  --image-name: string # The name of the image used to create the image builder.
  --image-arn: string # The ARN of the public, private, or shared image to use.
  instance_type: string # The instance type to use when launching the image builder. The following instance types are available: stream.standard.small stream.standard.medium stream.standard.large stream.compute.large stream.compute.xlarge stream.compute.2xlarge stream.compute.4xlarge stream.compute.8xlarge stream.memory.large stream.memory.xlarge stream.memory.2xlarge stream.memory.4xlarge stream.memory.8xlarge stream.memory.z1d.large stream.memory.z1d.xlarge stream.memory.z1d.2xlarge stream.memory.z1d.3xlarge stream.memory.z1d.6xlarge stream.memory.z1d.12xlarge stream.graphics-design.large stream.graphics-design.xlarge stream.graphics-design.2xlarge stream.graphics-design.4xlarge stream.graphics-desktop.2xlarge stream.graphics.g4dn.xlarge stream.graphics.g4dn.2xlarge stream.graphics.g4dn.4xlarge stream.graphics.g4dn.8xlarge stream.graphics.g4dn.12xlarge stream.graphics.g4dn.16xlarge stream.graphics-pro.4xlarge stream.graphics-pro.8xlarge stream.graphics-pro.16xlarge
  --description: string # The description to display.
  --display-name: string # The image builder name to display.
  --vpc-config: record # Describes VPC configuration information for fleets and image builders. — shape: {SubnetIds?: list<string>, SecurityGroupIds?: list<string>}
  --iam-role-arn: string # The Amazon Resource Name (ARN) of the IAM role to apply to the image builder. To assume a role, the image builder calls the AWS Security Token Service (STS) AssumeRole API operation and passes the ARN of the role to use. The operation creates a new session with temporary credentials. AppStream 2.0 retrieves the temporary credentials and creates the appstream_machine_role credential profile on the instance. For more information, see Using an IAM Role to Grant Permissions to Applications and Scripts Running on AppStream 2.0 Streaming Instances (https://docs.aws.amazon.com/appstream2/latest/developerguide/using-iam-roles-to-grant-permissions-to-applications-scripts-streaming-instances.html) in the Amazon AppStream 2.0 Administration Guide.
  --enable-default-internet-access: oneof<nothing, bool> # Enables or disables default internet access for the image builder.
  --domain-join-info: record # Describes the configuration information required to join fleets and image builders to Microsoft Active Directory domains. — shape: {DirectoryName?: string, OrganizationalUnitDistinguishedName?: string}
  --appstream-agent-version: string # The version of the AppStream 2.0 agent to use for this image builder. To use the latest version of the AppStream 2.0 agent, specify [LATEST].
  --tags: record # The tags to associate with the image builder. A tag is a key-value pair, and the value is optional. For example, Environment=Test. If you do not specify a value, Environment=. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following special characters: _ . : / = + \ - @ If you do not specify a value, the value is set to an empty string. For more information about tags, see Tagging Your Resources (https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html) in the Amazon AppStream 2.0 Administration Guide.
  --access-endpoints: list # The list of interface VPC endpoint (interface endpoint) objects. Administrators can connect to the image builder only through the specified endpoints. — item shape: {EndpointType: "STREAMING", VpceId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.CreateImageBuilder"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: ImageName, var: image_name}, {name: ImageArn, var: image_arn}, {name: InstanceType, var: instance_type}, {name: Description, var: description}, {name: DisplayName, var: display_name}, {name: VpcConfig, var: vpc_config}, {name: IamRoleArn, var: iam_role_arn}, {name: EnableDefaultInternetAccess, var: enable_default_internet_access}, {name: DomainJoinInfo, var: domain_join_info}, {name: AppstreamAgentVersion, var: appstream_agent_version}, {name: Tags, var: tags}, {name: AccessEndpoints, var: access_endpoints}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, image_name: $image_name, image_arn: $image_arn, instance_type: $instance_type, description: $description, display_name: $display_name, vpc_config: $vpc_config, iam_role_arn: $iam_role_arn, enable_default_internet_access: $enable_default_internet_access, domain_join_info: $domain_join_info, appstream_agent_version: $appstream_agent_version, tags: $tags, access_endpoints: $access_endpoints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a URL to start an image builder streaming session.
#
# POST /
# Returns: record<StreamingURL: string, Expires: string>
# operationId: CreateImageBuilderStreamingURL
export def "create-image-builder-streaming-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the image builder.
  --validity: int # The time that the streaming URL will be valid, in seconds. Specify a value between 1 and 604800 seconds. The default is 3600 seconds.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.CreateImageBuilderStreamingURL"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Validity, var: validity}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, validity: $validity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a stack to start streaming applications to users. A stack consists of an associated fleet, user access policies, and storage configurations.
#
# POST /
# Returns: record<Stack: record<Arn: string, Name: string, Description: string, DisplayName: string, CreatedTime: string, StorageConnectors: list<record>, RedirectURL: string, FeedbackURL: string, StackErrors: list<record>, UserSettings: list<record>, ApplicationSettings: record<Enabled: bool, SettingsGroup: string, S3BucketName: string>, AccessEndpoints: list<record>, EmbedHostDomains: list<string>, StreamingExperienceSettings: record<PreferredProtocol: string>>>
# operationId: CreateStack
export def "create-stack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the stack.
  --description: string # The description to display.
  --display-name: string # The stack name to display.
  --storage-connectors: list # The storage connectors. — item shape: {ConnectorType: "HOMEFOLDERS"|"GOOGLE_DRIVE"|"ONE_DRIVE", ResourceIdentifier?: string, Domains?: list<string>}
  --redirect-url: string # The URL that users are redirected to after their streaming session ends.
  --feedback-url: string # The URL that users are redirected to after they click the Send Feedback link. If no URL is specified, no Send Feedback link is displayed.
  --user-settings: list # The actions that are enabled or disabled for users during their streaming sessions. By default, these actions are enabled. — item shape: {Action: "CLIPBOARD_COPY_FROM_LOCAL_DEVICE"|"CLIPBOARD_COPY_TO_LOCAL_DEVICE"|"FILE_UPLOAD"|"FILE_DOWNLOAD"|"PRINTING_TO_LOCAL_DEVICE"|"DOMAIN_PASSWORD_SIGNIN"|"DOMAIN_SMART_CARD_SIGNIN", Permission: "ENABLED"|"DISABLED"}
  --application-settings: record # The persistent application settings for users of a stack. — shape: {Enabled: bool, SettingsGroup?: string}
  --tags: record # The tags to associate with the stack. A tag is a key-value pair, and the value is optional. For example, Environment=Test. If you do not specify a value, Environment=. If you do not specify a value, the value is set to an empty string. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following special characters: _ . : / = + \ - @ For more information about tags, see Tagging Your Resources (https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html) in the Amazon AppStream 2.0 Administration Guide.
  --access-endpoints: list # The list of interface VPC endpoint (interface endpoint) objects. Users of the stack can connect to AppStream 2.0 only through the specified endpoints. — item shape: {EndpointType: "STREAMING", VpceId?: string}
  --embed-host-domains: list<string> # The domains where AppStream 2.0 streaming sessions can be embedded in an iframe. You must approve the domains that you want to host embedded AppStream 2.0 streaming sessions.
  --streaming-experience-settings: record # The streaming protocol you want your stack to prefer. This can be UDP or TCP. Currently, UDP is only supported in the Windows native client. — shape: {PreferredProtocol?: "TCP"|"UDP"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.CreateStack"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: DisplayName, var: display_name}, {name: StorageConnectors, var: storage_connectors}, {name: RedirectURL, var: redirect_url}, {name: FeedbackURL, var: feedback_url}, {name: UserSettings, var: user_settings}, {name: ApplicationSettings, var: application_settings}, {name: Tags, var: tags}, {name: AccessEndpoints, var: access_endpoints}, {name: EmbedHostDomains, var: embed_host_domains}, {name: StreamingExperienceSettings, var: streaming_experience_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, display_name: $display_name, storage_connectors: $storage_connectors, redirect_url: $redirect_url, feedback_url: $feedback_url, user_settings: $user_settings, application_settings: $application_settings, tags: $tags, access_endpoints: $access_endpoints, embed_host_domains: $embed_host_domains, streaming_experience_settings: $streaming_experience_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a temporary URL to start an AppStream 2.0 streaming session for the specified user. A streaming URL enables application streaming to be tested without user setup.
#
# POST /
# Returns: record<StreamingURL: string, Expires: string>
# operationId: CreateStreamingURL
export def "create-streaming-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  stack_name: string # The name of the stack.
  fleet_name: string # The name of the fleet.
  user_id: string # The identifier of the user.
  --application-id: string # The name of the application to launch after the session starts. This is the name that you specified as Name in the Image Assistant. If your fleet is enabled for the Desktop stream view, you can also choose to launch directly to the operating system desktop. To do so, specify Desktop.
  --validity: int # The time that the streaming URL will be valid, in seconds. Specify a value between 1 and 604800 seconds. The default is 60 seconds.
  --session-context: string # The session context. For more information, see Session Context (https://docs.aws.amazon.com/appstream2/latest/developerguide/managing-stacks-fleets.html#managing-stacks-fleets-parameters) in the Amazon AppStream 2.0 Administration Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.CreateStreamingURL"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackName, var: stack_name}, {name: FleetName, var: fleet_name}, {name: UserId, var: user_id}, {name: ApplicationId, var: application_id}, {name: Validity, var: validity}, {name: SessionContext, var: session_context}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_name: $stack_name, fleet_name: $fleet_name, user_id: $user_id, application_id: $application_id, validity: $validity, session_context: $session_context
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new image with the latest Windows operating system updates, driver updates, and AppStream 2.0 agent software. For more information, see the "Update an Image by Using Managed AppStream 2.0 Image Updates" section in Administer Your AppStream 2.0 Images (https://docs.aws.amazon.com/appstream2/latest/developerguide/administer-images.html), in the Amazon AppStream 2.0 Administration Guide.
#
# POST /
# Returns: record<image: record<Name: string, Arn: string, BaseImageArn: string, DisplayName: string, State: string, Visibility: string, ImageBuilderSupported: bool, ImageBuilderName: string, Platform: string, Description: string, StateChangeReason: record<Code: string, Message: string>, Applications: list<record>, CreatedTime: string, PublicBaseImageReleasedDate: string, AppstreamAgentVersion: string, ImagePermissions: record<allowFleet: bool, allowImageBuilder: bool>, ImageErrors: list<record>>, canUpdateImage: bool>
# operationId: CreateUpdatedImage
export def "create-updated-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  existing_image_name: string # The name of the image to update.
  new_image_name: string # The name of the new image. The name must be unique within the AWS account and Region.
  --new-image-description: string # The description to display for the new image.
  --new-image-display-name: string # The name to display for the new image.
  --new-image-tags: record # The tags to associate with the new image. A tag is a key-value pair, and the value is optional. For example, Environment=Test. If you do not specify a value, Environment=. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following special characters: _ . : / = + \ - @ If you do not specify a value, the value is set to an empty string. For more information about tags, see Tagging Your Resources (https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html) in the Amazon AppStream 2.0 Administration Guide.
  --body-dry-run: oneof<nothing, bool> # Indicates whether to display the status of image update availability before AppStream 2.0 initiates the process of creating a new updated image. If this value is set to true, AppStream 2.0 displays whether image updates are available. If this value is set to false, AppStream 2.0 initiates the process of creating a new updated image without displaying whether image updates are available. (spec name: dryRun)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.CreateUpdatedImage"}]
    body: {content_type: "application/json", kind: json, fields: [{name: existingImageName, var: existing_image_name}, {name: newImageName, var: new_image_name}, {name: newImageDescription, var: new_image_description}, {name: newImageDisplayName, var: new_image_display_name}, {name: newImageTags, var: new_image_tags}, {name: dryRun, var: body_dry_run}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, existing_image_name: $existing_image_name, new_image_name: $new_image_name, new_image_description: $new_image_description, new_image_display_name: $new_image_display_name, new_image_tags: $new_image_tags, body_dry_run: $body_dry_run
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a usage report subscription. Usage reports are generated daily.
#
# POST /
# Returns: record<S3BucketName: string, Schedule: string>
# operationId: CreateUsageReportSubscription
export def "create-usage-report-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.CreateUsageReportSubscription"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new user in the user pool.
#
# POST /
# Returns: record
# operationId: CreateUser
export def "create-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  user_name: string # The email address of the user. Users' email addresses are case-sensitive. During login, if they specify an email address that doesn't use the same capitalization as the email address specified when their user pool account was created, a "user does not exist" error message displays. (format: password)
  --message-action: string@message-action-completer # The action to take for the welcome email that is sent to a user after the user is created in the user pool. If you specify SUPPRESS, no email is sent. If you specify RESEND, do not specify the first name or last name of the user. If the value is null, the email is sent. The temporary password in the welcome email is valid for only 7 days. If users don’t set their passwords within 7 days, you must send them a new welcome email.
  --first-name: string # The first name, or given name, of the user. (format: password)
  --last-name: string # The last name, or surname, of the user. (format: password)
  authentication_type: string@authentication-type-completer # The authentication type for the user. You must specify USERPOOL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.CreateUser"}]
    body: {content_type: "application/json", kind: json, fields: [{name: UserName, var: user_name}, {name: MessageAction, var: message_action}, {name: FirstName, var: first_name}, {name: LastName, var: last_name}, {name: AuthenticationType, var: authentication_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, user_name: $user_name, message_action: $message_action, first_name: $first_name, last_name: $last_name, authentication_type: $authentication_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an app block.
#
# POST /
# Returns: record
# operationId: DeleteAppBlock
export def "delete-app-block" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the app block.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DeleteAppBlock"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an application.
#
# POST /
# Returns: record
# operationId: DeleteApplication
export def "delete-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the application.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DeleteApplication"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified Directory Config object from AppStream 2.0. This object includes the information required to join streaming instances to an Active Directory domain.
#
# POST /
# Returns: record
# operationId: DeleteDirectoryConfig
export def "delete-directory-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  directory_name: string # The name of the directory configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DeleteDirectoryConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DirectoryName, var: directory_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, directory_name: $directory_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified entitlement.
#
# POST /
# Returns: record
# operationId: DeleteEntitlement
export def "delete-entitlement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the entitlement.
  stack_name: string # The name of the stack with which the entitlement is associated.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DeleteEntitlement"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: StackName, var: stack_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, stack_name: $stack_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified fleet.
#
# POST /
# Returns: record
# operationId: DeleteFleet
export def "delete-fleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the fleet.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DeleteFleet"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified image. You cannot delete an image when it is in use. After you delete an image, you cannot provision new capacity using the image.
#
# POST /
# Returns: record<Image: record<Name: string, Arn: string, BaseImageArn: string, DisplayName: string, State: string, Visibility: string, ImageBuilderSupported: bool, ImageBuilderName: string, Platform: string, Description: string, StateChangeReason: record<Code: string, Message: string>, Applications: list<record>, CreatedTime: string, PublicBaseImageReleasedDate: string, AppstreamAgentVersion: string, ImagePermissions: record<allowFleet: bool, allowImageBuilder: bool>, ImageErrors: list<record>>>
# operationId: DeleteImage
export def "delete-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the image.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DeleteImage"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified image builder and releases the capacity.
#
# POST /
# Returns: record<ImageBuilder: record<Name: string, Arn: string, ImageArn: string, Description: string, DisplayName: string, VpcConfig: record<SubnetIds: list, SecurityGroupIds: list>, InstanceType: string, Platform: string, IamRoleArn: string, State: string, StateChangeReason: record<Code: string, Message: string>, CreatedTime: string, EnableDefaultInternetAccess: bool, DomainJoinInfo: record<DirectoryName: string, OrganizationalUnitDistinguishedName: string>, NetworkAccessConfiguration: record<EniPrivateIpAddress: string, EniId: string>, ImageBuilderErrors: list<record>, AppstreamAgentVersion: string, AccessEndpoints: list<record>>>
# operationId: DeleteImageBuilder
export def "delete-image-builder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the image builder.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DeleteImageBuilder"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes permissions for the specified private image. After you delete permissions for an image, AWS accounts to which you previously granted these permissions can no longer use the image.
#
# POST /
# Returns: record
# operationId: DeleteImagePermissions
export def "delete-image-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the private image.
  shared_account_id: string # The 12-digit identifier of the AWS account for which to delete image permissions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DeleteImagePermissions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: SharedAccountId, var: shared_account_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, shared_account_id: $shared_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified stack. After the stack is deleted, the application streaming environment provided by the stack is no longer available to users. Also, any reservations made for application streaming sessions for the stack are released.
#
# POST /
# Returns: record
# operationId: DeleteStack
export def "delete-stack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the stack.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DeleteStack"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables usage report generation.
#
# POST /
# Returns: record
# operationId: DeleteUsageReportSubscription
export def "delete-usage-report-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DeleteUsageReportSubscription"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a user from the user pool.
#
# POST /
# Returns: record
# operationId: DeleteUser
export def "delete-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  user_name: string # The email address of the user. Users' email addresses are case-sensitive. (format: password)
  authentication_type: string@authentication-type-completer # The authentication type for the user. You must specify USERPOOL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DeleteUser"}]
    body: {content_type: "application/json", kind: json, fields: [{name: UserName, var: user_name}, {name: AuthenticationType, var: authentication_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, user_name: $user_name, authentication_type: $authentication_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list that describes one or more app blocks.
#
# POST /
# Returns: record<AppBlocks: table<Name: string, Arn: string, Description: string, DisplayName: string, SourceS3Location: record, SetupScriptDetails: record, CreatedTime: string>, NextToken: string>
# operationId: DescribeAppBlocks
export def "describe-app-blocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --arns: list<string> # The ARNs of the app blocks.
  --next-token: string # The pagination token used to retrieve the next page of results for this operation.
  --max-results: int # The maximum size of each page of results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DescribeAppBlocks"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Arns, var: arns}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arns: $arns, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list that describes one or more application fleet associations. Either ApplicationArn or FleetName must be specified.
#
# POST /
# Returns: record<ApplicationFleetAssociations: table<FleetName: string, ApplicationArn: string>, NextToken: string>
# operationId: DescribeApplicationFleetAssociations
export def "describe-application-fleet-associations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --fleet-name: string # The name of the fleet.
  --application-arn: string # The ARN of the application.
  --max-results: int # The maximum size of each page of results.
  --next-token: string # The pagination token used to retrieve the next page of results for this operation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DescribeApplicationFleetAssociations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FleetName, var: fleet_name}, {name: ApplicationArn, var: application_arn}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, fleet_name: $fleet_name, application_arn: $application_arn, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list that describes one or more applications.
#
# POST /
# Returns: record<Applications: table<Name: string, DisplayName: string, IconURL: string, LaunchPath: string, LaunchParameters: string, Enabled: bool, Metadata: record, WorkingDirectory: string, Description: string, Arn: string, AppBlockArn: string, IconS3Location: record, Platforms: list, InstanceFamilies: list, CreatedTime: string>, NextToken: string>
# operationId: DescribeApplications
export def "describe-applications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --arns: list<string> # The ARNs for the applications.
  --next-token: string # The pagination token used to retrieve the next page of results for this operation.
  --max-results: int # The maximum size of each page of results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DescribeApplications"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Arns, var: arns}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arns: $arns, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list that describes one or more specified Directory Config objects for AppStream 2.0, if the names for these objects are provided. Otherwise, all Directory Config objects in the account are described. These objects include the configuration information required to join fleets and image builders to Microsoft Active Directory domains. Although the response syntax in this topic includes the account password, this password is not returned in the actual response.
#
# POST /
# Returns: record<DirectoryConfigs: table<DirectoryName: string, OrganizationalUnitDistinguishedNames: list, ServiceAccountCredentials: record, CreatedTime: string, CertificateBasedAuthProperties: record>, NextToken: string>
# operationId: DescribeDirectoryConfigs
export def "describe-directory-configs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --directory-names: list<string> # The directory names.
  --max-results: int # The maximum size of each page of results.
  --next-token: string # The pagination token to use to retrieve the next page of results for this operation. If this value is null, it retrieves the first page.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DescribeDirectoryConfigs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DirectoryNames, var: directory_names}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, directory_names: $directory_names, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list that describes one of more entitlements.
#
# POST /
# Returns: record<Entitlements: table<Name: string, StackName: string, Description: string, AppVisibility: string, Attributes: list, CreatedTime: string, LastModifiedTime: string>, NextToken: string>
# operationId: DescribeEntitlements
export def "describe-entitlements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --name: string # The name of the entitlement.
  stack_name: string # The name of the stack with which the entitlement is associated.
  --next-token: string # The pagination token used to retrieve the next page of results for this operation.
  --max-results: int # The maximum size of each page of results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DescribeEntitlements"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: StackName, var: stack_name}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, stack_name: $stack_name, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list that describes one or more specified fleets, if the fleet names are provided. Otherwise, all fleets in the account are described.
#
# POST /
# Returns: record<Fleets: table<Arn: string, Name: string, DisplayName: string, Description: string, ImageName: string, ImageArn: string, InstanceType: string, FleetType: string, ComputeCapacityStatus: record, MaxUserDurationInSeconds: int, DisconnectTimeoutInSeconds: int, State: string, VpcConfig: record, CreatedTime: string, FleetErrors: list, EnableDefaultInternetAccess: bool, DomainJoinInfo: record, IdleDisconnectTimeoutInSeconds: int, IamRoleArn: string, StreamView: string, Platform: string, MaxConcurrentSessions: int, UsbDeviceFilterStrings: list, SessionScriptS3Location: record>, NextToken: string>
# operationId: DescribeFleets
export def "describe-fleets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --names: list<string> # The names of the fleets to describe.
  --next-token: string # The pagination token to use to retrieve the next page of results for this operation. If this value is null, it retrieves the first page.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DescribeFleets"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Names, var: names}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, names: $names, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list that describes one or more specified image builders, if the image builder names are provided. Otherwise, all image builders in the account are described.
#
# POST /
# Returns: record<ImageBuilders: table<Name: string, Arn: string, ImageArn: string, Description: string, DisplayName: string, VpcConfig: record, InstanceType: string, Platform: string, IamRoleArn: string, State: string, StateChangeReason: record, CreatedTime: string, EnableDefaultInternetAccess: bool, DomainJoinInfo: record, NetworkAccessConfiguration: record, ImageBuilderErrors: list, AppstreamAgentVersion: string, AccessEndpoints: list>, NextToken: string>
# operationId: DescribeImageBuilders
export def "describe-image-builders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --names: list<string> # The names of the image builders to describe.
  --max-results: int # The maximum size of each page of results.
  --next-token: string # The pagination token to use to retrieve the next page of results for this operation. If this value is null, it retrieves the first page.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DescribeImageBuilders"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Names, var: names}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, names: $names, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list that describes the permissions for shared AWS account IDs on a private image that you own.
#
# POST /
# Returns: record<Name: string, SharedImagePermissionsList: table<sharedAccountId: string, imagePermissions: record>, NextToken: string>
# operationId: DescribeImagePermissions
export def "describe-image-permissions" [
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  name: string # The name of the private image for which to describe permissions. The image must be one that you own.
  --body-max-results: int # The maximum size of each page of results. (spec name: MaxResults)
  --shared-aws-account-ids: list<string> # The 12-digit identifier of one or more AWS accounts with which the image is shared.
  --body-next-token: string # The pagination token to use to retrieve the next page of results for this operation. If this value is null, it retrieves the first page. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DescribeImagePermissions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: MaxResults, var: body_max_results}, {name: SharedAwsAccountIds, var: shared_aws_account_ids}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, body_max_results: $body_max_results, shared_aws_account_ids: $shared_aws_account_ids, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list that describes one or more specified images, if the image names or image ARNs are provided. Otherwise, all images in the account are described.
#
# POST /
# Returns: record<Images: table<Name: string, Arn: string, BaseImageArn: string, DisplayName: string, State: string, Visibility: string, ImageBuilderSupported: bool, ImageBuilderName: string, Platform: string, Description: string, StateChangeReason: record, Applications: list, CreatedTime: string, PublicBaseImageReleasedDate: string, AppstreamAgentVersion: string, ImagePermissions: record, ImageErrors: list>, NextToken: string>
# operationId: DescribeImages
export def "describe-images" [
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
  --x-amz-target: string@x-amz-target-completer-37 # required
  --names: list<string> # The names of the public or private images to describe.
  --arns: list<string> # The ARNs of the public, private, and shared images to describe.
  --type: string@type-completer # The type of image (public, private, or shared) to describe.
  --body-next-token: string # The pagination token to use to retrieve the next page of results for this operation. If this value is null, it retrieves the first page. (spec name: NextToken)
  --body-max-results: int # The maximum size of each page of results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DescribeImages"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Names, var: names}, {name: Arns, var: arns}, {name: Type, var: type}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, names: $names, arns: $arns, type: $type, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list that describes the streaming sessions for a specified stack and fleet. If a UserId is provided for the stack and fleet, only streaming sessions for that user are described. If an authentication type is not provided, the default is to authenticate users using a streaming URL.
#
# POST /
# Returns: record<Sessions: table<Id: string, UserId: string, StackName: string, FleetName: string, State: string, ConnectionState: string, StartTime: string, MaxExpirationTime: string, AuthenticationType: string, NetworkAccessConfiguration: record>, NextToken: string>
# operationId: DescribeSessions
export def "describe-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  stack_name: string # The name of the stack. This value is case-sensitive.
  fleet_name: string # The name of the fleet. This value is case-sensitive.
  --user-id: string # The user identifier (ID). If you specify a user ID, you must also specify the authentication type.
  --next-token: string # The pagination token to use to retrieve the next page of results for this operation. If this value is null, it retrieves the first page.
  --limit: int # The size of each page of results. The default value is 20 and the maximum value is 50.
  --authentication-type: string@authentication-type-completer # The authentication method. Specify API for a user authenticated using a streaming URL or SAML for a SAML federated user. The default is to authenticate users using a streaming URL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DescribeSessions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackName, var: stack_name}, {name: FleetName, var: fleet_name}, {name: UserId, var: user_id}, {name: NextToken, var: next_token}, {name: Limit, var: limit}, {name: AuthenticationType, var: authentication_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_name: $stack_name, fleet_name: $fleet_name, user_id: $user_id, next_token: $next_token, limit: $limit, authentication_type: $authentication_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list that describes one or more specified stacks, if the stack names are provided. Otherwise, all stacks in the account are described.
#
# POST /
# Returns: record<Stacks: table<Arn: string, Name: string, Description: string, DisplayName: string, CreatedTime: string, StorageConnectors: list, RedirectURL: string, FeedbackURL: string, StackErrors: list, UserSettings: list, ApplicationSettings: record, AccessEndpoints: list, EmbedHostDomains: list, StreamingExperienceSettings: record>, NextToken: string>
# operationId: DescribeStacks
export def "describe-stacks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --names: list<string> # The names of the stacks to describe.
  --next-token: string # The pagination token to use to retrieve the next page of results for this operation. If this value is null, it retrieves the first page.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DescribeStacks"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Names, var: names}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, names: $names, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list that describes one or more usage report subscriptions.
#
# POST /
# Returns: record<UsageReportSubscriptions: table<S3BucketName: string, Schedule: string, LastGeneratedReportDate: string, SubscriptionErrors: list>, NextToken: string>
# operationId: DescribeUsageReportSubscriptions
export def "describe-usage-report-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --max-results: int # The maximum size of each page of results.
  --next-token: string # The pagination token to use to retrieve the next page of results for this operation. If this value is null, it retrieves the first page.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DescribeUsageReportSubscriptions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list that describes the UserStackAssociation objects. You must specify either or both of the following: The stack name The user name (email address of the user associated with the stack) and the authentication type for the user
#
# POST /
# Returns: record<UserStackAssociations: table<StackName: string, UserName: string, AuthenticationType: string, SendEmailNotification: bool>, NextToken: string>
# operationId: DescribeUserStackAssociations
export def "describe-user-stack-associations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --stack-name: string # The name of the stack that is associated with the user.
  --user-name: string # The email address of the user who is associated with the stack. Users' email addresses are case-sensitive. (format: password)
  --authentication-type: string@authentication-type-completer # The authentication type for the user who is associated with the stack. You must specify USERPOOL.
  --max-results: int # The maximum size of each page of results.
  --next-token: string # The pagination token to use to retrieve the next page of results for this operation. If this value is null, it retrieves the first page.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DescribeUserStackAssociations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackName, var: stack_name}, {name: UserName, var: user_name}, {name: AuthenticationType, var: authentication_type}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_name: $stack_name, user_name: $user_name, authentication_type: $authentication_type, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list that describes one or more specified users in the user pool.
#
# POST /
# Returns: record<Users: table<Arn: string, UserName: string, Enabled: bool, Status: string, FirstName: string, LastName: string, CreatedTime: string, AuthenticationType: string>, NextToken: string>
# operationId: DescribeUsers
export def "describe-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  authentication_type: string@authentication-type-completer # The authentication type for the users in the user pool to describe. You must specify USERPOOL.
  --max-results: int # The maximum size of each page of results.
  --next-token: string # The pagination token to use to retrieve the next page of results for this operation. If this value is null, it retrieves the first page.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DescribeUsers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AuthenticationType, var: authentication_type}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, authentication_type: $authentication_type, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables the specified user in the user pool. Users can't sign in to AppStream 2.0 until they are re-enabled. This action does not delete the user.
#
# POST /
# Returns: record
# operationId: DisableUser
export def "disable-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  user_name: string # The email address of the user. Users' email addresses are case-sensitive. (format: password)
  authentication_type: string@authentication-type-completer # The authentication type for the user. You must specify USERPOOL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DisableUser"}]
    body: {content_type: "application/json", kind: json, fields: [{name: UserName, var: user_name}, {name: AuthenticationType, var: authentication_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, user_name: $user_name, authentication_type: $authentication_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates the specified application from the fleet.
#
# POST /
# Returns: record
# operationId: DisassociateApplicationFleet
export def "disassociate-application-fleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  fleet_name: string # The name of the fleet.
  application_arn: string # The ARN of the application.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DisassociateApplicationFleet"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FleetName, var: fleet_name}, {name: ApplicationArn, var: application_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, fleet_name: $fleet_name, application_arn: $application_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified application from the specified entitlement.
#
# POST /
# Returns: record
# operationId: DisassociateApplicationFromEntitlement
export def "disassociate-application-from-entitlement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  stack_name: string # The name of the stack with which the entitlement is associated.
  entitlement_name: string # The name of the entitlement.
  application_identifier: string # The identifier of the application to remove from the entitlement.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DisassociateApplicationFromEntitlement"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackName, var: stack_name}, {name: EntitlementName, var: entitlement_name}, {name: ApplicationIdentifier, var: application_identifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_name: $stack_name, entitlement_name: $entitlement_name, application_identifier: $application_identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates the specified fleet from the specified stack.
#
# POST /
# Returns: record
# operationId: DisassociateFleet
export def "disassociate-fleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  fleet_name: string # The name of the fleet.
  stack_name: string # The name of the stack.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.DisassociateFleet"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FleetName, var: fleet_name}, {name: StackName, var: stack_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, fleet_name: $fleet_name, stack_name: $stack_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables a user in the user pool. After being enabled, users can sign in to AppStream 2.0 and open applications from the stacks to which they are assigned.
#
# POST /
# Returns: record
# operationId: EnableUser
export def "enable-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  user_name: string # The email address of the user. Users' email addresses are case-sensitive. During login, if they specify an email address that doesn't use the same capitalization as the email address specified when their user pool account was created, a "user does not exist" error message displays. (format: password)
  authentication_type: string@authentication-type-completer # The authentication type for the user. You must specify USERPOOL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.EnableUser"}]
    body: {content_type: "application/json", kind: json, fields: [{name: UserName, var: user_name}, {name: AuthenticationType, var: authentication_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, user_name: $user_name, authentication_type: $authentication_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Immediately stops the specified streaming session.
#
# POST /
# Returns: record
# operationId: ExpireSession
export def "expire-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  session_id: string # The identifier of the streaming session.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.ExpireSession"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SessionId, var: session_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, session_id: $session_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the name of the fleet that is associated with the specified stack.
#
# POST /
# Returns: record<Names: list<string>, NextToken: string>
# operationId: ListAssociatedFleets
export def "list-associated-fleets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  stack_name: string # The name of the stack.
  --next-token: string # The pagination token to use to retrieve the next page of results for this operation. If this value is null, it retrieves the first page.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.ListAssociatedFleets"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackName, var: stack_name}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_name: $stack_name, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the name of the stack with which the specified fleet is associated.
#
# POST /
# Returns: record<Names: list<string>, NextToken: string>
# operationId: ListAssociatedStacks
export def "list-associated-stacks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  fleet_name: string # The name of the fleet.
  --next-token: string # The pagination token to use to retrieve the next page of results for this operation. If this value is null, it retrieves the first page.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.ListAssociatedStacks"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FleetName, var: fleet_name}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, fleet_name: $fleet_name, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of entitled applications.
#
# POST /
# Returns: record<EntitledApplications: table<ApplicationIdentifier: string>, NextToken: string>
# operationId: ListEntitledApplications
export def "list-entitled-applications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  stack_name: string # The name of the stack with which the entitlement is associated.
  entitlement_name: string # The name of the entitlement.
  --next-token: string # The pagination token used to retrieve the next page of results for this operation.
  --max-results: int # The maximum size of each page of results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.ListEntitledApplications"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackName, var: stack_name}, {name: EntitlementName, var: entitlement_name}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_name: $stack_name, entitlement_name: $entitlement_name, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of all tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks. For more information about tags, see Tagging Your Resources (https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html) in the Amazon AppStream 2.0 Administration Guide.
#
# POST /
# Returns: record<Tags: record>
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-52 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts the specified fleet.
#
# POST /
# Returns: record
# operationId: StartFleet
export def "start-fleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the fleet.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.StartFleet"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts the specified image builder.
#
# POST /
# Returns: record<ImageBuilder: record<Name: string, Arn: string, ImageArn: string, Description: string, DisplayName: string, VpcConfig: record<SubnetIds: list, SecurityGroupIds: list>, InstanceType: string, Platform: string, IamRoleArn: string, State: string, StateChangeReason: record<Code: string, Message: string>, CreatedTime: string, EnableDefaultInternetAccess: bool, DomainJoinInfo: record<DirectoryName: string, OrganizationalUnitDistinguishedName: string>, NetworkAccessConfiguration: record<EniPrivateIpAddress: string, EniId: string>, ImageBuilderErrors: list<record>, AppstreamAgentVersion: string, AccessEndpoints: list<record>>>
# operationId: StartImageBuilder
export def "start-image-builder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the image builder.
  --appstream-agent-version: string # The version of the AppStream 2.0 agent to use for this image builder. To use the latest version of the AppStream 2.0 agent, specify [LATEST].
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.StartImageBuilder"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: AppstreamAgentVersion, var: appstream_agent_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, appstream_agent_version: $appstream_agent_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops the specified fleet.
#
# POST /
# Returns: record
# operationId: StopFleet
export def "stop-fleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the fleet.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.StopFleet"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops the specified image builder.
#
# POST /
# Returns: record<ImageBuilder: record<Name: string, Arn: string, ImageArn: string, Description: string, DisplayName: string, VpcConfig: record<SubnetIds: list, SecurityGroupIds: list>, InstanceType: string, Platform: string, IamRoleArn: string, State: string, StateChangeReason: record<Code: string, Message: string>, CreatedTime: string, EnableDefaultInternetAccess: bool, DomainJoinInfo: record<DirectoryName: string, OrganizationalUnitDistinguishedName: string>, NetworkAccessConfiguration: record<EniPrivateIpAddress: string, EniId: string>, ImageBuilderErrors: list<record>, AppstreamAgentVersion: string, AccessEndpoints: list<record>>>
# operationId: StopImageBuilder
export def "stop-image-builder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the image builder.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.StopImageBuilder"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds or overwrites one or more tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks. Each tag consists of a key and an optional value. If a resource already has a tag with the same key, this operation updates its value. To list the current tags for your resources, use ListTagsForResource. To disassociate tags from your resources, use UntagResource. For more information about tags, see Tagging Your Resources (https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html) in the Amazon AppStream 2.0 Administration Guide.
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
  --x-amz-target: string@x-amz-target-completer-57 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource.
  tags: record # The tags to associate. A tag is a key-value pair, and the value is optional. For example, Environment=Test. If you do not specify a value, Environment=. If you do not specify a value, the value is set to an empty string. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following special characters: _ . : / = + \ - @
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates one or more specified tags from the specified AppStream 2.0 resource. To list the current tags for your resources, use ListTagsForResource. For more information about tags, see Tagging Your Resources (https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html) in the Amazon AppStream 2.0 Administration Guide.
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
  --x-amz-target: string@x-amz-target-completer-58 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource.
  tag_keys: list<string> # The tag keys for the tags to disassociate.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified application.
#
# POST /
# Returns: record<Application: record<Name: string, DisplayName: string, IconURL: string, LaunchPath: string, LaunchParameters: string, Enabled: bool, Metadata: record, WorkingDirectory: string, Description: string, Arn: string, AppBlockArn: string, IconS3Location: record<S3Bucket: string, S3Key: string>, Platforms: list<string>, InstanceFamilies: list<string>, CreatedTime: string>>
# operationId: UpdateApplication
export def "update-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the application. This name is visible to users when display name is not specified.
  --display-name: string # The display name of the application. This name is visible to users in the application catalog.
  --description: string # The description of the application.
  --icon-s3-location: record # Describes the S3 location. — shape: {S3Bucket: string, S3Key: string}
  --launch-path: string # The launch path of the application.
  --working-directory: string # The working directory of the application.
  --launch-parameters: string # The launch parameters of the application.
  --app-block-arn: string # The ARN of the app block.
  --attributes-to-delete: list<string> # The attributes to delete for an application.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.UpdateApplication"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: DisplayName, var: display_name}, {name: Description, var: description}, {name: IconS3Location, var: icon_s3_location}, {name: LaunchPath, var: launch_path}, {name: WorkingDirectory, var: working_directory}, {name: LaunchParameters, var: launch_parameters}, {name: AppBlockArn, var: app_block_arn}, {name: AttributesToDelete, var: attributes_to_delete}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, display_name: $display_name, description: $description, icon_s3_location: $icon_s3_location, launch_path: $launch_path, working_directory: $working_directory, launch_parameters: $launch_parameters, app_block_arn: $app_block_arn, attributes_to_delete: $attributes_to_delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
#
# POST /
# Returns: record<DirectoryConfig: record<DirectoryName: string, OrganizationalUnitDistinguishedNames: list<string>, ServiceAccountCredentials: record<AccountName: string, AccountPassword: string>, CreatedTime: string, CertificateBasedAuthProperties: record<Status: string, CertificateAuthorityArn: string>>>
# operationId: UpdateDirectoryConfig
export def "update-directory-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  directory_name: string # The name of the Directory Config object.
  --organizational-unit-distinguished-names: list<string> # The distinguished names of the organizational units for computer accounts.
  --service-account-credentials: record # Describes the credentials for the service account used by the fleet or image builder to connect to the directory. — shape: {AccountName: string, AccountPassword: string}
  --certificate-based-auth-properties: record # The certificate-based authentication properties used to authenticate SAML 2.0 Identity Provider (IdP) user identities to Active Directory domain-joined streaming instances. Fallback is turned on by default when certificate-based authentication is Enabled . Fallback allows users to log in using their AD domain password if certificate-based authentication is unsuccessful, or to unlock a desktop lock screen. Enabled_no_directory_login_fallback enables certificate-based authentication, but does not allow users to log in using their AD domain password. Users will be disconnected to re-authenticate using certificates. — shape: {Status?: "DISABLED"|"ENABLED"|"ENABLED_NO_DIRECTORY_LOGIN_FALLBACK", CertificateAuthorityArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.UpdateDirectoryConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DirectoryName, var: directory_name}, {name: OrganizationalUnitDistinguishedNames, var: organizational_unit_distinguished_names}, {name: ServiceAccountCredentials, var: service_account_credentials}, {name: CertificateBasedAuthProperties, var: certificate_based_auth_properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, directory_name: $directory_name, organizational_unit_distinguished_names: $organizational_unit_distinguished_names, service_account_credentials: $service_account_credentials, certificate_based_auth_properties: $certificate_based_auth_properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified entitlement.
#
# POST /
# Returns: record<Entitlement: record<Name: string, StackName: string, Description: string, AppVisibility: string, Attributes: list<record>, CreatedTime: string, LastModifiedTime: string>>
# operationId: UpdateEntitlement
export def "update-entitlement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the entitlement.
  stack_name: string # The name of the stack with which the entitlement is associated.
  --description: string # The description of the entitlement.
  --app-visibility: string@app-visibility-completer # Specifies whether all or only selected apps are entitled.
  --attributes: list # The attributes of the entitlement. — item shape: {Name: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.UpdateEntitlement"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: StackName, var: stack_name}, {name: Description, var: description}, {name: AppVisibility, var: app_visibility}, {name: Attributes, var: attributes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, stack_name: $stack_name, description: $description, app_visibility: $app_visibility, attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified fleet. If the fleet is in the STOPPED state, you can update any attribute except the fleet name. If the fleet is in the RUNNING state, you can update the following based on the fleet type: Always-On and On-Demand fleet types You can update the DisplayName, ComputeCapacity, ImageARN, ImageName, IdleDisconnectTimeoutInSeconds, and DisconnectTimeoutInSeconds attributes. Elastic fleet type You can update the DisplayName, IdleDisconnectTimeoutInSeconds, DisconnectTimeoutInSeconds, MaxConcurrentSessions, SessionScriptS3Location and UsbDeviceFilterStrings attributes. If the fleet is in the STARTING or STOPPED state, you can't update it.
#
# POST /
# Returns: record<Fleet: record<Arn: string, Name: string, DisplayName: string, Description: string, ImageName: string, ImageArn: string, InstanceType: string, FleetType: string, ComputeCapacityStatus: record<Desired: int, Running: int, InUse: int, Available: int>, MaxUserDurationInSeconds: int, DisconnectTimeoutInSeconds: int, State: string, VpcConfig: record<SubnetIds: list, SecurityGroupIds: list>, CreatedTime: string, FleetErrors: list<record>, EnableDefaultInternetAccess: bool, DomainJoinInfo: record<DirectoryName: string, OrganizationalUnitDistinguishedName: string>, IdleDisconnectTimeoutInSeconds: int, IamRoleArn: string, StreamView: string, Platform: string, MaxConcurrentSessions: int, UsbDeviceFilterStrings: list<string>, SessionScriptS3Location: record<S3Bucket: string, S3Key: string>>>
# operationId: UpdateFleet
export def "update-fleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --image-name: string # The name of the image used to create the fleet.
  --image-arn: string # The ARN of the public, private, or shared image to use.
  --name: string # A unique name for the fleet.
  --instance-type: string # The instance type to use when launching fleet instances. The following instance types are available: stream.standard.small stream.standard.medium stream.standard.large stream.standard.xlarge stream.standard.2xlarge stream.compute.large stream.compute.xlarge stream.compute.2xlarge stream.compute.4xlarge stream.compute.8xlarge stream.memory.large stream.memory.xlarge stream.memory.2xlarge stream.memory.4xlarge stream.memory.8xlarge stream.memory.z1d.large stream.memory.z1d.xlarge stream.memory.z1d.2xlarge stream.memory.z1d.3xlarge stream.memory.z1d.6xlarge stream.memory.z1d.12xlarge stream.graphics-design.large stream.graphics-design.xlarge stream.graphics-design.2xlarge stream.graphics-design.4xlarge stream.graphics-desktop.2xlarge stream.graphics.g4dn.xlarge stream.graphics.g4dn.2xlarge stream.graphics.g4dn.4xlarge stream.graphics.g4dn.8xlarge stream.graphics.g4dn.12xlarge stream.graphics.g4dn.16xlarge stream.graphics-pro.4xlarge stream.graphics-pro.8xlarge stream.graphics-pro.16xlarge The following instance types are available for Elastic fleets: stream.standard.small stream.standard.medium stream.standard.large stream.standard.xlarge stream.standard.2xlarge
  --compute-capacity: record # Describes the capacity for a fleet. — shape: {DesiredInstances: int}
  --vpc-config: record # Describes VPC configuration information for fleets and image builders. — shape: {SubnetIds?: list<string>, SecurityGroupIds?: list<string>}
  --max-user-duration-in-seconds: int # The maximum amount of time that a streaming session can remain active, in seconds. If users are still connected to a streaming instance five minutes before this limit is reached, they are prompted to save any open documents before being disconnected. After this time elapses, the instance is terminated and replaced by a new instance. Specify a value between 600 and 360000.
  --disconnect-timeout-in-seconds: int # The amount of time that a streaming session remains active after users disconnect. If users try to reconnect to the streaming session after a disconnection or network interruption within this time interval, they are connected to their previous session. Otherwise, they are connected to a new session with a new streaming instance. Specify a value between 60 and 360000.
  --delete-vpc-config: oneof<nothing, bool> # Deletes the VPC association for the specified fleet.
  --description: string # The description to display.
  --display-name: string # The fleet name to display.
  --enable-default-internet-access: oneof<nothing, bool> # Enables or disables default internet access for the fleet.
  --domain-join-info: record # Describes the configuration information required to join fleets and image builders to Microsoft Active Directory domains. — shape: {DirectoryName?: string, OrganizationalUnitDistinguishedName?: string}
  --idle-disconnect-timeout-in-seconds: int # The amount of time that users can be idle (inactive) before they are disconnected from their streaming session and the DisconnectTimeoutInSeconds time interval begins. Users are notified before they are disconnected due to inactivity. If users try to reconnect to the streaming session before the time interval specified in DisconnectTimeoutInSeconds elapses, they are connected to their previous session. Users are considered idle when they stop providing keyboard or mouse input during their streaming session. File uploads and downloads, audio in, audio out, and pixels changing do not qualify as user activity. If users continue to be idle after the time interval in IdleDisconnectTimeoutInSeconds elapses, they are disconnected. To prevent users from being disconnected due to inactivity, specify a value of 0. Otherwise, specify a value between 60 and 3600. The default value is 0. If you enable this feature, we recommend that you specify a value that corresponds exactly to a whole number of minutes (for example, 60, 120, and 180). If you don't do this, the value is rounded to the nearest minute. For example, if you specify a value of 70, users are disconnected after 1 minute of inactivity. If you specify a value that is at the midpoint between two different minutes, the value is rounded up. For example, if you specify a value of 90, users are disconnected after 2 minutes of inactivity.
  --attributes-to-delete: list<string> # The fleet attributes.
  --iam-role-arn: string # The Amazon Resource Name (ARN) of the IAM role to apply to the fleet. To assume a role, a fleet instance calls the AWS Security Token Service (STS) AssumeRole API operation and passes the ARN of the role to use. The operation creates a new session with temporary credentials. AppStream 2.0 retrieves the temporary credentials and creates the appstream_machine_role credential profile on the instance. For more information, see Using an IAM Role to Grant Permissions to Applications and Scripts Running on AppStream 2.0 Streaming Instances (https://docs.aws.amazon.com/appstream2/latest/developerguide/using-iam-roles-to-grant-permissions-to-applications-scripts-streaming-instances.html) in the Amazon AppStream 2.0 Administration Guide.
  --stream-view: string@stream-view-completer # The AppStream 2.0 view that is displayed to your users when they stream from the fleet. When APP is specified, only the windows of applications opened by users display. When DESKTOP is specified, the standard desktop that is provided by the operating system displays. The default value is APP.
  --platform: string@platform-completer # The platform of the fleet. WINDOWS_SERVER_2019 and AMAZON_LINUX2 are supported for Elastic fleets.
  --max-concurrent-sessions: int # The maximum number of concurrent sessions for a fleet.
  --usb-device-filter-strings: list<string> # The USB device filter strings that specify which USB devices a user can redirect to the fleet streaming session, when using the Windows native client. This is allowed but not required for Elastic fleets.
  --session-script-s3-location: record # Describes the S3 location. — shape: {S3Bucket: string, S3Key: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.UpdateFleet"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ImageName, var: image_name}, {name: ImageArn, var: image_arn}, {name: Name, var: name}, {name: InstanceType, var: instance_type}, {name: ComputeCapacity, var: compute_capacity}, {name: VpcConfig, var: vpc_config}, {name: MaxUserDurationInSeconds, var: max_user_duration_in_seconds}, {name: DisconnectTimeoutInSeconds, var: disconnect_timeout_in_seconds}, {name: DeleteVpcConfig, var: delete_vpc_config}, {name: Description, var: description}, {name: DisplayName, var: display_name}, {name: EnableDefaultInternetAccess, var: enable_default_internet_access}, {name: DomainJoinInfo, var: domain_join_info}, {name: IdleDisconnectTimeoutInSeconds, var: idle_disconnect_timeout_in_seconds}, {name: AttributesToDelete, var: attributes_to_delete}, {name: IamRoleArn, var: iam_role_arn}, {name: StreamView, var: stream_view}, {name: Platform, var: platform}, {name: MaxConcurrentSessions, var: max_concurrent_sessions}, {name: UsbDeviceFilterStrings, var: usb_device_filter_strings}, {name: SessionScriptS3Location, var: session_script_s3_location}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, image_name: $image_name, image_arn: $image_arn, name: $name, instance_type: $instance_type, compute_capacity: $compute_capacity, vpc_config: $vpc_config, max_user_duration_in_seconds: $max_user_duration_in_seconds, disconnect_timeout_in_seconds: $disconnect_timeout_in_seconds, delete_vpc_config: $delete_vpc_config, description: $description, display_name: $display_name, enable_default_internet_access: $enable_default_internet_access, domain_join_info: $domain_join_info, idle_disconnect_timeout_in_seconds: $idle_disconnect_timeout_in_seconds, attributes_to_delete: $attributes_to_delete, iam_role_arn: $iam_role_arn, stream_view: $stream_view, platform: $platform, max_concurrent_sessions: $max_concurrent_sessions, usb_device_filter_strings: $usb_device_filter_strings, session_script_s3_location: $session_script_s3_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds or updates permissions for the specified private image.
#
# POST /
# Returns: record
# operationId: UpdateImagePermissions
export def "update-image-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the private image.
  shared_account_id: string # The 12-digit identifier of the AWS account for which you want add or update image permissions.
  image_permissions: record # Describes the permissions for an image. — shape: {allowFleet?: bool, allowImageBuilder?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.UpdateImagePermissions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: SharedAccountId, var: shared_account_id}, {name: ImagePermissions, var: image_permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, shared_account_id: $shared_account_id, image_permissions: $image_permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified fields for the specified stack.
#
# POST /
# Returns: record<Stack: record<Arn: string, Name: string, Description: string, DisplayName: string, CreatedTime: string, StorageConnectors: list<record>, RedirectURL: string, FeedbackURL: string, StackErrors: list<record>, UserSettings: list<record>, ApplicationSettings: record<Enabled: bool, SettingsGroup: string, S3BucketName: string>, AccessEndpoints: list<record>, EmbedHostDomains: list<string>, StreamingExperienceSettings: record<PreferredProtocol: string>>>
# operationId: UpdateStack
export def "update-stack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --display-name: string # The stack name to display.
  --description: string # The description to display.
  name: string # The name of the stack.
  --storage-connectors: list # The storage connectors. — item shape: {ConnectorType: "HOMEFOLDERS"|"GOOGLE_DRIVE"|"ONE_DRIVE", ResourceIdentifier?: string, Domains?: list<string>}
  --delete-storage-connectors: oneof<nothing, bool> # Deletes the storage connectors currently enabled for the stack.
  --redirect-url: string # The URL that users are redirected to after their streaming session ends.
  --feedback-url: string # The URL that users are redirected to after they choose the Send Feedback link. If no URL is specified, no Send Feedback link is displayed.
  --attributes-to-delete: list<string> # The stack attributes to delete.
  --user-settings: list # The actions that are enabled or disabled for users during their streaming sessions. By default, these actions are enabled. — item shape: {Action: "CLIPBOARD_COPY_FROM_LOCAL_DEVICE"|"CLIPBOARD_COPY_TO_LOCAL_DEVICE"|"FILE_UPLOAD"|"FILE_DOWNLOAD"|"PRINTING_TO_LOCAL_DEVICE"|"DOMAIN_PASSWORD_SIGNIN"|"DOMAIN_SMART_CARD_SIGNIN", Permission: "ENABLED"|"DISABLED"}
  --application-settings: record # The persistent application settings for users of a stack. — shape: {Enabled: bool, SettingsGroup?: string}
  --access-endpoints: list # The list of interface VPC endpoint (interface endpoint) objects. Users of the stack can connect to AppStream 2.0 only through the specified endpoints. — item shape: {EndpointType: "STREAMING", VpceId?: string}
  --embed-host-domains: list<string> # The domains where AppStream 2.0 streaming sessions can be embedded in an iframe. You must approve the domains that you want to host embedded AppStream 2.0 streaming sessions.
  --streaming-experience-settings: record # The streaming protocol you want your stack to prefer. This can be UDP or TCP. Currently, UDP is only supported in the Windows native client. — shape: {PreferredProtocol?: "TCP"|"UDP"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "PhotonAdminProxyService.UpdateStack"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DisplayName, var: display_name}, {name: Description, var: description}, {name: Name, var: name}, {name: StorageConnectors, var: storage_connectors}, {name: DeleteStorageConnectors, var: delete_storage_connectors}, {name: RedirectURL, var: redirect_url}, {name: FeedbackURL, var: feedback_url}, {name: AttributesToDelete, var: attributes_to_delete}, {name: UserSettings, var: user_settings}, {name: ApplicationSettings, var: application_settings}, {name: AccessEndpoints, var: access_endpoints}, {name: EmbedHostDomains, var: embed_host_domains}, {name: StreamingExperienceSettings, var: streaming_experience_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, display_name: $display_name, description: $description, name: $name, storage_connectors: $storage_connectors, delete_storage_connectors: $delete_storage_connectors, redirect_url: $redirect_url, feedback_url: $feedback_url, attributes_to_delete: $attributes_to_delete, user_settings: $user_settings, application_settings: $application_settings, access_endpoints: $access_endpoints, embed_host_domains: $embed_host_domains, streaming_experience_settings: $streaming_experience_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
