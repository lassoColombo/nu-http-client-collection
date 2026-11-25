# Auto-generated client for Amazon Lookout for Vision v2020-11-20
# Source: https://api.apis.guru/v2/specs/amazonaws.com/lookoutvision/2020-11-20/openapi.json
# Auth: --token flag or $env.AMAZON_LOOKOUT_FOR_VISION_TOKEN

const CLIENT = {
  base_url: "http://lookoutvision.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_LOOKOUT_FOR_VISION_TOKEN"
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

def base-url-completer [] { ["http://lookoutvision.us-east-1.amazonaws.com" "http://lookoutvision.us-east-2.amazonaws.com" "http://lookoutvision.us-west-1.amazonaws.com" "http://lookoutvision.us-west-2.amazonaws.com" "http://lookoutvision.us-gov-west-1.amazonaws.com" "http://lookoutvision.us-gov-east-1.amazonaws.com" "http://lookoutvision.ca-central-1.amazonaws.com" "http://lookoutvision.eu-north-1.amazonaws.com" "http://lookoutvision.eu-west-1.amazonaws.com" "http://lookoutvision.eu-west-2.amazonaws.com" "http://lookoutvision.eu-west-3.amazonaws.com" "http://lookoutvision.eu-central-1.amazonaws.com" "http://lookoutvision.eu-south-1.amazonaws.com" "http://lookoutvision.af-south-1.amazonaws.com" "http://lookoutvision.ap-northeast-1.amazonaws.com" "http://lookoutvision.ap-northeast-2.amazonaws.com" "http://lookoutvision.ap-northeast-3.amazonaws.com" "http://lookoutvision.ap-southeast-1.amazonaws.com" "http://lookoutvision.ap-southeast-2.amazonaws.com" "http://lookoutvision.ap-east-1.amazonaws.com" "http://lookoutvision.ap-south-1.amazonaws.com" "http://lookoutvision.sa-east-1.amazonaws.com" "http://lookoutvision.me-south-1.amazonaws.com" "https://lookoutvision.us-east-1.amazonaws.com" "https://lookoutvision.us-east-2.amazonaws.com" "https://lookoutvision.us-west-1.amazonaws.com" "https://lookoutvision.us-west-2.amazonaws.com" "https://lookoutvision.us-gov-west-1.amazonaws.com" "https://lookoutvision.us-gov-east-1.amazonaws.com" "https://lookoutvision.ca-central-1.amazonaws.com" "https://lookoutvision.eu-north-1.amazonaws.com" "https://lookoutvision.eu-west-1.amazonaws.com" "https://lookoutvision.eu-west-2.amazonaws.com" "https://lookoutvision.eu-west-3.amazonaws.com" "https://lookoutvision.eu-central-1.amazonaws.com" "https://lookoutvision.eu-south-1.amazonaws.com" "https://lookoutvision.af-south-1.amazonaws.com" "https://lookoutvision.ap-northeast-1.amazonaws.com" "https://lookoutvision.ap-northeast-2.amazonaws.com" "https://lookoutvision.ap-northeast-3.amazonaws.com" "https://lookoutvision.ap-southeast-1.amazonaws.com" "https://lookoutvision.ap-southeast-2.amazonaws.com" "https://lookoutvision.ap-east-1.amazonaws.com" "https://lookoutvision.ap-south-1.amazonaws.com" "https://lookoutvision.sa-east-1.amazonaws.com" "https://lookoutvision.me-south-1.amazonaws.com" "http://lookoutvision.cn-north-1.amazonaws.com.cn" "http://lookoutvision.cn-northwest-1.amazonaws.com.cn" "https://lookoutvision.cn-north-1.amazonaws.com.cn" "https://lookoutvision.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-dataset: "record<DatasetMetadata: record<DatasetType: string, CreationTimestamp: string, Status: string, StatusMessage: string>>"
    create-model: "record<ModelMetadata: record<CreationTimestamp: string, ModelVersion: string, ModelArn: string, Description: string, Status: string, StatusMessage: string, Performance: record<F1Score: float, Recall: float, Precision: float>>>"
    list-models: "record<Models: table<CreationTimestamp: string, ModelVersion: string, ModelArn: string, Description: string, Status: string, StatusMessage: string, Performance: record>, NextToken: string>"
    create-project: "record<ProjectMetadata: record<ProjectArn: string, ProjectName: string, CreationTimestamp: string>>"
    list-projects: "record<Projects: table<ProjectArn: string, ProjectName: string, CreationTimestamp: string>, NextToken: string>"
    delete-dataset: "record"
    describe-dataset: "record<DatasetDescription: record<ProjectName: string, DatasetType: string, CreationTimestamp: string, LastUpdatedTimestamp: string, Status: string, StatusMessage: string, ImageStats: record<Total: int, Labeled: int, Normal: int, Anomaly: int>>>"
    delete-model: "record<ModelArn: string>"
    describe-model: "record<ModelDescription: record<ModelVersion: string, ModelArn: string, CreationTimestamp: string, Description: string, Status: string, StatusMessage: string, Performance: record<F1Score: float, Recall: float, Precision: float>, OutputConfig: record<S3Location: record>, EvaluationManifest: record<Bucket: string, Key: string>, EvaluationResult: record<Bucket: string, Key: string>, EvaluationEndTimestamp: string, KmsKeyId: string, MinInferenceUnits: int, MaxInferenceUnits: int>>"
    delete-project: "record<ProjectArn: string>"
    describe-project: "record<ProjectDescription: record<ProjectArn: string, ProjectName: string, CreationTimestamp: string, Datasets: list<record>>>"
    describe-model-packaging-job: "record<ModelPackagingDescription: record<JobName: string, ProjectName: string, ModelVersion: string, ModelPackagingConfiguration: record<Greengrass: record>, ModelPackagingJobDescription: string, ModelPackagingMethod: string, ModelPackagingOutputDetails: record<Greengrass: record>, Status: string, StatusMessage: string, CreationTimestamp: string, LastUpdatedTimestamp: string>>"
    detect-anomalies: "record<DetectAnomalyResult: record<Source: record<Type: string>, IsAnomalous: bool, Confidence: float, Anomalies: list<record>, AnomalyMask: string>>"
    list-dataset-entries: "record<DatasetEntries: list<string>, NextToken: string>"
    update-dataset-entries: "record<Status: string>"
    list-model-packaging-jobs: "record<ModelPackagingJobs: table<JobName: string, ProjectName: string, ModelVersion: string, ModelPackagingJobDescription: string, ModelPackagingMethod: string, Status: string, StatusMessage: string, CreationTimestamp: string, LastUpdatedTimestamp: string>, NextToken: string>"
    start-model-packaging-job: "record<JobName: string>"
    list-tags-for-resource: "record<Tags: table<Key: string, Value: string>>"
    tag-resource: "record"
    start-model: "record<Status: string>"
    stop-model: "record<Status: string>"
    untag-resource: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-dataset" "create-model" "list-models" "create-project" "list-projects" "delete-dataset" "describe-dataset" "delete-model" "describe-model" "delete-project" "describe-project" "describe-model-packaging-job" "detect-anomalies" "list-dataset-entries" "update-dataset-entries" "list-model-packaging-jobs" "start-model-packaging-job" "list-tags-for-resource" "tag-resource" "start-model" "stop-model" "untag-resource" "commands"] | sort) } | get name | first)
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

# Creates a new dataset in an Amazon Lookout for Vision project. CreateDataset can create a training or a test dataset from a valid dataset source (DatasetSource). If you want a single dataset project, specify train for the value of DatasetType. To have a project with separate training and test datasets, call CreateDataset twice. On the first call, specify train for the value of DatasetType. On the second call, specify test for the value of DatasetType. This operation requires permissions to perform the lookoutvision:CreateDataset operation.
#
# POST /2020-11-20/projects/{projectName}/datasets
# Returns: record<DatasetMetadata: record<DatasetType: string, CreationTimestamp: string, Status: string, StatusMessage: string>>
# operationId: CreateDataset
export def "create-dataset" [
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to CreateDataset completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from CreateDataset. In this case, safely retry your call to CreateDataset by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple dataset creation requests. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to CreateDataset. An idempotency token is active for 8 hours.
  dataset_type: string # The type of the dataset. Specify train for a training dataset. Specify test for a test dataset.
  --dataset-source: record # Information about the location of a manifest file that Amazon Lookout for Vision uses to to create a dataset. — shape: {GroundTruthManifest?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-11-20/projects/{projectName}/datasets"
    path_params: [{name: projectName, var: project_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amzn-Client-Token, var: x_amzn_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: DatasetType, var: dataset_type}, {name: DatasetSource, var: dataset_source}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    project_name: $project_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amzn_client_token: $x_amzn_client_token, dataset_type: $dataset_type, dataset_source: $dataset_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new version of a model within an an Amazon Lookout for Vision project. CreateModel is an asynchronous operation in which Amazon Lookout for Vision trains, tests, and evaluates a new version of a model. To get the current status, check the Status field returned in the response from DescribeModel. If the project has a single dataset, Amazon Lookout for Vision internally splits the dataset to create a training and a test dataset. If the project has a training and a test dataset, Lookout for Vision uses the respective datasets to train and test the model. After training completes, the evaluation metrics are stored at the location specified in OutputConfig. This operation requires permissions to perform the lookoutvision:CreateModel operation. If you want to tag your model, you also require permission to the lookoutvision:TagResource operation.
#
# POST /2020-11-20/projects/{projectName}/models
# Returns: record<ModelMetadata: record<CreationTimestamp: string, ModelVersion: string, ModelArn: string, Description: string, Status: string, StatusMessage: string, Performance: record<F1Score: float, Recall: float, Precision: float>>>
# operationId: CreateModel
export def "create-model" [
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to CreateModel completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from CreateModel. In this case, safely retry your call to CreateModel by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from starting multiple training jobs. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to CreateModel. An idempotency token is active for 8 hours.
  --description: string # A description for the version of the model.
  output_config: record # The S3 location where Amazon Lookout for Vision saves model training files. — shape: {S3Location?: record}
  --kms-key-id: string # The identifier for your AWS KMS key. The key is used to encrypt training and test images copied into the service for model training. Your source images are unaffected. If this parameter is not specified, the copied images are encrypted by a key that AWS owns and manages.
  --tags: list # A set of tags (key-value pairs) that you want to attach to the model. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-11-20/projects/{projectName}/models"
    path_params: [{name: projectName, var: project_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amzn-Client-Token, var: x_amzn_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: OutputConfig, var: output_config}, {name: KmsKeyId, var: kms_key_id}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    project_name: $project_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amzn_client_token: $x_amzn_client_token, description: $description, output_config: $output_config, kms_key_id: $kms_key_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the versions of a model in an Amazon Lookout for Vision project. The ListModels operation is eventually consistent. Recent calls to CreateModel might take a while to appear in the response from ListProjects. This operation requires permissions to perform the lookoutvision:ListModels operation.
#
# GET /2020-11-20/projects/{projectName}/models
# Returns: record<Models: table<CreationTimestamp: string, ModelVersion: string, ModelArn: string, Description: string, Status: string, StatusMessage: string, Performance: record>, NextToken: string>
# operationId: ListModels
export def "list-models" [
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Lookout for Vision returns a pagination token in the response. You can use this pagination token to retrieve the next set of models.
  --max-results: int # The maximum number of results to return per paginated call. The largest value you can specify is 100. If you specify a value greater than 100, a ValidationException error occurs. The default value is 100.
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
    path: "/2020-11-20/projects/{projectName}/models"
    path_params: [{name: projectName, var: project_name}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_name: $project_name, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an empty Amazon Lookout for Vision project. After you create the project, add a dataset by calling CreateDataset. This operation requires permissions to perform the lookoutvision:CreateProject operation.
#
# POST /2020-11-20/projects
# Returns: record<ProjectMetadata: record<ProjectArn: string, ProjectName: string, CreationTimestamp: string>>
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
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to CreateProject completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from CreateProject. In this case, safely retry your call to CreateProject by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple project creation requests. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to CreateProject. An idempotency token is active for 8 hours.
  project_name: string # The name for the project.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-11-20/projects"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amzn-Client-Token, var: x_amzn_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: ProjectName, var: project_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amzn_client_token: $x_amzn_client_token, project_name: $project_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Amazon Lookout for Vision projects in your AWS account that are in the AWS Region in which you call ListProjects. The ListProjects operation is eventually consistent. Recent calls to CreateProject and DeleteProject might take a while to appear in the response from ListProjects. This operation requires permissions to perform the lookoutvision:ListProjects operation.
#
# GET /2020-11-20/projects
# Returns: record<Projects: table<ProjectArn: string, ProjectName: string, CreationTimestamp: string>, NextToken: string>
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
  --next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Lookout for Vision returns a pagination token in the response. You can use this pagination token to retrieve the next set of projects.
  --max-results: int # The maximum number of results to return per paginated call. The largest value you can specify is 100. If you specify a value greater than 100, a ValidationException error occurs. The default value is 100.
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
    path: "/2020-11-20/projects"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing Amazon Lookout for Vision dataset. If your the project has a single dataset, you must create a new dataset before you can create a model. If you project has a training dataset and a test dataset consider the following. If you delete the test dataset, your project reverts to a single dataset project. If you then train the model, Amazon Lookout for Vision internally splits the remaining dataset into a training and test dataset. If you delete the training dataset, you must create a training dataset before you can create a model. This operation requires permissions to perform the lookoutvision:DeleteDataset operation.
#
# DELETE /2020-11-20/projects/{projectName}/datasets/{datasetType}
# Returns: record
# operationId: DeleteDataset
export def "delete-dataset" [
  project_name: string
  dataset_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to DeleteDataset completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from DeleteDataset. In this case, safely retry your call to DeleteDataset by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple deletetion requests. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to DeleteDataset. An idempotency token is active for 8 hours.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2020-11-20/projects/{projectName}/datasets/{datasetType}"
    path_params: [{name: projectName, var: project_name}, {name: datasetType, var: dataset_type}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amzn-Client-Token, var: x_amzn_client_token}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    project_name: $project_name, dataset_type: $dataset_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amzn_client_token: $x_amzn_client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe an Amazon Lookout for Vision dataset. This operation requires permissions to perform the lookoutvision:DescribeDataset operation.
#
# GET /2020-11-20/projects/{projectName}/datasets/{datasetType}
# Returns: record<DatasetDescription: record<ProjectName: string, DatasetType: string, CreationTimestamp: string, LastUpdatedTimestamp: string, Status: string, StatusMessage: string, ImageStats: record<Total: int, Labeled: int, Normal: int, Anomaly: int>>>
# operationId: DescribeDataset
export def "describe-dataset" [
  project_name: string
  dataset_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/2020-11-20/projects/{projectName}/datasets/{datasetType}"
    path_params: [{name: projectName, var: project_name}, {name: datasetType, var: dataset_type}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_name: $project_name, dataset_type: $dataset_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Amazon Lookout for Vision model. You can't delete a running model. To stop a running model, use the StopModel operation. It might take a few seconds to delete a model. To determine if a model has been deleted, call ListModels and check if the version of the model (ModelVersion) is in the Models array. This operation requires permissions to perform the lookoutvision:DeleteModel operation.
#
# DELETE /2020-11-20/projects/{projectName}/models/{modelVersion}
# Returns: record<ModelArn: string>
# operationId: DeleteModel
export def "delete-model" [
  project_name: string
  model_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to DeleteModel completes only once. You choose the value to pass. For example, an issue might prevent you from getting a response from DeleteModel. In this case, safely retry your call to DeleteModel by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple model deletion requests. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to DeleteModel. An idempotency token is active for 8 hours.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2020-11-20/projects/{projectName}/models/{modelVersion}"
    path_params: [{name: projectName, var: project_name}, {name: modelVersion, var: model_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amzn-Client-Token, var: x_amzn_client_token}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    project_name: $project_name, model_version: $model_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amzn_client_token: $x_amzn_client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a version of an Amazon Lookout for Vision model. This operation requires permissions to perform the lookoutvision:DescribeModel operation.
#
# GET /2020-11-20/projects/{projectName}/models/{modelVersion}
# Returns: record<ModelDescription: record<ModelVersion: string, ModelArn: string, CreationTimestamp: string, Description: string, Status: string, StatusMessage: string, Performance: record<F1Score: float, Recall: float, Precision: float>, OutputConfig: record<S3Location: record>, EvaluationManifest: record<Bucket: string, Key: string>, EvaluationResult: record<Bucket: string, Key: string>, EvaluationEndTimestamp: string, KmsKeyId: string, MinInferenceUnits: int, MaxInferenceUnits: int>>
# operationId: DescribeModel
export def "describe-model" [
  project_name: string
  model_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/2020-11-20/projects/{projectName}/models/{modelVersion}"
    path_params: [{name: projectName, var: project_name}, {name: modelVersion, var: model_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_name: $project_name, model_version: $model_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Amazon Lookout for Vision project. To delete a project, you must first delete each version of the model associated with the project. To delete a model use the DeleteModel operation. You also have to delete the dataset(s) associated with the model. For more information, see DeleteDataset. The images referenced by the training and test datasets aren't deleted. This operation requires permissions to perform the lookoutvision:DeleteProject operation.
#
# DELETE /2020-11-20/projects/{projectName}
# Returns: record<ProjectArn: string>
# operationId: DeleteProject
export def "delete-project" [
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to DeleteProject completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from DeleteProject. In this case, safely retry your call to DeleteProject by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple project deletion requests. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to DeleteProject. An idempotency token is active for 8 hours.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2020-11-20/projects/{projectName}"
    path_params: [{name: projectName, var: project_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amzn-Client-Token, var: x_amzn_client_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_name: $project_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amzn_client_token: $x_amzn_client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an Amazon Lookout for Vision project. This operation requires permissions to perform the lookoutvision:DescribeProject operation.
#
# GET /2020-11-20/projects/{projectName}
# Returns: record<ProjectDescription: record<ProjectArn: string, ProjectName: string, CreationTimestamp: string, Datasets: list<record>>>
# operationId: DescribeProject
export def "describe-project" [
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/2020-11-20/projects/{projectName}"
    path_params: [{name: projectName, var: project_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_name: $project_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an Amazon Lookout for Vision model packaging job. This operation requires permissions to perform the lookoutvision:DescribeModelPackagingJob operation. For more information, see Using your Amazon Lookout for Vision model on an edge device in the Amazon Lookout for Vision Developer Guide.
#
# GET /2020-11-20/projects/{projectName}/modelpackagingjobs/{jobName}
# Returns: record<ModelPackagingDescription: record<JobName: string, ProjectName: string, ModelVersion: string, ModelPackagingConfiguration: record<Greengrass: record>, ModelPackagingJobDescription: string, ModelPackagingMethod: string, ModelPackagingOutputDetails: record<Greengrass: record>, Status: string, StatusMessage: string, CreationTimestamp: string, LastUpdatedTimestamp: string>>
# operationId: DescribeModelPackagingJob
export def "describe-model-packaging-job" [
  project_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/2020-11-20/projects/{projectName}/modelpackagingjobs/{jobName}"
    path_params: [{name: projectName, var: project_name}, {name: jobName, var: job_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_name: $project_name, job_name: $job_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detects anomalies in an image that you supply. The response from DetectAnomalies includes a boolean prediction that the image contains one or more anomalies and a confidence value for the prediction. If the model is an image segmentation model, the response also includes segmentation information for each type of anomaly found in the image. Before calling DetectAnomalies, you must first start your model with the StartModel operation. You are charged for the amount of time, in minutes, that a model runs and for the number of anomaly detection units that your model uses. If you are not using a model, use the StopModel operation to stop your model. For more information, see Detecting anomalies in an image in the Amazon Lookout for Vision developer guide. This operation requires permissions to perform the lookoutvision:DetectAnomalies operation.
#
# POST /2020-11-20/projects/{projectName}/models/{modelVersion}/detect
# Returns: record<DetectAnomalyResult: record<Source: record<Type: string>, IsAnomalous: bool, Confidence: float, Anomalies: list<record>, AnomalyMask: string>>
# operationId: DetectAnomalies
export def "detect-anomalies" [
  project_name: string
  model_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --content-type: string # The type of the image passed in Body. Valid values are image/png (PNG format images) and image/jpeg (JPG format images). (required)
  body: string # The unencrypted image bytes that you want to analyze.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-11-20/projects/{projectName}/models/{modelVersion}/detect"
    path_params: [{name: projectName, var: project_name}, {name: modelVersion, var: model_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_name: $project_name, model_version: $model_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, content_type: $content_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the JSON Lines within a dataset. An Amazon Lookout for Vision JSON Line contains the anomaly information for a single image, including the image location and the assigned label. This operation requires permissions to perform the lookoutvision:ListDatasetEntries operation.
#
# GET /2020-11-20/projects/{projectName}/datasets/{datasetType}/entries
# Returns: record<DatasetEntries: list<string>, NextToken: string>
# operationId: ListDatasetEntries
export def "list-dataset-entries" [
  project_name: string
  dataset_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --labeled: oneof<nothing, bool> # Specify true to include labeled entries, otherwise specify false. If you don't specify a value, Lookout for Vision returns all entries.
  --anomaly-class: string # Specify normal to include only normal images. Specify anomaly to only include anomalous entries. If you don't specify a value, Amazon Lookout for Vision returns normal and anomalous images.
  --created-before: string # Only includes entries before the specified date in the response. For example, 2020-06-23T00:00:00. (format: date-time)
  --created-after: string # Only includes entries after the specified date in the response. For example, 2020-06-23T00:00:00. (format: date-time)
  --next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Lookout for Vision returns a pagination token in the response. You can use this pagination token to retrieve the next set of dataset entries.
  --max-results: int # The maximum number of results to return per paginated call. The largest value you can specify is 100. If you specify a value greater than 100, a ValidationException error occurs. The default value is 100.
  --source-ref-contains: string # Perform a "contains" search on the values of the source-ref key within the dataset. For example a value of "IMG_17" returns all JSON Lines where the source-ref key value matches *IMG_17*.
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
    path: "/2020-11-20/projects/{projectName}/datasets/{datasetType}/entries"
    path_params: [{name: projectName, var: project_name}, {name: datasetType, var: dataset_type}]
    query: [{name: labeled, var: labeled}, {name: anomalyClass, var: anomaly_class}, {name: createdBefore, var: created_before}, {name: createdAfter, var: created_after}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: sourceRefContains, var: source_ref_contains}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_name: $project_name, dataset_type: $dataset_type, labeled: $labeled, anomaly_class: $anomaly_class, created_before: $created_before, created_after: $created_after, next_token: $next_token, max_results: $max_results, source_ref_contains: $source_ref_contains, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds or updates one or more JSON Line entries in a dataset. A JSON Line includes information about an image used for training or testing an Amazon Lookout for Vision model. To update an existing JSON Line, use the source-ref field to identify the JSON Line. The JSON line that you supply replaces the existing JSON line. Any existing annotations that are not in the new JSON line are removed from the dataset. For more information, see Defining JSON lines for anomaly classification in the Amazon Lookout for Vision Developer Guide. The images you reference in the source-ref field of a JSON line, must be in the same S3 bucket as the existing images in the dataset. Updating a dataset might take a while to complete. To check the current status, call DescribeDataset and check the Status field in the response. This operation requires permissions to perform the lookoutvision:UpdateDatasetEntries operation.
#
# PATCH /2020-11-20/projects/{projectName}/datasets/{datasetType}/entries
# Returns: record<Status: string>
# operationId: UpdateDatasetEntries
export def "update-dataset-entries" [
  project_name: string
  dataset_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to UpdateDatasetEntries completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from UpdateDatasetEntries. In this case, safely retry your call to UpdateDatasetEntries by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple updates with the same dataset entries. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to UpdateDatasetEntries. An idempotency token is active for 8 hours.
  changes: string # The entries to add to the dataset.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/2020-11-20/projects/{projectName}/datasets/{datasetType}/entries"
    path_params: [{name: projectName, var: project_name}, {name: datasetType, var: dataset_type}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amzn-Client-Token, var: x_amzn_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: Changes, var: changes}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    project_name: $project_name, dataset_type: $dataset_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amzn_client_token: $x_amzn_client_token, changes: $changes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the model packaging jobs created for an Amazon Lookout for Vision project. This operation requires permissions to perform the lookoutvision:ListModelPackagingJobs operation. For more information, see Using your Amazon Lookout for Vision model on an edge device in the Amazon Lookout for Vision Developer Guide.
#
# GET /2020-11-20/projects/{projectName}/modelpackagingjobs
# Returns: record<ModelPackagingJobs: table<JobName: string, ProjectName: string, ModelVersion: string, ModelPackagingJobDescription: string, ModelPackagingMethod: string, Status: string, StatusMessage: string, CreationTimestamp: string, LastUpdatedTimestamp: string>, NextToken: string>
# operationId: ListModelPackagingJobs
export def "list-model-packaging-jobs" [
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # If the previous response was incomplete (because there is more results to retrieve), Amazon Lookout for Vision returns a pagination token in the response. You can use this pagination token to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per paginated call. The largest value you can specify is 100. If you specify a value greater than 100, a ValidationException error occurs. The default value is 100.
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
    path: "/2020-11-20/projects/{projectName}/modelpackagingjobs"
    path_params: [{name: projectName, var: project_name}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_name: $project_name, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an Amazon Lookout for Vision model packaging job. A model packaging job creates an AWS IoT Greengrass component for a Lookout for Vision model. You can use the component to deploy your model to an edge device managed by Greengrass. Use the DescribeModelPackagingJob API to determine the current status of the job. The model packaging job is complete if the value of Status is SUCCEEDED. To deploy the component to the target device, use the component name and component version with the AWS IoT Greengrass CreateDeployment (https://docs.aws.amazon.com/greengrass/v2/APIReference/API_CreateDeployment.html) API. This operation requires the following permissions: lookoutvision:StartModelPackagingJob s3:PutObject s3:GetBucketLocation kms:GenerateDataKey greengrass:CreateComponentVersion greengrass:DescribeComponent (Optional) greengrass:TagResource. Only required if you want to tag the component. For more information, see Using your Amazon Lookout for Vision model on an edge device in the Amazon Lookout for Vision Developer Guide.
#
# POST /2020-11-20/projects/{projectName}/modelpackagingjobs
# Returns: record<JobName: string>
# operationId: StartModelPackagingJob
export def "start-model-packaging-job" [
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to StartModelPackagingJob completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from StartModelPackagingJob. In this case, safely retry your call to StartModelPackagingJob by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple dataset creation requests. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to StartModelPackagingJob. An idempotency token is active for 8 hours.
  model_version: string # The version of the model within the project that you want to package.
  --job-name: string # A name for the model packaging job. If you don't supply a value, the service creates a job name for you.
  configuration: record # Configuration information for a Amazon Lookout for Vision model packaging job. For more information, see StartModelPackagingJob. — shape: {Greengrass?: record}
  --description: string # A description for the model packaging job.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-11-20/projects/{projectName}/modelpackagingjobs"
    path_params: [{name: projectName, var: project_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amzn-Client-Token, var: x_amzn_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: ModelVersion, var: model_version}, {name: JobName, var: job_name}, {name: Configuration, var: configuration}, {name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_name: $project_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amzn_client_token: $x_amzn_client_token, model_version: $model_version, job_name: $job_name, configuration: $configuration, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of tags attached to the specified Amazon Lookout for Vision model. This operation requires permissions to perform the lookoutvision:ListTagsForResource operation.
#
# GET /2020-11-20/tags/{resourceArn}
# Returns: record<Tags: table<Key: string, Value: string>>
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
    path: "/2020-11-20/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds one or more key-value tags to an Amazon Lookout for Vision model. For more information, see Tagging a model in the Amazon Lookout for Vision Developer Guide. This operation requires permissions to perform the lookoutvision:TagResource operation.
#
# POST /2020-11-20/tags/{resourceArn}
# Returns: record
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
  tags: list # The key-value tags to assign to the model. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-11-20/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
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

# Starts the running of the version of an Amazon Lookout for Vision model. Starting a model takes a while to complete. To check the current state of the model, use DescribeModel. A model is ready to use when its status is HOSTED. Once the model is running, you can detect custom labels in new images by calling DetectAnomalies. You are charged for the amount of time that the model is running. To stop a running model, call StopModel. This operation requires permissions to perform the lookoutvision:StartModel operation.
#
# POST /2020-11-20/projects/{projectName}/models/{modelVersion}/start
# Returns: record<Status: string>
# operationId: StartModel
export def "start-model" [
  project_name: string
  model_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to StartModel completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from StartModel. In this case, safely retry your call to StartModel by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple start requests. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to StartModel. An idempotency token is active for 8 hours.
  min_inference_units: int # The minimum number of inference units to use. A single inference unit represents 1 hour of processing. Use a higher number to increase the TPS throughput of your model. You are charged for the number of inference units that you use.
  --max-inference-units: int # The maximum number of inference units to use for auto-scaling the model. If you don't specify a value, Amazon Lookout for Vision doesn't auto-scale the model.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-11-20/projects/{projectName}/models/{modelVersion}/start"
    path_params: [{name: projectName, var: project_name}, {name: modelVersion, var: model_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amzn-Client-Token, var: x_amzn_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: MinInferenceUnits, var: min_inference_units}, {name: MaxInferenceUnits, var: max_inference_units}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    project_name: $project_name, model_version: $model_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amzn_client_token: $x_amzn_client_token, min_inference_units: $min_inference_units, max_inference_units: $max_inference_units
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops the hosting of a running model. The operation might take a while to complete. To check the current status, call DescribeModel. After the model hosting stops, the Status of the model is TRAINED. This operation requires permissions to perform the lookoutvision:StopModel operation.
#
# POST /2020-11-20/projects/{projectName}/models/{modelVersion}/stop
# Returns: record<Status: string>
# operationId: StopModel
export def "stop-model" [
  project_name: string
  model_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to StopModel completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from StopModel. In this case, safely retry your call to StopModel by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple stop requests. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to StopModel. An idempotency token is active for 8 hours.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/2020-11-20/projects/{projectName}/models/{modelVersion}/stop"
    path_params: [{name: projectName, var: project_name}, {name: modelVersion, var: model_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amzn-Client-Token, var: x_amzn_client_token}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    project_name: $project_name, model_version: $model_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amzn_client_token: $x_amzn_client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes one or more tags from an Amazon Lookout for Vision model. For more information, see Tagging a model in the Amazon Lookout for Vision Developer Guide. This operation requires permissions to perform the lookoutvision:UntagResource operation.
#
# DELETE /2020-11-20/tags/{resourceArn}
# Returns: record
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
  --tag-keys: list<string> # A list of the keys of the tags that you want to remove. (required)
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
    path: "/2020-11-20/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    query: [{name: tagKeys, var: tag_keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, tag_keys: $tag_keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
