# Auto-generated client for Einstein Vision and Einstein Language v2.0.1
# Source: https://api.apis.guru/v2/specs/salesforce.local/einstein/2.0.1/openapi.json
# Auth: --token flag or $env.EINSTEIN_VISION_AND_EINSTEIN_LANGUAGE_TOKEN

const CLIENT = {
  base_url: "http://salesforce.local"
  token_env_var: "EINSTEIN_VISION_AND_EINSTEIN_LANGUAGE_TOKEN"
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

def base-url-completer [] { ["http://salesforce.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["text-intent" "text-sentiment"] }
def source-completer [] { ["all" "feedback" "upload"] }
def grant-type-completer [] { ["refresh_token" "urn:ietf:params:oauth:grant-type:jwt-bearer"] }
def type-completer-1 [] { ["image" "image-multi-label"] }
def type-completer-2 [] { ["image" "image-detection" "image-multi-label"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-api-usage-plans-v2: "record<data: table<endsAt: string, id: string, licenseId: string, object: string, organizationId: string, planData: list, predictionsMax: int, predictionsUsed: int, startsAt: string>, object: string>"
    list-datasets: "record<data: table<available: bool, createdAt: string, id: int, labelSummary: record, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>, object: string>"
    upload-dataset-async: "record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>"
    upload-dataset-sync: "record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>"
    delete-dataset: "record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string>"
    get-dataset: "record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>"
    get-examples: "record<data: table<createdAt: string, id: int, label: record, location: string, name: string, object: string>, object: string>"
    get-trained-models: "record<data: table<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, failureMsg: string, language: string, modelId: string, modelType: string, name: string, object: string, progress: float, status: string, updatedAt: string>, object: string>"
    update-dataset-async: "record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>"
    get-v2-language-deletion-id: "record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string>"
    get-examples-by-label: "record<data: table<createdAt: string, id: int, label: record, location: string, name: string, object: string>, object: string>"
    provide-feedback: "record<createdAt: string, id: int, label: record<datasetId: int, id: int, name: string, numExamples: int>, location: string, name: string, object: string>"
    intent-multipart: "record<object: string, probabilities: table<label: string, probability: float>, sampleId: string>"
    delete-model: "record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string>"
    get-trained-model-metrics: "record<algorithm: string, createdAt: string, id: string, language: string, metricsData: record, object: string>"
    get-trained-model-learning-curve: "record<data: table<epoch: record, epochResults: record, metricsData: record, object: string>, object: string>"
    retrain: "record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string>"
    sentiment-multipart: "record<object: string, probabilities: table<label: string, probability: float>, sampleId: string>"
    train: "record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string>"
    get-train-status-and-progress: "record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string>"
    generate-token-v2: "record<access_token: string, expires_in: string, refresh_token: string, token_type: string>"
    update-dataset-async-1: "record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>"
    list-datasets-1: "record<data: table<available: bool, createdAt: string, id: int, labelSummary: record, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>, object: string>"
    create-dataset: "record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>"
    upload-dataset-async-1: "record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>"
    upload-dataset-sync-1: "record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>"
    delete-dataset-1: "record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string>"
    get-dataset-1: "record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>"
    get-examples-1: "record<data: table<createdAt: string, id: int, label: record, location: string, name: string, object: string>, object: string>"
    add-example: "record<createdAt: string, id: int, label: record<datasetId: int, id: int, name: string, numExamples: int>, location: string, name: string, object: string>"
    get-trained-models-1: "record<data: table<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, failureMsg: string, language: string, modelId: string, modelType: string, name: string, object: string, progress: float, status: string, updatedAt: string>, object: string>"
    update-dataset-async-2: "record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>"
    get-1: "record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string>"
    detect-multipart: "record<object: string, probabilities: table<boundingBox: record, label: string, probability: float>, sampleId: string>"
    get-examples-by-label-1: "record<data: table<createdAt: string, id: int, label: record, location: string, name: string, object: string>, object: string>"
    provide-feedback-1: "record<createdAt: string, id: int, label: record<datasetId: int, id: int, name: string, numExamples: int>, location: string, name: string, object: string>"
    delete-model-1: "record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string>"
    get-trained-model-metrics-1: "record<algorithm: string, createdAt: string, id: string, language: string, metricsData: record, object: string>"
    get-trained-model-learning-curve-1: "record<data: table<epoch: record, epochResults: record, metricsData: record, object: string>, object: string>"
    ocr-multipart: "record<object: string, probabilities: table<attributes: record, boundingBox: record, label: string, probability: float>, sampleId: string, task: string>"
    predict-multipart: "record<object: string, probabilities: table<label: string, probability: float>, sampleId: string>"
    retrain-1: "record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string>"
    train-1: "record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string>"
    get-train-status-and-progress-1: "record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-api-usage-plans-v2" "list-datasets" "upload-dataset-async" "upload-dataset-sync" "delete-dataset" "get-dataset" "get-examples" "get-trained-models" "update-dataset-async" "get-v2-language-deletion-id" "get-examples-by-label" "provide-feedback" "intent-multipart" "delete-model" "get-trained-model-metrics" "get-trained-model-learning-curve" "retrain" "sentiment-multipart" "train" "get-train-status-and-progress" "generate-token-v2" "revoke-refresh-token-v2" "update-dataset-async-1" "list-datasets-1" "create-dataset" "upload-dataset-async-1" "upload-dataset-sync-1" "delete-dataset-1" "get-dataset-1" "get-examples-1" "add-example" "get-trained-models-1" "update-dataset-async-2" "get-1" "detect-multipart" "get-examples-by-label-1" "provide-feedback-1" "delete-model-1" "get-trained-model-metrics-1" "get-trained-model-learning-curve-1" "ocr-multipart" "predict-multipart" "retrain-1" "train-1" "get-train-status-and-progress-1" "commands"] | sort) } | get name | first)
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

# Get API Isage
#
# GET /v2/apiusage
# Returns: record<data: table<endsAt: string, id: string, licenseId: string, object: string, organizationId: string, planData: list, predictionsMax: int, predictionsUsed: int, startsAt: string>, object: string>
# operationId: getApiUsagePlansV2
export def "get-api-usage-plans-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apiusage"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Datasets
#
# GET /v2/language/datasets
# Returns: record<data: table<available: bool, createdAt: string, id: int, labelSummary: record, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>, object: string>
# operationId: listDatasets
export def "list-datasets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Index of the dataset from which you want to start paging (default: 0)
  --count: string # Number of datsets to return. Maximum valid value is 25. If you specify a number greater than 25, the call returns 25 datasets. (default: 25)
  --global: oneof<nothing, bool> # If true, returns all global datasets. Global datasets are public datasets that Salesforce provides. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/language/datasets"
    query: [{name: offset, var: offset}, {name: count, var: count}, {name: global, var: global}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, count: $count, global: $global
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Dataset From a File Asynchronously
#
# POST /v2/language/datasets/upload
# Returns: record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>
# operationId: uploadDatasetAsync
export def "upload-dataset-async" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Path to the .csv, .tsv, or .json file on the local drive (FilePart).
  --name: string # Name of the dataset. Optional. If this parameter is omitted, the dataset name is derived from the file name. (e.g. weather)
  --path: string # URL of the .csv, .tsv, or .json file.
  --type: string@type-completer # Type of dataset data.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/language/datasets/upload"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: data, var: data}, {name: name, var: name}, {name: path, var: path}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    data: $data, name: $name, path: $path, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Dataset From a File Synchronously
#
# POST /v2/language/datasets/upload/sync
# Returns: record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>
# operationId: uploadDatasetSync
export def "upload-dataset-sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Path to the .csv, .tsv, or .json file on the local drive (FilePart).
  --name: string # Name of the dataset. Optional. If this parameter is omitted, the dataset name is derived from the file name. (e.g. weather)
  --path: string # URL of the .csv, .tsv, or .json file.
  --type: string@type-completer # Type of dataset data.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/language/datasets/upload/sync"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: data, var: data}, {name: name, var: name}, {name: path, var: path}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    data: $data, name: $name, path: $path, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Dataset
#
# DELETE /v2/language/datasets/{datasetId}
# Returns: record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string>
# operationId: deleteDataset
export def "delete-dataset" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v2/language/datasets/{datasetId}"
    path_params: [{name: datasetId, var: dataset_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dataset_id: $dataset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Dataset
#
# GET /v2/language/datasets/{datasetId}
# Returns: record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>
# operationId: getDataset
export def "get-dataset" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/language/datasets/{datasetId}"
    path_params: [{name: datasetId, var: dataset_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dataset_id: $dataset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Examples
#
# GET /v2/language/datasets/{datasetId}/examples
# Returns: record<data: table<createdAt: string, id: int, label: record, location: string, name: string, object: string>, object: string>
# operationId: getExamples
export def "get-examples" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Index of the example from which you want to start paging. (default: 0)
  --count: string # Number of examples to return. (default: 100)
  --source: string@source-completer # return examples that were created in the dataset as feedback
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/language/datasets/{datasetId}/examples"
    path_params: [{name: datasetId, var: dataset_id}]
    query: [{name: offset, var: offset}, {name: count, var: count}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dataset_id: $dataset_id, offset: $offset, count: $count, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Models
#
# GET /v2/language/datasets/{datasetId}/models
# Returns: record<data: table<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, failureMsg: string, language: string, modelId: string, modelType: string, name: string, object: string, progress: float, status: string, updatedAt: string>, object: string>
# operationId: getTrainedModels
export def "get-trained-models" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Index of the model from which you want to start paging. (default: 0)
  --count: string # Number of models to return. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/language/datasets/{datasetId}/models"
    path_params: [{name: datasetId, var: dataset_id}]
    query: [{name: offset, var: offset}, {name: count, var: count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dataset_id: $dataset_id, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Examples From a File
#
# PUT /v2/language/datasets/{datasetId}/upload
# Returns: record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>
# operationId: updateDatasetAsync
export def "update-dataset-async" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Path to the .csv, .tsv, or .json file on a local drive.
  --type: string # URL of the .csv, .tsv, or .json file.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/language/datasets/{datasetId}/upload"
    path_params: [{name: datasetId, var: dataset_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: data, var: data}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dataset_id: $dataset_id, data: $data, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Deletion Status
#
# GET /v2/language/deletion/{id}
# Returns: record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string>
# operationId: get
export def "get-v2-language-deletion-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/language/deletion/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Examples for Label
#
# GET /v2/language/examples
# Returns: record<data: table<createdAt: string, id: int, label: record, location: string, name: string, object: string>, object: string>
# operationId: getExamplesByLabel
export def "get-examples-by-label" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label-id: string # Label Id (e.g. SomeLabelId)
  --offset: string # Index of the example from which you want to start paging. (default: 0)
  --count: string # Number of examples to return. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/language/examples"
    query: [{name: labelId, var: label_id}, {name: offset, var: offset}, {name: count, var: count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    label_id: $label_id, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Feedback Example
#
# POST /v2/language/feedback
# Returns: record<createdAt: string, id: int, label: record<datasetId: int, id: int, name: string, numExamples: int>, location: string, name: string, object: string>
# operationId: provideFeedback
export def "provide-feedback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document: string # Intent or sentiment string to add to the dataset.
  --expected-label: string # Correct label for the example. Must be a label that exists in the dataset.
  --model-id: string # ID of the model that misclassified the image. The feedback example is added to the dataset associated with this model.
  --name: string # Name of the example. Optional. Maximum length is 180 characters. (e.g. feedback-2)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/language/feedback"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: document, var: document}, {name: expectedLabel, var: expected_label}, {name: modelId, var: model_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document: $document, expected_label: $expected_label, model_id: $model_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Prediction for Intent
#
# POST /v2/language/intent
# Returns: record<object: string, probabilities: table<label: string, probability: float>, sampleId: string>
# operationId: intentMultipart
export def "intent-multipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  document: string # Text for which you want to return an intent prediction. (e.g. I can't tell you how much fun it was)
  model_id: string # ID of the model that makes the prediction. The model must have been created from a dataset with a type of text-sentiment. (e.g. WJH4YCA7YX4PCWVNCYNWYHBMY4)
  --num-results: int # Number of probabilities to return. (format: int32, e.g. 3)
  --sample-id: string # String that you can pass in to tag the prediction. Optional. Can be any value, and is returned in the response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/language/intent"
    body: {content_type: "application/json", kind: json, fields: [{name: document, var: document}, {name: modelId, var: model_id}, {name: numResults, var: num_results}, {name: sampleId, var: sample_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document: $document, model_id: $model_id, num_results: $num_results, sample_id: $sample_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Model
#
# DELETE /v2/language/models/{modelId}
# Returns: record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string>
# operationId: deleteModel
export def "delete-model" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v2/language/models/{modelId}"
    path_params: [{name: modelId, var: model_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    model_id: $model_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Model Metrics
#
# GET /v2/language/models/{modelId}
# Returns: record<algorithm: string, createdAt: string, id: string, language: string, metricsData: record, object: string>
# operationId: getTrainedModelMetrics
export def "get-trained-model-metrics" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/language/models/{modelId}"
    path_params: [{name: modelId, var: model_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Model Learning Curve
#
# GET /v2/language/models/{modelId}/lc
# Returns: record<data: table<epoch: record, epochResults: record, metricsData: record, object: string>, object: string>
# operationId: getTrainedModelLearningCurve
export def "get-trained-model-learning-curve" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Index of the epoch from which you want to start paging (default: 0)
  --count: string # Number of epoch to return. Maximum valid value is 25. (default: 25)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/language/models/{modelId}/lc"
    path_params: [{name: modelId, var: model_id}]
    query: [{name: offset, var: offset}, {name: count, var: count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrain a Dataset
#
# POST /v2/language/retrain
# Returns: record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string>
# operationId: retrain
export def "retrain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string # Algorithm used for train (e.g. intent)
  --epochs: int # Number of training iterations for the neural network. Optional. (format: int32, e.g. 20)
  --learning-rate: float # N/A for intent or sentiment models. (format: float, e.g. 0.0001)
  --model-id: string # ID of the model to be updated from the training. (e.g. 7JXCXTRXTMNLJCEF2DR5CJ46QU)
  --train-params: record # JSON that contains parameters that specify how the model is created — shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/language/retrain"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: algorithm, var: algorithm}, {name: epochs, var: epochs}, {name: learningRate, var: learning_rate}, {name: modelId, var: model_id}, {name: trainParams, var: train_params}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    algorithm: $algorithm, epochs: $epochs, learning_rate: $learning_rate, model_id: $model_id, train_params: $train_params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Prediction for Sentiment
#
# POST /v2/language/sentiment
# Returns: record<object: string, probabilities: table<label: string, probability: float>, sampleId: string>
# operationId: sentimentMultipart
export def "sentiment-multipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  document: string # Text for which you want to return a sentiment prediction. (e.g. I can't tell you how much fun it was)
  model_id: string # ID of the model that makes the prediction. The model must have been created from a dataset with a type of text-sentiment. (e.g. WJH4YCA7YX4PCWVNCYNWYHBMY4)
  --num-results: int # Number of probabilities to return. (format: int32, e.g. 3)
  --sample-id: string # String that you can pass in to tag the prediction. Optional. Can be any value, and is returned in the response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/language/sentiment"
    body: {content_type: "application/json", kind: json, fields: [{name: document, var: document}, {name: modelId, var: model_id}, {name: numResults, var: num_results}, {name: sampleId, var: sample_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document: $document, model_id: $model_id, num_results: $num_results, sample_id: $sample_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Train a Dataset
#
# POST /v2/language/train
# Returns: record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string>
# operationId: train
export def "train" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string # Algorithm used for train (e.g. intent)
  --dataset-id: int # ID of the dataset to train. (format: int64, e.g. 57)
  --epochs: int # Number of training iterations for the neural network. Optional. (format: int32, e.g. 20)
  --learning-rate: float # N/A for intent or sentiment models. (format: double)
  --name: string # Name of the model. Maximum length is 180 characters.
  --train-params: record # JSON that contains parameters that specify how the model is created — shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/language/train"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: algorithm, var: algorithm}, {name: datasetId, var: dataset_id}, {name: epochs, var: epochs}, {name: learningRate, var: learning_rate}, {name: name, var: name}, {name: trainParams, var: train_params}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    algorithm: $algorithm, dataset_id: $dataset_id, epochs: $epochs, learning_rate: $learning_rate, name: $name, train_params: $train_params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Training Status
#
# GET /v2/language/train/{modelId}
# Returns: record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string>
# operationId: getTrainStatusAndProgress
export def "get-train-status-and-progress" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/language/train/{modelId}"
    path_params: [{name: modelId, var: model_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate an OAuth Token
#
# POST /v2/oauth2/token
# Docs: https://metamind.readme.io/docs/generate-an-oauth-access-token — authentication guid
# Returns: record<access_token: string, expires_in: string, refresh_token: string, token_type: string>
# operationId: generateTokenV2
export def "generate-token-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assertion: string # encrypted payload to identify yourself (e.g. SOME_ASSERTION_STRING)
  --grant-type: string@grant-type-completer # specify the authentication method desired (e.g. urn:ietf:params:oauth:grant-type:jwt-bearer)
  --refresh-token: string # The refresh token you created previously. (e.g. SomeRefreshToken)
  --scope: string # set to `offline` to generate a refresh token (e.g. offline)
  --valid-for: int # Number of seconds until the access token expires. Default is 60 seconds. Maximum value is 30 days (format: int32, default: 60, e.g. 120)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/oauth2/token"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: assertion, var: assertion}, {name: grant_type, var: grant_type}, {name: refresh_token, var: refresh_token}, {name: scope, var: scope}, {name: valid_for, var: valid_for}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    assertion: $assertion, grant_type: $grant_type, refresh_token: $refresh_token, scope: $scope, valid_for: $valid_for
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Refresh Token
#
# DELETE /v2/oauth2/tokens/{token}
# operationId: revokeRefreshTokenV2
export def "revoke-refresh-token-v2" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/oauth2/tokens/{token}"
    path_params: [{name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Feedback Examples From a Zip File
#
# PUT /v2/vision/bulkfeedback
# Returns: record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>
# operationId: updateDatasetAsync_1
export def "update-dataset-async-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Local .zip file to upload. The maximum .zip file size you can upload from a local drive is 50 MB.
  --model-id: string # ID of the model that misclassified the images. The feedback examples are added to the dataset associated with this model.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/vision/bulkfeedback"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: data, var: data}, {name: modelId, var: model_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    data: $data, model_id: $model_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Datasets
#
# GET /v2/vision/datasets
# Returns: record<data: table<available: bool, createdAt: string, id: int, labelSummary: record, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>, object: string>
# operationId: listDatasets_1
export def "list-datasets-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Index of the dataset from which you want to start paging (default: 0)
  --count: string # Number of datsets to return. Maximum valid value is 25. If you specify a number greater than 25, the call returns 25 datasets. (default: 25)
  --global: oneof<nothing, bool> # If true, returns all global datasets. Global datasets are public datasets that Salesforce provides. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/vision/datasets"
    query: [{name: offset, var: offset}, {name: count, var: count}, {name: global, var: global}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, count: $count, global: $global
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Dataset
#
# POST /v2/vision/datasets
# Returns: record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>
# operationId: createDataset
export def "create-dataset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --labels: string # Optional comma-separated list of labels. If specified, creates the labels in the dataset. Maximum number of labels per dataset is 250. (e.g. beach,mountain)
  --name: string # Name of the dataset. Maximum length is 180 characters. (e.g. Beach and Mountain)
  --type: string@type-completer-1 # Type of dataset data
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/vision/datasets"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: labels, var: labels}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    labels: $labels, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Dataset From a Zip File Asynchronously
#
# POST /v2/vision/datasets/upload
# Returns: record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>
# operationId: uploadDatasetAsync_1
export def "upload-dataset-async-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Path to the .zip file on the local drive (FilePart).
  --name: string # Name of the dataset. Optional. If this parameter is omitted, the dataset name is derived from the .zip file name. (e.g. mountainvsbeach)
  --path: string # URL of the .zip file.
  --type: string@type-completer-2 # Type of dataset data.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/vision/datasets/upload"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: data, var: data}, {name: name, var: name}, {name: path, var: path}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    data: $data, name: $name, path: $path, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Dataset From a Zip File Synchronously
#
# POST /v2/vision/datasets/upload/sync
# Returns: record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>
# operationId: uploadDatasetSync_1
export def "upload-dataset-sync-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Path to the .zip file on the local drive (FilePart).
  --name: string # Name of the dataset. Optional. If this parameter is omitted, the dataset name is derived from the .zip file name. (e.g. mountainvsbeach)
  --path: string # URL of the .zip file.
  --type: string@type-completer-2 # Type of dataset data.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/vision/datasets/upload/sync"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: data, var: data}, {name: name, var: name}, {name: path, var: path}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    data: $data, name: $name, path: $path, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Dataset
#
# DELETE /v2/vision/datasets/{datasetId}
# Returns: record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string>
# operationId: deleteDataset_1
export def "delete-dataset-1" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v2/vision/datasets/{datasetId}"
    path_params: [{name: datasetId, var: dataset_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    dataset_id: $dataset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Dataset
#
# GET /v2/vision/datasets/{datasetId}
# Returns: record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>
# operationId: getDataset_1
export def "get-dataset-1" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/vision/datasets/{datasetId}"
    path_params: [{name: datasetId, var: dataset_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dataset_id: $dataset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Examples
#
# GET /v2/vision/datasets/{datasetId}/examples
# Returns: record<data: table<createdAt: string, id: int, label: record, location: string, name: string, object: string>, object: string>
# operationId: getExamples_1
export def "get-examples-1" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Index of the example from which you want to start paging. (default: 0)
  --count: string # Number of examples to return. (default: 100)
  --source: string@source-completer # return examples that were created in the dataset as feedback
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/vision/datasets/{datasetId}/examples"
    path_params: [{name: datasetId, var: dataset_id}]
    query: [{name: offset, var: offset}, {name: count, var: count}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dataset_id: $dataset_id, offset: $offset, count: $count, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Example
#
# POST /v2/vision/datasets/{datasetId}/examples
# Returns: record<createdAt: string, id: int, label: record<datasetId: int, id: int, name: string, numExamples: int>, location: string, name: string, object: string>
# operationId: addExample
export def "add-example" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Location of the local image file to upload.
  --label-id: int # ID of the label to add to the example. (format: int64, e.g. 42)
  --name: string # Name of the example. Maximum length is 180 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/vision/datasets/{datasetId}/examples"
    path_params: [{name: datasetId, var: dataset_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: data, var: data}, {name: labelId, var: label_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dataset_id: $dataset_id, data: $data, label_id: $label_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Models
#
# GET /v2/vision/datasets/{datasetId}/models
# Returns: record<data: table<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, failureMsg: string, language: string, modelId: string, modelType: string, name: string, object: string, progress: float, status: string, updatedAt: string>, object: string>
# operationId: getTrainedModels_1
export def "get-trained-models-1" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Index of the model from which you want to start paging. (default: 0)
  --count: string # Number of models to return. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/vision/datasets/{datasetId}/models"
    path_params: [{name: datasetId, var: dataset_id}]
    query: [{name: offset, var: offset}, {name: count, var: count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dataset_id: $dataset_id, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Examples From a Zip File
#
# PUT /v2/vision/datasets/{datasetId}/upload
# Returns: record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>
# operationId: updateDatasetAsync_2
export def "update-dataset-async-2" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Location of the local image file to upload.
  --path: string # URL of the .zip file.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/vision/datasets/{datasetId}/upload"
    path_params: [{name: datasetId, var: dataset_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: data, var: data}, {name: path, var: path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dataset_id: $dataset_id, data: $data, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Deletion Status
#
# GET /v2/vision/deletion/{id}
# Returns: record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string>
# operationId: get_1
export def "get-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/vision/deletion/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detection with Image File
#
# POST /v2/vision/detect
# Returns: record<object: string, probabilities: table<boundingBox: record, label: string, probability: float>, sampleId: string>
# operationId: detectMultipart
export def "detect-multipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  model_id: string # ID of the model that makes the detection. (e.g. YCQ4ZACEPJFGXZNRA6ERF3GL5E)
  --sample-base64-content: string # The image contained in a base64 string. (e.g. SomeBase64EncodedImage)
  --sample-id: string # String that you can pass in to tag the prediction. Optional. Can be any value, and is returned in the response.
  --sample-location: string # URL of the image file.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/vision/detect"
    body: {content_type: "application/json", kind: json, fields: [{name: modelId, var: model_id}, {name: sampleBase64Content, var: sample_base64_content}, {name: sampleId, var: sample_id}, {name: sampleLocation, var: sample_location}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id, sample_base64_content: $sample_base64_content, sample_id: $sample_id, sample_location: $sample_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Examples for Label
#
# GET /v2/vision/examples
# Returns: record<data: table<createdAt: string, id: int, label: record, location: string, name: string, object: string>, object: string>
# operationId: getExamplesByLabel_1
export def "get-examples-by-label-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label-id: string # Label Id (e.g. SomeLabelId)
  --offset: string # Index of the example from which you want to start paging. (default: 0)
  --count: string # Number of examples to return. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/vision/examples"
    query: [{name: labelId, var: label_id}, {name: offset, var: offset}, {name: count, var: count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    label_id: $label_id, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Feedback Example
#
# POST /v2/vision/feedback
# Returns: record<createdAt: string, id: int, label: record<datasetId: int, id: int, name: string, numExamples: int>, location: string, name: string, object: string>
# operationId: provideFeedback_1
export def "provide-feedback-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Local image file to upload.
  --expected-label: string # Correct label for the example. Must be a label that exists in the dataset.
  --model-id: string # ID of the model that misclassified the image. The feedback example is added to the dataset associated with this model.
  --name: string # Name of the example. Optional. Maximum length is 180 characters. (e.g. feedback-1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/vision/feedback"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: data, var: data}, {name: expectedLabel, var: expected_label}, {name: modelId, var: model_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    data: $data, expected_label: $expected_label, model_id: $model_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Model
#
# DELETE /v2/vision/models/{modelId}
# Returns: record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string>
# operationId: deleteModel_1
export def "delete-model-1" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v2/vision/models/{modelId}"
    path_params: [{name: modelId, var: model_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    model_id: $model_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Model Metrics
#
# GET /v2/vision/models/{modelId}
# Returns: record<algorithm: string, createdAt: string, id: string, language: string, metricsData: record, object: string>
# operationId: getTrainedModelMetrics_1
export def "get-trained-model-metrics-1" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/vision/models/{modelId}"
    path_params: [{name: modelId, var: model_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Model Learning Curve
#
# GET /v2/vision/models/{modelId}/lc
# Returns: record<data: table<epoch: record, epochResults: record, metricsData: record, object: string>, object: string>
# operationId: getTrainedModelLearningCurve_1
export def "get-trained-model-learning-curve-1" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Index of the epoch from which you want to start paging (default: 0)
  --count: string # Number of epoch to return. Maximum valid value is 25. (default: 25)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/vision/models/{modelId}/lc"
    path_params: [{name: modelId, var: model_id}]
    query: [{name: offset, var: offset}, {name: count, var: count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detect Text
#
# POST /v2/vision/ocr
# Returns: record<object: string, probabilities: table<attributes: record, boundingBox: record, label: string, probability: float>, sampleId: string, task: string>
# operationId: ocrMultipart
export def "ocr-multipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --model-id: string # ID of the model that makes the prediction. Valid values are OCRModel and tabulatev2. (e.g. WJH4YCA7YX4PCWVNCYNWYHBMY4)
  --sample-content: string # Binary content of image file uploaded as multipart/form-data. Optional. (format: binary)
  --sample-id: string # String that you can pass in to tag the prediction. Optional. Can be any value, and is returned in the response.
  --sample-location: string # URL of the image file. Use this parameter when sending in a file from a web location. Optional.
  --task: string # Optional. Designates the type of data in the image. Default is text. Valid values: contact, table, and text. (default: text, e.g. table)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/vision/ocr"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: modelId, var: model_id}, {name: sampleContent, var: sample_content}, {name: sampleId, var: sample_id}, {name: sampleLocation, var: sample_location}, {name: task, var: task}], files: [sampleContent]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id, sample_content: $sample_content, sample_id: $sample_id, sample_location: $sample_location, task: $task
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Make Prediction
#
# POST /v2/vision/predict
# Returns: record<object: string, probabilities: table<label: string, probability: float>, sampleId: string>
# operationId: predictMultipart
export def "predict-multipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  model_id: string # ID of the model that makes the prediction. (e.g. WJH4YCA7YX4PCWVNCYNWYHBMY4)
  --num-results: int # Number of probabilities to return. (format: int32, e.g. 3)
  --sample-base64-content: string # The image contained in a base64 string. (e.g. SomeBase64EncodedImage)
  --sample-id: string # String that you can pass in to tag the prediction. Optional. Can be any value, and is returned in the response.
  --sample-location: string # URL of the image file.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/vision/predict"
    body: {content_type: "application/json", kind: json, fields: [{name: modelId, var: model_id}, {name: numResults, var: num_results}, {name: sampleBase64Content, var: sample_base64_content}, {name: sampleId, var: sample_id}, {name: sampleLocation, var: sample_location}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id, num_results: $num_results, sample_base64_content: $sample_base64_content, sample_id: $sample_id, sample_location: $sample_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrain a Dataset
#
# POST /v2/vision/retrain
# Returns: record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string>
# operationId: retrain_1
export def "retrain-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string # Specifies the algorithm used to train the dataset. Optional. Use this parameter only when training a dataset with a type of image-detection. Valid values are object-detection-v1 and retail-execution. (e.g. object-detection)
  --epochs: int # Number of training iterations for the neural network. Optional. (format: int32, e.g. 20)
  --learning-rate: float # Specifies how much the gradient affects the optimization of the model at each time step. Optional. (format: float, e.g. 0.0001)
  --model-id: string # ID of the model to be updated from the training. (e.g. 7JXCXTRXTMNLJCEF2DR5CJ46QU)
  --train-params: record # JSON that contains parameters that specify how the model is created — shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/vision/retrain"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: algorithm, var: algorithm}, {name: epochs, var: epochs}, {name: learningRate, var: learning_rate}, {name: modelId, var: model_id}, {name: trainParams, var: train_params}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    algorithm: $algorithm, epochs: $epochs, learning_rate: $learning_rate, model_id: $model_id, train_params: $train_params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Train a Dataset
#
# POST /v2/vision/train
# Returns: record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string>
# operationId: train_1
export def "train-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string # Specifies the algorithm used to train the dataset. Optional. Use this parameter only when training a dataset with a type of image-detection. Valid values are object-detection-v1 and retail-execution. (e.g. object-detection)
  --dataset-id: int # ID of the dataset to train. (format: int64, e.g. 57)
  --epochs: int # Number of training iterations for the neural network. Optional. (format: int32, e.g. 20)
  --learning-rate: float # Specifies how much the gradient affects the optimization of the model at each time step. Optional. (format: double, e.g. 0.0001)
  --name: string # Name of the model. Maximum length is 180 characters.
  --train-params: record # JSON that contains parameters that specify how the model is created — shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/vision/train"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: algorithm, var: algorithm}, {name: datasetId, var: dataset_id}, {name: epochs, var: epochs}, {name: learningRate, var: learning_rate}, {name: name, var: name}, {name: trainParams, var: train_params}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    algorithm: $algorithm, dataset_id: $dataset_id, epochs: $epochs, learning_rate: $learning_rate, name: $name, train_params: $train_params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Training Status
#
# GET /v2/vision/train/{modelId}
# Returns: record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string>
# operationId: getTrainStatusAndProgress_1
export def "get-train-status-and-progress-1" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/vision/train/{modelId}"
    path_params: [{name: modelId, var: model_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
