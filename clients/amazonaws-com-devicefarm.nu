# Auto-generated client for AWS Device Farm v2015-06-23
# Source: https://api.apis.guru/v2/specs/amazonaws.com/devicefarm/2015-06-23/openapi.json
# Auth: --token flag or $env.AWS_DEVICE_FARM_TOKEN

const CLIENT = {
  base_url: "http://devicefarm.us-east-1.amazonaws.com"
  token_env_var: "AWS_DEVICE_FARM_TOKEN"
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

def base-url-completer [] { ["http://devicefarm.us-east-1.amazonaws.com" "http://devicefarm.us-east-2.amazonaws.com" "http://devicefarm.us-west-1.amazonaws.com" "http://devicefarm.us-west-2.amazonaws.com" "http://devicefarm.us-gov-west-1.amazonaws.com" "http://devicefarm.us-gov-east-1.amazonaws.com" "http://devicefarm.ca-central-1.amazonaws.com" "http://devicefarm.eu-north-1.amazonaws.com" "http://devicefarm.eu-west-1.amazonaws.com" "http://devicefarm.eu-west-2.amazonaws.com" "http://devicefarm.eu-west-3.amazonaws.com" "http://devicefarm.eu-central-1.amazonaws.com" "http://devicefarm.eu-south-1.amazonaws.com" "http://devicefarm.af-south-1.amazonaws.com" "http://devicefarm.ap-northeast-1.amazonaws.com" "http://devicefarm.ap-northeast-2.amazonaws.com" "http://devicefarm.ap-northeast-3.amazonaws.com" "http://devicefarm.ap-southeast-1.amazonaws.com" "http://devicefarm.ap-southeast-2.amazonaws.com" "http://devicefarm.ap-east-1.amazonaws.com" "http://devicefarm.ap-south-1.amazonaws.com" "http://devicefarm.sa-east-1.amazonaws.com" "http://devicefarm.me-south-1.amazonaws.com" "https://devicefarm.us-east-1.amazonaws.com" "https://devicefarm.us-east-2.amazonaws.com" "https://devicefarm.us-west-1.amazonaws.com" "https://devicefarm.us-west-2.amazonaws.com" "https://devicefarm.us-gov-west-1.amazonaws.com" "https://devicefarm.us-gov-east-1.amazonaws.com" "https://devicefarm.ca-central-1.amazonaws.com" "https://devicefarm.eu-north-1.amazonaws.com" "https://devicefarm.eu-west-1.amazonaws.com" "https://devicefarm.eu-west-2.amazonaws.com" "https://devicefarm.eu-west-3.amazonaws.com" "https://devicefarm.eu-central-1.amazonaws.com" "https://devicefarm.eu-south-1.amazonaws.com" "https://devicefarm.af-south-1.amazonaws.com" "https://devicefarm.ap-northeast-1.amazonaws.com" "https://devicefarm.ap-northeast-2.amazonaws.com" "https://devicefarm.ap-northeast-3.amazonaws.com" "https://devicefarm.ap-southeast-1.amazonaws.com" "https://devicefarm.ap-southeast-2.amazonaws.com" "https://devicefarm.ap-east-1.amazonaws.com" "https://devicefarm.ap-south-1.amazonaws.com" "https://devicefarm.sa-east-1.amazonaws.com" "https://devicefarm.me-south-1.amazonaws.com" "http://devicefarm.cn-north-1.amazonaws.com.cn" "http://devicefarm.cn-northwest-1.amazonaws.com.cn" "https://devicefarm.cn-north-1.amazonaws.com.cn" "https://devicefarm.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["DeviceFarm_20150623.CreateDevicePool"] }
def x-amz-target-completer-1 [] { ["DeviceFarm_20150623.CreateInstanceProfile"] }
def type-completer [] { ["CURATED" "PRIVATE"] }
def x-amz-target-completer-2 [] { ["DeviceFarm_20150623.CreateNetworkProfile"] }
def x-amz-target-completer-3 [] { ["DeviceFarm_20150623.CreateProject"] }
def interaction-mode-completer [] { ["INTERACTIVE" "NO_VIDEO" "VIDEO_ONLY"] }
def x-amz-target-completer-4 [] { ["DeviceFarm_20150623.CreateRemoteAccessSession"] }
def x-amz-target-completer-5 [] { ["DeviceFarm_20150623.CreateTestGridProject"] }
def x-amz-target-completer-6 [] { ["DeviceFarm_20150623.CreateTestGridUrl"] }
def type-completer-1 [] { ["ANDROID_APP" "APPIUM_JAVA_JUNIT_TEST_PACKAGE" "APPIUM_JAVA_JUNIT_TEST_SPEC" "APPIUM_JAVA_TESTNG_TEST_PACKAGE" "APPIUM_JAVA_TESTNG_TEST_SPEC" "APPIUM_NODE_TEST_PACKAGE" "APPIUM_NODE_TEST_SPEC" "APPIUM_PYTHON_TEST_PACKAGE" "APPIUM_PYTHON_TEST_SPEC" "APPIUM_RUBY_TEST_PACKAGE" "APPIUM_RUBY_TEST_SPEC" "APPIUM_WEB_JAVA_JUNIT_TEST_PACKAGE" "APPIUM_WEB_JAVA_JUNIT_TEST_SPEC" "APPIUM_WEB_JAVA_TESTNG_TEST_PACKAGE" "APPIUM_WEB_JAVA_TESTNG_TEST_SPEC" "APPIUM_WEB_NODE_TEST_PACKAGE" "APPIUM_WEB_NODE_TEST_SPEC" "APPIUM_WEB_PYTHON_TEST_PACKAGE" "APPIUM_WEB_PYTHON_TEST_SPEC" "APPIUM_WEB_RUBY_TEST_PACKAGE" "APPIUM_WEB_RUBY_TEST_SPEC" "CALABASH_TEST_PACKAGE" "EXTERNAL_DATA" "INSTRUMENTATION_TEST_PACKAGE" "INSTRUMENTATION_TEST_SPEC" "IOS_APP" "UIAUTOMATION_TEST_PACKAGE" "UIAUTOMATOR_TEST_PACKAGE" "WEB_APP" "XCTEST_TEST_PACKAGE" "XCTEST_UI_TEST_PACKAGE" "XCTEST_UI_TEST_SPEC"] }
def x-amz-target-completer-7 [] { ["DeviceFarm_20150623.CreateUpload"] }
def x-amz-target-completer-8 [] { ["DeviceFarm_20150623.CreateVPCEConfiguration"] }
def x-amz-target-completer-9 [] { ["DeviceFarm_20150623.DeleteDevicePool"] }
def x-amz-target-completer-10 [] { ["DeviceFarm_20150623.DeleteInstanceProfile"] }
def x-amz-target-completer-11 [] { ["DeviceFarm_20150623.DeleteNetworkProfile"] }
def x-amz-target-completer-12 [] { ["DeviceFarm_20150623.DeleteProject"] }
def x-amz-target-completer-13 [] { ["DeviceFarm_20150623.DeleteRemoteAccessSession"] }
def x-amz-target-completer-14 [] { ["DeviceFarm_20150623.DeleteRun"] }
def x-amz-target-completer-15 [] { ["DeviceFarm_20150623.DeleteTestGridProject"] }
def x-amz-target-completer-16 [] { ["DeviceFarm_20150623.DeleteUpload"] }
def x-amz-target-completer-17 [] { ["DeviceFarm_20150623.DeleteVPCEConfiguration"] }
def x-amz-target-completer-18 [] { ["DeviceFarm_20150623.GetAccountSettings"] }
def x-amz-target-completer-19 [] { ["DeviceFarm_20150623.GetDevice"] }
def x-amz-target-completer-20 [] { ["DeviceFarm_20150623.GetDeviceInstance"] }
def x-amz-target-completer-21 [] { ["DeviceFarm_20150623.GetDevicePool"] }
def test-type-completer [] { ["APPIUM_JAVA_JUNIT" "APPIUM_JAVA_TESTNG" "APPIUM_NODE" "APPIUM_PYTHON" "APPIUM_RUBY" "APPIUM_WEB_JAVA_JUNIT" "APPIUM_WEB_JAVA_TESTNG" "APPIUM_WEB_NODE" "APPIUM_WEB_PYTHON" "APPIUM_WEB_RUBY" "BUILTIN_EXPLORER" "BUILTIN_FUZZ" "CALABASH" "INSTRUMENTATION" "REMOTE_ACCESS_RECORD" "REMOTE_ACCESS_REPLAY" "UIAUTOMATION" "UIAUTOMATOR" "WEB_PERFORMANCE_PROFILE" "XCTEST" "XCTEST_UI"] }
def x-amz-target-completer-22 [] { ["DeviceFarm_20150623.GetDevicePoolCompatibility"] }
def x-amz-target-completer-23 [] { ["DeviceFarm_20150623.GetInstanceProfile"] }
def x-amz-target-completer-24 [] { ["DeviceFarm_20150623.GetJob"] }
def x-amz-target-completer-25 [] { ["DeviceFarm_20150623.GetNetworkProfile"] }
def x-amz-target-completer-26 [] { ["DeviceFarm_20150623.GetOfferingStatus"] }
def x-amz-target-completer-27 [] { ["DeviceFarm_20150623.GetProject"] }
def x-amz-target-completer-28 [] { ["DeviceFarm_20150623.GetRemoteAccessSession"] }
def x-amz-target-completer-29 [] { ["DeviceFarm_20150623.GetRun"] }
def x-amz-target-completer-30 [] { ["DeviceFarm_20150623.GetSuite"] }
def x-amz-target-completer-31 [] { ["DeviceFarm_20150623.GetTest"] }
def x-amz-target-completer-32 [] { ["DeviceFarm_20150623.GetTestGridProject"] }
def x-amz-target-completer-33 [] { ["DeviceFarm_20150623.GetTestGridSession"] }
def x-amz-target-completer-34 [] { ["DeviceFarm_20150623.GetUpload"] }
def x-amz-target-completer-35 [] { ["DeviceFarm_20150623.GetVPCEConfiguration"] }
def x-amz-target-completer-36 [] { ["DeviceFarm_20150623.InstallToRemoteAccessSession"] }
def type-completer-2 [] { ["FILE" "LOG" "SCREENSHOT"] }
def x-amz-target-completer-37 [] { ["DeviceFarm_20150623.ListArtifacts"] }
def x-amz-target-completer-38 [] { ["DeviceFarm_20150623.ListDeviceInstances"] }
def x-amz-target-completer-39 [] { ["DeviceFarm_20150623.ListDevicePools"] }
def x-amz-target-completer-40 [] { ["DeviceFarm_20150623.ListDevices"] }
def x-amz-target-completer-41 [] { ["DeviceFarm_20150623.ListInstanceProfiles"] }
def x-amz-target-completer-42 [] { ["DeviceFarm_20150623.ListJobs"] }
def x-amz-target-completer-43 [] { ["DeviceFarm_20150623.ListNetworkProfiles"] }
def x-amz-target-completer-44 [] { ["DeviceFarm_20150623.ListOfferingPromotions"] }
def x-amz-target-completer-45 [] { ["DeviceFarm_20150623.ListOfferingTransactions"] }
def x-amz-target-completer-46 [] { ["DeviceFarm_20150623.ListOfferings"] }
def x-amz-target-completer-47 [] { ["DeviceFarm_20150623.ListProjects"] }
def x-amz-target-completer-48 [] { ["DeviceFarm_20150623.ListRemoteAccessSessions"] }
def x-amz-target-completer-49 [] { ["DeviceFarm_20150623.ListRuns"] }
def x-amz-target-completer-50 [] { ["DeviceFarm_20150623.ListSamples"] }
def x-amz-target-completer-51 [] { ["DeviceFarm_20150623.ListSuites"] }
def x-amz-target-completer-52 [] { ["DeviceFarm_20150623.ListTagsForResource"] }
def x-amz-target-completer-53 [] { ["DeviceFarm_20150623.ListTestGridProjects"] }
def x-amz-target-completer-54 [] { ["DeviceFarm_20150623.ListTestGridSessionActions"] }
def type-completer-3 [] { ["LOG" "VIDEO"] }
def x-amz-target-completer-55 [] { ["DeviceFarm_20150623.ListTestGridSessionArtifacts"] }
def status-completer [] { ["ACTIVE" "CLOSED" "ERRORED"] }
def x-amz-target-completer-56 [] { ["DeviceFarm_20150623.ListTestGridSessions"] }
def x-amz-target-completer-57 [] { ["DeviceFarm_20150623.ListTests"] }
def x-amz-target-completer-58 [] { ["DeviceFarm_20150623.ListUniqueProblems"] }
def x-amz-target-completer-59 [] { ["DeviceFarm_20150623.ListUploads"] }
def x-amz-target-completer-60 [] { ["DeviceFarm_20150623.ListVPCEConfigurations"] }
def x-amz-target-completer-61 [] { ["DeviceFarm_20150623.PurchaseOffering"] }
def x-amz-target-completer-62 [] { ["DeviceFarm_20150623.RenewOffering"] }
def x-amz-target-completer-63 [] { ["DeviceFarm_20150623.ScheduleRun"] }
def x-amz-target-completer-64 [] { ["DeviceFarm_20150623.StopJob"] }
def x-amz-target-completer-65 [] { ["DeviceFarm_20150623.StopRemoteAccessSession"] }
def x-amz-target-completer-66 [] { ["DeviceFarm_20150623.StopRun"] }
def x-amz-target-completer-67 [] { ["DeviceFarm_20150623.TagResource"] }
def x-amz-target-completer-68 [] { ["DeviceFarm_20150623.UntagResource"] }
def x-amz-target-completer-69 [] { ["DeviceFarm_20150623.UpdateDeviceInstance"] }
def x-amz-target-completer-70 [] { ["DeviceFarm_20150623.UpdateDevicePool"] }
def x-amz-target-completer-71 [] { ["DeviceFarm_20150623.UpdateInstanceProfile"] }
def x-amz-target-completer-72 [] { ["DeviceFarm_20150623.UpdateNetworkProfile"] }
def x-amz-target-completer-73 [] { ["DeviceFarm_20150623.UpdateProject"] }
def x-amz-target-completer-74 [] { ["DeviceFarm_20150623.UpdateTestGridProject"] }
def x-amz-target-completer-75 [] { ["DeviceFarm_20150623.UpdateUpload"] }
def x-amz-target-completer-76 [] { ["DeviceFarm_20150623.UpdateVPCEConfiguration"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-device-pool: "record<devicePool: record<arn: string, name: string, description: string, type: string, rules: list<record>, maxDevices: int>>"
    create-instance-profile: "record<instanceProfile: record<arn: string, packageCleanup: bool, excludeAppPackagesFromCleanup: list<string>, rebootAfterUse: bool, name: string, description: string>>"
    create-network-profile: "record<networkProfile: record<arn: string, name: string, description: string, type: string, uplinkBandwidthBits: int, downlinkBandwidthBits: int, uplinkDelayMs: int, downlinkDelayMs: int, uplinkJitterMs: int, downlinkJitterMs: int, uplinkLossPercent: int, downlinkLossPercent: int>>"
    create-project: "record<project: record<arn: string, name: string, defaultJobTimeoutMinutes: int, created: string, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>"
    create-remote-access-session: "record<remoteAccessSession: record<arn: string, name: string, created: string, status: string, result: string, message: string, started: string, stopped: string, device: record<arn: string, name: string, manufacturer: string, model: string, modelId: string, formFactor: string, platform: string, os: string, cpu: record, resolution: record, heapSize: int, memory: int, image: string, carrier: string, radio: string, remoteAccessEnabled: bool, remoteDebugEnabled: bool, fleetType: string, fleetName: string, instances: list, availability: string>, instanceArn: string, remoteDebugEnabled: bool, remoteRecordEnabled: bool, remoteRecordAppArn: string, hostAddress: string, clientId: string, billingMethod: string, deviceMinutes: record<total: float, metered: float, unmetered: float>, endpoint: string, deviceUdid: string, interactionMode: string, skipAppResign: bool, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>"
    create-test-grid-project: "record<testGridProject: record<arn: string, name: string, description: string, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>, created: string>>"
    create-test-grid-url: "record<url: string, expires: string>"
    create-upload: "record<upload: record<arn: string, name: string, created: string, type: string, status: string, url: string, metadata: string, contentType: string, message: string, category: string>>"
    create-vpce-configuration: "record<vpceConfiguration: record<arn: string, vpceConfigurationName: string, vpceServiceName: string, serviceDnsName: string, vpceConfigurationDescription: string>>"
    delete-device-pool: "record"
    delete-instance-profile: "record"
    delete-network-profile: "record"
    delete-project: "record"
    delete-remote-access-session: "record"
    delete-run: "record"
    delete-test-grid-project: "record"
    delete-upload: "record"
    delete-vpce-configuration: "record"
    get-account-settings: "record<accountSettings: record<awsAccountNumber: string, unmeteredDevices: record, unmeteredRemoteAccessDevices: record, maxJobTimeoutMinutes: int, trialMinutes: record<total: float, remaining: float>, maxSlots: record, defaultJobTimeoutMinutes: int, skipAppResign: bool>>"
    get-device: "record<device: record<arn: string, name: string, manufacturer: string, model: string, modelId: string, formFactor: string, platform: string, os: string, cpu: record<frequency: string, architecture: string, clock: float>, resolution: record<width: int, height: int>, heapSize: int, memory: int, image: string, carrier: string, radio: string, remoteAccessEnabled: bool, remoteDebugEnabled: bool, fleetType: string, fleetName: string, instances: list<record>, availability: string>>"
    get-device-instance: "record<deviceInstance: record<arn: string, deviceArn: string, labels: list<string>, status: string, udid: string, instanceProfile: record<arn: string, packageCleanup: bool, excludeAppPackagesFromCleanup: list, rebootAfterUse: bool, name: string, description: string>>>"
    get-device-pool: "record<devicePool: record<arn: string, name: string, description: string, type: string, rules: list<record>, maxDevices: int>>"
    get-device-pool-compatibility: "record<compatibleDevices: table<device: record, compatible: bool, incompatibilityMessages: list>, incompatibleDevices: table<device: record, compatible: bool, incompatibilityMessages: list>>"
    get-instance-profile: "record<instanceProfile: record<arn: string, packageCleanup: bool, excludeAppPackagesFromCleanup: list<string>, rebootAfterUse: bool, name: string, description: string>>"
    get-job: "record<job: record<arn: string, name: string, type: string, created: string, status: string, result: string, started: string, stopped: string, counters: record<total: int, passed: int, failed: int, warned: int, errored: int, stopped: int, skipped: int>, message: string, device: record<arn: string, name: string, manufacturer: string, model: string, modelId: string, formFactor: string, platform: string, os: string, cpu: record, resolution: record, heapSize: int, memory: int, image: string, carrier: string, radio: string, remoteAccessEnabled: bool, remoteDebugEnabled: bool, fleetType: string, fleetName: string, instances: list, availability: string>, instanceArn: string, deviceMinutes: record<total: float, metered: float, unmetered: float>, videoEndpoint: string, videoCapture: bool>>"
    get-network-profile: "record<networkProfile: record<arn: string, name: string, description: string, type: string, uplinkBandwidthBits: int, downlinkBandwidthBits: int, uplinkDelayMs: int, downlinkDelayMs: int, uplinkJitterMs: int, downlinkJitterMs: int, uplinkLossPercent: int, downlinkLossPercent: int>>"
    get-offering-status: "record<current: record, nextPeriod: record, nextToken: string>"
    get-project: "record<project: record<arn: string, name: string, defaultJobTimeoutMinutes: int, created: string, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>"
    get-remote-access-session: "record<remoteAccessSession: record<arn: string, name: string, created: string, status: string, result: string, message: string, started: string, stopped: string, device: record<arn: string, name: string, manufacturer: string, model: string, modelId: string, formFactor: string, platform: string, os: string, cpu: record, resolution: record, heapSize: int, memory: int, image: string, carrier: string, radio: string, remoteAccessEnabled: bool, remoteDebugEnabled: bool, fleetType: string, fleetName: string, instances: list, availability: string>, instanceArn: string, remoteDebugEnabled: bool, remoteRecordEnabled: bool, remoteRecordAppArn: string, hostAddress: string, clientId: string, billingMethod: string, deviceMinutes: record<total: float, metered: float, unmetered: float>, endpoint: string, deviceUdid: string, interactionMode: string, skipAppResign: bool, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>"
    get-run: "record<run: record<arn: string, name: string, type: string, platform: string, created: string, status: string, result: string, started: string, stopped: string, counters: record<total: int, passed: int, failed: int, warned: int, errored: int, stopped: int, skipped: int>, message: string, totalJobs: int, completedJobs: int, billingMethod: string, deviceMinutes: record<total: float, metered: float, unmetered: float>, networkProfile: record<arn: string, name: string, description: string, type: string, uplinkBandwidthBits: int, downlinkBandwidthBits: int, uplinkDelayMs: int, downlinkDelayMs: int, uplinkJitterMs: int, downlinkJitterMs: int, uplinkLossPercent: int, downlinkLossPercent: int>, parsingResultUrl: string, resultCode: string, seed: int, appUpload: string, eventCount: int, jobTimeoutMinutes: int, devicePoolArn: string, locale: string, radios: record<wifi: bool, bluetooth: bool, nfc: bool, gps: bool>, location: record<latitude: float, longitude: float>, customerArtifactPaths: record<iosPaths: list, androidPaths: list, deviceHostPaths: list>, webUrl: string, skipAppResign: bool, testSpecArn: string, deviceSelectionResult: record<filters: list, matchedDevicesCount: int, maxDevices: int>, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>"
    get-suite: "record<suite: record<arn: string, name: string, type: string, created: string, status: string, result: string, started: string, stopped: string, counters: record<total: int, passed: int, failed: int, warned: int, errored: int, stopped: int, skipped: int>, message: string, deviceMinutes: record<total: float, metered: float, unmetered: float>>>"
    get-test: "record<test: record<arn: string, name: string, type: string, created: string, status: string, result: string, started: string, stopped: string, counters: record<total: int, passed: int, failed: int, warned: int, errored: int, stopped: int, skipped: int>, message: string, deviceMinutes: record<total: float, metered: float, unmetered: float>>>"
    get-test-grid-project: "record<testGridProject: record<arn: string, name: string, description: string, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>, created: string>>"
    get-test-grid-session: "record<testGridSession: record<arn: string, status: string, created: string, ended: string, billingMinutes: float, seleniumProperties: string>>"
    get-upload: "record<upload: record<arn: string, name: string, created: string, type: string, status: string, url: string, metadata: string, contentType: string, message: string, category: string>>"
    get-vpce-configuration: "record<vpceConfiguration: record<arn: string, vpceConfigurationName: string, vpceServiceName: string, serviceDnsName: string, vpceConfigurationDescription: string>>"
    install-to-remote-access-session: "record<appUpload: record<arn: string, name: string, created: string, type: string, status: string, url: string, metadata: string, contentType: string, message: string, category: string>>"
    list-artifacts: "record<artifacts: table<arn: string, name: string, type: string, extension: string, url: string>, nextToken: string>"
    list-device-instances: "record<deviceInstances: table<arn: string, deviceArn: string, labels: list, status: string, udid: string, instanceProfile: record>, nextToken: string>"
    list-device-pools: "record<devicePools: table<arn: string, name: string, description: string, type: string, rules: list, maxDevices: int>, nextToken: string>"
    list-devices: "record<devices: table<arn: string, name: string, manufacturer: string, model: string, modelId: string, formFactor: string, platform: string, os: string, cpu: record, resolution: record, heapSize: int, memory: int, image: string, carrier: string, radio: string, remoteAccessEnabled: bool, remoteDebugEnabled: bool, fleetType: string, fleetName: string, instances: list, availability: string>, nextToken: string>"
    list-instance-profiles: "record<instanceProfiles: table<arn: string, packageCleanup: bool, excludeAppPackagesFromCleanup: list, rebootAfterUse: bool, name: string, description: string>, nextToken: string>"
    list-jobs: "record<jobs: table<arn: string, name: string, type: string, created: string, status: string, result: string, started: string, stopped: string, counters: record, message: string, device: record, instanceArn: string, deviceMinutes: record, videoEndpoint: string, videoCapture: bool>, nextToken: string>"
    list-network-profiles: "record<networkProfiles: table<arn: string, name: string, description: string, type: string, uplinkBandwidthBits: int, downlinkBandwidthBits: int, uplinkDelayMs: int, downlinkDelayMs: int, uplinkJitterMs: int, downlinkJitterMs: int, uplinkLossPercent: int, downlinkLossPercent: int>, nextToken: string>"
    list-offering-promotions: "record<offeringPromotions: table<id: string, description: string>, nextToken: string>"
    list-offering-transactions: "record<offeringTransactions: table<offeringStatus: record, transactionId: string, offeringPromotionId: string, createdOn: string, cost: record>, nextToken: string>"
    list-offerings: "record<offerings: table<id: string, description: string, type: string, platform: string, recurringCharges: list>, nextToken: string>"
    list-projects: "record<projects: table<arn: string, name: string, defaultJobTimeoutMinutes: int, created: string, vpcConfig: record>, nextToken: string>"
    list-remote-access-sessions: "record<remoteAccessSessions: table<arn: string, name: string, created: string, status: string, result: string, message: string, started: string, stopped: string, device: record, instanceArn: string, remoteDebugEnabled: bool, remoteRecordEnabled: bool, remoteRecordAppArn: string, hostAddress: string, clientId: string, billingMethod: string, deviceMinutes: record, endpoint: string, deviceUdid: string, interactionMode: string, skipAppResign: bool, vpcConfig: record>, nextToken: string>"
    list-runs: "record<runs: table<arn: string, name: string, type: string, platform: string, created: string, status: string, result: string, started: string, stopped: string, counters: record, message: string, totalJobs: int, completedJobs: int, billingMethod: string, deviceMinutes: record, networkProfile: record, parsingResultUrl: string, resultCode: string, seed: int, appUpload: string, eventCount: int, jobTimeoutMinutes: int, devicePoolArn: string, locale: string, radios: record, location: record, customerArtifactPaths: record, webUrl: string, skipAppResign: bool, testSpecArn: string, deviceSelectionResult: record, vpcConfig: record>, nextToken: string>"
    list-samples: "record<samples: table<arn: string, type: string, url: string>, nextToken: string>"
    list-suites: "record<suites: table<arn: string, name: string, type: string, created: string, status: string, result: string, started: string, stopped: string, counters: record, message: string, deviceMinutes: record>, nextToken: string>"
    list-tags-for-resource: "record<Tags: table<Key: string, Value: string>>"
    list-test-grid-projects: "record<testGridProjects: table<arn: string, name: string, description: string, vpcConfig: record, created: string>, nextToken: string>"
    list-test-grid-session-actions: "record<actions: table<action: string, started: string, duration: int, statusCode: string, requestMethod: string>, nextToken: string>"
    list-test-grid-session-artifacts: "record<artifacts: table<filename: string, type: string, url: string>, nextToken: string>"
    list-test-grid-sessions: "record<testGridSessions: table<arn: string, status: string, created: string, ended: string, billingMinutes: float, seleniumProperties: string>, nextToken: string>"
    list-tests: "record<tests: table<arn: string, name: string, type: string, created: string, status: string, result: string, started: string, stopped: string, counters: record, message: string, deviceMinutes: record>, nextToken: string>"
    list-unique-problems: "record<uniqueProblems: record, nextToken: string>"
    list-uploads: "record<uploads: table<arn: string, name: string, created: string, type: string, status: string, url: string, metadata: string, contentType: string, message: string, category: string>, nextToken: string>"
    list-vpce-configurations: "record<vpceConfigurations: table<arn: string, vpceConfigurationName: string, vpceServiceName: string, serviceDnsName: string, vpceConfigurationDescription: string>, nextToken: string>"
    purchase-offering: "record<offeringTransaction: record<offeringStatus: record<type: string, offering: record, quantity: int, effectiveOn: string>, transactionId: string, offeringPromotionId: string, createdOn: string, cost: record<amount: float, currencyCode: string>>>"
    renew-offering: "record<offeringTransaction: record<offeringStatus: record<type: string, offering: record, quantity: int, effectiveOn: string>, transactionId: string, offeringPromotionId: string, createdOn: string, cost: record<amount: float, currencyCode: string>>>"
    schedule-run: "record<run: record<arn: string, name: string, type: string, platform: string, created: string, status: string, result: string, started: string, stopped: string, counters: record<total: int, passed: int, failed: int, warned: int, errored: int, stopped: int, skipped: int>, message: string, totalJobs: int, completedJobs: int, billingMethod: string, deviceMinutes: record<total: float, metered: float, unmetered: float>, networkProfile: record<arn: string, name: string, description: string, type: string, uplinkBandwidthBits: int, downlinkBandwidthBits: int, uplinkDelayMs: int, downlinkDelayMs: int, uplinkJitterMs: int, downlinkJitterMs: int, uplinkLossPercent: int, downlinkLossPercent: int>, parsingResultUrl: string, resultCode: string, seed: int, appUpload: string, eventCount: int, jobTimeoutMinutes: int, devicePoolArn: string, locale: string, radios: record<wifi: bool, bluetooth: bool, nfc: bool, gps: bool>, location: record<latitude: float, longitude: float>, customerArtifactPaths: record<iosPaths: list, androidPaths: list, deviceHostPaths: list>, webUrl: string, skipAppResign: bool, testSpecArn: string, deviceSelectionResult: record<filters: list, matchedDevicesCount: int, maxDevices: int>, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>"
    stop-job: "record<job: record<arn: string, name: string, type: string, created: string, status: string, result: string, started: string, stopped: string, counters: record<total: int, passed: int, failed: int, warned: int, errored: int, stopped: int, skipped: int>, message: string, device: record<arn: string, name: string, manufacturer: string, model: string, modelId: string, formFactor: string, platform: string, os: string, cpu: record, resolution: record, heapSize: int, memory: int, image: string, carrier: string, radio: string, remoteAccessEnabled: bool, remoteDebugEnabled: bool, fleetType: string, fleetName: string, instances: list, availability: string>, instanceArn: string, deviceMinutes: record<total: float, metered: float, unmetered: float>, videoEndpoint: string, videoCapture: bool>>"
    stop-remote-access-session: "record<remoteAccessSession: record<arn: string, name: string, created: string, status: string, result: string, message: string, started: string, stopped: string, device: record<arn: string, name: string, manufacturer: string, model: string, modelId: string, formFactor: string, platform: string, os: string, cpu: record, resolution: record, heapSize: int, memory: int, image: string, carrier: string, radio: string, remoteAccessEnabled: bool, remoteDebugEnabled: bool, fleetType: string, fleetName: string, instances: list, availability: string>, instanceArn: string, remoteDebugEnabled: bool, remoteRecordEnabled: bool, remoteRecordAppArn: string, hostAddress: string, clientId: string, billingMethod: string, deviceMinutes: record<total: float, metered: float, unmetered: float>, endpoint: string, deviceUdid: string, interactionMode: string, skipAppResign: bool, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>"
    stop-run: "record<run: record<arn: string, name: string, type: string, platform: string, created: string, status: string, result: string, started: string, stopped: string, counters: record<total: int, passed: int, failed: int, warned: int, errored: int, stopped: int, skipped: int>, message: string, totalJobs: int, completedJobs: int, billingMethod: string, deviceMinutes: record<total: float, metered: float, unmetered: float>, networkProfile: record<arn: string, name: string, description: string, type: string, uplinkBandwidthBits: int, downlinkBandwidthBits: int, uplinkDelayMs: int, downlinkDelayMs: int, uplinkJitterMs: int, downlinkJitterMs: int, uplinkLossPercent: int, downlinkLossPercent: int>, parsingResultUrl: string, resultCode: string, seed: int, appUpload: string, eventCount: int, jobTimeoutMinutes: int, devicePoolArn: string, locale: string, radios: record<wifi: bool, bluetooth: bool, nfc: bool, gps: bool>, location: record<latitude: float, longitude: float>, customerArtifactPaths: record<iosPaths: list, androidPaths: list, deviceHostPaths: list>, webUrl: string, skipAppResign: bool, testSpecArn: string, deviceSelectionResult: record<filters: list, matchedDevicesCount: int, maxDevices: int>, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>"
    tag-resource: "record"
    untag-resource: "record"
    update-device-instance: "record<deviceInstance: record<arn: string, deviceArn: string, labels: list<string>, status: string, udid: string, instanceProfile: record<arn: string, packageCleanup: bool, excludeAppPackagesFromCleanup: list, rebootAfterUse: bool, name: string, description: string>>>"
    update-device-pool: "record<devicePool: record<arn: string, name: string, description: string, type: string, rules: list<record>, maxDevices: int>>"
    update-instance-profile: "record<instanceProfile: record<arn: string, packageCleanup: bool, excludeAppPackagesFromCleanup: list<string>, rebootAfterUse: bool, name: string, description: string>>"
    update-network-profile: "record<networkProfile: record<arn: string, name: string, description: string, type: string, uplinkBandwidthBits: int, downlinkBandwidthBits: int, uplinkDelayMs: int, downlinkDelayMs: int, uplinkJitterMs: int, downlinkJitterMs: int, uplinkLossPercent: int, downlinkLossPercent: int>>"
    update-project: "record<project: record<arn: string, name: string, defaultJobTimeoutMinutes: int, created: string, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>"
    update-test-grid-project: "record<testGridProject: record<arn: string, name: string, description: string, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>, created: string>>"
    update-upload: "record<upload: record<arn: string, name: string, created: string, type: string, status: string, url: string, metadata: string, contentType: string, message: string, category: string>>"
    update-vpce-configuration: "record<vpceConfiguration: record<arn: string, vpceConfigurationName: string, vpceServiceName: string, serviceDnsName: string, vpceConfigurationDescription: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-device-pool" "create-instance-profile" "create-network-profile" "create-project" "create-remote-access-session" "create-test-grid-project" "create-test-grid-url" "create-upload" "create-vpce-configuration" "delete-device-pool" "delete-instance-profile" "delete-network-profile" "delete-project" "delete-remote-access-session" "delete-run" "delete-test-grid-project" "delete-upload" "delete-vpce-configuration" "get-account-settings" "get-device" "get-device-instance" "get-device-pool" "get-device-pool-compatibility" "get-instance-profile" "get-job" "get-network-profile" "get-offering-status" "get-project" "get-remote-access-session" "get-run" "get-suite" "get-test" "get-test-grid-project" "get-test-grid-session" "get-upload" "get-vpce-configuration" "install-to-remote-access-session" "list-artifacts" "list-device-instances" "list-device-pools" "list-devices" "list-instance-profiles" "list-jobs" "list-network-profiles" "list-offering-promotions" "list-offering-transactions" "list-offerings" "list-projects" "list-remote-access-sessions" "list-runs" "list-samples" "list-suites" "list-tags-for-resource" "list-test-grid-projects" "list-test-grid-session-actions" "list-test-grid-session-artifacts" "list-test-grid-sessions" "list-tests" "list-unique-problems" "list-uploads" "list-vpce-configurations" "purchase-offering" "renew-offering" "schedule-run" "stop-job" "stop-remote-access-session" "stop-run" "tag-resource" "untag-resource" "update-device-instance" "update-device-pool" "update-instance-profile" "update-network-profile" "update-project" "update-test-grid-project" "update-upload" "update-vpce-configuration" "commands"] | sort) } | get name | first)
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

# Creates a device pool.
#
# POST /
# Returns: record<devicePool: record<arn: string, name: string, description: string, type: string, rules: list<record>, maxDevices: int>>
# operationId: CreateDevicePool
export def "create-device-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  project_arn: string # The ARN of the project for the device pool.
  name: string # The device pool's name.
  --description: string # The device pool's description.
  rules: list # The device pool's rules. — item shape: {attribute?: "ARN"|"PLATFORM"|"FORM_FACTOR"|"MANUFACTURER"|"REMOTE_ACCESS_ENABLED"|"REMOTE_DEBUG_ENABLED"|"APPIUM_VERSION"|"INSTANCE_ARN"|"INSTANCE_LABELS"|"FLEET_TYPE"|"OS_VERSION"|"MODEL"|"AVAILABILITY", operator?: "EQUALS"|"LESS_THAN"|"LESS_THAN_OR_EQUALS"|"GREATER_THAN"|"GREATER_THAN_OR_EQUALS"|"IN"|"NOT_IN"|"CONTAINS", value?: string}
  --max-devices: int # The number of devices that Device Farm can add to your device pool. Device Farm adds devices that are available and meet the criteria that you assign for the rules parameter. Depending on how many devices meet these constraints, your device pool might contain fewer devices than the value for this parameter. By specifying the maximum number of devices, you can control the costs that you incur by running tests.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.CreateDevicePool"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectArn, var: project_arn}, {name: name, var: name}, {name: description, var: description}, {name: rules, var: rules}, {name: maxDevices, var: max_devices}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_arn: $project_arn, name: $name, description: $description, rules: $rules, max_devices: $max_devices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a profile that can be applied to one or more private fleet device instances.
#
# POST /
# Returns: record<instanceProfile: record<arn: string, packageCleanup: bool, excludeAppPackagesFromCleanup: list<string>, rebootAfterUse: bool, name: string, description: string>>
# operationId: CreateInstanceProfile
export def "create-instance-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of your instance profile.
  --description: string # The description of your instance profile.
  --package-cleanup: oneof<nothing, bool> # When set to true, Device Farm removes app packages after a test run. The default value is false for private devices.
  --exclude-app-packages-from-cleanup: list<string> # An array of strings that specifies the list of app packages that should not be cleaned up from the device after a test run. The list of packages is considered only if you set packageCleanup to true.
  --reboot-after-use: oneof<nothing, bool> # When set to true, Device Farm reboots the instance after a test run. The default value is true.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.CreateInstanceProfile"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: packageCleanup, var: package_cleanup}, {name: excludeAppPackagesFromCleanup, var: exclude_app_packages_from_cleanup}, {name: rebootAfterUse, var: reboot_after_use}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, package_cleanup: $package_cleanup, exclude_app_packages_from_cleanup: $exclude_app_packages_from_cleanup, reboot_after_use: $reboot_after_use
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a network profile.
#
# POST /
# Returns: record<networkProfile: record<arn: string, name: string, description: string, type: string, uplinkBandwidthBits: int, downlinkBandwidthBits: int, uplinkDelayMs: int, downlinkDelayMs: int, uplinkJitterMs: int, downlinkJitterMs: int, uplinkLossPercent: int, downlinkLossPercent: int>>
# operationId: CreateNetworkProfile
export def "create-network-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  project_arn: string # The Amazon Resource Name (ARN) of the project for which you want to create a network profile.
  name: string # The name for the new network profile.
  --description: string # The description of the network profile.
  --type: string@type-completer # The type of network profile to create. Valid values are listed here.
  --uplink-bandwidth-bits: int # The data throughput rate in bits per second, as an integer from 0 to 104857600.
  --downlink-bandwidth-bits: int # The data throughput rate in bits per second, as an integer from 0 to 104857600.
  --uplink-delay-ms: int # Delay time for all packets to destination in milliseconds as an integer from 0 to 2000.
  --downlink-delay-ms: int # Delay time for all packets to destination in milliseconds as an integer from 0 to 2000.
  --uplink-jitter-ms: int # Time variation in the delay of received packets in milliseconds as an integer from 0 to 2000.
  --downlink-jitter-ms: int # Time variation in the delay of received packets in milliseconds as an integer from 0 to 2000.
  --uplink-loss-percent: int # Proportion of transmitted packets that fail to arrive from 0 to 100 percent.
  --downlink-loss-percent: int # Proportion of received packets that fail to arrive from 0 to 100 percent.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.CreateNetworkProfile"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectArn, var: project_arn}, {name: name, var: name}, {name: description, var: description}, {name: type, var: type}, {name: uplinkBandwidthBits, var: uplink_bandwidth_bits}, {name: downlinkBandwidthBits, var: downlink_bandwidth_bits}, {name: uplinkDelayMs, var: uplink_delay_ms}, {name: downlinkDelayMs, var: downlink_delay_ms}, {name: uplinkJitterMs, var: uplink_jitter_ms}, {name: downlinkJitterMs, var: downlink_jitter_ms}, {name: uplinkLossPercent, var: uplink_loss_percent}, {name: downlinkLossPercent, var: downlink_loss_percent}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_arn: $project_arn, name: $name, description: $description, type: $type, uplink_bandwidth_bits: $uplink_bandwidth_bits, downlink_bandwidth_bits: $downlink_bandwidth_bits, uplink_delay_ms: $uplink_delay_ms, downlink_delay_ms: $downlink_delay_ms, uplink_jitter_ms: $uplink_jitter_ms, downlink_jitter_ms: $downlink_jitter_ms, uplink_loss_percent: $uplink_loss_percent, downlink_loss_percent: $downlink_loss_percent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a project.
#
# POST /
# Returns: record<project: record<arn: string, name: string, defaultJobTimeoutMinutes: int, created: string, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>
# operationId: CreateProject
export def "create-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The project's name.
  --default-job-timeout-minutes: int # Sets the execution timeout value (in minutes) for a project. All test runs in this project use the specified execution timeout value unless overridden when scheduling a run.
  --vpc-config: record # Contains the VPC configuration data necessary to interface with AWS Device Farm's services. — shape: {securityGroupIds: list<string>, subnetIds: list<string>, vpcId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.CreateProject"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: defaultJobTimeoutMinutes, var: default_job_timeout_minutes}, {name: vpcConfig, var: vpc_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, default_job_timeout_minutes: $default_job_timeout_minutes, vpc_config: $vpc_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Specifies and starts a remote access session.
#
# POST /
# Returns: record<remoteAccessSession: record<arn: string, name: string, created: string, status: string, result: string, message: string, started: string, stopped: string, device: record<arn: string, name: string, manufacturer: string, model: string, modelId: string, formFactor: string, platform: string, os: string, cpu: record, resolution: record, heapSize: int, memory: int, image: string, carrier: string, radio: string, remoteAccessEnabled: bool, remoteDebugEnabled: bool, fleetType: string, fleetName: string, instances: list, availability: string>, instanceArn: string, remoteDebugEnabled: bool, remoteRecordEnabled: bool, remoteRecordAppArn: string, hostAddress: string, clientId: string, billingMethod: string, deviceMinutes: record<total: float, metered: float, unmetered: float>, endpoint: string, deviceUdid: string, interactionMode: string, skipAppResign: bool, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>
# operationId: CreateRemoteAccessSession
export def "create-remote-access-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  project_arn: string # The Amazon Resource Name (ARN) of the project for which you want to create a remote access session.
  device_arn: string # The ARN of the device for which you want to create a remote access session.
  --instance-arn: string # The Amazon Resource Name (ARN) of the device instance for which you want to create a remote access session.
  --ssh-public-key: string # Ignored. The public key of the ssh key pair you want to use for connecting to remote devices in your remote debugging session. This key is required only if remoteDebugEnabled is set to true. Remote debugging is no longer supported (https://docs.aws.amazon.com/devicefarm/latest/developerguide/history.html).
  --remote-debug-enabled: oneof<nothing, bool> # Set to true if you want to access devices remotely for debugging in your remote access session. Remote debugging is no longer supported (https://docs.aws.amazon.com/devicefarm/latest/developerguide/history.html).
  --remote-record-enabled: oneof<nothing, bool> # Set to true to enable remote recording for the remote access session.
  --remote-record-app-arn: string # The Amazon Resource Name (ARN) for the app to be recorded in the remote access session.
  --name: string # The name of the remote access session to create.
  --client-id: string # Unique identifier for the client. If you want access to multiple devices on the same client, you should pass the same clientId value in each call to CreateRemoteAccessSession. This identifier is required only if remoteDebugEnabled is set to true. Remote debugging is no longer supported (https://docs.aws.amazon.com/devicefarm/latest/developerguide/history.html).
  --configuration: record # Configuration settings for a remote access session, including billing method. — shape: {billingMethod?: "METERED"|"UNMETERED", vpceConfigurationArns?: list<string>}
  --interaction-mode: string@interaction-mode-completer # The interaction mode of the remote access session. Valid values are: INTERACTIVE: You can interact with the iOS device by viewing, touching, and rotating the screen. You cannot run XCUITest framework-based tests in this mode. NO_VIDEO: You are connected to the device, but cannot interact with it or view the screen. This mode has the fastest test execution speed. You can run XCUITest framework-based tests in this mode. VIDEO_ONLY: You can view the screen, but cannot touch or rotate it. You can run XCUITest framework-based tests and watch the screen in this mode.
  --skip-app-resign: oneof<nothing, bool> # When set to true, for private devices, Device Farm does not sign your app again. For public devices, Device Farm always signs your apps again. For more information on how Device Farm modifies your uploads during tests, see Do you modify my app? (http://aws.amazon.com/device-farm/faqs/)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.CreateRemoteAccessSession"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectArn, var: project_arn}, {name: deviceArn, var: device_arn}, {name: instanceArn, var: instance_arn}, {name: sshPublicKey, var: ssh_public_key}, {name: remoteDebugEnabled, var: remote_debug_enabled}, {name: remoteRecordEnabled, var: remote_record_enabled}, {name: remoteRecordAppArn, var: remote_record_app_arn}, {name: name, var: name}, {name: clientId, var: client_id}, {name: configuration, var: configuration}, {name: interactionMode, var: interaction_mode}, {name: skipAppResign, var: skip_app_resign}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_arn: $project_arn, device_arn: $device_arn, instance_arn: $instance_arn, ssh_public_key: $ssh_public_key, remote_debug_enabled: $remote_debug_enabled, remote_record_enabled: $remote_record_enabled, remote_record_app_arn: $remote_record_app_arn, name: $name, client_id: $client_id, configuration: $configuration, interaction_mode: $interaction_mode, skip_app_resign: $skip_app_resign
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Selenium testing project. Projects are used to track TestGridSession instances.
#
# POST /
# Returns: record<testGridProject: record<arn: string, name: string, description: string, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>, created: string>>
# operationId: CreateTestGridProject
export def "create-test-grid-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # Human-readable name of the Selenium testing project.
  --description: string # Human-readable description of the project.
  --vpc-config: record # The VPC security groups and subnets that are attached to a project. — shape: {securityGroupIds: list<string>, subnetIds: list<string>, vpcId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.CreateTestGridProject"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: vpcConfig, var: vpc_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, vpc_config: $vpc_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a signed, short-term URL that can be passed to a Selenium RemoteWebDriver constructor.
#
# POST /
# Returns: record<url: string, expires: string>
# operationId: CreateTestGridUrl
export def "create-test-grid-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  project_arn: string # ARN (from CreateTestGridProject or ListTestGridProjects) to associate with the short-term URL.
  expires_in_seconds: int # Lifetime, in seconds, of the URL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.CreateTestGridUrl"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectArn, var: project_arn}, {name: expiresInSeconds, var: expires_in_seconds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_arn: $project_arn, expires_in_seconds: $expires_in_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads an app or test scripts.
#
# POST /
# Returns: record<upload: record<arn: string, name: string, created: string, type: string, status: string, url: string, metadata: string, contentType: string, message: string, category: string>>
# operationId: CreateUpload
export def "create-upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  project_arn: string # The ARN of the project for the upload.
  name: string # The upload's file name. The name should not contain any forward slashes (/). If you are uploading an iOS app, the file name must end with the .ipa extension. If you are uploading an Android app, the file name must end with the .apk extension. For all others, the file name must end with the .zip file extension.
  type: string@type-completer-1 # The upload's upload type. Must be one of the following values: ANDROID_APP IOS_APP WEB_APP EXTERNAL_DATA APPIUM_JAVA_JUNIT_TEST_PACKAGE APPIUM_JAVA_TESTNG_TEST_PACKAGE APPIUM_PYTHON_TEST_PACKAGE APPIUM_NODE_TEST_PACKAGE APPIUM_RUBY_TEST_PACKAGE APPIUM_WEB_JAVA_JUNIT_TEST_PACKAGE APPIUM_WEB_JAVA_TESTNG_TEST_PACKAGE APPIUM_WEB_PYTHON_TEST_PACKAGE APPIUM_WEB_NODE_TEST_PACKAGE APPIUM_WEB_RUBY_TEST_PACKAGE CALABASH_TEST_PACKAGE INSTRUMENTATION_TEST_PACKAGE UIAUTOMATION_TEST_PACKAGE UIAUTOMATOR_TEST_PACKAGE XCTEST_TEST_PACKAGE XCTEST_UI_TEST_PACKAGE APPIUM_JAVA_JUNIT_TEST_SPEC APPIUM_JAVA_TESTNG_TEST_SPEC APPIUM_PYTHON_TEST_SPEC APPIUM_NODE_TEST_SPEC APPIUM_RUBY_TEST_SPEC APPIUM_WEB_JAVA_JUNIT_TEST_SPEC APPIUM_WEB_JAVA_TESTNG_TEST_SPEC APPIUM_WEB_PYTHON_TEST_SPEC APPIUM_WEB_NODE_TEST_SPEC APPIUM_WEB_RUBY_TEST_SPEC INSTRUMENTATION_TEST_SPEC XCTEST_UI_TEST_SPEC If you call CreateUpload with WEB_APP specified, AWS Device Farm throws an ArgumentException error.
  --content-type: string # The upload's content type (for example, application/octet-stream).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.CreateUpload"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectArn, var: project_arn}, {name: name, var: name}, {name: type, var: type}, {name: contentType, var: content_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_arn: $project_arn, name: $name, type: $type, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
#
# POST /
# Returns: record<vpceConfiguration: record<arn: string, vpceConfigurationName: string, vpceServiceName: string, serviceDnsName: string, vpceConfigurationDescription: string>>
# operationId: CreateVPCEConfiguration
export def "create-vpce-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  vpce_configuration_name: string # The friendly name you give to your VPC endpoint configuration, to manage your configurations more easily.
  vpce_service_name: string # The name of the VPC endpoint service running in your AWS account that you want Device Farm to test.
  service_dns_name: string # The DNS name of the service running in your VPC that you want Device Farm to test.
  --vpce-configuration-description: string # An optional description that provides details about your VPC endpoint configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.CreateVPCEConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: vpceConfigurationName, var: vpce_configuration_name}, {name: vpceServiceName, var: vpce_service_name}, {name: serviceDnsName, var: service_dns_name}, {name: vpceConfigurationDescription, var: vpce_configuration_description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, vpce_configuration_name: $vpce_configuration_name, vpce_service_name: $vpce_service_name, service_dns_name: $service_dns_name, vpce_configuration_description: $vpce_configuration_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
#
# POST /
# Returns: record
# operationId: DeleteDevicePool
export def "delete-device-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # Represents the Amazon Resource Name (ARN) of the Device Farm device pool to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.DeleteDevicePool"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a profile that can be applied to one or more private device instances.
#
# POST /
# Returns: record
# operationId: DeleteInstanceProfile
export def "delete-instance-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of the instance profile you are requesting to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.DeleteInstanceProfile"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a network profile.
#
# POST /
# Returns: record
# operationId: DeleteNetworkProfile
export def "delete-network-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The ARN of the network profile to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.DeleteNetworkProfile"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an AWS Device Farm project, given the project ARN. Deleting this resource does not stop an in-progress run.
#
# POST /
# Returns: record
# operationId: DeleteProject
export def "delete-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # Represents the Amazon Resource Name (ARN) of the Device Farm project to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.DeleteProject"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a completed remote access session and its results.
#
# POST /
# Returns: record
# operationId: DeleteRemoteAccessSession
export def "delete-remote-access-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of the session for which you want to delete remote access.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.DeleteRemoteAccessSession"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the run, given the run ARN. Deleting this resource does not stop an in-progress run.
#
# POST /
# Returns: record
# operationId: DeleteRun
export def "delete-run" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) for the run to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.DeleteRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Selenium testing project and all content generated under it. You cannot undo this operation. You cannot delete a project if it has active sessions.
#
# POST /
# Returns: record
# operationId: DeleteTestGridProject
export def "delete-test-grid-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  project_arn: string # The ARN of the project to delete, from CreateTestGridProject or ListTestGridProjects.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.DeleteTestGridProject"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectArn, var: project_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_arn: $project_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an upload given the upload ARN.
#
# POST /
# Returns: record
# operationId: DeleteUpload
export def "delete-upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # Represents the Amazon Resource Name (ARN) of the Device Farm upload to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.DeleteUpload"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
#
# POST /
# Returns: record
# operationId: DeleteVPCEConfiguration
export def "delete-vpce-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of the VPC endpoint configuration you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.DeleteVPCEConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the number of unmetered iOS or unmetered Android devices that have been purchased by the account.
#
# POST /
# Returns: record<accountSettings: record<awsAccountNumber: string, unmeteredDevices: record, unmeteredRemoteAccessDevices: record, maxJobTimeoutMinutes: int, trialMinutes: record<total: float, remaining: float>, maxSlots: record, defaultJobTimeoutMinutes: int, skipAppResign: bool>>
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetAccountSettings"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a unique device type.
#
# POST /
# Returns: record<device: record<arn: string, name: string, manufacturer: string, model: string, modelId: string, formFactor: string, platform: string, os: string, cpu: record<frequency: string, architecture: string, clock: float>, resolution: record<width: int, height: int>, heapSize: int, memory: int, image: string, carrier: string, radio: string, remoteAccessEnabled: bool, remoteDebugEnabled: bool, fleetType: string, fleetName: string, instances: list<record>, availability: string>>
# operationId: GetDevice
export def "get-device" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The device type's ARN.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetDevice"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a device instance that belongs to a private device fleet.
#
# POST /
# Returns: record<deviceInstance: record<arn: string, deviceArn: string, labels: list<string>, status: string, udid: string, instanceProfile: record<arn: string, packageCleanup: bool, excludeAppPackagesFromCleanup: list, rebootAfterUse: bool, name: string, description: string>>>
# operationId: GetDeviceInstance
export def "get-device-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of the instance you're requesting information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetDeviceInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a device pool.
#
# POST /
# Returns: record<devicePool: record<arn: string, name: string, description: string, type: string, rules: list<record>, maxDevices: int>>
# operationId: GetDevicePool
export def "get-device-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The device pool's ARN.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetDevicePool"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about compatibility with a device pool.
#
# POST /
# Returns: record<compatibleDevices: table<device: record, compatible: bool, incompatibilityMessages: list>, incompatibleDevices: table<device: record, compatible: bool, incompatibilityMessages: list>>
# operationId: GetDevicePoolCompatibility
export def "get-device-pool-compatibility" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  device_pool_arn: string # The device pool's ARN.
  --app-arn: string # The ARN of the app that is associated with the specified device pool.
  --test-type: string@test-type-completer # The test type for the specified device pool. Allowed values include the following: BUILTIN_FUZZ. BUILTIN_EXPLORER. For Android, an app explorer that traverses an Android app, interacting with it and capturing screenshots at the same time. APPIUM_JAVA_JUNIT. APPIUM_JAVA_TESTNG. APPIUM_PYTHON. APPIUM_NODE. APPIUM_RUBY. APPIUM_WEB_JAVA_JUNIT. APPIUM_WEB_JAVA_TESTNG. APPIUM_WEB_PYTHON. APPIUM_WEB_NODE. APPIUM_WEB_RUBY. CALABASH. INSTRUMENTATION. UIAUTOMATION. UIAUTOMATOR. XCTEST. XCTEST_UI.
  --test: record # Represents test settings. This data structure is passed in as the test parameter to ScheduleRun. For an example of the JSON request syntax, see ScheduleRun. — shape: {type: "BUILTIN_FUZZ"|"BUILTIN_EXPLORER"|"WEB_PERFORMANCE_PROFILE"|"APPIUM_JAVA_JUNIT"|"APPIUM_JAVA_TESTNG"|"APPIUM_PYTHON"|"APPIUM_NODE"|"APPIUM_RUBY"|"APPIUM_WEB_JAVA_JUNIT"|"APPIUM_WEB_JAVA_TESTNG"|"APPIUM_WEB_PYTHON"|"APPIUM_WEB_NODE"|"APPIUM_WEB_RUBY"|"CALABASH"|"INSTRUMENTATION"|"UIAUTOMATION"|"UIAUTOMATOR"|"XCTEST"|"XCTEST_UI"|"REMOTE_ACCESS_RECORD"|"REMOTE_ACCESS_REPLAY", testPackageArn?: string, testSpecArn?: string, filter?: string, parameters?: record}
  --configuration: record # Represents the settings for a run. Includes things like location, radio states, auxiliary apps, and network profiles. — shape: {extraDataPackageArn?: string, networkProfileArn?: string, locale?: string, location?: record, vpceConfigurationArns?: list<string>, customerArtifactPaths?: record, radios?: record, auxiliaryApps?: list<string>, billingMethod?: "METERED"|"UNMETERED"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetDevicePoolCompatibility"}]
    body: {content_type: "application/json", kind: json, fields: [{name: devicePoolArn, var: device_pool_arn}, {name: appArn, var: app_arn}, {name: testType, var: test_type}, {name: test, var: test}, {name: configuration, var: configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, device_pool_arn: $device_pool_arn, app_arn: $app_arn, test_type: $test_type, test: $test, configuration: $configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the specified instance profile.
#
# POST /
# Returns: record<instanceProfile: record<arn: string, packageCleanup: bool, excludeAppPackagesFromCleanup: list<string>, rebootAfterUse: bool, name: string, description: string>>
# operationId: GetInstanceProfile
export def "get-instance-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of an instance profile.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetInstanceProfile"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a job.
#
# POST /
# Returns: record<job: record<arn: string, name: string, type: string, created: string, status: string, result: string, started: string, stopped: string, counters: record<total: int, passed: int, failed: int, warned: int, errored: int, stopped: int, skipped: int>, message: string, device: record<arn: string, name: string, manufacturer: string, model: string, modelId: string, formFactor: string, platform: string, os: string, cpu: record, resolution: record, heapSize: int, memory: int, image: string, carrier: string, radio: string, remoteAccessEnabled: bool, remoteDebugEnabled: bool, fleetType: string, fleetName: string, instances: list, availability: string>, instanceArn: string, deviceMinutes: record<total: float, metered: float, unmetered: float>, videoEndpoint: string, videoCapture: bool>>
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
  --x-amz-target: string@x-amz-target-completer-24 # required
  arn: string # The job's ARN.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a network profile.
#
# POST /
# Returns: record<networkProfile: record<arn: string, name: string, description: string, type: string, uplinkBandwidthBits: int, downlinkBandwidthBits: int, uplinkDelayMs: int, downlinkDelayMs: int, uplinkJitterMs: int, downlinkJitterMs: int, uplinkLossPercent: int, downlinkLossPercent: int>>
# operationId: GetNetworkProfile
export def "get-network-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The ARN of the network profile to return information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetNetworkProfile"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a NotEligible error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact aws-devicefarm-support@amazon.com (mailto:aws-devicefarm-support@amazon.com).
#
# POST /
# Returns: record<current: record, nextPeriod: record, nextToken: string>
# operationId: GetOfferingStatus
export def "get-offering-status" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  --body-next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetOfferingStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a project.
#
# POST /
# Returns: record<project: record<arn: string, name: string, defaultJobTimeoutMinutes: int, created: string, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>
# operationId: GetProject
export def "get-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The project's ARN.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetProject"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a link to a currently running remote access session.
#
# POST /
# Returns: record<remoteAccessSession: record<arn: string, name: string, created: string, status: string, result: string, message: string, started: string, stopped: string, device: record<arn: string, name: string, manufacturer: string, model: string, modelId: string, formFactor: string, platform: string, os: string, cpu: record, resolution: record, heapSize: int, memory: int, image: string, carrier: string, radio: string, remoteAccessEnabled: bool, remoteDebugEnabled: bool, fleetType: string, fleetName: string, instances: list, availability: string>, instanceArn: string, remoteDebugEnabled: bool, remoteRecordEnabled: bool, remoteRecordAppArn: string, hostAddress: string, clientId: string, billingMethod: string, deviceMinutes: record<total: float, metered: float, unmetered: float>, endpoint: string, deviceUdid: string, interactionMode: string, skipAppResign: bool, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>
# operationId: GetRemoteAccessSession
export def "get-remote-access-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of the remote access session about which you want to get session information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetRemoteAccessSession"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a run.
#
# POST /
# Returns: record<run: record<arn: string, name: string, type: string, platform: string, created: string, status: string, result: string, started: string, stopped: string, counters: record<total: int, passed: int, failed: int, warned: int, errored: int, stopped: int, skipped: int>, message: string, totalJobs: int, completedJobs: int, billingMethod: string, deviceMinutes: record<total: float, metered: float, unmetered: float>, networkProfile: record<arn: string, name: string, description: string, type: string, uplinkBandwidthBits: int, downlinkBandwidthBits: int, uplinkDelayMs: int, downlinkDelayMs: int, uplinkJitterMs: int, downlinkJitterMs: int, uplinkLossPercent: int, downlinkLossPercent: int>, parsingResultUrl: string, resultCode: string, seed: int, appUpload: string, eventCount: int, jobTimeoutMinutes: int, devicePoolArn: string, locale: string, radios: record<wifi: bool, bluetooth: bool, nfc: bool, gps: bool>, location: record<latitude: float, longitude: float>, customerArtifactPaths: record<iosPaths: list, androidPaths: list, deviceHostPaths: list>, webUrl: string, skipAppResign: bool, testSpecArn: string, deviceSelectionResult: record<filters: list, matchedDevicesCount: int, maxDevices: int>, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>
# operationId: GetRun
export def "get-run" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The run's ARN.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a suite.
#
# POST /
# Returns: record<suite: record<arn: string, name: string, type: string, created: string, status: string, result: string, started: string, stopped: string, counters: record<total: int, passed: int, failed: int, warned: int, errored: int, stopped: int, skipped: int>, message: string, deviceMinutes: record<total: float, metered: float, unmetered: float>>>
# operationId: GetSuite
export def "get-suite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The suite's ARN.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetSuite"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a test.
#
# POST /
# Returns: record<test: record<arn: string, name: string, type: string, created: string, status: string, result: string, started: string, stopped: string, counters: record<total: int, passed: int, failed: int, warned: int, errored: int, stopped: int, skipped: int>, message: string, deviceMinutes: record<total: float, metered: float, unmetered: float>>>
# operationId: GetTest
export def "get-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The test's ARN.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetTest"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a Selenium testing project.
#
# POST /
# Returns: record<testGridProject: record<arn: string, name: string, description: string, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>, created: string>>
# operationId: GetTestGridProject
export def "get-test-grid-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  project_arn: string # The ARN of the Selenium testing project, from either CreateTestGridProject or ListTestGridProjects.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetTestGridProject"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectArn, var: project_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_arn: $project_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A session is an instance of a browser created through a RemoteWebDriver with the URL from CreateTestGridUrlResult$url. You can use the following to look up sessions: The session ARN (GetTestGridSessionRequest$sessionArn). The project ARN and a session ID (GetTestGridSessionRequest$projectArn and GetTestGridSessionRequest$sessionId).
#
# POST /
# Returns: record<testGridSession: record<arn: string, status: string, created: string, ended: string, billingMinutes: float, seleniumProperties: string>>
# operationId: GetTestGridSession
export def "get-test-grid-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --project-arn: string # The ARN for the project that this session belongs to. See CreateTestGridProject and ListTestGridProjects.
  --session-id: string # An ID associated with this session.
  --session-arn: string # An ARN that uniquely identifies a TestGridSession.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetTestGridSession"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectArn, var: project_arn}, {name: sessionId, var: session_id}, {name: sessionArn, var: session_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_arn: $project_arn, session_id: $session_id, session_arn: $session_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about an upload.
#
# POST /
# Returns: record<upload: record<arn: string, name: string, created: string, type: string, status: string, url: string, metadata: string, contentType: string, message: string, category: string>>
# operationId: GetUpload
export def "get-upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The upload's ARN.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetUpload"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
#
# POST /
# Returns: record<vpceConfiguration: record<arn: string, vpceConfigurationName: string, vpceServiceName: string, serviceDnsName: string, vpceConfigurationDescription: string>>
# operationId: GetVPCEConfiguration
export def "get-vpce-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of the VPC endpoint configuration you want to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.GetVPCEConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
#
# POST /
# Returns: record<appUpload: record<arn: string, name: string, created: string, type: string, status: string, url: string, metadata: string, contentType: string, message: string, category: string>>
# operationId: InstallToRemoteAccessSession
export def "install-to-remote-access-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  remote_access_session_arn: string # The Amazon Resource Name (ARN) of the remote access session about which you are requesting information.
  app_arn: string # The ARN of the app about which you are requesting information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.InstallToRemoteAccessSession"}]
    body: {content_type: "application/json", kind: json, fields: [{name: remoteAccessSessionArn, var: remote_access_session_arn}, {name: appArn, var: app_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, remote_access_session_arn: $remote_access_session_arn, app_arn: $app_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about artifacts.
#
# POST /
# Returns: record<artifacts: table<arn: string, name: string, type: string, extension: string, url: string>, nextToken: string>
# operationId: ListArtifacts
export def "list-artifacts" [
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
  --x-amz-target: string@x-amz-target-completer-37 # required
  arn: string # The run, job, suite, or test ARN.
  type: string@type-completer-2 # The artifacts' type. Allowed values include: FILE LOG SCREENSHOT
  --body-next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListArtifacts"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: type, var: type}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, type: $type, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the private device instances associated with one or more AWS accounts.
#
# POST /
# Returns: record<deviceInstances: table<arn: string, deviceArn: string, labels: list, status: string, udid: string, instanceProfile: record>, nextToken: string>
# operationId: ListDeviceInstances
export def "list-device-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --max-results: int # An integer that specifies the maximum number of items you want to return in the API response.
  --next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListDeviceInstances"}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about device pools.
#
# POST /
# Returns: record<devicePools: table<arn: string, name: string, description: string, type: string, rules: list, maxDevices: int>, nextToken: string>
# operationId: ListDevicePools
export def "list-device-pools" [
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
  --x-amz-target: string@x-amz-target-completer-39 # required
  arn: string # The project ARN.
  --type: string@type-completer # The device pools' type. Allowed values include: CURATED: A device pool that is created and managed by AWS Device Farm. PRIVATE: A device pool that is created and managed by the device pool developer.
  --body-next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListDevicePools"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: type, var: type}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, type: $type, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about unique device types.
#
# POST /
# Returns: record<devices: table<arn: string, name: string, manufacturer: string, model: string, modelId: string, formFactor: string, platform: string, os: string, cpu: record, resolution: record, heapSize: int, memory: int, image: string, carrier: string, radio: string, remoteAccessEnabled: bool, remoteDebugEnabled: bool, fleetType: string, fleetName: string, instances: list, availability: string>, nextToken: string>
# operationId: ListDevices
export def "list-devices" [
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
  --x-amz-target: string@x-amz-target-completer-40 # required
  --arn: string # The Amazon Resource Name (ARN) of the project.
  --body-next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. (spec name: nextToken)
  --filters: list # Used to select a set of devices. A filter is made up of an attribute, an operator, and one or more values. Attribute: The aspect of a device such as platform or model used as the selection criteria in a device filter. Allowed values include: ARN: The Amazon Resource Name (ARN) of the device (for example, arn:aws:devicefarm:us-west-2::device:12345Example). PLATFORM: The device platform. Valid values are ANDROID or IOS. OS_VERSION: The operating system version (for example, 10.3.2). MODEL: The device model (for example, iPad 5th Gen). AVAILABILITY: The current availability of the device. Valid values are AVAILABLE, HIGHLY_AVAILABLE, BUSY, or TEMPORARY_NOT_AVAILABLE. FORM_FACTOR: The device form factor. Valid values are PHONE or TABLET. MANUFACTURER: The device manufacturer (for example, Apple). REMOTE_ACCESS_ENABLED: Whether the device is enabled for remote access. Valid values are TRUE or FALSE. REMOTE_DEBUG_ENABLED: Whether the device is enabled for remote debugging. Valid values are TRUE or FALSE. Because remote debugging is no longer supported (https://docs.aws.amazon.com/devicefarm/latest/developerguide/history.html), this attribute is ignored. INSTANCE_ARN: The Amazon Resource Name (ARN) of the device instance. INSTANCE_LABELS: The label of the device instance. FLEET_TYPE: The fleet type. Valid values are PUBLIC or PRIVATE. Operator: The filter operator. The EQUALS operator is available for every attribute except INSTANCE_LABELS. The CONTAINS operator is available for the INSTANCE_LABELS and MODEL attributes. The IN and NOT_IN operators are available for the ARN, OS_VERSION, MODEL, MANUFACTURER, and INSTANCE_ARN attributes. The LESS_THAN, GREATER_THAN, LESS_THAN_OR_EQUALS, and GREATER_THAN_OR_EQUALS operators are also available for the OS_VERSION attribute. Values: An array of one or more filter values. The IN and NOT_IN operators take a values array that has one or more elements. The other operators require an array with a single element. In a request, the AVAILABILITY attribute takes the following values: AVAILABLE, HIGHLY_AVAILABLE, BUSY, or TEMPORARY_NOT_AVAILABLE. — item shape: {attribute: "ARN"|"PLATFORM"|"OS_VERSION"|"MODEL"|"AVAILABILITY"|"FORM_FACTOR"|"MANUFACTURER"|"REMOTE_ACCESS_ENABLED"|"REMOTE_DEBUG_ENABLED"|"INSTANCE_ARN"|"INSTANCE_LABELS"|"FLEET_TYPE", operator: "EQUALS"|"LESS_THAN"|"LESS_THAN_OR_EQUALS"|"GREATER_THAN"|"GREATER_THAN_OR_EQUALS"|"IN"|"NOT_IN"|"CONTAINS", values: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListDevices"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: nextToken, var: body_next_token}, {name: filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, body_next_token: $body_next_token, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about all the instance profiles in an AWS account.
#
# POST /
# Returns: record<instanceProfiles: table<arn: string, packageCleanup: bool, excludeAppPackagesFromCleanup: list, rebootAfterUse: bool, name: string, description: string>, nextToken: string>
# operationId: ListInstanceProfiles
export def "list-instance-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --max-results: int # An integer that specifies the maximum number of items you want to return in the API response.
  --next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListInstanceProfiles"}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about jobs for a given test run.
#
# POST /
# Returns: record<jobs: table<arn: string, name: string, type: string, created: string, status: string, result: string, started: string, stopped: string, counters: record, message: string, device: record, instanceArn: string, deviceMinutes: record, videoEndpoint: string, videoCapture: bool>, nextToken: string>
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
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-42 # required
  arn: string # The run's Amazon Resource Name (ARN).
  --body-next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of available network profiles.
#
# POST /
# Returns: record<networkProfiles: table<arn: string, name: string, description: string, type: string, uplinkBandwidthBits: int, downlinkBandwidthBits: int, uplinkDelayMs: int, downlinkDelayMs: int, uplinkJitterMs: int, downlinkJitterMs: int, uplinkLossPercent: int, downlinkLossPercent: int>, nextToken: string>
# operationId: ListNetworkProfiles
export def "list-network-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of the project for which you want to list network profiles.
  --type: string@type-completer # The type of network profile to return information about. Valid values are listed here.
  --next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListNetworkProfiles"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: type, var: type}, {name: nextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, type: $type, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a NotEligible error if the caller is not permitted to invoke the operation. Contact aws-devicefarm-support@amazon.com (mailto:aws-devicefarm-support@amazon.com) if you must be able to invoke this operation.
#
# POST /
# Returns: record<offeringPromotions: table<id: string, description: string>, nextToken: string>
# operationId: ListOfferingPromotions
export def "list-offering-promotions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListOfferingPromotions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a NotEligible error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact aws-devicefarm-support@amazon.com (mailto:aws-devicefarm-support@amazon.com).
#
# POST /
# Returns: record<offeringTransactions: table<offeringStatus: record, transactionId: string, offeringPromotionId: string, createdOn: string, cost: record>, nextToken: string>
# operationId: ListOfferingTransactions
export def "list-offering-transactions" [
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
  --x-amz-target: string@x-amz-target-completer-45 # required
  --body-next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListOfferingTransactions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a NotEligible error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact aws-devicefarm-support@amazon.com (mailto:aws-devicefarm-support@amazon.com).
#
# POST /
# Returns: record<offerings: table<id: string, description: string, type: string, platform: string, recurringCharges: list>, nextToken: string>
# operationId: ListOfferings
export def "list-offerings" [
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
  --body-next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListOfferings"}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about projects.
#
# POST /
# Returns: record<projects: table<arn: string, name: string, defaultJobTimeoutMinutes: int, created: string, vpcConfig: record>, nextToken: string>
# operationId: ListProjects
export def "list-projects" [
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
  --arn: string # Optional. If no Amazon Resource Name (ARN) is specified, then AWS Device Farm returns a list of all projects for the AWS account. You can also specify a project ARN.
  --body-next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListProjects"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all currently running remote access sessions.
#
# POST /
# Returns: record<remoteAccessSessions: table<arn: string, name: string, created: string, status: string, result: string, message: string, started: string, stopped: string, device: record, instanceArn: string, remoteDebugEnabled: bool, remoteRecordEnabled: bool, remoteRecordAppArn: string, hostAddress: string, clientId: string, billingMethod: string, deviceMinutes: record, endpoint: string, deviceUdid: string, interactionMode: string, skipAppResign: bool, vpcConfig: record>, nextToken: string>
# operationId: ListRemoteAccessSessions
export def "list-remote-access-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of the project about which you are requesting information.
  --next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListRemoteAccessSessions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: nextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about runs, given an AWS Device Farm project ARN.
#
# POST /
# Returns: record<runs: table<arn: string, name: string, type: string, platform: string, created: string, status: string, result: string, started: string, stopped: string, counters: record, message: string, totalJobs: int, completedJobs: int, billingMethod: string, deviceMinutes: record, networkProfile: record, parsingResultUrl: string, resultCode: string, seed: int, appUpload: string, eventCount: int, jobTimeoutMinutes: int, devicePoolArn: string, locale: string, radios: record, location: record, customerArtifactPaths: record, webUrl: string, skipAppResign: bool, testSpecArn: string, deviceSelectionResult: record, vpcConfig: record>, nextToken: string>
# operationId: ListRuns
export def "list-runs" [
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
  --x-amz-target: string@x-amz-target-completer-49 # required
  arn: string # The Amazon Resource Name (ARN) of the project for which you want to list runs.
  --body-next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListRuns"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about samples, given an AWS Device Farm job ARN.
#
# POST /
# Returns: record<samples: table<arn: string, type: string, url: string>, nextToken: string>
# operationId: ListSamples
export def "list-samples" [
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
  arn: string # The Amazon Resource Name (ARN) of the job used to list samples.
  --body-next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListSamples"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about test suites for a given job.
#
# POST /
# Returns: record<suites: table<arn: string, name: string, type: string, created: string, status: string, result: string, started: string, stopped: string, counters: record, message: string, deviceMinutes: record>, nextToken: string>
# operationId: ListSuites
export def "list-suites" [
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
  arn: string # The job's Amazon Resource Name (ARN).
  --body-next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListSuites"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the tags for an AWS Device Farm resource.
#
# POST /
# Returns: record<Tags: table<Key: string, Value: string>>
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
  resource_arn: string # The Amazon Resource Name (ARN) of the resource or resources for which to list tags. You can associate tags with the following Device Farm resources: PROJECT, RUN, NETWORK_PROFILE, INSTANCE_PROFILE, DEVICE_INSTANCE, SESSION, DEVICE_POOL, DEVICE, and VPCE_CONFIGURATION.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceARN, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of all Selenium testing projects in your account.
#
# POST /
# Returns: record<testGridProjects: table<arn: string, name: string, description: string, vpcConfig: record, created: string>, nextToken: string>
# operationId: ListTestGridProjects
export def "list-test-grid-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-result: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-53 # required
  --body-max-result: int # Return no more than this number of results. (spec name: maxResult)
  --body-next-token: string # From a response, used to continue a paginated listing. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResult, var: max_result}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListTestGridProjects"}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResult, var: body_max_result}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_result: $max_result, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_result: $body_max_result, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the actions taken in a TestGridSession.
#
# POST /
# Returns: record<actions: table<action: string, started: string, duration: int, statusCode: string, requestMethod: string>, nextToken: string>
# operationId: ListTestGridSessionActions
export def "list-test-grid-session-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-result: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-54 # required
  session_arn: string # The ARN of the session to retrieve.
  --body-max-result: int # The maximum number of sessions to return per response. (spec name: maxResult)
  --body-next-token: string # Pagination token. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResult, var: max_result}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListTestGridSessionActions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: sessionArn, var: session_arn}, {name: maxResult, var: body_max_result}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_result: $max_result, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, session_arn: $session_arn, body_max_result: $body_max_result, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of artifacts created during the session.
#
# POST /
# Returns: record<artifacts: table<filename: string, type: string, url: string>, nextToken: string>
# operationId: ListTestGridSessionArtifacts
export def "list-test-grid-session-artifacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-result: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-55 # required
  session_arn: string # The ARN of a TestGridSession.
  --type: string@type-completer-3 # Limit results to a specified type of artifact.
  --body-max-result: int # The maximum number of results to be returned by a request. (spec name: maxResult)
  --body-next-token: string # Pagination token. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResult, var: max_result}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListTestGridSessionArtifacts"}]
    body: {content_type: "application/json", kind: json, fields: [{name: sessionArn, var: session_arn}, {name: type, var: type}, {name: maxResult, var: body_max_result}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_result: $max_result, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, session_arn: $session_arn, type: $type, body_max_result: $body_max_result, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of sessions for a TestGridProject.
#
# POST /
# Returns: record<testGridSessions: table<arn: string, status: string, created: string, ended: string, billingMinutes: float, seleniumProperties: string>, nextToken: string>
# operationId: ListTestGridSessions
export def "list-test-grid-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-result: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-56 # required
  project_arn: string # ARN of a TestGridProject.
  --status: string@status-completer # Return only sessions in this state.
  --creation-time-after: string # Return only sessions created after this time. (format: date-time)
  --creation-time-before: string # Return only sessions created before this time. (format: date-time)
  --end-time-after: string # Return only sessions that ended after this time. (format: date-time)
  --end-time-before: string # Return only sessions that ended before this time. (format: date-time)
  --body-max-result: int # Return only this many results at a time. (spec name: maxResult)
  --body-next-token: string # Pagination token. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResult, var: max_result}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListTestGridSessions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectArn, var: project_arn}, {name: status, var: status}, {name: creationTimeAfter, var: creation_time_after}, {name: creationTimeBefore, var: creation_time_before}, {name: endTimeAfter, var: end_time_after}, {name: endTimeBefore, var: end_time_before}, {name: maxResult, var: body_max_result}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_result: $max_result, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_arn: $project_arn, status: $status, creation_time_after: $creation_time_after, creation_time_before: $creation_time_before, end_time_after: $end_time_after, end_time_before: $end_time_before, body_max_result: $body_max_result, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about tests in a given test suite.
#
# POST /
# Returns: record<tests: table<arn: string, name: string, type: string, created: string, status: string, result: string, started: string, stopped: string, counters: record, message: string, deviceMinutes: record>, nextToken: string>
# operationId: ListTests
export def "list-tests" [
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
  arn: string # The test suite's Amazon Resource Name (ARN).
  --body-next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListTests"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about unique problems, such as exceptions or crashes. Unique problems are defined as a single instance of an error across a run, job, or suite. For example, if a call in your application consistently raises an exception (OutOfBoundsException in MyActivity.java:386), ListUniqueProblems returns a single entry instead of many individual entries for that exception.
#
# POST /
# Returns: record<uniqueProblems: record, nextToken: string>
# operationId: ListUniqueProblems
export def "list-unique-problems" [
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
  arn: string # The unique problems' ARNs.
  --body-next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListUniqueProblems"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about uploads, given an AWS Device Farm project ARN.
#
# POST /
# Returns: record<uploads: table<arn: string, name: string, created: string, type: string, status: string, url: string, metadata: string, contentType: string, message: string, category: string>, nextToken: string>
# operationId: ListUploads
export def "list-uploads" [
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
  --x-amz-target: string@x-amz-target-completer-59 # required
  arn: string # The Amazon Resource Name (ARN) of the project for which you want to list uploads.
  --type: string@type-completer-1 # The type of upload. Must be one of the following values: ANDROID_APP IOS_APP WEB_APP EXTERNAL_DATA APPIUM_JAVA_JUNIT_TEST_PACKAGE APPIUM_JAVA_TESTNG_TEST_PACKAGE APPIUM_PYTHON_TEST_PACKAGE APPIUM_NODE_TEST_PACKAGE APPIUM_RUBY_TEST_PACKAGE APPIUM_WEB_JAVA_JUNIT_TEST_PACKAGE APPIUM_WEB_JAVA_TESTNG_TEST_PACKAGE APPIUM_WEB_PYTHON_TEST_PACKAGE APPIUM_WEB_NODE_TEST_PACKAGE APPIUM_WEB_RUBY_TEST_PACKAGE CALABASH_TEST_PACKAGE INSTRUMENTATION_TEST_PACKAGE UIAUTOMATION_TEST_PACKAGE UIAUTOMATOR_TEST_PACKAGE XCTEST_TEST_PACKAGE XCTEST_UI_TEST_PACKAGE APPIUM_JAVA_JUNIT_TEST_SPEC APPIUM_JAVA_TESTNG_TEST_SPEC APPIUM_PYTHON_TEST_SPEC APPIUM_NODE_TEST_SPEC APPIUM_RUBY_TEST_SPEC APPIUM_WEB_JAVA_JUNIT_TEST_SPEC APPIUM_WEB_JAVA_TESTNG_TEST_SPEC APPIUM_WEB_PYTHON_TEST_SPEC APPIUM_WEB_NODE_TEST_SPEC APPIUM_WEB_RUBY_TEST_SPEC INSTRUMENTATION_TEST_SPEC XCTEST_UI_TEST_SPEC
  --body-next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListUploads"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: type, var: type}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, type: $type, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
#
# POST /
# Returns: record<vpceConfigurations: table<arn: string, vpceConfigurationName: string, vpceServiceName: string, serviceDnsName: string, vpceConfigurationDescription: string>, nextToken: string>
# operationId: ListVPCEConfigurations
export def "list-vpce-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --max-results: int # An integer that specifies the maximum number of items you want to return in the API response.
  --next-token: string # An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ListVPCEConfigurations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a NotEligible error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact aws-devicefarm-support@amazon.com (mailto:aws-devicefarm-support@amazon.com).
#
# POST /
# Returns: record<offeringTransaction: record<offeringStatus: record<type: string, offering: record, quantity: int, effectiveOn: string>, transactionId: string, offeringPromotionId: string, createdOn: string, cost: record<amount: float, currencyCode: string>>>
# operationId: PurchaseOffering
export def "purchase-offering" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  offering_id: string # The ID of the offering.
  quantity: int # The number of device slots to purchase in an offering request.
  --offering-promotion-id: string # The ID of the offering promotion to be applied to the purchase.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.PurchaseOffering"}]
    body: {content_type: "application/json", kind: json, fields: [{name: offeringId, var: offering_id}, {name: quantity, var: quantity}, {name: offeringPromotionId, var: offering_promotion_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, offering_id: $offering_id, quantity: $quantity, offering_promotion_id: $offering_promotion_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Explicitly sets the quantity of devices to renew for an offering, starting from the effectiveDate of the next period. The API returns a NotEligible error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact aws-devicefarm-support@amazon.com (mailto:aws-devicefarm-support@amazon.com).
#
# POST /
# Returns: record<offeringTransaction: record<offeringStatus: record<type: string, offering: record, quantity: int, effectiveOn: string>, transactionId: string, offeringPromotionId: string, createdOn: string, cost: record<amount: float, currencyCode: string>>>
# operationId: RenewOffering
export def "renew-offering" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  offering_id: string # The ID of a request to renew an offering.
  quantity: int # The quantity requested in an offering renewal.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.RenewOffering"}]
    body: {content_type: "application/json", kind: json, fields: [{name: offeringId, var: offering_id}, {name: quantity, var: quantity}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, offering_id: $offering_id, quantity: $quantity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Schedules a run.
#
# POST /
# Returns: record<run: record<arn: string, name: string, type: string, platform: string, created: string, status: string, result: string, started: string, stopped: string, counters: record<total: int, passed: int, failed: int, warned: int, errored: int, stopped: int, skipped: int>, message: string, totalJobs: int, completedJobs: int, billingMethod: string, deviceMinutes: record<total: float, metered: float, unmetered: float>, networkProfile: record<arn: string, name: string, description: string, type: string, uplinkBandwidthBits: int, downlinkBandwidthBits: int, uplinkDelayMs: int, downlinkDelayMs: int, uplinkJitterMs: int, downlinkJitterMs: int, uplinkLossPercent: int, downlinkLossPercent: int>, parsingResultUrl: string, resultCode: string, seed: int, appUpload: string, eventCount: int, jobTimeoutMinutes: int, devicePoolArn: string, locale: string, radios: record<wifi: bool, bluetooth: bool, nfc: bool, gps: bool>, location: record<latitude: float, longitude: float>, customerArtifactPaths: record<iosPaths: list, androidPaths: list, deviceHostPaths: list>, webUrl: string, skipAppResign: bool, testSpecArn: string, deviceSelectionResult: record<filters: list, matchedDevicesCount: int, maxDevices: int>, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>
# operationId: ScheduleRun
export def "schedule-run" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  project_arn: string # The ARN of the project for the run to be scheduled.
  --app-arn: string # The ARN of an application package to run tests against, created with CreateUpload. See ListUploads.
  --device-pool-arn: string # The ARN of the device pool for the run to be scheduled.
  --device-selection-configuration: record # Represents the device filters used in a test run and the maximum number of devices to be included in the run. It is passed in as the deviceSelectionConfiguration request parameter in ScheduleRun. — shape: {filters: list, maxDevices: int}
  --name: string # The name for the run to be scheduled.
  test: record # Represents test settings. This data structure is passed in as the test parameter to ScheduleRun. For an example of the JSON request syntax, see ScheduleRun. — shape: {type: "BUILTIN_FUZZ"|"BUILTIN_EXPLORER"|"WEB_PERFORMANCE_PROFILE"|"APPIUM_JAVA_JUNIT"|"APPIUM_JAVA_TESTNG"|"APPIUM_PYTHON"|"APPIUM_NODE"|"APPIUM_RUBY"|"APPIUM_WEB_JAVA_JUNIT"|"APPIUM_WEB_JAVA_TESTNG"|"APPIUM_WEB_PYTHON"|"APPIUM_WEB_NODE"|"APPIUM_WEB_RUBY"|"CALABASH"|"INSTRUMENTATION"|"UIAUTOMATION"|"UIAUTOMATOR"|"XCTEST"|"XCTEST_UI"|"REMOTE_ACCESS_RECORD"|"REMOTE_ACCESS_REPLAY", testPackageArn?: string, testSpecArn?: string, filter?: string, parameters?: record}
  --configuration: record # Represents the settings for a run. Includes things like location, radio states, auxiliary apps, and network profiles. — shape: {extraDataPackageArn?: string, networkProfileArn?: string, locale?: string, location?: record, vpceConfigurationArns?: list<string>, customerArtifactPaths?: record, radios?: record, auxiliaryApps?: list<string>, billingMethod?: "METERED"|"UNMETERED"}
  --execution-configuration: record # Represents configuration information about a test run, such as the execution timeout (in minutes). — shape: {jobTimeoutMinutes?: int, accountsCleanup?: bool, appPackagesCleanup?: bool, videoCapture?: bool, skipAppResign?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.ScheduleRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectArn, var: project_arn}, {name: appArn, var: app_arn}, {name: devicePoolArn, var: device_pool_arn}, {name: deviceSelectionConfiguration, var: device_selection_configuration}, {name: name, var: name}, {name: test, var: test}, {name: configuration, var: configuration}, {name: executionConfiguration, var: execution_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_arn: $project_arn, app_arn: $app_arn, device_pool_arn: $device_pool_arn, device_selection_configuration: $device_selection_configuration, name: $name, test: $test, configuration: $configuration, execution_configuration: $execution_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates a stop request for the current job. AWS Device Farm immediately stops the job on the device where tests have not started. You are not billed for this device. On the device where tests have started, setup suite and teardown suite tests run to completion on the device. You are billed for setup, teardown, and any tests that were in progress or already completed.
#
# POST /
# Returns: record<job: record<arn: string, name: string, type: string, created: string, status: string, result: string, started: string, stopped: string, counters: record<total: int, passed: int, failed: int, warned: int, errored: int, stopped: int, skipped: int>, message: string, device: record<arn: string, name: string, manufacturer: string, model: string, modelId: string, formFactor: string, platform: string, os: string, cpu: record, resolution: record, heapSize: int, memory: int, image: string, carrier: string, radio: string, remoteAccessEnabled: bool, remoteDebugEnabled: bool, fleetType: string, fleetName: string, instances: list, availability: string>, instanceArn: string, deviceMinutes: record<total: float, metered: float, unmetered: float>, videoEndpoint: string, videoCapture: bool>>
# operationId: StopJob
export def "stop-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # Represents the Amazon Resource Name (ARN) of the Device Farm job to stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.StopJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ends a specified remote access session.
#
# POST /
# Returns: record<remoteAccessSession: record<arn: string, name: string, created: string, status: string, result: string, message: string, started: string, stopped: string, device: record<arn: string, name: string, manufacturer: string, model: string, modelId: string, formFactor: string, platform: string, os: string, cpu: record, resolution: record, heapSize: int, memory: int, image: string, carrier: string, radio: string, remoteAccessEnabled: bool, remoteDebugEnabled: bool, fleetType: string, fleetName: string, instances: list, availability: string>, instanceArn: string, remoteDebugEnabled: bool, remoteRecordEnabled: bool, remoteRecordAppArn: string, hostAddress: string, clientId: string, billingMethod: string, deviceMinutes: record<total: float, metered: float, unmetered: float>, endpoint: string, deviceUdid: string, interactionMode: string, skipAppResign: bool, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>
# operationId: StopRemoteAccessSession
export def "stop-remote-access-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of the remote access session to stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.StopRemoteAccessSession"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates a stop request for the current test run. AWS Device Farm immediately stops the run on devices where tests have not started. You are not billed for these devices. On devices where tests have started executing, setup suite and teardown suite tests run to completion on those devices. You are billed for setup, teardown, and any tests that were in progress or already completed.
#
# POST /
# Returns: record<run: record<arn: string, name: string, type: string, platform: string, created: string, status: string, result: string, started: string, stopped: string, counters: record<total: int, passed: int, failed: int, warned: int, errored: int, stopped: int, skipped: int>, message: string, totalJobs: int, completedJobs: int, billingMethod: string, deviceMinutes: record<total: float, metered: float, unmetered: float>, networkProfile: record<arn: string, name: string, description: string, type: string, uplinkBandwidthBits: int, downlinkBandwidthBits: int, uplinkDelayMs: int, downlinkDelayMs: int, uplinkJitterMs: int, downlinkJitterMs: int, uplinkLossPercent: int, downlinkLossPercent: int>, parsingResultUrl: string, resultCode: string, seed: int, appUpload: string, eventCount: int, jobTimeoutMinutes: int, devicePoolArn: string, locale: string, radios: record<wifi: bool, bluetooth: bool, nfc: bool, gps: bool>, location: record<latitude: float, longitude: float>, customerArtifactPaths: record<iosPaths: list, androidPaths: list, deviceHostPaths: list>, webUrl: string, skipAppResign: bool, testSpecArn: string, deviceSelectionResult: record<filters: list, matchedDevicesCount: int, maxDevices: int>, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>
# operationId: StopRun
export def "stop-run" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # Represents the Amazon Resource Name (ARN) of the Device Farm run to stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.StopRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are also deleted.
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
  --x-amz-target: string@x-amz-target-completer-67 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource or resources to which to add tags. You can associate tags with the following Device Farm resources: PROJECT, RUN, NETWORK_PROFILE, INSTANCE_PROFILE, DEVICE_INSTANCE, SESSION, DEVICE_POOL, DEVICE, and VPCE_CONFIGURATION.
  tags: list # The tags to add to the resource. A tag is an array of key-value pairs. Tag keys can have a maximum character length of 128 characters. Tag values can have a maximum length of 256 characters. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceARN, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified tags from a resource.
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
  --x-amz-target: string@x-amz-target-completer-68 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource or resources from which to delete tags. You can associate tags with the following Device Farm resources: PROJECT, RUN, NETWORK_PROFILE, INSTANCE_PROFILE, DEVICE_INSTANCE, SESSION, DEVICE_POOL, DEVICE, and VPCE_CONFIGURATION.
  tag_keys: list<string> # The keys of the tags to be removed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceARN, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates information about a private device instance.
#
# POST /
# Returns: record<deviceInstance: record<arn: string, deviceArn: string, labels: list<string>, status: string, udid: string, instanceProfile: record<arn: string, packageCleanup: bool, excludeAppPackagesFromCleanup: list, rebootAfterUse: bool, name: string, description: string>>>
# operationId: UpdateDeviceInstance
export def "update-device-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of the device instance.
  --profile-arn: string # The ARN of the profile that you want to associate with the device instance.
  --labels: list<string> # An array of strings that you want to associate with the device instance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.UpdateDeviceInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: profileArn, var: profile_arn}, {name: labels, var: labels}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, profile_arn: $profile_arn, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
#
# POST /
# Returns: record<devicePool: record<arn: string, name: string, description: string, type: string, rules: list<record>, maxDevices: int>>
# operationId: UpdateDevicePool
export def "update-device-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of the Device Farm device pool to update.
  --name: string # A string that represents the name of the device pool to update.
  --description: string # A description of the device pool to update.
  --rules: list # Represents the rules to modify for the device pool. Updating rules is optional. If you update rules for your request, the update replaces the existing rules. — item shape: {attribute?: "ARN"|"PLATFORM"|"FORM_FACTOR"|"MANUFACTURER"|"REMOTE_ACCESS_ENABLED"|"REMOTE_DEBUG_ENABLED"|"APPIUM_VERSION"|"INSTANCE_ARN"|"INSTANCE_LABELS"|"FLEET_TYPE"|"OS_VERSION"|"MODEL"|"AVAILABILITY", operator?: "EQUALS"|"LESS_THAN"|"LESS_THAN_OR_EQUALS"|"GREATER_THAN"|"GREATER_THAN_OR_EQUALS"|"IN"|"NOT_IN"|"CONTAINS", value?: string}
  --max-devices: int # The number of devices that Device Farm can add to your device pool. Device Farm adds devices that are available and that meet the criteria that you assign for the rules parameter. Depending on how many devices meet these constraints, your device pool might contain fewer devices than the value for this parameter. By specifying the maximum number of devices, you can control the costs that you incur by running tests. If you use this parameter in your request, you cannot use the clearMaxDevices parameter in the same request.
  --clear-max-devices: oneof<nothing, bool> # Sets whether the maxDevices parameter applies to your device pool. If you set this parameter to true, the maxDevices parameter does not apply, and Device Farm does not limit the number of devices that it adds to your device pool. In this case, Device Farm adds all available devices that meet the criteria specified in the rules parameter. If you use this parameter in your request, you cannot use the maxDevices parameter in the same request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.UpdateDevicePool"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: name, var: name}, {name: description, var: description}, {name: rules, var: rules}, {name: maxDevices, var: max_devices}, {name: clearMaxDevices, var: clear_max_devices}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, name: $name, description: $description, rules: $rules, max_devices: $max_devices, clear_max_devices: $clear_max_devices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates information about an existing private device instance profile.
#
# POST /
# Returns: record<instanceProfile: record<arn: string, packageCleanup: bool, excludeAppPackagesFromCleanup: list<string>, rebootAfterUse: bool, name: string, description: string>>
# operationId: UpdateInstanceProfile
export def "update-instance-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of the instance profile.
  --name: string # The updated name for your instance profile.
  --description: string # The updated description for your instance profile.
  --package-cleanup: oneof<nothing, bool> # The updated choice for whether you want to specify package cleanup. The default value is false for private devices.
  --exclude-app-packages-from-cleanup: list<string> # An array of strings that specifies the list of app packages that should not be cleaned up from the device after a test run is over. The list of packages is only considered if you set packageCleanup to true.
  --reboot-after-use: oneof<nothing, bool> # The updated choice for whether you want to reboot the device after use. The default value is true.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.UpdateInstanceProfile"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: name, var: name}, {name: description, var: description}, {name: packageCleanup, var: package_cleanup}, {name: excludeAppPackagesFromCleanup, var: exclude_app_packages_from_cleanup}, {name: rebootAfterUse, var: reboot_after_use}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, name: $name, description: $description, package_cleanup: $package_cleanup, exclude_app_packages_from_cleanup: $exclude_app_packages_from_cleanup, reboot_after_use: $reboot_after_use
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the network profile.
#
# POST /
# Returns: record<networkProfile: record<arn: string, name: string, description: string, type: string, uplinkBandwidthBits: int, downlinkBandwidthBits: int, uplinkDelayMs: int, downlinkDelayMs: int, uplinkJitterMs: int, downlinkJitterMs: int, uplinkLossPercent: int, downlinkLossPercent: int>>
# operationId: UpdateNetworkProfile
export def "update-network-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of the project for which you want to update network profile settings.
  --name: string # The name of the network profile about which you are returning information.
  --description: string # The description of the network profile about which you are returning information.
  --type: string@type-completer # The type of network profile to return information about. Valid values are listed here.
  --uplink-bandwidth-bits: int # The data throughput rate in bits per second, as an integer from 0 to 104857600.
  --downlink-bandwidth-bits: int # The data throughput rate in bits per second, as an integer from 0 to 104857600.
  --uplink-delay-ms: int # Delay time for all packets to destination in milliseconds as an integer from 0 to 2000.
  --downlink-delay-ms: int # Delay time for all packets to destination in milliseconds as an integer from 0 to 2000.
  --uplink-jitter-ms: int # Time variation in the delay of received packets in milliseconds as an integer from 0 to 2000.
  --downlink-jitter-ms: int # Time variation in the delay of received packets in milliseconds as an integer from 0 to 2000.
  --uplink-loss-percent: int # Proportion of transmitted packets that fail to arrive from 0 to 100 percent.
  --downlink-loss-percent: int # Proportion of received packets that fail to arrive from 0 to 100 percent.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.UpdateNetworkProfile"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: name, var: name}, {name: description, var: description}, {name: type, var: type}, {name: uplinkBandwidthBits, var: uplink_bandwidth_bits}, {name: downlinkBandwidthBits, var: downlink_bandwidth_bits}, {name: uplinkDelayMs, var: uplink_delay_ms}, {name: downlinkDelayMs, var: downlink_delay_ms}, {name: uplinkJitterMs, var: uplink_jitter_ms}, {name: downlinkJitterMs, var: downlink_jitter_ms}, {name: uplinkLossPercent, var: uplink_loss_percent}, {name: downlinkLossPercent, var: downlink_loss_percent}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, name: $name, description: $description, type: $type, uplink_bandwidth_bits: $uplink_bandwidth_bits, downlink_bandwidth_bits: $downlink_bandwidth_bits, uplink_delay_ms: $uplink_delay_ms, downlink_delay_ms: $downlink_delay_ms, uplink_jitter_ms: $uplink_jitter_ms, downlink_jitter_ms: $downlink_jitter_ms, uplink_loss_percent: $uplink_loss_percent, downlink_loss_percent: $downlink_loss_percent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the specified project name, given the project ARN and a new name.
#
# POST /
# Returns: record<project: record<arn: string, name: string, defaultJobTimeoutMinutes: int, created: string, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>>>
# operationId: UpdateProject
export def "update-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of the project whose name to update.
  --name: string # A string that represents the new name of the project that you are updating.
  --default-job-timeout-minutes: int # The number of minutes a test run in the project executes before it times out.
  --vpc-config: record # Contains the VPC configuration data necessary to interface with AWS Device Farm's services. — shape: {securityGroupIds: list<string>, subnetIds: list<string>, vpcId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.UpdateProject"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: name, var: name}, {name: defaultJobTimeoutMinutes, var: default_job_timeout_minutes}, {name: vpcConfig, var: vpc_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, name: $name, default_job_timeout_minutes: $default_job_timeout_minutes, vpc_config: $vpc_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change details of a project.
#
# POST /
# Returns: record<testGridProject: record<arn: string, name: string, description: string, vpcConfig: record<securityGroupIds: list, subnetIds: list, vpcId: string>, created: string>>
# operationId: UpdateTestGridProject
export def "update-test-grid-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  project_arn: string # ARN of the project to update.
  --name: string # Human-readable name for the project.
  --description: string # Human-readable description for the project.
  --vpc-config: record # The VPC security groups and subnets that are attached to a project. — shape: {securityGroupIds: list<string>, subnetIds: list<string>, vpcId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.UpdateTestGridProject"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectArn, var: project_arn}, {name: name, var: name}, {name: description, var: description}, {name: vpcConfig, var: vpc_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_arn: $project_arn, name: $name, description: $description, vpc_config: $vpc_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an uploaded test spec.
#
# POST /
# Returns: record<upload: record<arn: string, name: string, created: string, type: string, status: string, url: string, metadata: string, contentType: string, message: string, category: string>>
# operationId: UpdateUpload
export def "update-upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of the uploaded test spec.
  --name: string # The upload's test spec file name. The name must not contain any forward slashes (/). The test spec file name must end with the .yaml or .yml file extension.
  --content-type: string # The upload's content type (for example, application/x-yaml).
  --edit-content: oneof<nothing, bool> # Set to true if the YAML file has changed and must be updated. Otherwise, set to false.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.UpdateUpload"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: name, var: name}, {name: contentType, var: content_type}, {name: editContent, var: edit_content}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, name: $name, content_type: $content_type, edit_content: $edit_content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates information about an Amazon Virtual Private Cloud (VPC) endpoint configuration.
#
# POST /
# Returns: record<vpceConfiguration: record<arn: string, vpceConfigurationName: string, vpceServiceName: string, serviceDnsName: string, vpceConfigurationDescription: string>>
# operationId: UpdateVPCEConfiguration
export def "update-vpce-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of the VPC endpoint configuration you want to update.
  --vpce-configuration-name: string # The friendly name you give to your VPC endpoint configuration to manage your configurations more easily.
  --vpce-service-name: string # The name of the VPC endpoint service running in your AWS account that you want Device Farm to test.
  --service-dns-name: string # The DNS (domain) name used to connect to your private service in your VPC. The DNS name must not already be in use on the internet.
  --vpce-configuration-description: string # An optional description that provides details about your VPC endpoint configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "DeviceFarm_20150623.UpdateVPCEConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: vpceConfigurationName, var: vpce_configuration_name}, {name: vpceServiceName, var: vpce_service_name}, {name: serviceDnsName, var: service_dns_name}, {name: vpceConfigurationDescription, var: vpce_configuration_description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, vpce_configuration_name: $vpce_configuration_name, vpce_service_name: $vpce_service_name, service_dns_name: $service_dns_name, vpce_configuration_description: $vpce_configuration_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
