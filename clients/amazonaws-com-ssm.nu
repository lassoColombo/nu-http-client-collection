# Auto-generated client for Amazon Simple Systems Manager (SSM) v2014-11-06
# Source: https://api.apis.guru/v2/specs/amazonaws.com/ssm/2014-11-06/openapi.json
# Auth: --token flag or $env.AMAZON_SIMPLE_SYSTEMS_MANAGER_SSM_TOKEN

const CLIENT = {
  base_url: "http://ssm.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_SIMPLE_SYSTEMS_MANAGER_SSM_TOKEN"
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

def base-url-completer [] { ["http://ssm.us-east-1.amazonaws.com" "http://ssm.us-east-2.amazonaws.com" "http://ssm.us-west-1.amazonaws.com" "http://ssm.us-west-2.amazonaws.com" "http://ssm.us-gov-west-1.amazonaws.com" "http://ssm.us-gov-east-1.amazonaws.com" "http://ssm.ca-central-1.amazonaws.com" "http://ssm.eu-north-1.amazonaws.com" "http://ssm.eu-west-1.amazonaws.com" "http://ssm.eu-west-2.amazonaws.com" "http://ssm.eu-west-3.amazonaws.com" "http://ssm.eu-central-1.amazonaws.com" "http://ssm.eu-south-1.amazonaws.com" "http://ssm.af-south-1.amazonaws.com" "http://ssm.ap-northeast-1.amazonaws.com" "http://ssm.ap-northeast-2.amazonaws.com" "http://ssm.ap-northeast-3.amazonaws.com" "http://ssm.ap-southeast-1.amazonaws.com" "http://ssm.ap-southeast-2.amazonaws.com" "http://ssm.ap-east-1.amazonaws.com" "http://ssm.ap-south-1.amazonaws.com" "http://ssm.sa-east-1.amazonaws.com" "http://ssm.me-south-1.amazonaws.com" "https://ssm.us-east-1.amazonaws.com" "https://ssm.us-east-2.amazonaws.com" "https://ssm.us-west-1.amazonaws.com" "https://ssm.us-west-2.amazonaws.com" "https://ssm.us-gov-west-1.amazonaws.com" "https://ssm.us-gov-east-1.amazonaws.com" "https://ssm.ca-central-1.amazonaws.com" "https://ssm.eu-north-1.amazonaws.com" "https://ssm.eu-west-1.amazonaws.com" "https://ssm.eu-west-2.amazonaws.com" "https://ssm.eu-west-3.amazonaws.com" "https://ssm.eu-central-1.amazonaws.com" "https://ssm.eu-south-1.amazonaws.com" "https://ssm.af-south-1.amazonaws.com" "https://ssm.ap-northeast-1.amazonaws.com" "https://ssm.ap-northeast-2.amazonaws.com" "https://ssm.ap-northeast-3.amazonaws.com" "https://ssm.ap-southeast-1.amazonaws.com" "https://ssm.ap-southeast-2.amazonaws.com" "https://ssm.ap-east-1.amazonaws.com" "https://ssm.ap-south-1.amazonaws.com" "https://ssm.sa-east-1.amazonaws.com" "https://ssm.me-south-1.amazonaws.com" "http://ssm.cn-north-1.amazonaws.com.cn" "http://ssm.cn-northwest-1.amazonaws.com.cn" "https://ssm.cn-north-1.amazonaws.com.cn" "https://ssm.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def resource-type-completer [] { ["Association" "Automation" "Document" "MaintenanceWindow" "ManagedInstance" "OpsItem" "OpsMetadata" "Parameter" "PatchBaseline"] }
def x-amz-target-completer [] { ["AmazonSSM.AddTagsToResource"] }
def x-amz-target-completer-1 [] { ["AmazonSSM.AssociateOpsItemRelatedItem"] }
def x-amz-target-completer-2 [] { ["AmazonSSM.CancelCommand"] }
def x-amz-target-completer-3 [] { ["AmazonSSM.CancelMaintenanceWindowExecution"] }
def x-amz-target-completer-4 [] { ["AmazonSSM.CreateActivation"] }
def compliance-severity-completer [] { ["CRITICAL" "HIGH" "LOW" "MEDIUM" "UNSPECIFIED"] }
def sync-compliance-completer [] { ["AUTO" "MANUAL"] }
def x-amz-target-completer-5 [] { ["AmazonSSM.CreateAssociation"] }
def x-amz-target-completer-6 [] { ["AmazonSSM.CreateAssociationBatch"] }
def document-type-completer [] { ["ApplicationConfiguration" "ApplicationConfigurationSchema" "Automation" "Automation.ChangeTemplate" "ChangeCalendar" "CloudFormation" "Command" "ConformancePackTemplate" "DeploymentStrategy" "Package" "Policy" "ProblemAnalysis" "ProblemAnalysisTemplate" "QuickSetup" "Session"] }
def document-format-completer [] { ["JSON" "TEXT" "YAML"] }
def x-amz-target-completer-7 [] { ["AmazonSSM.CreateDocument"] }
def x-amz-target-completer-8 [] { ["AmazonSSM.CreateMaintenanceWindow"] }
def x-amz-target-completer-9 [] { ["AmazonSSM.CreateOpsItem"] }
def x-amz-target-completer-10 [] { ["AmazonSSM.CreateOpsMetadata"] }
def operating-system-completer [] { ["ALMA_LINUX" "AMAZON_LINUX" "AMAZON_LINUX_2" "AMAZON_LINUX_2022" "AMAZON_LINUX_2023" "CENTOS" "DEBIAN" "MACOS" "ORACLE_LINUX" "RASPBIAN" "REDHAT_ENTERPRISE_LINUX" "ROCKY_LINUX" "SUSE" "UBUNTU" "WINDOWS"] }
def approved-patches-compliance-level-completer [] { ["CRITICAL" "HIGH" "INFORMATIONAL" "LOW" "MEDIUM" "UNSPECIFIED"] }
def rejected-patches-action-completer [] { ["ALLOW_AS_DEPENDENCY" "BLOCK"] }
def x-amz-target-completer-11 [] { ["AmazonSSM.CreatePatchBaseline"] }
def x-amz-target-completer-12 [] { ["AmazonSSM.CreateResourceDataSync"] }
def x-amz-target-completer-13 [] { ["AmazonSSM.DeleteActivation"] }
def x-amz-target-completer-14 [] { ["AmazonSSM.DeleteAssociation"] }
def x-amz-target-completer-15 [] { ["AmazonSSM.DeleteDocument"] }
def schema-delete-option-completer [] { ["DeleteSchema" "DisableSchema"] }
def x-amz-target-completer-16 [] { ["AmazonSSM.DeleteInventory"] }
def x-amz-target-completer-17 [] { ["AmazonSSM.DeleteMaintenanceWindow"] }
def x-amz-target-completer-18 [] { ["AmazonSSM.DeleteOpsMetadata"] }
def x-amz-target-completer-19 [] { ["AmazonSSM.DeleteParameter"] }
def x-amz-target-completer-20 [] { ["AmazonSSM.DeleteParameters"] }
def x-amz-target-completer-21 [] { ["AmazonSSM.DeletePatchBaseline"] }
def x-amz-target-completer-22 [] { ["AmazonSSM.DeleteResourceDataSync"] }
def x-amz-target-completer-23 [] { ["AmazonSSM.DeleteResourcePolicy"] }
def x-amz-target-completer-24 [] { ["AmazonSSM.DeregisterManagedInstance"] }
def x-amz-target-completer-25 [] { ["AmazonSSM.DeregisterPatchBaselineForPatchGroup"] }
def x-amz-target-completer-26 [] { ["AmazonSSM.DeregisterTargetFromMaintenanceWindow"] }
def x-amz-target-completer-27 [] { ["AmazonSSM.DeregisterTaskFromMaintenanceWindow"] }
def x-amz-target-completer-28 [] { ["AmazonSSM.DescribeActivations"] }
def x-amz-target-completer-29 [] { ["AmazonSSM.DescribeAssociation"] }
def x-amz-target-completer-30 [] { ["AmazonSSM.DescribeAssociationExecutionTargets"] }
def x-amz-target-completer-31 [] { ["AmazonSSM.DescribeAssociationExecutions"] }
def x-amz-target-completer-32 [] { ["AmazonSSM.DescribeAutomationExecutions"] }
def x-amz-target-completer-33 [] { ["AmazonSSM.DescribeAutomationStepExecutions"] }
def x-amz-target-completer-34 [] { ["AmazonSSM.DescribeAvailablePatches"] }
def x-amz-target-completer-35 [] { ["AmazonSSM.DescribeDocument"] }
def permission-type-completer [] { ["Share"] }
def x-amz-target-completer-36 [] { ["AmazonSSM.DescribeDocumentPermission"] }
def x-amz-target-completer-37 [] { ["AmazonSSM.DescribeEffectiveInstanceAssociations"] }
def x-amz-target-completer-38 [] { ["AmazonSSM.DescribeEffectivePatchesForPatchBaseline"] }
def x-amz-target-completer-39 [] { ["AmazonSSM.DescribeInstanceAssociationsStatus"] }
def x-amz-target-completer-40 [] { ["AmazonSSM.DescribeInstanceInformation"] }
def x-amz-target-completer-41 [] { ["AmazonSSM.DescribeInstancePatchStates"] }
def x-amz-target-completer-42 [] { ["AmazonSSM.DescribeInstancePatchStatesForPatchGroup"] }
def x-amz-target-completer-43 [] { ["AmazonSSM.DescribeInstancePatches"] }
def x-amz-target-completer-44 [] { ["AmazonSSM.DescribeInventoryDeletions"] }
def x-amz-target-completer-45 [] { ["AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations"] }
def x-amz-target-completer-46 [] { ["AmazonSSM.DescribeMaintenanceWindowExecutionTasks"] }
def x-amz-target-completer-47 [] { ["AmazonSSM.DescribeMaintenanceWindowExecutions"] }
def resource-type-completer-1 [] { ["INSTANCE" "RESOURCE_GROUP"] }
def x-amz-target-completer-48 [] { ["AmazonSSM.DescribeMaintenanceWindowSchedule"] }
def x-amz-target-completer-49 [] { ["AmazonSSM.DescribeMaintenanceWindowTargets"] }
def x-amz-target-completer-50 [] { ["AmazonSSM.DescribeMaintenanceWindowTasks"] }
def x-amz-target-completer-51 [] { ["AmazonSSM.DescribeMaintenanceWindows"] }
def x-amz-target-completer-52 [] { ["AmazonSSM.DescribeMaintenanceWindowsForTarget"] }
def x-amz-target-completer-53 [] { ["AmazonSSM.DescribeOpsItems"] }
def x-amz-target-completer-54 [] { ["AmazonSSM.DescribeParameters"] }
def x-amz-target-completer-55 [] { ["AmazonSSM.DescribePatchBaselines"] }
def x-amz-target-completer-56 [] { ["AmazonSSM.DescribePatchGroupState"] }
def x-amz-target-completer-57 [] { ["AmazonSSM.DescribePatchGroups"] }
def property-completer [] { ["CLASSIFICATION" "MSRC_SEVERITY" "PRIORITY" "PRODUCT" "PRODUCT_FAMILY" "SEVERITY"] }
def patch-set-completer [] { ["APPLICATION" "OS"] }
def x-amz-target-completer-58 [] { ["AmazonSSM.DescribePatchProperties"] }
def state-completer [] { ["Active" "History"] }
def x-amz-target-completer-59 [] { ["AmazonSSM.DescribeSessions"] }
def x-amz-target-completer-60 [] { ["AmazonSSM.DisassociateOpsItemRelatedItem"] }
def x-amz-target-completer-61 [] { ["AmazonSSM.GetAutomationExecution"] }
def x-amz-target-completer-62 [] { ["AmazonSSM.GetCalendarState"] }
def x-amz-target-completer-63 [] { ["AmazonSSM.GetCommandInvocation"] }
def x-amz-target-completer-64 [] { ["AmazonSSM.GetConnectionStatus"] }
def x-amz-target-completer-65 [] { ["AmazonSSM.GetDefaultPatchBaseline"] }
def x-amz-target-completer-66 [] { ["AmazonSSM.GetDeployablePatchSnapshotForInstance"] }
def x-amz-target-completer-67 [] { ["AmazonSSM.GetDocument"] }
def x-amz-target-completer-68 [] { ["AmazonSSM.GetInventory"] }
def x-amz-target-completer-69 [] { ["AmazonSSM.GetInventorySchema"] }
def x-amz-target-completer-70 [] { ["AmazonSSM.GetMaintenanceWindow"] }
def x-amz-target-completer-71 [] { ["AmazonSSM.GetMaintenanceWindowExecution"] }
def x-amz-target-completer-72 [] { ["AmazonSSM.GetMaintenanceWindowExecutionTask"] }
def x-amz-target-completer-73 [] { ["AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation"] }
def x-amz-target-completer-74 [] { ["AmazonSSM.GetMaintenanceWindowTask"] }
def x-amz-target-completer-75 [] { ["AmazonSSM.GetOpsItem"] }
def x-amz-target-completer-76 [] { ["AmazonSSM.GetOpsMetadata"] }
def x-amz-target-completer-77 [] { ["AmazonSSM.GetOpsSummary"] }
def x-amz-target-completer-78 [] { ["AmazonSSM.GetParameter"] }
def x-amz-target-completer-79 [] { ["AmazonSSM.GetParameterHistory"] }
def x-amz-target-completer-80 [] { ["AmazonSSM.GetParameters"] }
def x-amz-target-completer-81 [] { ["AmazonSSM.GetParametersByPath"] }
def x-amz-target-completer-82 [] { ["AmazonSSM.GetPatchBaseline"] }
def x-amz-target-completer-83 [] { ["AmazonSSM.GetPatchBaselineForPatchGroup"] }
def x-amz-target-completer-84 [] { ["AmazonSSM.GetResourcePolicies"] }
def x-amz-target-completer-85 [] { ["AmazonSSM.GetServiceSetting"] }
def x-amz-target-completer-86 [] { ["AmazonSSM.LabelParameterVersion"] }
def x-amz-target-completer-87 [] { ["AmazonSSM.ListAssociationVersions"] }
def x-amz-target-completer-88 [] { ["AmazonSSM.ListAssociations"] }
def x-amz-target-completer-89 [] { ["AmazonSSM.ListCommandInvocations"] }
def x-amz-target-completer-90 [] { ["AmazonSSM.ListCommands"] }
def x-amz-target-completer-91 [] { ["AmazonSSM.ListComplianceItems"] }
def x-amz-target-completer-92 [] { ["AmazonSSM.ListComplianceSummaries"] }
def metadata-completer [] { ["DocumentReviews"] }
def x-amz-target-completer-93 [] { ["AmazonSSM.ListDocumentMetadataHistory"] }
def x-amz-target-completer-94 [] { ["AmazonSSM.ListDocumentVersions"] }
def x-amz-target-completer-95 [] { ["AmazonSSM.ListDocuments"] }
def x-amz-target-completer-96 [] { ["AmazonSSM.ListInventoryEntries"] }
def x-amz-target-completer-97 [] { ["AmazonSSM.ListOpsItemEvents"] }
def x-amz-target-completer-98 [] { ["AmazonSSM.ListOpsItemRelatedItems"] }
def x-amz-target-completer-99 [] { ["AmazonSSM.ListOpsMetadata"] }
def x-amz-target-completer-100 [] { ["AmazonSSM.ListResourceComplianceSummaries"] }
def x-amz-target-completer-101 [] { ["AmazonSSM.ListResourceDataSync"] }
def x-amz-target-completer-102 [] { ["AmazonSSM.ListTagsForResource"] }
def x-amz-target-completer-103 [] { ["AmazonSSM.ModifyDocumentPermission"] }
def upload-type-completer [] { ["COMPLETE" "PARTIAL"] }
def x-amz-target-completer-104 [] { ["AmazonSSM.PutComplianceItems"] }
def x-amz-target-completer-105 [] { ["AmazonSSM.PutInventory"] }
def type-completer [] { ["SecureString" "String" "StringList"] }
def tier-completer [] { ["Advanced" "Intelligent-Tiering" "Standard"] }
def x-amz-target-completer-106 [] { ["AmazonSSM.PutParameter"] }
def x-amz-target-completer-107 [] { ["AmazonSSM.PutResourcePolicy"] }
def x-amz-target-completer-108 [] { ["AmazonSSM.RegisterDefaultPatchBaseline"] }
def x-amz-target-completer-109 [] { ["AmazonSSM.RegisterPatchBaselineForPatchGroup"] }
def x-amz-target-completer-110 [] { ["AmazonSSM.RegisterTargetWithMaintenanceWindow"] }
def task-type-completer [] { ["AUTOMATION" "LAMBDA" "RUN_COMMAND" "STEP_FUNCTIONS"] }
def cutoff-behavior-completer [] { ["CANCEL_TASK" "CONTINUE_TASK"] }
def x-amz-target-completer-111 [] { ["AmazonSSM.RegisterTaskWithMaintenanceWindow"] }
def x-amz-target-completer-112 [] { ["AmazonSSM.RemoveTagsFromResource"] }
def x-amz-target-completer-113 [] { ["AmazonSSM.ResetServiceSetting"] }
def x-amz-target-completer-114 [] { ["AmazonSSM.ResumeSession"] }
def signal-type-completer [] { ["Approve" "Reject" "Resume" "StartStep" "StopStep"] }
def x-amz-target-completer-115 [] { ["AmazonSSM.SendAutomationSignal"] }
def document-hash-type-completer [] { ["Sha1" "Sha256"] }
def x-amz-target-completer-116 [] { ["AmazonSSM.SendCommand"] }
def x-amz-target-completer-117 [] { ["AmazonSSM.StartAssociationsOnce"] }
def mode-completer [] { ["Auto" "Interactive"] }
def x-amz-target-completer-118 [] { ["AmazonSSM.StartAutomationExecution"] }
def x-amz-target-completer-119 [] { ["AmazonSSM.StartChangeRequestExecution"] }
def x-amz-target-completer-120 [] { ["AmazonSSM.StartSession"] }
def type-completer-1 [] { ["Cancel" "Complete"] }
def x-amz-target-completer-121 [] { ["AmazonSSM.StopAutomationExecution"] }
def x-amz-target-completer-122 [] { ["AmazonSSM.TerminateSession"] }
def x-amz-target-completer-123 [] { ["AmazonSSM.UnlabelParameterVersion"] }
def x-amz-target-completer-124 [] { ["AmazonSSM.UpdateAssociation"] }
def x-amz-target-completer-125 [] { ["AmazonSSM.UpdateAssociationStatus"] }
def x-amz-target-completer-126 [] { ["AmazonSSM.UpdateDocument"] }
def x-amz-target-completer-127 [] { ["AmazonSSM.UpdateDocumentDefaultVersion"] }
def x-amz-target-completer-128 [] { ["AmazonSSM.UpdateDocumentMetadata"] }
def x-amz-target-completer-129 [] { ["AmazonSSM.UpdateMaintenanceWindow"] }
def x-amz-target-completer-130 [] { ["AmazonSSM.UpdateMaintenanceWindowTarget"] }
def x-amz-target-completer-131 [] { ["AmazonSSM.UpdateMaintenanceWindowTask"] }
def x-amz-target-completer-132 [] { ["AmazonSSM.UpdateManagedInstanceRole"] }
def status-completer [] { ["Approved" "Cancelled" "Cancelling" "ChangeCalendarOverrideApproved" "ChangeCalendarOverrideRejected" "Closed" "CompletedWithFailure" "CompletedWithSuccess" "Failed" "InProgress" "Open" "Pending" "PendingApproval" "PendingChangeCalendarOverride" "Rejected" "Resolved" "RunbookInProgress" "Scheduled" "TimedOut"] }
def x-amz-target-completer-133 [] { ["AmazonSSM.UpdateOpsItem"] }
def x-amz-target-completer-134 [] { ["AmazonSSM.UpdateOpsMetadata"] }
def x-amz-target-completer-135 [] { ["AmazonSSM.UpdatePatchBaseline"] }
def x-amz-target-completer-136 [] { ["AmazonSSM.UpdateResourceDataSync"] }
def x-amz-target-completer-137 [] { ["AmazonSSM.UpdateServiceSetting"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    add-tags-to-resource: "record"
    associate-ops-item-related-item: "record<AssociationId: string>"
    cancel-command: "record"
    cancel-maintenance-window-execution: "record<WindowExecutionId: string>"
    create-activation: "record<ActivationId: string, ActivationCode: string>"
    create-association: "record<AssociationDescription: record<Name: string, InstanceId: string, AssociationVersion: string, Date: string, LastUpdateAssociationDate: string, Status: record<Date: string, Name: string, Message: string, AdditionalInfo: string>, Overview: record<Status: string, DetailedStatus: string, AssociationStatusAggregatedCount: record>, DocumentVersion: string, AutomationTargetParameterName: string, Parameters: record, AssociationId: string, Targets: list<record>, ScheduleExpression: string, OutputLocation: record<S3Location: record>, LastExecutionDate: string, LastSuccessfulExecutionDate: string, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list<string>, TargetLocations: list<record>, ScheduleOffset: int, TargetMaps: list<record>, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>>>"
    create-association-batch: "record<Successful: table<Name: string, InstanceId: string, AssociationVersion: string, Date: string, LastUpdateAssociationDate: string, Status: record, Overview: record, DocumentVersion: string, AutomationTargetParameterName: string, Parameters: record, AssociationId: string, Targets: list, ScheduleExpression: string, OutputLocation: record, LastExecutionDate: string, LastSuccessfulExecutionDate: string, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list, TargetLocations: list, ScheduleOffset: int, TargetMaps: list, AlarmConfiguration: record, TriggeredAlarms: list>, Failed: table<Entry: record, Message: string, Fault: string>>"
    create-document: "record<DocumentDescription: record<Sha1: string, Hash: string, HashType: string, Name: string, DisplayName: string, VersionName: string, Owner: string, CreatedDate: string, Status: string, StatusInformation: string, DocumentVersion: string, Description: string, Parameters: list<record>, PlatformTypes: list<string>, DocumentType: string, SchemaVersion: string, LatestVersion: string, DefaultVersion: string, DocumentFormat: string, TargetType: string, Tags: list<record>, AttachmentsInformation: list<record>, Requires: list<record>, Author: string, ReviewInformation: list<record>, ApprovedVersion: string, PendingReviewVersion: string, ReviewStatus: string, Category: list<string>, CategoryEnum: list<string>>>"
    create-maintenance-window: "record<WindowId: string>"
    create-ops-item: "record<OpsItemId: string, OpsItemArn: string>"
    create-ops-metadata: "record<OpsMetadataArn: string>"
    create-patch-baseline: "record<BaselineId: string>"
    create-resource-data-sync: "record"
    delete-activation: "record"
    delete-association: "record"
    delete-document: "record"
    delete-inventory: "record<DeletionId: string, TypeName: string, DeletionSummary: record<TotalCount: int, RemainingCount: int, SummaryItems: list<record>>>"
    delete-maintenance-window: "record<WindowId: string>"
    delete-ops-metadata: "record"
    delete-parameter: "record"
    delete-parameters: "record<DeletedParameters: list<string>, InvalidParameters: list<string>>"
    delete-patch-baseline: "record<BaselineId: string>"
    delete-resource-data-sync: "record"
    delete-resource-policy: "record"
    deregister-managed-instance: "record"
    deregister-patch-baseline-for-patch-group: "record<BaselineId: string, PatchGroup: string>"
    deregister-target-from-maintenance-window: "record<WindowId: string, WindowTargetId: string>"
    deregister-task-from-maintenance-window: "record<WindowId: string, WindowTaskId: string>"
    describe-activations: "record<ActivationList: table<ActivationId: string, Description: string, DefaultInstanceName: string, IamRole: string, RegistrationLimit: int, RegistrationsCount: int, ExpirationDate: string, Expired: bool, CreatedDate: string, Tags: list>, NextToken: string>"
    describe-association: "record<AssociationDescription: record<Name: string, InstanceId: string, AssociationVersion: string, Date: string, LastUpdateAssociationDate: string, Status: record<Date: string, Name: string, Message: string, AdditionalInfo: string>, Overview: record<Status: string, DetailedStatus: string, AssociationStatusAggregatedCount: record>, DocumentVersion: string, AutomationTargetParameterName: string, Parameters: record, AssociationId: string, Targets: list<record>, ScheduleExpression: string, OutputLocation: record<S3Location: record>, LastExecutionDate: string, LastSuccessfulExecutionDate: string, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list<string>, TargetLocations: list<record>, ScheduleOffset: int, TargetMaps: list<record>, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>>>"
    describe-association-execution-targets: "record<AssociationExecutionTargets: table<AssociationId: string, AssociationVersion: string, ExecutionId: string, ResourceId: string, ResourceType: string, Status: string, DetailedStatus: string, LastExecutionDate: string, OutputSource: record>, NextToken: string>"
    describe-association-executions: "record<AssociationExecutions: table<AssociationId: string, AssociationVersion: string, ExecutionId: string, Status: string, DetailedStatus: string, CreatedTime: string, LastExecutionDate: string, ResourceCountByStatus: string, AlarmConfiguration: record, TriggeredAlarms: list>, NextToken: string>"
    describe-automation-executions: "record<AutomationExecutionMetadataList: table<AutomationExecutionId: string, DocumentName: string, DocumentVersion: string, AutomationExecutionStatus: string, ExecutionStartTime: string, ExecutionEndTime: string, ExecutedBy: string, LogFile: string, Outputs: record, Mode: string, ParentAutomationExecutionId: string, CurrentStepName: string, CurrentAction: string, FailureMessage: string, TargetParameterName: string, Targets: list, TargetMaps: list, ResolvedTargets: record, MaxConcurrency: string, MaxErrors: string, Target: string, AutomationType: string, AlarmConfiguration: record, TriggeredAlarms: list, AutomationSubtype: string, ScheduledTime: string, Runbooks: list, OpsItemId: string, AssociationId: string, ChangeRequestName: string>, NextToken: string>"
    describe-automation-step-executions: "record<StepExecutions: table<StepName: string, Action: string, TimeoutSeconds: int, OnFailure: string, MaxAttempts: int, ExecutionStartTime: string, ExecutionEndTime: string, StepStatus: string, ResponseCode: string, Inputs: record, Outputs: record, Response: string, FailureMessage: string, FailureDetails: record, StepExecutionId: string, OverriddenParameters: record, IsEnd: bool, NextStep: string, IsCritical: bool, ValidNextSteps: list, Targets: list, TargetLocation: record, TriggeredAlarms: list>, NextToken: string>"
    describe-available-patches: "record<Patches: table<Id: string, ReleaseDate: string, Title: string, Description: string, ContentUrl: string, Vendor: string, ProductFamily: string, Product: string, Classification: string, MsrcSeverity: string, KbNumber: string, MsrcNumber: string, Language: string, AdvisoryIds: list, BugzillaIds: list, CVEIds: list, Name: string, Epoch: int, Version: string, Release: string, Arch: string, Severity: string, Repository: string>, NextToken: string>"
    describe-document: "record<Document: record<Sha1: string, Hash: string, HashType: string, Name: string, DisplayName: string, VersionName: string, Owner: string, CreatedDate: string, Status: string, StatusInformation: string, DocumentVersion: string, Description: string, Parameters: list<record>, PlatformTypes: list<string>, DocumentType: string, SchemaVersion: string, LatestVersion: string, DefaultVersion: string, DocumentFormat: string, TargetType: string, Tags: list<record>, AttachmentsInformation: list<record>, Requires: list<record>, Author: string, ReviewInformation: list<record>, ApprovedVersion: string, PendingReviewVersion: string, ReviewStatus: string, Category: list<string>, CategoryEnum: list<string>>>"
    describe-document-permission: "record<AccountIds: list<string>, AccountSharingInfoList: table<AccountId: string, SharedDocumentVersion: string>, NextToken: string>"
    describe-effective-instance-associations: "record<Associations: table<AssociationId: string, InstanceId: string, Content: string, AssociationVersion: string>, NextToken: string>"
    describe-effective-patches-for-patch-baseline: "record<EffectivePatches: table<Patch: record, PatchStatus: record>, NextToken: string>"
    describe-instance-associations-status: "record<InstanceAssociationStatusInfos: table<AssociationId: string, Name: string, DocumentVersion: string, AssociationVersion: string, InstanceId: string, ExecutionDate: string, Status: string, DetailedStatus: string, ExecutionSummary: string, ErrorCode: string, OutputUrl: record, AssociationName: string>, NextToken: string>"
    describe-instance-information: "record<InstanceInformationList: table<InstanceId: string, PingStatus: string, LastPingDateTime: string, AgentVersion: string, IsLatestVersion: bool, PlatformType: string, PlatformName: string, PlatformVersion: string, ActivationId: string, IamRole: string, RegistrationDate: string, ResourceType: string, Name: string, IPAddress: string, ComputerName: string, AssociationStatus: string, LastAssociationExecutionDate: string, LastSuccessfulAssociationExecutionDate: string, AssociationOverview: record, SourceId: string, SourceType: string>, NextToken: string>"
    describe-instance-patch-states: "record<InstancePatchStates: table<InstanceId: string, PatchGroup: string, BaselineId: string, SnapshotId: string, InstallOverrideList: string, OwnerInformation: string, InstalledCount: int, InstalledOtherCount: int, InstalledPendingRebootCount: int, InstalledRejectedCount: int, MissingCount: int, FailedCount: int, UnreportedNotApplicableCount: int, NotApplicableCount: int, OperationStartTime: string, OperationEndTime: string, Operation: string, LastNoRebootInstallOperationTime: string, RebootOption: string, CriticalNonCompliantCount: int, SecurityNonCompliantCount: int, OtherNonCompliantCount: int>, NextToken: string>"
    describe-instance-patch-states-for-patch-group: "record<InstancePatchStates: table<InstanceId: string, PatchGroup: string, BaselineId: string, SnapshotId: string, InstallOverrideList: string, OwnerInformation: string, InstalledCount: int, InstalledOtherCount: int, InstalledPendingRebootCount: int, InstalledRejectedCount: int, MissingCount: int, FailedCount: int, UnreportedNotApplicableCount: int, NotApplicableCount: int, OperationStartTime: string, OperationEndTime: string, Operation: string, LastNoRebootInstallOperationTime: string, RebootOption: string, CriticalNonCompliantCount: int, SecurityNonCompliantCount: int, OtherNonCompliantCount: int>, NextToken: string>"
    describe-instance-patches: "record<Patches: table<Title: string, KBId: string, Classification: string, Severity: string, State: string, InstalledTime: string, CVEIds: string>, NextToken: string>"
    describe-inventory-deletions: "record<InventoryDeletions: table<DeletionId: string, TypeName: string, DeletionStartTime: string, LastStatus: string, LastStatusMessage: string, DeletionSummary: record, LastStatusUpdateTime: string>, NextToken: string>"
    describe-maintenance-window-execution-task-invocations: "record<WindowExecutionTaskInvocationIdentities: table<WindowExecutionId: string, TaskExecutionId: string, InvocationId: string, ExecutionId: string, TaskType: string, Parameters: string, Status: string, StatusDetails: string, StartTime: string, EndTime: string, OwnerInformation: string, WindowTargetId: string>, NextToken: string>"
    describe-maintenance-window-execution-tasks: "record<WindowExecutionTaskIdentities: table<WindowExecutionId: string, TaskExecutionId: string, Status: string, StatusDetails: string, StartTime: string, EndTime: string, TaskArn: string, TaskType: string, AlarmConfiguration: record, TriggeredAlarms: list>, NextToken: string>"
    describe-maintenance-window-executions: "record<WindowExecutions: table<WindowId: string, WindowExecutionId: string, Status: string, StatusDetails: string, StartTime: string, EndTime: string>, NextToken: string>"
    describe-maintenance-window-schedule: "record<ScheduledWindowExecutions: table<WindowId: string, Name: string, ExecutionTime: string>, NextToken: string>"
    describe-maintenance-window-targets: "record<Targets: table<WindowId: string, WindowTargetId: string, ResourceType: string, Targets: list, OwnerInformation: string, Name: string, Description: string>, NextToken: string>"
    describe-maintenance-window-tasks: "record<Tasks: table<WindowId: string, WindowTaskId: string, TaskArn: string, Type: string, Targets: list, TaskParameters: record, Priority: int, LoggingInfo: record, ServiceRoleArn: string, MaxConcurrency: string, MaxErrors: string, Name: string, Description: string, CutoffBehavior: string, AlarmConfiguration: record>, NextToken: string>"
    describe-maintenance-windows: "record<WindowIdentities: table<WindowId: string, Name: string, Description: string, Enabled: bool, Duration: int, Cutoff: int, Schedule: string, ScheduleTimezone: string, ScheduleOffset: int, EndDate: string, StartDate: string, NextExecutionTime: string>, NextToken: string>"
    describe-maintenance-windows-for-target: "record<WindowIdentities: table<WindowId: string, Name: string>, NextToken: string>"
    describe-ops-items: "record<NextToken: string, OpsItemSummaries: table<CreatedBy: string, CreatedTime: string, LastModifiedBy: string, LastModifiedTime: string, Priority: int, Source: string, Status: string, OpsItemId: string, Title: string, OperationalData: record, Category: string, Severity: string, OpsItemType: string, ActualStartTime: string, ActualEndTime: string, PlannedStartTime: string, PlannedEndTime: string>>"
    describe-parameters: "record<Parameters: table<Name: string, Type: string, KeyId: string, LastModifiedDate: string, LastModifiedUser: string, Description: string, AllowedPattern: string, Version: int, Tier: string, Policies: list, DataType: string>, NextToken: string>"
    describe-patch-baselines: "record<BaselineIdentities: table<BaselineId: string, BaselineName: string, OperatingSystem: string, BaselineDescription: string, DefaultBaseline: bool>, NextToken: string>"
    describe-patch-group-state: "record<Instances: int, InstancesWithInstalledPatches: int, InstancesWithInstalledOtherPatches: int, InstancesWithInstalledPendingRebootPatches: int, InstancesWithInstalledRejectedPatches: int, InstancesWithMissingPatches: int, InstancesWithFailedPatches: int, InstancesWithNotApplicablePatches: int, InstancesWithUnreportedNotApplicablePatches: int, InstancesWithCriticalNonCompliantPatches: int, InstancesWithSecurityNonCompliantPatches: int, InstancesWithOtherNonCompliantPatches: int>"
    describe-patch-groups: "record<Mappings: table<PatchGroup: string, BaselineIdentity: record>, NextToken: string>"
    describe-patch-properties: "record<Properties: list<record>, NextToken: string>"
    describe-sessions: "record<Sessions: table<SessionId: string, Target: string, Status: string, StartDate: string, EndDate: string, DocumentName: string, Owner: string, Reason: string, Details: string, OutputUrl: record, MaxSessionDuration: string>, NextToken: string>"
    disassociate-ops-item-related-item: "record"
    get-automation-execution: "record<AutomationExecution: record<AutomationExecutionId: string, DocumentName: string, DocumentVersion: string, ExecutionStartTime: string, ExecutionEndTime: string, AutomationExecutionStatus: string, StepExecutions: list<record>, StepExecutionsTruncated: bool, Parameters: record, Outputs: record, FailureMessage: string, Mode: string, ParentAutomationExecutionId: string, ExecutedBy: string, CurrentStepName: string, CurrentAction: string, TargetParameterName: string, Targets: list<record>, TargetMaps: list<record>, ResolvedTargets: record<ParameterValues: list, Truncated: bool>, MaxConcurrency: string, MaxErrors: string, Target: string, TargetLocations: list<record>, ProgressCounters: record<TotalSteps: int, SuccessSteps: int, FailedSteps: int, CancelledSteps: int, TimedOutSteps: int>, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>, AutomationSubtype: string, ScheduledTime: string, Runbooks: list<record>, OpsItemId: string, AssociationId: string, ChangeRequestName: string>>"
    get-calendar-state: "record<State: string, AtTime: string, NextTransitionTime: string>"
    get-command-invocation: "record<CommandId: string, InstanceId: string, Comment: string, DocumentName: string, DocumentVersion: string, PluginName: string, ResponseCode: int, ExecutionStartDateTime: string, ExecutionElapsedTime: string, ExecutionEndDateTime: string, Status: string, StatusDetails: string, StandardOutputContent: string, StandardOutputUrl: string, StandardErrorContent: string, StandardErrorUrl: string, CloudWatchOutputConfig: record<CloudWatchLogGroupName: string, CloudWatchOutputEnabled: bool>>"
    get-connection-status: "record<Target: string, Status: string>"
    get-default-patch-baseline: "record<BaselineId: string, OperatingSystem: string>"
    get-deployable-patch-snapshot-for-instance: "record<InstanceId: string, SnapshotId: string, SnapshotDownloadUrl: string, Product: string>"
    get-document: "record<Name: string, CreatedDate: string, DisplayName: string, VersionName: string, DocumentVersion: string, Status: string, StatusInformation: string, Content: string, DocumentType: string, DocumentFormat: string, Requires: table<Name: string, Version: string, RequireType: string, VersionName: string>, AttachmentsContent: table<Name: string, Size: int, Hash: string, HashType: string, Url: string>, ReviewStatus: string>"
    get-inventory: "record<Entities: table<Id: string, Data: record>, NextToken: string>"
    get-inventory-schema: "record<Schemas: table<TypeName: string, Version: string, Attributes: list, DisplayName: string>, NextToken: string>"
    get-maintenance-window: "record<WindowId: string, Name: string, Description: string, StartDate: string, EndDate: string, Schedule: string, ScheduleTimezone: string, ScheduleOffset: int, NextExecutionTime: string, Duration: int, Cutoff: int, AllowUnassociatedTargets: bool, Enabled: bool, CreatedDate: string, ModifiedDate: string>"
    get-maintenance-window-execution: "record<WindowExecutionId: string, TaskIds: list<string>, Status: string, StatusDetails: string, StartTime: string, EndTime: string>"
    get-maintenance-window-execution-task: "record<WindowExecutionId: string, TaskExecutionId: string, TaskArn: string, ServiceRole: string, Type: string, TaskParameters: list<record>, Priority: int, MaxConcurrency: string, MaxErrors: string, Status: string, StatusDetails: string, StartTime: string, EndTime: string, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list<record>>, TriggeredAlarms: table<Name: string, State: string>>"
    get-maintenance-window-execution-task-invocation: "record<WindowExecutionId: string, TaskExecutionId: string, InvocationId: string, ExecutionId: string, TaskType: string, Parameters: string, Status: string, StatusDetails: string, StartTime: string, EndTime: string, OwnerInformation: string, WindowTargetId: string>"
    get-maintenance-window-task: "record<WindowId: string, WindowTaskId: string, Targets: table<Key: string, Values: list>, TaskArn: string, ServiceRoleArn: string, TaskType: string, TaskParameters: record, TaskInvocationParameters: record<RunCommand: record<Comment: string, CloudWatchOutputConfig: record, DocumentHash: string, DocumentHashType: string, DocumentVersion: string, NotificationConfig: record, OutputS3BucketName: string, OutputS3KeyPrefix: string, Parameters: record, ServiceRoleArn: string, TimeoutSeconds: int>, Automation: record<DocumentVersion: string, Parameters: record>, StepFunctions: record<Input: string, Name: string>, Lambda: record<ClientContext: string, Qualifier: string, Payload: string>>, Priority: int, MaxConcurrency: string, MaxErrors: string, LoggingInfo: record<S3BucketName: string, S3KeyPrefix: string, S3Region: string>, Name: string, Description: string, CutoffBehavior: string, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list<record>>>"
    get-ops-item: "record<OpsItem: record<CreatedBy: string, OpsItemType: string, CreatedTime: string, Description: string, LastModifiedBy: string, LastModifiedTime: string, Notifications: list<record>, Priority: int, RelatedOpsItems: list<record>, Status: string, OpsItemId: string, Version: string, Title: string, Source: string, OperationalData: record, Category: string, Severity: string, ActualStartTime: string, ActualEndTime: string, PlannedStartTime: string, PlannedEndTime: string, OpsItemArn: string>>"
    get-ops-metadata: "record<ResourceId: string, Metadata: record, NextToken: string>"
    get-ops-summary: "record<Entities: table<Id: string, Data: record>, NextToken: string>"
    get-parameter: "record<Parameter: record<Name: string, Type: string, Value: string, Version: int, Selector: string, SourceResult: string, LastModifiedDate: string, ARN: string, DataType: string>>"
    get-parameter-history: "record<Parameters: table<Name: string, Type: string, KeyId: string, LastModifiedDate: string, LastModifiedUser: string, Description: string, Value: string, AllowedPattern: string, Version: int, Labels: list, Tier: string, Policies: list, DataType: string>, NextToken: string>"
    get-parameters: "record<Parameters: table<Name: string, Type: string, Value: string, Version: int, Selector: string, SourceResult: string, LastModifiedDate: string, ARN: string, DataType: string>, InvalidParameters: list<string>>"
    get-parameters-by-path: "record<Parameters: table<Name: string, Type: string, Value: string, Version: int, Selector: string, SourceResult: string, LastModifiedDate: string, ARN: string, DataType: string>, NextToken: string>"
    get-patch-baseline: "record<BaselineId: string, Name: string, OperatingSystem: string, GlobalFilters: record<PatchFilters: list<record>>, ApprovalRules: record<PatchRules: list<record>>, ApprovedPatches: list<string>, ApprovedPatchesComplianceLevel: string, ApprovedPatchesEnableNonSecurity: bool, RejectedPatches: list<string>, RejectedPatchesAction: string, PatchGroups: list<string>, CreatedDate: string, ModifiedDate: string, Description: string, Sources: table<Name: string, Products: list, Configuration: string>>"
    get-patch-baseline-for-patch-group: "record<BaselineId: string, PatchGroup: string, OperatingSystem: string>"
    get-resource-policies: "record<NextToken: string, Policies: table<PolicyId: string, PolicyHash: string, Policy: string>>"
    get-service-setting: "record<ServiceSetting: record<SettingId: string, SettingValue: string, LastModifiedDate: string, LastModifiedUser: string, ARN: string, Status: string>>"
    label-parameter-version: "record<InvalidLabels: list<string>, ParameterVersion: int>"
    list-association-versions: "record<AssociationVersions: table<AssociationId: string, AssociationVersion: string, CreatedDate: string, Name: string, DocumentVersion: string, Parameters: record, Targets: list, ScheduleExpression: string, OutputLocation: record, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list, TargetLocations: list, ScheduleOffset: int, TargetMaps: list>, NextToken: string>"
    list-associations: "record<Associations: table<Name: string, InstanceId: string, AssociationId: string, AssociationVersion: string, DocumentVersion: string, Targets: list, LastExecutionDate: string, Overview: record, ScheduleExpression: string, AssociationName: string, ScheduleOffset: int, TargetMaps: list>, NextToken: string>"
    list-command-invocations: "record<CommandInvocations: table<CommandId: string, InstanceId: string, InstanceName: string, Comment: string, DocumentName: string, DocumentVersion: string, RequestedDateTime: string, Status: string, StatusDetails: string, TraceOutput: string, StandardOutputUrl: string, StandardErrorUrl: string, CommandPlugins: list, ServiceRole: string, NotificationConfig: record, CloudWatchOutputConfig: record>, NextToken: string>"
    list-commands: "record<Commands: table<CommandId: string, DocumentName: string, DocumentVersion: string, Comment: string, ExpiresAfter: string, Parameters: record, InstanceIds: list, Targets: list, RequestedDateTime: string, Status: string, StatusDetails: string, OutputS3Region: string, OutputS3BucketName: string, OutputS3KeyPrefix: string, MaxConcurrency: string, MaxErrors: string, TargetCount: int, CompletedCount: int, ErrorCount: int, DeliveryTimedOutCount: int, ServiceRole: string, NotificationConfig: record, CloudWatchOutputConfig: record, TimeoutSeconds: int, AlarmConfiguration: record, TriggeredAlarms: list>, NextToken: string>"
    list-compliance-items: "record<ComplianceItems: table<ComplianceType: string, ResourceType: string, ResourceId: string, Id: string, Title: string, Status: string, Severity: string, ExecutionSummary: record, Details: record>, NextToken: string>"
    list-compliance-summaries: "record<ComplianceSummaryItems: table<ComplianceType: string, CompliantSummary: record, NonCompliantSummary: record>, NextToken: string>"
    list-document-metadata-history: "record<Name: string, DocumentVersion: string, Author: string, Metadata: record<ReviewerResponse: list<record>>, NextToken: string>"
    list-document-versions: "record<DocumentVersions: table<Name: string, DisplayName: string, DocumentVersion: string, VersionName: string, CreatedDate: string, IsDefaultVersion: bool, DocumentFormat: string, Status: string, StatusInformation: string, ReviewStatus: string>, NextToken: string>"
    list-documents: "record<DocumentIdentifiers: table<Name: string, CreatedDate: string, DisplayName: string, Owner: string, VersionName: string, PlatformTypes: list, DocumentVersion: string, DocumentType: string, SchemaVersion: string, DocumentFormat: string, TargetType: string, Tags: list, Requires: list, ReviewStatus: string, Author: string>, NextToken: string>"
    list-inventory-entries: "record<TypeName: string, InstanceId: string, SchemaVersion: string, CaptureTime: string, Entries: list<record>, NextToken: string>"
    list-ops-item-events: "record<NextToken: string, Summaries: table<OpsItemId: string, EventId: string, Source: string, DetailType: string, Detail: string, CreatedBy: record, CreatedTime: string>>"
    list-ops-item-related-items: "record<NextToken: string, Summaries: table<OpsItemId: string, AssociationId: string, ResourceType: string, AssociationType: string, ResourceUri: string, CreatedBy: record, CreatedTime: string, LastModifiedBy: record, LastModifiedTime: string>>"
    list-ops-metadata: "record<OpsMetadataList: table<ResourceId: string, OpsMetadataArn: string, LastModifiedDate: string, LastModifiedUser: string, CreationDate: string>, NextToken: string>"
    list-resource-compliance-summaries: "record<ResourceComplianceSummaryItems: table<ComplianceType: string, ResourceType: string, ResourceId: string, Status: string, OverallSeverity: string, ExecutionSummary: record, CompliantSummary: record, NonCompliantSummary: record>, NextToken: string>"
    list-resource-data-sync: "record<ResourceDataSyncItems: table<SyncName: string, SyncType: string, SyncSource: record, S3Destination: record, LastSyncTime: string, LastSuccessfulSyncTime: string, SyncLastModifiedTime: string, LastStatus: string, SyncCreatedTime: string, LastSyncStatusMessage: string>, NextToken: string>"
    list-tags-for-resource: "record<TagList: table<Key: string, Value: string>>"
    modify-document-permission: "record"
    put-compliance-items: "record"
    put-inventory: "record<Message: string>"
    put-parameter: "record<Version: int, Tier: string>"
    put-resource-policy: "record<PolicyId: string, PolicyHash: string>"
    register-default-patch-baseline: "record<BaselineId: string>"
    register-patch-baseline-for-patch-group: "record<BaselineId: string, PatchGroup: string>"
    register-target-with-maintenance-window: "record<WindowTargetId: string>"
    register-task-with-maintenance-window: "record<WindowTaskId: string>"
    remove-tags-from-resource: "record"
    reset-service-setting: "record<ServiceSetting: record<SettingId: string, SettingValue: string, LastModifiedDate: string, LastModifiedUser: string, ARN: string, Status: string>>"
    resume-session: "record<SessionId: string, TokenValue: string, StreamUrl: string>"
    send-automation-signal: "record"
    send-command: "record<Command: record<CommandId: string, DocumentName: string, DocumentVersion: string, Comment: string, ExpiresAfter: string, Parameters: record, InstanceIds: list<string>, Targets: list<record>, RequestedDateTime: string, Status: string, StatusDetails: string, OutputS3Region: string, OutputS3BucketName: string, OutputS3KeyPrefix: string, MaxConcurrency: string, MaxErrors: string, TargetCount: int, CompletedCount: int, ErrorCount: int, DeliveryTimedOutCount: int, ServiceRole: string, NotificationConfig: record<NotificationArn: string, NotificationEvents: list, NotificationType: string>, CloudWatchOutputConfig: record<CloudWatchLogGroupName: string, CloudWatchOutputEnabled: bool>, TimeoutSeconds: int, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>>>"
    start-associations-once: "record"
    start-automation-execution: "record<AutomationExecutionId: string>"
    start-change-request-execution: "record<AutomationExecutionId: string>"
    start-session: "record<SessionId: string, TokenValue: string, StreamUrl: string>"
    stop-automation-execution: "record"
    terminate-session: "record<SessionId: string>"
    unlabel-parameter-version: "record<RemovedLabels: list<string>, InvalidLabels: list<string>>"
    update-association: "record<AssociationDescription: record<Name: string, InstanceId: string, AssociationVersion: string, Date: string, LastUpdateAssociationDate: string, Status: record<Date: string, Name: string, Message: string, AdditionalInfo: string>, Overview: record<Status: string, DetailedStatus: string, AssociationStatusAggregatedCount: record>, DocumentVersion: string, AutomationTargetParameterName: string, Parameters: record, AssociationId: string, Targets: list<record>, ScheduleExpression: string, OutputLocation: record<S3Location: record>, LastExecutionDate: string, LastSuccessfulExecutionDate: string, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list<string>, TargetLocations: list<record>, ScheduleOffset: int, TargetMaps: list<record>, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>>>"
    update-association-status: "record<AssociationDescription: record<Name: string, InstanceId: string, AssociationVersion: string, Date: string, LastUpdateAssociationDate: string, Status: record<Date: string, Name: string, Message: string, AdditionalInfo: string>, Overview: record<Status: string, DetailedStatus: string, AssociationStatusAggregatedCount: record>, DocumentVersion: string, AutomationTargetParameterName: string, Parameters: record, AssociationId: string, Targets: list<record>, ScheduleExpression: string, OutputLocation: record<S3Location: record>, LastExecutionDate: string, LastSuccessfulExecutionDate: string, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list<string>, TargetLocations: list<record>, ScheduleOffset: int, TargetMaps: list<record>, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>>>"
    update-document: "record<DocumentDescription: record<Sha1: string, Hash: string, HashType: string, Name: string, DisplayName: string, VersionName: string, Owner: string, CreatedDate: string, Status: string, StatusInformation: string, DocumentVersion: string, Description: string, Parameters: list<record>, PlatformTypes: list<string>, DocumentType: string, SchemaVersion: string, LatestVersion: string, DefaultVersion: string, DocumentFormat: string, TargetType: string, Tags: list<record>, AttachmentsInformation: list<record>, Requires: list<record>, Author: string, ReviewInformation: list<record>, ApprovedVersion: string, PendingReviewVersion: string, ReviewStatus: string, Category: list<string>, CategoryEnum: list<string>>>"
    update-document-default-version: "record<Description: record<Name: string, DefaultVersion: string, DefaultVersionName: string>>"
    update-document-metadata: "record"
    update-maintenance-window: "record<WindowId: string, Name: string, Description: string, StartDate: string, EndDate: string, Schedule: string, ScheduleTimezone: string, ScheduleOffset: int, Duration: int, Cutoff: int, AllowUnassociatedTargets: bool, Enabled: bool>"
    update-maintenance-window-target: "record<WindowId: string, WindowTargetId: string, Targets: table<Key: string, Values: list>, OwnerInformation: string, Name: string, Description: string>"
    update-maintenance-window-task: "record<WindowId: string, WindowTaskId: string, Targets: table<Key: string, Values: list>, TaskArn: string, ServiceRoleArn: string, TaskParameters: record, TaskInvocationParameters: record<RunCommand: record<Comment: string, CloudWatchOutputConfig: record, DocumentHash: string, DocumentHashType: string, DocumentVersion: string, NotificationConfig: record, OutputS3BucketName: string, OutputS3KeyPrefix: string, Parameters: record, ServiceRoleArn: string, TimeoutSeconds: int>, Automation: record<DocumentVersion: string, Parameters: record>, StepFunctions: record<Input: string, Name: string>, Lambda: record<ClientContext: string, Qualifier: string, Payload: string>>, Priority: int, MaxConcurrency: string, MaxErrors: string, LoggingInfo: record<S3BucketName: string, S3KeyPrefix: string, S3Region: string>, Name: string, Description: string, CutoffBehavior: string, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list<record>>>"
    update-managed-instance-role: "record"
    update-ops-item: "record"
    update-ops-metadata: "record<OpsMetadataArn: string>"
    update-patch-baseline: "record<BaselineId: string, Name: string, OperatingSystem: string, GlobalFilters: record<PatchFilters: list<record>>, ApprovalRules: record<PatchRules: list<record>>, ApprovedPatches: list<string>, ApprovedPatchesComplianceLevel: string, ApprovedPatchesEnableNonSecurity: bool, RejectedPatches: list<string>, RejectedPatchesAction: string, CreatedDate: string, ModifiedDate: string, Description: string, Sources: table<Name: string, Products: list, Configuration: string>>"
    update-resource-data-sync: "record"
    update-service-setting: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["add-tags-to-resource" "associate-ops-item-related-item" "cancel-command" "cancel-maintenance-window-execution" "create-activation" "create-association" "create-association-batch" "create-document" "create-maintenance-window" "create-ops-item" "create-ops-metadata" "create-patch-baseline" "create-resource-data-sync" "delete-activation" "delete-association" "delete-document" "delete-inventory" "delete-maintenance-window" "delete-ops-metadata" "delete-parameter" "delete-parameters" "delete-patch-baseline" "delete-resource-data-sync" "delete-resource-policy" "deregister-managed-instance" "deregister-patch-baseline-for-patch-group" "deregister-target-from-maintenance-window" "deregister-task-from-maintenance-window" "describe-activations" "describe-association" "describe-association-execution-targets" "describe-association-executions" "describe-automation-executions" "describe-automation-step-executions" "describe-available-patches" "describe-document" "describe-document-permission" "describe-effective-instance-associations" "describe-effective-patches-for-patch-baseline" "describe-instance-associations-status" "describe-instance-information" "describe-instance-patch-states" "describe-instance-patch-states-for-patch-group" "describe-instance-patches" "describe-inventory-deletions" "describe-maintenance-window-execution-task-invocations" "describe-maintenance-window-execution-tasks" "describe-maintenance-window-executions" "describe-maintenance-window-schedule" "describe-maintenance-window-targets" "describe-maintenance-window-tasks" "describe-maintenance-windows" "describe-maintenance-windows-for-target" "describe-ops-items" "describe-parameters" "describe-patch-baselines" "describe-patch-group-state" "describe-patch-groups" "describe-patch-properties" "describe-sessions" "disassociate-ops-item-related-item" "get-automation-execution" "get-calendar-state" "get-command-invocation" "get-connection-status" "get-default-patch-baseline" "get-deployable-patch-snapshot-for-instance" "get-document" "get-inventory" "get-inventory-schema" "get-maintenance-window" "get-maintenance-window-execution" "get-maintenance-window-execution-task" "get-maintenance-window-execution-task-invocation" "get-maintenance-window-task" "get-ops-item" "get-ops-metadata" "get-ops-summary" "get-parameter" "get-parameter-history" "get-parameters" "get-parameters-by-path" "get-patch-baseline" "get-patch-baseline-for-patch-group" "get-resource-policies" "get-service-setting" "label-parameter-version" "list-association-versions" "list-associations" "list-command-invocations" "list-commands" "list-compliance-items" "list-compliance-summaries" "list-document-metadata-history" "list-document-versions" "list-documents" "list-inventory-entries" "list-ops-item-events" "list-ops-item-related-items" "list-ops-metadata" "list-resource-compliance-summaries" "list-resource-data-sync" "list-tags-for-resource" "modify-document-permission" "put-compliance-items" "put-inventory" "put-parameter" "put-resource-policy" "register-default-patch-baseline" "register-patch-baseline-for-patch-group" "register-target-with-maintenance-window" "register-task-with-maintenance-window" "remove-tags-from-resource" "reset-service-setting" "resume-session" "send-automation-signal" "send-command" "start-associations-once" "start-automation-execution" "start-change-request-execution" "start-session" "stop-automation-execution" "terminate-session" "unlabel-parameter-version" "update-association" "update-association-status" "update-document" "update-document-default-version" "update-document-metadata" "update-maintenance-window" "update-maintenance-window-target" "update-maintenance-window-task" "update-managed-instance-role" "update-ops-item" "update-ops-metadata" "update-patch-baseline" "update-resource-data-sync" "update-service-setting" "commands"] | sort) } | get name | first)
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

# Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your automations, documents, managed nodes, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed nodes that helps you track each node's owner and stack level. For example: Key=Owner,Value=DbAdmin Key=Owner,Value=SysAdmin Key=Owner,Value=Dev Key=Stack,Value=Production Key=Stack,Value=Pre-Production Key=Stack,Value=Test Most resources can have a maximum of 50 tags. Automations can have a maximum of 5 tags. We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to and are interpreted strictly as a string of characters. For more information about using tags with Amazon Elastic Compute Cloud (Amazon EC2) instances, see Tagging your Amazon EC2 resources (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html) in the Amazon EC2 User Guide.
#
# POST /
# Returns: record
# operationId: AddTagsToResource
export def "add-tags-to-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_type: string@resource-type-completer # Specifies the type of resource you are tagging. The ManagedInstance type for this API operation is for on-premises managed nodes. You must specify the name of the managed node in the following format: mi-ID_number . For example, mi-1a2b3c4d5e6f.
  resource_id: string # The resource ID you want to tag. Use the ID of the resource. Here are some examples: MaintenanceWindow: mw-012345abcde PatchBaseline: pb-012345abcde Automation: example-c160-4567-8519-012345abcde OpsMetadata object: ResourceID for tagging is created from the Amazon Resource Name (ARN) for the object. Specifically, ResourceID is created from the strings that come after the word opsmetadata in the ARN. For example, an OpsMetadata object with an ARN of arn:aws:ssm:us-east-2:1234567890:opsmetadata/aws/ssm/MyGroup/appmanager has a ResourceID of either aws/ssm/MyGroup/appmanager or /aws/ssm/MyGroup/appmanager. For the Document and Parameter values, use the name of the resource. ManagedInstance: mi-012345abcde The ManagedInstance type for this API operation is only for on-premises managed nodes. You must specify the name of the managed node in the following format: mi-ID_number . For example, mi-1a2b3c4d5e6f.
  tags: list # One or more tags. The value parameter is required. Don't enter personally identifiable information in this field. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.AddTagsToResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceType, var: resource_type}, {name: ResourceId, var: resource_id}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_type: $resource_type, resource_id: $resource_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a related item to a Systems Manager OpsCenter OpsItem. For example, you can associate an Incident Manager incident or analysis with an OpsItem. Incident Manager and OpsCenter are capabilities of Amazon Web Services Systems Manager.
#
# POST /
# Returns: record<AssociationId: string>
# operationId: AssociateOpsItemRelatedItem
export def "associate-ops-item-related-item" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  ops_item_id: string # The ID of the OpsItem to which you want to associate a resource as a related item.
  association_type: string # The type of association that you want to create between an OpsItem and a resource. OpsCenter supports IsParentOf and RelatesTo association types.
  resource_type: string # The type of resource that you want to associate with an OpsItem. OpsCenter supports the following types: AWS::SSMIncidents::IncidentRecord: an Incident Manager incident. AWS::SSM::Document: a Systems Manager (SSM) document.
  resource_uri: string # The Amazon Resource Name (ARN) of the Amazon Web Services resource that you want to associate with the OpsItem.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.AssociateOpsItemRelatedItem"}]
    body: {content_type: "application/json", kind: json, fields: [{name: OpsItemId, var: ops_item_id}, {name: AssociationType, var: association_type}, {name: ResourceType, var: resource_type}, {name: ResourceUri, var: resource_uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ops_item_id: $ops_item_id, association_type: $association_type, resource_type: $resource_type, resource_uri: $resource_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
#
# POST /
# Returns: record
# operationId: CancelCommand
export def "cancel-command" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  command_id: string # The ID of the command you want to cancel.
  --instance-ids: list<string> # (Optional) A list of managed node IDs on which you want to cancel the command. If not provided, the command is canceled on every node on which it was requested.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.CancelCommand"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CommandId, var: command_id}, {name: InstanceIds, var: instance_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, command_id: $command_id, instance_ids: $instance_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a maintenance window execution that is already in progress and cancels any tasks in the window that haven't already starting running. Tasks already in progress will continue to completion.
#
# POST /
# Returns: record<WindowExecutionId: string>
# operationId: CancelMaintenanceWindowExecution
export def "cancel-maintenance-window-execution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  window_execution_id: string # The ID of the maintenance window execution to stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.CancelMaintenanceWindowExecution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowExecutionId, var: window_execution_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_execution_id: $window_execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates an activation code and activation ID you can use to register your on-premises servers, edge devices, or virtual machine (VM) with Amazon Web Services Systems Manager. Registering these machines with Systems Manager makes it possible to manage them using Systems Manager capabilities. You use the activation code and ID when installing SSM Agent on machines in your hybrid environment. For more information about requirements for managing on-premises machines using Systems Manager, see Setting up Amazon Web Services Systems Manager for hybrid environments (https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html) in the Amazon Web Services Systems Manager User Guide. Amazon Elastic Compute Cloud (Amazon EC2) instances, edge devices, and on-premises servers and VMs that are configured for Systems Manager are all called managed nodes.
#
# POST /
# Returns: record<ActivationId: string, ActivationCode: string>
# operationId: CreateActivation
export def "create-activation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --description: string # A user-defined description of the resource that you want to register with Systems Manager. Don't enter personally identifiable information in this field.
  --default-instance-name: string # The name of the registered, managed node as it will appear in the Amazon Web Services Systems Manager console or when you use the Amazon Web Services command line tools to list Systems Manager resources. Don't enter personally identifiable information in this field.
  iam_role: string # The name of the Identity and Access Management (IAM) role that you want to assign to the managed node. This IAM role must provide AssumeRole permissions for the Amazon Web Services Systems Manager service principal ssm.amazonaws.com. For more information, see Create an IAM service role for a hybrid environment (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-service-role.html) in the Amazon Web Services Systems Manager User Guide. You can't specify an IAM service-linked role for this parameter. You must create a unique role.
  --registration-limit: int # Specify the maximum number of managed nodes you want to register. The default value is 1.
  --expiration-date: string # The date by which this activation request should expire, in timestamp format, such as "2021-07-07T00:00:00". You can specify a date up to 30 days in advance. If you don't provide an expiration date, the activation code expires in 24 hours. (format: date-time)
  --tags: list # Optional metadata that you assign to a resource. Tags enable you to categorize a resource in different ways, such as by purpose, owner, or environment. For example, you might want to tag an activation to identify which servers or virtual machines (VMs) in your on-premises environment you intend to activate. In this case, you could specify the following key-value pairs: Key=OS,Value=Windows Key=Environment,Value=Production When you install SSM Agent on your on-premises servers and VMs, you specify an activation ID and code. When you specify the activation ID and code, tags assigned to the activation are automatically applied to the on-premises servers or VMs. You can't add tags to or delete tags from an existing activation. You can tag your on-premises servers, edge devices, and VMs after they connect to Systems Manager for the first time and are assigned a managed node ID. This means they are listed in the Amazon Web Services Systems Manager console with an ID that is prefixed with "mi-". For information about how to add tags to your managed nodes, see AddTagsToResource. For information about how to remove tags from your managed nodes, see RemoveTagsFromResource. — item shape: {Key: string, Value: string}
  --registration-metadata: list # Reserved for internal use. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.CreateActivation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: DefaultInstanceName, var: default_instance_name}, {name: IamRole, var: iam_role}, {name: RegistrationLimit, var: registration_limit}, {name: ExpirationDate, var: expiration_date}, {name: Tags, var: tags}, {name: RegistrationMetadata, var: registration_metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, description: $description, default_instance_name: $default_instance_name, iam_role: $iam_role, registration_limit: $registration_limit, expiration_date: $expiration_date, tags: $tags, registration_metadata: $registration_metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A State Manager association defines the state that you want to maintain on your managed nodes. For example, an association can specify that anti-virus software must be installed and running on your managed nodes, or that certain ports must be closed. For static targets, the association specifies a schedule for when the configuration is reapplied. For dynamic targets, such as an Amazon Web Services resource group or an Amazon Web Services autoscaling group, State Manager, a capability of Amazon Web Services Systems Manager applies the configuration when new managed nodes are added to the group. The association also specifies actions to take when applying the configuration. For example, an association for anti-virus software might run once a day. If the software isn't installed, then State Manager installs it. If the software is installed, but the service isn't running, then the association might instruct State Manager to start the service.
#
# POST /
# Returns: record<AssociationDescription: record<Name: string, InstanceId: string, AssociationVersion: string, Date: string, LastUpdateAssociationDate: string, Status: record<Date: string, Name: string, Message: string, AdditionalInfo: string>, Overview: record<Status: string, DetailedStatus: string, AssociationStatusAggregatedCount: record>, DocumentVersion: string, AutomationTargetParameterName: string, Parameters: record, AssociationId: string, Targets: list<record>, ScheduleExpression: string, OutputLocation: record<S3Location: record>, LastExecutionDate: string, LastSuccessfulExecutionDate: string, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list<string>, TargetLocations: list<record>, ScheduleOffset: int, TargetMaps: list<record>, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>>>
# operationId: CreateAssociation
export def "create-association" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the SSM Command document or Automation runbook that contains the configuration information for the managed node. You can specify Amazon Web Services-predefined documents, documents you created, or a document that is shared with you from another Amazon Web Services account. For Systems Manager documents (SSM documents) that are shared with you from other Amazon Web Services accounts, you must specify the complete SSM document ARN, in the following format: arn:partition:ssm:region:account-id:document/document-name For example: arn:aws:ssm:us-east-2:12345678912:document/My-Shared-Document For Amazon Web Services-predefined documents and SSM documents you created in your account, you only need to specify the document name. For example, AWS-ApplyPatchBaseline or My-Document.
  --document-version: string # The document version you want to associate with the target(s). Can be a specific version or the default version. State Manager doesn't support running associations that use a new version of a document if that document is shared from another account. State Manager always runs the default version of a document if shared from another account, even though the Systems Manager console shows that a new version was processed. If you want to run an association using a new version of a document shared form another account, you must set the document version to default.
  --instance-id: string # The managed node ID. InstanceId has been deprecated. To specify a managed node ID for an association, use the Targets parameter. Requests that include the parameter InstanceID with Systems Manager documents (SSM documents) that use schema version 2.0 or later will fail. In addition, if you use the parameter InstanceId, you can't use the parameters AssociationName, DocumentVersion, MaxErrors, MaxConcurrency, OutputLocation, or ScheduleExpression. To use these parameters, you must use the Targets parameter.
  --parameters: record # The parameters for the runtime configuration of the document.
  --targets: list # The targets for the association. You can target managed nodes by using tags, Amazon Web Services resource groups, all managed nodes in an Amazon Web Services account, or individual managed node IDs. You can target all managed nodes in an Amazon Web Services account by specifying the InstanceIds key with a value of *. For more information about choosing targets for an association, see Using targets and rate controls with State Manager associations (https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-state-manager-targets-and-rate-controls.html) in the Amazon Web Services Systems Manager User Guide. — item shape: {Key?: string, Values?: list<string>}
  --schedule-expression: string # A cron expression when the association will be applied to the target(s).
  --output-location: record # An S3 bucket where you want to store the results of this request. For the minimal permissions required to enable Amazon S3 output for an association, see Creating associations (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-state-assoc.html) in the Systems Manager User Guide. — shape: {S3Location?: record}
  --association-name: string # Specify a descriptive name for the association.
  --automation-target-parameter-name: string # Choose the parameter that will define how your automation will branch out. This target is required for associations that use an Automation runbook and target resources by using rate controls. Automation is a capability of Amazon Web Services Systems Manager.
  --max-errors: string # The number of errors that are allowed before the system stops sending requests to run the association on additional targets. You can specify either an absolute number of errors, for example 10, or a percentage of the target set, for example 10%. If you specify 3, for example, the system stops sending requests when the fourth error is received. If you specify 0, then the system stops sending requests after the first error is returned. If you run an association on 50 managed nodes and set MaxError to 10%, then the system stops sending the request when the sixth error is received. Executions that are already running an association when MaxErrors is reached are allowed to complete, but some of these executions may fail as well. If you need to ensure that there won't be more than max-errors failed executions, set MaxConcurrency to 1 so that executions proceed one at a time.
  --max-concurrency: string # The maximum number of targets allowed to run the association at the same time. You can specify a number, for example 10, or a percentage of the target set, for example 10%. The default value is 100%, which means all targets run the association at the same time. If a new managed node starts and attempts to run an association while Systems Manager is running MaxConcurrency associations, the association is allowed to run. During the next association interval, the new managed node will process its association within the limit specified for MaxConcurrency.
  --compliance-severity: string@compliance-severity-completer # The severity level to assign to the association.
  --sync-compliance: string@sync-compliance-completer # The mode for generating association compliance. You can specify AUTO or MANUAL. In AUTO mode, the system uses the status of the association execution to determine the compliance status. If the association execution runs successfully, then the association is COMPLIANT. If the association execution doesn't run successfully, the association is NON-COMPLIANT. In MANUAL mode, you must specify the AssociationId as a parameter for the PutComplianceItems API operation. In this case, compliance data isn't managed by State Manager. It is managed by your direct call to the PutComplianceItems API operation. By default, all associations use AUTO mode.
  --apply-only-at-cron-interval: oneof<nothing, bool> # By default, when you create a new association, the system runs it immediately after it is created and then according to the schedule you specified. Specify this option if you don't want an association to run immediately after you create it. This parameter isn't supported for rate expressions.
  --calendar-names: list<string> # The names or Amazon Resource Names (ARNs) of the Change Calendar type documents you want to gate your associations under. The associations only run when that change calendar is open. For more information, see Amazon Web Services Systems Manager Change Calendar (https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar).
  --target-locations: list # A location is a combination of Amazon Web Services Regions and Amazon Web Services accounts where you want to run the association. Use this action to create an association in multiple Regions and multiple accounts. — item shape: {Accounts?: list<string>, Regions?: list<string>, TargetLocationMaxConcurrency?: string, TargetLocationMaxErrors?: string, ExecutionRoleName?: string, TargetLocationAlarmConfiguration?: record}
  --schedule-offset: int # Number of days to wait after the scheduled day to run an association. For example, if you specified a cron schedule of cron(0 0 ? * THU#2 *), you could specify an offset of 3 to run the association each Sunday after the second Thursday of the month. For more information about cron schedules for associations, see Reference: Cron and rate expressions for Systems Manager (https://docs.aws.amazon.com/systems-manager/latest/userguide/reference-cron-and-rate-expressions.html) in the Amazon Web Services Systems Manager User Guide. To use offsets, you must specify the ApplyOnlyAtCronInterval parameter. This option tells the system not to run an association immediately after you create it.
  --target-maps: list # A key-value mapping of document parameters to target resources. Both Targets and TargetMaps can't be specified together.
  --tags: list # Adds or overwrites one or more tags for a State Manager association. Tags are metadata that you can assign to your Amazon Web Services resources. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. — item shape: {Key: string, Value: string}
  --alarm-configuration: record # The details for the CloudWatch alarm you want to apply to an automation or command. — shape: {IgnorePollAlarmFailure?: bool, Alarms: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.CreateAssociation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: DocumentVersion, var: document_version}, {name: InstanceId, var: instance_id}, {name: Parameters, var: parameters}, {name: Targets, var: targets}, {name: ScheduleExpression, var: schedule_expression}, {name: OutputLocation, var: output_location}, {name: AssociationName, var: association_name}, {name: AutomationTargetParameterName, var: automation_target_parameter_name}, {name: MaxErrors, var: max_errors}, {name: MaxConcurrency, var: max_concurrency}, {name: ComplianceSeverity, var: compliance_severity}, {name: SyncCompliance, var: sync_compliance}, {name: ApplyOnlyAtCronInterval, var: apply_only_at_cron_interval}, {name: CalendarNames, var: calendar_names}, {name: TargetLocations, var: target_locations}, {name: ScheduleOffset, var: schedule_offset}, {name: TargetMaps, var: target_maps}, {name: Tags, var: tags}, {name: AlarmConfiguration, var: alarm_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, document_version: $document_version, instance_id: $instance_id, parameters: $parameters, targets: $targets, schedule_expression: $schedule_expression, output_location: $output_location, association_name: $association_name, automation_target_parameter_name: $automation_target_parameter_name, max_errors: $max_errors, max_concurrency: $max_concurrency, compliance_severity: $compliance_severity, sync_compliance: $sync_compliance, apply_only_at_cron_interval: $apply_only_at_cron_interval, calendar_names: $calendar_names, target_locations: $target_locations, schedule_offset: $schedule_offset, target_maps: $target_maps, tags: $tags, alarm_configuration: $alarm_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates the specified Amazon Web Services Systems Manager document (SSM document) with the specified managed nodes or targets. When you associate a document with one or more managed nodes using IDs or tags, Amazon Web Services Systems Manager Agent (SSM Agent) running on the managed node processes the document and configures the node as specified. If you associate a document with a managed node that already has an associated document, the system returns the AssociationAlreadyExists exception.
#
# POST /
# Returns: record<Successful: table<Name: string, InstanceId: string, AssociationVersion: string, Date: string, LastUpdateAssociationDate: string, Status: record, Overview: record, DocumentVersion: string, AutomationTargetParameterName: string, Parameters: record, AssociationId: string, Targets: list, ScheduleExpression: string, OutputLocation: record, LastExecutionDate: string, LastSuccessfulExecutionDate: string, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list, TargetLocations: list, ScheduleOffset: int, TargetMaps: list, AlarmConfiguration: record, TriggeredAlarms: list>, Failed: table<Entry: record, Message: string, Fault: string>>
# operationId: CreateAssociationBatch
export def "create-association-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  entries: list # One or more associations. — item shape: {Name: string, InstanceId?: string, Parameters?: record, AutomationTargetParameterName?: string, DocumentVersion?: string, Targets?: list, ScheduleExpression?: string, OutputLocation?: record, AssociationName?: string, MaxErrors?: string, MaxConcurrency?: string, ComplianceSeverity?: "CRITICAL"|"HIGH"|"MEDIUM"|"LOW"|"UNSPECIFIED", SyncCompliance?: "AUTO"|"MANUAL", ApplyOnlyAtCronInterval?: bool, CalendarNames?: list<string>, TargetLocations?: list, ScheduleOffset?: int, TargetMaps?: list, ... (1 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.CreateAssociationBatch"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Amazon Web Services Systems Manager (SSM document). An SSM document defines the actions that Systems Manager performs on your managed nodes. For more information about SSM documents, including information about supported schemas, features, and syntax, see Amazon Web Services Systems Manager Documents (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-ssm-docs.html) in the Amazon Web Services Systems Manager User Guide.
#
# POST /
# Returns: record<DocumentDescription: record<Sha1: string, Hash: string, HashType: string, Name: string, DisplayName: string, VersionName: string, Owner: string, CreatedDate: string, Status: string, StatusInformation: string, DocumentVersion: string, Description: string, Parameters: list<record>, PlatformTypes: list<string>, DocumentType: string, SchemaVersion: string, LatestVersion: string, DefaultVersion: string, DocumentFormat: string, TargetType: string, Tags: list<record>, AttachmentsInformation: list<record>, Requires: list<record>, Author: string, ReviewInformation: list<record>, ApprovedVersion: string, PendingReviewVersion: string, ReviewStatus: string, Category: list<string>, CategoryEnum: list<string>>>
# operationId: CreateDocument
export def "create-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  content: string # The content for the new SSM document in JSON or YAML format. The content of the document must not exceed 64KB. This quota also includes the content specified for input parameters at runtime. We recommend storing the contents for your new document in an external JSON or YAML file and referencing the file in a command. For examples, see the following topics in the Amazon Web Services Systems Manager User Guide. Create an SSM document (Amazon Web Services API) (https://docs.aws.amazon.com/systems-manager/latest/userguide/create-ssm-document-api.html) Create an SSM document (Amazon Web Services CLI) (https://docs.aws.amazon.com/systems-manager/latest/userguide/create-ssm-document-cli.html) Create an SSM document (API) (https://docs.aws.amazon.com/systems-manager/latest/userguide/create-ssm-document-api.html)
  --requires: list # A list of SSM documents required by a document. This parameter is used exclusively by AppConfig. When a user creates an AppConfig configuration in an SSM document, the user must also specify a required document for validation purposes. In this case, an ApplicationConfiguration document requires an ApplicationConfigurationSchema document for validation purposes. For more information, see What is AppConfig? (https://docs.aws.amazon.com/appconfig/latest/userguide/what-is-appconfig.html) in the AppConfig User Guide. — item shape: {Name: string, Version?: string, RequireType?: string, VersionName?: string}
  --attachments: list # A list of key-value pairs that describe attachments to a version of a document. — item shape: {Key?: "SourceUrl"|"S3FileUrl"|"AttachmentReference", Values?: list<string>, Name?: string}
  name: string # A name for the SSM document. You can't use the following strings as document name prefixes. These are reserved by Amazon Web Services for use as document name prefixes: aws amazon amzn
  --display-name: string # An optional field where you can specify a friendly name for the SSM document. This value can differ for each version of the document. You can update this value at a later time using the UpdateDocument operation.
  --version-name: string # An optional field specifying the version of the artifact you are creating with the document. For example, Release12.1. This value is unique across all versions of a document, and can't be changed.
  --document-type: string@document-type-completer # The type of document to create. The DeploymentStrategy document type is an internal-use-only document type reserved for AppConfig.
  --document-format: string@document-format-completer # Specify the document format for the request. The document format can be JSON, YAML, or TEXT. JSON is the default format.
  --target-type: string # Specify a target type to define the kinds of resources the document can run on. For example, to run a document on EC2 instances, specify the following value: /AWS::EC2::Instance. If you specify a value of '/' the document can run on all types of resources. If you don't specify a value, the document can't run on any resources. For a list of valid resource types, see Amazon Web Services resource and property types reference (https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html) in the CloudFormation User Guide.
  --tags: list # Optional metadata that you assign to a resource. Tags enable you to categorize a resource in different ways, such as by purpose, owner, or environment. For example, you might want to tag an SSM document to identify the types of targets or the environment where it will run. In this case, you could specify the following key-value pairs: Key=OS,Value=Windows Key=Environment,Value=Production To add tags to an existing SSM document, use the AddTagsToResource operation. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.CreateDocument"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Content, var: content}, {name: Requires, var: requires}, {name: Attachments, var: attachments}, {name: Name, var: name}, {name: DisplayName, var: display_name}, {name: VersionName, var: version_name}, {name: DocumentType, var: document_type}, {name: DocumentFormat, var: document_format}, {name: TargetType, var: target_type}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, content: $content, requires: $requires, attachments: $attachments, name: $name, display_name: $display_name, version_name: $version_name, document_type: $document_type, document_format: $document_format, target_type: $target_type, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new maintenance window. The value you specify for Duration determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for Cutoff. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for Cutoff is one hour, no maintenance window tasks can start after 5 PM.
#
# POST /
# Returns: record<WindowId: string>
# operationId: CreateMaintenanceWindow
export def "create-maintenance-window" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the maintenance window.
  --description: string # An optional description for the maintenance window. We recommend specifying a description to help you organize your maintenance windows. (format: password)
  --start-date: string # The date and time, in ISO-8601 Extended format, for when you want the maintenance window to become active. StartDate allows you to delay activation of the maintenance window until the specified future date.
  --end-date: string # The date and time, in ISO-8601 Extended format, for when you want the maintenance window to become inactive. EndDate allows you to set a date and time in the future when the maintenance window will no longer run.
  schedule: string # The schedule of the maintenance window in the form of a cron or rate expression.
  --schedule-timezone: string # The time zone that the scheduled maintenance window executions are based on, in Internet Assigned Numbers Authority (IANA) format. For example: "America/Los_Angeles", "UTC", or "Asia/Seoul". For more information, see the Time Zone Database (https://www.iana.org/time-zones) on the IANA website.
  --schedule-offset: int # The number of days to wait after the date and time specified by a cron expression before running the maintenance window. For example, the following cron expression schedules a maintenance window to run on the third Tuesday of every month at 11:30 PM. cron(30 23 ? * TUE#3 *) If the schedule offset is 2, the maintenance window won't run until two days later.
  duration: int # The duration of the maintenance window in hours.
  cutoff: int # The number of hours before the end of the maintenance window that Amazon Web Services Systems Manager stops scheduling new tasks for execution.
  --allow-unassociated-targets: oneof<nothing, bool> # Enables a maintenance window task to run on managed nodes, even if you haven't registered those nodes as targets. If enabled, then you must specify the unregistered managed nodes (by node ID) when you register a task with the maintenance window. If you don't enable this option, then you must specify previously-registered targets when you register a task with the maintenance window.
  --client-token: string # User-provided idempotency token.
  --tags: list # Optional metadata that you assign to a resource. Tags enable you to categorize a resource in different ways, such as by purpose, owner, or environment. For example, you might want to tag a maintenance window to identify the type of tasks it will run, the types of targets, and the environment it will run in. In this case, you could specify the following key-value pairs: Key=TaskType,Value=AgentUpdate Key=OS,Value=Windows Key=Environment,Value=Production To add tags to an existing maintenance window, use the AddTagsToResource operation. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.CreateMaintenanceWindow"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: Schedule, var: schedule}, {name: ScheduleTimezone, var: schedule_timezone}, {name: ScheduleOffset, var: schedule_offset}, {name: Duration, var: duration}, {name: Cutoff, var: cutoff}, {name: AllowUnassociatedTargets, var: allow_unassociated_targets, required: true}, {name: ClientToken, var: client_token}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, start_date: $start_date, end_date: $end_date, schedule: $schedule, schedule_timezone: $schedule_timezone, schedule_offset: $schedule_offset, duration: $duration, cutoff: $cutoff, allow_unassociated_targets: $allow_unassociated_targets, client_token: $client_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new OpsItem. You must have permission in Identity and Access Management (IAM) to create a new OpsItem. For more information, see Getting started with OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html) in the Amazon Web Services Systems Manager User Guide. Operations engineers and IT professionals use Amazon Web Services Systems Manager OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their Amazon Web Services resources. For more information, see Amazon Web Services Systems Manager OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html) in the Amazon Web Services Systems Manager User Guide.
#
# POST /
# Returns: record<OpsItemId: string, OpsItemArn: string>
# operationId: CreateOpsItem
export def "create-ops-item" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  description: string # Information about the OpsItem.
  --ops-item-type: string # The type of OpsItem to create. Systems Manager supports the following types of OpsItems: /aws/issue This type of OpsItem is used for default OpsItems created by OpsCenter. /aws/changerequest This type of OpsItem is used by Change Manager for reviewing and approving or rejecting change requests. /aws/insights This type of OpsItem is used by OpsCenter for aggregating and reporting on duplicate OpsItems.
  --operational-data: record # Operational data is custom data that provides useful reference details about the OpsItem. For example, you can specify log files, error strings, license keys, troubleshooting tips, or other relevant data. You enter operational data as key-value pairs. The key has a maximum length of 128 characters. The value has a maximum size of 20 KB. Operational data keys can't begin with the following: amazon, aws, amzn, ssm, /amazon, /aws, /amzn, /ssm. You can choose to make the data searchable by other users in the account or you can restrict search access. Searchable data means that all users with access to the OpsItem Overview page (as provided by the DescribeOpsItems API operation) can view and search on the specified data. Operational data that isn't searchable is only viewable by users who have access to the OpsItem (as provided by the GetOpsItem API operation). Use the /aws/resources key in OperationalData to specify a related resource in the request. Use the /aws/automations key in OperationalData to associate an Automation runbook with the OpsItem. To view Amazon Web Services CLI example commands that use these keys, see Creating OpsItems manually (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-creating-OpsItems.html#OpsCenter-manually-create-OpsItems) in the Amazon Web Services Systems Manager User Guide.
  --notifications: list # The Amazon Resource Name (ARN) of an SNS topic where notifications are sent when this OpsItem is edited or changed. — item shape: {Arn?: string}
  --priority: int # The importance of this OpsItem in relation to other OpsItems in the system.
  --related-ops-items: list # One or more OpsItems that share something in common with the current OpsItems. For example, related OpsItems can include OpsItems with similar error messages, impacted resources, or statuses for the impacted resource. — item shape: {OpsItemId: string}
  source: string # The origin of the OpsItem, such as Amazon EC2 or Systems Manager. The source name can't contain the following strings: aws, amazon, and amzn.
  title: string # A short heading that describes the nature of the OpsItem and the impacted resource.
  --tags: list # Optional metadata that you assign to a resource. You can restrict access to OpsItems by using an inline IAM policy that specifies tags. For more information, see Getting started with OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html#OpsCenter-getting-started-user-permissions) in the Amazon Web Services Systems Manager User Guide. Tags use a key-value pair. For example: Key=Department,Value=Finance To add tags to a new OpsItem, a user must have IAM permissions for both the ssm:CreateOpsItems operation and the ssm:AddTagsToResource operation. To add tags to an existing OpsItem, use the AddTagsToResource operation. — item shape: {Key: string, Value: string}
  --category: string # Specify a category to assign to an OpsItem.
  --severity: string # Specify a severity to assign to an OpsItem.
  --actual-start-time: string # The time a runbook workflow started. Currently reported only for the OpsItem type /aws/changerequest. (format: date-time)
  --actual-end-time: string # The time a runbook workflow ended. Currently reported only for the OpsItem type /aws/changerequest. (format: date-time)
  --planned-start-time: string # The time specified in a change request for a runbook workflow to start. Currently supported only for the OpsItem type /aws/changerequest. (format: date-time)
  --planned-end-time: string # The time specified in a change request for a runbook workflow to end. Currently supported only for the OpsItem type /aws/changerequest. (format: date-time)
  --account-id: string # The target Amazon Web Services account where you want to create an OpsItem. To make this call, your account must be configured to work with OpsItems across accounts. For more information, see Setting up OpsCenter to work with OpsItems across accounts (https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-OpsCenter-multiple-accounts.html) in the Amazon Web Services Systems Manager User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.CreateOpsItem"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: OpsItemType, var: ops_item_type}, {name: OperationalData, var: operational_data}, {name: Notifications, var: notifications}, {name: Priority, var: priority}, {name: RelatedOpsItems, var: related_ops_items}, {name: Source, var: source}, {name: Title, var: title}, {name: Tags, var: tags}, {name: Category, var: category}, {name: Severity, var: severity}, {name: ActualStartTime, var: actual_start_time}, {name: ActualEndTime, var: actual_end_time}, {name: PlannedStartTime, var: planned_start_time}, {name: PlannedEndTime, var: planned_end_time}, {name: AccountId, var: account_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, description: $description, ops_item_type: $ops_item_type, operational_data: $operational_data, notifications: $notifications, priority: $priority, related_ops_items: $related_ops_items, source: $source, title: $title, tags: $tags, category: $category, severity: $severity, actual_start_time: $actual_start_time, actual_end_time: $actual_end_time, planned_start_time: $planned_start_time, planned_end_time: $planned_end_time, account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# If you create a new application in Application Manager, Amazon Web Services Systems Manager calls this API operation to specify information about the new application, including the application type.
#
# POST /
# Returns: record<OpsMetadataArn: string>
# operationId: CreateOpsMetadata
export def "create-ops-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_id: string # A resource ID for a new Application Manager application.
  --metadata: record # Metadata for a new Application Manager application.
  --tags: list # Optional metadata that you assign to a resource. You can specify a maximum of five tags for an OpsMetadata object. Tags enable you to categorize a resource in different ways, such as by purpose, owner, or environment. For example, you might want to tag an OpsMetadata object to identify an environment or target Amazon Web Services Region. In this case, you could specify the following key-value pairs: Key=Environment,Value=Production Key=Region,Value=us-east-2 — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.CreateOpsMetadata"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}, {name: Metadata, var: metadata}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id, metadata: $metadata, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a patch baseline. For information about valid key-value pairs in PatchFilters for each supported operating system type, see PatchFilter.
#
# POST /
# Returns: record<BaselineId: string>
# operationId: CreatePatchBaseline
export def "create-patch-baseline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --operating-system: string@operating-system-completer # Defines the operating system the patch baseline applies to. The default value is WINDOWS.
  name: string # The name of the patch baseline.
  --global-filters: record # A set of patch filters, typically used for approval rules. — shape: {PatchFilters: list}
  --approval-rules: record # A set of rules defining the approval rules for a patch baseline. — shape: {PatchRules: list}
  --approved-patches: list<string> # A list of explicitly approved patches for the baseline. For information about accepted formats for lists of approved patches and rejected patches, see About package name formats for approved and rejected patch lists (https://docs.aws.amazon.com/systems-manager/latest/userguide/patch-manager-approved-rejected-package-name-formats.html) in the Amazon Web Services Systems Manager User Guide.
  --approved-patches-compliance-level: string@approved-patches-compliance-level-completer # Defines the compliance level for approved patches. When an approved patch is reported as missing, this value describes the severity of the compliance violation. The default value is UNSPECIFIED.
  --approved-patches-enable-non-security: oneof<nothing, bool> # Indicates whether the list of approved patches includes non-security updates that should be applied to the managed nodes. The default value is false. Applies to Linux managed nodes only.
  --rejected-patches: list<string> # A list of explicitly rejected patches for the baseline. For information about accepted formats for lists of approved patches and rejected patches, see About package name formats for approved and rejected patch lists (https://docs.aws.amazon.com/systems-manager/latest/userguide/patch-manager-approved-rejected-package-name-formats.html) in the Amazon Web Services Systems Manager User Guide.
  --rejected-patches-action: string@rejected-patches-action-completer # The action for Patch Manager to take on patches included in the RejectedPackages list. ALLOW_AS_DEPENDENCY : A package in the Rejected patches list is installed only if it is a dependency of another package. It is considered compliant with the patch baseline, and its status is reported as InstalledOther. This is the default action if no option is specified. BLOCK : Packages in the RejectedPatches list, and packages that include them as dependencies, aren't installed under any circumstances. If a package was installed before it was added to the Rejected patches list, it is considered non-compliant with the patch baseline, and its status is reported as InstalledRejected.
  --description: string # A description of the patch baseline.
  --sources: list # Information about the patches to use to update the managed nodes, including target operating systems and source repositories. Applies to Linux managed nodes only. — item shape: {Name: string, Products: list<string>, Configuration: string}
  --client-token: string # User-provided idempotency token.
  --tags: list # Optional metadata that you assign to a resource. Tags enable you to categorize a resource in different ways, such as by purpose, owner, or environment. For example, you might want to tag a patch baseline to identify the severity level of patches it specifies and the operating system family it applies to. In this case, you could specify the following key-value pairs: Key=PatchSeverity,Value=Critical Key=OS,Value=Windows To add tags to an existing patch baseline, use the AddTagsToResource operation. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.CreatePatchBaseline"}]
    body: {content_type: "application/json", kind: json, fields: [{name: OperatingSystem, var: operating_system}, {name: Name, var: name}, {name: GlobalFilters, var: global_filters}, {name: ApprovalRules, var: approval_rules}, {name: ApprovedPatches, var: approved_patches}, {name: ApprovedPatchesComplianceLevel, var: approved_patches_compliance_level}, {name: ApprovedPatchesEnableNonSecurity, var: approved_patches_enable_non_security}, {name: RejectedPatches, var: rejected_patches}, {name: RejectedPatchesAction, var: rejected_patches_action}, {name: Description, var: description}, {name: Sources, var: sources}, {name: ClientToken, var: client_token}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, operating_system: $operating_system, name: $name, global_filters: $global_filters, approval_rules: $approval_rules, approved_patches: $approved_patches, approved_patches_compliance_level: $approved_patches_compliance_level, approved_patches_enable_non_security: $approved_patches_enable_non_security, rejected_patches: $rejected_patches, rejected_patches_action: $rejected_patches_action, description: $description, sources: $sources, client_token: $client_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A resource data sync helps you view data from multiple sources in a single location. Amazon Web Services Systems Manager offers two types of resource data sync: SyncToDestination and SyncFromSource. You can configure Systems Manager Inventory to use the SyncToDestination type to synchronize Inventory data from multiple Amazon Web Services Regions to a single Amazon Simple Storage Service (Amazon S3) bucket. For more information, see Configuring resource data sync for Inventory (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html) in the Amazon Web Services Systems Manager User Guide. You can configure Systems Manager Explorer to use the SyncFromSource type to synchronize operational work items (OpsItems) and operational data (OpsData) from multiple Amazon Web Services Regions to a single Amazon S3 bucket. This type can synchronize OpsItems and OpsData from multiple Amazon Web Services accounts and Amazon Web Services Regions or EntireOrganization by using Organizations. For more information, see Setting up Systems Manager Explorer to display data from multiple accounts and Regions (https://docs.aws.amazon.com/systems-manager/latest/userguide/Explorer-resource-data-sync.html) in the Amazon Web Services Systems Manager User Guide. A resource data sync is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data. To check the status of a sync, use the ListResourceDataSync. By default, data isn't encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy.
#
# POST /
# Returns: record
# operationId: CreateResourceDataSync
export def "create-resource-data-sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  sync_name: string # A name for the configuration.
  --s3-destination: record # Information about the target S3 bucket for the resource data sync. — shape: {BucketName: string, Prefix?: string, SyncFormat: "JsonSerDe", Region: string, AWSKMSKeyARN?: string, DestinationDataSharing?: record}
  --sync-type: string # Specify SyncToDestination to create a resource data sync that synchronizes data to an S3 bucket for Inventory. If you specify SyncToDestination, you must provide a value for S3Destination. Specify SyncFromSource to synchronize data from a single account and multiple Regions, or multiple Amazon Web Services accounts and Amazon Web Services Regions, as listed in Organizations for Explorer. If you specify SyncFromSource, you must provide a value for SyncSource. The default value is SyncToDestination.
  --sync-source: record # Information about the source of the data included in the resource data sync. — shape: {SourceType: string, AwsOrganizationsSource?: record, SourceRegions: list<string>, IncludeFutureRegions?: bool, EnableAllOpsDataSources?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.CreateResourceDataSync"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SyncName, var: sync_name}, {name: S3Destination, var: s3_destination}, {name: SyncType, var: sync_type}, {name: SyncSource, var: sync_source}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, sync_name: $sync_name, s3_destination: $s3_destination, sync_type: $sync_type, sync_source: $sync_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an activation. You aren't required to delete an activation. If you delete an activation, you can no longer use it to register additional managed nodes. Deleting an activation doesn't de-register managed nodes. You must manually de-register managed nodes.
#
# POST /
# Returns: record
# operationId: DeleteActivation
export def "delete-activation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  activation_id: string # The ID of the activation that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DeleteActivation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ActivationId, var: activation_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, activation_id: $activation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates the specified Amazon Web Services Systems Manager document (SSM document) from the specified managed node. If you created the association by using the Targets parameter, then you must delete the association by using the association ID. When you disassociate a document from a managed node, it doesn't change the configuration of the node. To change the configuration state of a managed node after you disassociate a document, you must create a new document with the desired configuration and associate it with the node.
#
# POST /
# Returns: record
# operationId: DeleteAssociation
export def "delete-association" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --name: string # The name of the SSM document.
  --instance-id: string # The managed node ID. InstanceId has been deprecated. To specify a managed node ID for an association, use the Targets parameter. Requests that include the parameter InstanceID with Systems Manager documents (SSM documents) that use schema version 2.0 or later will fail. In addition, if you use the parameter InstanceId, you can't use the parameters AssociationName, DocumentVersion, MaxErrors, MaxConcurrency, OutputLocation, or ScheduleExpression. To use these parameters, you must use the Targets parameter.
  --association-id: string # The association ID that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DeleteAssociation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: InstanceId, var: instance_id}, {name: AssociationId, var: association_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, instance_id: $instance_id, association_id: $association_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the Amazon Web Services Systems Manager document (SSM document) and all managed node associations to the document. Before you delete the document, we recommend that you use DeleteAssociation to disassociate all managed nodes that are associated with the document.
#
# POST /
# Returns: record
# operationId: DeleteDocument
export def "delete-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the document.
  --document-version: string # The version of the document that you want to delete. If not provided, all versions of the document are deleted.
  --version-name: string # The version name of the document that you want to delete. If not provided, all versions of the document are deleted.
  --force: oneof<nothing, bool> # Some SSM document types require that you specify a Force flag before you can delete the document. For example, you must specify a Force flag to delete a document of type ApplicationConfigurationSchema. You can restrict access to the Force flag in an Identity and Access Management (IAM) policy.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DeleteDocument"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: DocumentVersion, var: document_version}, {name: VersionName, var: version_name}, {name: Force, var: force}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, document_version: $document_version, version_name: $version_name, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a custom inventory type or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
#
# POST /
# Returns: record<DeletionId: string, TypeName: string, DeletionSummary: record<TotalCount: int, RemainingCount: int, SummaryItems: list<record>>>
# operationId: DeleteInventory
export def "delete-inventory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  type_name: string # The name of the custom inventory type for which you want to delete either all previously collected data or the inventory type itself.
  --schema-delete-option: string@schema-delete-option-completer # Use the SchemaDeleteOption to delete a custom inventory type (schema). If you don't choose this option, the system only deletes existing inventory data associated with the custom inventory type. Choose one of the following options: DisableSchema: If you choose this option, the system ignores all inventory data for the specified version, and any earlier versions. To enable this schema again, you must call the PutInventory operation for a version greater than the disabled version. DeleteSchema: This option deletes the specified custom type from the Inventory service. You can recreate the schema later, if you want.
  --body-dry-run: oneof<nothing, bool> # Use this option to view a summary of the deletion request without deleting any data or the data type. This option is useful when you only want to understand what will be deleted. Once you validate that the data to be deleted is what you intend to delete, you can run the same command without specifying the DryRun option. (spec name: DryRun)
  --client-token: string # User-provided idempotency token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DeleteInventory"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TypeName, var: type_name}, {name: SchemaDeleteOption, var: schema_delete_option}, {name: DryRun, var: body_dry_run}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, type_name: $type_name, schema_delete_option: $schema_delete_option, body_dry_run: $body_dry_run, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a maintenance window.
#
# POST /
# Returns: record<WindowId: string>
# operationId: DeleteMaintenanceWindow
export def "delete-maintenance-window" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  window_id: string # The ID of the maintenance window to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DeleteMaintenanceWindow"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowId, var: window_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_id: $window_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete OpsMetadata related to an application.
#
# POST /
# Returns: record
# operationId: DeleteOpsMetadata
export def "delete-ops-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  ops_metadata_arn: string # The Amazon Resource Name (ARN) of an OpsMetadata Object to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DeleteOpsMetadata"}]
    body: {content_type: "application/json", kind: json, fields: [{name: OpsMetadataArn, var: ops_metadata_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ops_metadata_arn: $ops_metadata_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a parameter from the system. After deleting a parameter, wait for at least 30 seconds to create a parameter with the same name.
#
# POST /
# Returns: record
# operationId: DeleteParameter
export def "delete-parameter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the parameter to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DeleteParameter"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a list of parameters. After deleting a parameter, wait for at least 30 seconds to create a parameter with the same name.
#
# POST /
# Returns: record<DeletedParameters: list<string>, InvalidParameters: list<string>>
# operationId: DeleteParameters
export def "delete-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  names: list<string> # The names of the parameters to delete. After deleting a parameter, wait for at least 30 seconds to create a parameter with the same name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DeleteParameters"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Names, var: names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, names: $names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a patch baseline.
#
# POST /
# Returns: record<BaselineId: string>
# operationId: DeletePatchBaseline
export def "delete-patch-baseline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  baseline_id: string # The ID of the patch baseline to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DeletePatchBaseline"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BaselineId, var: baseline_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, baseline_id: $baseline_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a resource data sync configuration. After the configuration is deleted, changes to data on managed nodes are no longer synced to or from the target. Deleting a sync configuration doesn't delete data.
#
# POST /
# Returns: record
# operationId: DeleteResourceDataSync
export def "delete-resource-data-sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  sync_name: string # The name of the configuration to delete.
  --sync-type: string # Specify the type of resource data sync to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DeleteResourceDataSync"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SyncName, var: sync_name}, {name: SyncType, var: sync_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, sync_name: $sync_name, sync_type: $sync_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Systems Manager resource policy. A resource policy helps you to define the IAM entity (for example, an Amazon Web Services account) that can manage your Systems Manager resources. Currently, OpsItemGroup is the only resource that supports Systems Manager resource policies. The resource policy for OpsItemGroup enables Amazon Web Services accounts to view and interact with OpsCenter operational work items (OpsItems).
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
  --x-amz-target: string@x-amz-target-completer-23 # required
  resource_arn: string # Amazon Resource Name (ARN) of the resource to which the policies are attached.
  policy_id: string # The policy ID.
  policy_hash: string # ID of the current policy version. The hash helps to prevent multiple calls from attempting to overwrite a policy.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DeleteResourcePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: PolicyId, var: policy_id}, {name: PolicyHash, var: policy_hash}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, policy_id: $policy_id, policy_hash: $policy_hash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the server or virtual machine from the list of registered servers. You can reregister the node again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
#
# POST /
# Returns: record
# operationId: DeregisterManagedInstance
export def "deregister-managed-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_id: string # The ID assigned to the managed node when you registered it using the activation process.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DeregisterManagedInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a patch group from a patch baseline.
#
# POST /
# Returns: record<BaselineId: string, PatchGroup: string>
# operationId: DeregisterPatchBaselineForPatchGroup
export def "deregister-patch-baseline-for-patch-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  baseline_id: string # The ID of the patch baseline to deregister the patch group from.
  patch_group: string # The name of the patch group that should be deregistered from the patch baseline.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DeregisterPatchBaselineForPatchGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BaselineId, var: baseline_id}, {name: PatchGroup, var: patch_group}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, baseline_id: $baseline_id, patch_group: $patch_group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a target from a maintenance window.
#
# POST /
# Returns: record<WindowId: string, WindowTargetId: string>
# operationId: DeregisterTargetFromMaintenanceWindow
export def "deregister-target-from-maintenance-window" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  window_id: string # The ID of the maintenance window the target should be removed from.
  window_target_id: string # The ID of the target definition to remove.
  --safe: oneof<nothing, bool> # The system checks if the target is being referenced by a task. If the target is being referenced, the system returns an error and doesn't deregister the target from the maintenance window.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DeregisterTargetFromMaintenanceWindow"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowId, var: window_id}, {name: WindowTargetId, var: window_target_id}, {name: Safe, var: safe}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_id: $window_id, window_target_id: $window_target_id, safe: $safe
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a task from a maintenance window.
#
# POST /
# Returns: record<WindowId: string, WindowTaskId: string>
# operationId: DeregisterTaskFromMaintenanceWindow
export def "deregister-task-from-maintenance-window" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  window_id: string # The ID of the maintenance window the task should be removed from.
  window_task_id: string # The ID of the task to remove from the maintenance window.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DeregisterTaskFromMaintenanceWindow"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowId, var: window_id}, {name: WindowTaskId, var: window_task_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_id: $window_id, window_task_id: $window_task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes details about the activation, such as the date and time the activation was created, its expiration date, the Identity and Access Management (IAM) role assigned to the managed nodes in the activation, and the number of nodes registered by using this activation.
#
# POST /
# Returns: record<ActivationList: table<ActivationId: string, Description: string, DefaultInstanceName: string, IamRole: string, RegistrationLimit: int, RegistrationsCount: int, ExpirationDate: string, Expired: bool, CreatedDate: string, Tags: list>, NextToken: string>
# operationId: DescribeActivations
export def "describe-activations" [
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  --filters: list # A filter to view information about your activations. — item shape: {FilterKey?: "ActivationIds"|"DefaultInstanceName"|"IamRole", FilterValues?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeActivations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the association for the specified target or managed node. If you created the association by using the Targets parameter, then you must retrieve the association by using the association ID.
#
# POST /
# Returns: record<AssociationDescription: record<Name: string, InstanceId: string, AssociationVersion: string, Date: string, LastUpdateAssociationDate: string, Status: record<Date: string, Name: string, Message: string, AdditionalInfo: string>, Overview: record<Status: string, DetailedStatus: string, AssociationStatusAggregatedCount: record>, DocumentVersion: string, AutomationTargetParameterName: string, Parameters: record, AssociationId: string, Targets: list<record>, ScheduleExpression: string, OutputLocation: record<S3Location: record>, LastExecutionDate: string, LastSuccessfulExecutionDate: string, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list<string>, TargetLocations: list<record>, ScheduleOffset: int, TargetMaps: list<record>, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>>>
# operationId: DescribeAssociation
export def "describe-association" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --name: string # The name of the SSM document.
  --instance-id: string # The managed node ID.
  --association-id: string # The association ID for which you want information.
  --association-version: string # Specify the association version to retrieve. To view the latest version, either specify $LATEST for this parameter, or omit this parameter. To view a list of all associations for a managed node, use ListAssociations. To get a list of versions for a specific association, use ListAssociationVersions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeAssociation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: InstanceId, var: instance_id}, {name: AssociationId, var: association_id}, {name: AssociationVersion, var: association_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, instance_id: $instance_id, association_id: $association_id, association_version: $association_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Views information about a specific execution of a specific association.
#
# POST /
# Returns: record<AssociationExecutionTargets: table<AssociationId: string, AssociationVersion: string, ExecutionId: string, ResourceId: string, ResourceType: string, Status: string, DetailedStatus: string, LastExecutionDate: string, OutputSource: record>, NextToken: string>
# operationId: DescribeAssociationExecutionTargets
export def "describe-association-execution-targets" [
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
  association_id: string # The association ID that includes the execution for which you want to view details.
  execution_id: string # The execution ID for which you want to view details.
  --filters: list # Filters for the request. You can specify the following filters and values. Status (EQUAL) ResourceId (EQUAL) ResourceType (EQUAL) — item shape: {Key: "Status"|"ResourceId"|"ResourceType", Value: string}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeAssociationExecutionTargets"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AssociationId, var: association_id}, {name: ExecutionId, var: execution_id}, {name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, association_id: $association_id, execution_id: $execution_id, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Views all executions for a specific association ID.
#
# POST /
# Returns: record<AssociationExecutions: table<AssociationId: string, AssociationVersion: string, ExecutionId: string, Status: string, DetailedStatus: string, CreatedTime: string, LastExecutionDate: string, ResourceCountByStatus: string, AlarmConfiguration: record, TriggeredAlarms: list>, NextToken: string>
# operationId: DescribeAssociationExecutions
export def "describe-association-executions" [
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
  association_id: string # The association ID for which you want to view execution history details.
  --filters: list # Filters for the request. You can specify the following filters and values. ExecutionId (EQUAL) Status (EQUAL) CreatedTime (EQUAL, GREATER_THAN, LESS_THAN) — item shape: {Key: "ExecutionId"|"Status"|"CreatedTime", Value: string, Type: "EQUAL"|"LESS_THAN"|"GREATER_THAN"}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeAssociationExecutions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AssociationId, var: association_id}, {name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, association_id: $association_id, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides details about all active and terminated Automation executions.
#
# POST /
# Returns: record<AutomationExecutionMetadataList: table<AutomationExecutionId: string, DocumentName: string, DocumentVersion: string, AutomationExecutionStatus: string, ExecutionStartTime: string, ExecutionEndTime: string, ExecutedBy: string, LogFile: string, Outputs: record, Mode: string, ParentAutomationExecutionId: string, CurrentStepName: string, CurrentAction: string, FailureMessage: string, TargetParameterName: string, Targets: list, TargetMaps: list, ResolvedTargets: record, MaxConcurrency: string, MaxErrors: string, Target: string, AutomationType: string, AlarmConfiguration: record, TriggeredAlarms: list, AutomationSubtype: string, ScheduledTime: string, Runbooks: list, OpsItemId: string, AssociationId: string, ChangeRequestName: string>, NextToken: string>
# operationId: DescribeAutomationExecutions
export def "describe-automation-executions" [
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
  --filters: list # Filters used to limit the scope of executions that are requested. — item shape: {Key: "DocumentNamePrefix"|"ExecutionStatus"|"ExecutionId"|"ParentExecutionId"|"CurrentAction"|"StartTimeBefore"|"StartTimeAfter"|"AutomationType"|"TagKey"|"TargetResourceGroup"|"AutomationSubtype"|"OpsItemId", Values: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeAutomationExecutions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information about all active and terminated step executions in an Automation workflow.
#
# POST /
# Returns: record<StepExecutions: table<StepName: string, Action: string, TimeoutSeconds: int, OnFailure: string, MaxAttempts: int, ExecutionStartTime: string, ExecutionEndTime: string, StepStatus: string, ResponseCode: string, Inputs: record, Outputs: record, Response: string, FailureMessage: string, FailureDetails: record, StepExecutionId: string, OverriddenParameters: record, IsEnd: bool, NextStep: string, IsCritical: bool, ValidNextSteps: list, Targets: list, TargetLocation: record, TriggeredAlarms: list>, NextToken: string>
# operationId: DescribeAutomationStepExecutions
export def "describe-automation-step-executions" [
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
  automation_execution_id: string # The Automation execution ID for which you want step execution descriptions.
  --filters: list # One or more filters to limit the number of step executions returned by the request. — item shape: {Key: "StartTimeBefore"|"StartTimeAfter"|"StepExecutionStatus"|"StepExecutionId"|"StepName"|"Action", Values: list<string>}
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --reverse-order: oneof<nothing, bool> # Indicates whether to list step executions in reverse order by start time. The default value is 'false'.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeAutomationStepExecutions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AutomationExecutionId, var: automation_execution_id}, {name: Filters, var: filters}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: ReverseOrder, var: reverse_order}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, automation_execution_id: $automation_execution_id, filters: $filters, body_next_token: $body_next_token, body_max_results: $body_max_results, reverse_order: $reverse_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all patches eligible to be included in a patch baseline.
#
# POST /
# Returns: record<Patches: table<Id: string, ReleaseDate: string, Title: string, Description: string, ContentUrl: string, Vendor: string, ProductFamily: string, Product: string, Classification: string, MsrcSeverity: string, KbNumber: string, MsrcNumber: string, Language: string, AdvisoryIds: list, BugzillaIds: list, CVEIds: list, Name: string, Epoch: int, Version: string, Release: string, Arch: string, Severity: string, Repository: string>, NextToken: string>
# operationId: DescribeAvailablePatches
export def "describe-available-patches" [
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
  --x-amz-target: string@x-amz-target-completer-34 # required
  --filters: list # Each element in the array is a structure containing a key-value pair. Windows Server Supported keys for Windows Server managed node patches include the following: PATCH_SET Sample values: OS | APPLICATION PRODUCT Sample values: WindowsServer2012 | Office 2010 | MicrosoftDefenderAntivirus PRODUCT_FAMILY Sample values: Windows | Office MSRC_SEVERITY Sample values: ServicePacks | Important | Moderate CLASSIFICATION Sample values: ServicePacks | SecurityUpdates | DefinitionUpdates PATCH_ID Sample values: KB123456 | KB4516046 Linux When specifying filters for Linux patches, you must specify a key-pair for PRODUCT. For example, using the Command Line Interface (CLI), the following command fails: aws ssm describe-available-patches --filters Key=CVE_ID,Values=CVE-2018-3615 However, the following command succeeds: aws ssm describe-available-patches --filters Key=PRODUCT,Values=AmazonLinux2018.03 Key=CVE_ID,Values=CVE-2018-3615 Supported keys for Linux managed node patches include the following: PRODUCT Sample values: AmazonLinux2018.03 | AmazonLinux2.0 NAME Sample values: kernel-headers | samba-python | php SEVERITY Sample values: Critical | Important | Medium | Low EPOCH Sample values: 0 | 1 VERSION Sample values: 78.6.1 | 4.10.16 RELEASE Sample values: 9.56.amzn1 | 1.amzn2 ARCH Sample values: i686 | x86_64 REPOSITORY Sample values: Core | Updates ADVISORY_ID Sample values: ALAS-2018-1058 | ALAS2-2021-1594 CVE_ID Sample values: CVE-2018-3615 | CVE-2020-1472 BUGZILLA_ID Sample values: 1463241 — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of patches to return (per page). (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeAvailablePatches"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the specified Amazon Web Services Systems Manager document (SSM document).
#
# POST /
# Returns: record<Document: record<Sha1: string, Hash: string, HashType: string, Name: string, DisplayName: string, VersionName: string, Owner: string, CreatedDate: string, Status: string, StatusInformation: string, DocumentVersion: string, Description: string, Parameters: list<record>, PlatformTypes: list<string>, DocumentType: string, SchemaVersion: string, LatestVersion: string, DefaultVersion: string, DocumentFormat: string, TargetType: string, Tags: list<record>, AttachmentsInformation: list<record>, Requires: list<record>, Author: string, ReviewInformation: list<record>, ApprovedVersion: string, PendingReviewVersion: string, ReviewStatus: string, Category: list<string>, CategoryEnum: list<string>>>
# operationId: DescribeDocument
export def "describe-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the SSM document.
  --document-version: string # The document version for which you want information. Can be a specific version or the default version.
  --version-name: string # An optional field specifying the version of the artifact associated with the document. For example, "Release 12, Update 6". This value is unique across all versions of a document, and can't be changed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeDocument"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: DocumentVersion, var: document_version}, {name: VersionName, var: version_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, document_version: $document_version, version_name: $version_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the permissions for a Amazon Web Services Systems Manager document (SSM document). If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's Amazon Web Services account ID) or publicly (All).
#
# POST /
# Returns: record<AccountIds: list<string>, AccountSharingInfoList: table<AccountId: string, SharedDocumentVersion: string>, NextToken: string>
# operationId: DescribeDocumentPermission
export def "describe-document-permission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the document for which you are the owner.
  permission_type: string@permission-type-completer # The permission type for the document. The permission type can be Share.
  --max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeDocumentPermission"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: PermissionType, var: permission_type}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, permission_type: $permission_type, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All associations for the managed node(s).
#
# POST /
# Returns: record<Associations: table<AssociationId: string, InstanceId: string, Content: string, AssociationVersion: string>, NextToken: string>
# operationId: DescribeEffectiveInstanceAssociations
export def "describe-effective-instance-associations" [
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
  instance_id: string # The managed node ID for which you want to view all associations.
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeEffectiveInstanceAssociations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Applies to patch baselines for Windows only.
#
# POST /
# Returns: record<EffectivePatches: table<Patch: record, PatchStatus: record>, NextToken: string>
# operationId: DescribeEffectivePatchesForPatchBaseline
export def "describe-effective-patches-for-patch-baseline" [
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
  --x-amz-target: string@x-amz-target-completer-38 # required
  baseline_id: string # The ID of the patch baseline to retrieve the effective patches for.
  --body-max-results: int # The maximum number of patches to return (per page). (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeEffectivePatchesForPatchBaseline"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BaselineId, var: baseline_id}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, baseline_id: $baseline_id, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The status of the associations for the managed node(s).
#
# POST /
# Returns: record<InstanceAssociationStatusInfos: table<AssociationId: string, Name: string, DocumentVersion: string, AssociationVersion: string, InstanceId: string, ExecutionDate: string, Status: string, DetailedStatus: string, ExecutionSummary: string, ErrorCode: string, OutputUrl: record, AssociationName: string>, NextToken: string>
# operationId: DescribeInstanceAssociationsStatus
export def "describe-instance-associations-status" [
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
  --x-amz-target: string@x-amz-target-completer-39 # required
  instance_id: string # The managed node IDs for which you want association status information.
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeInstanceAssociationsStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes one or more of your managed nodes, including information about the operating system platform, the version of SSM Agent installed on the managed node, node status, and so on. If you specify one or more managed node IDs, it returns information for those managed nodes. If you don't specify node IDs, it returns information for all your managed nodes. If you specify a node ID that isn't valid or a node that you don't own, you receive an error. The IamRole field for this API operation is the Identity and Access Management (IAM) role assigned to on-premises managed nodes. This call doesn't return the IAM role for EC2 instances.
#
# POST /
# Returns: record<InstanceInformationList: table<InstanceId: string, PingStatus: string, LastPingDateTime: string, AgentVersion: string, IsLatestVersion: bool, PlatformType: string, PlatformName: string, PlatformVersion: string, ActivationId: string, IamRole: string, RegistrationDate: string, ResourceType: string, Name: string, IPAddress: string, ComputerName: string, AssociationStatus: string, LastAssociationExecutionDate: string, LastSuccessfulAssociationExecutionDate: string, AssociationOverview: record, SourceId: string, SourceType: string>, NextToken: string>
# operationId: DescribeInstanceInformation
export def "describe-instance-information" [
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
  --x-amz-target: string@x-amz-target-completer-40 # required
  --instance-information-filter-list: list # This is a legacy method. We recommend that you don't use this method. Instead, use the Filters data type. Filters enables you to return node information by filtering based on tags applied to managed nodes. Attempting to use InstanceInformationFilterList and Filters leads to an exception error. — item shape: {key: "InstanceIds"|"AgentVersion"|"PingStatus"|"PlatformTypes"|"ActivationIds"|"IamRole"|"ResourceType"|"AssociationStatus", valueSet: list<string>}
  --filters: list # One or more filters. Use a filter to return a more specific list of managed nodes. You can filter based on tags applied to your managed nodes. Use this Filters data type instead of InstanceInformationFilterList, which is deprecated. — item shape: {Key: string, Values: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeInstanceInformation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceInformationFilterList, var: instance_information_filter_list}, {name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_information_filter_list: $instance_information_filter_list, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the high-level patch state of one or more managed nodes.
#
# POST /
# Returns: record<InstancePatchStates: table<InstanceId: string, PatchGroup: string, BaselineId: string, SnapshotId: string, InstallOverrideList: string, OwnerInformation: string, InstalledCount: int, InstalledOtherCount: int, InstalledPendingRebootCount: int, InstalledRejectedCount: int, MissingCount: int, FailedCount: int, UnreportedNotApplicableCount: int, NotApplicableCount: int, OperationStartTime: string, OperationEndTime: string, Operation: string, LastNoRebootInstallOperationTime: string, RebootOption: string, CriticalNonCompliantCount: int, SecurityNonCompliantCount: int, OtherNonCompliantCount: int>, NextToken: string>
# operationId: DescribeInstancePatchStates
export def "describe-instance-patch-states" [
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
  --x-amz-target: string@x-amz-target-completer-41 # required
  instance_ids: list<string> # The ID of the managed node for which patch state information should be retrieved.
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --body-max-results: int # The maximum number of managed nodes to return (per page). (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeInstancePatchStates"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceIds, var: instance_ids}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_ids: $instance_ids, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the high-level patch state for the managed nodes in the specified patch group.
#
# POST /
# Returns: record<InstancePatchStates: table<InstanceId: string, PatchGroup: string, BaselineId: string, SnapshotId: string, InstallOverrideList: string, OwnerInformation: string, InstalledCount: int, InstalledOtherCount: int, InstalledPendingRebootCount: int, InstalledRejectedCount: int, MissingCount: int, FailedCount: int, UnreportedNotApplicableCount: int, NotApplicableCount: int, OperationStartTime: string, OperationEndTime: string, Operation: string, LastNoRebootInstallOperationTime: string, RebootOption: string, CriticalNonCompliantCount: int, SecurityNonCompliantCount: int, OtherNonCompliantCount: int>, NextToken: string>
# operationId: DescribeInstancePatchStatesForPatchGroup
export def "describe-instance-patch-states-for-patch-group" [
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
  --x-amz-target: string@x-amz-target-completer-42 # required
  patch_group: string # The name of the patch group for which the patch state information should be retrieved.
  --filters: list # Each entry in the array is a structure containing: Key (string between 1 and 200 characters) Values (array containing a single string) Type (string "Equal", "NotEqual", "LessThan", "GreaterThan") — item shape: {Key: string, Values: list<string>, Type: "Equal"|"NotEqual"|"LessThan"|"GreaterThan"}
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --body-max-results: int # The maximum number of patches to return (per page). (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeInstancePatchStatesForPatchGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PatchGroup, var: patch_group}, {name: Filters, var: filters}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, patch_group: $patch_group, filters: $filters, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the patches on the specified managed node and their state relative to the patch baseline being used for the node.
#
# POST /
# Returns: record<Patches: table<Title: string, KBId: string, Classification: string, Severity: string, State: string, InstalledTime: string, CVEIds: string>, NextToken: string>
# operationId: DescribeInstancePatches
export def "describe-instance-patches" [
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
  --x-amz-target: string@x-amz-target-completer-43 # required
  instance_id: string # The ID of the managed node whose patch state information should be retrieved.
  --filters: list # Each element in the array is a structure containing a key-value pair. Supported keys for DescribeInstancePatchesinclude the following: Classification Sample values: Security | SecurityUpdates KBId Sample values: KB4480056 | java-1.7.0-openjdk.x86_64 Severity Sample values: Important | Medium | Low State Sample values: Installed | InstalledOther | InstalledPendingReboot — item shape: {Key?: string, Values?: list<string>}
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --body-max-results: int # The maximum number of patches to return (per page). (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeInstancePatches"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: Filters, var: filters}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id, filters: $filters, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a specific delete inventory operation.
#
# POST /
# Returns: record<InventoryDeletions: table<DeletionId: string, TypeName: string, DeletionStartTime: string, LastStatus: string, LastStatusMessage: string, DeletionSummary: record, LastStatusUpdateTime: string>, NextToken: string>
# operationId: DescribeInventoryDeletions
export def "describe-inventory-deletions" [
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
  --x-amz-target: string@x-amz-target-completer-44 # required
  --deletion-id: string # Specify the delete inventory ID for which you want information. This ID was returned by the DeleteInventory operation.
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeInventoryDeletions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DeletionId, var: deletion_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deletion_id: $deletion_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
#
# POST /
# Returns: record<WindowExecutionTaskInvocationIdentities: table<WindowExecutionId: string, TaskExecutionId: string, InvocationId: string, ExecutionId: string, TaskType: string, Parameters: string, Status: string, StatusDetails: string, StartTime: string, EndTime: string, OwnerInformation: string, WindowTargetId: string>, NextToken: string>
# operationId: DescribeMaintenanceWindowExecutionTaskInvocations
export def "describe-maintenance-window-execution-task-invocations" [
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
  --x-amz-target: string@x-amz-target-completer-45 # required
  window_execution_id: string # The ID of the maintenance window execution the task is part of.
  task_id: string # The ID of the specific task in the maintenance window task that should be retrieved.
  --filters: list # Optional filters used to scope down the returned task invocations. The supported filter key is STATUS with the corresponding values PENDING, IN_PROGRESS, SUCCESS, FAILED, TIMED_OUT, CANCELLING, and CANCELLED. — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowExecutionId, var: window_execution_id}, {name: TaskId, var: task_id}, {name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_execution_id: $window_execution_id, task_id: $task_id, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For a given maintenance window execution, lists the tasks that were run.
#
# POST /
# Returns: record<WindowExecutionTaskIdentities: table<WindowExecutionId: string, TaskExecutionId: string, Status: string, StatusDetails: string, StartTime: string, EndTime: string, TaskArn: string, TaskType: string, AlarmConfiguration: record, TriggeredAlarms: list>, NextToken: string>
# operationId: DescribeMaintenanceWindowExecutionTasks
export def "describe-maintenance-window-execution-tasks" [
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
  --x-amz-target: string@x-amz-target-completer-46 # required
  window_execution_id: string # The ID of the maintenance window execution whose task executions should be retrieved.
  --filters: list # Optional filters used to scope down the returned tasks. The supported filter key is STATUS with the corresponding values PENDING, IN_PROGRESS, SUCCESS, FAILED, TIMED_OUT, CANCELLING, and CANCELLED. — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeMaintenanceWindowExecutionTasks"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowExecutionId, var: window_execution_id}, {name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_execution_id: $window_execution_id, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
#
# POST /
# Returns: record<WindowExecutions: table<WindowId: string, WindowExecutionId: string, Status: string, StatusDetails: string, StartTime: string, EndTime: string>, NextToken: string>
# operationId: DescribeMaintenanceWindowExecutions
export def "describe-maintenance-window-executions" [
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
  --x-amz-target: string@x-amz-target-completer-47 # required
  window_id: string # The ID of the maintenance window whose executions should be retrieved.
  --filters: list # Each entry in the array is a structure containing: Key. A string between 1 and 128 characters. Supported keys include ExecutedBefore and ExecutedAfter. Values. An array of strings, each between 1 and 256 characters. Supported values are date/time strings in a valid ISO 8601 date/time format, such as 2021-11-04T05:00:00Z. — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeMaintenanceWindowExecutions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowId, var: window_id}, {name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_id: $window_id, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about upcoming executions of a maintenance window.
#
# POST /
# Returns: record<ScheduledWindowExecutions: table<WindowId: string, Name: string, ExecutionTime: string>, NextToken: string>
# operationId: DescribeMaintenanceWindowSchedule
export def "describe-maintenance-window-schedule" [
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
  --window-id: string # The ID of the maintenance window to retrieve information about.
  --targets: list # The managed node ID or key-value pair to retrieve information about. — item shape: {Key?: string, Values?: list<string>}
  --resource-type: string@resource-type-completer-1 # The type of resource you want to retrieve information about. For example, INSTANCE.
  --filters: list # Filters used to limit the range of results. For example, you can limit maintenance window executions to only those scheduled before or after a certain date and time. — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeMaintenanceWindowSchedule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowId, var: window_id}, {name: Targets, var: targets}, {name: ResourceType, var: resource_type}, {name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_id: $window_id, targets: $targets, resource_type: $resource_type, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the targets registered with the maintenance window.
#
# POST /
# Returns: record<Targets: table<WindowId: string, WindowTargetId: string, ResourceType: string, Targets: list, OwnerInformation: string, Name: string, Description: string>, NextToken: string>
# operationId: DescribeMaintenanceWindowTargets
export def "describe-maintenance-window-targets" [
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
  window_id: string # The ID of the maintenance window whose targets should be retrieved.
  --filters: list # Optional filters that can be used to narrow down the scope of the returned window targets. The supported filter keys are Type, WindowTargetId, and OwnerInformation. — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeMaintenanceWindowTargets"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowId, var: window_id}, {name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_id: $window_id, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tasks in a maintenance window. For maintenance window tasks without a specified target, you can't supply values for --max-errors and --max-concurrency. Instead, the system inserts a placeholder value of 1, which may be reported in the response to this command. These values don't affect the running of your task and can be ignored.
#
# POST /
# Returns: record<Tasks: table<WindowId: string, WindowTaskId: string, TaskArn: string, Type: string, Targets: list, TaskParameters: record, Priority: int, LoggingInfo: record, ServiceRoleArn: string, MaxConcurrency: string, MaxErrors: string, Name: string, Description: string, CutoffBehavior: string, AlarmConfiguration: record>, NextToken: string>
# operationId: DescribeMaintenanceWindowTasks
export def "describe-maintenance-window-tasks" [
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
  --x-amz-target: string@x-amz-target-completer-50 # required
  window_id: string # The ID of the maintenance window whose tasks should be retrieved.
  --filters: list # Optional filters used to narrow down the scope of the returned tasks. The supported filter keys are WindowTaskId, TaskArn, Priority, and TaskType. — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeMaintenanceWindowTasks"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowId, var: window_id}, {name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_id: $window_id, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the maintenance windows in an Amazon Web Services account.
#
# POST /
# Returns: record<WindowIdentities: table<WindowId: string, Name: string, Description: string, Enabled: bool, Duration: int, Cutoff: int, Schedule: string, ScheduleTimezone: string, ScheduleOffset: int, EndDate: string, StartDate: string, NextExecutionTime: string>, NextToken: string>
# operationId: DescribeMaintenanceWindows
export def "describe-maintenance-windows" [
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
  --x-amz-target: string@x-amz-target-completer-51 # required
  --filters: list # Optional filters used to narrow down the scope of the returned maintenance windows. Supported filter keys are Name and Enabled. For example, Name=MyMaintenanceWindow and Enabled=True. — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeMaintenanceWindows"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the maintenance window targets or tasks that a managed node is associated with.
#
# POST /
# Returns: record<WindowIdentities: table<WindowId: string, Name: string>, NextToken: string>
# operationId: DescribeMaintenanceWindowsForTarget
export def "describe-maintenance-windows-for-target" [
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
  targets: list # The managed node ID or key-value pair to retrieve information about. — item shape: {Key?: string, Values?: list<string>}
  resource_type: string@resource-type-completer-1 # The type of resource you want to retrieve information about. For example, INSTANCE.
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeMaintenanceWindowsForTarget"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Targets, var: targets}, {name: ResourceType, var: resource_type}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, targets: $targets, resource_type: $resource_type, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query a set of OpsItems. You must have permission in Identity and Access Management (IAM) to query a list of OpsItems. For more information, see Getting started with OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html) in the Amazon Web Services Systems Manager User Guide. Operations engineers and IT professionals use Amazon Web Services Systems Manager OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their Amazon Web Services resources. For more information, see OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html) in the Amazon Web Services Systems Manager User Guide.
#
# POST /
# Returns: record<NextToken: string, OpsItemSummaries: table<CreatedBy: string, CreatedTime: string, LastModifiedBy: string, LastModifiedTime: string, Priority: int, Source: string, Status: string, OpsItemId: string, Title: string, OperationalData: record, Category: string, Severity: string, OpsItemType: string, ActualStartTime: string, ActualEndTime: string, PlannedStartTime: string, PlannedEndTime: string>>
# operationId: DescribeOpsItems
export def "describe-ops-items" [
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
  --ops-item-filters: list # One or more filters to limit the response. Key: CreatedTime Operations: GreaterThan, LessThan Key: LastModifiedBy Operations: Contains, Equals Key: LastModifiedTime Operations: GreaterThan, LessThan Key: Priority Operations: Equals Key: Source Operations: Contains, Equals Key: Status Operations: Equals Key: Title* Operations: Equals,Contains Key: OperationalData** Operations: Equals Key: OperationalDataKey Operations: Equals Key: OperationalDataValue Operations: Equals, Contains Key: OpsItemId Operations: Equals Key: ResourceId Operations: Contains Key: AutomationId Operations: Equals *The Equals operator for Title matches the first 100 characters. If you specify more than 100 characters, they system returns an error that the filter value exceeds the length limit. **If you filter the response by using the OperationalData operator, specify a key-value pair by using the following JSON format: {"key":"key_name","value":"a_value"} — item shape: {Key: "Status"|"CreatedBy"|"Source"|"Priority"|"Title"|"OpsItemId"|"CreatedTime"|"LastModifiedTime"|"ActualStartTime"|"ActualEndTime"|"PlannedStartTime"|"PlannedEndTime"|"OperationalData"|"OperationalDataKey"|"OperationalDataValue"|"ResourceId"|"AutomationId"|"Category"|"Severity"|"OpsItemType"|"ChangeRequestByRequesterArn"|"ChangeRequestByRequesterName"|"ChangeRequestByApproverArn"|"ChangeRequestByApproverName"|"ChangeRequestByTemplate"|"ChangeRequestByTargetsResourceGroup"|"InsightByType"|"AccountId", ... (2 more fields)}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeOpsItems"}]
    body: {content_type: "application/json", kind: json, fields: [{name: OpsItemFilters, var: ops_item_filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ops_item_filters: $ops_item_filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about a parameter. Request results are returned on a best-effort basis. If you specify MaxResults in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of MaxResults. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a NextToken. You can specify the NextToken in a subsequent call to get the next set of results. If you change the KMS key alias for the KMS key used to encrypt a parameter, then you must also update the key alias the parameter uses to reference KMS. Otherwise, DescribeParameters retrieves whatever the original key alias was referencing.
#
# POST /
# Returns: record<Parameters: table<Name: string, Type: string, KeyId: string, LastModifiedDate: string, LastModifiedUser: string, Description: string, AllowedPattern: string, Version: int, Tier: string, Policies: list, DataType: string>, NextToken: string>
# operationId: DescribeParameters
export def "describe-parameters" [
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
  --filters: list # This data type is deprecated. Instead, use ParameterFilters. — item shape: {Key: "Name"|"Type"|"KeyId", Values: list<string>}
  --parameter-filters: list # Filters to limit the request results. — item shape: {Key: string, Option?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeParameters"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: ParameterFilters, var: parameter_filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, parameter_filters: $parameter_filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the patch baselines in your Amazon Web Services account.
#
# POST /
# Returns: record<BaselineIdentities: table<BaselineId: string, BaselineName: string, OperatingSystem: string, BaselineDescription: string, DefaultBaseline: bool>, NextToken: string>
# operationId: DescribePatchBaselines
export def "describe-patch-baselines" [
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
  --filters: list # Each element in the array is a structure containing a key-value pair. Supported keys for DescribePatchBaselines include the following: NAME_PREFIX Sample values: AWS- | My- OWNER Sample values: AWS | Self OPERATING_SYSTEM Sample values: AMAZON_LINUX | SUSE | WINDOWS — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of patch baselines to return (per page). (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribePatchBaselines"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns high-level aggregated patch compliance state information for a patch group.
#
# POST /
# Returns: record<Instances: int, InstancesWithInstalledPatches: int, InstancesWithInstalledOtherPatches: int, InstancesWithInstalledPendingRebootPatches: int, InstancesWithInstalledRejectedPatches: int, InstancesWithMissingPatches: int, InstancesWithFailedPatches: int, InstancesWithNotApplicablePatches: int, InstancesWithUnreportedNotApplicablePatches: int, InstancesWithCriticalNonCompliantPatches: int, InstancesWithSecurityNonCompliantPatches: int, InstancesWithOtherNonCompliantPatches: int>
# operationId: DescribePatchGroupState
export def "describe-patch-group-state" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  patch_group: string # The name of the patch group whose patch snapshot should be retrieved.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribePatchGroupState"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PatchGroup, var: patch_group}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, patch_group: $patch_group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all patch groups that have been registered with patch baselines.
#
# POST /
# Returns: record<Mappings: table<PatchGroup: string, BaselineIdentity: record>, NextToken: string>
# operationId: DescribePatchGroups
export def "describe-patch-groups" [
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
  --x-amz-target: string@x-amz-target-completer-57 # required
  --body-max-results: int # The maximum number of patch groups to return (per page). (spec name: MaxResults)
  --filters: list # Each element in the array is a structure containing a key-value pair. Supported keys for DescribePatchGroups include the following: NAME_PREFIX Sample values: AWS- | My-. OPERATING_SYSTEM Sample values: AMAZON_LINUX | SUSE | WINDOWS — item shape: {Key?: string, Values?: list<string>}
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribePatchGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: Filters, var: filters}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, filters: $filters, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for operations such as CreatePatchBaseline, UpdatePatchBaseline, DescribeAvailablePatches, and DescribePatchBaselines. The following section lists the properties that can be used in filters for each major operating system type: AMAZON_LINUX Valid properties: PRODUCT | CLASSIFICATION | SEVERITY AMAZON_LINUX_2 Valid properties: PRODUCT | CLASSIFICATION | SEVERITY CENTOS Valid properties: PRODUCT | CLASSIFICATION | SEVERITY DEBIAN Valid properties: PRODUCT | PRIORITY MACOS Valid properties: PRODUCT | CLASSIFICATION ORACLE_LINUX Valid properties: PRODUCT | CLASSIFICATION | SEVERITY REDHAT_ENTERPRISE_LINUX Valid properties: PRODUCT | CLASSIFICATION | SEVERITY SUSE Valid properties: PRODUCT | CLASSIFICATION | SEVERITY UBUNTU Valid properties: PRODUCT | PRIORITY WINDOWS Valid properties: PRODUCT | PRODUCT_FAMILY | CLASSIFICATION | MSRC_SEVERITY
#
# POST /
# Returns: record<Properties: list<record>, NextToken: string>
# operationId: DescribePatchProperties
export def "describe-patch-properties" [
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
  --x-amz-target: string@x-amz-target-completer-58 # required
  operating_system: string@operating-system-completer # The operating system type for which to list patches.
  property: string@property-completer # The patch property for which you want to view patch details.
  --patch-set: string@patch-set-completer # Indicates whether to list patches for the Windows operating system or for applications released by Microsoft. Not applicable for the Linux or macOS operating systems.
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribePatchProperties"}]
    body: {content_type: "application/json", kind: json, fields: [{name: OperatingSystem, var: operating_system}, {name: Property, var: property}, {name: PatchSet, var: patch_set}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, operating_system: $operating_system, property: $property, patch_set: $patch_set, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
#
# POST /
# Returns: record<Sessions: table<SessionId: string, Target: string, Status: string, StartDate: string, EndDate: string, DocumentName: string, Owner: string, Reason: string, Details: string, OutputUrl: record, MaxSessionDuration: string>, NextToken: string>
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
  state: string@state-completer # The session status to retrieve a list of sessions for. For example, "Active".
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --filters: list # One or more filters to limit the type of sessions returned by the request. — item shape: {key: "InvokedAfter"|"InvokedBefore"|"Target"|"Owner"|"Status"|"SessionId", value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DescribeSessions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: State, var: state}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, state: $state, body_max_results: $body_max_results, body_next_token: $body_next_token, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the association between an OpsItem and a related item. For example, this API operation can delete an Incident Manager incident from an OpsItem. Incident Manager is a capability of Amazon Web Services Systems Manager.
#
# POST /
# Returns: record
# operationId: DisassociateOpsItemRelatedItem
export def "disassociate-ops-item-related-item" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  ops_item_id: string # The ID of the OpsItem for which you want to delete an association between the OpsItem and a related item.
  association_id: string # The ID of the association for which you want to delete an association between the OpsItem and a related item.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.DisassociateOpsItemRelatedItem"}]
    body: {content_type: "application/json", kind: json, fields: [{name: OpsItemId, var: ops_item_id}, {name: AssociationId, var: association_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ops_item_id: $ops_item_id, association_id: $association_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detailed information about a particular Automation execution.
#
# POST /
# Returns: record<AutomationExecution: record<AutomationExecutionId: string, DocumentName: string, DocumentVersion: string, ExecutionStartTime: string, ExecutionEndTime: string, AutomationExecutionStatus: string, StepExecutions: list<record>, StepExecutionsTruncated: bool, Parameters: record, Outputs: record, FailureMessage: string, Mode: string, ParentAutomationExecutionId: string, ExecutedBy: string, CurrentStepName: string, CurrentAction: string, TargetParameterName: string, Targets: list<record>, TargetMaps: list<record>, ResolvedTargets: record<ParameterValues: list, Truncated: bool>, MaxConcurrency: string, MaxErrors: string, Target: string, TargetLocations: list<record>, ProgressCounters: record<TotalSteps: int, SuccessSteps: int, FailedSteps: int, CancelledSteps: int, TimedOutSteps: int>, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>, AutomationSubtype: string, ScheduledTime: string, Runbooks: list<record>, OpsItemId: string, AssociationId: string, ChangeRequestName: string>>
# operationId: GetAutomationExecution
export def "get-automation-execution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  automation_execution_id: string # The unique identifier for an existing automation execution to examine. The execution ID is returned by StartAutomationExecution when the execution of an Automation runbook is initiated.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetAutomationExecution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AutomationExecutionId, var: automation_execution_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, automation_execution_id: $automation_execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the state of a Amazon Web Services Systems Manager change calendar at the current time or a specified time. If you specify a time, GetCalendarState returns the state of the calendar at that specific time, and returns the next time that the change calendar state will transition. If you don't specify a time, GetCalendarState uses the current time. Change Calendar entries have two possible states: OPEN or CLOSED. If you specify more than one calendar in a request, the command returns the status of OPEN only if all calendars in the request are open. If one or more calendars in the request are closed, the status returned is CLOSED. For more information about Change Calendar, a capability of Amazon Web Services Systems Manager, see Amazon Web Services Systems Manager Change Calendar (https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar.html) in the Amazon Web Services Systems Manager User Guide.
#
# POST /
# Returns: record<State: string, AtTime: string, NextTransitionTime: string>
# operationId: GetCalendarState
export def "get-calendar-state" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  calendar_names: list<string> # The names or Amazon Resource Names (ARNs) of the Systems Manager documents (SSM documents) that represent the calendar entries for which you want to get the state.
  --at-time: string # (Optional) The specific time for which you want to get calendar state information, in ISO 8601 (https://en.wikipedia.org/wiki/ISO_8601) format. If you don't specify a value or AtTime, the current time is used.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetCalendarState"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CalendarNames, var: calendar_names}, {name: AtTime, var: at_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, calendar_names: $calendar_names, at_time: $at_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns detailed information about command execution for an invocation or plugin. GetCommandInvocation only gives the execution status of a plugin in a document. To get the command execution status on a specific managed node, use ListCommandInvocations. To get the command execution status across managed nodes, use ListCommands.
#
# POST /
# Returns: record<CommandId: string, InstanceId: string, Comment: string, DocumentName: string, DocumentVersion: string, PluginName: string, ResponseCode: int, ExecutionStartDateTime: string, ExecutionElapsedTime: string, ExecutionEndDateTime: string, Status: string, StatusDetails: string, StandardOutputContent: string, StandardOutputUrl: string, StandardErrorContent: string, StandardErrorUrl: string, CloudWatchOutputConfig: record<CloudWatchLogGroupName: string, CloudWatchOutputEnabled: bool>>
# operationId: GetCommandInvocation
export def "get-command-invocation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  command_id: string # (Required) The parent command ID of the invocation plugin.
  instance_id: string # (Required) The ID of the managed node targeted by the command. A managed node can be an Amazon Elastic Compute Cloud (Amazon EC2) instance, edge device, and on-premises server or VM in your hybrid environment that is configured for Amazon Web Services Systems Manager.
  --plugin-name: string # The name of the step for which you want detailed results. If the document contains only one step, you can omit the name and details for that step. If the document contains more than one step, you must specify the name of the step for which you want to view details. Be sure to specify the name of the step, not the name of a plugin like aws:RunShellScript. To find the PluginName, check the document content and find the name of the step you want details for. Alternatively, use ListCommandInvocations with the CommandId and Details parameters. The PluginName is the Name attribute of the CommandPlugin object in the CommandPlugins list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetCommandInvocation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CommandId, var: command_id}, {name: InstanceId, var: instance_id}, {name: PluginName, var: plugin_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, command_id: $command_id, instance_id: $instance_id, plugin_name: $plugin_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the Session Manager connection status for a managed node to determine whether it is running and ready to receive Session Manager connections.
#
# POST /
# Returns: record<Target: string, Status: string>
# operationId: GetConnectionStatus
export def "get-connection-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  target: string # The managed node ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetConnectionStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the default patch baseline. Amazon Web Services Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system. If you don't specify an operating system value, the default patch baseline for Windows is returned.
#
# POST /
# Returns: record<BaselineId: string, OperatingSystem: string>
# operationId: GetDefaultPatchBaseline
export def "get-default-patch-baseline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --operating-system: string@operating-system-completer # Returns the default patch baseline for the specified operating system.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetDefaultPatchBaseline"}]
    body: {content_type: "application/json", kind: json, fields: [{name: OperatingSystem, var: operating_system}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, operating_system: $operating_system
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the current snapshot for the patch baseline the managed node uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document (SSM document). If you run the command locally, such as with the Command Line Interface (CLI), the system attempts to use your local Amazon Web Services credentials and the operation fails. To avoid this, you can run the command in the Amazon Web Services Systems Manager console. Use Run Command, a capability of Amazon Web Services Systems Manager, with an SSM document that enables you to target a managed node with a script or command. For example, run the command using the AWS-RunShellScript document or the AWS-RunPowerShellScript document.
#
# POST /
# Returns: record<InstanceId: string, SnapshotId: string, SnapshotDownloadUrl: string, Product: string>
# operationId: GetDeployablePatchSnapshotForInstance
export def "get-deployable-patch-snapshot-for-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_id: string # The ID of the managed node for which the appropriate patch snapshot should be retrieved.
  snapshot_id: string # The snapshot ID provided by the user when running AWS-RunPatchBaseline.
  --baseline-override: record # Defines the basic information about a patch baseline override. — shape: {OperatingSystem?: "WINDOWS"|"AMAZON_LINUX"|"AMAZON_LINUX_2"|"AMAZON_LINUX_2022"|"UBUNTU"|"REDHAT_ENTERPRISE_LINUX"|"SUSE"|"CENTOS"|"ORACLE_LINUX"|"DEBIAN"|"MACOS"|"RASPBIAN"|"ROCKY_LINUX"|"ALMA_LINUX"|"AMAZON_LINUX_2023", GlobalFilters?: record, ApprovalRules?: record, ApprovedPatches?: list<string>, ApprovedPatchesComplianceLevel?: "CRITICAL"|"HIGH"|"MEDIUM"|"LOW"|"INFORMATIONAL"|"UNSPECIFIED", RejectedPatches?: list<string>, RejectedPatchesAction?: "ALLOW_AS_DEPENDENCY"|"BLOCK", ... (2 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetDeployablePatchSnapshotForInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: SnapshotId, var: snapshot_id}, {name: BaselineOverride, var: baseline_override}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id, snapshot_id: $snapshot_id, baseline_override: $baseline_override
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the contents of the specified Amazon Web Services Systems Manager document (SSM document).
#
# POST /
# Returns: record<Name: string, CreatedDate: string, DisplayName: string, VersionName: string, DocumentVersion: string, Status: string, StatusInformation: string, Content: string, DocumentType: string, DocumentFormat: string, Requires: table<Name: string, Version: string, RequireType: string, VersionName: string>, AttachmentsContent: table<Name: string, Size: int, Hash: string, HashType: string, Url: string>, ReviewStatus: string>
# operationId: GetDocument
export def "get-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the SSM document.
  --version-name: string # An optional field specifying the version of the artifact associated with the document. For example, "Release 12, Update 6". This value is unique across all versions of a document and can't be changed.
  --document-version: string # The document version for which you want information.
  --document-format: string@document-format-completer # Returns the document in the specified format. The document format can be either JSON or YAML. JSON is the default format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetDocument"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: VersionName, var: version_name}, {name: DocumentVersion, var: document_version}, {name: DocumentFormat, var: document_format}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, version_name: $version_name, document_version: $document_version, document_format: $document_format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query inventory information. This includes managed node status, such as Stopped or Terminated.
#
# POST /
# Returns: record<Entities: table<Id: string, Data: record>, NextToken: string>
# operationId: GetInventory
export def "get-inventory" [
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
  --x-amz-target: string@x-amz-target-completer-68 # required
  --filters: list # One or more filters. Use a filter to return a more specific list of results. — item shape: {Key: string, Values: list<string>, Type?: "Equal"|"NotEqual"|"BeginWith"|"LessThan"|"GreaterThan"|"Exists"}
  --aggregators: list # Returns counts of inventory types based on one or more expressions. For example, if you aggregate by using an expression that uses the AWS:InstanceInformation.PlatformType type, you can see a count of how many Windows and Linux managed nodes exist in your inventoried fleet. — item shape: {Expression?: string, Aggregators?: list, Groups?: list}
  --result-attributes: list # The list of inventory item types to return. — item shape: {TypeName: string}
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetInventory"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: Aggregators, var: aggregators}, {name: ResultAttributes, var: result_attributes}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, aggregators: $aggregators, result_attributes: $result_attributes, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type.
#
# POST /
# Returns: record<Schemas: table<TypeName: string, Version: string, Attributes: list, DisplayName: string>, NextToken: string>
# operationId: GetInventorySchema
export def "get-inventory-schema" [
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
  --type-name: string # The type of inventory item to return.
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --aggregator: oneof<nothing, bool> # Returns inventory schemas that support aggregation. For example, this call returns the AWS:InstanceInformation type, because it supports aggregation based on the PlatformName, PlatformType, and PlatformVersion attributes.
  --sub-type: oneof<nothing, bool> # Returns the sub-type schema for a specified inventory type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetInventorySchema"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TypeName, var: type_name}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Aggregator, var: aggregator}, {name: SubType, var: sub_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, type_name: $type_name, body_next_token: $body_next_token, body_max_results: $body_max_results, aggregator: $aggregator, sub_type: $sub_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a maintenance window.
#
# POST /
# Returns: record<WindowId: string, Name: string, Description: string, StartDate: string, EndDate: string, Schedule: string, ScheduleTimezone: string, ScheduleOffset: int, NextExecutionTime: string, Duration: int, Cutoff: int, AllowUnassociatedTargets: bool, Enabled: bool, CreatedDate: string, ModifiedDate: string>
# operationId: GetMaintenanceWindow
export def "get-maintenance-window" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  window_id: string # The ID of the maintenance window for which you want to retrieve information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetMaintenanceWindow"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowId, var: window_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_id: $window_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves details about a specific a maintenance window execution.
#
# POST /
# Returns: record<WindowExecutionId: string, TaskIds: list<string>, Status: string, StatusDetails: string, StartTime: string, EndTime: string>
# operationId: GetMaintenanceWindowExecution
export def "get-maintenance-window-execution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  window_execution_id: string # The ID of the maintenance window execution that includes the task.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetMaintenanceWindowExecution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowExecutionId, var: window_execution_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_execution_id: $window_execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details about a specific task run as part of a maintenance window execution.
#
# POST /
# Returns: record<WindowExecutionId: string, TaskExecutionId: string, TaskArn: string, ServiceRole: string, Type: string, TaskParameters: list<record>, Priority: int, MaxConcurrency: string, MaxErrors: string, Status: string, StatusDetails: string, StartTime: string, EndTime: string, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list<record>>, TriggeredAlarms: table<Name: string, State: string>>
# operationId: GetMaintenanceWindowExecutionTask
export def "get-maintenance-window-execution-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  window_execution_id: string # The ID of the maintenance window execution that includes the task.
  task_id: string # The ID of the specific task execution in the maintenance window task that should be retrieved.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetMaintenanceWindowExecutionTask"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowExecutionId, var: window_execution_id}, {name: TaskId, var: task_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_execution_id: $window_execution_id, task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a specific task running on a specific target.
#
# POST /
# Returns: record<WindowExecutionId: string, TaskExecutionId: string, InvocationId: string, ExecutionId: string, TaskType: string, Parameters: string, Status: string, StatusDetails: string, StartTime: string, EndTime: string, OwnerInformation: string, WindowTargetId: string>
# operationId: GetMaintenanceWindowExecutionTaskInvocation
export def "get-maintenance-window-execution-task-invocation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  window_execution_id: string # The ID of the maintenance window execution for which the task is a part.
  task_id: string # The ID of the specific task in the maintenance window task that should be retrieved.
  invocation_id: string # The invocation ID to retrieve.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowExecutionId, var: window_execution_id}, {name: TaskId, var: task_id}, {name: InvocationId, var: invocation_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_execution_id: $window_execution_id, task_id: $task_id, invocation_id: $invocation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details of a maintenance window task. For maintenance window tasks without a specified target, you can't supply values for --max-errors and --max-concurrency. Instead, the system inserts a placeholder value of 1, which may be reported in the response to this command. These values don't affect the running of your task and can be ignored. To retrieve a list of tasks in a maintenance window, instead use the DescribeMaintenanceWindowTasks command.
#
# POST /
# Returns: record<WindowId: string, WindowTaskId: string, Targets: table<Key: string, Values: list>, TaskArn: string, ServiceRoleArn: string, TaskType: string, TaskParameters: record, TaskInvocationParameters: record<RunCommand: record<Comment: string, CloudWatchOutputConfig: record, DocumentHash: string, DocumentHashType: string, DocumentVersion: string, NotificationConfig: record, OutputS3BucketName: string, OutputS3KeyPrefix: string, Parameters: record, ServiceRoleArn: string, TimeoutSeconds: int>, Automation: record<DocumentVersion: string, Parameters: record>, StepFunctions: record<Input: string, Name: string>, Lambda: record<ClientContext: string, Qualifier: string, Payload: string>>, Priority: int, MaxConcurrency: string, MaxErrors: string, LoggingInfo: record<S3BucketName: string, S3KeyPrefix: string, S3Region: string>, Name: string, Description: string, CutoffBehavior: string, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list<record>>>
# operationId: GetMaintenanceWindowTask
export def "get-maintenance-window-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  window_id: string # The maintenance window ID that includes the task to retrieve.
  window_task_id: string # The maintenance window task ID to retrieve.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetMaintenanceWindowTask"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowId, var: window_id}, {name: WindowTaskId, var: window_task_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_id: $window_id, window_task_id: $window_task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about an OpsItem by using the ID. You must have permission in Identity and Access Management (IAM) to view information about an OpsItem. For more information, see Getting started with OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html) in the Amazon Web Services Systems Manager User Guide. Operations engineers and IT professionals use Amazon Web Services Systems Manager OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their Amazon Web Services resources. For more information, see OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html) in the Amazon Web Services Systems Manager User Guide.
#
# POST /
# Returns: record<OpsItem: record<CreatedBy: string, OpsItemType: string, CreatedTime: string, Description: string, LastModifiedBy: string, LastModifiedTime: string, Notifications: list<record>, Priority: int, RelatedOpsItems: list<record>, Status: string, OpsItemId: string, Version: string, Title: string, Source: string, OperationalData: record, Category: string, Severity: string, ActualStartTime: string, ActualEndTime: string, PlannedStartTime: string, PlannedEndTime: string, OpsItemArn: string>>
# operationId: GetOpsItem
export def "get-ops-item" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  ops_item_id: string # The ID of the OpsItem that you want to get.
  --ops-item-arn: string # The OpsItem Amazon Resource Name (ARN).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetOpsItem"}]
    body: {content_type: "application/json", kind: json, fields: [{name: OpsItemId, var: ops_item_id}, {name: OpsItemArn, var: ops_item_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ops_item_id: $ops_item_id, ops_item_arn: $ops_item_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View operational metadata related to an application in Application Manager.
#
# POST /
# Returns: record<ResourceId: string, Metadata: record, NextToken: string>
# operationId: GetOpsMetadata
export def "get-ops-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  ops_metadata_arn: string # The Amazon Resource Name (ARN) of an OpsMetadata Object to view.
  --max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  --next-token: string # A token to start the list. Use this token to get the next set of results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetOpsMetadata"}]
    body: {content_type: "application/json", kind: json, fields: [{name: OpsMetadataArn, var: ops_metadata_arn}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ops_metadata_arn: $ops_metadata_arn, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a summary of operations metadata (OpsData) based on specified filters and aggregators. OpsData can include information about Amazon Web Services Systems Manager OpsCenter operational workitems (OpsItems) as well as information about any Amazon Web Services resource or service configured to report OpsData to Amazon Web Services Systems Manager Explorer.
#
# POST /
# Returns: record<Entities: table<Id: string, Data: record>, NextToken: string>
# operationId: GetOpsSummary
export def "get-ops-summary" [
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
  --x-amz-target: string@x-amz-target-completer-77 # required
  --sync-name: string # Specify the name of a resource data sync to get.
  --filters: list # Optional filters used to scope down the returned OpsData. — item shape: {Key: string, Values: list<string>, Type?: "Equal"|"NotEqual"|"BeginWith"|"LessThan"|"GreaterThan"|"Exists"}
  --aggregators: list # Optional aggregators that return counts of OpsData based on one or more expressions. — item shape: {AggregatorType?: string, TypeName?: string, AttributeName?: string, Values?: record, Filters?: list, Aggregators?: list}
  --result-attributes: list # The OpsData data type to return. — item shape: {TypeName: string}
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetOpsSummary"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SyncName, var: sync_name}, {name: Filters, var: filters}, {name: Aggregators, var: aggregators}, {name: ResultAttributes, var: result_attributes}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, sync_name: $sync_name, filters: $filters, aggregators: $aggregators, result_attributes: $result_attributes, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about a single parameter by specifying the parameter name. To get information about more than one parameter at a time, use the GetParameters operation.
#
# POST /
# Returns: record<Parameter: record<Name: string, Type: string, Value: string, Version: int, Selector: string, SourceResult: string, LastModifiedDate: string, ARN: string, DataType: string>>
# operationId: GetParameter
export def "get-parameter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the parameter you want to query. To query by parameter label, use "Name": "name:label". To query by parameter version, use "Name": "name:version".
  --with-decryption: oneof<nothing, bool> # Return decrypted values for secure string parameters. This flag is ignored for String and StringList parameter types.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetParameter"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: WithDecryption, var: with_decryption}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, with_decryption: $with_decryption
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the history of all changes to a parameter. If you change the KMS key alias for the KMS key used to encrypt a parameter, then you must also update the key alias the parameter uses to reference KMS. Otherwise, GetParameterHistory retrieves whatever the original key alias was referencing.
#
# POST /
# Returns: record<Parameters: table<Name: string, Type: string, KeyId: string, LastModifiedDate: string, LastModifiedUser: string, Description: string, Value: string, AllowedPattern: string, Version: int, Labels: list, Tier: string, Policies: list, DataType: string>, NextToken: string>
# operationId: GetParameterHistory
export def "get-parameter-history" [
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
  name: string # The name of the parameter for which you want to review history.
  --with-decryption: oneof<nothing, bool> # Return decrypted values for secure string parameters. This flag is ignored for String and StringList parameter types.
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetParameterHistory"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: WithDecryption, var: with_decryption}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, with_decryption: $with_decryption, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about one or more parameters by specifying multiple parameter names. To get information about a single parameter, you can use the GetParameter operation instead.
#
# POST /
# Returns: record<Parameters: table<Name: string, Type: string, Value: string, Version: int, Selector: string, SourceResult: string, LastModifiedDate: string, ARN: string, DataType: string>, InvalidParameters: list<string>>
# operationId: GetParameters
export def "get-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  names: list<string> # Names of the parameters for which you want to query information. To query by parameter label, use "Name": "name:label". To query by parameter version, use "Name": "name:version".
  --with-decryption: oneof<nothing, bool> # Return decrypted secure string value. Return decrypted values for secure string parameters. This flag is ignored for String and StringList parameter types.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetParameters"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Names, var: names}, {name: WithDecryption, var: with_decryption}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, names: $names, with_decryption: $with_decryption
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve information about one or more parameters in a specific hierarchy. Request results are returned on a best-effort basis. If you specify MaxResults in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of MaxResults. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a NextToken. You can specify the NextToken in a subsequent call to get the next set of results.
#
# POST /
# Returns: record<Parameters: table<Name: string, Type: string, Value: string, Version: int, Selector: string, SourceResult: string, LastModifiedDate: string, ARN: string, DataType: string>, NextToken: string>
# operationId: GetParametersByPath
export def "get-parameters-by-path" [
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
  --x-amz-target: string@x-amz-target-completer-81 # required
  path: string # The hierarchy for the parameter. Hierarchies start with a forward slash (/). The hierarchy is the parameter name except the last part of the parameter. For the API call to succeed, the last part of the parameter name can't be in the path. A parameter name hierarchy can have a maximum of 15 levels. Here is an example of a hierarchy: /Finance/Prod/IAD/WinServ2016/license33
  --recursive: oneof<nothing, bool> # Retrieve all parameters within a hierarchy. If a user has access to a path, then the user can access all levels of that path. For example, if a user has permission to access path /a, then the user can also access /a/b. Even if a user has explicitly been denied access in IAM for parameter /a/b, they can still call the GetParametersByPath API operation recursively for /a and view /a/b.
  --parameter-filters: list # Filters to limit the request results. The following Key values are supported for GetParametersByPath: Type, KeyId, and Label. The following Key values aren't supported for GetParametersByPath: tag, DataType, Name, Path, and Tier. — item shape: {Key: string, Option?: string, Values?: list<string>}
  --with-decryption: oneof<nothing, bool> # Retrieve all parameters in a hierarchy with their value decrypted.
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetParametersByPath"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Path, var: path}, {name: Recursive, var: recursive}, {name: ParameterFilters, var: parameter_filters}, {name: WithDecryption, var: with_decryption}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, path: $path, recursive: $recursive, parameter_filters: $parameter_filters, with_decryption: $with_decryption, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a patch baseline.
#
# POST /
# Returns: record<BaselineId: string, Name: string, OperatingSystem: string, GlobalFilters: record<PatchFilters: list<record>>, ApprovalRules: record<PatchRules: list<record>>, ApprovedPatches: list<string>, ApprovedPatchesComplianceLevel: string, ApprovedPatchesEnableNonSecurity: bool, RejectedPatches: list<string>, RejectedPatchesAction: string, PatchGroups: list<string>, CreatedDate: string, ModifiedDate: string, Description: string, Sources: table<Name: string, Products: list, Configuration: string>>
# operationId: GetPatchBaseline
export def "get-patch-baseline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  baseline_id: string # The ID of the patch baseline to retrieve. To retrieve information about an Amazon Web Services managed patch baseline, specify the full Amazon Resource Name (ARN) of the baseline. For example, for the baseline AWS-AmazonLinuxDefaultPatchBaseline, specify arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0e392de35e7c563b7 instead of pb-0e392de35e7c563b7.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetPatchBaseline"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BaselineId, var: baseline_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, baseline_id: $baseline_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the patch baseline that should be used for the specified patch group.
#
# POST /
# Returns: record<BaselineId: string, PatchGroup: string, OperatingSystem: string>
# operationId: GetPatchBaselineForPatchGroup
export def "get-patch-baseline-for-patch-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  patch_group: string # The name of the patch group whose patch baseline should be retrieved.
  --operating-system: string@operating-system-completer # Returns the operating system rule specified for patch groups using the patch baseline.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetPatchBaselineForPatchGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PatchGroup, var: patch_group}, {name: OperatingSystem, var: operating_system}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, patch_group: $patch_group, operating_system: $operating_system
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of the Policy object.
#
# POST /
# Returns: record<NextToken: string, Policies: table<PolicyId: string, PolicyHash: string, Policy: string>>
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
  --x-amz-target: string@x-amz-target-completer-84 # required
  resource_arn: string # Amazon Resource Name (ARN) of the resource to which the policies are attached.
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetResourcePolicies"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ServiceSetting is an account-level setting for an Amazon Web Services service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an Amazon Web Services service charges money to the account based on feature or service usage, then the Amazon Web Services service team might create a default setting of false. This means the user can't use this feature unless they change the setting to true and intentionally opt in for a paid feature. Services map a SettingId object to a setting value. Amazon Web Services services teams define the default value for a SettingId. You can't create a new SettingId, but you can overwrite the default value if you have the ssm:UpdateServiceSetting permission for the setting. Use the UpdateServiceSetting API operation to change the default setting. Or use the ResetServiceSetting to change the value back to the original value defined by the Amazon Web Services service team. Query the current service setting for the Amazon Web Services account.
#
# POST /
# Returns: record<ServiceSetting: record<SettingId: string, SettingValue: string, LastModifiedDate: string, LastModifiedUser: string, ARN: string, Status: string>>
# operationId: GetServiceSetting
export def "get-service-setting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  setting_id: string # The ID of the service setting to get. The setting ID can be one of the following. /ssm/managed-instance/default-ec2-instance-management-role /ssm/automation/customer-script-log-destination /ssm/automation/customer-script-log-group-name /ssm/documents/console/public-sharing-permission /ssm/managed-instance/activation-tier /ssm/opsinsights/opscenter /ssm/parameter-store/default-parameter-tier /ssm/parameter-store/high-throughput-enabled
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.GetServiceSetting"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SettingId, var: setting_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, setting_id: $setting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Amazon Web Services Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. Parameter labels have the following requirements and restrictions. A version of a parameter can have a maximum of 10 labels. You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2. You can move a label from one version of a parameter to another. You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter. If you no longer want to use a parameter label, then you can either delete it or move it to a different version of a parameter. A label can have a maximum of 100 characters. Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_). Labels can't begin with a number, "aws" or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label isn't associated with a parameter and the system displays it in the list of InvalidLabels.
#
# POST /
# Returns: record<InvalidLabels: list<string>, ParameterVersion: int>
# operationId: LabelParameterVersion
export def "label-parameter-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The parameter name on which you want to attach one or more labels.
  --parameter-version: int # The specific version of the parameter on which you want to attach one or more labels. If no version is specified, the system attaches the label to the latest version.
  labels: list<string> # One or more labels to attach to the specified parameter version.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.LabelParameterVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: ParameterVersion, var: parameter_version}, {name: Labels, var: labels}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, parameter_version: $parameter_version, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all versions of an association for a specific association ID.
#
# POST /
# Returns: record<AssociationVersions: table<AssociationId: string, AssociationVersion: string, CreatedDate: string, Name: string, DocumentVersion: string, Parameters: record, Targets: list, ScheduleExpression: string, OutputLocation: record, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list, TargetLocations: list, ScheduleOffset: int, TargetMaps: list>, NextToken: string>
# operationId: ListAssociationVersions
export def "list-association-versions" [
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
  association_id: string # The association ID for which you want to view all versions.
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ListAssociationVersions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AssociationId, var: association_id}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, association_id: $association_id, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all State Manager associations in the current Amazon Web Services account and Amazon Web Services Region. You can limit the results to a specific State Manager association document or managed node by specifying a filter. State Manager is a capability of Amazon Web Services Systems Manager.
#
# POST /
# Returns: record<Associations: table<Name: string, InstanceId: string, AssociationId: string, AssociationVersion: string, DocumentVersion: string, Targets: list, LastExecutionDate: string, Overview: record, ScheduleExpression: string, AssociationName: string, ScheduleOffset: int, TargetMaps: list>, NextToken: string>
# operationId: ListAssociations
export def "list-associations" [
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
  --x-amz-target: string@x-amz-target-completer-88 # required
  --association-filter-list: list # One or more filters. Use a filter to return a more specific list of results. Filtering associations using the InstanceID attribute only returns legacy associations created using the InstanceID attribute. Associations targeting the managed node that are part of the Target Attributes ResourceGroup or Tags aren't returned. — item shape: {key: "InstanceId"|"Name"|"AssociationId"|"AssociationStatusName"|"LastExecutedBefore"|"LastExecutedAfter"|"AssociationName"|"ResourceGroupName", value: string}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ListAssociations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AssociationFilterList, var: association_filter_list}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, association_filter_list: $association_filter_list, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# An invocation is copy of a command sent to a specific managed node. A command can apply to one or more managed nodes. A command invocation applies to one managed node. For example, if a user runs SendCommand against three managed nodes, then a command invocation is created for each requested managed node ID. ListCommandInvocations provide status about command execution.
#
# POST /
# Returns: record<CommandInvocations: table<CommandId: string, InstanceId: string, InstanceName: string, Comment: string, DocumentName: string, DocumentVersion: string, RequestedDateTime: string, Status: string, StatusDetails: string, TraceOutput: string, StandardOutputUrl: string, StandardErrorUrl: string, CommandPlugins: list, ServiceRole: string, NotificationConfig: record, CloudWatchOutputConfig: record>, NextToken: string>
# operationId: ListCommandInvocations
export def "list-command-invocations" [
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
  --x-amz-target: string@x-amz-target-completer-89 # required
  --command-id: string # (Optional) The invocations for a specific command ID.
  --instance-id: string # (Optional) The command execution details for a specific managed node ID.
  --body-max-results: int # (Optional) The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # (Optional) The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --filters: list # (Optional) One or more filters. Use a filter to return a more specific list of results. — item shape: {key: "InvokedAfter"|"InvokedBefore"|"Status"|"ExecutionStage"|"DocumentName", value: string}
  --details: oneof<nothing, bool> # (Optional) If set this returns the response of the command executions and any command output. The default value is false.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ListCommandInvocations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CommandId, var: command_id}, {name: InstanceId, var: instance_id}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}, {name: Filters, var: filters}, {name: Details, var: details}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, command_id: $command_id, instance_id: $instance_id, body_max_results: $body_max_results, body_next_token: $body_next_token, filters: $filters, details: $details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the commands requested by users of the Amazon Web Services account.
#
# POST /
# Returns: record<Commands: table<CommandId: string, DocumentName: string, DocumentVersion: string, Comment: string, ExpiresAfter: string, Parameters: record, InstanceIds: list, Targets: list, RequestedDateTime: string, Status: string, StatusDetails: string, OutputS3Region: string, OutputS3BucketName: string, OutputS3KeyPrefix: string, MaxConcurrency: string, MaxErrors: string, TargetCount: int, CompletedCount: int, ErrorCount: int, DeliveryTimedOutCount: int, ServiceRole: string, NotificationConfig: record, CloudWatchOutputConfig: record, TimeoutSeconds: int, AlarmConfiguration: record, TriggeredAlarms: list>, NextToken: string>
# operationId: ListCommands
export def "list-commands" [
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
  --command-id: string # (Optional) If provided, lists only the specified command.
  --instance-id: string # (Optional) Lists commands issued against this managed node ID. You can't specify a managed node ID in the same command that you specify Status = Pending. This is because the command hasn't reached the managed node yet.
  --body-max-results: int # (Optional) The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # (Optional) The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --filters: list # (Optional) One or more filters. Use a filter to return a more specific list of results. — item shape: {key: "InvokedAfter"|"InvokedBefore"|"Status"|"ExecutionStage"|"DocumentName", value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ListCommands"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CommandId, var: command_id}, {name: InstanceId, var: instance_id}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, command_id: $command_id, instance_id: $instance_id, body_max_results: $body_max_results, body_next_token: $body_next_token, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For a specified resource ID, this API operation returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter.
#
# POST /
# Returns: record<ComplianceItems: table<ComplianceType: string, ResourceType: string, ResourceId: string, Id: string, Title: string, Status: string, Severity: string, ExecutionSummary: record, Details: record>, NextToken: string>
# operationId: ListComplianceItems
export def "list-compliance-items" [
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
  --x-amz-target: string@x-amz-target-completer-91 # required
  --filters: list # One or more compliance filters. Use a filter to return a more specific list of results. — item shape: {Key?: string, Values?: list<string>, Type?: "EQUAL"|"NOT_EQUAL"|"BEGIN_WITH"|"LESS_THAN"|"GREATER_THAN"}
  --resource-ids: list<string> # The ID for the resources from which to get compliance information. Currently, you can only specify one resource ID.
  --resource-types: list<string> # The type of resource from which to get compliance information. Currently, the only supported resource type is ManagedInstance.
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ListComplianceItems"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: ResourceIds, var: resource_ids}, {name: ResourceTypes, var: resource_types}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, resource_ids: $resource_ids, resource_types: $resource_types, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify.
#
# POST /
# Returns: record<ComplianceSummaryItems: table<ComplianceType: string, CompliantSummary: record, NonCompliantSummary: record>, NextToken: string>
# operationId: ListComplianceSummaries
export def "list-compliance-summaries" [
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
  --x-amz-target: string@x-amz-target-completer-92 # required
  --filters: list # One or more compliance or inventory filters. Use a filter to return a more specific list of results. — item shape: {Key?: string, Values?: list<string>, Type?: "EQUAL"|"NOT_EQUAL"|"BEGIN_WITH"|"LESS_THAN"|"GREATER_THAN"}
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. Currently, you can specify null or 50. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ListComplianceSummaries"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information about approval reviews for a version of a change template in Change Manager.
#
# POST /
# Returns: record<Name: string, DocumentVersion: string, Author: string, Metadata: record<ReviewerResponse: list<record>>, NextToken: string>
# operationId: ListDocumentMetadataHistory
export def "list-document-metadata-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the change template.
  --document-version: string # The version of the change template.
  metadata: string@metadata-completer # The type of data for which details are being requested. Currently, the only supported value is DocumentReviews.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ListDocumentMetadataHistory"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: DocumentVersion, var: document_version}, {name: Metadata, var: metadata}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, document_version: $document_version, metadata: $metadata, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all versions for a document.
#
# POST /
# Returns: record<DocumentVersions: table<Name: string, DisplayName: string, DocumentVersion: string, VersionName: string, CreatedDate: string, IsDefaultVersion: bool, DocumentFormat: string, Status: string, StatusInformation: string, ReviewStatus: string>, NextToken: string>
# operationId: ListDocumentVersions
export def "list-document-versions" [
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
  name: string # The name of the document. You can specify an Amazon Resource Name (ARN).
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ListDocumentVersions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all Systems Manager (SSM) documents in the current Amazon Web Services account and Amazon Web Services Region. You can limit the results of this request by using a filter.
#
# POST /
# Returns: record<DocumentIdentifiers: table<Name: string, CreatedDate: string, DisplayName: string, Owner: string, VersionName: string, PlatformTypes: list, DocumentVersion: string, DocumentType: string, SchemaVersion: string, DocumentFormat: string, TargetType: string, Tags: list, Requires: list, ReviewStatus: string, Author: string>, NextToken: string>
# operationId: ListDocuments
export def "list-documents" [
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
  --document-filter-list: list # This data type is deprecated. Instead, use Filters. — item shape: {key: "Name"|"Owner"|"PlatformTypes"|"DocumentType", value: string}
  --filters: list # One or more DocumentKeyValuesFilter objects. Use a filter to return a more specific list of results. For keys, you can specify one or more key-value pair tags that have been applied to a document. Other valid keys include Owner, Name, PlatformTypes, DocumentType, and TargetType. For example, to return documents you own use Key=Owner,Values=Self. To specify a custom key-value pair, use the format Key=tag:tagName,Values=valueName. This API operation only supports filtering documents by using a single tag key and one or more tag values. For example: Key=tag:tagName,Values=valueName1,valueName2 — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ListDocuments"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DocumentFilterList, var: document_filter_list}, {name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, document_filter_list: $document_filter_list, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A list of inventory items returned by the request.
#
# POST /
# Returns: record<TypeName: string, InstanceId: string, SchemaVersion: string, CaptureTime: string, Entries: list<record>, NextToken: string>
# operationId: ListInventoryEntries
export def "list-inventory-entries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_id: string # The managed node ID for which you want inventory information.
  type_name: string # The type of inventory item for which you want information.
  --filters: list # One or more filters. Use a filter to return a more specific list of results. — item shape: {Key: string, Values: list<string>, Type?: "Equal"|"NotEqual"|"BeginWith"|"LessThan"|"GreaterThan"|"Exists"}
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ListInventoryEntries"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: TypeName, var: type_name}, {name: Filters, var: filters}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id, type_name: $type_name, filters: $filters, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all OpsItem events in the current Amazon Web Services Region and Amazon Web Services account. You can limit the results to events associated with specific OpsItems by specifying a filter.
#
# POST /
# Returns: record<NextToken: string, Summaries: table<OpsItemId: string, EventId: string, Source: string, DetailType: string, Detail: string, CreatedBy: record, CreatedTime: string>>
# operationId: ListOpsItemEvents
export def "list-ops-item-events" [
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
  --filters: list # One or more OpsItem filters. Use a filter to return a more specific list of results. — item shape: {Key: "OpsItemId", Values: list<string>, Operator: "Equal"}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ListOpsItemEvents"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all related-item resources associated with a Systems Manager OpsCenter OpsItem. OpsCenter is a capability of Amazon Web Services Systems Manager.
#
# POST /
# Returns: record<NextToken: string, Summaries: table<OpsItemId: string, AssociationId: string, ResourceType: string, AssociationType: string, ResourceUri: string, CreatedBy: record, CreatedTime: string, LastModifiedBy: record, LastModifiedTime: string>>
# operationId: ListOpsItemRelatedItems
export def "list-ops-item-related-items" [
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
  --x-amz-target: string@x-amz-target-completer-98 # required
  --ops-item-id: string # The ID of the OpsItem for which you want to list all related-item resources.
  --filters: list # One or more OpsItem filters. Use a filter to return a more specific list of results. — item shape: {Key: "ResourceType"|"AssociationId"|"ResourceUri", Values: list<string>, Operator: "Equal"}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ListOpsItemRelatedItems"}]
    body: {content_type: "application/json", kind: json, fields: [{name: OpsItemId, var: ops_item_id}, {name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ops_item_id: $ops_item_id, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Amazon Web Services Systems Manager calls this API operation when displaying all Application Manager OpsMetadata objects or blobs.
#
# POST /
# Returns: record<OpsMetadataList: table<ResourceId: string, OpsMetadataArn: string, LastModifiedDate: string, LastModifiedUser: string, CreationDate: string>, NextToken: string>
# operationId: ListOpsMetadata
export def "list-ops-metadata" [
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
  --filters: list # One or more filters to limit the number of OpsMetadata objects returned by the call. — item shape: {Key: string, Values: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ListOpsMetadata"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
#
# POST /
# Returns: record<ResourceComplianceSummaryItems: table<ComplianceType: string, ResourceType: string, ResourceId: string, Status: string, OverallSeverity: string, ExecutionSummary: record, CompliantSummary: record, NonCompliantSummary: record>, NextToken: string>
# operationId: ListResourceComplianceSummaries
export def "list-resource-compliance-summaries" [
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
  --x-amz-target: string@x-amz-target-completer-100 # required
  --filters: list # One or more filters. Use a filter to return a more specific list of results. — item shape: {Key?: string, Values?: list<string>, Type?: "EQUAL"|"NOT_EQUAL"|"BEGIN_WITH"|"LESS_THAN"|"GREATER_THAN"}
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ListResourceComplianceSummaries"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed. The number of sync configurations might be too large to return using a single call to ListResourceDataSync. You can limit the number of sync configurations returned by using the MaxResults parameter. To determine whether there are more sync configurations to list, check the value of NextToken in the output. If there are more sync configurations to list, you can request them by specifying the NextToken returned in the call to the parameter of a subsequent call.
#
# POST /
# Returns: record<ResourceDataSyncItems: table<SyncName: string, SyncType: string, SyncSource: record, S3Destination: record, LastSyncTime: string, LastSuccessfulSyncTime: string, SyncLastModifiedTime: string, LastStatus: string, SyncCreatedTime: string, LastSyncStatusMessage: string>, NextToken: string>
# operationId: ListResourceDataSync
export def "list-resource-data-sync" [
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
  --x-amz-target: string@x-amz-target-completer-101 # required
  --sync-type: string # View a list of resource data syncs according to the sync type. Specify SyncToDestination to view resource data syncs that synchronize data to an Amazon S3 bucket. Specify SyncFromSource to view resource data syncs from Organizations or from multiple Amazon Web Services Regions.
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ListResourceDataSync"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SyncType, var: sync_type}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, sync_type: $sync_type, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the tags assigned to the specified resource. For information about the ID format for each supported resource type, see AddTagsToResource.
#
# POST /
# Returns: record<TagList: table<Key: string, Value: string>>
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
  --x-amz-target: string@x-amz-target-completer-102 # required
  resource_type: string@resource-type-completer # Returns a list of tags for a specific resource type.
  resource_id: string # The resource ID for which you want to see a list of tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceType, var: resource_type}, {name: ResourceId, var: resource_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_type: $resource_type, resource_id: $resource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shares a Amazon Web Services Systems Manager document (SSM document)publicly or privately. If you share a document privately, you must specify the Amazon Web Services user IDs for those people who can use the document. If you share a document publicly, you must specify All as the account ID.
#
# POST /
# Returns: record
# operationId: ModifyDocumentPermission
export def "modify-document-permission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-103 # required
  name: string # The name of the document that you want to share.
  permission_type: string@permission-type-completer # The permission type for the document. The permission type can be Share.
  --account-ids-to-add: list<string> # The Amazon Web Services users that should have access to the document. The account IDs can either be a group of account IDs or All.
  --account-ids-to-remove: list<string> # The Amazon Web Services users that should no longer have access to the document. The Amazon Web Services user can either be a group of account IDs or All. This action has a higher priority than AccountIdsToAdd. If you specify an ID to add and the same ID to remove, the system removes access to the document.
  --shared-document-version: string # The document version shared with other Amazon Web Services accounts. You can share Latest, Default or All versions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ModifyDocumentPermission"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: PermissionType, var: permission_type}, {name: AccountIdsToAdd, var: account_ids_to_add}, {name: AccountIdsToRemove, var: account_ids_to_remove}, {name: SharedDocumentVersion, var: shared_document_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, permission_type: $permission_type, account_ids_to_add: $account_ids_to_add, account_ids_to_remove: $account_ids_to_remove, shared_document_version: $shared_document_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a compliance type and other compliance details on a designated resource. This operation lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request. ComplianceType can be one of the following: ExecutionId: The execution ID when the patch, association, or custom compliance item was applied. ExecutionType: Specify patch, association, or Custom:string. ExecutionTime. The time the patch, association, or custom compliance item was applied to the managed node. Id: The patch, association, or custom compliance ID. Title: A title. Status: The status of the compliance item. For example, approved for patches, or Failed for associations. Severity: A patch severity. For example, Critical. DocumentName: An SSM document name. For example, AWS-RunPatchBaseline. DocumentVersion: An SSM document version number. For example, 4. Classification: A patch classification. For example, security updates. PatchBaselineId: A patch baseline ID. PatchSeverity: A patch severity. For example, Critical. PatchState: A patch state. For example, InstancesWithFailedPatches. PatchGroup: The name of a patch group. InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'
#
# POST /
# Returns: record
# operationId: PutComplianceItems
export def "put-compliance-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_id: string # Specify an ID for this resource. For a managed node, this is the node ID.
  resource_type: string # Specify the type of resource. ManagedInstance is currently the only supported resource type.
  compliance_type: string # Specify the compliance type. For example, specify Association (for a State Manager association), Patch, or Custom:string.
  execution_summary: record # A summary of the call execution that includes an execution ID, the type of execution (for example, Command), and the date/time of the execution using a datetime object that is saved in the following format: yyyy-MM-dd'T'HH:mm:ss'Z'. — shape: {ExecutionTime: string, ExecutionId?: string, ExecutionType?: string}
  items: list # Information about the compliance as defined by the resource type. For example, for a patch compliance type, Items includes information about the PatchSeverity, Classification, and so on. — item shape: {Id?: string, Title?: string, Severity: "CRITICAL"|"HIGH"|"MEDIUM"|"LOW"|"INFORMATIONAL"|"UNSPECIFIED", Status: "COMPLIANT"|"NON_COMPLIANT", Details?: record}
  --item-content-hash: string # MD5 or SHA-256 content hash. The content hash is used to determine if existing information should be overwritten or ignored. If the content hashes match, the request to put compliance information is ignored.
  --upload-type: string@upload-type-completer # The mode for uploading compliance items. You can specify COMPLETE or PARTIAL. In COMPLETE mode, the system overwrites all existing compliance information for the resource. You must provide a full list of compliance items each time you send the request. In PARTIAL mode, the system overwrites compliance information for a specific association. The association must be configured with SyncCompliance set to MANUAL. By default, all requests use COMPLETE mode. This attribute is only valid for association compliance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.PutComplianceItems"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}, {name: ResourceType, var: resource_type}, {name: ComplianceType, var: compliance_type}, {name: ExecutionSummary, var: execution_summary}, {name: Items, var: items}, {name: ItemContentHash, var: item_content_hash}, {name: UploadType, var: upload_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id, resource_type: $resource_type, compliance_type: $compliance_type, execution_summary: $execution_summary, items: $items, item_content_hash: $item_content_hash, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk update custom inventory items on one or more managed nodes. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
#
# POST /
# Returns: record<Message: string>
# operationId: PutInventory
export def "put-inventory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_id: string # An managed node ID where you want to add or update inventory items.
  items: list # The inventory items that you want to add or update on managed nodes. — item shape: {TypeName: string, SchemaVersion: string, CaptureTime: string, ContentHash?: string, Content?: list, Context?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.PutInventory"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: Items, var: items}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a parameter to the system.
#
# POST /
# Returns: record<Version: int, Tier: string>
# operationId: PutParameter
export def "put-parameter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-106 # required
  name: string # The fully qualified name of the parameter that you want to add to the system. The fully qualified name includes the complete hierarchy of the parameter path and name. For parameters in a hierarchy, you must include a leading forward slash character (/) when you create or reference a parameter. For example: /Dev/DBServer/MySQL/db-string13 Naming Constraints: Parameter names are case sensitive. A parameter name must be unique within an Amazon Web Services Region A parameter name can't be prefixed with "aws" or "ssm" (case-insensitive). Parameter names can include only the following symbols and letters: a-zA-Z0-9_.- In addition, the slash character ( / ) is used to delineate hierarchies in parameter names. For example: /Dev/Production/East/Project-ABC/MyParameter A parameter name can't include spaces. Parameter hierarchies are limited to a maximum depth of fifteen levels. For additional information about valid values for parameter names, see Creating Systems Manager parameters (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-su-create.html) in the Amazon Web Services Systems Manager User Guide. The maximum length constraint of 2048 characters listed below includes 1037 characters reserved for internal use by Systems Manager. The maximum length for a parameter name that you create is 1011 characters. This includes the characters in the ARN that precede the name you specify, such as arn:aws:ssm:us-east-2:111122223333:parameter/.
  --description: string # Information about the parameter that you want to add to the system. Optional but recommended. Don't enter personally identifiable information in this field.
  value: string # The parameter value that you want to add to the system. Standard parameters have a value limit of 4 KB. Advanced parameters have a value limit of 8 KB. Parameters can't be referenced or nested in the values of other parameters. You can't include {{}} or {{ssm:parameter-name}} in a parameter value. (format: password)
  --type: string@type-completer # The type of parameter that you want to add to the system. SecureString isn't currently supported for CloudFormation templates. Items in a StringList must be separated by a comma (,). You can't use other punctuation or special character to escape items in the list. If you have a parameter value that requires a comma, then use the String data type. Specifying a parameter type isn't required when updating a parameter. You must specify a parameter type when creating a parameter.
  --key-id: string # The Key Management Service (KMS) ID that you want to use to encrypt a parameter. Use a custom key for better security. Required for parameters that use the SecureString data type. If you don't specify a key ID, the system uses the default key associated with your Amazon Web Services account which is not as secure as using a custom key. To use a custom KMS key, choose the SecureString data type with the Key ID parameter.
  --overwrite: oneof<nothing, bool> # Overwrite an existing parameter. The default value is false.
  --allowed-pattern: string # A regular expression used to validate the parameter value. For example, for String types with values restricted to numbers, you can specify the following: AllowedPattern=^\d+$
  --tags: list # Optional metadata that you assign to a resource. Tags enable you to categorize a resource in different ways, such as by purpose, owner, or environment. For example, you might want to tag a Systems Manager parameter to identify the type of resource to which it applies, the environment, or the type of configuration data referenced by the parameter. In this case, you could specify the following key-value pairs: Key=Resource,Value=S3bucket Key=OS,Value=Windows Key=ParameterType,Value=LicenseKey To add tags to an existing Systems Manager parameter, use the AddTagsToResource operation. — item shape: {Key: string, Value: string}
  --tier: string@tier-completer # The parameter tier to assign to a parameter. Parameter Store offers a standard tier and an advanced tier for parameters. Standard parameters have a content size limit of 4 KB and can't be configured to use parameter policies. You can create a maximum of 10,000 standard parameters for each Region in an Amazon Web Services account. Standard parameters are offered at no additional cost. Advanced parameters have a content size limit of 8 KB and can be configured to use parameter policies. You can create a maximum of 100,000 advanced parameters for each Region in an Amazon Web Services account. Advanced parameters incur a charge. For more information, see Standard and advanced parameter tiers (https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-advanced-parameters.html) in the Amazon Web Services Systems Manager User Guide. You can change a standard parameter to an advanced parameter any time. But you can't revert an advanced parameter to a standard parameter. Reverting an advanced parameter to a standard parameter would result in data loss because the system would truncate the size of the parameter from 8 KB to 4 KB. Reverting would also remove any policies attached to the parameter. Lastly, advanced parameters use a different form of encryption than standard parameters. If you no longer need an advanced parameter, or if you no longer want to incur charges for an advanced parameter, you must delete it and recreate it as a new standard parameter. Using the Default Tier Configuration In PutParameter requests, you can specify the tier to create the parameter in. Whenever you specify a tier in the request, Parameter Store creates or updates the parameter according to that request. However, if you don't specify a tier in a request, Parameter Store assigns the tier based on the current Parameter Store default tier configuration. The default tier when you begin using Parameter Store is the standard-parameter tier. If you use the advanced-parameter tier, you can specify one of the following as the default: Advanced: With this option, Parameter Store evaluates all requests as advanced parameters. Intelligent-Tiering: With this option, Parameter Store evaluates each request to determine if the parameter is standard or advanced. If the request doesn't include any options that require an advanced parameter, the parameter is created in the standard-parameter tier. If one or more options requiring an advanced parameter are included in the request, Parameter Store create a parameter in the advanced-parameter tier. This approach helps control your parameter-related costs by always creating standard parameters unless an advanced parameter is necessary. Options that require an advanced parameter include the following: The content size of the parameter is more than 4 KB. The parameter uses a parameter policy. More than 10,000 parameters already exist in your Amazon Web Services account in the current Amazon Web Services Region. For more information about configuring the default tier option, see Specifying a default parameter tier (https://docs.aws.amazon.com/systems-manager/latest/userguide/ps-default-tier.html) in the Amazon Web Services Systems Manager User Guide.
  --policies: string # One or more policies to apply to a parameter. This operation takes a JSON array. Parameter Store, a capability of Amazon Web Services Systems Manager supports the following policy types: Expiration: This policy deletes the parameter after it expires. When you create the policy, you specify the expiration date. You can update the expiration date and time by updating the policy. Updating the parameter doesn't affect the expiration date and time. When the expiration time is reached, Parameter Store deletes the parameter. ExpirationNotification: This policy initiates an event in Amazon CloudWatch Events that notifies you about the expiration. By using this policy, you can receive notification before or after the expiration time is reached, in units of days or hours. NoChangeNotification: This policy initiates a CloudWatch Events event if a parameter hasn't been modified for a specified period of time. This policy type is useful when, for example, a secret needs to be changed within a period of time, but it hasn't been changed. All existing policies are preserved until you send new policies or an empty policy. For more information about parameter policies, see Assigning parameter policies (https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-policies.html).
  --data-type: string # The data type for a String parameter. Supported data types include plain text and Amazon Machine Image (AMI) IDs. The following data type values are supported. text aws:ec2:image aws:ssm:integration When you create a String parameter and specify aws:ec2:image, Amazon Web Services Systems Manager validates the parameter value is in the required format, such as ami-12345abcdeEXAMPLE, and that the specified AMI is available in your Amazon Web Services account. If the action is successful, the service sends back an HTTP 200 response which indicates a successful PutParameter call for all cases except for data type aws:ec2:image. If you call PutParameter with aws:ec2:image data type, a successful HTTP 200 response does not guarantee that your parameter was successfully created or updated. The aws:ec2:image value is validated asynchronously, and the PutParameter call returns before the validation is complete. If you submit an invalid AMI value, the PutParameter operation will return success, but the asynchronous validation will fail and the parameter will not be created or updated. To monitor whether your aws:ec2:image parameters are created successfully, see Setting up notifications or trigger actions based on Parameter Store events (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-cwe.html). For more information about AMI format validation , see Native parameter support for Amazon Machine Image (AMI) IDs (https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-ec2-aliases.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.PutParameter"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: Value, var: value}, {name: Type, var: type}, {name: KeyId, var: key_id}, {name: Overwrite, var: overwrite}, {name: AllowedPattern, var: allowed_pattern}, {name: Tags, var: tags}, {name: Tier, var: tier}, {name: Policies, var: policies}, {name: DataType, var: data_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, value: $value, type: $type, key_id: $key_id, overwrite: $overwrite, allowed_pattern: $allowed_pattern, tags: $tags, tier: $tier, policies: $policies, data_type: $data_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a Systems Manager resource policy. A resource policy helps you to define the IAM entity (for example, an Amazon Web Services account) that can manage your Systems Manager resources. Currently, OpsItemGroup is the only resource that supports Systems Manager resource policies. The resource policy for OpsItemGroup enables Amazon Web Services accounts to view and interact with OpsCenter operational work items (OpsItems).
#
# POST /
# Returns: record<PolicyId: string, PolicyHash: string>
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
  --x-amz-target: string@x-amz-target-completer-107 # required
  resource_arn: string # Amazon Resource Name (ARN) of the resource to which you want to attach a policy.
  policy: string # A policy you want to associate with a resource.
  --policy-id: string # The policy ID.
  --policy-hash: string # ID of the current policy version. The hash helps to prevent a situation where multiple users attempt to overwrite a policy. You must provide this hash when updating or deleting a policy.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.PutResourcePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: Policy, var: policy}, {name: PolicyId, var: policy_id}, {name: PolicyHash, var: policy_hash}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, policy: $policy, policy_id: $policy_id, policy_hash: $policy_hash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Defines the default patch baseline for the relevant operating system. To reset the Amazon Web Services-predefined patch baseline as the default, specify the full patch baseline Amazon Resource Name (ARN) as the baseline ID value. For example, for CentOS, specify arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed instead of pb-0574b43a65ea646ed.
#
# POST /
# Returns: record<BaselineId: string>
# operationId: RegisterDefaultPatchBaseline
export def "register-default-patch-baseline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  baseline_id: string # The ID of the patch baseline that should be the default patch baseline.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.RegisterDefaultPatchBaseline"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BaselineId, var: baseline_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, baseline_id: $baseline_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a patch baseline for a patch group.
#
# POST /
# Returns: record<BaselineId: string, PatchGroup: string>
# operationId: RegisterPatchBaselineForPatchGroup
export def "register-patch-baseline-for-patch-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  baseline_id: string # The ID of the patch baseline to register with the patch group.
  patch_group: string # The name of the patch group to be registered with the patch baseline.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.RegisterPatchBaselineForPatchGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BaselineId, var: baseline_id}, {name: PatchGroup, var: patch_group}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, baseline_id: $baseline_id, patch_group: $patch_group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a target with a maintenance window.
#
# POST /
# Returns: record<WindowTargetId: string>
# operationId: RegisterTargetWithMaintenanceWindow
export def "register-target-with-maintenance-window" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  window_id: string # The ID of the maintenance window the target should be registered with.
  resource_type: string@resource-type-completer-1 # The type of target being registered with the maintenance window.
  targets: list # The targets to register with the maintenance window. In other words, the managed nodes to run commands on when the maintenance window runs. If a single maintenance window task is registered with multiple targets, its task invocations occur sequentially and not in parallel. If your task must run on multiple targets at the same time, register a task for each target individually and assign each task the same priority level. You can specify targets using managed node IDs, resource group names, or tags that have been applied to managed nodes. Example 1: Specify managed node IDs Key=InstanceIds,Values=<instance-id-1>,<instance-id-2>,<instance-id-3> Example 2: Use tag key-pairs applied to managed nodes Key=tag:<my-tag-key>,Values=<my-tag-value-1>,<my-tag-value-2> Example 3: Use tag-keys applied to managed nodes Key=tag-key,Values=<my-tag-key-1>,<my-tag-key-2> Example 4: Use resource group names Key=resource-groups:Name,Values=<resource-group-name> Example 5: Use filters for resource group types Key=resource-groups:ResourceTypeFilters,Values=<resource-type-1>,<resource-type-2> For Key=resource-groups:ResourceTypeFilters, specify resource types in the following format Key=resource-groups:ResourceTypeFilters,Values=AWS::EC2::INSTANCE,AWS::EC2::VPC For more information about these examples formats, including the best use case for each one, see Examples: Register targets with a maintenance window (https://docs.aws.amazon.com/systems-manager/latest/userguide/mw-cli-tutorial-targets-examples.html) in the Amazon Web Services Systems Manager User Guide. — item shape: {Key?: string, Values?: list<string>}
  --owner-information: string # User-provided value that will be included in any Amazon CloudWatch Events events raised while running tasks for these targets in this maintenance window. (format: password)
  --name: string # An optional name for the target.
  --description: string # An optional description for the target. (format: password)
  --client-token: string # User-provided idempotency token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.RegisterTargetWithMaintenanceWindow"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowId, var: window_id}, {name: ResourceType, var: resource_type}, {name: Targets, var: targets}, {name: OwnerInformation, var: owner_information}, {name: Name, var: name}, {name: Description, var: description}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_id: $window_id, resource_type: $resource_type, targets: $targets, owner_information: $owner_information, name: $name, description: $description, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new task to a maintenance window.
#
# POST /
# Returns: record<WindowTaskId: string>
# operationId: RegisterTaskWithMaintenanceWindow
export def "register-task-with-maintenance-window" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  window_id: string # The ID of the maintenance window the task should be added to.
  --targets: list # The targets (either managed nodes or maintenance window targets). One or more targets must be specified for maintenance window Run Command-type tasks. Depending on the task, targets are optional for other maintenance window task types (Automation, Lambda, and Step Functions). For more information about running tasks that don't specify targets, see Registering maintenance window tasks without targets (https://docs.aws.amazon.com/systems-manager/latest/userguide/maintenance-windows-targetless-tasks.html) in the Amazon Web Services Systems Manager User Guide. Specify managed nodes using the following format: Key=InstanceIds,Values=<instance-id-1>,<instance-id-2> Specify maintenance window targets using the following format: Key=WindowTargetIds,Values=<window-target-id-1>,<window-target-id-2> — item shape: {Key?: string, Values?: list<string>}
  task_arn: string # The ARN of the task to run.
  --service-role-arn: string # The Amazon Resource Name (ARN) of the IAM service role for Amazon Web Services Systems Manager to assume when running a maintenance window task. If you do not specify a service role ARN, Systems Manager uses your account's service-linked role. If no service-linked role for Systems Manager exists in your account, it is created when you run RegisterTaskWithMaintenanceWindow. For more information, see the following topics in the in the Amazon Web Services Systems Manager User Guide: Using service-linked roles for Systems Manager (https://docs.aws.amazon.com/systems-manager/latest/userguide/using-service-linked-roles.html#slr-permissions) Should I use a service-linked role or a custom service role to run maintenance window tasks? (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-maintenance-permissions.html#maintenance-window-tasks-service-role)
  task_type: string@task-type-completer # The type of task being registered.
  --task-parameters: record # The parameters that should be passed to the task when it is run. TaskParameters has been deprecated. To specify parameters to pass to a task when it runs, instead use the Parameters option in the TaskInvocationParameters structure. For information about how Systems Manager handles these options for the supported maintenance window task types, see MaintenanceWindowTaskInvocationParameters.
  --task-invocation-parameters: record # The parameters for task execution. — shape: {RunCommand?: record, Automation?: record, StepFunctions?: record, Lambda?: record}
  --priority: int # The priority of the task in the maintenance window, the lower the number the higher the priority. Tasks in a maintenance window are scheduled in priority order with tasks that have the same priority scheduled in parallel.
  --max-concurrency: string # The maximum number of targets this task can be run for, in parallel. Although this element is listed as "Required: No", a value can be omitted only when you are registering or updating a targetless task (https://docs.aws.amazon.com/systems-manager/latest/userguide/maintenance-windows-targetless-tasks.html) You must provide a value in all other cases. For maintenance window tasks without a target specified, you can't supply a value for this option. Instead, the system inserts a placeholder value of 1. This value doesn't affect the running of your task.
  --max-errors: string # The maximum number of errors allowed before this task stops being scheduled. Although this element is listed as "Required: No", a value can be omitted only when you are registering or updating a targetless task (https://docs.aws.amazon.com/systems-manager/latest/userguide/maintenance-windows-targetless-tasks.html) You must provide a value in all other cases. For maintenance window tasks without a target specified, you can't supply a value for this option. Instead, the system inserts a placeholder value of 1. This value doesn't affect the running of your task.
  --logging-info: record # Information about an Amazon Simple Storage Service (Amazon S3) bucket to write managed node-level logs to. LoggingInfo has been deprecated. To specify an Amazon Simple Storage Service (Amazon S3) bucket to contain logs, instead use the OutputS3BucketName and OutputS3KeyPrefix options in the TaskInvocationParameters structure. For information about how Amazon Web Services Systems Manager handles these options for the supported maintenance window task types, see MaintenanceWindowTaskInvocationParameters. — shape: {S3BucketName: string, S3KeyPrefix?: string, S3Region: string}
  --name: string # An optional name for the task.
  --description: string # An optional description for the task. (format: password)
  --client-token: string # User-provided idempotency token.
  --cutoff-behavior: string@cutoff-behavior-completer # Indicates whether tasks should continue to run after the cutoff time specified in the maintenance windows is reached. CONTINUE_TASK: When the cutoff time is reached, any tasks that are running continue. The default value. CANCEL_TASK: For Automation, Lambda, Step Functions tasks: When the cutoff time is reached, any task invocations that are already running continue, but no new task invocations are started. For Run Command tasks: When the cutoff time is reached, the system sends a CancelCommand operation that attempts to cancel the command associated with the task. However, there is no guarantee that the command will be terminated and the underlying process stopped. The status for tasks that are not completed is TIMED_OUT.
  --alarm-configuration: record # The details for the CloudWatch alarm you want to apply to an automation or command. — shape: {IgnorePollAlarmFailure?: bool, Alarms: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.RegisterTaskWithMaintenanceWindow"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowId, var: window_id}, {name: Targets, var: targets}, {name: TaskArn, var: task_arn}, {name: ServiceRoleArn, var: service_role_arn}, {name: TaskType, var: task_type}, {name: TaskParameters, var: task_parameters}, {name: TaskInvocationParameters, var: task_invocation_parameters}, {name: Priority, var: priority}, {name: MaxConcurrency, var: max_concurrency}, {name: MaxErrors, var: max_errors}, {name: LoggingInfo, var: logging_info}, {name: Name, var: name}, {name: Description, var: description}, {name: ClientToken, var: client_token}, {name: CutoffBehavior, var: cutoff_behavior}, {name: AlarmConfiguration, var: alarm_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_id: $window_id, targets: $targets, task_arn: $task_arn, service_role_arn: $service_role_arn, task_type: $task_type, task_parameters: $task_parameters, task_invocation_parameters: $task_invocation_parameters, priority: $priority, max_concurrency: $max_concurrency, max_errors: $max_errors, logging_info: $logging_info, name: $name, description: $description, client_token: $client_token, cutoff_behavior: $cutoff_behavior, alarm_configuration: $alarm_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes tag keys from the specified resource.
#
# POST /
# Returns: record
# operationId: RemoveTagsFromResource
export def "remove-tags-from-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_type: string@resource-type-completer # The type of resource from which you want to remove a tag. The ManagedInstance type for this API operation is only for on-premises managed nodes. Specify the name of the managed node in the following format: mi-ID_number . For example, mi-1a2b3c4d5e6f.
  resource_id: string # The ID of the resource from which you want to remove tags. For example: ManagedInstance: mi-012345abcde MaintenanceWindow: mw-012345abcde Automation: example-c160-4567-8519-012345abcde PatchBaseline: pb-012345abcde OpsMetadata object: ResourceID for tagging is created from the Amazon Resource Name (ARN) for the object. Specifically, ResourceID is created from the strings that come after the word opsmetadata in the ARN. For example, an OpsMetadata object with an ARN of arn:aws:ssm:us-east-2:1234567890:opsmetadata/aws/ssm/MyGroup/appmanager has a ResourceID of either aws/ssm/MyGroup/appmanager or /aws/ssm/MyGroup/appmanager. For the Document and Parameter values, use the name of the resource. The ManagedInstance type for this API operation is only for on-premises managed nodes. Specify the name of the managed node in the following format: mi-ID_number. For example, mi-1a2b3c4d5e6f.
  tag_keys: list<string> # Tag keys that you want to remove from the specified resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.RemoveTagsFromResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceType, var: resource_type}, {name: ResourceId, var: resource_id}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_type: $resource_type, resource_id: $resource_id, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ServiceSetting is an account-level setting for an Amazon Web Services service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an Amazon Web Services service charges money to the account based on feature or service usage, then the Amazon Web Services service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature. Services map a SettingId object to a setting value. Amazon Web Services services teams define the default value for a SettingId. You can't create a new SettingId, but you can overwrite the default value if you have the ssm:UpdateServiceSetting permission for the setting. Use the GetServiceSetting API operation to view the current value. Use the UpdateServiceSetting API operation to change the default setting. Reset the service setting for the account to the default value as provisioned by the Amazon Web Services service team.
#
# POST /
# Returns: record<ServiceSetting: record<SettingId: string, SettingValue: string, LastModifiedDate: string, LastModifiedUser: string, ARN: string, Status: string>>
# operationId: ResetServiceSetting
export def "reset-service-setting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-113 # required
  setting_id: string # The Amazon Resource Name (ARN) of the service setting to reset. The setting ID can be one of the following. /ssm/managed-instance/default-ec2-instance-management-role /ssm/automation/customer-script-log-destination /ssm/automation/customer-script-log-group-name /ssm/documents/console/public-sharing-permission /ssm/managed-instance/activation-tier /ssm/opsinsights/opscenter /ssm/parameter-store/default-parameter-tier /ssm/parameter-store/high-throughput-enabled
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ResetServiceSetting"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SettingId, var: setting_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, setting_id: $setting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reconnects a session to a managed node after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions. This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It isn't intended for any other use.
#
# POST /
# Returns: record<SessionId: string, TokenValue: string, StreamUrl: string>
# operationId: ResumeSession
export def "resume-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  session_id: string # The ID of the disconnected session to resume.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.ResumeSession"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SessionId, var: session_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, session_id: $session_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a signal to an Automation execution to change the current behavior or status of the execution.
#
# POST /
# Returns: record
# operationId: SendAutomationSignal
export def "send-automation-signal" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  automation_execution_id: string # The unique identifier for an existing Automation execution that you want to send the signal to.
  signal_type: string@signal-type-completer # The type of signal to send to an Automation execution.
  --payload: record # The data sent with the signal. The data schema depends on the type of signal used in the request. For Approve and Reject signal types, the payload is an optional comment that you can send with the signal type. For example: Comment="Looks good" For StartStep and Resume signal types, you must send the name of the Automation step to start or resume as the payload. For example: StepName="step1" For the StopStep signal type, you must send the step execution ID as the payload. For example: StepExecutionId="97fff367-fc5a-4299-aed8-0123456789ab"
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.SendAutomationSignal"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AutomationExecutionId, var: automation_execution_id}, {name: SignalType, var: signal_type}, {name: Payload, var: payload}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, automation_execution_id: $automation_execution_id, signal_type: $signal_type, payload: $payload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs commands on one or more managed nodes.
#
# POST /
# Returns: record<Command: record<CommandId: string, DocumentName: string, DocumentVersion: string, Comment: string, ExpiresAfter: string, Parameters: record, InstanceIds: list<string>, Targets: list<record>, RequestedDateTime: string, Status: string, StatusDetails: string, OutputS3Region: string, OutputS3BucketName: string, OutputS3KeyPrefix: string, MaxConcurrency: string, MaxErrors: string, TargetCount: int, CompletedCount: int, ErrorCount: int, DeliveryTimedOutCount: int, ServiceRole: string, NotificationConfig: record<NotificationArn: string, NotificationEvents: list, NotificationType: string>, CloudWatchOutputConfig: record<CloudWatchLogGroupName: string, CloudWatchOutputEnabled: bool>, TimeoutSeconds: int, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>>>
# operationId: SendCommand
export def "send-command" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --instance-ids: list<string> # The IDs of the managed nodes where the command should run. Specifying managed node IDs is most useful when you are targeting a limited number of managed nodes, though you can specify up to 50 IDs. To target a larger number of managed nodes, or if you prefer not to list individual node IDs, we recommend using the Targets option instead. Using Targets, which accepts tag key-value pairs to identify the managed nodes to send commands to, you can a send command to tens, hundreds, or thousands of nodes at once. For more information about how to use targets, see Using targets and rate controls to send commands to a fleet (https://docs.aws.amazon.com/systems-manager/latest/userguide/send-commands-multiple.html) in the Amazon Web Services Systems Manager User Guide.
  --targets: list # An array of search criteria that targets managed nodes using a Key,Value combination that you specify. Specifying targets is most useful when you want to send a command to a large number of managed nodes at once. Using Targets, which accepts tag key-value pairs to identify managed nodes, you can send a command to tens, hundreds, or thousands of nodes at once. To send a command to a smaller number of managed nodes, you can use the InstanceIds option instead. For more information about how to use targets, see Sending commands to a fleet (https://docs.aws.amazon.com/systems-manager/latest/userguide/send-commands-multiple.html) in the Amazon Web Services Systems Manager User Guide. — item shape: {Key?: string, Values?: list<string>}
  document_name: string # The name of the Amazon Web Services Systems Manager document (SSM document) to run. This can be a public document or a custom document. To run a shared document belonging to another account, specify the document Amazon Resource Name (ARN). For more information about how to use shared documents, see Using shared SSM documents (https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-using-shared.html) in the Amazon Web Services Systems Manager User Guide. If you specify a document name or ARN that hasn't been shared with your account, you receive an InvalidDocument error.
  --document-version: string # The SSM document version to use in the request. You can specify $DEFAULT, $LATEST, or a specific version number. If you run commands by using the Command Line Interface (Amazon Web Services CLI), then you must escape the first two options by using a backslash. If you specify a version number, then you don't need to use the backslash. For example: --document-version "\$DEFAULT" --document-version "\$LATEST" --document-version "3"
  --document-hash: string # The Sha256 or Sha1 hash created by the system when the document was created. Sha1 hashes have been deprecated.
  --document-hash-type: string@document-hash-type-completer # Sha256 or Sha1. Sha1 hashes have been deprecated.
  --timeout-seconds: int # If this time is reached and the command hasn't already started running, it won't run.
  --comment: string # User-specified information about the command, such as a brief description of what the command should do.
  --parameters: record # The required and optional parameters specified in the document being run.
  --output-s3-region: string # (Deprecated) You can no longer specify this parameter. The system ignores it. Instead, Systems Manager automatically determines the Amazon Web Services Region of the S3 bucket.
  --output-s3-bucket-name: string # The name of the S3 bucket where command execution responses should be stored.
  --output-s3-key-prefix: string # The directory structure within the S3 bucket where the responses should be stored.
  --max-concurrency: string # (Optional) The maximum number of managed nodes that are allowed to run the command at the same time. You can specify a number such as 10 or a percentage such as 10%. The default value is 50. For more information about how to use MaxConcurrency, see Using concurrency controls (https://docs.aws.amazon.com/systems-manager/latest/userguide/send-commands-multiple.html#send-commands-velocity) in the Amazon Web Services Systems Manager User Guide.
  --max-errors: string # The maximum number of errors allowed without the command failing. When the command fails one more time beyond the value of MaxErrors, the systems stops sending the command to additional targets. You can specify a number like 10 or a percentage like 10%. The default value is 0. For more information about how to use MaxErrors, see Using error controls (https://docs.aws.amazon.com/systems-manager/latest/userguide/send-commands-multiple.html#send-commands-maxerrors) in the Amazon Web Services Systems Manager User Guide.
  --service-role-arn: string # The ARN of the Identity and Access Management (IAM) service role to use to publish Amazon Simple Notification Service (Amazon SNS) notifications for Run Command commands. This role must provide the sns:Publish permission for your notification topic. For information about creating and using this service role, see Monitoring Systems Manager status changes using Amazon SNS notifications (https://docs.aws.amazon.com/systems-manager/latest/userguide/monitoring-sns-notifications.html) in the Amazon Web Services Systems Manager User Guide.
  --notification-config: record # Configurations for sending notifications. — shape: {NotificationArn?: string, NotificationEvents?: list<string>, NotificationType?: "Command"|"Invocation"}
  --cloud-watch-output-config: record # Configuration options for sending command output to Amazon CloudWatch Logs. — shape: {CloudWatchLogGroupName?: string, CloudWatchOutputEnabled?: bool}
  --alarm-configuration: record # The details for the CloudWatch alarm you want to apply to an automation or command. — shape: {IgnorePollAlarmFailure?: bool, Alarms: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.SendCommand"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceIds, var: instance_ids}, {name: Targets, var: targets}, {name: DocumentName, var: document_name}, {name: DocumentVersion, var: document_version}, {name: DocumentHash, var: document_hash}, {name: DocumentHashType, var: document_hash_type}, {name: TimeoutSeconds, var: timeout_seconds}, {name: Comment, var: comment}, {name: Parameters, var: parameters}, {name: OutputS3Region, var: output_s3_region}, {name: OutputS3BucketName, var: output_s3_bucket_name}, {name: OutputS3KeyPrefix, var: output_s3_key_prefix}, {name: MaxConcurrency, var: max_concurrency}, {name: MaxErrors, var: max_errors}, {name: ServiceRoleArn, var: service_role_arn}, {name: NotificationConfig, var: notification_config}, {name: CloudWatchOutputConfig, var: cloud_watch_output_config}, {name: AlarmConfiguration, var: alarm_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_ids: $instance_ids, targets: $targets, document_name: $document_name, document_version: $document_version, document_hash: $document_hash, document_hash_type: $document_hash_type, timeout_seconds: $timeout_seconds, comment: $comment, parameters: $parameters, output_s3_region: $output_s3_region, output_s3_bucket_name: $output_s3_bucket_name, output_s3_key_prefix: $output_s3_key_prefix, max_concurrency: $max_concurrency, max_errors: $max_errors, service_role_arn: $service_role_arn, notification_config: $notification_config, cloud_watch_output_config: $cloud_watch_output_config, alarm_configuration: $alarm_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs an association immediately and only one time. This operation can be helpful when troubleshooting associations.
#
# POST /
# Returns: record
# operationId: StartAssociationsOnce
export def "start-associations-once" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  association_ids: list<string> # The association IDs that you want to run immediately and only one time.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.StartAssociationsOnce"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AssociationIds, var: association_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, association_ids: $association_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates execution of an Automation runbook.
#
# POST /
# Returns: record<AutomationExecutionId: string>
# operationId: StartAutomationExecution
export def "start-automation-execution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-118 # required
  document_name: string # The name of the SSM document to run. This can be a public document or a custom document. To run a shared document belonging to another account, specify the document ARN. For more information about how to use shared documents, see Using shared SSM documents (https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-using-shared.html) in the Amazon Web Services Systems Manager User Guide.
  --document-version: string # The version of the Automation runbook to use for this execution.
  --parameters: record # A key-value map of execution parameters, which match the declared parameters in the Automation runbook.
  --client-token: string # User-provided idempotency token. The token must be unique, is case insensitive, enforces the UUID format, and can't be reused.
  --mode: string@mode-completer # The execution mode of the automation. Valid modes include the following: Auto and Interactive. The default mode is Auto.
  --target-parameter-name: string # The name of the parameter used as the target resource for the rate-controlled execution. Required if you specify targets.
  --targets: list # A key-value mapping to target resources. Required if you specify TargetParameterName. — item shape: {Key?: string, Values?: list<string>}
  --target-maps: list # A key-value mapping of document parameters to target resources. Both Targets and TargetMaps can't be specified together.
  --max-concurrency: string # The maximum number of targets allowed to run this task in parallel. You can specify a number, such as 10, or a percentage, such as 10%. The default value is 10.
  --max-errors: string # The number of errors that are allowed before the system stops running the automation on additional targets. You can specify either an absolute number of errors, for example 10, or a percentage of the target set, for example 10%. If you specify 3, for example, the system stops running the automation when the fourth error is received. If you specify 0, then the system stops running the automation on additional targets after the first error result is returned. If you run an automation on 50 resources and set max-errors to 10%, then the system stops running the automation on additional targets when the sixth error is received. Executions that are already running an automation when max-errors is reached are allowed to complete, but some of these executions may fail as well. If you need to ensure that there won't be more than max-errors failed executions, set max-concurrency to 1 so the executions proceed one at a time.
  --target-locations: list # A location is a combination of Amazon Web Services Regions and/or Amazon Web Services accounts where you want to run the automation. Use this operation to start an automation in multiple Amazon Web Services Regions and multiple Amazon Web Services accounts. For more information, see Running Automation workflows in multiple Amazon Web Services Regions and Amazon Web Services accounts (https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-automation-multiple-accounts-and-regions.html) in the Amazon Web Services Systems Manager User Guide. — item shape: {Accounts?: list<string>, Regions?: list<string>, TargetLocationMaxConcurrency?: string, TargetLocationMaxErrors?: string, ExecutionRoleName?: string, TargetLocationAlarmConfiguration?: record}
  --tags: list # Optional metadata that you assign to a resource. You can specify a maximum of five tags for an automation. Tags enable you to categorize a resource in different ways, such as by purpose, owner, or environment. For example, you might want to tag an automation to identify an environment or operating system. In this case, you could specify the following key-value pairs: Key=environment,Value=test Key=OS,Value=Windows To add tags to an existing automation, use the AddTagsToResource operation. — item shape: {Key: string, Value: string}
  --alarm-configuration: record # The details for the CloudWatch alarm you want to apply to an automation or command. — shape: {IgnorePollAlarmFailure?: bool, Alarms: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.StartAutomationExecution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DocumentName, var: document_name}, {name: DocumentVersion, var: document_version}, {name: Parameters, var: parameters}, {name: ClientToken, var: client_token}, {name: Mode, var: mode}, {name: TargetParameterName, var: target_parameter_name}, {name: Targets, var: targets}, {name: TargetMaps, var: target_maps}, {name: MaxConcurrency, var: max_concurrency}, {name: MaxErrors, var: max_errors}, {name: TargetLocations, var: target_locations}, {name: Tags, var: tags}, {name: AlarmConfiguration, var: alarm_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, document_name: $document_name, document_version: $document_version, parameters: $parameters, client_token: $client_token, mode: $mode, target_parameter_name: $target_parameter_name, targets: $targets, target_maps: $target_maps, max_concurrency: $max_concurrency, max_errors: $max_errors, target_locations: $target_locations, tags: $tags, alarm_configuration: $alarm_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a change request for Change Manager. The Automation runbooks specified in the change request run only after all required approvals for the change request have been received.
#
# POST /
# Returns: record<AutomationExecutionId: string>
# operationId: StartChangeRequestExecution
export def "start-change-request-execution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-119 # required
  --scheduled-time: string # The date and time specified in the change request to run the Automation runbooks. The Automation runbooks specified for the runbook workflow can't run until all required approvals for the change request have been received. (format: date-time)
  document_name: string # The name of the change template document to run during the runbook workflow.
  --document-version: string # The version of the change template document to run during the runbook workflow.
  --parameters: record # A key-value map of parameters that match the declared parameters in the change template document.
  --change-request-name: string # The name of the change request associated with the runbook workflow to be run.
  --client-token: string # The user-provided idempotency token. The token must be unique, is case insensitive, enforces the UUID format, and can't be reused.
  --auto-approve: oneof<nothing, bool> # Indicates whether the change request can be approved automatically without the need for manual approvals. If AutoApprovable is enabled in a change template, then setting AutoApprove to true in StartChangeRequestExecution creates a change request that bypasses approver review. Change Calendar restrictions are not bypassed in this scenario. If the state of an associated calendar is CLOSED, change freeze approvers must still grant permission for this change request to run. If they don't, the change won't be processed until the calendar state is again OPEN.
  runbooks: list # Information about the Automation runbooks that are run during the runbook workflow. The Automation runbooks specified for the runbook workflow can't run until all required approvals for the change request have been received. — item shape: {DocumentName: string, DocumentVersion?: string, Parameters?: record, TargetParameterName?: string, Targets?: list, TargetMaps?: list, MaxConcurrency?: string, MaxErrors?: string, TargetLocations?: list}
  --tags: list # Optional metadata that you assign to a resource. You can specify a maximum of five tags for a change request. Tags enable you to categorize a resource in different ways, such as by purpose, owner, or environment. For example, you might want to tag a change request to identify an environment or target Amazon Web Services Region. In this case, you could specify the following key-value pairs: Key=Environment,Value=Production Key=Region,Value=us-east-2 — item shape: {Key: string, Value: string}
  --scheduled-end-time: string # The time that the requester expects the runbook workflow related to the change request to complete. The time is an estimate only that the requester provides for reviewers. (format: date-time)
  --change-details: string # User-provided details about the change. If no details are provided, content specified in the Template information section of the associated change template is added.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.StartChangeRequestExecution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ScheduledTime, var: scheduled_time}, {name: DocumentName, var: document_name}, {name: DocumentVersion, var: document_version}, {name: Parameters, var: parameters}, {name: ChangeRequestName, var: change_request_name}, {name: ClientToken, var: client_token}, {name: AutoApprove, var: auto_approve}, {name: Runbooks, var: runbooks}, {name: Tags, var: tags}, {name: ScheduledEndTime, var: scheduled_end_time}, {name: ChangeDetails, var: change_details}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, scheduled_time: $scheduled_time, document_name: $document_name, document_version: $document_version, parameters: $parameters, change_request_name: $change_request_name, client_token: $client_token, auto_approve: $auto_approve, runbooks: $runbooks, tags: $tags, scheduled_end_time: $scheduled_end_time, change_details: $change_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates a connection to a target (for example, a managed node) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs. Amazon Web Services CLI usage: start-session is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see Install the Session Manager plugin for the Amazon Web Services CLI (https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) in the Amazon Web Services Systems Manager User Guide. Amazon Web Services Tools for PowerShell usage: Start-SSMSession isn't currently supported by Amazon Web Services Tools for PowerShell on Windows local machines.
#
# POST /
# Returns: record<SessionId: string, TokenValue: string, StreamUrl: string>
# operationId: StartSession
export def "start-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  target: string # The managed node to connect to for the session.
  --document-name: string # The name of the SSM document you want to use to define the type of session, input parameters, or preferences for the session. For example, SSM-SessionManagerRunShell. You can call the GetDocument API to verify the document exists before attempting to start a session. If no document name is provided, a shell to the managed node is launched by default. For more information, see Start a session (https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html) in the Amazon Web Services Systems Manager User Guide.
  --reason: string # The reason for connecting to the instance. This value is included in the details for the Amazon CloudWatch Events event created when you start the session.
  --parameters: record # The values you want to specify for the parameters defined in the Session document.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.StartSession"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Target, var: target}, {name: DocumentName, var: document_name}, {name: Reason, var: reason}, {name: Parameters, var: parameters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, target: $target, document_name: $document_name, reason: $reason, parameters: $parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop an Automation that is currently running.
#
# POST /
# Returns: record
# operationId: StopAutomationExecution
export def "stop-automation-execution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  automation_execution_id: string # The execution ID of the Automation to stop.
  --type: string@type-completer-1 # The stop request type. Valid types include the following: Cancel and Complete. The default type is Cancel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.StopAutomationExecution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AutomationExecutionId, var: automation_execution_id}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, automation_execution_id: $automation_execution_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the managed node. A terminated session can't be resumed.
#
# POST /
# Returns: record<SessionId: string>
# operationId: TerminateSession
export def "terminate-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-122 # required
  session_id: string # The ID of the session to terminate.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.TerminateSession"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SessionId, var: session_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, session_id: $session_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a label or labels from a parameter.
#
# POST /
# Returns: record<RemovedLabels: list<string>, InvalidLabels: list<string>>
# operationId: UnlabelParameterVersion
export def "unlabel-parameter-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the parameter from which you want to delete one or more labels.
  parameter_version: int # The specific version of the parameter which you want to delete one or more labels from. If it isn't present, the call will fail.
  labels: list<string> # One or more labels to delete from the specified parameter version.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.UnlabelParameterVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: ParameterVersion, var: parameter_version}, {name: Labels, var: labels}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, parameter_version: $parameter_version, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon Simple Storage Service (Amazon S3) output. When you call UpdateAssociation, the system removes all optional parameters from the request and overwrites the association with null values for those parameters. This is by design. You must specify all optional parameters in the call, even if you are not changing the parameters. This includes the Name parameter. Before calling this API action, we recommend that you call the DescribeAssociation API operation and make a note of all optional parameters required for your UpdateAssociation call. In order to call this API operation, a user, group, or role must be granted permission to call the DescribeAssociation API operation. If you don't have permission to call DescribeAssociation, then you receive the following error: An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: <user_arn> isn't authorized to perform: ssm:DescribeAssociation on resource: <resource_arn> When you update an association, the association immediately runs against the specified targets. You can add the ApplyOnlyAtCronInterval parameter to run the association during the next schedule run.
#
# POST /
# Returns: record<AssociationDescription: record<Name: string, InstanceId: string, AssociationVersion: string, Date: string, LastUpdateAssociationDate: string, Status: record<Date: string, Name: string, Message: string, AdditionalInfo: string>, Overview: record<Status: string, DetailedStatus: string, AssociationStatusAggregatedCount: record>, DocumentVersion: string, AutomationTargetParameterName: string, Parameters: record, AssociationId: string, Targets: list<record>, ScheduleExpression: string, OutputLocation: record<S3Location: record>, LastExecutionDate: string, LastSuccessfulExecutionDate: string, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list<string>, TargetLocations: list<record>, ScheduleOffset: int, TargetMaps: list<record>, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>>>
# operationId: UpdateAssociation
export def "update-association" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-124 # required
  association_id: string # The ID of the association you want to update.
  --parameters: record # The parameters you want to update for the association. If you create a parameter using Parameter Store, a capability of Amazon Web Services Systems Manager, you can reference the parameter using {{ssm:parameter-name}}.
  --document-version: string # The document version you want update for the association. State Manager doesn't support running associations that use a new version of a document if that document is shared from another account. State Manager always runs the default version of a document if shared from another account, even though the Systems Manager console shows that a new version was processed. If you want to run an association using a new version of a document shared form another account, you must set the document version to default.
  --schedule-expression: string # The cron expression used to schedule the association that you want to update.
  --output-location: record # An S3 bucket where you want to store the results of this request. For the minimal permissions required to enable Amazon S3 output for an association, see Creating associations (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-state-assoc.html) in the Systems Manager User Guide. — shape: {S3Location?: record}
  --name: string # The name of the SSM Command document or Automation runbook that contains the configuration information for the managed node. You can specify Amazon Web Services-predefined documents, documents you created, or a document that is shared with you from another account. For Systems Manager document (SSM document) that are shared with you from other Amazon Web Services accounts, you must specify the complete SSM document ARN, in the following format: arn:aws:ssm:region:account-id:document/document-name For example: arn:aws:ssm:us-east-2:12345678912:document/My-Shared-Document For Amazon Web Services-predefined documents and SSM documents you created in your account, you only need to specify the document name. For example, AWS-ApplyPatchBaseline or My-Document.
  --targets: list # The targets of the association. — item shape: {Key?: string, Values?: list<string>}
  --association-name: string # The name of the association that you want to update.
  --association-version: string # This parameter is provided for concurrency control purposes. You must specify the latest association version in the service. If you want to ensure that this request succeeds, either specify $LATEST, or omit this parameter.
  --automation-target-parameter-name: string # Choose the parameter that will define how your automation will branch out. This target is required for associations that use an Automation runbook and target resources by using rate controls. Automation is a capability of Amazon Web Services Systems Manager.
  --max-errors: string # The number of errors that are allowed before the system stops sending requests to run the association on additional targets. You can specify either an absolute number of errors, for example 10, or a percentage of the target set, for example 10%. If you specify 3, for example, the system stops sending requests when the fourth error is received. If you specify 0, then the system stops sending requests after the first error is returned. If you run an association on 50 managed nodes and set MaxError to 10%, then the system stops sending the request when the sixth error is received. Executions that are already running an association when MaxErrors is reached are allowed to complete, but some of these executions may fail as well. If you need to ensure that there won't be more than max-errors failed executions, set MaxConcurrency to 1 so that executions proceed one at a time.
  --max-concurrency: string # The maximum number of targets allowed to run the association at the same time. You can specify a number, for example 10, or a percentage of the target set, for example 10%. The default value is 100%, which means all targets run the association at the same time. If a new managed node starts and attempts to run an association while Systems Manager is running MaxConcurrency associations, the association is allowed to run. During the next association interval, the new managed node will process its association within the limit specified for MaxConcurrency.
  --compliance-severity: string@compliance-severity-completer # The severity level to assign to the association.
  --sync-compliance: string@sync-compliance-completer # The mode for generating association compliance. You can specify AUTO or MANUAL. In AUTO mode, the system uses the status of the association execution to determine the compliance status. If the association execution runs successfully, then the association is COMPLIANT. If the association execution doesn't run successfully, the association is NON-COMPLIANT. In MANUAL mode, you must specify the AssociationId as a parameter for the PutComplianceItems API operation. In this case, compliance data isn't managed by State Manager, a capability of Amazon Web Services Systems Manager. It is managed by your direct call to the PutComplianceItems API operation. By default, all associations use AUTO mode.
  --apply-only-at-cron-interval: oneof<nothing, bool> # By default, when you update an association, the system runs it immediately after it is updated and then according to the schedule you specified. Specify this option if you don't want an association to run immediately after you update it. This parameter isn't supported for rate expressions. If you chose this option when you created an association and later you edit that association or you make changes to the SSM document on which that association is based (by using the Documents page in the console), State Manager applies the association at the next specified cron interval. For example, if you chose the Latest version of an SSM document when you created an association and you edit the association by choosing a different document version on the Documents page, State Manager applies the association at the next specified cron interval if you previously selected this option. If this option wasn't selected, State Manager immediately runs the association. You can reset this option. To do so, specify the no-apply-only-at-cron-interval parameter when you update the association from the command line. This parameter forces the association to run immediately after updating it and according to the interval specified.
  --calendar-names: list<string> # The names or Amazon Resource Names (ARNs) of the Change Calendar type documents you want to gate your associations under. The associations only run when that change calendar is open. For more information, see Amazon Web Services Systems Manager Change Calendar (https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar).
  --target-locations: list # A location is a combination of Amazon Web Services Regions and Amazon Web Services accounts where you want to run the association. Use this action to update an association in multiple Regions and multiple accounts. — item shape: {Accounts?: list<string>, Regions?: list<string>, TargetLocationMaxConcurrency?: string, TargetLocationMaxErrors?: string, ExecutionRoleName?: string, TargetLocationAlarmConfiguration?: record}
  --schedule-offset: int # Number of days to wait after the scheduled day to run an association. For example, if you specified a cron schedule of cron(0 0 ? * THU#2 *), you could specify an offset of 3 to run the association each Sunday after the second Thursday of the month. For more information about cron schedules for associations, see Reference: Cron and rate expressions for Systems Manager (https://docs.aws.amazon.com/systems-manager/latest/userguide/reference-cron-and-rate-expressions.html) in the Amazon Web Services Systems Manager User Guide. To use offsets, you must specify the ApplyOnlyAtCronInterval parameter. This option tells the system not to run an association immediately after you create it.
  --target-maps: list # A key-value mapping of document parameters to target resources. Both Targets and TargetMaps can't be specified together.
  --alarm-configuration: record # The details for the CloudWatch alarm you want to apply to an automation or command. — shape: {IgnorePollAlarmFailure?: bool, Alarms: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.UpdateAssociation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AssociationId, var: association_id}, {name: Parameters, var: parameters}, {name: DocumentVersion, var: document_version}, {name: ScheduleExpression, var: schedule_expression}, {name: OutputLocation, var: output_location}, {name: Name, var: name}, {name: Targets, var: targets}, {name: AssociationName, var: association_name}, {name: AssociationVersion, var: association_version}, {name: AutomationTargetParameterName, var: automation_target_parameter_name}, {name: MaxErrors, var: max_errors}, {name: MaxConcurrency, var: max_concurrency}, {name: ComplianceSeverity, var: compliance_severity}, {name: SyncCompliance, var: sync_compliance}, {name: ApplyOnlyAtCronInterval, var: apply_only_at_cron_interval}, {name: CalendarNames, var: calendar_names}, {name: TargetLocations, var: target_locations}, {name: ScheduleOffset, var: schedule_offset}, {name: TargetMaps, var: target_maps}, {name: AlarmConfiguration, var: alarm_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, association_id: $association_id, parameters: $parameters, document_version: $document_version, schedule_expression: $schedule_expression, output_location: $output_location, name: $name, targets: $targets, association_name: $association_name, association_version: $association_version, automation_target_parameter_name: $automation_target_parameter_name, max_errors: $max_errors, max_concurrency: $max_concurrency, compliance_severity: $compliance_severity, sync_compliance: $sync_compliance, apply_only_at_cron_interval: $apply_only_at_cron_interval, calendar_names: $calendar_names, target_locations: $target_locations, schedule_offset: $schedule_offset, target_maps: $target_maps, alarm_configuration: $alarm_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the status of the Amazon Web Services Systems Manager document (SSM document) associated with the specified managed node. UpdateAssociationStatus is primarily used by the Amazon Web Services Systems Manager Agent (SSM Agent) to report status updates about your associations and is only used for associations created with the InstanceId legacy parameter.
#
# POST /
# Returns: record<AssociationDescription: record<Name: string, InstanceId: string, AssociationVersion: string, Date: string, LastUpdateAssociationDate: string, Status: record<Date: string, Name: string, Message: string, AdditionalInfo: string>, Overview: record<Status: string, DetailedStatus: string, AssociationStatusAggregatedCount: record>, DocumentVersion: string, AutomationTargetParameterName: string, Parameters: record, AssociationId: string, Targets: list<record>, ScheduleExpression: string, OutputLocation: record<S3Location: record>, LastExecutionDate: string, LastSuccessfulExecutionDate: string, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list<string>, TargetLocations: list<record>, ScheduleOffset: int, TargetMaps: list<record>, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>>>
# operationId: UpdateAssociationStatus
export def "update-association-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the SSM document.
  instance_id: string # The managed node ID.
  association_status: record # Describes an association status. — shape: {Date: string, Name: "Pending"|"Success"|"Failed", Message: string, AdditionalInfo?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.UpdateAssociationStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: InstanceId, var: instance_id}, {name: AssociationStatus, var: association_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, instance_id: $instance_id, association_status: $association_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates one or more values for an SSM document.
#
# POST /
# Returns: record<DocumentDescription: record<Sha1: string, Hash: string, HashType: string, Name: string, DisplayName: string, VersionName: string, Owner: string, CreatedDate: string, Status: string, StatusInformation: string, DocumentVersion: string, Description: string, Parameters: list<record>, PlatformTypes: list<string>, DocumentType: string, SchemaVersion: string, LatestVersion: string, DefaultVersion: string, DocumentFormat: string, TargetType: string, Tags: list<record>, AttachmentsInformation: list<record>, Requires: list<record>, Author: string, ReviewInformation: list<record>, ApprovedVersion: string, PendingReviewVersion: string, ReviewStatus: string, Category: list<string>, CategoryEnum: list<string>>>
# operationId: UpdateDocument
export def "update-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  content: string # A valid JSON or YAML string.
  --attachments: list # A list of key-value pairs that describe attachments to a version of a document. — item shape: {Key?: "SourceUrl"|"S3FileUrl"|"AttachmentReference", Values?: list<string>, Name?: string}
  name: string # The name of the SSM document that you want to update.
  --display-name: string # The friendly name of the SSM document that you want to update. This value can differ for each version of the document. If you don't specify a value for this parameter in your request, the existing value is applied to the new document version.
  --version-name: string # An optional field specifying the version of the artifact you are updating with the document. For example, "Release 12, Update 6". This value is unique across all versions of a document, and can't be changed.
  --document-version: string # The version of the document that you want to update. Currently, Systems Manager supports updating only the latest version of the document. You can specify the version number of the latest version or use the $LATEST variable. If you change a document version for a State Manager association, Systems Manager immediately runs the association unless you previously specifed the apply-only-at-cron-interval parameter.
  --document-format: string@document-format-completer # Specify the document format for the new document version. Systems Manager supports JSON and YAML documents. JSON is the default format.
  --target-type: string # Specify a new target type for the document.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.UpdateDocument"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Content, var: content}, {name: Attachments, var: attachments}, {name: Name, var: name}, {name: DisplayName, var: display_name}, {name: VersionName, var: version_name}, {name: DocumentVersion, var: document_version}, {name: DocumentFormat, var: document_format}, {name: TargetType, var: target_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, content: $content, attachments: $attachments, name: $name, display_name: $display_name, version_name: $version_name, document_version: $document_version, document_format: $document_format, target_type: $target_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the default version of a document. If you change a document version for a State Manager association, Systems Manager immediately runs the association unless you previously specifed the apply-only-at-cron-interval parameter.
#
# POST /
# Returns: record<Description: record<Name: string, DefaultVersion: string, DefaultVersionName: string>>
# operationId: UpdateDocumentDefaultVersion
export def "update-document-default-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-127 # required
  name: string # The name of a custom document that you want to set as the default version.
  document_version: string # The version of a custom document that you want to set as the default version.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.UpdateDocumentDefaultVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: DocumentVersion, var: document_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, document_version: $document_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates information related to approval reviews for a specific version of a change template in Change Manager.
#
# POST /
# Returns: record
# operationId: UpdateDocumentMetadata
export def "update-document-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the change template for which a version's metadata is to be updated.
  --document-version: string # The version of a change template in which to update approval metadata.
  document_reviews: record # Information about a document approval review. — shape: {Action: "SendForReview"|"UpdateReview"|"Approve"|"Reject", Comment?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.UpdateDocumentMetadata"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: DocumentVersion, var: document_version}, {name: DocumentReviews, var: document_reviews}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, document_version: $document_version, document_reviews: $document_reviews
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing maintenance window. Only specified parameters are modified. The value you specify for Duration determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for Cutoff. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for Cutoff is one hour, no maintenance window tasks can start after 5 PM.
#
# POST /
# Returns: record<WindowId: string, Name: string, Description: string, StartDate: string, EndDate: string, Schedule: string, ScheduleTimezone: string, ScheduleOffset: int, Duration: int, Cutoff: int, AllowUnassociatedTargets: bool, Enabled: bool>
# operationId: UpdateMaintenanceWindow
export def "update-maintenance-window" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  window_id: string # The ID of the maintenance window to update.
  --name: string # The name of the maintenance window.
  --description: string # An optional description for the update request. (format: password)
  --start-date: string # The date and time, in ISO-8601 Extended format, for when you want the maintenance window to become active. StartDate allows you to delay activation of the maintenance window until the specified future date.
  --end-date: string # The date and time, in ISO-8601 Extended format, for when you want the maintenance window to become inactive. EndDate allows you to set a date and time in the future when the maintenance window will no longer run.
  --schedule: string # The schedule of the maintenance window in the form of a cron or rate expression.
  --schedule-timezone: string # The time zone that the scheduled maintenance window executions are based on, in Internet Assigned Numbers Authority (IANA) format. For example: "America/Los_Angeles", "UTC", or "Asia/Seoul". For more information, see the Time Zone Database (https://www.iana.org/time-zones) on the IANA website.
  --schedule-offset: int # The number of days to wait after the date and time specified by a cron expression before running the maintenance window. For example, the following cron expression schedules a maintenance window to run the third Tuesday of every month at 11:30 PM. cron(30 23 ? * TUE#3 *) If the schedule offset is 2, the maintenance window won't run until two days later.
  --duration: int # The duration of the maintenance window in hours.
  --cutoff: int # The number of hours before the end of the maintenance window that Amazon Web Services Systems Manager stops scheduling new tasks for execution.
  --allow-unassociated-targets: oneof<nothing, bool> # Whether targets must be registered with the maintenance window before tasks can be defined for those targets.
  --enabled: oneof<nothing, bool> # Whether the maintenance window is enabled.
  --replace: oneof<nothing, bool> # If True, then all fields that are required by the CreateMaintenanceWindow operation are also required for this API request. Optional fields that aren't specified are set to null.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.UpdateMaintenanceWindow"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowId, var: window_id}, {name: Name, var: name}, {name: Description, var: description}, {name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: Schedule, var: schedule}, {name: ScheduleTimezone, var: schedule_timezone}, {name: ScheduleOffset, var: schedule_offset}, {name: Duration, var: duration}, {name: Cutoff, var: cutoff}, {name: AllowUnassociatedTargets, var: allow_unassociated_targets}, {name: Enabled, var: enabled}, {name: Replace, var: replace}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_id: $window_id, name: $name, description: $description, start_date: $start_date, end_date: $end_date, schedule: $schedule, schedule_timezone: $schedule_timezone, schedule_offset: $schedule_offset, duration: $duration, cutoff: $cutoff, allow_unassociated_targets: $allow_unassociated_targets, enabled: $enabled, replace: $replace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the target of an existing maintenance window. You can change the following: Name Description Owner IDs for an ID target Tags for a Tag target From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see Target. If a parameter is null, then the corresponding field isn't modified.
#
# POST /
# Returns: record<WindowId: string, WindowTargetId: string, Targets: table<Key: string, Values: list>, OwnerInformation: string, Name: string, Description: string>
# operationId: UpdateMaintenanceWindowTarget
export def "update-maintenance-window-target" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  window_id: string # The maintenance window ID with which to modify the target.
  window_target_id: string # The target ID to modify.
  --targets: list # The targets to add or replace. — item shape: {Key?: string, Values?: list<string>}
  --owner-information: string # User-provided value that will be included in any Amazon CloudWatch Events events raised while running tasks for these targets in this maintenance window. (format: password)
  --name: string # A name for the update.
  --description: string # An optional description for the update. (format: password)
  --replace: oneof<nothing, bool> # If True, then all fields that are required by the RegisterTargetWithMaintenanceWindow operation are also required for this API request. Optional fields that aren't specified are set to null.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.UpdateMaintenanceWindowTarget"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowId, var: window_id}, {name: WindowTargetId, var: window_target_id}, {name: Targets, var: targets}, {name: OwnerInformation, var: owner_information}, {name: Name, var: name}, {name: Description, var: description}, {name: Replace, var: replace}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_id: $window_id, window_target_id: $window_target_id, targets: $targets, owner_information: $owner_information, name: $name, description: $description, replace: $replace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values: TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript. ServiceRoleArn TaskInvocationParameters Priority MaxConcurrency MaxErrors One or more targets must be specified for maintenance window Run Command-type tasks. Depending on the task, targets are optional for other maintenance window task types (Automation, Lambda, and Step Functions). For more information about running tasks that don't specify targets, see Registering maintenance window tasks without targets (https://docs.aws.amazon.com/systems-manager/latest/userguide/maintenance-windows-targetless-tasks.html) in the Amazon Web Services Systems Manager User Guide. If the value for a parameter in UpdateMaintenanceWindowTask is null, then the corresponding field isn't modified. If you set Replace to true, then all fields required by the RegisterTaskWithMaintenanceWindow operation are required for this request. Optional fields that aren't specified are set to null. When you update a maintenance window task that has options specified in TaskInvocationParameters, you must provide again all the TaskInvocationParameters values that you want to retain. The values you don't specify again are removed. For example, suppose that when you registered a Run Command task, you specified TaskInvocationParameters values for Comment, NotificationConfig, and OutputS3BucketName. If you update the maintenance window task and specify only a different OutputS3BucketName value, the values for Comment and NotificationConfig are removed.
#
# POST /
# Returns: record<WindowId: string, WindowTaskId: string, Targets: table<Key: string, Values: list>, TaskArn: string, ServiceRoleArn: string, TaskParameters: record, TaskInvocationParameters: record<RunCommand: record<Comment: string, CloudWatchOutputConfig: record, DocumentHash: string, DocumentHashType: string, DocumentVersion: string, NotificationConfig: record, OutputS3BucketName: string, OutputS3KeyPrefix: string, Parameters: record, ServiceRoleArn: string, TimeoutSeconds: int>, Automation: record<DocumentVersion: string, Parameters: record>, StepFunctions: record<Input: string, Name: string>, Lambda: record<ClientContext: string, Qualifier: string, Payload: string>>, Priority: int, MaxConcurrency: string, MaxErrors: string, LoggingInfo: record<S3BucketName: string, S3KeyPrefix: string, S3Region: string>, Name: string, Description: string, CutoffBehavior: string, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list<record>>>
# operationId: UpdateMaintenanceWindowTask
export def "update-maintenance-window-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-131 # required
  window_id: string # The maintenance window ID that contains the task to modify.
  window_task_id: string # The task ID to modify.
  --targets: list # The targets (either managed nodes or tags) to modify. Managed nodes are specified using the format Key=instanceids,Values=instanceID_1,instanceID_2. Tags are specified using the format Key=tag_name,Values=tag_value. One or more targets must be specified for maintenance window Run Command-type tasks. Depending on the task, targets are optional for other maintenance window task types (Automation, Lambda, and Step Functions). For more information about running tasks that don't specify targets, see Registering maintenance window tasks without targets (https://docs.aws.amazon.com/systems-manager/latest/userguide/maintenance-windows-targetless-tasks.html) in the Amazon Web Services Systems Manager User Guide. — item shape: {Key?: string, Values?: list<string>}
  --task-arn: string # The task ARN to modify.
  --service-role-arn: string # The Amazon Resource Name (ARN) of the IAM service role for Amazon Web Services Systems Manager to assume when running a maintenance window task. If you do not specify a service role ARN, Systems Manager uses your account's service-linked role. If no service-linked role for Systems Manager exists in your account, it is created when you run RegisterTaskWithMaintenanceWindow. For more information, see the following topics in the in the Amazon Web Services Systems Manager User Guide: Using service-linked roles for Systems Manager (https://docs.aws.amazon.com/systems-manager/latest/userguide/using-service-linked-roles.html#slr-permissions) Should I use a service-linked role or a custom service role to run maintenance window tasks? (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-maintenance-permissions.html#maintenance-window-tasks-service-role)
  --task-parameters: record # The parameters to modify. TaskParameters has been deprecated. To specify parameters to pass to a task when it runs, instead use the Parameters option in the TaskInvocationParameters structure. For information about how Systems Manager handles these options for the supported maintenance window task types, see MaintenanceWindowTaskInvocationParameters. The map has the following format: Key: string, between 1 and 255 characters Value: an array of strings, each string is between 1 and 255 characters
  --task-invocation-parameters: record # The parameters for task execution. — shape: {RunCommand?: record, Automation?: record, StepFunctions?: record, Lambda?: record}
  --priority: int # The new task priority to specify. The lower the number, the higher the priority. Tasks that have the same priority are scheduled in parallel.
  --max-concurrency: string # The new MaxConcurrency value you want to specify. MaxConcurrency is the number of targets that are allowed to run this task, in parallel. Although this element is listed as "Required: No", a value can be omitted only when you are registering or updating a targetless task (https://docs.aws.amazon.com/systems-manager/latest/userguide/maintenance-windows-targetless-tasks.html) You must provide a value in all other cases. For maintenance window tasks without a target specified, you can't supply a value for this option. Instead, the system inserts a placeholder value of 1. This value doesn't affect the running of your task.
  --max-errors: string # The new MaxErrors value to specify. MaxErrors is the maximum number of errors that are allowed before the task stops being scheduled. Although this element is listed as "Required: No", a value can be omitted only when you are registering or updating a targetless task (https://docs.aws.amazon.com/systems-manager/latest/userguide/maintenance-windows-targetless-tasks.html) You must provide a value in all other cases. For maintenance window tasks without a target specified, you can't supply a value for this option. Instead, the system inserts a placeholder value of 1. This value doesn't affect the running of your task.
  --logging-info: record # Information about an Amazon Simple Storage Service (Amazon S3) bucket to write managed node-level logs to. LoggingInfo has been deprecated. To specify an Amazon Simple Storage Service (Amazon S3) bucket to contain logs, instead use the OutputS3BucketName and OutputS3KeyPrefix options in the TaskInvocationParameters structure. For information about how Amazon Web Services Systems Manager handles these options for the supported maintenance window task types, see MaintenanceWindowTaskInvocationParameters. — shape: {S3BucketName: string, S3KeyPrefix?: string, S3Region: string}
  --name: string # The new task name to specify.
  --description: string # The new task description to specify. (format: password)
  --replace: oneof<nothing, bool> # If True, then all fields that are required by the RegisterTaskWithMaintenanceWindow operation are also required for this API request. Optional fields that aren't specified are set to null.
  --cutoff-behavior: string@cutoff-behavior-completer # Indicates whether tasks should continue to run after the cutoff time specified in the maintenance windows is reached. CONTINUE_TASK: When the cutoff time is reached, any tasks that are running continue. The default value. CANCEL_TASK: For Automation, Lambda, Step Functions tasks: When the cutoff time is reached, any task invocations that are already running continue, but no new task invocations are started. For Run Command tasks: When the cutoff time is reached, the system sends a CancelCommand operation that attempts to cancel the command associated with the task. However, there is no guarantee that the command will be terminated and the underlying process stopped. The status for tasks that are not completed is TIMED_OUT.
  --alarm-configuration: record # The details for the CloudWatch alarm you want to apply to an automation or command. — shape: {IgnorePollAlarmFailure?: bool, Alarms: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.UpdateMaintenanceWindowTask"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WindowId, var: window_id}, {name: WindowTaskId, var: window_task_id}, {name: Targets, var: targets}, {name: TaskArn, var: task_arn}, {name: ServiceRoleArn, var: service_role_arn}, {name: TaskParameters, var: task_parameters}, {name: TaskInvocationParameters, var: task_invocation_parameters}, {name: Priority, var: priority}, {name: MaxConcurrency, var: max_concurrency}, {name: MaxErrors, var: max_errors}, {name: LoggingInfo, var: logging_info}, {name: Name, var: name}, {name: Description, var: description}, {name: Replace, var: replace}, {name: CutoffBehavior, var: cutoff_behavior}, {name: AlarmConfiguration, var: alarm_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, window_id: $window_id, window_task_id: $window_task_id, targets: $targets, task_arn: $task_arn, service_role_arn: $service_role_arn, task_parameters: $task_parameters, task_invocation_parameters: $task_invocation_parameters, priority: $priority, max_concurrency: $max_concurrency, max_errors: $max_errors, logging_info: $logging_info, name: $name, description: $description, replace: $replace, cutoff_behavior: $cutoff_behavior, alarm_configuration: $alarm_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the Identity and Access Management (IAM) role that is assigned to the on-premises server, edge device, or virtual machines (VM). IAM roles are first assigned to these hybrid nodes during the activation process. For more information, see CreateActivation.
#
# POST /
# Returns: record
# operationId: UpdateManagedInstanceRole
export def "update-managed-instance-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_id: string # The ID of the managed node where you want to update the role.
  iam_role: string # The name of the Identity and Access Management (IAM) role that you want to assign to the managed node. This IAM role must provide AssumeRole permissions for the Amazon Web Services Systems Manager service principal ssm.amazonaws.com. For more information, see Create an IAM service role for a hybrid environment (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-service-role.html) in the Amazon Web Services Systems Manager User Guide. You can't specify an IAM service-linked role for this parameter. You must create a unique role.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.UpdateManagedInstanceRole"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: IamRole, var: iam_role}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id, iam_role: $iam_role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit or change an OpsItem. You must have permission in Identity and Access Management (IAM) to update an OpsItem. For more information, see Getting started with OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html) in the Amazon Web Services Systems Manager User Guide. Operations engineers and IT professionals use Amazon Web Services Systems Manager OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their Amazon Web Services resources. For more information, see OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html) in the Amazon Web Services Systems Manager User Guide.
#
# POST /
# Returns: record
# operationId: UpdateOpsItem
export def "update-ops-item" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-133 # required
  --description: string # Update the information about the OpsItem. Provide enough information so that users reading this OpsItem for the first time understand the issue.
  --operational-data: record # Add new keys or edit existing key-value pairs of the OperationalData map in the OpsItem object. Operational data is custom data that provides useful reference details about the OpsItem. For example, you can specify log files, error strings, license keys, troubleshooting tips, or other relevant data. You enter operational data as key-value pairs. The key has a maximum length of 128 characters. The value has a maximum size of 20 KB. Operational data keys can't begin with the following: amazon, aws, amzn, ssm, /amazon, /aws, /amzn, /ssm. You can choose to make the data searchable by other users in the account or you can restrict search access. Searchable data means that all users with access to the OpsItem Overview page (as provided by the DescribeOpsItems API operation) can view and search on the specified data. Operational data that isn't searchable is only viewable by users who have access to the OpsItem (as provided by the GetOpsItem API operation). Use the /aws/resources key in OperationalData to specify a related resource in the request. Use the /aws/automations key in OperationalData to associate an Automation runbook with the OpsItem. To view Amazon Web Services CLI example commands that use these keys, see Creating OpsItems manually (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-creating-OpsItems.html#OpsCenter-manually-create-OpsItems) in the Amazon Web Services Systems Manager User Guide.
  --operational-data-to-delete: list<string> # Keys that you want to remove from the OperationalData map.
  --notifications: list # The Amazon Resource Name (ARN) of an SNS topic where notifications are sent when this OpsItem is edited or changed. — item shape: {Arn?: string}
  --priority: int # The importance of this OpsItem in relation to other OpsItems in the system.
  --related-ops-items: list # One or more OpsItems that share something in common with the current OpsItems. For example, related OpsItems can include OpsItems with similar error messages, impacted resources, or statuses for the impacted resource. — item shape: {OpsItemId: string}
  --status: string@status-completer # The OpsItem status. Status can be Open, In Progress, or Resolved. For more information, see Editing OpsItem details (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-working-with-OpsItems.html#OpsCenter-working-with-OpsItems-editing-details) in the Amazon Web Services Systems Manager User Guide.
  ops_item_id: string # The ID of the OpsItem.
  --title: string # A short heading that describes the nature of the OpsItem and the impacted resource.
  --category: string # Specify a new category for an OpsItem.
  --severity: string # Specify a new severity for an OpsItem.
  --actual-start-time: string # The time a runbook workflow started. Currently reported only for the OpsItem type /aws/changerequest. (format: date-time)
  --actual-end-time: string # The time a runbook workflow ended. Currently reported only for the OpsItem type /aws/changerequest. (format: date-time)
  --planned-start-time: string # The time specified in a change request for a runbook workflow to start. Currently supported only for the OpsItem type /aws/changerequest. (format: date-time)
  --planned-end-time: string # The time specified in a change request for a runbook workflow to end. Currently supported only for the OpsItem type /aws/changerequest. (format: date-time)
  --ops-item-arn: string # The OpsItem Amazon Resource Name (ARN).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.UpdateOpsItem"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: OperationalData, var: operational_data}, {name: OperationalDataToDelete, var: operational_data_to_delete}, {name: Notifications, var: notifications}, {name: Priority, var: priority}, {name: RelatedOpsItems, var: related_ops_items}, {name: Status, var: status}, {name: OpsItemId, var: ops_item_id}, {name: Title, var: title}, {name: Category, var: category}, {name: Severity, var: severity}, {name: ActualStartTime, var: actual_start_time}, {name: ActualEndTime, var: actual_end_time}, {name: PlannedStartTime, var: planned_start_time}, {name: PlannedEndTime, var: planned_end_time}, {name: OpsItemArn, var: ops_item_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, description: $description, operational_data: $operational_data, operational_data_to_delete: $operational_data_to_delete, notifications: $notifications, priority: $priority, related_ops_items: $related_ops_items, status: $status, ops_item_id: $ops_item_id, title: $title, category: $category, severity: $severity, actual_start_time: $actual_start_time, actual_end_time: $actual_end_time, planned_start_time: $planned_start_time, planned_end_time: $planned_end_time, ops_item_arn: $ops_item_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Amazon Web Services Systems Manager calls this API operation when you edit OpsMetadata in Application Manager.
#
# POST /
# Returns: record<OpsMetadataArn: string>
# operationId: UpdateOpsMetadata
export def "update-ops-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-134 # required
  ops_metadata_arn: string # The Amazon Resource Name (ARN) of the OpsMetadata Object to update.
  --metadata-to-update: record # Metadata to add to an OpsMetadata object.
  --keys-to-delete: list<string> # The metadata keys to delete from the OpsMetadata object.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.UpdateOpsMetadata"}]
    body: {content_type: "application/json", kind: json, fields: [{name: OpsMetadataArn, var: ops_metadata_arn}, {name: MetadataToUpdate, var: metadata_to_update}, {name: KeysToDelete, var: keys_to_delete}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ops_metadata_arn: $ops_metadata_arn, metadata_to_update: $metadata_to_update, keys_to_delete: $keys_to_delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies an existing patch baseline. Fields not specified in the request are left unchanged. For information about valid key-value pairs in PatchFilters for each supported operating system type, see PatchFilter.
#
# POST /
# Returns: record<BaselineId: string, Name: string, OperatingSystem: string, GlobalFilters: record<PatchFilters: list<record>>, ApprovalRules: record<PatchRules: list<record>>, ApprovedPatches: list<string>, ApprovedPatchesComplianceLevel: string, ApprovedPatchesEnableNonSecurity: bool, RejectedPatches: list<string>, RejectedPatchesAction: string, CreatedDate: string, ModifiedDate: string, Description: string, Sources: table<Name: string, Products: list, Configuration: string>>
# operationId: UpdatePatchBaseline
export def "update-patch-baseline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  baseline_id: string # The ID of the patch baseline to update.
  --name: string # The name of the patch baseline.
  --global-filters: record # A set of patch filters, typically used for approval rules. — shape: {PatchFilters: list}
  --approval-rules: record # A set of rules defining the approval rules for a patch baseline. — shape: {PatchRules: list}
  --approved-patches: list<string> # A list of explicitly approved patches for the baseline. For information about accepted formats for lists of approved patches and rejected patches, see About package name formats for approved and rejected patch lists (https://docs.aws.amazon.com/systems-manager/latest/userguide/patch-manager-approved-rejected-package-name-formats.html) in the Amazon Web Services Systems Manager User Guide.
  --approved-patches-compliance-level: string@approved-patches-compliance-level-completer # Assigns a new compliance severity level to an existing patch baseline.
  --approved-patches-enable-non-security: oneof<nothing, bool> # Indicates whether the list of approved patches includes non-security updates that should be applied to the managed nodes. The default value is false. Applies to Linux managed nodes only.
  --rejected-patches: list<string> # A list of explicitly rejected patches for the baseline. For information about accepted formats for lists of approved patches and rejected patches, see About package name formats for approved and rejected patch lists (https://docs.aws.amazon.com/systems-manager/latest/userguide/patch-manager-approved-rejected-package-name-formats.html) in the Amazon Web Services Systems Manager User Guide.
  --rejected-patches-action: string@rejected-patches-action-completer # The action for Patch Manager to take on patches included in the RejectedPackages list. ALLOW_AS_DEPENDENCY : A package in the Rejected patches list is installed only if it is a dependency of another package. It is considered compliant with the patch baseline, and its status is reported as InstalledOther. This is the default action if no option is specified. BLOCK : Packages in the RejectedPatches list, and packages that include them as dependencies, aren't installed under any circumstances. If a package was installed before it was added to the Rejected patches list, it is considered non-compliant with the patch baseline, and its status is reported as InstalledRejected.
  --description: string # A description of the patch baseline.
  --sources: list # Information about the patches to use to update the managed nodes, including target operating systems and source repositories. Applies to Linux managed nodes only. — item shape: {Name: string, Products: list<string>, Configuration: string}
  --replace: oneof<nothing, bool> # If True, then all fields that are required by the CreatePatchBaseline operation are also required for this API request. Optional fields that aren't specified are set to null.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.UpdatePatchBaseline"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BaselineId, var: baseline_id}, {name: Name, var: name}, {name: GlobalFilters, var: global_filters}, {name: ApprovalRules, var: approval_rules}, {name: ApprovedPatches, var: approved_patches}, {name: ApprovedPatchesComplianceLevel, var: approved_patches_compliance_level}, {name: ApprovedPatchesEnableNonSecurity, var: approved_patches_enable_non_security}, {name: RejectedPatches, var: rejected_patches}, {name: RejectedPatchesAction, var: rejected_patches_action}, {name: Description, var: description}, {name: Sources, var: sources}, {name: Replace, var: replace}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, baseline_id: $baseline_id, name: $name, global_filters: $global_filters, approval_rules: $approval_rules, approved_patches: $approved_patches, approved_patches_compliance_level: $approved_patches_compliance_level, approved_patches_enable_non_security: $approved_patches_enable_non_security, rejected_patches: $rejected_patches, rejected_patches_action: $rejected_patches_action, description: $description, sources: $sources, replace: $replace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a resource data sync. After you create a resource data sync for a Region, you can't change the account options for that sync. For example, if you create a sync in the us-east-2 (Ohio) Region and you choose the Include only the current account option, you can't edit that sync later and choose the Include all accounts from my Organizations configuration option. Instead, you must delete the first resource data sync, and create a new one. This API operation only supports a resource data sync that was created with a SyncFromSource SyncType.
#
# POST /
# Returns: record
# operationId: UpdateResourceDataSync
export def "update-resource-data-sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-136 # required
  sync_name: string # The name of the resource data sync you want to update.
  sync_type: string # The type of resource data sync. The supported SyncType is SyncFromSource.
  sync_source: record # Information about the source of the data included in the resource data sync. — shape: {SourceType: string, AwsOrganizationsSource?: record, SourceRegions: list<string>, IncludeFutureRegions?: bool, EnableAllOpsDataSources?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.UpdateResourceDataSync"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SyncName, var: sync_name}, {name: SyncType, var: sync_type}, {name: SyncSource, var: sync_source}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, sync_name: $sync_name, sync_type: $sync_type, sync_source: $sync_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ServiceSetting is an account-level setting for an Amazon Web Services service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an Amazon Web Services service charges money to the account based on feature or service usage, then the Amazon Web Services service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature. Services map a SettingId object to a setting value. Amazon Web Services services teams define the default value for a SettingId. You can't create a new SettingId, but you can overwrite the default value if you have the ssm:UpdateServiceSetting permission for the setting. Use the GetServiceSetting API operation to view the current value. Or, use the ResetServiceSetting to change the value back to the original value defined by the Amazon Web Services service team. Update the service setting for the account.
#
# POST /
# Returns: record
# operationId: UpdateServiceSetting
export def "update-service-setting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-137 # required
  setting_id: string # The Amazon Resource Name (ARN) of the service setting to update. For example, arn:aws:ssm:us-east-1:111122223333:servicesetting/ssm/parameter-store/high-throughput-enabled. The setting ID can be one of the following. /ssm/managed-instance/default-ec2-instance-management-role /ssm/automation/customer-script-log-destination /ssm/automation/customer-script-log-group-name /ssm/documents/console/public-sharing-permission /ssm/managed-instance/activation-tier /ssm/opsinsights/opscenter /ssm/parameter-store/default-parameter-tier /ssm/parameter-store/high-throughput-enabled Permissions to update the /ssm/managed-instance/default-ec2-instance-management-role setting should only be provided to administrators. Implement least privilege access when allowing individuals to configure or modify the Default Host Management Configuration.
  setting_value: string # The new value to specify for the service setting. The following list specifies the available values for each setting. /ssm/managed-instance/default-ec2-instance-management-role: The name of an IAM role /ssm/automation/customer-script-log-destination: CloudWatch /ssm/automation/customer-script-log-group-name: The name of an Amazon CloudWatch Logs log group /ssm/documents/console/public-sharing-permission: Enable or Disable /ssm/managed-instance/activation-tier: standard or advanced /ssm/opsinsights/opscenter: Enabled or Disabled /ssm/parameter-store/default-parameter-tier: Standard, Advanced, Intelligent-Tiering /ssm/parameter-store/high-throughput-enabled: true or false
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonSSM.UpdateServiceSetting"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SettingId, var: setting_id}, {name: SettingValue, var: setting_value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, setting_id: $setting_id, setting_value: $setting_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
