# Auto-generated client for AWS Service Catalog v2015-12-10
# Source: https://api.apis.guru/v2/specs/amazonaws.com/servicecatalog/2015-12-10/openapi.json
# Auth: --token flag or $env.AWS_SERVICE_CATALOG_TOKEN

const CLIENT = {
  base_url: "http://servicecatalog.us-east-1.amazonaws.com"
  token_env_var: "AWS_SERVICE_CATALOG_TOKEN"
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

def base-url-completer [] { ["http://servicecatalog.us-east-1.amazonaws.com" "http://servicecatalog.us-east-2.amazonaws.com" "http://servicecatalog.us-west-1.amazonaws.com" "http://servicecatalog.us-west-2.amazonaws.com" "http://servicecatalog.us-gov-west-1.amazonaws.com" "http://servicecatalog.us-gov-east-1.amazonaws.com" "http://servicecatalog.ca-central-1.amazonaws.com" "http://servicecatalog.eu-north-1.amazonaws.com" "http://servicecatalog.eu-west-1.amazonaws.com" "http://servicecatalog.eu-west-2.amazonaws.com" "http://servicecatalog.eu-west-3.amazonaws.com" "http://servicecatalog.eu-central-1.amazonaws.com" "http://servicecatalog.eu-south-1.amazonaws.com" "http://servicecatalog.af-south-1.amazonaws.com" "http://servicecatalog.ap-northeast-1.amazonaws.com" "http://servicecatalog.ap-northeast-2.amazonaws.com" "http://servicecatalog.ap-northeast-3.amazonaws.com" "http://servicecatalog.ap-southeast-1.amazonaws.com" "http://servicecatalog.ap-southeast-2.amazonaws.com" "http://servicecatalog.ap-east-1.amazonaws.com" "http://servicecatalog.ap-south-1.amazonaws.com" "http://servicecatalog.sa-east-1.amazonaws.com" "http://servicecatalog.me-south-1.amazonaws.com" "https://servicecatalog.us-east-1.amazonaws.com" "https://servicecatalog.us-east-2.amazonaws.com" "https://servicecatalog.us-west-1.amazonaws.com" "https://servicecatalog.us-west-2.amazonaws.com" "https://servicecatalog.us-gov-west-1.amazonaws.com" "https://servicecatalog.us-gov-east-1.amazonaws.com" "https://servicecatalog.ca-central-1.amazonaws.com" "https://servicecatalog.eu-north-1.amazonaws.com" "https://servicecatalog.eu-west-1.amazonaws.com" "https://servicecatalog.eu-west-2.amazonaws.com" "https://servicecatalog.eu-west-3.amazonaws.com" "https://servicecatalog.eu-central-1.amazonaws.com" "https://servicecatalog.eu-south-1.amazonaws.com" "https://servicecatalog.af-south-1.amazonaws.com" "https://servicecatalog.ap-northeast-1.amazonaws.com" "https://servicecatalog.ap-northeast-2.amazonaws.com" "https://servicecatalog.ap-northeast-3.amazonaws.com" "https://servicecatalog.ap-southeast-1.amazonaws.com" "https://servicecatalog.ap-southeast-2.amazonaws.com" "https://servicecatalog.ap-east-1.amazonaws.com" "https://servicecatalog.ap-south-1.amazonaws.com" "https://servicecatalog.sa-east-1.amazonaws.com" "https://servicecatalog.me-south-1.amazonaws.com" "http://servicecatalog.cn-north-1.amazonaws.com.cn" "http://servicecatalog.cn-northwest-1.amazonaws.com.cn" "https://servicecatalog.cn-north-1.amazonaws.com.cn" "https://servicecatalog.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def portfolio-share-type-completer [] { ["AWS_ORGANIZATIONS" "AWS_SERVICECATALOG" "IMPORTED"] }
def x-amz-target-completer [] { ["AWS242ServiceCatalogService.AcceptPortfolioShare"] }
def x-amz-target-completer-1 [] { ["AWS242ServiceCatalogService.AssociateBudgetWithResource"] }
def principal-type-completer [] { ["IAM" "IAM_PATTERN"] }
def x-amz-target-completer-2 [] { ["AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio"] }
def x-amz-target-completer-3 [] { ["AWS242ServiceCatalogService.AssociateProductWithPortfolio"] }
def x-amz-target-completer-4 [] { ["AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact"] }
def x-amz-target-completer-5 [] { ["AWS242ServiceCatalogService.AssociateTagOptionWithResource"] }
def x-amz-target-completer-6 [] { ["AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact"] }
def x-amz-target-completer-7 [] { ["AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact"] }
def x-amz-target-completer-8 [] { ["AWS242ServiceCatalogService.CopyProduct"] }
def x-amz-target-completer-9 [] { ["AWS242ServiceCatalogService.CreateConstraint"] }
def x-amz-target-completer-10 [] { ["AWS242ServiceCatalogService.CreatePortfolio"] }
def x-amz-target-completer-11 [] { ["AWS242ServiceCatalogService.CreatePortfolioShare"] }
def product-type-completer [] { ["CLOUD_FORMATION_TEMPLATE" "MARKETPLACE" "TERRAFORM_OPEN_SOURCE"] }
def x-amz-target-completer-12 [] { ["AWS242ServiceCatalogService.CreateProduct"] }
def plan-type-completer [] { ["CLOUDFORMATION"] }
def x-amz-target-completer-13 [] { ["AWS242ServiceCatalogService.CreateProvisionedProductPlan"] }
def x-amz-target-completer-14 [] { ["AWS242ServiceCatalogService.CreateProvisioningArtifact"] }
def definition-type-completer [] { ["SSM_AUTOMATION"] }
def x-amz-target-completer-15 [] { ["AWS242ServiceCatalogService.CreateServiceAction"] }
def x-amz-target-completer-16 [] { ["AWS242ServiceCatalogService.CreateTagOption"] }
def x-amz-target-completer-17 [] { ["AWS242ServiceCatalogService.DeleteConstraint"] }
def x-amz-target-completer-18 [] { ["AWS242ServiceCatalogService.DeletePortfolio"] }
def x-amz-target-completer-19 [] { ["AWS242ServiceCatalogService.DeletePortfolioShare"] }
def x-amz-target-completer-20 [] { ["AWS242ServiceCatalogService.DeleteProduct"] }
def x-amz-target-completer-21 [] { ["AWS242ServiceCatalogService.DeleteProvisionedProductPlan"] }
def x-amz-target-completer-22 [] { ["AWS242ServiceCatalogService.DeleteProvisioningArtifact"] }
def x-amz-target-completer-23 [] { ["AWS242ServiceCatalogService.DeleteServiceAction"] }
def x-amz-target-completer-24 [] { ["AWS242ServiceCatalogService.DeleteTagOption"] }
def x-amz-target-completer-25 [] { ["AWS242ServiceCatalogService.DescribeConstraint"] }
def x-amz-target-completer-26 [] { ["AWS242ServiceCatalogService.DescribeCopyProductStatus"] }
def x-amz-target-completer-27 [] { ["AWS242ServiceCatalogService.DescribePortfolio"] }
def x-amz-target-completer-28 [] { ["AWS242ServiceCatalogService.DescribePortfolioShareStatus"] }
def type-completer [] { ["ACCOUNT" "ORGANIZATION" "ORGANIZATIONAL_UNIT" "ORGANIZATION_MEMBER_ACCOUNT"] }
def x-amz-target-completer-29 [] { ["AWS242ServiceCatalogService.DescribePortfolioShares"] }
def x-amz-target-completer-30 [] { ["AWS242ServiceCatalogService.DescribeProduct"] }
def x-amz-target-completer-31 [] { ["AWS242ServiceCatalogService.DescribeProductAsAdmin"] }
def x-amz-target-completer-32 [] { ["AWS242ServiceCatalogService.DescribeProductView"] }
def x-amz-target-completer-33 [] { ["AWS242ServiceCatalogService.DescribeProvisionedProduct"] }
def x-amz-target-completer-34 [] { ["AWS242ServiceCatalogService.DescribeProvisionedProductPlan"] }
def x-amz-target-completer-35 [] { ["AWS242ServiceCatalogService.DescribeProvisioningArtifact"] }
def x-amz-target-completer-36 [] { ["AWS242ServiceCatalogService.DescribeProvisioningParameters"] }
def x-amz-target-completer-37 [] { ["AWS242ServiceCatalogService.DescribeRecord"] }
def x-amz-target-completer-38 [] { ["AWS242ServiceCatalogService.DescribeServiceAction"] }
def x-amz-target-completer-39 [] { ["AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters"] }
def x-amz-target-completer-40 [] { ["AWS242ServiceCatalogService.DescribeTagOption"] }
def x-amz-target-completer-41 [] { ["AWS242ServiceCatalogService.DisableAWSOrganizationsAccess"] }
def x-amz-target-completer-42 [] { ["AWS242ServiceCatalogService.DisassociateBudgetFromResource"] }
def x-amz-target-completer-43 [] { ["AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio"] }
def x-amz-target-completer-44 [] { ["AWS242ServiceCatalogService.DisassociateProductFromPortfolio"] }
def x-amz-target-completer-45 [] { ["AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact"] }
def x-amz-target-completer-46 [] { ["AWS242ServiceCatalogService.DisassociateTagOptionFromResource"] }
def x-amz-target-completer-47 [] { ["AWS242ServiceCatalogService.EnableAWSOrganizationsAccess"] }
def x-amz-target-completer-48 [] { ["AWS242ServiceCatalogService.ExecuteProvisionedProductPlan"] }
def x-amz-target-completer-49 [] { ["AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction"] }
def x-amz-target-completer-50 [] { ["AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus"] }
def x-amz-target-completer-51 [] { ["AWS242ServiceCatalogService.GetProvisionedProductOutputs"] }
def x-amz-target-completer-52 [] { ["AWS242ServiceCatalogService.ImportAsProvisionedProduct"] }
def x-amz-target-completer-53 [] { ["AWS242ServiceCatalogService.ListAcceptedPortfolioShares"] }
def x-amz-target-completer-54 [] { ["AWS242ServiceCatalogService.ListBudgetsForResource"] }
def x-amz-target-completer-55 [] { ["AWS242ServiceCatalogService.ListConstraintsForPortfolio"] }
def x-amz-target-completer-56 [] { ["AWS242ServiceCatalogService.ListLaunchPaths"] }
def organization-node-type-completer [] { ["ACCOUNT" "ORGANIZATION" "ORGANIZATIONAL_UNIT"] }
def x-amz-target-completer-57 [] { ["AWS242ServiceCatalogService.ListOrganizationPortfolioAccess"] }
def x-amz-target-completer-58 [] { ["AWS242ServiceCatalogService.ListPortfolioAccess"] }
def x-amz-target-completer-59 [] { ["AWS242ServiceCatalogService.ListPortfolios"] }
def x-amz-target-completer-60 [] { ["AWS242ServiceCatalogService.ListPortfoliosForProduct"] }
def x-amz-target-completer-61 [] { ["AWS242ServiceCatalogService.ListPrincipalsForPortfolio"] }
def x-amz-target-completer-62 [] { ["AWS242ServiceCatalogService.ListProvisionedProductPlans"] }
def x-amz-target-completer-63 [] { ["AWS242ServiceCatalogService.ListProvisioningArtifacts"] }
def x-amz-target-completer-64 [] { ["AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction"] }
def x-amz-target-completer-65 [] { ["AWS242ServiceCatalogService.ListRecordHistory"] }
def x-amz-target-completer-66 [] { ["AWS242ServiceCatalogService.ListResourcesForTagOption"] }
def x-amz-target-completer-67 [] { ["AWS242ServiceCatalogService.ListServiceActions"] }
def x-amz-target-completer-68 [] { ["AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact"] }
def x-amz-target-completer-69 [] { ["AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct"] }
def x-amz-target-completer-70 [] { ["AWS242ServiceCatalogService.ListTagOptions"] }
def status-completer [] { ["FAILED" "SUCCEEDED"] }
def x-amz-target-completer-71 [] { ["AWS242ServiceCatalogService.NotifyProvisionProductEngineWorkflowResult"] }
def x-amz-target-completer-72 [] { ["AWS242ServiceCatalogService.NotifyTerminateProvisionedProductEngineWorkflowResult"] }
def x-amz-target-completer-73 [] { ["AWS242ServiceCatalogService.NotifyUpdateProvisionedProductEngineWorkflowResult"] }
def x-amz-target-completer-74 [] { ["AWS242ServiceCatalogService.ProvisionProduct"] }
def x-amz-target-completer-75 [] { ["AWS242ServiceCatalogService.RejectPortfolioShare"] }
def x-amz-target-completer-76 [] { ["AWS242ServiceCatalogService.ScanProvisionedProducts"] }
def sort-by-completer [] { ["CreationDate" "Title" "VersionCount"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }
def x-amz-target-completer-77 [] { ["AWS242ServiceCatalogService.SearchProducts"] }
def product-source-completer [] { ["ACCOUNT"] }
def x-amz-target-completer-78 [] { ["AWS242ServiceCatalogService.SearchProductsAsAdmin"] }
def x-amz-target-completer-79 [] { ["AWS242ServiceCatalogService.SearchProvisionedProducts"] }
def x-amz-target-completer-80 [] { ["AWS242ServiceCatalogService.TerminateProvisionedProduct"] }
def x-amz-target-completer-81 [] { ["AWS242ServiceCatalogService.UpdateConstraint"] }
def x-amz-target-completer-82 [] { ["AWS242ServiceCatalogService.UpdatePortfolio"] }
def x-amz-target-completer-83 [] { ["AWS242ServiceCatalogService.UpdatePortfolioShare"] }
def x-amz-target-completer-84 [] { ["AWS242ServiceCatalogService.UpdateProduct"] }
def x-amz-target-completer-85 [] { ["AWS242ServiceCatalogService.UpdateProvisionedProduct"] }
def x-amz-target-completer-86 [] { ["AWS242ServiceCatalogService.UpdateProvisionedProductProperties"] }
def guidance-completer [] { ["DEFAULT" "DEPRECATED"] }
def x-amz-target-completer-87 [] { ["AWS242ServiceCatalogService.UpdateProvisioningArtifact"] }
def x-amz-target-completer-88 [] { ["AWS242ServiceCatalogService.UpdateServiceAction"] }
def x-amz-target-completer-89 [] { ["AWS242ServiceCatalogService.UpdateTagOption"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    accept-portfolio-share: "record"
    associate-budget-with-resource: "record"
    associate-principal-with-portfolio: "record"
    associate-product-with-portfolio: "record"
    associate-service-action-with-provisioning-artifact: "record"
    associate-tag-option-with-resource: "record"
    batch-associate-service-action-with-provisioning-artifact: "record<FailedServiceActionAssociations: table<ServiceActionId: string, ProductId: string, ProvisioningArtifactId: string, ErrorCode: string, ErrorMessage: string>>"
    batch-disassociate-service-action-from-provisioning-artifact: "record<FailedServiceActionAssociations: table<ServiceActionId: string, ProductId: string, ProvisioningArtifactId: string, ErrorCode: string, ErrorMessage: string>>"
    copy-product: "record<CopyProductToken: string>"
    create-constraint: "record<ConstraintDetail: record<ConstraintId: string, Type: string, Description: string, Owner: string, ProductId: string, PortfolioId: string>, ConstraintParameters: string, Status: string>"
    create-portfolio: "record<PortfolioDetail: record<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, Tags: table<Key: string, Value: string>>"
    create-portfolio-share: "record<PortfolioShareToken: string>"
    create-product: "record<ProductViewDetail: record<ProductViewSummary: record<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, Status: string, ProductARN: string, CreatedTime: string, SourceConnection: record<Type: string, ConnectionParameters: record, LastSync: record>>, ProvisioningArtifactDetail: record<Id: string, Name: string, Description: string, Type: string, CreatedTime: string, Active: bool, Guidance: string, SourceRevision: string>, Tags: table<Key: string, Value: string>>"
    create-provisioned-product-plan: "record<PlanName: string, PlanId: string, ProvisionProductId: string, ProvisionedProductName: string, ProvisioningArtifactId: string>"
    create-provisioning-artifact: "record<ProvisioningArtifactDetail: record<Id: string, Name: string, Description: string, Type: string, CreatedTime: string, Active: bool, Guidance: string, SourceRevision: string>, Info: record, Status: string>"
    create-service-action: "record<ServiceActionDetail: record<ServiceActionSummary: record<Id: string, Name: string, Description: string, DefinitionType: string>, Definition: record>>"
    create-tag-option: "record<TagOptionDetail: record<Key: string, Value: string, Active: bool, Id: string, Owner: string>>"
    delete-constraint: "record"
    delete-portfolio: "record"
    delete-portfolio-share: "record<PortfolioShareToken: string>"
    delete-product: "record"
    delete-provisioned-product-plan: "record"
    delete-provisioning-artifact: "record"
    delete-service-action: "record"
    delete-tag-option: "record"
    describe-constraint: "record<ConstraintDetail: record<ConstraintId: string, Type: string, Description: string, Owner: string, ProductId: string, PortfolioId: string>, ConstraintParameters: string, Status: string>"
    describe-copy-product-status: "record<CopyProductStatus: string, TargetProductId: string, StatusDetail: string>"
    describe-portfolio: "record<PortfolioDetail: record<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, Tags: table<Key: string, Value: string>, TagOptions: table<Key: string, Value: string, Active: bool, Id: string, Owner: string>, Budgets: table<BudgetName: string>>"
    describe-portfolio-share-status: "record<PortfolioShareToken: string, PortfolioId: string, OrganizationNodeValue: string, Status: string, ShareDetails: record<SuccessfulShares: list<string>, ShareErrors: list<record>>>"
    describe-portfolio-shares: "record<NextPageToken: string, PortfolioShareDetails: table<PrincipalId: string, Type: string, Accepted: bool, ShareTagOptions: bool, SharePrincipals: bool>>"
    describe-product: "record<ProductViewSummary: record<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, ProvisioningArtifacts: table<Id: string, Name: string, Description: string, CreatedTime: string, Guidance: string>, Budgets: table<BudgetName: string>, LaunchPaths: table<Id: string, Name: string>>"
    describe-product-as-admin: "record<ProductViewDetail: record<ProductViewSummary: record<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, Status: string, ProductARN: string, CreatedTime: string, SourceConnection: record<Type: string, ConnectionParameters: record, LastSync: record>>, ProvisioningArtifactSummaries: table<Id: string, Name: string, Description: string, CreatedTime: string, ProvisioningArtifactMetadata: record>, Tags: table<Key: string, Value: string>, TagOptions: table<Key: string, Value: string, Active: bool, Id: string, Owner: string>, Budgets: table<BudgetName: string>>"
    describe-product-view: "record<ProductViewSummary: record<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, ProvisioningArtifacts: table<Id: string, Name: string, Description: string, CreatedTime: string, Guidance: string>>"
    describe-provisioned-product: "record<ProvisionedProductDetail: record<Name: string, Arn: string, Type: string, Id: string, Status: string, StatusMessage: string, CreatedTime: string, IdempotencyToken: string, LastRecordId: string, LastProvisioningRecordId: string, LastSuccessfulProvisioningRecordId: string, ProductId: string, ProvisioningArtifactId: string, LaunchRoleArn: string>, CloudWatchDashboards: table<Name: string>>"
    describe-provisioned-product-plan: "record<ProvisionedProductPlanDetails: record<CreatedTime: string, PathId: string, ProductId: string, PlanName: string, PlanId: string, ProvisionProductId: string, ProvisionProductName: string, PlanType: string, ProvisioningArtifactId: string, Status: string, UpdatedTime: string, NotificationArns: list<string>, ProvisioningParameters: list<record>, Tags: list<record>, StatusMessage: string>, ResourceChanges: table<Action: string, LogicalResourceId: string, PhysicalResourceId: string, ResourceType: string, Replacement: string, Scope: list, Details: list>, NextPageToken: string>"
    describe-provisioning-artifact: "record<ProvisioningArtifactDetail: record<Id: string, Name: string, Description: string, Type: string, CreatedTime: string, Active: bool, Guidance: string, SourceRevision: string>, Info: record, Status: string>"
    describe-provisioning-parameters: "record<ProvisioningArtifactParameters: table<ParameterKey: string, DefaultValue: string, ParameterType: string, IsNoEcho: bool, Description: string, ParameterConstraints: record>, ConstraintSummaries: table<Type: string, Description: string>, UsageInstructions: table<Type: string, Value: string>, TagOptions: table<Key: string, Values: list>, ProvisioningArtifactPreferences: record<StackSetAccounts: list<string>, StackSetRegions: list<string>>, ProvisioningArtifactOutputs: table<Key: string, Description: string>, ProvisioningArtifactOutputKeys: table<Key: string, Description: string>>"
    describe-record: "record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>, RecordOutputs: table<OutputKey: string, OutputValue: string, Description: string>, NextPageToken: string>"
    describe-service-action: "record<ServiceActionDetail: record<ServiceActionSummary: record<Id: string, Name: string, Description: string, DefinitionType: string>, Definition: record>>"
    describe-service-action-execution-parameters: "record<ServiceActionParameters: table<Name: string, Type: string, DefaultValues: list>>"
    describe-tag-option: "record<TagOptionDetail: record<Key: string, Value: string, Active: bool, Id: string, Owner: string>>"
    disable-aws-organizations-access: "record"
    disassociate-budget-from-resource: "record"
    disassociate-principal-from-portfolio: "record"
    disassociate-product-from-portfolio: "record"
    disassociate-service-action-from-provisioning-artifact: "record"
    disassociate-tag-option-from-resource: "record"
    enable-aws-organizations-access: "record"
    execute-provisioned-product-plan: "record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>"
    execute-provisioned-product-service-action: "record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>"
    get-aws-organizations-access-status: "record<AccessStatus: string>"
    get-provisioned-product-outputs: "record<Outputs: table<OutputKey: string, OutputValue: string, Description: string>, NextPageToken: string>"
    import-as-provisioned-product: "record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>"
    list-accepted-portfolio-shares: "record<PortfolioDetails: table<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, NextPageToken: string>"
    list-budgets-for-resource: "record<Budgets: table<BudgetName: string>, NextPageToken: string>"
    list-constraints-for-portfolio: "record<ConstraintDetails: table<ConstraintId: string, Type: string, Description: string, Owner: string, ProductId: string, PortfolioId: string>, NextPageToken: string>"
    list-launch-paths: "record<LaunchPathSummaries: table<Id: string, ConstraintSummaries: list, Tags: list, Name: string>, NextPageToken: string>"
    list-organization-portfolio-access: "record<OrganizationNodes: table<Type: string, Value: string>, NextPageToken: string>"
    list-portfolio-access: "record<AccountIds: list<string>, NextPageToken: string>"
    list-portfolios: "record<PortfolioDetails: table<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, NextPageToken: string>"
    list-portfolios-for-product: "record<PortfolioDetails: table<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, NextPageToken: string>"
    list-principals-for-portfolio: "record<Principals: table<PrincipalARN: string, PrincipalType: string>, NextPageToken: string>"
    list-provisioned-product-plans: "record<ProvisionedProductPlans: table<PlanName: string, PlanId: string, ProvisionProductId: string, ProvisionProductName: string, PlanType: string, ProvisioningArtifactId: string>, NextPageToken: string>"
    list-provisioning-artifacts: "record<ProvisioningArtifactDetails: table<Id: string, Name: string, Description: string, Type: string, CreatedTime: string, Active: bool, Guidance: string, SourceRevision: string>, NextPageToken: string>"
    list-provisioning-artifacts-for-service-action: "record<ProvisioningArtifactViews: table<ProductViewSummary: record, ProvisioningArtifact: record>, NextPageToken: string>"
    list-record-history: "record<RecordDetails: table<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list, RecordTags: list, LaunchRoleArn: string>, NextPageToken: string>"
    list-resources-for-tag-option: "record<ResourceDetails: table<Id: string, ARN: string, Name: string, Description: string, CreatedTime: string>, PageToken: string>"
    list-service-actions: "record<ServiceActionSummaries: table<Id: string, Name: string, Description: string, DefinitionType: string>, NextPageToken: string>"
    list-service-actions-for-provisioning-artifact: "record<ServiceActionSummaries: table<Id: string, Name: string, Description: string, DefinitionType: string>, NextPageToken: string>"
    list-stack-instances-for-provisioned-product: "record<StackInstances: table<Account: string, Region: string, StackInstanceStatus: string>, NextPageToken: string>"
    list-tag-options: "record<TagOptionDetails: table<Key: string, Value: string, Active: bool, Id: string, Owner: string>, PageToken: string>"
    notify-provision-product-engine-workflow-result: "record"
    notify-terminate-provisioned-product-engine-workflow-result: "record"
    notify-update-provisioned-product-engine-workflow-result: "record"
    provision-product: "record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>"
    reject-portfolio-share: "record"
    scan-provisioned-products: "record<ProvisionedProducts: table<Name: string, Arn: string, Type: string, Id: string, Status: string, StatusMessage: string, CreatedTime: string, IdempotencyToken: string, LastRecordId: string, LastProvisioningRecordId: string, LastSuccessfulProvisioningRecordId: string, ProductId: string, ProvisioningArtifactId: string, LaunchRoleArn: string>, NextPageToken: string>"
    search-products: "record<ProductViewSummaries: table<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, ProductViewAggregations: record, NextPageToken: string>"
    search-products-as-admin: "record<ProductViewDetails: table<ProductViewSummary: record, Status: string, ProductARN: string, CreatedTime: string, SourceConnection: record>, NextPageToken: string>"
    search-provisioned-products: "record<ProvisionedProducts: table<Name: string, Arn: string, Type: string, Id: string, Status: string, StatusMessage: string, CreatedTime: string, IdempotencyToken: string, LastRecordId: string, LastProvisioningRecordId: string, LastSuccessfulProvisioningRecordId: string, Tags: list, PhysicalId: string, ProductId: string, ProductName: string, ProvisioningArtifactId: string, ProvisioningArtifactName: string, UserArn: string, UserArnSession: string>, TotalResultsCount: int, NextPageToken: string>"
    terminate-provisioned-product: "record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>"
    update-constraint: "record<ConstraintDetail: record<ConstraintId: string, Type: string, Description: string, Owner: string, ProductId: string, PortfolioId: string>, ConstraintParameters: string, Status: string>"
    update-portfolio: "record<PortfolioDetail: record<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, Tags: table<Key: string, Value: string>>"
    update-portfolio-share: "record<PortfolioShareToken: string, Status: string>"
    update-product: "record<ProductViewDetail: record<ProductViewSummary: record<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, Status: string, ProductARN: string, CreatedTime: string, SourceConnection: record<Type: string, ConnectionParameters: record, LastSync: record>>, Tags: table<Key: string, Value: string>>"
    update-provisioned-product: "record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>"
    update-provisioned-product-properties: "record<ProvisionedProductId: string, ProvisionedProductProperties: record, RecordId: string, Status: string>"
    update-provisioning-artifact: "record<ProvisioningArtifactDetail: record<Id: string, Name: string, Description: string, Type: string, CreatedTime: string, Active: bool, Guidance: string, SourceRevision: string>, Info: record, Status: string>"
    update-service-action: "record<ServiceActionDetail: record<ServiceActionSummary: record<Id: string, Name: string, Description: string, DefinitionType: string>, Definition: record>>"
    update-tag-option: "record<TagOptionDetail: record<Key: string, Value: string, Active: bool, Id: string, Owner: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accept-portfolio-share" "associate-budget-with-resource" "associate-principal-with-portfolio" "associate-product-with-portfolio" "associate-service-action-with-provisioning-artifact" "associate-tag-option-with-resource" "batch-associate-service-action-with-provisioning-artifact" "batch-disassociate-service-action-from-provisioning-artifact" "copy-product" "create-constraint" "create-portfolio" "create-portfolio-share" "create-product" "create-provisioned-product-plan" "create-provisioning-artifact" "create-service-action" "create-tag-option" "delete-constraint" "delete-portfolio" "delete-portfolio-share" "delete-product" "delete-provisioned-product-plan" "delete-provisioning-artifact" "delete-service-action" "delete-tag-option" "describe-constraint" "describe-copy-product-status" "describe-portfolio" "describe-portfolio-share-status" "describe-portfolio-shares" "describe-product" "describe-product-as-admin" "describe-product-view" "describe-provisioned-product" "describe-provisioned-product-plan" "describe-provisioning-artifact" "describe-provisioning-parameters" "describe-record" "describe-service-action" "describe-service-action-execution-parameters" "describe-tag-option" "disable-aws-organizations-access" "disassociate-budget-from-resource" "disassociate-principal-from-portfolio" "disassociate-product-from-portfolio" "disassociate-service-action-from-provisioning-artifact" "disassociate-tag-option-from-resource" "enable-aws-organizations-access" "execute-provisioned-product-plan" "execute-provisioned-product-service-action" "get-aws-organizations-access-status" "get-provisioned-product-outputs" "import-as-provisioned-product" "list-accepted-portfolio-shares" "list-budgets-for-resource" "list-constraints-for-portfolio" "list-launch-paths" "list-organization-portfolio-access" "list-portfolio-access" "list-portfolios" "list-portfolios-for-product" "list-principals-for-portfolio" "list-provisioned-product-plans" "list-provisioning-artifacts" "list-provisioning-artifacts-for-service-action" "list-record-history" "list-resources-for-tag-option" "list-service-actions" "list-service-actions-for-provisioning-artifact" "list-stack-instances-for-provisioned-product" "list-tag-options" "notify-provision-product-engine-workflow-result" "notify-terminate-provisioned-product-engine-workflow-result" "notify-update-provisioned-product-engine-workflow-result" "provision-product" "reject-portfolio-share" "scan-provisioned-products" "search-products" "search-products-as-admin" "search-provisioned-products" "terminate-provisioned-product" "update-constraint" "update-portfolio" "update-portfolio-share" "update-product" "update-provisioned-product" "update-provisioned-product-properties" "update-provisioning-artifact" "update-service-action" "update-tag-option" "commands"] | sort) } | get name | first)
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

# Accepts an offer to share the specified portfolio.
#
# POST /
# Returns: record
# operationId: AcceptPortfolioShare
export def "accept-portfolio-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  --portfolio-share-type: string@portfolio-share-type-completer # The type of shared portfolios to accept. The default is to accept imported portfolios. AWS_ORGANIZATIONS - Accept portfolios shared by the management account of your organization. IMPORTED - Accept imported portfolios. AWS_SERVICECATALOG - Not supported. (Throws ResourceNotFoundException.) For example, aws servicecatalog accept-portfolio-share --portfolio-id "port-2qwzkwxt3y5fk" --portfolio-share-type AWS_ORGANIZATIONS
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.AcceptPortfolioShare"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PortfolioId, var: portfolio_id}, {name: PortfolioShareType, var: portfolio_share_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, portfolio_id: $portfolio_id, portfolio_share_type: $portfolio_share_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates the specified budget with the specified resource.
#
# POST /
# Returns: record
# operationId: AssociateBudgetWithResource
export def "associate-budget-with-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  budget_name: string # The name of the budget you want to associate.
  resource_id: string # The resource identifier. Either a portfolio-id or a product-id.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.AssociateBudgetWithResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BudgetName, var: budget_name}, {name: ResourceId, var: resource_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, budget_name: $budget_name, resource_id: $resource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates the specified principal ARN with the specified portfolio. If you share the portfolio with principal name sharing enabled, the PrincipalARN association is included in the share. The PortfolioID, PrincipalARN, and PrincipalType parameters are required. You can associate a maximum of 10 Principals with a portfolio using PrincipalType as IAM_PATTERN When you associate a principal with portfolio, a potential privilege escalation path may occur when that portfolio is then shared with other accounts. For a user in a recipient account who is not an Service Catalog Admin, but still has the ability to create Principals (Users/Groups/Roles), that user could create a role that matches a principal name association for the portfolio. Although this user may not know which principal names are associated through Service Catalog, they may be able to guess the user. If this potential escalation path is a concern, then Service Catalog recommends using PrincipalType as IAM. With this configuration, the PrincipalARN must already exist in the recipient account before it can be associated.
#
# POST /
# Returns: record
# operationId: AssociatePrincipalWithPortfolio
export def "associate-principal-with-portfolio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  principal_arn: string # The ARN of the principal (user, role, or group). This field allows an ARN with no accountID if PrincipalType is IAM_PATTERN. You can associate multiple IAM patterns even if the account has no principal with that name. This is useful in Principal Name Sharing if you want to share a principal without creating it in the account that owns the portfolio.
  principal_type: string@principal-type-completer # The principal type. The supported value is IAM if you use a fully defined ARN, or IAM_PATTERN if you use an ARN with no accountID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PortfolioId, var: portfolio_id}, {name: PrincipalARN, var: principal_arn}, {name: PrincipalType, var: principal_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, portfolio_id: $portfolio_id, principal_arn: $principal_arn, principal_type: $principal_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates the specified product with the specified portfolio. A delegated admin is authorized to invoke this command.
#
# POST /
# Returns: record
# operationId: AssociateProductWithPortfolio
export def "associate-product-with-portfolio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
  portfolio_id: string # The portfolio identifier.
  --source-portfolio-id: string # The identifier of the source portfolio.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.AssociateProductWithPortfolio"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ProductId, var: product_id}, {name: PortfolioId, var: portfolio_id}, {name: SourcePortfolioId, var: source_portfolio_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, product_id: $product_id, portfolio_id: $portfolio_id, source_portfolio_id: $source_portfolio_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a self-service action with a provisioning artifact.
#
# POST /
# Returns: record
# operationId: AssociateServiceActionWithProvisioningArtifact
export def "associate-service-action-with-provisioning-artifact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  product_id: string # The product identifier. For example, prod-abcdzk7xy33qa.
  provisioning_artifact_id: string # The identifier of the provisioning artifact. For example, pa-4abcdjnxjj6ne.
  service_action_id: string # The self-service action identifier. For example, act-fs7abcd89wxyz.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ProductId, var: product_id}, {name: ProvisioningArtifactId, var: provisioning_artifact_id}, {name: ServiceActionId, var: service_action_id}, {name: AcceptLanguage, var: accept_language}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, product_id: $product_id, provisioning_artifact_id: $provisioning_artifact_id, service_action_id: $service_action_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate the specified TagOption with the specified portfolio or product.
#
# POST /
# Returns: record
# operationId: AssociateTagOptionWithResource
export def "associate-tag-option-with-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_id: string # The resource identifier.
  tag_option_id: string # The TagOption identifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.AssociateTagOptionWithResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}, {name: TagOptionId, var: tag_option_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id, tag_option_id: $tag_option_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates multiple self-service actions with provisioning artifacts.
#
# POST /
# Returns: record<FailedServiceActionAssociations: table<ServiceActionId: string, ProductId: string, ProvisioningArtifactId: string, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchAssociateServiceActionWithProvisioningArtifact
export def "batch-associate-service-action-with-provisioning-artifact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  service_action_associations: list # One or more associations, each consisting of the Action ID, the Product ID, and the Provisioning Artifact ID. — item shape: {ServiceActionId: string, ProductId: string, ProvisioningArtifactId: string}
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceActionAssociations, var: service_action_associations}, {name: AcceptLanguage, var: accept_language}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_action_associations: $service_action_associations, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a batch of self-service actions from the specified provisioning artifact.
#
# POST /
# Returns: record<FailedServiceActionAssociations: table<ServiceActionId: string, ProductId: string, ProvisioningArtifactId: string, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchDisassociateServiceActionFromProvisioningArtifact
export def "batch-disassociate-service-action-from-provisioning-artifact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  service_action_associations: list # One or more associations, each consisting of the Action ID, the Product ID, and the Provisioning Artifact ID. — item shape: {ServiceActionId: string, ProductId: string, ProvisioningArtifactId: string}
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceActionAssociations, var: service_action_associations}, {name: AcceptLanguage, var: accept_language}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_action_associations: $service_action_associations, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copies the specified source product to the specified target product or a new product. You can copy a product to the same account or another account. You can copy a product to the same Region or another Region. If you copy a product to another account, you must first share the product in a portfolio using CreatePortfolioShare. This operation is performed asynchronously. To track the progress of the operation, use DescribeCopyProductStatus.
#
# POST /
# Returns: record<CopyProductToken: string>
# operationId: CopyProduct
export def "copy-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  source_product_arn: string # The Amazon Resource Name (ARN) of the source product.
  --target-product-id: string # The identifier of the target product. By default, a new product is created.
  --target-product-name: string # A name for the target product. The default is the name of the source product.
  --source-provisioning-artifact-identifiers: list # The identifiers of the provisioning artifacts (also known as versions) of the product to copy. By default, all provisioning artifacts are copied.
  --copy-options: list<string> # The copy options. If the value is CopyTags, the tags from the source product are copied to the target product.
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.CopyProduct"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: SourceProductArn, var: source_product_arn}, {name: TargetProductId, var: target_product_id}, {name: TargetProductName, var: target_product_name}, {name: SourceProvisioningArtifactIdentifiers, var: source_provisioning_artifact_identifiers}, {name: CopyOptions, var: copy_options}, {name: IdempotencyToken, var: idempotency_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, source_product_arn: $source_product_arn, target_product_id: $target_product_id, target_product_name: $target_product_name, source_provisioning_artifact_identifiers: $source_provisioning_artifact_identifiers, copy_options: $copy_options, idempotency_token: $idempotency_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a constraint. A delegated admin is authorized to invoke this command.
#
# POST /
# Returns: record<ConstraintDetail: record<ConstraintId: string, Type: string, Description: string, Owner: string, ProductId: string, PortfolioId: string>, ConstraintParameters: string, Status: string>
# operationId: CreateConstraint
export def "create-constraint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  product_id: string # The product identifier.
  parameters: string # The constraint parameters, in JSON format. The syntax depends on the constraint type as follows: LAUNCH You are required to specify either the RoleArn or the LocalRoleName but can't use both. Specify the RoleArn property as follows: {"RoleArn" : "arn:aws:iam::123456789012:role/LaunchRole"} Specify the LocalRoleName property as follows: {"LocalRoleName": "SCBasicLaunchRole"} If you specify the LocalRoleName property, when an account uses the launch constraint, the IAM role with that name in the account will be used. This allows launch-role constraints to be account-agnostic so the administrator can create fewer resources per shared account. The given role name must exist in the account used to create the launch constraint and the account of the user who launches a product with this launch constraint. You cannot have both a LAUNCH and a STACKSET constraint. You also cannot have more than one LAUNCH constraint on a product and portfolio. NOTIFICATION Specify the NotificationArns property as follows: {"NotificationArns" : ["arn:aws:sns:us-east-1:123456789012:Topic"]} RESOURCE_UPDATE Specify the TagUpdatesOnProvisionedProduct property as follows: {"Version":"2.0","Properties":{"TagUpdateOnProvisionedProduct":"String"}} The TagUpdatesOnProvisionedProduct property accepts a string value of ALLOWED or NOT_ALLOWED. STACKSET Specify the Parameters property as follows: {"Version": "String", "Properties": {"AccountList": [ "String" ], "RegionList": [ "String" ], "AdminRole": "String", "ExecutionRole": "String"}} You cannot have both a LAUNCH and a STACKSET constraint. You also cannot have more than one STACKSET constraint on a product and portfolio. Products with a STACKSET constraint will launch an CloudFormation stack set. TEMPLATE Specify the Rules property. For more information, see Template Constraint Rules (http://docs.aws.amazon.com/servicecatalog/latest/adminguide/reference-template_constraint_rules.html).
  type: string # The type of constraint. LAUNCH NOTIFICATION RESOURCE_UPDATE STACKSET TEMPLATE
  --description: string # The description of the constraint.
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.CreateConstraint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PortfolioId, var: portfolio_id}, {name: ProductId, var: product_id}, {name: Parameters, var: parameters}, {name: Type, var: type}, {name: Description, var: description}, {name: IdempotencyToken, var: idempotency_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, portfolio_id: $portfolio_id, product_id: $product_id, parameters: $parameters, type: $type, description: $description, idempotency_token: $idempotency_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a portfolio. A delegated admin is authorized to invoke this command.
#
# POST /
# Returns: record<PortfolioDetail: record<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, Tags: table<Key: string, Value: string>>
# operationId: CreatePortfolio
export def "create-portfolio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  display_name: string # The name to use for display purposes.
  --description: string # The description of the portfolio.
  provider_name: string # The name of the portfolio provider.
  --tags: list # One or more tags. — item shape: {Key: string, Value: string}
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.CreatePortfolio"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: DisplayName, var: display_name}, {name: Description, var: description}, {name: ProviderName, var: provider_name}, {name: Tags, var: tags}, {name: IdempotencyToken, var: idempotency_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, display_name: $display_name, description: $description, provider_name: $provider_name, tags: $tags, idempotency_token: $idempotency_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the management account of an organization or by a delegated administrator. You can share portfolios to an organization, an organizational unit, or a specific account. Note that if a delegated admin is de-registered, they can no longer create portfolio shares. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node. You can't share a shared resource, including portfolios that contain a shared product. If the portfolio share with the specified account or organization node already exists, this action will have no effect and will not return an error. To update an existing share, you must use the UpdatePortfolioShare API instead. When you associate a principal with portfolio, a potential privilege escalation path may occur when that portfolio is then shared with other accounts. For a user in a recipient account who is not an Service Catalog Admin, but still has the ability to create Principals (Users/Groups/Roles), that user could create a role that matches a principal name association for the portfolio. Although this user may not know which principal names are associated through Service Catalog, they may be able to guess the user. If this potential escalation path is a concern, then Service Catalog recommends using PrincipalType as IAM. With this configuration, the PrincipalARN must already exist in the recipient account before it can be associated.
#
# POST /
# Returns: record<PortfolioShareToken: string>
# operationId: CreatePortfolioShare
export def "create-portfolio-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  --account-id: string # The Amazon Web Services account ID. For example, 123456789012.
  --organization-node: record # Information about the organization node. — shape: {Type?: "ORGANIZATION"|"ORGANIZATIONAL_UNIT"|"ACCOUNT", Value?: string}
  --share-tag-options: oneof<nothing, bool> # Enables or disables TagOptions sharing when creating the portfolio share. If this flag is not provided, TagOptions sharing is disabled.
  --share-principals: oneof<nothing, bool> # Enables or disables Principal sharing when creating the portfolio share. If this flag is not provided, principal sharing is disabled. When you enable Principal Name Sharing for a portfolio share, the share recipient account end users with a principal that matches any of the associated IAM patterns can provision products from the portfolio. Once shared, the share recipient can view associations of PrincipalType: IAM_PATTERN on their portfolio. You can create the principals in the recipient account before or after creating the share.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.CreatePortfolioShare"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PortfolioId, var: portfolio_id}, {name: AccountId, var: account_id}, {name: OrganizationNode, var: organization_node}, {name: ShareTagOptions, var: share_tag_options}, {name: SharePrincipals, var: share_principals}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, portfolio_id: $portfolio_id, account_id: $account_id, organization_node: $organization_node, share_tag_options: $share_tag_options, share_principals: $share_principals
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a product. A delegated admin is authorized to invoke this command. The user or role that performs this operation must have the cloudformation:GetTemplate IAM policy permission. This policy permission is required when using the ImportFromPhysicalId template source in the information data section.
#
# POST /
# Returns: record<ProductViewDetail: record<ProductViewSummary: record<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, Status: string, ProductARN: string, CreatedTime: string, SourceConnection: record<Type: string, ConnectionParameters: record, LastSync: record>>, ProvisioningArtifactDetail: record<Id: string, Name: string, Description: string, Type: string, CreatedTime: string, Active: bool, Guidance: string, SourceRevision: string>, Tags: table<Key: string, Value: string>>
# operationId: CreateProduct
export def "create-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  name: string # The name of the product.
  owner: string # The owner of the product.
  --description: string # The description of the product.
  --distributor: string # The distributor of the product.
  --support-description: string # The support information about the product.
  --support-email: string # The contact email for product support.
  --support-url: string # The contact URL for product support. ^https?:\/\// / is the pattern used to validate SupportUrl.
  product_type: string@product-type-completer # The type of product.
  --tags: list # One or more tags. — item shape: {Key: string, Value: string}
  --provisioning-artifact-parameters: record # Information about a provisioning artifact (also known as a version) for a product. — shape: {Name?: string, Description?: string, Info?: record, Type?: "CLOUD_FORMATION_TEMPLATE"|"MARKETPLACE_AMI"|"MARKETPLACE_CAR"|"TERRAFORM_OPEN_SOURCE", DisableTemplateValidation?: bool}
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
  --source-connection: record # A top level ProductViewDetail response containing details about the product’s connection. Service Catalog returns this field for the CreateProduct, UpdateProduct, DescribeProductAsAdmin, and SearchProductAsAdmin APIs. This response contains the same fields as the ConnectionParameters request, with the addition of the LastSync response. — shape: {Type?: "CODESTAR", ConnectionParameters: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.CreateProduct"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: Name, var: name}, {name: Owner, var: owner}, {name: Description, var: description}, {name: Distributor, var: distributor}, {name: SupportDescription, var: support_description}, {name: SupportEmail, var: support_email}, {name: SupportUrl, var: support_url}, {name: ProductType, var: product_type}, {name: Tags, var: tags}, {name: ProvisioningArtifactParameters, var: provisioning_artifact_parameters}, {name: IdempotencyToken, var: idempotency_token}, {name: SourceConnection, var: source_connection}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, name: $name, owner: $owner, description: $description, distributor: $distributor, support_description: $support_description, support_email: $support_email, support_url: $support_url, product_type: $product_type, tags: $tags, provisioning_artifact_parameters: $provisioning_artifact_parameters, idempotency_token: $idempotency_token, source_connection: $source_connection
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed. You can create one plan for each provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILABLE or TAINTED. To view the resource changes in the change set, use DescribeProvisionedProductPlan. To create or modify the provisioned product, use ExecuteProvisionedProductPlan.
#
# POST /
# Returns: record<PlanName: string, PlanId: string, ProvisionProductId: string, ProvisionedProductName: string, ProvisioningArtifactId: string>
# operationId: CreateProvisionedProductPlan
export def "create-provisioned-product-plan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  plan_name: string # The name of the plan.
  plan_type: string@plan-type-completer # The plan type.
  --notification-arns: list<string> # Passed to CloudFormation. The SNS topic ARNs to which to publish stack-related events.
  --path-id: string # The path identifier of the product. This value is optional if the product has a default path, and required if the product has more than one path. To list the paths for a product, use ListLaunchPaths.
  product_id: string # The product identifier.
  provisioned_product_name: string # A user-friendly name for the provisioned product. This value must be unique for the Amazon Web Services account and cannot be updated after the product is provisioned.
  provisioning_artifact_id: string # The identifier of the provisioning artifact.
  --provisioning-parameters: list # Parameters specified by the administrator that are required for provisioning the product. — item shape: {Key?: string, Value?: string, UsePreviousValue?: bool}
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
  --tags: list # One or more tags. If the plan is for an existing provisioned product, the product must have a RESOURCE_UPDATE constraint with TagUpdatesOnProvisionedProduct set to ALLOWED to allow tag updates. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.CreateProvisionedProductPlan"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PlanName, var: plan_name}, {name: PlanType, var: plan_type}, {name: NotificationArns, var: notification_arns}, {name: PathId, var: path_id}, {name: ProductId, var: product_id}, {name: ProvisionedProductName, var: provisioned_product_name}, {name: ProvisioningArtifactId, var: provisioning_artifact_id}, {name: ProvisioningParameters, var: provisioning_parameters}, {name: IdempotencyToken, var: idempotency_token}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, plan_name: $plan_name, plan_type: $plan_type, notification_arns: $notification_arns, path_id: $path_id, product_id: $product_id, provisioned_product_name: $provisioned_product_name, provisioning_artifact_id: $provisioning_artifact_id, provisioning_parameters: $provisioning_parameters, idempotency_token: $idempotency_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a provisioning artifact (also known as a version) for the specified product. You cannot create a provisioning artifact for a product that was shared with you. The user or role that performs this operation must have the cloudformation:GetTemplate IAM policy permission. This policy permission is required when using the ImportFromPhysicalId template source in the information data section.
#
# POST /
# Returns: record<ProvisioningArtifactDetail: record<Id: string, Name: string, Description: string, Type: string, CreatedTime: string, Active: bool, Guidance: string, SourceRevision: string>, Info: record, Status: string>
# operationId: CreateProvisioningArtifact
export def "create-provisioning-artifact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
  parameters: record # Information about a provisioning artifact (also known as a version) for a product. — shape: {Name?: string, Description?: string, Info?: record, Type?: "CLOUD_FORMATION_TEMPLATE"|"MARKETPLACE_AMI"|"MARKETPLACE_CAR"|"TERRAFORM_OPEN_SOURCE", DisableTemplateValidation?: bool}
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.CreateProvisioningArtifact"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ProductId, var: product_id}, {name: Parameters, var: parameters}, {name: IdempotencyToken, var: idempotency_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, product_id: $product_id, parameters: $parameters, idempotency_token: $idempotency_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a self-service action.
#
# POST /
# Returns: record<ServiceActionDetail: record<ServiceActionSummary: record<Id: string, Name: string, Description: string, DefinitionType: string>, Definition: record>>
# operationId: CreateServiceAction
export def "create-service-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The self-service action name.
  definition_type: string@definition-type-completer # The service action definition type. For example, SSM_AUTOMATION.
  definition: record # The self-service action definition. Can be one of the following: Name The name of the Amazon Web Services Systems Manager document (SSM document). For example, AWS-RestartEC2Instance. If you are using a shared SSM document, you must provide the ARN instead of the name. Version The Amazon Web Services Systems Manager automation document version. For example, "Version": "1" AssumeRole The Amazon Resource Name (ARN) of the role that performs the self-service actions on your behalf. For example, "AssumeRole": "arn:aws:iam::12345678910:role/ActionRole". To reuse the provisioned product launch role, set to "AssumeRole": "LAUNCH_ROLE". Parameters The list of parameters in JSON format. For example: [{\"Name\":\"InstanceId\",\"Type\":\"TARGET\"}] or [{\"Name\":\"InstanceId\",\"Type\":\"TEXT_VALUE\"}].
  --description: string # The self-service action description.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.CreateServiceAction"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: DefinitionType, var: definition_type}, {name: Definition, var: definition}, {name: Description, var: description}, {name: AcceptLanguage, var: accept_language}, {name: IdempotencyToken, var: idempotency_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, definition_type: $definition_type, definition: $definition, description: $description, accept_language: $accept_language, idempotency_token: $idempotency_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a TagOption.
#
# POST /
# Returns: record<TagOptionDetail: record<Key: string, Value: string, Active: bool, Id: string, Owner: string>>
# operationId: CreateTagOption
export def "create-tag-option" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  key: string # The TagOption key.
  value: string # The TagOption value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.CreateTagOption"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Key, var: key}, {name: Value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, key: $key, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified constraint. A delegated admin is authorized to invoke this command.
#
# POST /
# Returns: record
# operationId: DeleteConstraint
export def "delete-constraint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The identifier of the constraint.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DeleteConstraint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified portfolio. You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts. A delegated admin is authorized to invoke this command.
#
# POST /
# Returns: record
# operationId: DeletePortfolio
export def "delete-portfolio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The portfolio identifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DeletePortfolio"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the management account of an organization or by a delegated administrator. Note that if a delegated admin is de-registered, portfolio shares created from that account are removed.
#
# POST /
# Returns: record<PortfolioShareToken: string>
# operationId: DeletePortfolioShare
export def "delete-portfolio-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  --account-id: string # The Amazon Web Services account ID.
  --organization-node: record # Information about the organization node. — shape: {Type?: "ORGANIZATION"|"ORGANIZATIONAL_UNIT"|"ACCOUNT", Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DeletePortfolioShare"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PortfolioId, var: portfolio_id}, {name: AccountId, var: account_id}, {name: OrganizationNode, var: organization_node}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, portfolio_id: $portfolio_id, account_id: $account_id, organization_node: $organization_node
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified product. You cannot delete a product if it was shared with you or is associated with a portfolio. A delegated admin is authorized to invoke this command.
#
# POST /
# Returns: record
# operationId: DeleteProduct
export def "delete-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The product identifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DeleteProduct"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified plan.
#
# POST /
# Returns: record
# operationId: DeleteProvisionedProductPlan
export def "delete-provisioned-product-plan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  plan_id: string # The plan identifier.
  --ignore-errors: oneof<nothing, bool> # If set to true, Service Catalog stops managing the specified provisioned product even if it cannot delete the underlying resources.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DeleteProvisionedProductPlan"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PlanId, var: plan_id}, {name: IgnoreErrors, var: ignore_errors}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, plan_id: $plan_id, ignore_errors: $ignore_errors
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified provisioning artifact (also known as a version) for the specified product. You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.
#
# POST /
# Returns: record
# operationId: DeleteProvisioningArtifact
export def "delete-provisioning-artifact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
  provisioning_artifact_id: string # The identifier of the provisioning artifact.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DeleteProvisioningArtifact"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ProductId, var: product_id}, {name: ProvisioningArtifactId, var: provisioning_artifact_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, product_id: $product_id, provisioning_artifact_id: $provisioning_artifact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a self-service action.
#
# POST /
# Returns: record
# operationId: DeleteServiceAction
export def "delete-service-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The self-service action identifier. For example, act-fs7abcd89wxyz.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DeleteServiceAction"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: AcceptLanguage, var: accept_language}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified TagOption. You cannot delete a TagOption if it is associated with a product or portfolio.
#
# POST /
# Returns: record
# operationId: DeleteTagOption
export def "delete-tag-option" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The TagOption identifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DeleteTagOption"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified constraint.
#
# POST /
# Returns: record<ConstraintDetail: record<ConstraintId: string, Type: string, Description: string, Owner: string, ProductId: string, PortfolioId: string>, ConstraintParameters: string, Status: string>
# operationId: DescribeConstraint
export def "describe-constraint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The identifier of the constraint.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DescribeConstraint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the status of the specified copy product operation.
#
# POST /
# Returns: record<CopyProductStatus: string, TargetProductId: string, StatusDetail: string>
# operationId: DescribeCopyProductStatus
export def "describe-copy-product-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  copy_product_token: string # The token for the copy product operation. This token is returned by CopyProduct.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DescribeCopyProductStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: CopyProductToken, var: copy_product_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, copy_product_token: $copy_product_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified portfolio. A delegated admin is authorized to invoke this command.
#
# POST /
# Returns: record<PortfolioDetail: record<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, Tags: table<Key: string, Value: string>, TagOptions: table<Key: string, Value: string, Active: bool, Id: string, Owner: string>, Budgets: table<BudgetName: string>>
# operationId: DescribePortfolio
export def "describe-portfolio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The portfolio identifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DescribePortfolio"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the status of the specified portfolio share operation. This API can only be called by the management account in the organization or by a delegated admin.
#
# POST /
# Returns: record<PortfolioShareToken: string, PortfolioId: string, OrganizationNodeValue: string, Status: string, ShareDetails: record<SuccessfulShares: list<string>, ShareErrors: list<record>>>
# operationId: DescribePortfolioShareStatus
export def "describe-portfolio-share-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  portfolio_share_token: string # The token for the portfolio share operation. This token is returned either by CreatePortfolioShare or by DeletePortfolioShare.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DescribePortfolioShareStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PortfolioShareToken, var: portfolio_share_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, portfolio_share_token: $portfolio_share_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a summary of each of the portfolio shares that were created for the specified portfolio. You can use this API to determine which accounts or organizational nodes this portfolio have been shared, whether the recipient entity has imported the share, and whether TagOptions are included with the share. The PortfolioId and Type parameters are both required.
#
# POST /
# Returns: record<NextPageToken: string, PortfolioShareDetails: table<PrincipalId: string, Type: string, Accepted: bool, ShareTagOptions: bool, SharePrincipals: bool>>
# operationId: DescribePortfolioShares
export def "describe-portfolio-shares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-29 # required
  portfolio_id: string # The unique identifier of the portfolio for which shares will be retrieved.
  type: string@type-completer # The type of portfolio share to summarize. This field acts as a filter on the type of portfolio share, which can be one of the following: 1. ACCOUNT - Represents an external account to account share. 2. ORGANIZATION - Represents a share to an organization. This share is available to every account in the organization. 3. ORGANIZATIONAL_UNIT - Represents a share to an organizational unit. 4. ORGANIZATION_MEMBER_ACCOUNT - Represents a share to an account in the organization.
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DescribePortfolioShares"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PortfolioId, var: portfolio_id}, {name: Type, var: type}, {name: PageToken, var: body_page_token}, {name: PageSize, var: body_page_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, portfolio_id: $portfolio_id, type: $type, body_page_token: $body_page_token, body_page_size: $body_page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified product. Running this operation with administrator access results in a failure. DescribeProductAsAdmin should be used instead.
#
# POST /
# Returns: record<ProductViewSummary: record<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, ProvisioningArtifacts: table<Id: string, Name: string, Description: string, CreatedTime: string, Guidance: string>, Budgets: table<BudgetName: string>, LaunchPaths: table<Id: string, Name: string>>
# operationId: DescribeProduct
export def "describe-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --id: string # The product identifier.
  --name: string # The product name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DescribeProduct"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: Id, var: id}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified product. This operation is run with administrator access.
#
# POST /
# Returns: record<ProductViewDetail: record<ProductViewSummary: record<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, Status: string, ProductARN: string, CreatedTime: string, SourceConnection: record<Type: string, ConnectionParameters: record, LastSync: record>>, ProvisioningArtifactSummaries: table<Id: string, Name: string, Description: string, CreatedTime: string, ProvisioningArtifactMetadata: record>, Tags: table<Key: string, Value: string>, TagOptions: table<Key: string, Value: string, Active: bool, Id: string, Owner: string>, Budgets: table<BudgetName: string>>
# operationId: DescribeProductAsAdmin
export def "describe-product-as-admin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --id: string # The product identifier.
  --name: string # The product name.
  --source-portfolio-id: string # The unique identifier of the shared portfolio that the specified product is associated with. You can provide this parameter to retrieve the shared TagOptions associated with the product. If this parameter is provided and if TagOptions sharing is enabled in the portfolio share, the API returns both local and shared TagOptions associated with the product. Otherwise only local TagOptions will be returned.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DescribeProductAsAdmin"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: Id, var: id}, {name: Name, var: name}, {name: SourcePortfolioId, var: source_portfolio_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, id: $id, name: $name, source_portfolio_id: $source_portfolio_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified product.
#
# POST /
# Returns: record<ProductViewSummary: record<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, ProvisioningArtifacts: table<Id: string, Name: string, Description: string, CreatedTime: string, Guidance: string>>
# operationId: DescribeProductView
export def "describe-product-view" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The product view identifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DescribeProductView"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified provisioned product.
#
# POST /
# Returns: record<ProvisionedProductDetail: record<Name: string, Arn: string, Type: string, Id: string, Status: string, StatusMessage: string, CreatedTime: string, IdempotencyToken: string, LastRecordId: string, LastProvisioningRecordId: string, LastSuccessfulProvisioningRecordId: string, ProductId: string, ProvisioningArtifactId: string, LaunchRoleArn: string>, CloudWatchDashboards: table<Name: string>>
# operationId: DescribeProvisionedProduct
export def "describe-provisioned-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --id: string # The provisioned product identifier. You must provide the name or ID, but not both. If you do not provide a name or ID, or you provide both name and ID, an InvalidParametersException will occur.
  --name: string # The name of the provisioned product. You must provide the name or ID, but not both. If you do not provide a name or ID, or you provide both name and ID, an InvalidParametersException will occur.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DescribeProvisionedProduct"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: Id, var: id}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the resource changes for the specified plan.
#
# POST /
# Returns: record<ProvisionedProductPlanDetails: record<CreatedTime: string, PathId: string, ProductId: string, PlanName: string, PlanId: string, ProvisionProductId: string, ProvisionProductName: string, PlanType: string, ProvisioningArtifactId: string, Status: string, UpdatedTime: string, NotificationArns: list<string>, ProvisioningParameters: list<record>, Tags: list<record>, StatusMessage: string>, ResourceChanges: table<Action: string, LogicalResourceId: string, PhysicalResourceId: string, ResourceType: string, Replacement: string, Scope: list, Details: list>, NextPageToken: string>
# operationId: DescribeProvisionedProductPlan
export def "describe-provisioned-product-plan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  plan_id: string # The plan identifier.
  --page-size: int # The maximum number of items to return with this call.
  --page-token: string # The page token for the next set of results. To retrieve the first set of results, use null.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DescribeProvisionedProductPlan"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PlanId, var: plan_id}, {name: PageSize, var: page_size}, {name: PageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, plan_id: $plan_id, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified provisioning artifact (also known as a version) for the specified product.
#
# POST /
# Returns: record<ProvisioningArtifactDetail: record<Id: string, Name: string, Description: string, Type: string, CreatedTime: string, Active: bool, Guidance: string, SourceRevision: string>, Info: record, Status: string>
# operationId: DescribeProvisioningArtifact
export def "describe-provisioning-artifact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --provisioning-artifact-id: string # The identifier of the provisioning artifact.
  --product-id: string # The product identifier.
  --provisioning-artifact-name: string # The provisioning artifact name.
  --product-name: string # The product name.
  --verbose: oneof<nothing, bool> # Indicates whether a verbose level of detail is enabled.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DescribeProvisioningArtifact"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ProvisioningArtifactId, var: provisioning_artifact_id}, {name: ProductId, var: product_id}, {name: ProvisioningArtifactName, var: provisioning_artifact_name}, {name: ProductName, var: product_name}, {name: Verbose, var: verbose}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, provisioning_artifact_id: $provisioning_artifact_id, product_id: $product_id, provisioning_artifact_name: $provisioning_artifact_name, product_name: $product_name, verbose: $verbose
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the configuration required to provision the specified product using the specified provisioning artifact. If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to ProvisionProduct, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[N]:Value". Tag the provisioned product with the value sc-tagoption-conflict-portfolioId-productId.
#
# POST /
# Returns: record<ProvisioningArtifactParameters: table<ParameterKey: string, DefaultValue: string, ParameterType: string, IsNoEcho: bool, Description: string, ParameterConstraints: record>, ConstraintSummaries: table<Type: string, Description: string>, UsageInstructions: table<Type: string, Value: string>, TagOptions: table<Key: string, Values: list>, ProvisioningArtifactPreferences: record<StackSetAccounts: list<string>, StackSetRegions: list<string>>, ProvisioningArtifactOutputs: table<Key: string, Description: string>, ProvisioningArtifactOutputKeys: table<Key: string, Description: string>>
# operationId: DescribeProvisioningParameters
export def "describe-provisioning-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --product-id: string # The product identifier. You must provide the product name or ID, but not both.
  --product-name: string # The name of the product. You must provide the name or ID, but not both.
  --provisioning-artifact-id: string # The identifier of the provisioning artifact. You must provide the name or ID, but not both.
  --provisioning-artifact-name: string # The name of the provisioning artifact. You must provide the name or ID, but not both.
  --path-id: string # The path identifier of the product. This value is optional if the product has a default path, and required if the product has more than one path. To list the paths for a product, use ListLaunchPaths. You must provide the name or ID, but not both.
  --path-name: string # The name of the path. You must provide the name or ID, but not both.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DescribeProvisioningParameters"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ProductId, var: product_id}, {name: ProductName, var: product_name}, {name: ProvisioningArtifactId, var: provisioning_artifact_id}, {name: ProvisioningArtifactName, var: provisioning_artifact_name}, {name: PathId, var: path_id}, {name: PathName, var: path_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, product_id: $product_id, product_name: $product_name, provisioning_artifact_id: $provisioning_artifact_id, provisioning_artifact_name: $provisioning_artifact_name, path_id: $path_id, path_name: $path_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified request operation. Use this operation after calling a request operation (for example, ProvisionProduct, TerminateProvisionedProduct, or UpdateProvisionedProduct). If a provisioned product was transferred to a new owner using UpdateProvisionedProductProperties, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use ListRecordHistory to see the product's history from when he was the owner.
#
# POST /
# Returns: record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>, RecordOutputs: table<OutputKey: string, OutputValue: string, Description: string>, NextPageToken: string>
# operationId: DescribeRecord
export def "describe-record" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The record identifier of the provisioned product. This identifier is returned by the request operation.
  --page-token: string # The page token for the next set of results. To retrieve the first set of results, use null.
  --page-size: int # The maximum number of items to return with this call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DescribeRecord"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: Id, var: id}, {name: PageToken, var: page_token}, {name: PageSize, var: page_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, id: $id, page_token: $page_token, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a self-service action.
#
# POST /
# Returns: record<ServiceActionDetail: record<ServiceActionSummary: record<Id: string, Name: string, Description: string, DefinitionType: string>, Definition: record>>
# operationId: DescribeServiceAction
export def "describe-service-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The self-service action identifier.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DescribeServiceAction"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: AcceptLanguage, var: accept_language}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Finds the default parameters for a specific self-service action on a specific provisioned product and returns a map of the results to the user.
#
# POST /
# Returns: record<ServiceActionParameters: table<Name: string, Type: string, DefaultValues: list>>
# operationId: DescribeServiceActionExecutionParameters
export def "describe-service-action-execution-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  provisioned_product_id: string # The identifier of the provisioned product.
  service_action_id: string # The self-service action identifier.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ProvisionedProductId, var: provisioned_product_id}, {name: ServiceActionId, var: service_action_id}, {name: AcceptLanguage, var: accept_language}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, provisioned_product_id: $provisioned_product_id, service_action_id: $service_action_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified TagOption.
#
# POST /
# Returns: record<TagOptionDetail: record<Key: string, Value: string, Active: bool, Id: string, Owner: string>>
# operationId: DescribeTagOption
export def "describe-tag-option" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The TagOption identifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DescribeTagOption"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable portfolio sharing through the Organizations service. This command will not delete your current shares, but prevents you from creating new shares throughout your organization. Current shares are not kept in sync with your organization structure if the structure changes after calling this API. Only the management account in the organization can call this API. You cannot call this API if there are active delegated administrators in the organization. Note that a delegated administrator is not authorized to invoke DisableAWSOrganizationsAccess. If you share an Service Catalog portfolio in an organization within Organizations, and then disable Organizations access for Service Catalog, the portfolio access permissions will not sync with the latest changes to the organization structure. Specifically, accounts that you removed from the organization after disabling Service Catalog access will retain access to the previously shared portfolio.
#
# POST /
# Returns: record
# operationId: DisableAWSOrganizationsAccess
export def "disable-aws-organizations-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DisableAWSOrganizationsAccess"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates the specified budget from the specified resource.
#
# POST /
# Returns: record
# operationId: DisassociateBudgetFromResource
export def "disassociate-budget-from-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  budget_name: string # The name of the budget you want to disassociate.
  resource_id: string # The resource identifier you want to disassociate from. Either a portfolio-id or a product-id.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DisassociateBudgetFromResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BudgetName, var: budget_name}, {name: ResourceId, var: resource_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, budget_name: $budget_name, resource_id: $resource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a previously associated principal ARN from a specified portfolio. The PrincipalType and PrincipalARN must match the AssociatePrincipalWithPortfolio call request details. For example, to disassociate an association created with a PrincipalARN of PrincipalType IAM you must use the PrincipalType IAM when calling DisassociatePrincipalFromPortfolio. For portfolios that have been shared with principal name sharing enabled: after disassociating a principal, share recipient accounts will no longer be able to provision products in this portfolio using a role matching the name of the associated principal.
#
# POST /
# Returns: record
# operationId: DisassociatePrincipalFromPortfolio
export def "disassociate-principal-from-portfolio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  principal_arn: string # The ARN of the principal (user, role, or group). This field allows an ARN with no accountID if PrincipalType is IAM_PATTERN.
  --principal-type: string@principal-type-completer # The supported value is IAM if you use a fully defined ARN, or IAM_PATTERN if you use no accountID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PortfolioId, var: portfolio_id}, {name: PrincipalARN, var: principal_arn}, {name: PrincipalType, var: principal_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, portfolio_id: $portfolio_id, principal_arn: $principal_arn, principal_type: $principal_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates the specified product from the specified portfolio. A delegated admin is authorized to invoke this command.
#
# POST /
# Returns: record
# operationId: DisassociateProductFromPortfolio
export def "disassociate-product-from-portfolio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
  portfolio_id: string # The portfolio identifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DisassociateProductFromPortfolio"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ProductId, var: product_id}, {name: PortfolioId, var: portfolio_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, product_id: $product_id, portfolio_id: $portfolio_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates the specified self-service action association from the specified provisioning artifact.
#
# POST /
# Returns: record
# operationId: DisassociateServiceActionFromProvisioningArtifact
export def "disassociate-service-action-from-provisioning-artifact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  product_id: string # The product identifier. For example, prod-abcdzk7xy33qa.
  provisioning_artifact_id: string # The identifier of the provisioning artifact. For example, pa-4abcdjnxjj6ne.
  service_action_id: string # The self-service action identifier. For example, act-fs7abcd89wxyz.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ProductId, var: product_id}, {name: ProvisioningArtifactId, var: provisioning_artifact_id}, {name: ServiceActionId, var: service_action_id}, {name: AcceptLanguage, var: accept_language}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, product_id: $product_id, provisioning_artifact_id: $provisioning_artifact_id, service_action_id: $service_action_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates the specified TagOption from the specified resource.
#
# POST /
# Returns: record
# operationId: DisassociateTagOptionFromResource
export def "disassociate-tag-option-from-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_id: string # The resource identifier.
  tag_option_id: string # The TagOption identifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.DisassociateTagOptionFromResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}, {name: TagOptionId, var: tag_option_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id, tag_option_id: $tag_option_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable portfolio sharing feature through Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the management account in the organization. When you call this API, Service Catalog calls organizations:EnableAWSServiceAccess on your behalf so that your shares stay in sync with any changes in your Organizations structure. Note that a delegated administrator is not authorized to invoke EnableAWSOrganizationsAccess. If you have previously disabled Organizations access for Service Catalog, and then enable access again, the portfolio access permissions might not sync with the latest changes to the organization structure. Specifically, accounts that you removed from the organization after disabling Service Catalog access, and before you enabled access again, can retain access to the previously shared portfolio. As a result, an account that has been removed from the organization might still be able to create or manage Amazon Web Services resources when it is no longer authorized to do so. Amazon Web Services is working to resolve this issue.
#
# POST /
# Returns: record
# operationId: EnableAWSOrganizationsAccess
export def "enable-aws-organizations-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.EnableAWSOrganizationsAccess"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provisions or modifies a product based on the resource changes for the specified plan.
#
# POST /
# Returns: record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>
# operationId: ExecuteProvisionedProductPlan
export def "execute-provisioned-product-plan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  plan_id: string # The plan identifier.
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ExecuteProvisionedProductPlan"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PlanId, var: plan_id}, {name: IdempotencyToken, var: idempotency_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, plan_id: $plan_id, idempotency_token: $idempotency_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Executes a self-service action against a provisioned product.
#
# POST /
# Returns: record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>
# operationId: ExecuteProvisionedProductServiceAction
export def "execute-provisioned-product-service-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  provisioned_product_id: string # The identifier of the provisioned product.
  service_action_id: string # The self-service action identifier. For example, act-fs7abcd89wxyz.
  execute_token: string # An idempotency token that uniquely identifies the execute request.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --parameters: record # A map of all self-service action parameters and their values. If a provided parameter is of a special type, such as TARGET, the provided value will override the default value generated by Service Catalog. If the parameters field is not provided, no additional parameters are passed and default values will be used for any special parameters such as TARGET.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ProvisionedProductId, var: provisioned_product_id}, {name: ServiceActionId, var: service_action_id}, {name: ExecuteToken, var: execute_token}, {name: AcceptLanguage, var: accept_language}, {name: Parameters, var: parameters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, provisioned_product_id: $provisioned_product_id, service_action_id: $service_action_id, execute_token: $execute_token, accept_language: $accept_language, parameters: $parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Access Status for Organizations portfolio share feature. This API can only be called by the management account in the organization or by a delegated admin.
#
# POST /
# Returns: record<AccessStatus: string>
# operationId: GetAWSOrganizationsAccessStatus
export def "get-aws-organizations-access-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API takes either a ProvisonedProductId or a ProvisionedProductName, along with a list of one or more output keys, and responds with the key/value pairs of those outputs.
#
# POST /
# Returns: record<Outputs: table<OutputKey: string, OutputValue: string, Description: string>, NextPageToken: string>
# operationId: GetProvisionedProductOutputs
export def "get-provisioned-product-outputs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-51 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --provisioned-product-id: string # The identifier of the provisioned product that you want the outputs from.
  --provisioned-product-name: string # The name of the provisioned product that you want the outputs from.
  --output-keys: list<string> # The list of keys that the API should return with their values. If none are provided, the API will return all outputs of the provisioned product.
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.GetProvisionedProductOutputs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ProvisionedProductId, var: provisioned_product_id}, {name: ProvisionedProductName, var: provisioned_product_name}, {name: OutputKeys, var: output_keys}, {name: PageSize, var: body_page_size}, {name: PageToken, var: body_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, provisioned_product_id: $provisioned_product_id, provisioned_product_name: $provisioned_product_name, output_keys: $output_keys, body_page_size: $body_page_size, body_page_token: $body_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests the import of a resource as an Service Catalog provisioned product that is associated to an Service Catalog product and provisioning artifact. Once imported, all supported governance actions are supported on the provisioned product. Resource import only supports CloudFormation stack ARNs. CloudFormation StackSets, and non-root nested stacks are not supported. The CloudFormation stack must have one of the following statuses to be imported: CREATE_COMPLETE, UPDATE_COMPLETE, UPDATE_ROLLBACK_COMPLETE, IMPORT_COMPLETE, and IMPORT_ROLLBACK_COMPLETE. Import of the resource requires that the CloudFormation stack template matches the associated Service Catalog product provisioning artifact. When you import an existing CloudFormation stack into a portfolio, constraints that are associated with the product aren't applied during the import process. The constraints are applied after you call UpdateProvisionedProduct for the provisioned product. The user or role that performs this operation must have the cloudformation:GetTemplate and cloudformation:DescribeStacks IAM policy permissions.
#
# POST /
# Returns: record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>
# operationId: ImportAsProvisionedProduct
export def "import-as-provisioned-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
  provisioning_artifact_id: string # The identifier of the provisioning artifact.
  provisioned_product_name: string # The user-friendly name of the provisioned product. The value must be unique for the Amazon Web Services account. The name cannot be updated after the product is provisioned.
  physical_id: string # The unique identifier of the resource to be imported. It only currently supports CloudFormation stack IDs.
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ImportAsProvisionedProduct"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ProductId, var: product_id}, {name: ProvisioningArtifactId, var: provisioning_artifact_id}, {name: ProvisionedProductName, var: provisioned_product_name}, {name: PhysicalId, var: physical_id}, {name: IdempotencyToken, var: idempotency_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, product_id: $product_id, provisioning_artifact_id: $provisioning_artifact_id, provisioned_product_name: $provisioned_product_name, physical_id: $physical_id, idempotency_token: $idempotency_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all imported portfolios for which account-to-account shares were accepted by this account. By specifying the PortfolioShareType, you can list portfolios for which organizational shares were accepted by this account.
#
# POST /
# Returns: record<PortfolioDetails: table<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, NextPageToken: string>
# operationId: ListAcceptedPortfolioShares
export def "list-accepted-portfolio-shares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-53 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
  --portfolio-share-type: string@portfolio-share-type-completer # The type of shared portfolios to list. The default is to list imported portfolios. AWS_ORGANIZATIONS - List portfolios accepted and shared via organizational sharing by the management account or delegated administrator of your organization. AWS_SERVICECATALOG - Deprecated type. IMPORTED - List imported portfolios that have been accepted and shared through account-to-account sharing.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListAcceptedPortfolioShares"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PageToken, var: body_page_token}, {name: PageSize, var: body_page_size}, {name: PortfolioShareType, var: portfolio_share_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, body_page_token: $body_page_token, body_page_size: $body_page_size, portfolio_share_type: $portfolio_share_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the budgets associated to the specified resource.
#
# POST /
# Returns: record<Budgets: table<BudgetName: string>, NextPageToken: string>
# operationId: ListBudgetsForResource
export def "list-budgets-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-54 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  resource_id: string # The resource identifier.
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListBudgetsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ResourceId, var: resource_id}, {name: PageSize, var: body_page_size}, {name: PageToken, var: body_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, resource_id: $resource_id, body_page_size: $body_page_size, body_page_token: $body_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the constraints for the specified portfolio and product.
#
# POST /
# Returns: record<ConstraintDetails: table<ConstraintId: string, Type: string, Description: string, Owner: string, ProductId: string, PortfolioId: string>, NextPageToken: string>
# operationId: ListConstraintsForPortfolio
export def "list-constraints-for-portfolio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-55 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  --product-id: string # The product identifier.
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListConstraintsForPortfolio"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PortfolioId, var: portfolio_id}, {name: ProductId, var: product_id}, {name: PageSize, var: body_page_size}, {name: PageToken, var: body_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, portfolio_id: $portfolio_id, product_id: $product_id, body_page_size: $body_page_size, body_page_token: $body_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the paths to the specified product. A path describes how the user gets access to a specified product and is necessary when provisioning a product. A path also determines the constraints that are put on a product. A path is dependent on a specific product, porfolio, and principal. When provisioning a product that's been added to a portfolio, you must grant your user, group, or role access to the portfolio. For more information, see Granting users access (https://docs.aws.amazon.com/servicecatalog/latest/adminguide/catalogs_portfolios_users.html) in the Service Catalog User Guide.
#
# POST /
# Returns: record<LaunchPathSummaries: table<Id: string, ConstraintSummaries: list, Tags: list, Name: string>, NextPageToken: string>
# operationId: ListLaunchPaths
export def "list-launch-paths" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-56 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListLaunchPaths"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ProductId, var: product_id}, {name: PageSize, var: body_page_size}, {name: PageToken, var: body_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, product_id: $product_id, body_page_size: $body_page_size, body_page_token: $body_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the organization nodes that have access to the specified portfolio. This API can only be called by the management account in the organization or by a delegated admin. If a delegated admin is de-registered, they can no longer perform this operation.
#
# POST /
# Returns: record<OrganizationNodes: table<Type: string, Value: string>, NextPageToken: string>
# operationId: ListOrganizationPortfolioAccess
export def "list-organization-portfolio-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-57 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier. For example, port-2abcdext3y5fk.
  organization_node_type: string@organization-node-type-completer # The organization node type that will be returned in the output. ORGANIZATION - Organization that has access to the portfolio. ORGANIZATIONAL_UNIT - Organizational unit that has access to the portfolio within your organization. ACCOUNT - Account that has access to the portfolio within your organization.
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListOrganizationPortfolioAccess"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PortfolioId, var: portfolio_id}, {name: OrganizationNodeType, var: organization_node_type}, {name: PageToken, var: body_page_token}, {name: PageSize, var: body_page_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, portfolio_id: $portfolio_id, organization_node_type: $organization_node_type, body_page_token: $body_page_token, body_page_size: $body_page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the account IDs that have access to the specified portfolio. A delegated admin can list the accounts that have access to the shared portfolio. Note that if a delegated admin is de-registered, they can no longer perform this operation.
#
# POST /
# Returns: record<AccountIds: list<string>, NextPageToken: string>
# operationId: ListPortfolioAccess
export def "list-portfolio-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-58 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  --organization-parent-id: string # The ID of an organization node the portfolio is shared with. All children of this node with an inherited portfolio share will be returned.
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListPortfolioAccess"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PortfolioId, var: portfolio_id}, {name: OrganizationParentId, var: organization_parent_id}, {name: PageToken, var: body_page_token}, {name: PageSize, var: body_page_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, portfolio_id: $portfolio_id, organization_parent_id: $organization_parent_id, body_page_token: $body_page_token, body_page_size: $body_page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all portfolios in the catalog.
#
# POST /
# Returns: record<PortfolioDetails: table<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, NextPageToken: string>
# operationId: ListPortfolios
export def "list-portfolios" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-59 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListPortfolios"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PageToken, var: body_page_token}, {name: PageSize, var: body_page_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, body_page_token: $body_page_token, body_page_size: $body_page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all portfolios that the specified product is associated with.
#
# POST /
# Returns: record<PortfolioDetails: table<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, NextPageToken: string>
# operationId: ListPortfoliosForProduct
export def "list-portfolios-for-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-60 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListPortfoliosForProduct"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ProductId, var: product_id}, {name: PageToken, var: body_page_token}, {name: PageSize, var: body_page_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, product_id: $product_id, body_page_token: $body_page_token, body_page_size: $body_page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all PrincipalARNs and corresponding PrincipalTypes associated with the specified portfolio.
#
# POST /
# Returns: record<Principals: table<PrincipalARN: string, PrincipalType: string>, NextPageToken: string>
# operationId: ListPrincipalsForPortfolio
export def "list-principals-for-portfolio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-61 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListPrincipalsForPortfolio"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PortfolioId, var: portfolio_id}, {name: PageSize, var: body_page_size}, {name: PageToken, var: body_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, portfolio_id: $portfolio_id, body_page_size: $body_page_size, body_page_token: $body_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the plans for the specified provisioned product or all plans to which the user has access.
#
# POST /
# Returns: record<ProvisionedProductPlans: table<PlanName: string, PlanId: string, ProvisionProductId: string, ProvisionProductName: string, PlanType: string, ProvisioningArtifactId: string>, NextPageToken: string>
# operationId: ListProvisionedProductPlans
export def "list-provisioned-product-plans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --provision-product-id: string # The product identifier.
  --page-size: int # The maximum number of items to return with this call.
  --page-token: string # The page token for the next set of results. To retrieve the first set of results, use null.
  --access-level-filter: record # The access level to use to filter results. — shape: {Key?: "Account"|"Role"|"User", Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListProvisionedProductPlans"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ProvisionProductId, var: provision_product_id}, {name: PageSize, var: page_size}, {name: PageToken, var: page_token}, {name: AccessLevelFilter, var: access_level_filter}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, provision_product_id: $provision_product_id, page_size: $page_size, page_token: $page_token, access_level_filter: $access_level_filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all provisioning artifacts (also known as versions) for the specified product.
#
# POST /
# Returns: record<ProvisioningArtifactDetails: table<Id: string, Name: string, Description: string, Type: string, CreatedTime: string, Active: bool, Guidance: string, SourceRevision: string>, NextPageToken: string>
# operationId: ListProvisioningArtifacts
export def "list-provisioning-artifacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListProvisioningArtifacts"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ProductId, var: product_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all provisioning artifacts (also known as versions) for the specified self-service action.
#
# POST /
# Returns: record<ProvisioningArtifactViews: table<ProductViewSummary: record, ProvisioningArtifact: record>, NextPageToken: string>
# operationId: ListProvisioningArtifactsForServiceAction
export def "list-provisioning-artifacts-for-service-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-64 # required
  service_action_id: string # The self-service action identifier. For example, act-fs7abcd89wxyz.
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceActionId, var: service_action_id}, {name: PageSize, var: body_page_size}, {name: PageToken, var: body_page_token}, {name: AcceptLanguage, var: accept_language}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_action_id: $service_action_id, body_page_size: $body_page_size, body_page_token: $body_page_token, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the specified requests or all performed requests.
#
# POST /
# Returns: record<RecordDetails: table<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list, RecordTags: list, LaunchRoleArn: string>, NextPageToken: string>
# operationId: ListRecordHistory
export def "list-record-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --access-level-filter: record # The access level to use to filter results. — shape: {Key?: "Account"|"Role"|"User", Value?: string}
  --search-filter: record # The search filter to use when listing history records. — shape: {Key?: string, Value?: string}
  --page-size: int # The maximum number of items to return with this call.
  --page-token: string # The page token for the next set of results. To retrieve the first set of results, use null.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListRecordHistory"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: AccessLevelFilter, var: access_level_filter}, {name: SearchFilter, var: search_filter}, {name: PageSize, var: page_size}, {name: PageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, access_level_filter: $access_level_filter, search_filter: $search_filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the resources associated with the specified TagOption.
#
# POST /
# Returns: record<ResourceDetails: table<Id: string, ARN: string, Name: string, Description: string, CreatedTime: string>, PageToken: string>
# operationId: ListResourcesForTagOption
export def "list-resources-for-tag-option" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-66 # required
  tag_option_id: string # The TagOption identifier.
  --resource-type: string # The resource type. Portfolio Product
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListResourcesForTagOption"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TagOptionId, var: tag_option_id}, {name: ResourceType, var: resource_type}, {name: PageSize, var: body_page_size}, {name: PageToken, var: body_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, tag_option_id: $tag_option_id, resource_type: $resource_type, body_page_size: $body_page_size, body_page_token: $body_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all self-service actions.
#
# POST /
# Returns: record<ServiceActionSummaries: table<Id: string, Name: string, Description: string, DefinitionType: string>, NextPageToken: string>
# operationId: ListServiceActions
export def "list-service-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-67 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListServiceActions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PageSize, var: body_page_size}, {name: PageToken, var: body_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, body_page_size: $body_page_size, body_page_token: $body_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
#
# POST /
# Returns: record<ServiceActionSummaries: table<Id: string, Name: string, Description: string, DefinitionType: string>, NextPageToken: string>
# operationId: ListServiceActionsForProvisioningArtifact
export def "list-service-actions-for-provisioning-artifact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-68 # required
  product_id: string # The product identifier. For example, prod-abcdzk7xy33qa.
  provisioning_artifact_id: string # The identifier of the provisioning artifact. For example, pa-4abcdjnxjj6ne.
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ProductId, var: product_id}, {name: ProvisioningArtifactId, var: provisioning_artifact_id}, {name: PageSize, var: body_page_size}, {name: PageToken, var: body_page_token}, {name: AcceptLanguage, var: accept_language}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, product_id: $product_id, provisioning_artifact_id: $provisioning_artifact_id, body_page_size: $body_page_size, body_page_token: $body_page_token, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns summary information about stack instances that are associated with the specified CFN_STACKSET type provisioned product. You can filter for stack instances that are associated with a specific Amazon Web Services account name or Region.
#
# POST /
# Returns: record<StackInstances: table<Account: string, Region: string, StackInstanceStatus: string>, NextPageToken: string>
# operationId: ListStackInstancesForProvisionedProduct
export def "list-stack-instances-for-provisioned-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  provisioned_product_id: string # The identifier of the provisioned product.
  --page-token: string # The page token for the next set of results. To retrieve the first set of results, use null.
  --page-size: int # The maximum number of items to return with this call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ProvisionedProductId, var: provisioned_product_id}, {name: PageToken, var: page_token}, {name: PageSize, var: page_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, provisioned_product_id: $provisioned_product_id, page_token: $page_token, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the specified TagOptions or all TagOptions.
#
# POST /
# Returns: record<TagOptionDetails: table<Key: string, Value: string, Active: bool, Id: string, Owner: string>, PageToken: string>
# operationId: ListTagOptions
export def "list-tag-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-70 # required
  --filters: record # Filters to use when listing TagOptions. — shape: {Key?: string, Value?: string, Active?: bool}
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ListTagOptions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: PageSize, var: body_page_size}, {name: PageToken, var: body_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_page_size: $body_page_size, body_page_token: $body_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Notifies the result of the provisioning engine execution.
#
# POST /
# Returns: record
# operationId: NotifyProvisionProductEngineWorkflowResult
export def "notify-provision-product-engine-workflow-result" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  workflow_token: string # The encrypted contents of the provisioning engine execution payload that Service Catalog sends after the Terraform product provisioning workflow starts.
  record_id: string # The identifier of the record.
  status: string@status-completer # The status of the provisioning engine execution.
  --failure-reason: string # The reason why the provisioning engine execution failed.
  --resource-identifier: record # The ID for the provisioned product resources that are part of a resource group. — shape: {UniqueTag?: record}
  --outputs: list # The output of the provisioning engine execution. — item shape: {OutputKey?: string, OutputValue?: string, Description?: string}
  idempotency_token: string # The idempotency token that identifies the provisioning engine execution.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.NotifyProvisionProductEngineWorkflowResult"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WorkflowToken, var: workflow_token}, {name: RecordId, var: record_id}, {name: Status, var: status}, {name: FailureReason, var: failure_reason}, {name: ResourceIdentifier, var: resource_identifier}, {name: Outputs, var: outputs}, {name: IdempotencyToken, var: idempotency_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, workflow_token: $workflow_token, record_id: $record_id, status: $status, failure_reason: $failure_reason, resource_identifier: $resource_identifier, outputs: $outputs, idempotency_token: $idempotency_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Notifies the result of the terminate engine execution.
#
# POST /
# Returns: record
# operationId: NotifyTerminateProvisionedProductEngineWorkflowResult
export def "notify-terminate-provisioned-product-engine-workflow-result" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  workflow_token: string # The encrypted contents of the terminate engine execution payload that Service Catalog sends after the Terraform product terminate workflow starts.
  record_id: string # The identifier of the record.
  status: string@status-completer # The status of the terminate engine execution.
  --failure-reason: string # The reason why the terminate engine execution failed.
  idempotency_token: string # The idempotency token that identifies the terminate engine execution.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.NotifyTerminateProvisionedProductEngineWorkflowResult"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WorkflowToken, var: workflow_token}, {name: RecordId, var: record_id}, {name: Status, var: status}, {name: FailureReason, var: failure_reason}, {name: IdempotencyToken, var: idempotency_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, workflow_token: $workflow_token, record_id: $record_id, status: $status, failure_reason: $failure_reason, idempotency_token: $idempotency_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Notifies the result of the update engine execution.
#
# POST /
# Returns: record
# operationId: NotifyUpdateProvisionedProductEngineWorkflowResult
export def "notify-update-provisioned-product-engine-workflow-result" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  workflow_token: string # The encrypted contents of the update engine execution payload that Service Catalog sends after the Terraform product update workflow starts.
  record_id: string # The identifier of the record.
  status: string@status-completer # The status of the update engine execution.
  --failure-reason: string # The reason why the update engine execution failed.
  --outputs: list # The output of the update engine execution. — item shape: {OutputKey?: string, OutputValue?: string, Description?: string}
  idempotency_token: string # The idempotency token that identifies the update engine execution.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.NotifyUpdateProvisionedProductEngineWorkflowResult"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WorkflowToken, var: workflow_token}, {name: RecordId, var: record_id}, {name: Status, var: status}, {name: FailureReason, var: failure_reason}, {name: Outputs, var: outputs}, {name: IdempotencyToken, var: idempotency_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, workflow_token: $workflow_token, record_id: $record_id, status: $status, failure_reason: $failure_reason, outputs: $outputs, idempotency_token: $idempotency_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provisions the specified product. A provisioned product is a resourced instance of a product. For example, provisioning a product that's based on an CloudFormation template launches an CloudFormation stack and its underlying resources. You can check the status of this request using DescribeRecord. If the request contains a tag key with an empty list of values, there's a tag conflict for that key. Don't include conflicted keys as tags, or this will cause the error "Parameter validation failed: Missing required parameter in Tags[N]:Value". When provisioning a product that's been added to a portfolio, you must grant your user, group, or role access to the portfolio. For more information, see Granting users access (https://docs.aws.amazon.com/servicecatalog/latest/adminguide/catalogs_portfolios_users.html) in the Service Catalog User Guide.
#
# POST /
# Returns: record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>
# operationId: ProvisionProduct
export def "provision-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --product-id: string # The product identifier. You must provide the name or ID, but not both.
  --product-name: string # The name of the product. You must provide the name or ID, but not both.
  --provisioning-artifact-id: string # The identifier of the provisioning artifact. You must provide the name or ID, but not both.
  --provisioning-artifact-name: string # The name of the provisioning artifact. You must provide the name or ID, but not both.
  --path-id: string # The path identifier of the product. This value is optional if the product has a default path, and required if the product has more than one path. To list the paths for a product, use ListLaunchPaths. You must provide the name or ID, but not both.
  --path-name: string # The name of the path. You must provide the name or ID, but not both.
  provisioned_product_name: string # A user-friendly name for the provisioned product. This value must be unique for the Amazon Web Services account and cannot be updated after the product is provisioned.
  --provisioning-parameters: list # Parameters specified by the administrator that are required for provisioning the product. — item shape: {Key?: string, Value?: string}
  --provisioning-preferences: record # The user-defined preferences that will be applied when updating a provisioned product. Not all preferences are applicable to all provisioned product type One or more Amazon Web Services accounts that will have access to the provisioned product. Applicable only to a CFN_STACKSET provisioned product type. The Amazon Web Services accounts specified should be within the list of accounts in the STACKSET constraint. To get the list of accounts in the STACKSET constraint, use the DescribeProvisioningParameters operation. If no values are specified, the default value is all accounts from the STACKSET constraint. — shape: {StackSetAccounts?: list<string>, StackSetRegions?: list<string>, StackSetFailureToleranceCount?: int, StackSetFailureTolerancePercentage?: int, StackSetMaxConcurrencyCount?: int, StackSetMaxConcurrencyPercentage?: int}
  --tags: list # One or more tags. — item shape: {Key: string, Value: string}
  --notification-arns: list<string> # Passed to CloudFormation. The SNS topic ARNs to which to publish stack-related events.
  provision_token: string # An idempotency token that uniquely identifies the provisioning request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ProvisionProduct"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ProductId, var: product_id}, {name: ProductName, var: product_name}, {name: ProvisioningArtifactId, var: provisioning_artifact_id}, {name: ProvisioningArtifactName, var: provisioning_artifact_name}, {name: PathId, var: path_id}, {name: PathName, var: path_name}, {name: ProvisionedProductName, var: provisioned_product_name}, {name: ProvisioningParameters, var: provisioning_parameters}, {name: ProvisioningPreferences, var: provisioning_preferences}, {name: Tags, var: tags}, {name: NotificationArns, var: notification_arns}, {name: ProvisionToken, var: provision_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, product_id: $product_id, product_name: $product_name, provisioning_artifact_id: $provisioning_artifact_id, provisioning_artifact_name: $provisioning_artifact_name, path_id: $path_id, path_name: $path_name, provisioned_product_name: $provisioned_product_name, provisioning_parameters: $provisioning_parameters, provisioning_preferences: $provisioning_preferences, tags: $tags, notification_arns: $notification_arns, provision_token: $provision_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rejects an offer to share the specified portfolio.
#
# POST /
# Returns: record
# operationId: RejectPortfolioShare
export def "reject-portfolio-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  --portfolio-share-type: string@portfolio-share-type-completer # The type of shared portfolios to reject. The default is to reject imported portfolios. AWS_ORGANIZATIONS - Reject portfolios shared by the management account of your organization. IMPORTED - Reject imported portfolios. AWS_SERVICECATALOG - Not supported. (Throws ResourceNotFoundException.) For example, aws servicecatalog reject-portfolio-share --portfolio-id "port-2qwzkwxt3y5fk" --portfolio-share-type AWS_ORGANIZATIONS
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.RejectPortfolioShare"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PortfolioId, var: portfolio_id}, {name: PortfolioShareType, var: portfolio_share_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, portfolio_id: $portfolio_id, portfolio_share_type: $portfolio_share_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the provisioned products that are available (not terminated). To use additional filtering, see SearchProvisionedProducts.
#
# POST /
# Returns: record<ProvisionedProducts: table<Name: string, Arn: string, Type: string, Id: string, Status: string, StatusMessage: string, CreatedTime: string, IdempotencyToken: string, LastRecordId: string, LastProvisioningRecordId: string, LastSuccessfulProvisioningRecordId: string, ProductId: string, ProvisioningArtifactId: string, LaunchRoleArn: string>, NextPageToken: string>
# operationId: ScanProvisionedProducts
export def "scan-provisioned-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --access-level-filter: record # The access level to use to filter results. — shape: {Key?: "Account"|"Role"|"User", Value?: string}
  --page-size: int # The maximum number of items to return with this call.
  --page-token: string # The page token for the next set of results. To retrieve the first set of results, use null.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.ScanProvisionedProducts"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: AccessLevelFilter, var: access_level_filter}, {name: PageSize, var: page_size}, {name: PageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, access_level_filter: $access_level_filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the products to which the caller has access.
#
# POST /
# Returns: record<ProductViewSummaries: table<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, ProductViewAggregations: record, NextPageToken: string>
# operationId: SearchProducts
export def "search-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-77 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --filters: record # The search filters. If no search filters are specified, the output includes all products to which the caller has access.
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
  --sort-by: string@sort-by-completer # The sort field. If no value is specified, the results are not sorted.
  --sort-order: string@sort-order-completer # The sort order. If no value is specified, the results are not sorted.
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.SearchProducts"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: Filters, var: filters}, {name: PageSize, var: body_page_size}, {name: SortBy, var: sort_by}, {name: SortOrder, var: sort_order}, {name: PageToken, var: body_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, filters: $filters, body_page_size: $body_page_size, sort_by: $sort_by, sort_order: $sort_order, body_page_token: $body_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the products for the specified portfolio or all products.
#
# POST /
# Returns: record<ProductViewDetails: table<ProductViewSummary: record, Status: string, ProductARN: string, CreatedTime: string, SourceConnection: record>, NextPageToken: string>
# operationId: SearchProductsAsAdmin
export def "search-products-as-admin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-78 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --portfolio-id: string # The portfolio identifier.
  --filters: record # The search filters. If no search filters are specified, the output includes all products to which the administrator has access.
  --sort-by: string@sort-by-completer # The sort field. If no value is specified, the results are not sorted.
  --sort-order: string@sort-order-completer # The sort order. If no value is specified, the results are not sorted.
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
  --product-source: string@product-source-completer # Access level of the source of the product.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.SearchProductsAsAdmin"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PortfolioId, var: portfolio_id}, {name: Filters, var: filters}, {name: SortBy, var: sort_by}, {name: SortOrder, var: sort_order}, {name: PageToken, var: body_page_token}, {name: PageSize, var: body_page_size}, {name: ProductSource, var: product_source}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, portfolio_id: $portfolio_id, filters: $filters, sort_by: $sort_by, sort_order: $sort_order, body_page_token: $body_page_token, body_page_size: $body_page_size, product_source: $product_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the provisioned products that meet the specified criteria.
#
# POST /
# Returns: record<ProvisionedProducts: table<Name: string, Arn: string, Type: string, Id: string, Status: string, StatusMessage: string, CreatedTime: string, IdempotencyToken: string, LastRecordId: string, LastProvisioningRecordId: string, LastSuccessfulProvisioningRecordId: string, Tags: list, PhysicalId: string, ProductId: string, ProductName: string, ProvisioningArtifactId: string, ProvisioningArtifactName: string, UserArn: string, UserArnSession: string>, TotalResultsCount: int, NextPageToken: string>
# operationId: SearchProvisionedProducts
export def "search-provisioned-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-79 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --access-level-filter: record # The access level to use to filter results. — shape: {Key?: "Account"|"Role"|"User", Value?: string}
  --filters: record # The search filters. When the key is SearchQuery, the searchable fields are arn, createdTime, id, lastRecordId, idempotencyToken, name, physicalId, productId, provisioningArtifact, type, status, tags, userArn, userArnSession, lastProvisioningRecordId, lastSuccessfulProvisioningRecordId, productName, and provisioningArtifactName. Example: "SearchQuery":["status:AVAILABLE"]
  --sort-by: string # The sort field. If no value is specified, the results are not sorted. The valid values are arn, id, name, and lastRecordId.
  --sort-order: string@sort-order-completer # The sort order. If no value is specified, the results are not sorted.
  --body-page-size: int # The maximum number of items to return with this call. (spec name: PageSize)
  --body-page-token: string # The page token for the next set of results. To retrieve the first set of results, use null. (spec name: PageToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: PageSize, var: page_size}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.SearchProvisionedProducts"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: AccessLevelFilter, var: access_level_filter}, {name: Filters, var: filters}, {name: SortBy, var: sort_by}, {name: SortOrder, var: sort_order}, {name: PageSize, var: body_page_size}, {name: PageToken, var: body_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, access_level_filter: $access_level_filter, filters: $filters, sort_by: $sort_by, sort_order: $sort_order, body_page_size: $body_page_size, body_page_token: $body_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Terminates the specified provisioned product. This operation does not delete any records associated with the provisioned product. You can check the status of this request using DescribeRecord.
#
# POST /
# Returns: record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>
# operationId: TerminateProvisionedProduct
export def "terminate-provisioned-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --provisioned-product-name: string # The name of the provisioned product. You cannot specify both ProvisionedProductName and ProvisionedProductId.
  --provisioned-product-id: string # The identifier of the provisioned product. You cannot specify both ProvisionedProductName and ProvisionedProductId.
  terminate_token: string # An idempotency token that uniquely identifies the termination request. This token is only valid during the termination process. After the provisioned product is terminated, subsequent requests to terminate the same provisioned product always return ResourceNotFound.
  --ignore-errors: oneof<nothing, bool> # If set to true, Service Catalog stops managing the specified provisioned product even if it cannot delete the underlying resources.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --retain-physical-resources: oneof<nothing, bool> # When this boolean parameter is set to true, the TerminateProvisionedProduct API deletes the Service Catalog provisioned product. However, it does not remove the CloudFormation stack, stack set, or the underlying resources of the deleted provisioned product. The default value is false.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.TerminateProvisionedProduct"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ProvisionedProductName, var: provisioned_product_name}, {name: ProvisionedProductId, var: provisioned_product_id}, {name: TerminateToken, var: terminate_token}, {name: IgnoreErrors, var: ignore_errors}, {name: AcceptLanguage, var: accept_language}, {name: RetainPhysicalResources, var: retain_physical_resources}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, provisioned_product_name: $provisioned_product_name, provisioned_product_id: $provisioned_product_id, terminate_token: $terminate_token, ignore_errors: $ignore_errors, accept_language: $accept_language, retain_physical_resources: $retain_physical_resources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified constraint.
#
# POST /
# Returns: record<ConstraintDetail: record<ConstraintId: string, Type: string, Description: string, Owner: string, ProductId: string, PortfolioId: string>, ConstraintParameters: string, Status: string>
# operationId: UpdateConstraint
export def "update-constraint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The identifier of the constraint.
  --description: string # The updated description of the constraint.
  --parameters: string # The constraint parameters, in JSON format. The syntax depends on the constraint type as follows: LAUNCH You are required to specify either the RoleArn or the LocalRoleName but can't use both. Specify the RoleArn property as follows: {"RoleArn" : "arn:aws:iam::123456789012:role/LaunchRole"} Specify the LocalRoleName property as follows: {"LocalRoleName": "SCBasicLaunchRole"} If you specify the LocalRoleName property, when an account uses the launch constraint, the IAM role with that name in the account will be used. This allows launch-role constraints to be account-agnostic so the administrator can create fewer resources per shared account. The given role name must exist in the account used to create the launch constraint and the account of the user who launches a product with this launch constraint. You cannot have both a LAUNCH and a STACKSET constraint. You also cannot have more than one LAUNCH constraint on a product and portfolio. NOTIFICATION Specify the NotificationArns property as follows: {"NotificationArns" : ["arn:aws:sns:us-east-1:123456789012:Topic"]} RESOURCE_UPDATE Specify the TagUpdatesOnProvisionedProduct property as follows: {"Version":"2.0","Properties":{"TagUpdateOnProvisionedProduct":"String"}} The TagUpdatesOnProvisionedProduct property accepts a string value of ALLOWED or NOT_ALLOWED. STACKSET Specify the Parameters property as follows: {"Version": "String", "Properties": {"AccountList": [ "String" ], "RegionList": [ "String" ], "AdminRole": "String", "ExecutionRole": "String"}} You cannot have both a LAUNCH and a STACKSET constraint. You also cannot have more than one STACKSET constraint on a product and portfolio. Products with a STACKSET constraint will launch an CloudFormation stack set. TEMPLATE Specify the Rules property. For more information, see Template Constraint Rules (http://docs.aws.amazon.com/servicecatalog/latest/adminguide/reference-template_constraint_rules.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.UpdateConstraint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: Id, var: id}, {name: Description, var: description}, {name: Parameters, var: parameters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, id: $id, description: $description, parameters: $parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified portfolio. You cannot update a product that was shared with you.
#
# POST /
# Returns: record<PortfolioDetail: record<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, Tags: table<Key: string, Value: string>>
# operationId: UpdatePortfolio
export def "update-portfolio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The portfolio identifier.
  --display-name: string # The name to use for display purposes.
  --description: string # The updated description of the portfolio.
  --provider-name: string # The updated name of the portfolio provider.
  --add-tags: list # The tags to add. — item shape: {Key: string, Value: string}
  --remove-tags: list<string> # The tags to remove.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.UpdatePortfolio"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: Id, var: id}, {name: DisplayName, var: display_name}, {name: Description, var: description}, {name: ProviderName, var: provider_name}, {name: AddTags, var: add_tags}, {name: RemoveTags, var: remove_tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, id: $id, display_name: $display_name, description: $description, provider_name: $provider_name, add_tags: $add_tags, remove_tags: $remove_tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified portfolio share. You can use this API to enable or disable TagOptions sharing or Principal sharing for an existing portfolio share. The portfolio share cannot be updated if the CreatePortfolioShare operation is IN_PROGRESS, as the share is not available to recipient entities. In this case, you must wait for the portfolio share to be COMPLETED. You must provide the accountId or organization node in the input, but not both. If the portfolio is shared to both an external account and an organization node, and both shares need to be updated, you must invoke UpdatePortfolioShare separately for each share type. This API cannot be used for removing the portfolio share. You must use DeletePortfolioShare API for that action. When you associate a principal with portfolio, a potential privilege escalation path may occur when that portfolio is then shared with other accounts. For a user in a recipient account who is not an Service Catalog Admin, but still has the ability to create Principals (Users/Groups/Roles), that user could create a role that matches a principal name association for the portfolio. Although this user may not know which principal names are associated through Service Catalog, they may be able to guess the user. If this potential escalation path is a concern, then Service Catalog recommends using PrincipalType as IAM. With this configuration, the PrincipalARN must already exist in the recipient account before it can be associated.
#
# POST /
# Returns: record<PortfolioShareToken: string, Status: string>
# operationId: UpdatePortfolioShare
export def "update-portfolio-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The unique identifier of the portfolio for which the share will be updated.
  --account-id: string # The Amazon Web Services account Id of the recipient account. This field is required when updating an external account to account type share.
  --organization-node: record # Information about the organization node. — shape: {Type?: "ORGANIZATION"|"ORGANIZATIONAL_UNIT"|"ACCOUNT", Value?: string}
  --share-tag-options: oneof<nothing, bool> # Enables or disables TagOptions sharing for the portfolio share. If this field is not provided, the current state of TagOptions sharing on the portfolio share will not be modified.
  --share-principals: oneof<nothing, bool> # A flag to enables or disables Principals sharing in the portfolio. If this field is not provided, the current state of the Principals sharing on the portfolio share will not be modified.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.UpdatePortfolioShare"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: PortfolioId, var: portfolio_id}, {name: AccountId, var: account_id}, {name: OrganizationNode, var: organization_node}, {name: ShareTagOptions, var: share_tag_options}, {name: SharePrincipals, var: share_principals}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, portfolio_id: $portfolio_id, account_id: $account_id, organization_node: $organization_node, share_tag_options: $share_tag_options, share_principals: $share_principals
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified product.
#
# POST /
# Returns: record<ProductViewDetail: record<ProductViewSummary: record<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, Status: string, ProductARN: string, CreatedTime: string, SourceConnection: record<Type: string, ConnectionParameters: record, LastSync: record>>, Tags: table<Key: string, Value: string>>
# operationId: UpdateProduct
export def "update-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The product identifier.
  --name: string # The updated product name.
  --owner: string # The updated owner of the product.
  --description: string # The updated description of the product.
  --distributor: string # The updated distributor of the product.
  --support-description: string # The updated support description for the product.
  --support-email: string # The updated support email for the product.
  --support-url: string # The updated support URL for the product.
  --add-tags: list # The tags to add to the product. — item shape: {Key: string, Value: string}
  --remove-tags: list<string> # The tags to remove from the product.
  --source-connection: record # A top level ProductViewDetail response containing details about the product’s connection. Service Catalog returns this field for the CreateProduct, UpdateProduct, DescribeProductAsAdmin, and SearchProductAsAdmin APIs. This response contains the same fields as the ConnectionParameters request, with the addition of the LastSync response. — shape: {Type?: "CODESTAR", ConnectionParameters: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.UpdateProduct"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: Id, var: id}, {name: Name, var: name}, {name: Owner, var: owner}, {name: Description, var: description}, {name: Distributor, var: distributor}, {name: SupportDescription, var: support_description}, {name: SupportEmail, var: support_email}, {name: SupportUrl, var: support_url}, {name: AddTags, var: add_tags}, {name: RemoveTags, var: remove_tags}, {name: SourceConnection, var: source_connection}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, id: $id, name: $name, owner: $owner, description: $description, distributor: $distributor, support_description: $support_description, support_email: $support_email, support_url: $support_url, add_tags: $add_tags, remove_tags: $remove_tags, source_connection: $source_connection
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests updates to the configuration of the specified provisioned product. If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely. You can check the status of this request using DescribeRecord.
#
# POST /
# Returns: record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>
# operationId: UpdateProvisionedProduct
export def "update-provisioned-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --provisioned-product-name: string # The name of the provisioned product. You cannot specify both ProvisionedProductName and ProvisionedProductId.
  --provisioned-product-id: string # The identifier of the provisioned product. You must provide the name or ID, but not both.
  --product-id: string # The identifier of the product. You must provide the name or ID, but not both.
  --product-name: string # The name of the product. You must provide the name or ID, but not both.
  --provisioning-artifact-id: string # The identifier of the provisioning artifact.
  --provisioning-artifact-name: string # The name of the provisioning artifact. You must provide the name or ID, but not both.
  --path-id: string # The path identifier. This value is optional if the product has a default path, and required if the product has more than one path. You must provide the name or ID, but not both.
  --path-name: string # The name of the path. You must provide the name or ID, but not both.
  --provisioning-parameters: list # The new parameters. — item shape: {Key?: string, Value?: string, UsePreviousValue?: bool}
  --provisioning-preferences: record # The user-defined preferences that will be applied when updating a provisioned product. Not all preferences are applicable to all provisioned product types. — shape: {StackSetAccounts?: list<string>, StackSetRegions?: list<string>, StackSetFailureToleranceCount?: int, StackSetFailureTolerancePercentage?: int, StackSetMaxConcurrencyCount?: int, StackSetMaxConcurrencyPercentage?: int, StackSetOperationType?: "CREATE"|"UPDATE"|"DELETE"}
  --tags: list # One or more tags. Requires the product to have RESOURCE_UPDATE constraint with TagUpdatesOnProvisionedProduct set to ALLOWED to allow tag updates. — item shape: {Key: string, Value: string}
  update_token: string # The idempotency token that uniquely identifies the provisioning update request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.UpdateProvisionedProduct"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ProvisionedProductName, var: provisioned_product_name}, {name: ProvisionedProductId, var: provisioned_product_id}, {name: ProductId, var: product_id}, {name: ProductName, var: product_name}, {name: ProvisioningArtifactId, var: provisioning_artifact_id}, {name: ProvisioningArtifactName, var: provisioning_artifact_name}, {name: PathId, var: path_id}, {name: PathName, var: path_name}, {name: ProvisioningParameters, var: provisioning_parameters}, {name: ProvisioningPreferences, var: provisioning_preferences}, {name: Tags, var: tags}, {name: UpdateToken, var: update_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, provisioned_product_name: $provisioned_product_name, provisioned_product_id: $provisioned_product_id, product_id: $product_id, product_name: $product_name, provisioning_artifact_id: $provisioning_artifact_id, provisioning_artifact_name: $provisioning_artifact_name, path_id: $path_id, path_name: $path_name, provisioning_parameters: $provisioning_parameters, provisioning_preferences: $provisioning_preferences, tags: $tags, update_token: $update_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests updates to the properties of the specified provisioned product.
#
# POST /
# Returns: record<ProvisionedProductId: string, ProvisionedProductProperties: record, RecordId: string, Status: string>
# operationId: UpdateProvisionedProductProperties
export def "update-provisioned-product-properties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  provisioned_product_id: string # The identifier of the provisioned product.
  provisioned_product_properties: record # A map that contains the provisioned product properties to be updated. The LAUNCH_ROLE key accepts role ARNs. This key allows an administrator to call UpdateProvisionedProductProperties to update the launch role that is associated with a provisioned product. This role is used when an end user calls a provisioning operation such as UpdateProvisionedProduct, TerminateProvisionedProduct, or ExecuteProvisionedProductServiceAction. Only a role ARN is valid. A user ARN is invalid. The OWNER key accepts user ARNs, IAM role ARNs, and STS assumed-role ARNs. The owner is the user that has permission to see, update, terminate, and execute service actions in the provisioned product. The administrator can change the owner of a provisioned product to another IAM or STS entity within the same account. Both end user owners and administrators can see ownership history of the provisioned product using the ListRecordHistory API. The new owner can describe all past records for the provisioned product using the DescribeRecord API. The previous owner can no longer use DescribeRecord, but can still see the product's history from when he was an owner using ListRecordHistory. If a provisioned product ownership is assigned to an end user, they can see and perform any action through the API or Service Catalog console such as update, terminate, and execute service actions. If an end user provisions a product and the owner is updated to someone else, they will no longer be able to see or perform any actions through API or the Service Catalog console on that provisioned product.
  idempotency_token: string # The idempotency token that uniquely identifies the provisioning product update request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.UpdateProvisionedProductProperties"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ProvisionedProductId, var: provisioned_product_id}, {name: ProvisionedProductProperties, var: provisioned_product_properties}, {name: IdempotencyToken, var: idempotency_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, provisioned_product_id: $provisioned_product_id, provisioned_product_properties: $provisioned_product_properties, idempotency_token: $idempotency_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified provisioning artifact (also known as a version) for the specified product. You cannot update a provisioning artifact for a product that was shared with you.
#
# POST /
# Returns: record<ProvisioningArtifactDetail: record<Id: string, Name: string, Description: string, Type: string, CreatedTime: string, Active: bool, Guidance: string, SourceRevision: string>, Info: record, Status: string>
# operationId: UpdateProvisioningArtifact
export def "update-provisioning-artifact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-87 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
  provisioning_artifact_id: string # The identifier of the provisioning artifact.
  --name: string # The updated name of the provisioning artifact.
  --description: string # The updated description of the provisioning artifact.
  --active: oneof<nothing, bool> # Indicates whether the product version is active. Inactive provisioning artifacts are invisible to end users. End users cannot launch or update a provisioned product from an inactive provisioning artifact.
  --guidance: string@guidance-completer # Information set by the administrator to provide guidance to end users about which provisioning artifacts to use. The DEFAULT value indicates that the product version is active. The administrator can set the guidance to DEPRECATED to inform users that the product version is deprecated. Users are able to make updates to a provisioned product of a deprecated version but cannot launch new provisioned products using a deprecated version.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.UpdateProvisioningArtifact"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLanguage, var: accept_language}, {name: ProductId, var: product_id}, {name: ProvisioningArtifactId, var: provisioning_artifact_id}, {name: Name, var: name}, {name: Description, var: description}, {name: Active, var: active}, {name: Guidance, var: guidance}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accept_language: $accept_language, product_id: $product_id, provisioning_artifact_id: $provisioning_artifact_id, name: $name, description: $description, active: $active, guidance: $guidance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a self-service action.
#
# POST /
# Returns: record<ServiceActionDetail: record<ServiceActionSummary: record<Id: string, Name: string, Description: string, DefinitionType: string>, Definition: record>>
# operationId: UpdateServiceAction
export def "update-service-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The self-service action identifier.
  --name: string # The self-service action name.
  --definition: record # A map that defines the self-service action.
  --description: string # The self-service action description.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.UpdateServiceAction"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Name, var: name}, {name: Definition, var: definition}, {name: Description, var: description}, {name: AcceptLanguage, var: accept_language}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, name: $name, definition: $definition, description: $description, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified TagOption.
#
# POST /
# Returns: record<TagOptionDetail: record<Key: string, Value: string, Active: bool, Id: string, Owner: string>>
# operationId: UpdateTagOption
export def "update-tag-option" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The TagOption identifier.
  --value: string # The updated value.
  --active: oneof<nothing, bool> # The updated active state.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWS242ServiceCatalogService.UpdateTagOption"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Value, var: value}, {name: Active, var: active}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, value: $value, active: $active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
