# Auto-generated client for Linode API v4.145.0
# Source: https://api.apis.guru/v2/specs/linode.com/4.145.0/openapi.json
# Auth: --token flag or $env.LINODE_API_TOKEN

const CLIENT = {
  base_url: "https://api.linode.com/v4"
  token_env_var: "LINODE_API_TOKEN"
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

def base-url-completer [] { ["https://api.linode.com/v4" "https://api.linode.com/v4beta"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "image/png"] }
def type-completer [] { ["credit_card"] }
def target-completer [] { ["primary" "secondary"] }
def cluster-size-completer [] { ["1" "3"] }
def replication-type-completer [] { ["asynch" "none" "semi_synch"] }
def replication-commit-type-completer [] { ["local" "off" "on" "remote_apply" "remote_write"] }
def status-completer [] { ["active" "disabled"] }
def type-completer-1 [] { ["master" "slave"] }
def tag-completer [] { ["iodef" "issue" "issuewild"] }
def type-completer-2 [] { ["A" "AAAA" "CAA" "CNAME" "MX" "NS" "PTR" "SRV" "TXT"] }
def run-level-completer [] { ["binbash" "default" "single"] }
def virt-mode-completer [] { ["fullvirt" "paravirt"] }
def filesystem-completer [] { ["ext3" "ext4" "initrd" "raw" "swap"] }
def type-completer-3 [] { ["ipv4"] }
def longview-subscription-completer [] { ["longview-10" "longview-100" "longview-3" "longview-40"] }
def service-type-completer [] { ["tcp" "url"] }
def status-completer-1 [] { ["disabled" "enabled"] }
def type-completer-4 [] { ["linode"] }
def inbound-policy-completer [] { ["ACCEPT" "DROP"] }
def outbound-policy-completer [] { ["ACCEPT" "DROP"] }
def prefix-length-completer [] { ["56" "64"] }
def algorithm-completer [] { ["leastconn" "roundrobin" "source"] }
def check-completer [] { ["connection" "http" "http_body" "none"] }
def cipher-suite-completer [] { ["legacy" "recommended"] }
def protocol-completer [] { ["http" "https" "tcp"] }
def proxy-protocol-completer [] { ["none" "v1" "v2"] }
def stickiness-completer [] { ["http_cookie" "none" "table"] }
def mode-completer [] { ["accept" "backup" "drain" "reject"] }
def acl-completer [] { ["authenticated-read" "private" "public-read" "public-read-write"] }
def acl-completer-1 [] { ["authenticated-read" "custom" "private" "public-read" "public-read-write"] }
def lish-auth-method-completer [] { ["disabled" "keys_only" "password_keys"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-account: "record<active_promotions: table<credit_monthly_cap: string, credit_remaining: string, description: string, expire_dt: string, image_url: string, service_type: string, summary: string, this_month_credit_remaining: string>, active_since: string, address_1: string, address_2: string, balance: float, balance_uninvoiced: float, billing_source: string, capabilities: list<string>, city: string, company: string, country: string, credit_card: record<expiry: string, last_four: string>, email: string, euuid: string, first_name: string, last_name: string, phone: string, state: string, tax_id: string, zip: string>"
    update-account: "record<active_promotions: table<credit_monthly_cap: string, credit_remaining: string, description: string, expire_dt: string, image_url: string, service_type: string, summary: string, this_month_credit_remaining: string>, active_since: string, address_1: string, address_2: string, balance: float, balance_uninvoiced: float, billing_source: string, capabilities: list<string>, city: string, company: string, country: string, credit_card: record<expiry: string, last_four: string>, email: string, euuid: string, first_name: string, last_name: string, phone: string, state: string, tax_id: string, zip: string>"
    cancel-account: "record<survey_link: string>"
    create-credit-card: "record"
    get-entity-transfers: "record<page: int, pages: int, results: int, data: table<created: string, entities: record, expiry: string, is_sender: bool, status: string, token: string, updated: string>>"
    create-entity-transfer: "record<created: string, entities: record<linodes: list<int>>, expiry: string, is_sender: bool, status: string, token: string, updated: string>"
    delete-entity-transfer: "record"
    get-entity-transfer: "record<created: string, entities: record<linodes: list<int>>, expiry: string, is_sender: bool, status: string, token: string, updated: string>"
    accept-entity-transfer: "record"
    get-events: "record<data: table<action: string, created: string, duration: float, entity: record, id: int, message: string, percent_complete: int, rate: string, read: bool, secondary_entity: record, seen: bool, status: string, time_remaining: string, username: string>, page: int, pages: int, results: int>"
    get-event: "record<action: string, created: string, duration: float, entity: record<id: int, label: string, type: string, url: string>, id: int, message: string, percent_complete: int, rate: string, read: bool, secondary_entity: record<id: string, label: string, type: string, url: string>, seen: bool, status: string, time_remaining: string, username: string>"
    event-read: "record"
    event-seen: "record"
    get-invoices: "record<data: table<date: string, id: int, label: string, subtotal: float, tax: float, tax_summary: list, total: float>, page: int, pages: int, results: int>"
    get-invoice: "record<date: string, id: int, label: string, subtotal: float, tax: float, tax_summary: table<name: string, tax: float>, total: float>"
    get-invoice-items: "record<data: table<amount: float, from: string, label: string, quantity: int, tax: float, to: string, total: float, type: string, unit_price: string>, page: int, pages: int, results: int>"
    get-account-logins: "record<data: table<datetime: string, id: int, ip: string, restricted: bool, username: string>, page: int, pages: int, results: int>"
    get-account-login: "record<datetime: string, id: int, ip: string, restricted: bool, username: string>"
    get-maintenance: "record<data: table<entity: record, reason: string, status: string, type: string, when: string>, page: int, pages: int, results: int>"
    get-notifications: "record<data: table<body: string, entity: record, label: string, message: string, severity: string, type: string, until: string, when: string>, page: int, pages: int, results: int>"
    get-clients: "record<data: table<id: string, label: string, public: bool, redirect_uri: string, secret: string, status: string, thumbnail_url: string>, page: int, pages: int, results: int>"
    create-client: "record<id: string, label: string, public: bool, redirect_uri: string, secret: string, status: string, thumbnail_url: string>"
    delete-client: "record"
    get-client: "record<id: string, label: string, public: bool, redirect_uri: string, secret: string, status: string, thumbnail_url: string>"
    update-client: "record<id: string, label: string, public: bool, redirect_uri: string, secret: string, status: string, thumbnail_url: string>"
    reset-client-secret: "record<id: string, label: string, public: bool, redirect_uri: string, secret: string, status: string, thumbnail_url: string>"
    get-client-thumbnail: "binary"
    set-client-thumbnail: "record"
    get-payment-methods: "record<data: table<created: string, data: any, id: int, is_default: bool, type: string>, page: int, pages: int, results: int>"
    create-payment-method: "record"
    delete-payment-method: "record"
    get-payment-method: "record<created: string, data: any, id: int, is_default: bool, type: string>"
    make-payment-method-default: "record"
    get-payments: "record<data: table<date: string, id: int, usd: int>, page: int, pages: int, results: int>"
    create-payment: "record<date: string, id: int, usd: int>"
    create-pay-pal-payment: "record<checkout_token: string, payment_id: string>"
    execute-pay-pal-payment: "record"
    get-payment: "record<date: string, id: int, usd: int>"
    create-promo-credit: "record<credit_monthly_cap: string, credit_remaining: string, description: string, expire_dt: string, image_url: string, service_type: string, summary: string, this_month_credit_remaining: string>"
    get-service-transfers: "record<data: table<created: string, entities: record, expiry: string, is_sender: bool, status: string, token: string, updated: string>, page: int, pages: int, results: int>"
    create-service-transfer: "record<created: string, entities: record<linodes: list<int>>, expiry: string, is_sender: bool, status: string, token: string, updated: string>"
    delete-service-transfer: "record"
    get-service-transfer: "record<created: string, entities: record<linodes: list<int>>, expiry: string, is_sender: bool, status: string, token: string, updated: string>"
    accept-service-transfer: "record"
    get-account-settings: "record<backups_enabled: bool, longview_subscription: string, managed: bool, network_helper: bool, object_storage: string>"
    update-account-settings: "record<backups_enabled: bool, longview_subscription: string, managed: bool, network_helper: bool, object_storage: string>"
    enable-account-managed: "record"
    get-transfer: "record<billable: int, quota: int, used: int>"
    get-users: "record<data: table<email: string, restricted: bool, ssh_keys: list, tfa_enabled: bool, username: string>, page: int, pages: int, results: int>"
    create-user: "record<email: string, restricted: bool, ssh_keys: list<string>, tfa_enabled: bool, username: string>"
    delete-user: "record"
    get-user: "record<email: string, restricted: bool, ssh_keys: list<string>, tfa_enabled: bool, username: string>"
    update-user: "record<email: string, restricted: bool, ssh_keys: list<string>, tfa_enabled: bool, username: string>"
    get-user-grants: "record<database: table<id: int, label: string, permissions: string>, domain: table<id: int, label: string, permissions: string>, global: record<account_access: string, add_databases: bool, add_domains: bool, add_firewalls: bool, add_images: bool, add_linodes: bool, add_longview: bool, add_nodebalancers: bool, add_stackscripts: bool, add_volumes: bool, cancel_account: bool, longview_subscription: bool>, image: table<id: int, label: string, permissions: string>, linode: table<id: int, label: string, permissions: string>, longview: table<id: int, label: string, permissions: string>, nodebalancer: table<id: int, label: string, permissions: string>, stackscript: table<id: int, label: string, permissions: string>, volume: table<id: int, label: string, permissions: string>>"
    update-user-grants: "record<database: table<id: int, label: string, permissions: string>, domain: table<id: int, label: string, permissions: string>, global: record<account_access: string, add_databases: bool, add_domains: bool, add_firewalls: bool, add_images: bool, add_linodes: bool, add_longview: bool, add_nodebalancers: bool, add_stackscripts: bool, add_volumes: bool, cancel_account: bool, longview_subscription: bool>, image: table<id: int, label: string, permissions: string>, linode: table<id: int, label: string, permissions: string>, longview: table<id: int, label: string, permissions: string>, nodebalancer: table<id: int, label: string, permissions: string>, stackscript: table<id: int, label: string, permissions: string>, volume: table<id: int, label: string, permissions: string>>"
    get-databases-engines: "record<page: int, pages: int, results: int, data: table<engine: string, id: string, version: string>>"
    get-databases-engine: "record<engine: string, id: string, version: string>"
    get-databases-instances: "record<page: int, pages: int, results: int, data: table<allow_list: list, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record, id: int, instance_uri: string, label: string, region: string, status: string, type: string, updated: string, updates: record, version: string>>"
    get-databases-mongo-db-instances: "record<page: int, pages: int, results: int, data: table<allow_list: list, cluster_size: int, compression_type: string, created: string, encrypted: bool, engine: string, hosts: record, id: int, label: string, peers: list, port: int, region: string, replica_set: string, ssl_connection: bool, status: string, storage_engine: string, type: string, updated: string, updates: record, version: string>>"
    delete-databases-mongo-db-instance: "record"
    get-databases-mongo-db-instance: "record<allow_list: list<string>, cluster_size: int, compression_type: string, created: string, encrypted: bool, engine: string, hosts: record<primary: string, secondary: string>, id: int, label: string, peers: list<string>, port: int, region: string, replica_set: string, ssl_connection: bool, status: string, storage_engine: string, type: string, updated: string, updates: record<day_of_week: int, duration: int, frequency: string, hour_of_day: int, week_of_month: int>, version: string>"
    put-databases-mongo-db-instance: "record<allow_list: list<string>, cluster_size: int, compression_type: string, created: string, encrypted: bool, engine: string, hosts: record<primary: string, secondary: string>, id: int, label: string, peers: list<string>, port: int, region: string, replica_set: string, ssl_connection: bool, status: string, storage_engine: string, type: string, updated: string, updates: record<day_of_week: int, duration: int, frequency: string, hour_of_day: int, week_of_month: int>, version: string>"
    get-databases-mongo-db-instance-backups: "record<page: int, pages: int, results: int, data: table<created: string, id: int, label: string, type: string>>"
    post-databases-mongo-db-instance-backup: "record"
    delete-database-mongo-db-instance-backup: "record"
    get-databases-mongo-db-instance-backup: "record<created: string, id: int, label: string, type: string>"
    post-databases-mongo-db-instance-backup-restore: "record"
    get-databases-mongo-db-instance-credentials: "record<password: string, username: string>"
    post-databases-mongo-db-instance-credentials-reset: "record"
    post-databases-mongo-db-instance-patch: "record"
    get-databases-mongo-db-instance-ssl: "record<ca_certificate: string>"
    get-databases-my-sql-instances: "record<page: int, pages: int, results: int, data: table<allow_list: list, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record, id: int, label: string, port: int, region: string, replication_type: string, ssl_connection: bool, status: string, type: string, updated: string, updates: record, version: string>>"
    post-databases-my-sql-instances: "record<allow_list: list<string>, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record<primary: string, secondary: string>, id: int, label: string, port: int, region: string, replication_type: string, ssl_connection: bool, status: string, type: string, updated: string, updates: record<day_of_week: int, duration: int, frequency: string, hour_of_day: int, week_of_month: int>, version: string>"
    delete-databases-my-sql-instance: "record"
    get-databases-my-sql-instance: "record<allow_list: list<string>, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record<primary: string, secondary: string>, id: int, label: string, port: int, region: string, replication_type: string, ssl_connection: bool, status: string, type: string, updated: string, updates: record<day_of_week: int, duration: int, frequency: string, hour_of_day: int, week_of_month: int>, version: string>"
    put-databases-my-sql-instance: "record<allow_list: list<string>, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record<primary: string, secondary: string>, id: int, label: string, port: int, region: string, replication_type: string, ssl_connection: bool, status: string, type: string, updated: string, updates: record<day_of_week: int, duration: int, frequency: string, hour_of_day: int, week_of_month: int>, version: string>"
    get-databases-my-sql-instance-backups: "record<page: int, pages: int, results: int, data: table<created: string, id: int, label: string, type: string>>"
    post-databases-my-sql-instance-backup: "record"
    delete-database-my-sql-instance-backup: "record"
    get-databases-my-sql-instance-backup: "record<created: string, id: int, label: string, type: string>"
    post-databases-my-sql-instance-backup-restore: "record"
    get-databases-my-sql-instance-credentials: "record<password: string, username: string>"
    post-databases-my-sql-instance-credentials-reset: "record"
    post-databases-my-sql-instance-patch: "record"
    get-databases-my-sql-instance-ssl: "record<ca_certificate: string>"
    get-databases-postgre-sql-instances: "record<page: int, pages: int, results: int, data: table<allow_list: list, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record, id: int, label: string, port: int, region: string, replication_commit_type: string, replication_type: string, ssl_connection: bool, status: string, type: string, updated: string, updates: record, version: string>>"
    post-databases-postgre-sql-instances: "record<allow_list: list<string>, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record<primary: string, secondary: string>, id: int, label: string, port: int, region: string, replication_commit_type: string, replication_type: string, ssl_connection: bool, status: string, type: string, updated: string, updates: record<day_of_week: int, duration: int, frequency: string, hour_of_day: int, week_of_month: int>, version: string>"
    delete-databases-postgre-sql-instance: "record"
    get-databases-postgre-sql-instance: "record<allow_list: list<string>, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record<primary: string, secondary: string>, id: int, label: string, port: int, region: string, replication_commit_type: string, replication_type: string, ssl_connection: bool, status: string, type: string, updated: string, updates: record<day_of_week: int, duration: int, frequency: string, hour_of_day: int, week_of_month: int>, version: string>"
    put-databases-postgre-sql-instance: "record<allow_list: list<string>, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record<primary: string, secondary: string>, id: int, label: string, port: int, region: string, replication_commit_type: string, replication_type: string, ssl_connection: bool, status: string, type: string, updated: string, updates: record<day_of_week: int, duration: int, frequency: string, hour_of_day: int, week_of_month: int>, version: string>"
    get-databases-postgre-sql-instance-backups: "record<page: int, pages: int, results: int, data: table<created: string, id: int, label: string, type: string>>"
    post-databases-postgre-sql-instance-backup: "record"
    delete-database-postgre-sql-instance-backup: "record"
    get-databases-postgre-sql-instance-backup: "record<created: string, id: int, label: string, type: string>"
    post-databases-postgre-sql-instance-backup-restore: "record"
    get-databases-postgre-sql-instance-credentials: "record<password: string, username: string>"
    post-databases-postgre-sql-instance-credentials-reset: "record"
    post-databases-postgre-sql-instance-patch: "record"
    get-databases-postgre-sql-instance-ssl: "record<ca_certificate: string>"
    get-databases-types: "record<page: int, pages: int, results: int, data: table<class: string, deprecated: bool, disk: int, engines: record, id: string, label: string, memory: int, vcpus: int>>"
    get-databases-type: "record<class: string, deprecated: bool, disk: int, engines: record<mongodb: list<record>, mysql: list<record>, postgresql: list<record>>, id: string, label: string, memory: int, vcpus: int>"
    get-domains: "record<data: table<axfr_ips: list, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list, ttl_sec: int, type: string>, page: int, pages: int, results: int>"
    create-domain: "record<axfr_ips: list<string>, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list<string>, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list<string>, ttl_sec: int, type: string>"
    import-domain: "record<axfr_ips: list<string>, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list<string>, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list<string>, ttl_sec: int, type: string>"
    delete-domain: "record"
    get-domain: "record<axfr_ips: list<string>, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list<string>, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list<string>, ttl_sec: int, type: string>"
    update-domain: "record<axfr_ips: list<string>, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list<string>, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list<string>, ttl_sec: int, type: string>"
    clone-domain: "record<axfr_ips: list<string>, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list<string>, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list<string>, ttl_sec: int, type: string>"
    get-domain-records: "record<data: table<created: string, id: int, name: string, port: int, priority: int, protocol: string, service: string, tag: string, target: string, ttl_sec: int, type: string, updated: string, weight: int>, page: int, pages: int, results: int>"
    create-domain-record: "record<created: string, id: int, name: string, port: int, priority: int, protocol: string, service: string, tag: string, target: string, ttl_sec: int, type: string, updated: string, weight: int>"
    delete-domain-record: "record"
    get-domain-record: "record<created: string, id: int, name: string, port: int, priority: int, protocol: string, service: string, tag: string, target: string, ttl_sec: int, type: string, updated: string, weight: int>"
    update-domain-record: "record<created: string, id: int, name: string, port: int, priority: int, protocol: string, service: string, tag: string, target: string, ttl_sec: int, type: string, updated: string, weight: int>"
    get-domain-zone: "record<zone_file: list<string>>"
    get-images: "record<data: table<created: string, created_by: string, deprecated: bool, description: string, eol: string, expiry: string, id: string, is_public: bool, label: string, size: int, status: string, type: string, updated: string, vendor: string>, page: int, pages: int, results: int>"
    create-image: "record<created: string, created_by: string, deprecated: bool, description: string, eol: string, expiry: string, id: string, is_public: bool, label: string, size: int, status: string, type: string, updated: string, vendor: string>"
    post-images-upload: "record<image: record<created: string, created_by: string, deprecated: bool, description: string, eol: string, expiry: string, id: string, is_public: bool, label: string, size: int, status: string, type: string, updated: string, vendor: string>, upload_to: string>"
    delete-image: "record"
    get-image: "record<created: string, created_by: string, deprecated: bool, description: string, eol: string, expiry: string, id: string, is_public: bool, label: string, size: int, status: string, type: string, updated: string, vendor: string>"
    update-image: "record<created: string, created_by: string, deprecated: bool, description: string, eol: string, expiry: string, id: string, is_public: bool, label: string, size: int, status: string, type: string, updated: string, vendor: string>"
    get-linode-instances: "record<data: table<alerts: record, backups: record, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: string, ipv4: list, ipv6: string, label: string, region: string, specs: record, status: string, tags: list, type: string, updated: string, watchdog_enabled: bool>, page: int, pages: int, results: int>"
    create-linode-instance: "record<alerts: record<cpu: int, io: int, network_in: int, network_out: int, transfer_quota: int>, backups: record<available: bool, enabled: bool, last_successful: string, schedule: record<day: string, window: string>>, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: string, ipv4: list<string>, ipv6: string, label: string, region: string, specs: record<disk: int, memory: int, transfer: int, vcpus: int>, status: string, tags: list<string>, type: string, updated: string, watchdog_enabled: bool>"
    delete-linode-instance: "record"
    get-linode-instance: "record<alerts: record<cpu: int, io: int, network_in: int, network_out: int, transfer_quota: int>, backups: record<available: bool, enabled: bool, last_successful: string, schedule: record<day: string, window: string>>, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: string, ipv4: list<string>, ipv6: string, label: string, region: string, specs: record<disk: int, memory: int, transfer: int, vcpus: int>, status: string, tags: list<string>, type: string, updated: string, watchdog_enabled: bool>"
    update-linode-instance: "record<alerts: record<cpu: int, io: int, network_in: int, network_out: int, transfer_quota: int>, backups: record<available: bool, enabled: bool, last_successful: string, schedule: record<day: string, window: string>>, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: string, ipv4: list<string>, ipv6: string, label: string, region: string, specs: record<disk: int, memory: int, transfer: int, vcpus: int>, status: string, tags: list<string>, type: string, updated: string, watchdog_enabled: bool>"
    get-backups: "record<automatic: table<available: bool, configs: list, created: string, disks: list, finished: string, id: int, label: string, status: string, type: string, updated: string>, snapshot: record<current: record<available: bool, configs: list, created: string, disks: list, finished: string, id: int, label: string, status: string, type: string, updated: string>, in_progress: record<available: bool, configs: list, created: string, disks: list, finished: string, id: int, label: string, status: string, type: string, updated: string>>>"
    create-snapshot: "record<available: bool, configs: list<string>, created: string, disks: table<filesystem: string, label: string, size: int>, finished: string, id: int, label: string, status: string, type: string, updated: string>"
    cancel-backups: "record"
    enable-backups: "record"
    get-backup: "record<available: bool, configs: list<string>, created: string, disks: table<filesystem: string, label: string, size: int>, finished: string, id: int, label: string, status: string, type: string, updated: string>"
    restore-backup: "record"
    boot-linode-instance: "record"
    clone-linode-instance: "record<alerts: record<cpu: int, io: int, network_in: int, network_out: int, transfer_quota: int>, backups: record<available: bool, enabled: bool, last_successful: string, schedule: record<day: string, window: string>>, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: string, ipv4: list<string>, ipv6: string, label: string, region: string, specs: record<disk: int, memory: int, transfer: int, vcpus: int>, status: string, tags: list<string>, type: string, updated: string, watchdog_enabled: bool>"
    get-linode-configs: "record<data: table<comments: string, devices: record, helpers: record, id: int, interfaces: list, kernel: string, label: string, memory_limit: int, root_device: string, run_level: string, virt_mode: string>, page: int, pages: int, results: int>"
    add-linode-config: "record<comments: string, devices: record<sda: record<disk_id: int, volume_id: int>, sdb: record<disk_id: int, volume_id: int>, sdc: record<disk_id: int, volume_id: int>, sdd: record<disk_id: int, volume_id: int>, sde: record<disk_id: int, volume_id: int>, sdf: record<disk_id: int, volume_id: int>, sdg: record<disk_id: int, volume_id: int>, sdh: record<disk_id: int, volume_id: int>>, helpers: record<devtmpfs_automount: bool, distro: bool, modules_dep: bool, network: bool, updatedb_disabled: bool>, id: int, interfaces: table<ipam_address: string, label: string, purpose: string>, kernel: string, label: string, memory_limit: int, root_device: string, run_level: string, virt_mode: string>"
    delete-linode-config: "record"
    get-linode-config: "record<comments: string, devices: record<sda: record<disk_id: int, volume_id: int>, sdb: record<disk_id: int, volume_id: int>, sdc: record<disk_id: int, volume_id: int>, sdd: record<disk_id: int, volume_id: int>, sde: record<disk_id: int, volume_id: int>, sdf: record<disk_id: int, volume_id: int>, sdg: record<disk_id: int, volume_id: int>, sdh: record<disk_id: int, volume_id: int>>, helpers: record<devtmpfs_automount: bool, distro: bool, modules_dep: bool, network: bool, updatedb_disabled: bool>, id: int, interfaces: table<ipam_address: string, label: string, purpose: string>, kernel: string, label: string, memory_limit: int, root_device: string, run_level: string, virt_mode: string>"
    update-linode-config: "record<comments: string, devices: record<sda: record<disk_id: int, volume_id: int>, sdb: record<disk_id: int, volume_id: int>, sdc: record<disk_id: int, volume_id: int>, sdd: record<disk_id: int, volume_id: int>, sde: record<disk_id: int, volume_id: int>, sdf: record<disk_id: int, volume_id: int>, sdg: record<disk_id: int, volume_id: int>, sdh: record<disk_id: int, volume_id: int>>, helpers: record<devtmpfs_automount: bool, distro: bool, modules_dep: bool, network: bool, updatedb_disabled: bool>, id: int, interfaces: table<ipam_address: string, label: string, purpose: string>, kernel: string, label: string, memory_limit: int, root_device: string, run_level: string, virt_mode: string>"
    get-linode-disks: "record<data: table<created: string, filesystem: string, id: int, label: string, size: int, status: string, updated: string>, page: int, pages: int, results: int>"
    add-linode-disk: "record<created: string, filesystem: string, id: int, label: string, size: int, status: string, updated: string>"
    delete-disk: "record"
    get-linode-disk: "record<created: string, filesystem: string, id: int, label: string, size: int, status: string, updated: string>"
    update-disk: "record<created: string, filesystem: string, id: int, label: string, size: int, status: string, updated: string>"
    clone-linode-disk: "record<created: string, filesystem: string, id: int, label: string, size: int, status: string, updated: string>"
    reset-disk-password: "record"
    resize-disk: "record"
    get-linode-firewalls: "record<data: table<created: string, id: int, label: string, rules: record, status: string, tags: list, updated: string>, page: int, pages: int, results: int>"
    get-linode-i-ps: "record<ipv4: record<private: list<record>, public: list<record>, reserved: list<record>, shared: list<record>>, ipv6: record<global: record<prefix: int, range: string, region: string, route_target: string>, link_local: record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>, slaac: record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>>>"
    add-linode-ip: "record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>"
    remove-linode-ip: "record"
    get-linode-ip: "record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>"
    update-linode-ip: "record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>"
    migrate-linode-instance: "record"
    mutate-linode-instance: "record"
    get-linode-node-balancers: "record<data: table<client_conn_throttle: int, created: string, hostname: string, id: int, ipv4: string, ipv6: string, label: string, region: string, tags: list, transfer: record, updated: string>, page: int, pages: int, results: int>"
    reset-linode-password: "record"
    reboot-linode-instance: "record"
    rebuild-linode-instance: "record<alerts: record<cpu: int, io: int, network_in: int, network_out: int, transfer_quota: int>, backups: record<available: bool, enabled: bool, last_successful: string, schedule: record<day: string, window: string>>, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: string, ipv4: list<string>, ipv6: string, label: string, region: string, specs: record<disk: int, memory: int, transfer: int, vcpus: int>, status: string, tags: list<string>, type: string, updated: string, watchdog_enabled: bool>"
    rescue-linode-instance: "record"
    resize-linode-instance: "record"
    shutdown-linode-instance: "record"
    get-linode-stats: "record<cpu: list<list<float>>, io: record<io: list<list>, swap: list<list>>, netv4: record<in: list<list>, out: list<list>, private_in: list<list>, private_out: list<list>>, netv6: record<in: list<list>, out: list<list>, private_in: list<list>, private_out: list<list>>, title: string>"
    get-linode-stats-by-year-month: "record<cpu: list<list<float>>, io: record<io: list<list>, swap: list<list>>, netv4: record<in: list<list>, out: list<list>, private_in: list<list>, private_out: list<list>>, netv6: record<in: list<list>, out: list<list>, private_in: list<list>, private_out: list<list>>, title: string>"
    get-linode-transfer: "record<billable: int, quota: int, used: int>"
    get-linode-transfer-by-year-month: "record<bytes_in: int, bytes_out: int, bytes_total: int>"
    get-linode-volumes: "record<data: table<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: string, size: int, status: string, tags: list, updated: string>, page: int, pages: int, results: int>"
    get-kernels: "record<data: table<architecture: string, built: string, deprecated: bool, id: string, kvm: bool, label: string, pvops: bool, version: string, xen: bool>, page: int, pages: int, results: int>"
    get-kernel: "record<architecture: string, built: string, deprecated: bool, id: string, kvm: bool, label: string, pvops: bool, version: string, xen: bool>"
    get-stack-scripts: "record<data: table<created: string, deployments_active: int, deployments_total: int, description: string, id: int, images: list, is_public: bool, label: string, mine: bool, rev_note: string, script: string, updated: string, user_defined_fields: list, user_gravatar_id: string, username: string>, page: int, pages: int, results: int>"
    add-stack-script: "record<created: string, deployments_active: int, deployments_total: int, description: string, id: int, images: list<string>, is_public: bool, label: string, mine: bool, rev_note: string, script: string, updated: string, user_defined_fields: table<default: string, example: string, label: string, manyOf: string, name: string, oneOf: string>, user_gravatar_id: string, username: string>"
    delete-stack-script: "record"
    get-stack-script: "record<created: string, deployments_active: int, deployments_total: int, description: string, id: int, images: list<string>, is_public: bool, label: string, mine: bool, rev_note: string, script: string, updated: string, user_defined_fields: table<default: string, example: string, label: string, manyOf: string, name: string, oneOf: string>, user_gravatar_id: string, username: string>"
    update-stack-script: "record<created: string, deployments_active: int, deployments_total: int, description: string, id: int, images: list<string>, is_public: bool, label: string, mine: bool, rev_note: string, script: string, updated: string, user_defined_fields: table<default: string, example: string, label: string, manyOf: string, name: string, oneOf: string>, user_gravatar_id: string, username: string>"
    get-linode-types: "record<data: table<addons: record, class: string, disk: int, gpus: int, id: string, label: string, memory: int, network_out: int, price: record, successor: string, transfer: int, vcpus: int>, page: int, pages: int, results: int>"
    get-linode-type: "record<addons: record<backups: record<price: record>>, class: string, disk: int, gpus: int, id: string, label: string, memory: int, network_out: int, price: record<hourly: int, monthly: int>, successor: string, transfer: int, vcpus: int>"
    get-lke-clusters: "record<data: table<control_plane: record, created: string, id: int, k8s_version: string, label: string, region: string, tags: list, updated: string>, page: int, pages: int, results: int>"
    create-lke-cluster: "record<control_plane: record<high_availability: bool>, created: string, id: int, k8s_version: string, label: string, region: string, tags: list<string>, updated: string>"
    delete-lke-cluster: "record"
    get-lke-cluster: "record<control_plane: record<high_availability: bool>, created: string, id: int, k8s_version: string, label: string, region: string, tags: list<string>, updated: string>"
    put-lke-cluster: "record<created: string, k8s_version: string, label: string, region: string, tags: list<string>, updated: string>"
    get-lke-cluster-api-endpoints: "record<data: table<endpoint: string>, page: int, pages: int, results: int>"
    get-lke-cluster-dashboard: "record<url: string>"
    delete-lke-cluster-kubeconfig: "record"
    get-lke-cluster-kubeconfig: "record<kubeconfig: string>"
    delete-lke-cluster-node: "record"
    get-lke-cluster-node: "record<id: string, instance_id: int, status: string>"
    post-lke-cluster-node-recycle: "record"
    get-lke-cluster-pools: "record<data: table<autoscaler: record, count: int, disks: list, id: int, nodes: list, tags: list, type: string>, page: int, pages: int, results: int>"
    post-lke-cluster-pools: "record<autoscaler: record<enabled: bool, max: int, min: int>, count: int, disks: table<size: int, type: string>, id: int, nodes: table<id: string, instance_id: string, status: string>, tags: list<string>, type: string>"
    delete-lke-node-pool: "record"
    get-lke-node-pool: "record<autoscaler: record<enabled: bool, max: int, min: int>, count: int, disks: table<size: int, type: string>, id: int, nodes: table<id: string, instance_id: string, status: string>, tags: list<string>, type: string>"
    put-lke-node-pool: "record<autoscaler: record<enabled: bool, max: int, min: int>, count: int, disks: table<size: int, type: string>, id: int, nodes: table<id: string, instance_id: string, status: string>, tags: list<string>, type: string>"
    post-lke-cluster-pool-recycle: "record"
    post-lke-cluster-recycle: "record"
    post-lke-cluster-regenerate: "record"
    post-lkec-service-token-delete: "record"
    get-lke-versions: "record<data: table<id: string>, page: int, pages: int, results: int>"
    get-lke-version: "record<id: string>"
    get-longview-clients: "record<data: table<api_key: string, apps: record, created: string, id: int, install_code: string, label: string, updated: string>, page: int, pages: int, results: int>"
    create-longview-client: "record<api_key: string, apps: record<apache: bool, mysql: bool, nginx: bool>, created: string, id: int, install_code: string, label: string, updated: string>"
    delete-longview-client: "record"
    get-longview-client: "record<api_key: string, apps: record<apache: bool, mysql: bool, nginx: bool>, created: string, id: int, install_code: string, label: string, updated: string>"
    update-longview-client: "record<api_key: string, apps: record<apache: bool, mysql: bool, nginx: bool>, created: string, id: int, install_code: string, label: string, updated: string>"
    get-longview-plan: "record<clients_included: int, id: string, label: string, price: record<hourly: float, monthly: float>>"
    update-longview-plan: "record<clients_included: int, id: string, label: string, price: record<hourly: float, monthly: float>>"
    get-longview-subscriptions: "record<data: table<clients_included: int, id: string, label: string, price: record>, page: int, pages: int, results: int>"
    get-longview-subscription: "record<clients_included: int, id: string, label: string, price: record<hourly: float, monthly: float>>"
    get-managed-contacts: "record<data: table<email: string, group: string, id: int, name: string, phone: record, updated: string>, page: int, pages: int, results: int>"
    create-managed-contact: "record<email: string, group: string, id: int, name: string, phone: record<primary: string, secondary: string>, updated: string>"
    delete-managed-contact: "record"
    get-managed-contact: "record<email: string, group: string, id: int, name: string, phone: record<primary: string, secondary: string>, updated: string>"
    update-managed-contact: "record<email: string, group: string, id: int, name: string, phone: record<primary: string, secondary: string>, updated: string>"
    get-managed-credentials: "record<data: table<id: int, label: string, last_decrypted: string>, page: int, pages: int, results: int>"
    create-managed-credential: "record<id: int, label: string, last_decrypted: string>"
    view-managed-ssh-key: "record<ssh_key: string>"
    get-managed-credential: "record<id: int, label: string, last_decrypted: string>"
    update-managed-credential: "record<id: int, label: string, last_decrypted: string>"
    delete-managed-credential: "record"
    update-managed-credential-username-password: "record"
    get-managed-issues: "record<data: table<created: string, entity: record, id: int, services: list>, page: int, pages: int, results: int>"
    get-managed-issue: "record<created: string, entity: record<id: int, label: string, type: string, url: string>, id: int, services: list<int>>"
    get-managed-linode-settings: "record<data: table<group: string, id: int, label: string, ssh: record>, page: int, pages: int, results: int>"
    get-managed-linode-setting: "record<group: string, id: int, label: string, ssh: record<access: bool, ip: string, port: int, user: string>>"
    update-managed-linode-setting: "record<group: string, id: int, label: string, ssh: record<access: bool, ip: string, port: int, user: string>>"
    get-managed-services: "record<data: table<address: string, body: string, consultation_group: string, created: string, credentials: list, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string>, page: int, pages: int, results: int>"
    create-managed-service: "record<address: string, body: string, consultation_group: string, created: string, credentials: list<int>, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string>"
    delete-managed-service: "record"
    get-managed-service: "record<address: string, body: string, consultation_group: string, created: string, credentials: list<int>, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string>"
    update-managed-service: "record<address: string, body: string, consultation_group: string, created: string, credentials: list<int>, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string>"
    disable-managed-service: "record<address: string, body: string, consultation_group: string, created: string, credentials: list<int>, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string>"
    enable-managed-service: "record<address: string, body: string, consultation_group: string, created: string, credentials: list<int>, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string>"
    get-managed-stats: "record<data: record>"
    get-firewalls: "record<data: table<created: string, id: int, label: string, rules: record, status: string, tags: list, updated: string>, page: int, pages: int, results: int>"
    create-firewalls: "record<created: string, id: int, label: string, rules: record<inbound: list<record>, inbound_policy: string, outbound: list<record>, outbound_policy: string>, status: string, tags: list<string>, updated: string>"
    delete-firewall: "record"
    get-firewall: "record<created: string, id: int, label: string, rules: record<inbound: list<record>, inbound_policy: string, outbound: list<record>, outbound_policy: string>, status: string, tags: list<string>, updated: string>"
    update-firewall: "record<created: string, id: int, label: string, rules: record<inbound: list<record>, inbound_policy: string, outbound: list<record>, outbound_policy: string>, status: string, tags: list<string>, updated: string>"
    get-firewall-devices: "record<data: table<created: string, entity: record, id: int, updated: string>, page: int, pages: int, results: int>"
    create-firewall-device: "record<created: string, entity: record<id: int, label: string, type: string, url: string>, id: int, updated: string>"
    delete-firewall-device: "record"
    get-firewall-device: "record<created: string, entity: record<id: int, label: string, type: string, url: string>, id: int, updated: string>"
    get-firewall-rules: "record<inbound: table<action: string, addresses: record, description: string, label: string, ports: string, protocol: string>, inbound_policy: string, outbound: table<action: string, addresses: record, description: string, label: string, ports: string, protocol: string>, outbound_policy: string>"
    update-firewall-rules: "record<inbound: table<action: string, addresses: record, description: string, label: string, ports: string, protocol: string>, inbound_policy: string, outbound: table<action: string, addresses: record, description: string, label: string, ports: string, protocol: string>, outbound_policy: string>"
    get-i-ps: "record<data: table<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>, page: int, pages: int, results: int>"
    allocate-ip: "record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>"
    assign-i-ps: "record"
    share-i-ps: "record"
    get-ip: "record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>"
    update-ip: "record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>"
    assign-i-pv4s: "record"
    share-i-pv4s: "record"
    get-i-pv6-pools: "record<data: table<prefix: int, range: string, region: string, route_target: string>, page: int, pages: int, results: int>"
    get-i-pv6-ranges: "record<data: table<prefix: int, range: string, region: string, route_target: string>, page: int, pages: int, results: int>"
    post-i-pv6-range: "record<range: string, route_target: string>"
    delete-i-pv6-range: "record"
    get-i-pv6-range: "record<is_bgp: bool, linodes: list<int>, prefix: int, range: string, region: string>"
    get-vla-ns: "record<data: table<created: string, label: string, linodes: list, region: string>, page: int, pages: int, results: int>"
    get-node-balancers: "record<data: table<client_conn_throttle: int, created: string, hostname: string, id: int, ipv4: string, ipv6: string, label: string, region: string, tags: list, transfer: record, updated: string>, page: int, pages: int, results: int>"
    create-node-balancer: "record<client_conn_throttle: int, created: string, hostname: string, id: int, ipv4: string, ipv6: string, label: string, region: string, tags: list<string>, transfer: record<in: float, out: float, total: float>, updated: string>"
    delete-node-balancer: "record"
    get-node-balancer: "record<client_conn_throttle: int, created: string, hostname: string, id: int, ipv4: string, ipv6: string, label: string, region: string, tags: list<string>, transfer: record<in: float, out: float, total: float>, updated: string>"
    update-node-balancer: "record<client_conn_throttle: int, created: string, hostname: string, id: int, ipv4: string, ipv6: string, label: string, region: string, tags: list<string>, transfer: record<in: float, out: float, total: float>, updated: string>"
    get-node-balancer-configs: "record<data: table<algorithm: string, check: string, check_attempts: int, check_body: string, check_interval: int, check_passive: bool, check_path: string, check_timeout: int, cipher_suite: string, id: int, nodebalancer_id: int, nodes_status: record, port: int, protocol: string, proxy_protocol: string, ssl_cert: string, ssl_commonname: string, ssl_fingerprint: string, ssl_key: string, stickiness: string>, page: int, pages: int, results: int>"
    create-node-balancer-config: "record<algorithm: string, check: string, check_attempts: int, check_body: string, check_interval: int, check_passive: bool, check_path: string, check_timeout: int, cipher_suite: string, id: int, nodebalancer_id: int, nodes_status: record<down: int, up: int>, port: int, protocol: string, proxy_protocol: string, ssl_cert: string, ssl_commonname: string, ssl_fingerprint: string, ssl_key: string, stickiness: string>"
    delete-node-balancer-config: "record"
    get-node-balancer-config: "record<algorithm: string, check: string, check_attempts: int, check_body: string, check_interval: int, check_passive: bool, check_path: string, check_timeout: int, cipher_suite: string, id: int, nodebalancer_id: int, nodes_status: record<down: int, up: int>, port: int, protocol: string, proxy_protocol: string, ssl_cert: string, ssl_commonname: string, ssl_fingerprint: string, ssl_key: string, stickiness: string>"
    update-node-balancer-config: "record<algorithm: string, check: string, check_attempts: int, check_body: string, check_interval: int, check_passive: bool, check_path: string, check_timeout: int, cipher_suite: string, id: int, nodebalancer_id: int, nodes_status: record<down: int, up: int>, port: int, protocol: string, proxy_protocol: string, ssl_cert: string, ssl_commonname: string, ssl_fingerprint: string, ssl_key: string, stickiness: string>"
    get-node-balancer-config-nodes: "record<data: table<address: string, config_id: int, id: int, label: string, mode: string, nodebalancer_id: int, status: string, weight: int>, page: int, pages: int, results: int>"
    create-node-balancer-node: "record<address: string, config_id: int, id: int, label: string, mode: string, nodebalancer_id: int, status: string, weight: int>"
    delete-node-balancer-config-node: "record"
    get-node-balancer-node: "record<address: string, config_id: int, id: int, label: string, mode: string, nodebalancer_id: int, status: string, weight: int>"
    update-node-balancer-node: "record<address: string, config_id: int, id: int, label: string, mode: string, nodebalancer_id: int, status: string, weight: int>"
    rebuild-node-balancer-config: "record<algorithm: string, check: string, check_attempts: int, check_body: string, check_interval: int, check_passive: bool, check_path: string, check_timeout: int, cipher_suite: string, id: int, nodebalancer_id: int, nodes_status: record<down: int, up: int>, port: int, protocol: string, proxy_protocol: string, ssl_cert: string, ssl_commonname: string, ssl_fingerprint: string, ssl_key: string, stickiness: string>"
    get-nodebalancers-node-balancer-id-stats: "record<data: record<connections: list<float>, traffic: record<in: list, out: list>>, title: string>"
    get-object-storage-buckets: "record<data: table<cluster: string, created: string, hostname: string, label: string, objects: int, size: int>, page: int, pages: int, results: int>"
    create-object-storage-bucket: "record<cluster: string, created: string, hostname: string, label: string, objects: int, size: int>"
    get-object-storage-bucketin-cluster: "record<data: table<cluster: string, created: string, hostname: string, label: string, objects: int, size: int>, page: int, pages: int, results: int>"
    delete-object-storage-bucket: "record"
    get-object-storage-bucket: "record<cluster: string, created: string, hostname: string, label: string, objects: int, size: int>"
    modify-object-storage-bucket-access: "record"
    update-object-storage-bucket-access: "record"
    view-object-storage-bucket-acl: "record<acl: string, acl_xml: string>"
    update-object-storage-bucket-acl: "record<acl: string, acl_xml: string>"
    get-object-storage-bucket-content: "record<data: table<etag: string, is_truncated: bool, last_modified: string, name: string, next_marker: string, owner: string, size: int>>"
    create-object-storage-object-url: "record<url: string>"
    delete-object-storage-ssl: "record"
    get-object-storage-ssl: "record<ssl: bool>"
    create-object-storage-ssl: "record<ssl: bool>"
    cancel-object-storage: "record"
    get-object-storage-clusters: "record<data: table<domain: string, id: string, region: string, static_site_domain: string, status: string>, page: int, pages: int, results: int>"
    get-object-storage-cluster: "record<domain: string, id: string, region: string, static_site_domain: string, status: string>"
    get-object-storage-keys: "record<data: table<access_key: string, bucket_access: list, id: int, label: string, limited: bool, secret_key: string>, page: int, pages: int, results: int>"
    create-object-storage-keys: "record<access_key: string, bucket_access: table<bucket_name: string, cluster: string, permissions: string>, id: int, label: string, limited: bool, secret_key: string>"
    delete-object-storage-key: "record"
    get-object-storage-key: "record<access_key: string, bucket_access: table<bucket_name: string, cluster: string, permissions: string>, id: int, label: string, limited: bool, secret_key: string>"
    update-object-storage-key: "record<access_key: string, bucket_access: table<bucket_name: string, cluster: string, permissions: string>, id: int, label: string, limited: bool, secret_key: string>"
    get-object-storage-transfer: "record<used: int>"
    get-profile: "record<authentication_type: string, authorized_keys: list<string>, email: string, email_notifications: bool, ip_whitelist_enabled: bool, lish_auth_method: string, referrals: record<code: string, completed: int, credit: int, pending: int, total: int, url: string>, restricted: bool, timezone: string, two_factor_auth: bool, uid: int, username: string, verified_phone_number: string>"
    update-profile: "record<authentication_type: string, authorized_keys: list<string>, email: string, email_notifications: bool, ip_whitelist_enabled: bool, lish_auth_method: string, referrals: record<code: string, completed: int, credit: int, pending: int, total: int, url: string>, restricted: bool, timezone: string, two_factor_auth: bool, uid: int, username: string, verified_phone_number: string>"
    get-profile-apps: "record<data: table<created: string, expiry: string, id: int, label: string, scopes: string, thumbnail_url: string, website: string>, page: int, pages: int, results: int>"
    delete-profile-app: "record"
    get-profile-app: "record<created: string, expiry: string, id: int, label: string, scopes: string, thumbnail_url: string, website: string>"
    get-devices: "record<data: table<created: string, expiry: string, id: int, last_authenticated: string, last_remote_addr: string, user_agent: string>, page: int, pages: int, results: int>"
    revoke-trusted-device: "record"
    get-trusted-device: "record<created: string, expiry: string, id: int, last_authenticated: string, last_remote_addr: string, user_agent: string>"
    get-profile-grants: "record<database: table<id: int, label: string, permissions: string>, domain: table<id: int, label: string, permissions: string>, global: record<account_access: string, add_databases: bool, add_domains: bool, add_firewalls: bool, add_images: bool, add_linodes: bool, add_longview: bool, add_nodebalancers: bool, add_stackscripts: bool, add_volumes: bool, cancel_account: bool, longview_subscription: bool>, image: table<id: int, label: string, permissions: string>, linode: table<id: int, label: string, permissions: string>, longview: table<id: int, label: string, permissions: string>, nodebalancer: table<id: int, label: string, permissions: string>, stackscript: table<id: int, label: string, permissions: string>, volume: table<id: int, label: string, permissions: string>>"
    get-profile-logins: "record<data: table<datetime: string, id: int, ip: string, restricted: bool, username: string>, page: int, pages: int, results: int>"
    get-profile-login: "record<datetime: string, id: int, ip: string, restricted: bool, username: string>"
    delete-profile-phone-number: "record"
    post-profile-phone-number: "record"
    post-profile-phone-number-verify: "record"
    get-user-preferences: "record"
    update-user-preferences: "record"
    get-security-questions: "record<security_questions: table<id: int, question: string, response: string>>"
    post-security-questions: "record<security_questions: table<question_id: int, response: string, security_question: string>>"
    get-ssh-keys: "record<data: table<created: string, id: int, label: string, ssh_key: string>, page: int, pages: int, results: int>"
    add-ssh-key: "record<created: string, id: int, label: string, ssh_key: string>"
    delete-ssh-key: "record"
    get-ssh-key: "record<created: string, id: int, label: string, ssh_key: string>"
    update-ssh-key: "record<created: string, id: int, label: string, ssh_key: string>"
    tfa-disable: "record"
    tfa-enable: "record<expiry: string, secret: string>"
    tfa-confirm: "record<scratch: string>"
    get-personal-access-tokens: "record<data: table<created: string, expiry: string, id: int, label: string, scopes: string, token: string>, page: int, pages: int, results: int>"
    create-personal-access-token: "record<created: string, expiry: string, id: int, label: string, scopes: string, token: string>"
    delete-personal-access-token: "record"
    get-personal-access-token: "record<created: string, expiry: string, id: int, label: string, scopes: string, token: string>"
    update-personal-access-token: "record<created: string, expiry: string, id: int, label: string, scopes: string, token: string>"
    get-regions: "record<data: table<capabilities: list, country: string, id: string, label: string, resolvers: record, status: string>, page: int, pages: int, results: int>"
    get-region: "record<capabilities: list<string>, country: string, id: string, label: string, resolvers: record<ipv4: string, ipv6: string>, status: string>"
    get-tickets: "record<data: table<attachments: list, closable: bool, closed: string, description: string, entity: record, gravatar_id: string, id: int, opened: string, opened_by: string, status: string, summary: string, updated: string, updated_by: string>, page: int, pages: int, results: int>"
    create-ticket: "record<attachments: list<string>, closable: bool, closed: string, description: string, entity: record<id: int, label: string, type: string, url: string>, gravatar_id: string, id: int, opened: string, opened_by: string, status: string, summary: string, updated: string, updated_by: string>"
    get-ticket: "record<attachments: list<string>, closable: bool, closed: string, description: string, entity: record<id: int, label: string, type: string, url: string>, gravatar_id: string, id: int, opened: string, opened_by: string, status: string, summary: string, updated: string, updated_by: string>"
    create-ticket-attachment: "record"
    close-ticket: "record"
    get-ticket-replies: "record<data: table<created: string, created_by: string, description: string, from_linode: bool, gravatar_id: string, id: int>, page: int, pages: int, results: int>"
    create-ticket-reply: "record<created: string, created_by: string, description: string, from_linode: bool, gravatar_id: string, id: int>"
    get-tags: "record<data: table<label: string>, page: int, pages: int, results: int>"
    create-tag: "record<label: string>"
    delete-tag: "record"
    get-tagged-objects: "record<data: table<data: any, type: string>, page: int, pages: int, results: int>"
    get-volumes: "record<data: table<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: string, size: int, status: string, tags: list, updated: string>, page: int, pages: int, results: int>"
    create-volume: "record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: string, size: int, status: string, tags: list<string>, updated: string>"
    delete-volume: "record"
    get-volume: "record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: string, size: int, status: string, tags: list<string>, updated: string>"
    update-volume: "record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: string, size: int, status: string, tags: list<string>, updated: string>"
    attach-volume: "record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: string, size: int, status: string, tags: list<string>, updated: string>"
    clone-volume: "record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: string, size: int, status: string, tags: list<string>, updated: string>"
    detach-volume: "record"
    resize-volume: "record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: string, size: int, status: string, tags: list<string>, updated: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-account" "update-account" "cancel-account" "create-credit-card" "get-entity-transfers" "create-entity-transfer" "delete-entity-transfer" "get-entity-transfer" "accept-entity-transfer" "get-events" "get-event" "event-read" "event-seen" "get-invoices" "get-invoice" "get-invoice-items" "get-account-logins" "get-account-login" "get-maintenance" "get-notifications" "get-clients" "create-client" "delete-client" "get-client" "update-client" "reset-client-secret" "get-client-thumbnail" "set-client-thumbnail" "get-payment-methods" "create-payment-method" "delete-payment-method" "get-payment-method" "make-payment-method-default" "get-payments" "create-payment" "create-pay-pal-payment" "execute-pay-pal-payment" "get-payment" "create-promo-credit" "get-service-transfers" "create-service-transfer" "delete-service-transfer" "get-service-transfer" "accept-service-transfer" "get-account-settings" "update-account-settings" "enable-account-managed" "get-transfer" "get-users" "create-user" "delete-user" "get-user" "update-user" "get-user-grants" "update-user-grants" "get-databases-engines" "get-databases-engine" "get-databases-instances" "get-databases-mongo-db-instances" "delete-databases-mongo-db-instance" "get-databases-mongo-db-instance" "put-databases-mongo-db-instance" "get-databases-mongo-db-instance-backups" "post-databases-mongo-db-instance-backup" "delete-database-mongo-db-instance-backup" "get-databases-mongo-db-instance-backup" "post-databases-mongo-db-instance-backup-restore" "get-databases-mongo-db-instance-credentials" "post-databases-mongo-db-instance-credentials-reset" "post-databases-mongo-db-instance-patch" "get-databases-mongo-db-instance-ssl" "get-databases-my-sql-instances" "post-databases-my-sql-instances" "delete-databases-my-sql-instance" "get-databases-my-sql-instance" "put-databases-my-sql-instance" "get-databases-my-sql-instance-backups" "post-databases-my-sql-instance-backup" "delete-database-my-sql-instance-backup" "get-databases-my-sql-instance-backup" "post-databases-my-sql-instance-backup-restore" "get-databases-my-sql-instance-credentials" "post-databases-my-sql-instance-credentials-reset" "post-databases-my-sql-instance-patch" "get-databases-my-sql-instance-ssl" "get-databases-postgre-sql-instances" "post-databases-postgre-sql-instances" "delete-databases-postgre-sql-instance" "get-databases-postgre-sql-instance" "put-databases-postgre-sql-instance" "get-databases-postgre-sql-instance-backups" "post-databases-postgre-sql-instance-backup" "delete-database-postgre-sql-instance-backup" "get-databases-postgre-sql-instance-backup" "post-databases-postgre-sql-instance-backup-restore" "get-databases-postgre-sql-instance-credentials" "post-databases-postgre-sql-instance-credentials-reset" "post-databases-postgre-sql-instance-patch" "get-databases-postgre-sql-instance-ssl" "get-databases-types" "get-databases-type" "get-domains" "create-domain" "import-domain" "delete-domain" "get-domain" "update-domain" "clone-domain" "get-domain-records" "create-domain-record" "delete-domain-record" "get-domain-record" "update-domain-record" "get-domain-zone" "get-images" "create-image" "post-images-upload" "delete-image" "get-image" "update-image" "get-linode-instances" "create-linode-instance" "delete-linode-instance" "get-linode-instance" "update-linode-instance" "get-backups" "create-snapshot" "cancel-backups" "enable-backups" "get-backup" "restore-backup" "boot-linode-instance" "clone-linode-instance" "get-linode-configs" "add-linode-config" "delete-linode-config" "get-linode-config" "update-linode-config" "get-linode-disks" "add-linode-disk" "delete-disk" "get-linode-disk" "update-disk" "clone-linode-disk" "reset-disk-password" "resize-disk" "get-linode-firewalls" "get-linode-i-ps" "add-linode-ip" "remove-linode-ip" "get-linode-ip" "update-linode-ip" "migrate-linode-instance" "mutate-linode-instance" "get-linode-node-balancers" "reset-linode-password" "reboot-linode-instance" "rebuild-linode-instance" "rescue-linode-instance" "resize-linode-instance" "shutdown-linode-instance" "get-linode-stats" "get-linode-stats-by-year-month" "get-linode-transfer" "get-linode-transfer-by-year-month" "get-linode-volumes" "get-kernels" "get-kernel" "get-stack-scripts" "add-stack-script" "delete-stack-script" "get-stack-script" "update-stack-script" "get-linode-types" "get-linode-type" "get-lke-clusters" "create-lke-cluster" "delete-lke-cluster" "get-lke-cluster" "put-lke-cluster" "get-lke-cluster-api-endpoints" "get-lke-cluster-dashboard" "delete-lke-cluster-kubeconfig" "get-lke-cluster-kubeconfig" "delete-lke-cluster-node" "get-lke-cluster-node" "post-lke-cluster-node-recycle" "get-lke-cluster-pools" "post-lke-cluster-pools" "delete-lke-node-pool" "get-lke-node-pool" "put-lke-node-pool" "post-lke-cluster-pool-recycle" "post-lke-cluster-recycle" "post-lke-cluster-regenerate" "post-lkec-service-token-delete" "get-lke-versions" "get-lke-version" "get-longview-clients" "create-longview-client" "delete-longview-client" "get-longview-client" "update-longview-client" "get-longview-plan" "update-longview-plan" "get-longview-subscriptions" "get-longview-subscription" "get-managed-contacts" "create-managed-contact" "delete-managed-contact" "get-managed-contact" "update-managed-contact" "get-managed-credentials" "create-managed-credential" "view-managed-ssh-key" "get-managed-credential" "update-managed-credential" "delete-managed-credential" "update-managed-credential-username-password" "get-managed-issues" "get-managed-issue" "get-managed-linode-settings" "get-managed-linode-setting" "update-managed-linode-setting" "get-managed-services" "create-managed-service" "delete-managed-service" "get-managed-service" "update-managed-service" "disable-managed-service" "enable-managed-service" "get-managed-stats" "get-firewalls" "create-firewalls" "delete-firewall" "get-firewall" "update-firewall" "get-firewall-devices" "create-firewall-device" "delete-firewall-device" "get-firewall-device" "get-firewall-rules" "update-firewall-rules" "get-i-ps" "allocate-ip" "assign-i-ps" "share-i-ps" "get-ip" "update-ip" "assign-i-pv4s" "share-i-pv4s" "get-i-pv6-pools" "get-i-pv6-ranges" "post-i-pv6-range" "delete-i-pv6-range" "get-i-pv6-range" "get-vla-ns" "get-node-balancers" "create-node-balancer" "delete-node-balancer" "get-node-balancer" "update-node-balancer" "get-node-balancer-configs" "create-node-balancer-config" "delete-node-balancer-config" "get-node-balancer-config" "update-node-balancer-config" "get-node-balancer-config-nodes" "create-node-balancer-node" "delete-node-balancer-config-node" "get-node-balancer-node" "update-node-balancer-node" "rebuild-node-balancer-config" "get-nodebalancers-node-balancer-id-stats" "get-object-storage-buckets" "create-object-storage-bucket" "get-object-storage-bucketin-cluster" "delete-object-storage-bucket" "get-object-storage-bucket" "modify-object-storage-bucket-access" "update-object-storage-bucket-access" "view-object-storage-bucket-acl" "update-object-storage-bucket-acl" "get-object-storage-bucket-content" "create-object-storage-object-url" "delete-object-storage-ssl" "get-object-storage-ssl" "create-object-storage-ssl" "cancel-object-storage" "get-object-storage-clusters" "get-object-storage-cluster" "get-object-storage-keys" "create-object-storage-keys" "delete-object-storage-key" "get-object-storage-key" "update-object-storage-key" "get-object-storage-transfer" "get-profile" "update-profile" "get-profile-apps" "delete-profile-app" "get-profile-app" "get-devices" "revoke-trusted-device" "get-trusted-device" "get-profile-grants" "get-profile-logins" "get-profile-login" "delete-profile-phone-number" "post-profile-phone-number" "post-profile-phone-number-verify" "get-user-preferences" "update-user-preferences" "get-security-questions" "post-security-questions" "get-ssh-keys" "add-ssh-key" "delete-ssh-key" "get-ssh-key" "update-ssh-key" "tfa-disable" "tfa-enable" "tfa-confirm" "get-personal-access-tokens" "create-personal-access-token" "delete-personal-access-token" "get-personal-access-token" "update-personal-access-token" "get-regions" "get-region" "get-tickets" "create-ticket" "get-ticket" "create-ticket-attachment" "close-ticket" "get-ticket-replies" "create-ticket-reply" "get-tags" "create-tag" "delete-tag" "get-tagged-objects" "get-volumes" "create-volume" "delete-volume" "get-volume" "update-volume" "attach-volume" "clone-volume" "detach-volume" "resize-volume" "commands"] | sort) } | get name | first)
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

# Account View
#
# GET /account
# Returns: record<active_promotions: table<credit_monthly_cap: string, credit_remaining: string, description: string, expire_dt: string, image_url: string, service_type: string, summary: string, this_month_credit_remaining: string>, active_since: string, address_1: string, address_2: string, balance: float, balance_uninvoiced: float, billing_source: string, capabilities: list<string>, city: string, company: string, country: string, credit_card: record<expiry: string, last_four: string>, email: string, euuid: string, first_name: string, last_name: string, phone: string, state: string, tax_id: string, zip: string>
# operationId: getAccount
export def "get-account" [
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
    path: "/account"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Account Update
#
# PUT /account
# Returns: record<active_promotions: table<credit_monthly_cap: string, credit_remaining: string, description: string, expire_dt: string, image_url: string, service_type: string, summary: string, this_month_credit_remaining: string>, active_since: string, address_1: string, address_2: string, balance: float, balance_uninvoiced: float, billing_source: string, capabilities: list<string>, city: string, company: string, country: string, credit_card: record<expiry: string, last_four: string>, email: string, euuid: string, first_name: string, last_name: string, phone: string, state: string, tax_id: string, zip: string>
# operationId: updateAccount
export def "update-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-1: string # First line of this Account's billing address. (e.g. 123 Main Street)
  --address-2: string # Second line of this Account's billing address. (e.g. Suite A)
  --city: string # The city for this Account's billing address. (e.g. Philadelphia)
  --company: string # The company name associated with this Account. (e.g. Linode LLC)
  --country: string # The two-letter ISO 3166 country code of this Account's billing address. (e.g. US)
  --email: string # The email address of the person associated with this Account. (e.g. john.smith@linode.com)
  --first-name: string # The first name of the person associated with this Account. (e.g. John)
  --last-name: string # The last name of the person associated with this Account. (e.g. Smith)
  --phone: string # The phone number associated with this Account. (e.g. 215-555-1212)
  --state: string # If billing address is in the United States (US) or Canada (CA), only the two-letter ISO 3166 State or Province code are accepted. If entering a US military address, state abbreviations (AA, AE, AP) should be entered. If the address is outside the US or CA, this is the Province associated with the Account's billing address. (e.g. PA)
  --tax-id: string # The tax identification number associated with this Account, for tax calculations in some countries. If you do not live in a country that collects tax, this should be an empty string (`""`). (e.g. ATU99999999)
  --zip: string # The zip code of this Account's billing address. The following restrictions apply: - May only consist of letters, numbers, spaces, and hyphens. - Must not contain more than 9 letter or number characters. (e.g. 19102-1234)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account"
    body: {content_type: "application/json", kind: json, fields: [{name: address_1, var: address_1}, {name: address_2, var: address_2}, {name: city, var: city}, {name: company, var: company}, {name: country, var: country}, {name: email, var: email}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: phone, var: phone}, {name: state, var: state}, {name: tax_id, var: tax_id}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address_1: $address_1, address_2: $address_2, city: $city, company: $company, country: $country, email: $email, first_name: $first_name, last_name: $last_name, phone: $phone, state: $state, tax_id: $tax_id, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Account Cancel
#
# POST /account/cancel
# Returns: record<survey_link: string>
# operationId: cancelAccount
export def "cancel-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comments: string # Any reason for cancelling the account, and any other comments you might have about your Linode service. (e.g. I'm consolidating multiple accounts into one.)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/cancel"
    body: {content_type: "application/json", kind: json, fields: [{name: comments, var: comments}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comments: $comments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Credit Card Add/Edit
#
# POST /account/credit-card
# DEPRECATED
# Returns: record
# operationId: createCreditCard
@deprecated
export def "create-credit-card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  card_number: string # Your credit card number. No spaces or dashes allowed. (format: digits, e.g. 4111111111111111)
  cvv: string # CVV (Card Verification Value) of the credit card, typically found on the back of the card. (format: digits, e.g. 123)
  expiry_month: int # A value from 1-12 representing the expiration month of your credit card. * 1 = January * 2 = February * 3 = March * Etc. (e.g. 12)
  expiry_year: int # A four-digit integer representing the expiration year of your credit card. The combination of `expiry_month` and `expiry_year` must result in a month/year combination of the current month or in the future. An expiration date set in the past is invalid. (e.g. 2020)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/credit-card"
    body: {content_type: "application/json", kind: json, fields: [{name: card_number, var: card_number}, {name: cvv, var: cvv}, {name: expiry_month, var: expiry_month}, {name: expiry_year, var: expiry_year}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_number: $card_number, cvv: $cvv, expiry_month: $expiry_month, expiry_year: $expiry_year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Entity Transfers List
#
# GET /account/entity-transfers
# DEPRECATED
# Returns: record<page: int, pages: int, results: int, data: table<created: string, entities: record, expiry: string, is_sender: bool, status: string, token: string, updated: string>>
# operationId: getEntityTransfers
@deprecated
export def "get-entity-transfers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/entity-transfers"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Entity Transfer Create
#
# POST /account/entity-transfers
# DEPRECATED
# Returns: record<created: string, entities: record<linodes: list<int>>, expiry: string, is_sender: bool, status: string, token: string, updated: string>
# operationId: createEntityTransfer
@deprecated
export def "create-entity-transfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  entities: record # A collection of the entities to include in this transfer request, separated by type. — shape: {linodes?: list<int>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/entity-transfers"
    body: {content_type: "application/json", kind: json, fields: [{name: entities, var: entities}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    entities: $entities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Entity Transfer Cancel
#
# DELETE /account/entity-transfers/{token}
# DEPRECATED
# Returns: record
# operationId: deleteEntityTransfer
@deprecated
export def "delete-entity-transfer" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/account/entity-transfers/{token}"
    path_params: [{name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Entity Transfer View
#
# GET /account/entity-transfers/{token}
# DEPRECATED
# Returns: record<created: string, entities: record<linodes: list<int>>, expiry: string, is_sender: bool, status: string, token: string, updated: string>
# operationId: getEntityTransfer
@deprecated
export def "get-entity-transfer" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/entity-transfers/{token}"
    path_params: [{name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Entity Transfer Accept
#
# POST /account/entity-transfers/{token}/accept
# DEPRECATED
# Returns: record
# operationId: acceptEntityTransfer
@deprecated
export def "accept-entity-transfer" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/account/entity-transfers/{token}/accept"
    path_params: [{name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Events List
#
# GET /account/events
# Returns: record<data: table<action: string, created: string, duration: float, entity: record, id: int, message: string, percent_complete: int, rate: string, read: bool, secondary_entity: record, seen: bool, status: string, time_remaining: string, username: string>, page: int, pages: int, results: int>
# operationId: getEvents
export def "get-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/events"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Event View
#
# GET /account/events/{eventId}
# Returns: record<action: string, created: string, duration: float, entity: record<id: int, label: string, type: string, url: string>, id: int, message: string, percent_complete: int, rate: string, read: bool, secondary_entity: record<id: string, label: string, type: string, url: string>, seen: bool, status: string, time_remaining: string, username: string>
# operationId: getEvent
export def "get-event" [
  event_id: int
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
    path: "/account/events/{eventId}"
    path_params: [{name: eventId, var: event_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event_id: $event_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Event Mark as Read
#
# POST /account/events/{eventId}/read
# Returns: record
# operationId: eventRead
export def "event-read" [
  event_id: int
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
    method: post
    path: "/account/events/{eventId}/read"
    path_params: [{name: eventId, var: event_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event_id: $event_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Event Mark as Seen
#
# POST /account/events/{eventId}/seen
# Returns: record
# operationId: eventSeen
export def "event-seen" [
  event_id: int
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
    method: post
    path: "/account/events/{eventId}/seen"
    path_params: [{name: eventId, var: event_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event_id: $event_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invoices List
#
# GET /account/invoices
# Returns: record<data: table<date: string, id: int, label: string, subtotal: float, tax: float, tax_summary: list, total: float>, page: int, pages: int, results: int>
# operationId: getInvoices
export def "get-invoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/invoices"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invoice View
#
# GET /account/invoices/{invoiceId}
# Returns: record<date: string, id: int, label: string, subtotal: float, tax: float, tax_summary: table<name: string, tax: float>, total: float>
# operationId: getInvoice
export def "get-invoice" [
  invoice_id: int
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
    path: "/account/invoices/{invoiceId}"
    path_params: [{name: invoiceId, var: invoice_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invoice Items List
#
# GET /account/invoices/{invoiceId}/items
# Returns: record<data: table<amount: float, from: string, label: string, quantity: int, tax: float, to: string, total: float, type: string, unit_price: string>, page: int, pages: int, results: int>
# operationId: getInvoiceItems
export def "get-invoice-items" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/invoices/{invoiceId}/items"
    path_params: [{name: invoiceId, var: invoice_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User Logins List All
#
# GET /account/logins
# Returns: record<data: table<datetime: string, id: int, ip: string, restricted: bool, username: string>, page: int, pages: int, results: int>
# operationId: getAccountLogins
export def "get-account-logins" [
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
    path: "/account/logins"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Login View
#
# GET /account/logins/{loginId}
# Returns: record<datetime: string, id: int, ip: string, restricted: bool, username: string>
# operationId: getAccountLogin
export def "get-account-login" [
  login_id: int
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
    path: "/account/logins/{loginId}"
    path_params: [{name: loginId, var: login_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login_id: $login_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Maintenance List
#
# GET /account/maintenance
# Returns: record<data: table<entity: record, reason: string, status: string, type: string, when: string>, page: int, pages: int, results: int>
# operationId: getMaintenance
export def "get-maintenance" [
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
    path: "/account/maintenance"
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Notifications List
#
# GET /account/notifications
# Returns: record<data: table<body: string, entity: record, label: string, message: string, severity: string, type: string, until: string, when: string>, page: int, pages: int, results: int>
# operationId: getNotifications
export def "get-notifications" [
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
    path: "/account/notifications"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OAuth Clients List
#
# GET /account/oauth-clients
# Returns: record<data: table<id: string, label: string, public: bool, redirect_uri: string, secret: string, status: string, thumbnail_url: string>, page: int, pages: int, results: int>
# operationId: getClients
export def "get-clients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/oauth-clients"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OAuth Client Create
#
# POST /account/oauth-clients
# Returns: record<id: string, label: string, public: bool, redirect_uri: string, secret: string, status: string, thumbnail_url: string>
# operationId: createClient
export def "create-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string # The name of this application. This will be presented to users when they are asked to grant it access to their Account. (e.g. Test_Client_1)
  --public: oneof<nothing, bool> # If this is a public or private OAuth Client. Public clients have a slightly different authentication workflow than private clients. See the OAuth spec (https://oauth.net/2/) for more details. (default: false, e.g. false)
  redirect_uri: string # The location a successful log in from https://login.linode.com (https://login.linode.com) should be redirected to for this client. The receiver of this redirect should be ready to accept an OAuth exchange code and finish the OAuth exchange. (format: url, e.g. https://example.org/oauth/callback)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/oauth-clients"
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}, {name: public, var: public}, {name: redirect_uri, var: redirect_uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    label: $label, public: $public, redirect_uri: $redirect_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OAuth Client Delete
#
# DELETE /account/oauth-clients/{clientId}
# Returns: record
# operationId: deleteClient
export def "delete-client" [
  client_id: string
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
    path: "/account/oauth-clients/{clientId}"
    path_params: [{name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OAuth Client View
#
# GET /account/oauth-clients/{clientId}
# Returns: record<id: string, label: string, public: bool, redirect_uri: string, secret: string, status: string, thumbnail_url: string>
# operationId: getClient
export def "get-client" [
  client_id: string
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
    path: "/account/oauth-clients/{clientId}"
    path_params: [{name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OAuth Client Update
#
# PUT /account/oauth-clients/{clientId}
# Returns: record<id: string, label: string, public: bool, redirect_uri: string, secret: string, status: string, thumbnail_url: string>
# operationId: updateClient
export def "update-client" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # The name of this application. This will be presented to users when they are asked to grant it access to their Account. (e.g. Test_Client_1)
  --public: oneof<nothing, bool> # If this is a public or private OAuth Client. Public clients have a slightly different authentication workflow than private clients. See the OAuth spec (https://oauth.net/2/) for more details. (default: false, e.g. false)
  --redirect-uri: string # The location a successful log in from https://login.linode.com (https://login.linode.com) should be redirected to for this client. The receiver of this redirect should be ready to accept an OAuth exchange code and finish the OAuth exchange. (format: url, e.g. https://example.org/oauth/callback)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/oauth-clients/{clientId}"
    path_params: [{name: clientId, var: client_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}, {name: public, var: public}, {name: redirect_uri, var: redirect_uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, label: $label, public: $public, redirect_uri: $redirect_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OAuth Client Secret Reset
#
# POST /account/oauth-clients/{clientId}/reset-secret
# Returns: record<id: string, label: string, public: bool, redirect_uri: string, secret: string, status: string, thumbnail_url: string>
# operationId: resetClientSecret
export def "reset-client-secret" [
  client_id: string
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
    method: post
    path: "/account/oauth-clients/{clientId}/reset-secret"
    path_params: [{name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OAuth Client Thumbnail View
#
# GET /account/oauth-clients/{clientId}/thumbnail
# Returns: binary
# operationId: getClientThumbnail
export def "get-client-thumbnail" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: get
    path: "/account/oauth-clients/{clientId}/thumbnail"
    path_params: [{name: clientId, var: client_id}]
    accept: ["image/png", "application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# OAuth Client Thumbnail Update
#
# PUT /account/oauth-clients/{clientId}/thumbnail
# Returns: record
# operationId: setClientThumbnail
export def "set-client-thumbnail" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/oauth-clients/{clientId}/thumbnail"
    path_params: [{name: clientId, var: client_id}]
    body: {content_type: "image/png", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Payment Methods List
#
# GET /account/payment-methods
# Returns: record<data: table<created: string, data: any, id: int, is_default: bool, type: string>, page: int, pages: int, results: int>
# operationId: getPaymentMethods
export def "get-payment-methods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/payment-methods"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Payment Method Add
#
# POST /account/payment-methods
# Returns: record
# operationId: createPaymentMethod
export def "create-payment-method" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # An object representing the credit card information you have on file with Linode to make Payments against your Account. — shape: {card_number: string, cvv: string, expiry_month: int, expiry_year: int}
  --is-default: oneof<nothing, bool> # Whether this Payment Method is the default method for automatically processing service charges. (e.g. true)
  type: string@type-completer # The type of Payment Method. Alternative Payment Methods including Google Pay and PayPal can be added using the Cloud Manager. See the [Manage Payment Methods](/docs/products/platform/billing/guides/payment-methods/) guide for details and instructions. (e.g. credit_card)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/payment-methods"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: is_default, var: is_default, required: true}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    data: $data, is_default: $is_default, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Payment Method Delete
#
# DELETE /account/payment-methods/{paymentMethodId}
# Returns: record
# operationId: deletePaymentMethod
export def "delete-payment-method" [
  payment_method_id: int
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
    path: "/account/payment-methods/{paymentMethodId}"
    path_params: [{name: paymentMethodId, var: payment_method_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_method_id: $payment_method_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Payment Method View
#
# GET /account/payment-methods/{paymentMethodId}
# Returns: record<created: string, data: any, id: int, is_default: bool, type: string>
# operationId: getPaymentMethod
export def "get-payment-method" [
  payment_method_id: int
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
    path: "/account/payment-methods/{paymentMethodId}"
    path_params: [{name: paymentMethodId, var: payment_method_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    payment_method_id: $payment_method_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Payment Method Make Default
#
# POST /account/payment-methods/{paymentMethodId}/make-default
# Returns: record
# operationId: makePaymentMethodDefault
export def "make-payment-method-default" [
  payment_method_id: int
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
    method: post
    path: "/account/payment-methods/{paymentMethodId}/make-default"
    path_params: [{name: paymentMethodId, var: payment_method_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    payment_method_id: $payment_method_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Payments List
#
# GET /account/payments
# Returns: record<data: table<date: string, id: int, usd: int>, page: int, pages: int, results: int>
# operationId: getPayments
export def "get-payments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/payments"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Payment Make
#
# POST /account/payments
# Returns: record<date: string, id: int, usd: int>
# operationId: createPayment
export def "create-payment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cvv: string # CVV (Card Verification Value) of the credit card to be used for the Payment. Required if paying by credit card. (e.g. 123)
  --payment-method-id: int # The ID of the Payment Method to apply to the Payment. (e.g. 123)
  usd: string # The amount in US Dollars of the Payment. * Can begin with or without `$`. * Commas (`,`) are not accepted. * Must end with a decimal expression, such as `.00` or `.99`. * Minimum: `$5.00` or the Account balance, whichever is lower. * Maximum: `$2000.00` or the Account balance up to `$50000.00`, whichever is greater. (e.g. $120.50)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/payments"
    body: {content_type: "application/json", kind: json, fields: [{name: cvv, var: cvv}, {name: payment_method_id, var: payment_method_id}, {name: usd, var: usd}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    cvv: $cvv, payment_method_id: $payment_method_id, usd: $usd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PayPal Payment Stage
#
# POST /account/payments/paypal
# DEPRECATED
# Returns: record<checkout_token: string, payment_id: string>
# operationId: createPayPalPayment
@deprecated
export def "create-pay-pal-payment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  cancel_url: string # The URL to have PayPal redirect to when Payment is cancelled. (e.g. https://example.org)
  redirect_url: string # The URL to have PayPal redirect to when Payment is approved. (e.g. https://example.org)
  usd: string # The payment amount in USD. Minimum accepted value of $5 USD. Maximum accepted value of $500 USD or credit card payment limit; whichever value is highest. PayPal's maximum transaction limit is $10,000 USD. (e.g. 120.50)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/payments/paypal"
    body: {content_type: "application/json", kind: json, fields: [{name: cancel_url, var: cancel_url}, {name: redirect_url, var: redirect_url}, {name: usd, var: usd}]}
    accept: ["application/json"]
    ok: [200, 299]
    auth: bearer
  } {
    cancel_url: $cancel_url, redirect_url: $redirect_url, usd: $usd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Staged/Approved PayPal Payment Execute
#
# POST /account/payments/paypal/execute
# DEPRECATED
# Returns: record
# operationId: executePayPalPayment
@deprecated
export def "execute-pay-pal-payment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payer_id: string # The PayerID returned by PayPal during the transaction authorization process. (e.g. ABCDEFGHIJKLM)
  payment_id: string # The PaymentID returned from [POST /account/payments/paypal](/docs/api/account/#paypal-payment-stage) that has been approved with PayPal. (e.g. PAY-1234567890ABCDEFGHIJKLMN)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/payments/paypal/execute"
    body: {content_type: "application/json", kind: json, fields: [{name: payer_id, var: payer_id}, {name: payment_id, var: payment_id}]}
    accept: ["application/json"]
    ok: [200, 202, 299]
    auth: bearer
  } {
    payer_id: $payer_id, payment_id: $payment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Payment View
#
# GET /account/payments/{paymentId}
# Returns: record<date: string, id: int, usd: int>
# operationId: getPayment
export def "get-payment" [
  payment_id: int
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
    path: "/account/payments/{paymentId}"
    path_params: [{name: paymentId, var: payment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_id: $payment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Promo Credit Add
#
# POST /account/promo-codes
# Returns: record<credit_monthly_cap: string, credit_remaining: string, description: string, expire_dt: string, image_url: string, service_type: string, summary: string, this_month_credit_remaining: string>
# operationId: createPromoCredit
export def "create-promo-credit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  promo_code: string # The Promo Code.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/promo-codes"
    body: {content_type: "application/json", kind: json, fields: [{name: promo_code, var: promo_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    promo_code: $promo_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Service Transfers List
#
# GET /account/service-transfers
# Returns: record<data: table<created: string, entities: record, expiry: string, is_sender: bool, status: string, token: string, updated: string>, page: int, pages: int, results: int>
# operationId: getServiceTransfers
export def "get-service-transfers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/service-transfers"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Service Transfer Create
#
# POST /account/service-transfers
# Returns: record<created: string, entities: record<linodes: list<int>>, expiry: string, is_sender: bool, status: string, token: string, updated: string>
# operationId: createServiceTransfer
export def "create-service-transfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  entities: record # A collection of the services to include in this transfer request, separated by type. — shape: {linodes?: list<int>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/service-transfers"
    body: {content_type: "application/json", kind: json, fields: [{name: entities, var: entities}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    entities: $entities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Service Transfer Cancel
#
# DELETE /account/service-transfers/{token}
# Returns: record
# operationId: deleteServiceTransfer
export def "delete-service-transfer" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/account/service-transfers/{token}"
    path_params: [{name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Service Transfer View
#
# GET /account/service-transfers/{token}
# Returns: record<created: string, entities: record<linodes: list<int>>, expiry: string, is_sender: bool, status: string, token: string, updated: string>
# operationId: getServiceTransfer
export def "get-service-transfer" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/service-transfers/{token}"
    path_params: [{name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Service Transfer Accept
#
# POST /account/service-transfers/{token}/accept
# Returns: record
# operationId: acceptServiceTransfer
export def "accept-service-transfer" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/account/service-transfers/{token}/accept"
    path_params: [{name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Account Settings View
#
# GET /account/settings
# Returns: record<backups_enabled: bool, longview_subscription: string, managed: bool, network_helper: bool, object_storage: string>
# operationId: getAccountSettings
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/settings"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Account Settings Update
#
# PUT /account/settings
# Returns: record<backups_enabled: bool, longview_subscription: string, managed: bool, network_helper: bool, object_storage: string>
# operationId: updateAccountSettings
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
  --backups-enabled: oneof<nothing, bool> # Account-wide backups default. If `true`, all Linodes created will automatically be enrolled in the Backups service. If `false`, Linodes will not be enrolled by default, but may still be enrolled on creation or later. (e.g. true)
  --network-helper: oneof<nothing, bool> # Enables network helper across all users by default for new Linodes and Linode Configs. (e.g. false)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/settings"
    body: {content_type: "application/json", kind: json, fields: [{name: backups_enabled, var: backups_enabled}, {name: network_helper, var: network_helper}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    backups_enabled: $backups_enabled, network_helper: $network_helper
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode Managed Enable
#
# POST /account/settings/managed-enable
# Returns: record
# operationId: enableAccountManaged
export def "enable-account-managed" [
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
    method: post
    path: "/account/settings/managed-enable"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Network Utilization View
#
# GET /account/transfer
# Returns: record<billable: int, quota: int, used: int>
# operationId: getTransfer
export def "get-transfer" [
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
    path: "/account/transfer"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Users List
#
# GET /account/users
# Returns: record<data: table<email: string, restricted: bool, ssh_keys: list, tfa_enabled: bool, username: string>, page: int, pages: int, results: int>
# operationId: getUsers
export def "get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/users"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User Create
#
# POST /account/users
# Returns: record<email: string, restricted: bool, ssh_keys: list<string>, tfa_enabled: bool, username: string>
# operationId: createUser
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
  email: string # The email address for the User. Linode sends emails to this address for account management communications. May be used for other communications as configured. (format: email, e.g. example_user@linode.com)
  --restricted: oneof<nothing, bool> # If true, the User must be granted access to perform actions or access entities on this Account. See User Grants View ([GET /account/users/{username}/grants](/docs/api/account/#users-grants-view)) for details on how to configure grants for a restricted User. (e.g. true)
  username: string # The User's username. This is used for logging in, and may also be displayed alongside actions the User performs (for example, in Events or public StackScripts). (e.g. example_user)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/users"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: restricted, var: restricted}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, restricted: $restricted, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User Delete
#
# DELETE /account/users/{username}
# Returns: record
# operationId: deleteUser
export def "delete-user" [
  username: string
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
    path: "/account/users/{username}"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User View
#
# GET /account/users/{username}
# Returns: record<email: string, restricted: bool, ssh_keys: list<string>, tfa_enabled: bool, username: string>
# operationId: getUser
export def "get-user" [
  username: string
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
    path: "/account/users/{username}"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User Update
#
# PUT /account/users/{username}
# Returns: record<email: string, restricted: bool, ssh_keys: list<string>, tfa_enabled: bool, username: string>
# operationId: updateUser
export def "update-user" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address for the User. Linode sends emails to this address for account management communications. May be used for other communications as configured. (format: email, e.g. example_user@linode.com)
  --restricted: oneof<nothing, bool> # If true, the User must be granted access to perform actions or access entities on this Account. See User Grants View ([GET /account/users/{username}/grants](/docs/api/account/#users-grants-view)) for details on how to configure grants for a restricted User. (e.g. true)
  --body-username: string # The User's username. This is used for logging in, and may also be displayed alongside actions the User performs (for example, in Events or public StackScripts). (e.g. example_user) (spec name: username)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/users/{username}"
    path_params: [{name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: restricted, var: restricted}, {name: username, var: body_username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, email: $email, restricted: $restricted, body_username: $body_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User's Grants View
#
# GET /account/users/{username}/grants
# Returns: record<database: table<id: int, label: string, permissions: string>, domain: table<id: int, label: string, permissions: string>, global: record<account_access: string, add_databases: bool, add_domains: bool, add_firewalls: bool, add_images: bool, add_linodes: bool, add_longview: bool, add_nodebalancers: bool, add_stackscripts: bool, add_volumes: bool, cancel_account: bool, longview_subscription: bool>, image: table<id: int, label: string, permissions: string>, linode: table<id: int, label: string, permissions: string>, longview: table<id: int, label: string, permissions: string>, nodebalancer: table<id: int, label: string, permissions: string>, stackscript: table<id: int, label: string, permissions: string>, volume: table<id: int, label: string, permissions: string>>
# operationId: getUserGrants
export def "get-user-grants" [
  username: string
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
    path: "/account/users/{username}/grants"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User's Grants Update
#
# PUT /account/users/{username}/grants
# Returns: record<database: table<id: int, label: string, permissions: string>, domain: table<id: int, label: string, permissions: string>, global: record<account_access: string, add_databases: bool, add_domains: bool, add_firewalls: bool, add_images: bool, add_linodes: bool, add_longview: bool, add_nodebalancers: bool, add_stackscripts: bool, add_volumes: bool, cancel_account: bool, longview_subscription: bool>, image: table<id: int, label: string, permissions: string>, linode: table<id: int, label: string, permissions: string>, longview: table<id: int, label: string, permissions: string>, nodebalancer: table<id: int, label: string, permissions: string>, stackscript: table<id: int, label: string, permissions: string>, volume: table<id: int, label: string, permissions: string>>
# operationId: updateUserGrants
export def "update-user-grants" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --database: list # The grants this User has for each Database that is owned by this Account. — item shape: {id?: int, permissions?: "read_only"|"read_write"}
  --domain: list # The grants this User has for each Domain that is owned by this Account. — item shape: {id?: int, permissions?: "read_only"|"read_write"}
  --global: record # A structure containing the Account-level grants a User has. — shape: {account_access?: "read_only"|"read_write", add_databases?: bool, add_domains?: bool, add_firewalls?: bool, add_images?: bool, add_linodes?: bool, add_longview?: bool, add_nodebalancers?: bool, add_stackscripts?: bool, add_volumes?: bool, cancel_account?: bool, longview_subscription?: bool}
  --image: list # The grants this User has for each Image that is owned by this Account. — item shape: {id?: int, permissions?: "read_only"|"read_write"}
  --linode: list # The grants this User has for each Linode that is owned by this Account. — item shape: {id?: int, permissions?: "read_only"|"read_write"}
  --longview: list # The grants this User has for each Longview Client that is owned by this Account. — item shape: {id?: int, permissions?: "read_only"|"read_write"}
  --nodebalancer: list # The grants this User has for each NodeBalancer that is owned by this Account. — item shape: {id?: int, permissions?: "read_only"|"read_write"}
  --stackscript: list # The grants this User has for each StackScript that is owned by this Account. — item shape: {id?: int, permissions?: "read_only"|"read_write"}
  --volume: list # The grants this User has for each Block Storage Volume that is owned by this Account. — item shape: {id?: int, permissions?: "read_only"|"read_write"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/users/{username}/grants"
    path_params: [{name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: database, var: database}, {name: domain, var: domain}, {name: global, var: global}, {name: image, var: image}, {name: linode, var: linode}, {name: longview, var: longview}, {name: nodebalancer, var: nodebalancer}, {name: stackscript, var: stackscript}, {name: volume, var: volume}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, database: $database, domain: $domain, global: $global, image: $image, linode: $linode, longview: $longview, nodebalancer: $nodebalancer, stackscript: $stackscript, volume: $volume
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Database Engines List
#
# GET /databases/engines
# Returns: record<page: int, pages: int, results: int, data: table<engine: string, id: string, version: string>>
# operationId: getDatabasesEngines
export def "get-databases-engines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/databases/engines"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Database Engine View
#
# GET /databases/engines/{engineId}
# Returns: record<engine: string, id: string, version: string>
# operationId: getDatabasesEngine
export def "get-databases-engine" [
  engine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/databases/engines/{engineId}"
    path_params: [{name: engineId, var: engine_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    engine_id: $engine_id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Databases List All
#
# GET /databases/instances
# Returns: record<page: int, pages: int, results: int, data: table<allow_list: list, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record, id: int, instance_uri: string, label: string, region: string, status: string, type: string, updated: string, updates: record, version: string>>
# operationId: getDatabasesInstances
export def "get-databases-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/databases/instances"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MongoDB Databases List
#
# GET /databases/mongodb/instances
# Returns: record<page: int, pages: int, results: int, data: table<allow_list: list, cluster_size: int, compression_type: string, created: string, encrypted: bool, engine: string, hosts: record, id: int, label: string, peers: list, port: int, region: string, replica_set: string, ssl_connection: bool, status: string, storage_engine: string, type: string, updated: string, updates: record, version: string>>
# operationId: getDatabasesMongoDBInstances
export def "get-databases-mongo-db-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/databases/mongodb/instances"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MongoDB Database Delete
#
# DELETE /databases/mongodb/instances/{instanceId}
# Returns: record
# operationId: deleteDatabasesMongoDBInstance
export def "delete-databases-mongo-db-instance" [
  instance_id: int
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
    path: "/databases/mongodb/instances/{instanceId}"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MongoDB Database View
#
# GET /databases/mongodb/instances/{instanceId}
# Returns: record<allow_list: list<string>, cluster_size: int, compression_type: string, created: string, encrypted: bool, engine: string, hosts: record<primary: string, secondary: string>, id: int, label: string, peers: list<string>, port: int, region: string, replica_set: string, ssl_connection: bool, status: string, storage_engine: string, type: string, updated: string, updates: record<day_of_week: int, duration: int, frequency: string, hour_of_day: int, week_of_month: int>, version: string>
# operationId: getDatabasesMongoDBInstance
export def "get-databases-mongo-db-instance" [
  instance_id: int
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
    path: "/databases/mongodb/instances/{instanceId}"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MongoDB Database Update
#
# PUT /databases/mongodb/instances/{instanceId}
# Returns: record<allow_list: list<string>, cluster_size: int, compression_type: string, created: string, encrypted: bool, engine: string, hosts: record<primary: string, secondary: string>, id: int, label: string, peers: list<string>, port: int, region: string, replica_set: string, ssl_connection: bool, status: string, storage_engine: string, type: string, updated: string, updates: record<day_of_week: int, duration: int, frequency: string, hour_of_day: int, week_of_month: int>, version: string>
# operationId: putDatabasesMongoDBInstance
export def "put-databases-mongo-db-instance" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-list: list<string> # A list of IP addresses that can access the Managed Database. Each item can be a single IP address or a range in CIDR format. By default, this is an empty array (`[]`), which blocks all connections (both public and private) to the Managed Database. If `0.0.0.0/0` is a value in this list, then all IP addresses can access the Managed Database. (e.g. [203.0.113.1/32, 192.0.1.0/24])
  --label: string # A unique, user-defined string referring to the Managed Database. (e.g. example-db)
  --updates: record # Configuration settings for automated patch update maintenance for the Managed Database. — shape: {day_of_week?: int, duration?: int, frequency?: "weekly"|"monthly", hour_of_day?: int, week_of_month?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/databases/mongodb/instances/{instanceId}"
    path_params: [{name: instanceId, var: instance_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allow_list, var: allow_list}, {name: label, var: label}, {name: updates, var: updates}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, allow_list: $allow_list, label: $label, updates: $updates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MongoDB Database Backups List
#
# GET /databases/mongodb/instances/{instanceId}/backups
# Returns: record<page: int, pages: int, results: int, data: table<created: string, id: int, label: string, type: string>>
# operationId: getDatabasesMongoDBInstanceBackups
export def "get-databases-mongo-db-instance-backups" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/databases/mongodb/instances/{instanceId}/backups"
    path_params: [{name: instanceId, var: instance_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MongoDB Database Backup Snapshot Create
#
# POST /databases/mongodb/instances/{instanceId}/backups
# Returns: record
# operationId: postDatabasesMongoDBInstanceBackup
export def "post-databases-mongo-db-instance-backup" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string # The label for the Database snapshot backup. * Must include only ASCII letters or numbers. * Must be unique among other backup labels for this Database. (e.g. db-snapshot)
  --target: string@target-completer # The Database cluster target. If the Database is a high availability cluster, choosing `secondary` creates a snapshot backup of a replica node. (default: primary, e.g. primary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/databases/mongodb/instances/{instanceId}/backups"
    path_params: [{name: instanceId, var: instance_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, label: $label, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MongoDB Database Backup Delete
#
# DELETE /databases/mongodb/instances/{instanceId}/backups/{backupId}
# Returns: record
# operationId: deleteDatabaseMongoDBInstanceBackup
export def "delete-database-mongo-db-instance-backup" [
  instance_id: int
  backup_id: int
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
    path: "/databases/mongodb/instances/{instanceId}/backups/{backupId}"
    path_params: [{name: instanceId, var: instance_id}, {name: backupId, var: backup_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, backup_id: $backup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MongoDB Database Backup View
#
# GET /databases/mongodb/instances/{instanceId}/backups/{backupId}
# Returns: record<created: string, id: int, label: string, type: string>
# operationId: getDatabasesMongoDBInstanceBackup
export def "get-databases-mongo-db-instance-backup" [
  instance_id: int
  backup_id: int
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
    path: "/databases/mongodb/instances/{instanceId}/backups/{backupId}"
    path_params: [{name: instanceId, var: instance_id}, {name: backupId, var: backup_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, backup_id: $backup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MongoDB Database Backup Restore
#
# POST /databases/mongodb/instances/{instanceId}/backups/{backupId}/restore
# Returns: record
# operationId: postDatabasesMongoDBInstanceBackupRestore
export def "post-databases-mongo-db-instance-backup-restore" [
  instance_id: int
  backup_id: int
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
    method: post
    path: "/databases/mongodb/instances/{instanceId}/backups/{backupId}/restore"
    path_params: [{name: instanceId, var: instance_id}, {name: backupId, var: backup_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, backup_id: $backup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MongoDB Database Credentials View
#
# GET /databases/mongodb/instances/{instanceId}/credentials
# Returns: record<password: string, username: string>
# operationId: getDatabasesMongoDBInstanceCredentials
export def "get-databases-mongo-db-instance-credentials" [
  instance_id: int
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
    path: "/databases/mongodb/instances/{instanceId}/credentials"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MongoDB Database Credentials Reset
#
# POST /databases/mongodb/instances/{instanceId}/credentials/reset
# Returns: record
# operationId: postDatabasesMongoDBInstanceCredentialsReset
export def "post-databases-mongo-db-instance-credentials-reset" [
  instance_id: int
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
    method: post
    path: "/databases/mongodb/instances/{instanceId}/credentials/reset"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MongoDB Database Patch
#
# POST /databases/mongodb/instances/{instanceId}/patch
# Returns: record
# operationId: postDatabasesMongoDBInstancePatch
export def "post-databases-mongo-db-instance-patch" [
  instance_id: int
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
    method: post
    path: "/databases/mongodb/instances/{instanceId}/patch"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MongoDB Database SSL Certificate View
#
# GET /databases/mongodb/instances/{instanceId}/ssl
# Returns: record<ca_certificate: string>
# operationId: getDatabasesMongoDBInstanceSSL
export def "get-databases-mongo-db-instance-ssl" [
  instance_id: int
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
    path: "/databases/mongodb/instances/{instanceId}/ssl"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MySQL Databases List
#
# GET /databases/mysql/instances
# Returns: record<page: int, pages: int, results: int, data: table<allow_list: list, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record, id: int, label: string, port: int, region: string, replication_type: string, ssl_connection: bool, status: string, type: string, updated: string, updates: record, version: string>>
# operationId: getDatabasesMySQLInstances
export def "get-databases-my-sql-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/databases/mysql/instances"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MySQL Database Create
#
# POST /databases/mysql/instances
# Returns: record<allow_list: list<string>, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record<primary: string, secondary: string>, id: int, label: string, port: int, region: string, replication_type: string, ssl_connection: bool, status: string, type: string, updated: string, updates: record<day_of_week: int, duration: int, frequency: string, hour_of_day: int, week_of_month: int>, version: string>
# operationId: postDatabasesMySQLInstances
export def "post-databases-my-sql-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-list: list<string> # A list of IP addresses that can access the Managed Database. Each item can be a single IP address or a range in CIDR format. By default, this is an empty array (`[]`), which blocks all connections (both public and private) to the Managed Database. If `0.0.0.0/0` is a value in this list, then all IP addresses can access the Managed Database. (e.g. [203.0.113.1/32, 192.0.1.0/24])
  --cluster-size: int@cluster-size-completer # The number of Linode Instance nodes deployed to the Managed Database. Choosing 3 nodes creates a high availability cluster consisting of 1 primary node and 2 replica nodes. (default: 1, e.g. 3)
  --encrypted: oneof<nothing, bool> # Whether the Managed Databases is encrypted. (default: false, e.g. false)
  engine: string # The Managed Database engine in engine/version format. (e.g. mysql/8.0.26)
  label: string # A unique, user-defined string referring to the Managed Database. (e.g. example-db)
  region: string # The [Region](/docs/api/regions/) ID for the Managed Database. (e.g. us-east)
  --replication-type: string@replication-type-completer # The replication method used for the Managed Database. Defaults to `none` for a single cluster and `semi_synch` for a high availability cluster. Must be `none` for a single node cluster. Must be `asynch` or `semi_synch` for a high availability cluster. (e.g. semi_synch)
  --ssl-connection: oneof<nothing, bool> # Whether to require SSL credentials to establish a connection to the Managed Database. Use the **Managed MySQL Database Credentials View** ([GET /databases/mysql/instances/{instanceId}/credentials](/docs/api/databases/#managed-mysql-database-credentials-view)) command for access information. (default: true, e.g. true)
  type: string # The Linode Instance type used by the Managed Database for its nodes. (e.g. g6-dedicated-2)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/databases/mysql/instances"
    body: {content_type: "application/json", kind: json, fields: [{name: allow_list, var: allow_list}, {name: cluster_size, var: cluster_size}, {name: encrypted, var: encrypted}, {name: engine, var: engine}, {name: label, var: label}, {name: region, var: region}, {name: replication_type, var: replication_type}, {name: ssl_connection, var: ssl_connection}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    allow_list: $allow_list, cluster_size: $cluster_size, encrypted: $encrypted, engine: $engine, label: $label, region: $region, replication_type: $replication_type, ssl_connection: $ssl_connection, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MySQL Database Delete
#
# DELETE /databases/mysql/instances/{instanceId}
# Returns: record
# operationId: deleteDatabasesMySQLInstance
export def "delete-databases-my-sql-instance" [
  instance_id: int
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
    path: "/databases/mysql/instances/{instanceId}"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MySQL Database View
#
# GET /databases/mysql/instances/{instanceId}
# Returns: record<allow_list: list<string>, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record<primary: string, secondary: string>, id: int, label: string, port: int, region: string, replication_type: string, ssl_connection: bool, status: string, type: string, updated: string, updates: record<day_of_week: int, duration: int, frequency: string, hour_of_day: int, week_of_month: int>, version: string>
# operationId: getDatabasesMySQLInstance
export def "get-databases-my-sql-instance" [
  instance_id: int
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
    path: "/databases/mysql/instances/{instanceId}"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MySQL Database Update
#
# PUT /databases/mysql/instances/{instanceId}
# Returns: record<allow_list: list<string>, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record<primary: string, secondary: string>, id: int, label: string, port: int, region: string, replication_type: string, ssl_connection: bool, status: string, type: string, updated: string, updates: record<day_of_week: int, duration: int, frequency: string, hour_of_day: int, week_of_month: int>, version: string>
# operationId: putDatabasesMySQLInstance
export def "put-databases-my-sql-instance" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-list: list<string> # A list of IP addresses that can access the Managed Database. Each item can be a single IP address or a range in CIDR format. By default, this is an empty array (`[]`), which blocks all connections (both public and private) to the Managed Database. If `0.0.0.0/0` is a value in this list, then all IP addresses can access the Managed Database. (e.g. [203.0.113.1/32, 192.0.1.0/24])
  --label: string # A unique, user-defined string referring to the Managed Database. (e.g. example-db)
  --updates: record # Configuration settings for automated patch update maintenance for the Managed Database. — shape: {day_of_week?: int, duration?: int, frequency?: "weekly"|"monthly", hour_of_day?: int, week_of_month?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/databases/mysql/instances/{instanceId}"
    path_params: [{name: instanceId, var: instance_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allow_list, var: allow_list}, {name: label, var: label}, {name: updates, var: updates}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, allow_list: $allow_list, label: $label, updates: $updates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MySQL Database Backups List
#
# GET /databases/mysql/instances/{instanceId}/backups
# Returns: record<page: int, pages: int, results: int, data: table<created: string, id: int, label: string, type: string>>
# operationId: getDatabasesMySQLInstanceBackups
export def "get-databases-my-sql-instance-backups" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/databases/mysql/instances/{instanceId}/backups"
    path_params: [{name: instanceId, var: instance_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MySQL Database Backup Snapshot Create
#
# POST /databases/mysql/instances/{instanceId}/backups
# Returns: record
# operationId: postDatabasesMySQLInstanceBackup
export def "post-databases-my-sql-instance-backup" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string # The label for the Database snapshot backup. * Must include only ASCII letters or numbers. * Must be unique among other backup labels for this Database. (e.g. db-snapshot)
  --target: string@target-completer # The Database cluster target. If the Database is a high availability cluster, choosing `secondary` creates a snapshot backup of a replica node. (default: primary, e.g. primary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/databases/mysql/instances/{instanceId}/backups"
    path_params: [{name: instanceId, var: instance_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, label: $label, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MySQL Database Backup Delete
#
# DELETE /databases/mysql/instances/{instanceId}/backups/{backupId}
# Returns: record
# operationId: deleteDatabaseMySQLInstanceBackup
export def "delete-database-my-sql-instance-backup" [
  instance_id: int
  backup_id: int
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
    path: "/databases/mysql/instances/{instanceId}/backups/{backupId}"
    path_params: [{name: instanceId, var: instance_id}, {name: backupId, var: backup_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, backup_id: $backup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MySQL Database Backup View
#
# GET /databases/mysql/instances/{instanceId}/backups/{backupId}
# Returns: record<created: string, id: int, label: string, type: string>
# operationId: getDatabasesMySQLInstanceBackup
export def "get-databases-my-sql-instance-backup" [
  instance_id: int
  backup_id: int
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
    path: "/databases/mysql/instances/{instanceId}/backups/{backupId}"
    path_params: [{name: instanceId, var: instance_id}, {name: backupId, var: backup_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, backup_id: $backup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MySQL Database Backup Restore
#
# POST /databases/mysql/instances/{instanceId}/backups/{backupId}/restore
# Returns: record
# operationId: postDatabasesMySQLInstanceBackupRestore
export def "post-databases-my-sql-instance-backup-restore" [
  instance_id: int
  backup_id: int
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
    method: post
    path: "/databases/mysql/instances/{instanceId}/backups/{backupId}/restore"
    path_params: [{name: instanceId, var: instance_id}, {name: backupId, var: backup_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, backup_id: $backup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MySQL Database Credentials View
#
# GET /databases/mysql/instances/{instanceId}/credentials
# Returns: record<password: string, username: string>
# operationId: getDatabasesMySQLInstanceCredentials
export def "get-databases-my-sql-instance-credentials" [
  instance_id: int
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
    path: "/databases/mysql/instances/{instanceId}/credentials"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MySQL Database Credentials Reset
#
# POST /databases/mysql/instances/{instanceId}/credentials/reset
# Returns: record
# operationId: postDatabasesMySQLInstanceCredentialsReset
export def "post-databases-my-sql-instance-credentials-reset" [
  instance_id: int
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
    method: post
    path: "/databases/mysql/instances/{instanceId}/credentials/reset"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MySQL Database Patch
#
# POST /databases/mysql/instances/{instanceId}/patch
# Returns: record
# operationId: postDatabasesMySQLInstancePatch
export def "post-databases-my-sql-instance-patch" [
  instance_id: int
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
    method: post
    path: "/databases/mysql/instances/{instanceId}/patch"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed MySQL Database SSL Certificate View
#
# GET /databases/mysql/instances/{instanceId}/ssl
# Returns: record<ca_certificate: string>
# operationId: getDatabasesMySQLInstanceSSL
export def "get-databases-my-sql-instance-ssl" [
  instance_id: int
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
    path: "/databases/mysql/instances/{instanceId}/ssl"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed PostgreSQL Databases List
#
# GET /databases/postgresql/instances
# Returns: record<page: int, pages: int, results: int, data: table<allow_list: list, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record, id: int, label: string, port: int, region: string, replication_commit_type: string, replication_type: string, ssl_connection: bool, status: string, type: string, updated: string, updates: record, version: string>>
# operationId: getDatabasesPostgreSQLInstances
export def "get-databases-postgre-sql-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/databases/postgresql/instances"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed PostgreSQL Database Create
#
# POST /databases/postgresql/instances
# Returns: record<allow_list: list<string>, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record<primary: string, secondary: string>, id: int, label: string, port: int, region: string, replication_commit_type: string, replication_type: string, ssl_connection: bool, status: string, type: string, updated: string, updates: record<day_of_week: int, duration: int, frequency: string, hour_of_day: int, week_of_month: int>, version: string>
# operationId: postDatabasesPostgreSQLInstances
export def "post-databases-postgre-sql-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-list: list<string> # A list of IP addresses that can access the Managed Database. Each item can be a single IP address or a range in CIDR format. By default, this is an empty array (`[]`), which blocks all connections (both public and private) to the Managed Database. If `0.0.0.0/0` is a value in this list, then all IP addresses can access the Managed Database. (e.g. [203.0.113.1/32, 192.0.1.0/24])
  --cluster-size: int@cluster-size-completer # The number of Linode Instance nodes deployed to the Managed Database. Choosing 3 nodes creates a high availability cluster consisting of 1 primary node and 2 replica nodes. (default: 1, e.g. 3)
  --encrypted: oneof<nothing, bool> # Whether the Managed Databases is encrypted. (default: false, e.g. false)
  engine: string # The Managed Database engine in engine/version format. (e.g. postgresql/13.2)
  label: string # A unique, user-defined string referring to the Managed Database. (e.g. example-db)
  region: string # The [Region](/docs/api/regions/) ID for the Managed Database. (e.g. us-east)
  --replication-commit-type: string@replication-commit-type-completer # The synchronization level of the replicating server. Must be `local` or `off` for the `asynch` replication type. Must be `on`, `remote_write`, or `remote_apply` for the `semi_synch` replication type. (default: local, e.g. local)
  --replication-type: string@replication-type-completer # The replication method used for the Managed Database. Defaults to `none` for a single cluster and `semi_synch` for a high availability cluster. Must be `none` for a single node cluster. Must be `asynch` or `semi_synch` for a high availability cluster. (e.g. semi_synch)
  --ssl-connection: oneof<nothing, bool> # Whether to require SSL credentials to establish a connection to the Managed Database. Use the **Managed PostgreSQL Database Credentials View** ([GET /databases/postgresql/instances/{instanceId}/credentials](/docs/api/databases/#managed-postgresql-database-credentials-view)) command for access information. (default: true, e.g. true)
  type: string # The Linode Instance type used by the Managed Database for its nodes. (e.g. g6-dedicated-2)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/databases/postgresql/instances"
    body: {content_type: "application/json", kind: json, fields: [{name: allow_list, var: allow_list}, {name: cluster_size, var: cluster_size}, {name: encrypted, var: encrypted}, {name: engine, var: engine}, {name: label, var: label}, {name: region, var: region}, {name: replication_commit_type, var: replication_commit_type}, {name: replication_type, var: replication_type}, {name: ssl_connection, var: ssl_connection}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    allow_list: $allow_list, cluster_size: $cluster_size, encrypted: $encrypted, engine: $engine, label: $label, region: $region, replication_commit_type: $replication_commit_type, replication_type: $replication_type, ssl_connection: $ssl_connection, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed PostgreSQL Database Delete
#
# DELETE /databases/postgresql/instances/{instanceId}
# Returns: record
# operationId: deleteDatabasesPostgreSQLInstance
export def "delete-databases-postgre-sql-instance" [
  instance_id: int
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
    path: "/databases/postgresql/instances/{instanceId}"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed PostgreSQL Database View
#
# GET /databases/postgresql/instances/{instanceId}
# Returns: record<allow_list: list<string>, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record<primary: string, secondary: string>, id: int, label: string, port: int, region: string, replication_commit_type: string, replication_type: string, ssl_connection: bool, status: string, type: string, updated: string, updates: record<day_of_week: int, duration: int, frequency: string, hour_of_day: int, week_of_month: int>, version: string>
# operationId: getDatabasesPostgreSQLInstance
export def "get-databases-postgre-sql-instance" [
  instance_id: int
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
    path: "/databases/postgresql/instances/{instanceId}"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed PostgreSQL Database Update
#
# PUT /databases/postgresql/instances/{instanceId}
# Returns: record<allow_list: list<string>, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record<primary: string, secondary: string>, id: int, label: string, port: int, region: string, replication_commit_type: string, replication_type: string, ssl_connection: bool, status: string, type: string, updated: string, updates: record<day_of_week: int, duration: int, frequency: string, hour_of_day: int, week_of_month: int>, version: string>
# operationId: putDatabasesPostgreSQLInstance
export def "put-databases-postgre-sql-instance" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-list: list<string> # A list of IP addresses that can access the Managed Database. Each item can be a single IP address or a range in CIDR format. By default, this is an empty array (`[]`), which blocks all connections (both public and private) to the Managed Database. If `0.0.0.0/0` is a value in this list, then all IP addresses can access the Managed Database. (e.g. [203.0.113.1/32, 192.0.1.0/24])
  --label: string # A unique, user-defined string referring to the Managed Database. (e.g. example-db)
  --updates: record # Configuration settings for automated patch update maintenance for the Managed Database. — shape: {day_of_week?: int, duration?: int, frequency?: "weekly"|"monthly", hour_of_day?: int, week_of_month?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/databases/postgresql/instances/{instanceId}"
    path_params: [{name: instanceId, var: instance_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allow_list, var: allow_list}, {name: label, var: label}, {name: updates, var: updates}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, allow_list: $allow_list, label: $label, updates: $updates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed PostgreSQL Database Backups List
#
# GET /databases/postgresql/instances/{instanceId}/backups
# Returns: record<page: int, pages: int, results: int, data: table<created: string, id: int, label: string, type: string>>
# operationId: getDatabasesPostgreSQLInstanceBackups
export def "get-databases-postgre-sql-instance-backups" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/databases/postgresql/instances/{instanceId}/backups"
    path_params: [{name: instanceId, var: instance_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed PostgreSQL Database Backup Snapshot Create
#
# POST /databases/postgresql/instances/{instanceId}/backups
# Returns: record
# operationId: postDatabasesPostgreSQLInstanceBackup
export def "post-databases-postgre-sql-instance-backup" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string # The label for the Database snapshot backup. * Must include only ASCII letters or numbers. * Must be unique among other backup labels for this Database. (e.g. db-snapshot)
  --target: string@target-completer # The Database cluster target. If the Database is a high availability cluster, choosing `secondary` creates a snapshot backup of a replica node. (default: primary, e.g. primary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/databases/postgresql/instances/{instanceId}/backups"
    path_params: [{name: instanceId, var: instance_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, label: $label, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed PostgreSQL Database Backup Delete
#
# DELETE /databases/postgresql/instances/{instanceId}/backups/{backupId}
# Returns: record
# operationId: deleteDatabasePostgreSQLInstanceBackup
export def "delete-database-postgre-sql-instance-backup" [
  instance_id: int
  backup_id: int
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
    path: "/databases/postgresql/instances/{instanceId}/backups/{backupId}"
    path_params: [{name: instanceId, var: instance_id}, {name: backupId, var: backup_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, backup_id: $backup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed PostgreSQL Database Backup View
#
# GET /databases/postgresql/instances/{instanceId}/backups/{backupId}
# Returns: record<created: string, id: int, label: string, type: string>
# operationId: getDatabasesPostgreSQLInstanceBackup
export def "get-databases-postgre-sql-instance-backup" [
  instance_id: int
  backup_id: int
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
    path: "/databases/postgresql/instances/{instanceId}/backups/{backupId}"
    path_params: [{name: instanceId, var: instance_id}, {name: backupId, var: backup_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, backup_id: $backup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed PostgreSQL Database Backup Restore
#
# POST /databases/postgresql/instances/{instanceId}/backups/{backupId}/restore
# Returns: record
# operationId: postDatabasesPostgreSQLInstanceBackupRestore
export def "post-databases-postgre-sql-instance-backup-restore" [
  instance_id: int
  backup_id: int
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
    method: post
    path: "/databases/postgresql/instances/{instanceId}/backups/{backupId}/restore"
    path_params: [{name: instanceId, var: instance_id}, {name: backupId, var: backup_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id, backup_id: $backup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed PostgreSQL Database Credentials View
#
# GET /databases/postgresql/instances/{instanceId}/credentials
# Returns: record<password: string, username: string>
# operationId: getDatabasesPostgreSQLInstanceCredentials
export def "get-databases-postgre-sql-instance-credentials" [
  instance_id: int
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
    path: "/databases/postgresql/instances/{instanceId}/credentials"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed PostgreSQL Database Credentials Reset
#
# POST /databases/postgresql/instances/{instanceId}/credentials/reset
# Returns: record
# operationId: postDatabasesPostgreSQLInstanceCredentialsReset
export def "post-databases-postgre-sql-instance-credentials-reset" [
  instance_id: int
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
    method: post
    path: "/databases/postgresql/instances/{instanceId}/credentials/reset"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed PostgreSQL Database Patch
#
# POST /databases/postgresql/instances/{instanceId}/patch
# Returns: record
# operationId: postDatabasesPostgreSQLInstancePatch
export def "post-databases-postgre-sql-instance-patch" [
  instance_id: int
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
    method: post
    path: "/databases/postgresql/instances/{instanceId}/patch"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed PostgreSQL Database SSL Certificate View
#
# GET /databases/postgresql/instances/{instanceId}/ssl
# Returns: record<ca_certificate: string>
# operationId: getDatabasesPostgreSQLInstanceSSL
export def "get-databases-postgre-sql-instance-ssl" [
  instance_id: int
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
    path: "/databases/postgresql/instances/{instanceId}/ssl"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Database Types List
#
# GET /databases/types
# Returns: record<page: int, pages: int, results: int, data: table<class: string, deprecated: bool, disk: int, engines: record, id: string, label: string, memory: int, vcpus: int>>
# operationId: getDatabasesTypes
export def "get-databases-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/databases/types"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Database Type View
#
# GET /databases/types/{typeId}
# Returns: record<class: string, deprecated: bool, disk: int, engines: record<mongodb: list<record>, mysql: list<record>, postgresql: list<record>>, id: string, label: string, memory: int, vcpus: int>
# operationId: getDatabasesType
export def "get-databases-type" [
  type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/databases/types/{typeId}"
    path_params: [{name: typeId, var: type_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    type_id: $type_id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Domains List
#
# GET /domains
# Returns: record<data: table<axfr_ips: list, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list, ttl_sec: int, type: string>, page: int, pages: int, results: int>
# operationId: getDomains
export def "get-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/domains"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Domain Create
#
# POST /domains
# Returns: record<axfr_ips: list<string>, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list<string>, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list<string>, ttl_sec: int, type: string>
# operationId: createDomain
@deprecated --flag group
export def "create-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --axfr-ips: list<string> # The list of IPs that may perform a zone transfer for this Domain. The total combined length of all data within this array cannot exceed 1000 characters. **Note**: This is potentially dangerous, and should be set to an empty list unless you intend to use it. (e.g. [])
  --description: string # A description for this Domain. This is for display purposes only.
  domain: string # The domain this Domain represents. Domain labels cannot be longer than 63 characters and must conform to [RFC1035](https://tools.ietf.org/html/rfc1035). Domains must be unique on Linode's platform, including across different Linode accounts; there cannot be two Domains representing the same domain. (e.g. example.org)
  --expire-sec: int # The amount of time in seconds that may pass before this Domain is no longer authoritative. * Valid values are 0, 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200. * Any other value is rounded up to the nearest valid value. * A value of 0 is equivalent to the default value of 1209600. (default: 0, e.g. 300)
  --group: string # The group this Domain belongs to. This is for display purposes only. (DEPRECATED)
  --master-ips: list<string> # The IP addresses representing the master DNS for this Domain. At least one value is required for `type` slave Domains. The total combined length of all data within this array cannot exceed 1000 characters. (e.g. [])
  --refresh-sec: int # The amount of time in seconds before this Domain should be refreshed. * Valid values are 0, 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200. * Any other value is rounded up to the nearest valid value. * A value of 0 is equivalent to the default value of 14400. (default: 0, e.g. 300)
  --retry-sec: int # The interval, in seconds, at which a failed refresh should be retried. * Valid values are 0, 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200. * Any other value is rounded up to the nearest valid value. * A value of 0 is equivalent to the default value of 14400. (default: 0, e.g. 300)
  --soa-email: string # Start of Authority email address. This is required for `type` master Domains. (format: email, e.g. admin@example.org)
  --status: string@status-completer # Used to control whether this Domain is currently being rendered. (default: active, e.g. active)
  --tags: list<string> # An array of tags applied to this object. Tags are for organizational purposes only. (e.g. [example tag, another example])
  --ttl-sec: int # "Time to Live" - the amount of time in seconds that this Domain's records may be cached by resolvers or other domain servers. * Valid values are 0, 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200. * Any other value is rounded up to the nearest valid value. * A value of 0 is equivalent to the default value of 86400. (default: 0, e.g. 300)
  type: string@type-completer-1 # Whether this Domain represents the authoritative source of information for the domain it describes ("master"), or whether it is a read-only copy of a master ("slave"). (e.g. master)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains"
    body: {content_type: "application/json", kind: json, fields: [{name: axfr_ips, var: axfr_ips}, {name: description, var: description}, {name: domain, var: domain}, {name: expire_sec, var: expire_sec}, {name: group, var: group}, {name: master_ips, var: master_ips}, {name: refresh_sec, var: refresh_sec}, {name: retry_sec, var: retry_sec}, {name: soa_email, var: soa_email}, {name: status, var: status}, {name: tags, var: tags}, {name: ttl_sec, var: ttl_sec}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    axfr_ips: $axfr_ips, description: $description, domain: $domain, expire_sec: $expire_sec, group: $group, master_ips: $master_ips, refresh_sec: $refresh_sec, retry_sec: $retry_sec, soa_email: $soa_email, status: $status, tags: $tags, ttl_sec: $ttl_sec, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Domain Import
#
# POST /domains/import
# Returns: record<axfr_ips: list<string>, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list<string>, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list<string>, ttl_sec: int, type: string>
# operationId: importDomain
export def "import-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  domain: string # The domain to import. (e.g. example.com)
  remote_nameserver: string # The remote nameserver that allows zone transfers (AXFR). (e.g. examplenameserver.com)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/import"
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: remote_nameserver, var: remote_nameserver}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, remote_nameserver: $remote_nameserver
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Domain Delete
#
# DELETE /domains/{domainId}
# Returns: record
# operationId: deleteDomain
export def "delete-domain" [
  domain_id: int
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
    path: "/domains/{domainId}"
    path_params: [{name: domainId, var: domain_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_id: $domain_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Domain View
#
# GET /domains/{domainId}
# Returns: record<axfr_ips: list<string>, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list<string>, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list<string>, ttl_sec: int, type: string>
# operationId: getDomain
export def "get-domain" [
  domain_id: int
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
    path: "/domains/{domainId}"
    path_params: [{name: domainId, var: domain_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_id: $domain_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Domain Update
#
# PUT /domains/{domainId}
# Returns: record<axfr_ips: list<string>, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list<string>, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list<string>, ttl_sec: int, type: string>
# operationId: updateDomain
@deprecated --flag group
export def "update-domain" [
  domain_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --axfr-ips: list<string> # The list of IPs that may perform a zone transfer for this Domain. The total combined length of all data within this array cannot exceed 1000 characters. **Note**: This is potentially dangerous, and should be set to an empty list unless you intend to use it. (e.g. [])
  --description: string # A description for this Domain. This is for display purposes only.
  --domain: string # The domain this Domain represents. Domain labels cannot be longer than 63 characters and must conform to [RFC1035](https://tools.ietf.org/html/rfc1035). Domains must be unique on Linode's platform, including across different Linode accounts; there cannot be two Domains representing the same domain. (e.g. example.org)
  --expire-sec: int # The amount of time in seconds that may pass before this Domain is no longer authoritative. * Valid values are 0, 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200. * Any other value is rounded up to the nearest valid value. * A value of 0 is equivalent to the default value of 1209600. (default: 0, e.g. 300)
  --group: string # The group this Domain belongs to. This is for display purposes only. (DEPRECATED)
  --master-ips: list<string> # The IP addresses representing the master DNS for this Domain. At least one value is required for `type` slave Domains. The total combined length of all data within this array cannot exceed 1000 characters. (e.g. [])
  --refresh-sec: int # The amount of time in seconds before this Domain should be refreshed. * Valid values are 0, 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200. * Any other value is rounded up to the nearest valid value. * A value of 0 is equivalent to the default value of 14400. (default: 0, e.g. 300)
  --retry-sec: int # The interval, in seconds, at which a failed refresh should be retried. * Valid values are 0, 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200. * Any other value is rounded up to the nearest valid value. * A value of 0 is equivalent to the default value of 14400. (default: 0, e.g. 300)
  --soa-email: string # Start of Authority email address. This is required for `type` master Domains. (format: email, e.g. admin@example.org)
  --status: string@status-completer # Used to control whether this Domain is currently being rendered. (default: active, e.g. active)
  --tags: list<string> # An array of tags applied to this object. Tags are for organizational purposes only. (e.g. [example tag, another example])
  --ttl-sec: int # "Time to Live" - the amount of time in seconds that this Domain's records may be cached by resolvers or other domain servers. * Valid values are 0, 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200. * Any other value is rounded up to the nearest valid value. * A value of 0 is equivalent to the default value of 86400. (default: 0, e.g. 300)
  --type: string@type-completer-1 # Whether this Domain represents the authoritative source of information for the domain it describes ("master"), or whether it is a read-only copy of a master ("slave"). (e.g. master)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/domains/{domainId}"
    path_params: [{name: domainId, var: domain_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: axfr_ips, var: axfr_ips}, {name: description, var: description}, {name: domain, var: domain}, {name: expire_sec, var: expire_sec}, {name: group, var: group}, {name: master_ips, var: master_ips}, {name: refresh_sec, var: refresh_sec}, {name: retry_sec, var: retry_sec}, {name: soa_email, var: soa_email}, {name: status, var: status}, {name: tags, var: tags}, {name: ttl_sec, var: ttl_sec}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_id: $domain_id, axfr_ips: $axfr_ips, description: $description, domain: $domain, expire_sec: $expire_sec, group: $group, master_ips: $master_ips, refresh_sec: $refresh_sec, retry_sec: $retry_sec, soa_email: $soa_email, status: $status, tags: $tags, ttl_sec: $ttl_sec, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Domain Clone
#
# POST /domains/{domainId}/clone
# Returns: record<axfr_ips: list<string>, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list<string>, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list<string>, ttl_sec: int, type: string>
# operationId: cloneDomain
export def "clone-domain" [
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  domain: string # The new domain for the clone. Domain labels cannot be longer than 63 characters and must conform to [RFC1035](https://tools.ietf.org/html/rfc1035). Domains must be unique on Linode's platform, including across different Linode accounts; there cannot be two Domains representing the same domain. (e.g. example.org)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{domainId}/clone"
    path_params: [{name: domainId, var: domain_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_id: $domain_id, domain: $domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Domain Records List
#
# GET /domains/{domainId}/records
# Returns: record<data: table<created: string, id: int, name: string, port: int, priority: int, protocol: string, service: string, tag: string, target: string, ttl_sec: int, type: string, updated: string, weight: int>, page: int, pages: int, results: int>
# operationId: getDomainRecords
export def "get-domain-records" [
  domain_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/domains/{domainId}/records"
    path_params: [{name: domainId, var: domain_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_id: $domain_id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Domain Record Create
#
# POST /domains/{domainId}/records
# Returns: record<created: string, id: int, name: string, port: int, priority: int, protocol: string, service: string, tag: string, target: string, ttl_sec: int, type: string, updated: string, weight: int>
# operationId: createDomainRecord
export def "create-domain-record" [
  domain_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of this Record. For requests, this property's actual usage and whether it is required depends on the type of record this represents: `A` and `AAAA`: The hostname or FQDN of the Record. `NS`: The subdomain, if any, to use with the Domain of the Record. Wildcard NS records (`*`) are not supported. `MX`: The mail subdomain. For example, `sub` for the address `user@sub.example.com` under the `example.com` Domain. Must be an empty string (`""`) for a Null MX Record. `CNAME`: The hostname. Must be unique. Required. `TXT`: The hostname. `SRV`: Unused. Use the `service` property to set the service name for this record. `CAA`: The subdomain. Omit or enter an empty string (`""`) to apply to the entire Domain. `PTR`: See our guide on how to [Configure Your Linode for Reverse DNS (rDNS)](/docs/guides/configure-rdns/). (e.g. test)
  --port: int # The port this Record points to. Only valid and required for SRV record requests. (e.g. 80)
  --priority: int # The priority of the target host for this Record. Lower values are preferred. Only valid for MX and SRV record requests. Required for SRV record requests. Defaults to `0` for MX record requests. Must be `0` for Null MX records. (e.g. 50)
  --protocol: string # The protocol this Record's service communicates with. An underscore (`_`) is prepended automatically to the submitted value for this property. Only valid for SRV record requests. (nullable)
  --service: string # The name of the service. An underscore (`_`) is prepended and a period (`.`) is appended automatically to the submitted value for this property. Only valid and required for SRV record requests. (nullable)
  --tag: string@tag-completer # The tag portion of a CAA record. Only valid and required for CAA record requests. (nullable)
  --target: string # The target for this Record. For requests, this property's actual usage and whether it is required depends on the type of record this represents: `A` and `AAAA`: The IP address. Use `[remote_addr]` to submit the IPv4 address of the request. Required. `NS`: The name server. Must be a valid domain. Required. `MX`: The mail server. Must be a valid domain unless creating a Null MX Record. To create a [Null MX Record](https://datatracker.ietf.org/doc/html/rfc7505), first [remove](/docs/api/domains/#domain-record-delete) any additional MX records, create an MX record with empty strings (`""`) for the `target` and `name`. If a Domain has a Null MX record, new MX records cannot be created. Required. `CNAME`: The alias. Must be a valid domain. Required. `TXT`: The value. Required. `SRV`: The target domain or subdomain. If a subdomain is entered, it is automatically used with the Domain. To configure for a different domain, enter a valid FQDN. For example, the value `www` with a Domain for `example.com` results in a target set to `www.example.com`, whereas the value `sample.com` results in a target set to `sample.com`. Required. `CAA`: The value. For `issue` or `issuewild` tags, the domain of your certificate issuer. For the `iodef` tag, a contact or submission URL (domain, http, https, or mailto). Requirements depend on the tag for this record: * `issue`: The domain of your certificate issuer. Must be a valid domain. * `issuewild`: Must begin with `*`. * `iodef`: Must be either (1) a valid domain, (2) a valid domain prepended with `http://` or `https://`, or (3) a valid email address prepended with `mailto:`. `PTR`: Required. See our guide on how to [Configure Your Linode for Reverse DNS (rDNS)](/docs/guides/configure-rdns/). With the exception of A, AAAA, and CAA records, this field accepts a trailing period. (e.g. 192.0.2.0)
  --ttl-sec: int # "Time to Live" - the amount of time in seconds that this Domain's records may be cached by resolvers or other domain servers. Valid values are 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200 - any other value will be rounded to the nearest valid value. (e.g. 604800)
  type: string@type-completer-2 # The type of Record this is in the DNS system. For example, A records associate a domain name with an IPv4 address, and AAAA records associate a domain name with an IPv6 address. For more information, see the guides on [DNS Record Types](/docs/products/networking/dns-manager/guides/#dns-record-types). (e.g. A)
  --weight: int # The relative weight of this Record used in the case of identical priority. Higher values are preferred. Only valid and required for SRV record requests. (e.g. 50)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{domainId}/records"
    path_params: [{name: domainId, var: domain_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: port, var: port}, {name: priority, var: priority}, {name: protocol, var: protocol}, {name: service, var: service}, {name: tag, var: tag}, {name: target, var: target}, {name: ttl_sec, var: ttl_sec}, {name: type, var: type}, {name: weight, var: weight}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_id: $domain_id, name: $name, port: $port, priority: $priority, protocol: $protocol, service: $service, tag: $tag, target: $target, ttl_sec: $ttl_sec, type: $type, weight: $weight
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Domain Record Delete
#
# DELETE /domains/{domainId}/records/{recordId}
# Returns: record
# operationId: deleteDomainRecord
export def "delete-domain-record" [
  domain_id: int
  record_id: int
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
    path: "/domains/{domainId}/records/{recordId}"
    path_params: [{name: domainId, var: domain_id}, {name: recordId, var: record_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_id: $domain_id, record_id: $record_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Domain Record View
#
# GET /domains/{domainId}/records/{recordId}
# Returns: record<created: string, id: int, name: string, port: int, priority: int, protocol: string, service: string, tag: string, target: string, ttl_sec: int, type: string, updated: string, weight: int>
# operationId: getDomainRecord
export def "get-domain-record" [
  domain_id: int
  record_id: int
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
    path: "/domains/{domainId}/records/{recordId}"
    path_params: [{name: domainId, var: domain_id}, {name: recordId, var: record_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_id: $domain_id, record_id: $record_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Domain Record Update
#
# PUT /domains/{domainId}/records/{recordId}
# Returns: record<created: string, id: int, name: string, port: int, priority: int, protocol: string, service: string, tag: string, target: string, ttl_sec: int, type: string, updated: string, weight: int>
# operationId: updateDomainRecord
export def "update-domain-record" [
  domain_id: int
  record_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of this Record. For requests, this property's actual usage and whether it is required depends on the type of record this represents: `A` and `AAAA`: The hostname or FQDN of the Record. `NS`: The subdomain, if any, to use with the Domain of the Record. Wildcard NS records (`*`) are not supported. `MX`: The mail subdomain. For example, `sub` for the address `user@sub.example.com` under the `example.com` Domain. Must be an empty string (`""`) for a Null MX Record. `CNAME`: The hostname. Must be unique. Required. `TXT`: The hostname. `SRV`: Unused. Use the `service` property to set the service name for this record. `CAA`: The subdomain. Omit or enter an empty string (`""`) to apply to the entire Domain. `PTR`: See our guide on how to [Configure Your Linode for Reverse DNS (rDNS)](/docs/guides/configure-rdns/). (e.g. test)
  --port: int # The port this Record points to. Only valid and required for SRV record requests. (e.g. 80)
  --priority: int # The priority of the target host for this Record. Lower values are preferred. Only valid for MX and SRV record requests. Required for SRV record requests. Defaults to `0` for MX record requests. Must be `0` for Null MX records. (e.g. 50)
  --protocol: string # The protocol this Record's service communicates with. An underscore (`_`) is prepended automatically to the submitted value for this property. Only valid for SRV record requests. (nullable)
  --service: string # The name of the service. An underscore (`_`) is prepended and a period (`.`) is appended automatically to the submitted value for this property. Only valid and required for SRV record requests. (nullable)
  --tag: string@tag-completer # The tag portion of a CAA record. Only valid and required for CAA record requests. (nullable)
  --target: string # The target for this Record. For requests, this property's actual usage and whether it is required depends on the type of record this represents: `A` and `AAAA`: The IP address. Use `[remote_addr]` to submit the IPv4 address of the request. Required. `NS`: The name server. Must be a valid domain. Required. `MX`: The mail server. Must be a valid domain unless creating a Null MX Record. To create a [Null MX Record](https://datatracker.ietf.org/doc/html/rfc7505), first [remove](/docs/api/domains/#domain-record-delete) any additional MX records, create an MX record with empty strings (`""`) for the `target` and `name`. If a Domain has a Null MX record, new MX records cannot be created. Required. `CNAME`: The alias. Must be a valid domain. Required. `TXT`: The value. Required. `SRV`: The target domain or subdomain. If a subdomain is entered, it is automatically used with the Domain. To configure for a different domain, enter a valid FQDN. For example, the value `www` with a Domain for `example.com` results in a target set to `www.example.com`, whereas the value `sample.com` results in a target set to `sample.com`. Required. `CAA`: The value. For `issue` or `issuewild` tags, the domain of your certificate issuer. For the `iodef` tag, a contact or submission URL (domain, http, https, or mailto). Requirements depend on the tag for this record: * `issue`: The domain of your certificate issuer. Must be a valid domain. * `issuewild`: Must begin with `*`. * `iodef`: Must be either (1) a valid domain, (2) a valid domain prepended with `http://` or `https://`, or (3) a valid email address prepended with `mailto:`. `PTR`: Required. See our guide on how to [Configure Your Linode for Reverse DNS (rDNS)](/docs/guides/configure-rdns/). With the exception of A, AAAA, and CAA records, this field accepts a trailing period. (e.g. 192.0.2.0)
  --ttl-sec: int # "Time to Live" - the amount of time in seconds that this Domain's records may be cached by resolvers or other domain servers. Valid values are 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200 - any other value will be rounded to the nearest valid value. (e.g. 604800)
  --weight: int # The relative weight of this Record used in the case of identical priority. Higher values are preferred. Only valid and required for SRV record requests. (e.g. 50)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/domains/{domainId}/records/{recordId}"
    path_params: [{name: domainId, var: domain_id}, {name: recordId, var: record_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: port, var: port}, {name: priority, var: priority}, {name: protocol, var: protocol}, {name: service, var: service}, {name: tag, var: tag}, {name: target, var: target}, {name: ttl_sec, var: ttl_sec}, {name: weight, var: weight}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_id: $domain_id, record_id: $record_id, name: $name, port: $port, priority: $priority, protocol: $protocol, service: $service, tag: $tag, target: $target, ttl_sec: $ttl_sec, weight: $weight
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Domain Zone File View
#
# GET /domains/{domainId}/zone-file
# Returns: record<zone_file: list<string>>
# operationId: getDomainZone
export def "get-domain-zone" [
  domain_id: string
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
    path: "/domains/{domainId}/zone-file"
    path_params: [{name: domainId, var: domain_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_id: $domain_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Images List
#
# GET /images
# Returns: record<data: table<created: string, created_by: string, deprecated: bool, description: string, eol: string, expiry: string, id: string, is_public: bool, label: string, size: int, status: string, type: string, updated: string, vendor: string>, page: int, pages: int, results: int>
# operationId: getImages
export def "get-images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Image Create
#
# POST /images
# Returns: record<created: string, created_by: string, deprecated: bool, description: string, eol: string, expiry: string, id: string, is_public: bool, label: string, size: int, status: string, type: string, updated: string, vendor: string>
# operationId: createImage
export def "create-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A detailed description of this Image.
  disk_id: int # The ID of the Linode Disk that this Image will be created from. (e.g. 42)
  --label: string # A short title of this Image. Defaults to the label of the Disk it is being created from if not provided.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/images"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: disk_id, var: disk_id}, {name: label, var: label}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, disk_id: $disk_id, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Image Upload
#
# POST /images/upload
# Returns: record<image: record<created: string, created_by: string, deprecated: bool, description: string, eol: string, expiry: string, id: string, is_public: bool, label: string, size: int, status: string, type: string, updated: string, vendor: string>, upload_to: string>
export def "post-images-upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description for the uploaded Image. (e.g. This is an example image in the docs.)
  label: string # Label for the uploaded Image. (e.g. my-image-label)
  region: string # The region to upload to. Once uploaded, the Image can be used in any region. (e.g. eu-central)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/images/upload"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: label, var: label}, {name: region, var: region}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    description: $description, label: $label, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Image Delete
#
# DELETE /images/{imageId}
# Returns: record
# operationId: deleteImage
export def "delete-image" [
  image_id: string
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
    path: "/images/{imageId}"
    path_params: [{name: imageId, var: image_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_id: $image_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Image View
#
# GET /images/{imageId}
# Returns: record<created: string, created_by: string, deprecated: bool, description: string, eol: string, expiry: string, id: string, is_public: bool, label: string, size: int, status: string, type: string, updated: string, vendor: string>
# operationId: getImage
export def "get-image" [
  image_id: string
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
    path: "/images/{imageId}"
    path_params: [{name: imageId, var: image_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_id: $image_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Image Update
#
# PUT /images/{imageId}
# Returns: record<created: string, created_by: string, deprecated: bool, description: string, eol: string, expiry: string, id: string, is_public: bool, label: string, size: int, status: string, type: string, updated: string, vendor: string>
# operationId: updateImage
export def "update-image" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A detailed description of this Image. (nullable, e.g. Example Image description.)
  --label: string # A short description of the Image. (e.g. Debian 11)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/images/{imageId}"
    path_params: [{name: imageId, var: image_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: label, var: label}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_id: $image_id, description: $description, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linodes List
#
# GET /linode/instances
# Returns: record<data: table<alerts: record, backups: record, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: string, ipv4: list, ipv6: string, label: string, region: string, specs: record, status: string, tags: list, type: string, updated: string, watchdog_enabled: bool>, page: int, pages: int, results: int>
# operationId: getLinodeInstances
export def "get-linode-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/linode/instances"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode Create
#
# POST /linode/instances
# Returns: record<alerts: record<cpu: int, io: int, network_in: int, network_out: int, transfer_quota: int>, backups: record<available: bool, enabled: bool, last_successful: string, schedule: record<day: string, window: string>>, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: string, ipv4: list<string>, ipv6: string, label: string, region: string, specs: record<disk: int, memory: int, transfer: int, vcpus: int>, status: string, tags: list<string>, type: string, updated: string, watchdog_enabled: bool>
# operationId: createLinodeInstance
@deprecated --flag group
export def "create-linode-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorized-keys: list<string> # A list of public SSH keys that will be automatically appended to the root user's `~/.ssh/authorized_keys` file when deploying from an Image. (e.g. [ssh-rsa AAAA_valid_public_ssh_key_123456785== user@their-computer])
  --authorized-users: list<string> # A list of usernames. If the usernames have associated SSH keys, the keys will be appended to the root users `~/.ssh/authorized_keys` file automatically when deploying from an Image. (e.g. [myUser, secondaryUser])
  --booted: oneof<nothing, bool> # This field defaults to `true` if the Linode is created with an Image or from a Backup. If it is deployed from an Image or a Backup and you wish it to remain `offline` after deployment, set this to `false`. (default: true)
  --image: string # An Image ID to deploy the Linode Disk from. Access the Images List ([GET /images](/docs/api/images/#images-list)) endpoint with authentication to view all available Images. Official Linode Images start with `linode/`, while your Account's Images start with `private/`. Creating a disk from a Private Image requires `read_only` or `read_write` permissions for that Image. Access the User's Grant Update ([PUT /account/users/{username}/grants](/docs/api/account/#users-grants-update)) endpoint to adjust permissions for an Account Image. (e.g. linode/debian9)
  --root-pass: string # This sets the root user's password on a newly-created Linode Disk when deploying from an Image. * **Required** when creating a Linode Disk from an Image, including when using a StackScript. * Must meet a password strength score requirement that is calculated internally by the API. If the strength requirement is not met, you will receive a `Password does not meet strength requirement` error. (format: password, e.g. aComplexP@ssword)
  --stackscript-data: record # This field is required only if the StackScript being deployed requires input data from the User for successful completion. See [User Defined Fields (UDFs)](/docs/guides/writing-scripts-for-use-with-linode-stackscripts-a-tutorial/#user-defined-fields-udfs) for more details. This field is required to be valid JSON. Total length cannot exceed 65,535 characters. (e.g. {gh_username: linode})
  --stackscript-id: int # A StackScript ID that will cause the referenced StackScript to be run during deployment of this Linode. A compatible `image` is required to use a StackScript. To get a list of available StackScript and their permitted Images see [/stackscripts](/docs/api/stackscripts/#stackscripts-list). This field cannot be used when deploying from a Backup or a Private Image. (e.g. 10079)
  --backup-id: int # A Backup ID from another Linode's available backups. Your User must have `read_write` access to that Linode, the Backup must have a `status` of `successful`, and the Linode must be deployed to the same `region` as the Backup. See [GET /linode/instances/{linodeId}/backups](/docs/api/linode-instances/#backups-list) for a Linode's available backups. This field and the `image` field are mutually exclusive. (e.g. 1234)
  --backups-enabled: oneof<nothing, bool> # If this field is set to `true`, the created Linode will automatically be enrolled in the Linode Backup service. This will incur an additional charge. The cost for the Backup service is dependent on the Type of Linode deployed. This option is always treated as `true` if the account-wide `backups_enabled` setting is `true`. See [account settings](/docs/api/account/#account-settings-view) for more information. Backup pricing is included in the response from [/linodes/types](/docs/api/linode-types/#types-list)
  --group: string # A deprecated property denoting a group label for this Linode. (DEPRECATED, e.g. Linode-Group)
  --interfaces: list # An array of Network Interfaces to add to this Linode's Configuration Profile. Up to three interface objects can be entered in this array. The position in the array determines the interface to which the settings apply: - First/0: eth0 - Second/1: eth1 - Third/2: eth2 When updating a Linode's interfaces, *each interface must be redefined*. An empty interfaces array results in a default public interface configuration only. If no public interface is configured, public IP addresses are still assigned to the Linode but will not be usable without manual configuration. **Note:** Changes to Linode interface configurations can be enabled by rebooting the Linode. **Note:** Only Next Generation Network (NGN) data centers support VLANs. Use the Regions ([/regions](/docs/api/regions/)) endpoint to view the capabilities of data center regions. If a VLAN is attached to your Linode and you attempt to migrate or clone it to a non-NGN data center, the migration or cloning will not initiate. If a Linode cannot be migrated because of an incompatibility, you will be prompted to select a different data center or contact support. **Note:** See the [VLANs Overview](/docs/products/networking/vlans/#technical-specifications) guide to view additional specifications and limitations. — item shape: {ipam_address?: string, label?: string, purpose?: "public"|"vlan"}
  --label: string # The Linode's label is for display purposes only. If no label is provided for a Linode, a default will be assigned. Linode labels have the following constraints: * Must begin and end with an alphanumeric character. * May only consist of alphanumeric characters, dashes (`-`), underscores (`_`) or periods (`.`). * Cannot have two dashes (`--`), underscores (`__`) or periods (`..`) in a row. (e.g. linode123)
  --private-ip: oneof<nothing, bool> # If true, the created Linode will have private networking enabled and assigned a private IPv4 address. (e.g. true)
  region: string # The [Region](/docs/api/regions/#regions-list) where the Linode will be located. (e.g. us-east)
  --swap-size: int # When deploying from an Image, this field is optional, otherwise it is ignored. This is used to set the swap disk size for the newly-created Linode. (default: 512, e.g. 512)
  --tags: list<string> # An array of tags applied to this object. Tags are for organizational purposes only. (e.g. [example tag, another example])
  type: string # The [Linode Type](/docs/api/linode-types/#types-list) of the Linode you are creating. (e.g. g6-standard-2)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/instances"
    body: {content_type: "application/json", kind: json, fields: [{name: authorized_keys, var: authorized_keys}, {name: authorized_users, var: authorized_users}, {name: booted, var: booted}, {name: image, var: image}, {name: root_pass, var: root_pass}, {name: stackscript_data, var: stackscript_data}, {name: stackscript_id, var: stackscript_id}, {name: backup_id, var: backup_id}, {name: backups_enabled, var: backups_enabled}, {name: group, var: group}, {name: interfaces, var: interfaces}, {name: label, var: label}, {name: private_ip, var: private_ip}, {name: region, var: region}, {name: swap_size, var: swap_size}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorized_keys: $authorized_keys, authorized_users: $authorized_users, booted: $booted, image: $image, root_pass: $root_pass, stackscript_data: $stackscript_data, stackscript_id: $stackscript_id, backup_id: $backup_id, backups_enabled: $backups_enabled, group: $group, interfaces: $interfaces, label: $label, private_ip: $private_ip, region: $region, swap_size: $swap_size, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode Delete
#
# DELETE /linode/instances/{linodeId}
# Returns: record
# operationId: deleteLinodeInstance
export def "delete-linode-instance" [
  linode_id: int
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
    path: "/linode/instances/{linodeId}"
    path_params: [{name: linodeId, var: linode_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode View
#
# GET /linode/instances/{linodeId}
# Returns: record<alerts: record<cpu: int, io: int, network_in: int, network_out: int, transfer_quota: int>, backups: record<available: bool, enabled: bool, last_successful: string, schedule: record<day: string, window: string>>, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: string, ipv4: list<string>, ipv6: string, label: string, region: string, specs: record<disk: int, memory: int, transfer: int, vcpus: int>, status: string, tags: list<string>, type: string, updated: string, watchdog_enabled: bool>
# operationId: getLinodeInstance
export def "get-linode-instance" [
  linode_id: int
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
    path: "/linode/instances/{linodeId}"
    path_params: [{name: linodeId, var: linode_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode Update
#
# PUT /linode/instances/{linodeId}
# Returns: record<alerts: record<cpu: int, io: int, network_in: int, network_out: int, transfer_quota: int>, backups: record<available: bool, enabled: bool, last_successful: string, schedule: record<day: string, window: string>>, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: string, ipv4: list<string>, ipv6: string, label: string, region: string, specs: record<disk: int, memory: int, transfer: int, vcpus: int>, status: string, tags: list<string>, type: string, updated: string, watchdog_enabled: bool>
# operationId: updateLinodeInstance
@deprecated --flag group
export def "update-linode-instance" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alerts: record # shape: {cpu?: int, io?: int, network_in?: int, network_out?: int, transfer_quota?: int}
  --backups: record # Information about this Linode's backups status. For information about available backups, see [/linode/instances/{linodeId}/backups](/docs/api/linode-instances/#backups-list). — shape: {schedule?: record}
  --group: string # A deprecated property denoting a group label for this Linode. (DEPRECATED, e.g. Linode-Group)
  --label: string # The Linode's label is for display purposes only. If no label is provided for a Linode, a default will be assigned. Linode labels have the following constraints: * Must begin and end with an alphanumeric character. * May only consist of alphanumeric characters, dashes (`-`), underscores (`_`) or periods (`.`). * Cannot have two dashes (`--`), underscores (`__`) or periods (`..`) in a row. (e.g. linode123)
  --tags: list<string> # An array of tags applied to this object. Tags are for organizational purposes only. (e.g. [example tag, another example])
  --watchdog-enabled: oneof<nothing, bool> # The watchdog, named Lassie, is a Shutdown Watchdog that monitors your Linode and will reboot it if it powers off unexpectedly. It works by issuing a boot job when your Linode powers off without a shutdown job being responsible. To prevent a loop, Lassie will give up if there have been more than 5 boot jobs issued within 15 minutes. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/linode/instances/{linodeId}"
    path_params: [{name: linodeId, var: linode_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: alerts, var: alerts}, {name: backups, var: backups}, {name: group, var: group}, {name: label, var: label}, {name: tags, var: tags}, {name: watchdog_enabled, var: watchdog_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, alerts: $alerts, backups: $backups, group: $group, label: $label, tags: $tags, watchdog_enabled: $watchdog_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Backups List
#
# GET /linode/instances/{linodeId}/backups
# Returns: record<automatic: table<available: bool, configs: list, created: string, disks: list, finished: string, id: int, label: string, status: string, type: string, updated: string>, snapshot: record<current: record<available: bool, configs: list, created: string, disks: list, finished: string, id: int, label: string, status: string, type: string, updated: string>, in_progress: record<available: bool, configs: list, created: string, disks: list, finished: string, id: int, label: string, status: string, type: string, updated: string>>>
# operationId: getBackups
export def "get-backups" [
  linode_id: int
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
    path: "/linode/instances/{linodeId}/backups"
    path_params: [{name: linodeId, var: linode_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Snapshot Create
#
# POST /linode/instances/{linodeId}/backups
# Returns: record<available: bool, configs: list<string>, created: string, disks: table<filesystem: string, label: string, size: int>, finished: string, id: int, label: string, status: string, type: string, updated: string>
# operationId: createSnapshot
export def "create-snapshot" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string # The label for the new snapshot. (e.g. SnapshotLabel)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/instances/{linodeId}/backups"
    path_params: [{name: linodeId, var: linode_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Backups Cancel
#
# POST /linode/instances/{linodeId}/backups/cancel
# Returns: record
# operationId: cancelBackups
export def "cancel-backups" [
  linode_id: int
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
    method: post
    path: "/linode/instances/{linodeId}/backups/cancel"
    path_params: [{name: linodeId, var: linode_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Backups Enable
#
# POST /linode/instances/{linodeId}/backups/enable
# Returns: record
# operationId: enableBackups
export def "enable-backups" [
  linode_id: int
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
    method: post
    path: "/linode/instances/{linodeId}/backups/enable"
    path_params: [{name: linodeId, var: linode_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Backup View
#
# GET /linode/instances/{linodeId}/backups/{backupId}
# Returns: record<available: bool, configs: list<string>, created: string, disks: table<filesystem: string, label: string, size: int>, finished: string, id: int, label: string, status: string, type: string, updated: string>
# operationId: getBackup
export def "get-backup" [
  linode_id: int
  backup_id: int
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
    path: "/linode/instances/{linodeId}/backups/{backupId}"
    path_params: [{name: linodeId, var: linode_id}, {name: backupId, var: backup_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, backup_id: $backup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Backup Restore
#
# POST /linode/instances/{linodeId}/backups/{backupId}/restore
# Returns: record
# operationId: restoreBackup
export def "restore-backup" [
  linode_id: int
  backup_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-linode-id: int # The ID of the Linode to restore a Backup to. (e.g. 234) (spec name: linode_id)
  --overwrite: oneof<nothing, bool> # If True, deletes all Disks and Configs on the target Linode before restoring. If False, and the Disk image size is larger than the available space on the Linode, an error message indicating insufficient space is returned. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/instances/{linodeId}/backups/{backupId}/restore"
    path_params: [{name: linodeId, var: linode_id}, {name: backupId, var: backup_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: linode_id, var: body_linode_id, required: true}, {name: overwrite, var: overwrite}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, backup_id: $backup_id, body_linode_id: $body_linode_id, overwrite: $overwrite
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode Boot
#
# POST /linode/instances/{linodeId}/boot
# Returns: record
# operationId: bootLinodeInstance
export def "boot-linode-instance" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-id: int # The Linode Config ID to boot into.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/instances/{linodeId}/boot"
    path_params: [{name: linodeId, var: linode_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config_id, var: config_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode Clone
#
# POST /linode/instances/{linodeId}/clone
# Returns: record<alerts: record<cpu: int, io: int, network_in: int, network_out: int, transfer_quota: int>, backups: record<available: bool, enabled: bool, last_successful: string, schedule: record<day: string, window: string>>, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: string, ipv4: list<string>, ipv6: string, label: string, region: string, specs: record<disk: int, memory: int, transfer: int, vcpus: int>, status: string, tags: list<string>, type: string, updated: string, watchdog_enabled: bool>
# operationId: cloneLinodeInstance
@deprecated --flag group
export def "clone-linode-instance" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --backups-enabled: oneof<nothing, bool> # If this field is set to `true`, the created Linode will automatically be enrolled in the Linode Backup service. This will incur an additional charge. Pricing is included in the response from [/linodes/types](/docs/api/linode-types/#types-list). * Can only be included when cloning to a new Linode. (e.g. true)
  --configs: list<int> # An array of configuration profile IDs. * If the `configs` parameter **is not provided**, then **all configuration profiles and their associated disks will be cloned** from the source Linode. Any disks specified by the `disks` parameter will also be cloned. * **If an empty array is provided** for the `configs` parameter, then **no configuration profiles (nor their associated disks) will be cloned** from the source Linode. Any disks specified by the `disks` parameter will still be cloned. * **If a non-empty array is provided** for the `configs` parameter, then **the configuration profiles specified in the array (and their associated disks) will be cloned** from the source Linode. Any disks specified by the `disks` parameter will also be cloned.
  --disks: list<int> # An array of disk IDs. * If the `disks` parameter **is not provided**, then **no extra disks will be cloned** from the source Linode. All disks associated with the configuration profiles specified by the `configs` parameter will still be cloned. * **If an empty array is provided** for the `disks` parameter, then **no extra disks will be cloned** from the source Linode. All disks associated with the configuration profiles specified by the `configs` parameter will still be cloned. * **If a non-empty array is provided** for the `disks` parameter, then **the disks specified in the array will be cloned** from the source Linode, in addition to any disks associated with the configuration profiles specified by the `configs` parameter.
  --group: string # A label used to group Linodes for display. Linodes are not required to have a group. (DEPRECATED, e.g. Linode-Group)
  --label: string # The label to assign this Linode when cloning to a new Linode. * Can only be provided when cloning to a new Linode. * Defaults to "linode". (e.g. cloned-linode)
  --body-linode-id: int # If an existing Linode is the target for the clone, the ID of that Linode. The existing Linode must have enough resources to accept the clone. (e.g. 124) (spec name: linode_id)
  --private-ip: oneof<nothing, bool> # If true, the created Linode will have private networking enabled and assigned a private IPv4 address. * Can only be provided when cloning to a new Linode. (e.g. true)
  --region: string # This is the Region where the Linode will be deployed. To view all available Regions you can deploy to see [/regions](/docs/api/regions/#regions-list). * Region can only be provided and is required when cloning to a new Linode. (e.g. us-east)
  --type: string # A Linode's Type determines what resources are available to it, including disk space, memory, and virtual cpus. The amounts available to a specific Linode are returned as `specs` on the Linode object. To view all available Linode Types you can deploy with see [/linode/types](/docs/api/linode-types/#types-list). * Type can only be provided and is required when cloning to a new Linode. (e.g. g6-standard-2)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/instances/{linodeId}/clone"
    path_params: [{name: linodeId, var: linode_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: backups_enabled, var: backups_enabled}, {name: configs, var: configs}, {name: disks, var: disks}, {name: group, var: group}, {name: label, var: label}, {name: linode_id, var: body_linode_id}, {name: private_ip, var: private_ip}, {name: region, var: region}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, backups_enabled: $backups_enabled, configs: $configs, disks: $disks, group: $group, label: $label, body_linode_id: $body_linode_id, private_ip: $private_ip, region: $region, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configuration Profiles List
#
# GET /linode/instances/{linodeId}/configs
# Returns: record<data: table<comments: string, devices: record, helpers: record, id: int, interfaces: list, kernel: string, label: string, memory_limit: int, root_device: string, run_level: string, virt_mode: string>, page: int, pages: int, results: int>
# operationId: getLinodeConfigs
export def "get-linode-configs" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/linode/instances/{linodeId}/configs"
    path_params: [{name: linodeId, var: linode_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configuration Profile Create
#
# POST /linode/instances/{linodeId}/configs
# Returns: record<comments: string, devices: record<sda: record<disk_id: int, volume_id: int>, sdb: record<disk_id: int, volume_id: int>, sdc: record<disk_id: int, volume_id: int>, sdd: record<disk_id: int, volume_id: int>, sde: record<disk_id: int, volume_id: int>, sdf: record<disk_id: int, volume_id: int>, sdg: record<disk_id: int, volume_id: int>, sdh: record<disk_id: int, volume_id: int>>, helpers: record<devtmpfs_automount: bool, distro: bool, modules_dep: bool, network: bool, updatedb_disabled: bool>, id: int, interfaces: table<ipam_address: string, label: string, purpose: string>, kernel: string, label: string, memory_limit: int, root_device: string, run_level: string, virt_mode: string>
# operationId: addLinodeConfig
export def "add-linode-config" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comments: string # Optional field for arbitrary User comments on this Config. (nullable, e.g. This is my main Config)
  devices: record # A dictionary of device disks to use as a device map in a Linode's configuration profile. * An empty device disk dictionary or a dictionary with empty values for device slots is allowed. * If no devices are specified, booting from this configuration will hold until a device exists that allows the boot process to start. — shape: {sda?: record, sdb?: record, sdc?: record, sdd?: record, sde?: record, sdf?: record, sdg?: record, sdh?: record}
  --helpers: record # Helpers enabled when booting to this Linode Config. — shape: {devtmpfs_automount?: bool, distro?: bool, modules_dep?: bool, network?: bool, updatedb_disabled?: bool}
  --interfaces: list # An array of Network Interfaces to add to this Linode's Configuration Profile. Up to three interface objects can be entered in this array. The position in the array determines the interface to which the settings apply: - First/0: eth0 - Second/1: eth1 - Third/2: eth2 When updating a Linode's interfaces, *each interface must be redefined*. An empty interfaces array results in a default public interface configuration only. If no public interface is configured, public IP addresses are still assigned to the Linode but will not be usable without manual configuration. **Note:** Changes to Linode interface configurations can be enabled by rebooting the Linode. **Note:** Only Next Generation Network (NGN) data centers support VLANs. Use the Regions ([/regions](/docs/api/regions/)) endpoint to view the capabilities of data center regions. If a VLAN is attached to your Linode and you attempt to migrate or clone it to a non-NGN data center, the migration or cloning will not initiate. If a Linode cannot be migrated because of an incompatibility, you will be prompted to select a different data center or contact support. **Note:** See the [VLANs Overview](/docs/products/networking/vlans/#technical-specifications) guide to view additional specifications and limitations. — item shape: {ipam_address?: string, label?: string, purpose?: "public"|"vlan"}
  --kernel: string # A Kernel ID to boot a Linode with. Defaults to "linode/latest-64bit". (e.g. linode/latest-64bit)
  label: string # The Config's label is for display purposes only. (e.g. My Config)
  --memory-limit: int # Defaults to the total RAM of the Linode. (e.g. 2048)
  --root-device: string # The root device to boot. * If no value or an invalid value is provided, root device will default to `/dev/sda`. * If the device specified at the root device location is not mounted, the Linode will not boot until a device is mounted. (e.g. /dev/sda)
  --run-level: string@run-level-completer # Defines the state of your Linode after booting. Defaults to `default`. (e.g. default)
  --virt-mode: string@virt-mode-completer # Controls the virtualization mode. Defaults to `paravirt`. * `paravirt` is suitable for most cases. Linodes running in paravirt mode share some qualities with the host, ultimately making it run faster since there is less transition between it and the host. * `fullvirt` affords more customization, but is slower because 100% of the VM is virtualized. (e.g. paravirt)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/instances/{linodeId}/configs"
    path_params: [{name: linodeId, var: linode_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: comments, var: comments}, {name: devices, var: devices}, {name: helpers, var: helpers}, {name: interfaces, var: interfaces}, {name: kernel, var: kernel}, {name: label, var: label}, {name: memory_limit, var: memory_limit}, {name: root_device, var: root_device}, {name: run_level, var: run_level}, {name: virt_mode, var: virt_mode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, comments: $comments, devices: $devices, helpers: $helpers, interfaces: $interfaces, kernel: $kernel, label: $label, memory_limit: $memory_limit, root_device: $root_device, run_level: $run_level, virt_mode: $virt_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configuration Profile Delete
#
# DELETE /linode/instances/{linodeId}/configs/{configId}
# Returns: record
# operationId: deleteLinodeConfig
export def "delete-linode-config" [
  linode_id: int
  config_id: int
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
    path: "/linode/instances/{linodeId}/configs/{configId}"
    path_params: [{name: linodeId, var: linode_id}, {name: configId, var: config_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configuration Profile View
#
# GET /linode/instances/{linodeId}/configs/{configId}
# Returns: record<comments: string, devices: record<sda: record<disk_id: int, volume_id: int>, sdb: record<disk_id: int, volume_id: int>, sdc: record<disk_id: int, volume_id: int>, sdd: record<disk_id: int, volume_id: int>, sde: record<disk_id: int, volume_id: int>, sdf: record<disk_id: int, volume_id: int>, sdg: record<disk_id: int, volume_id: int>, sdh: record<disk_id: int, volume_id: int>>, helpers: record<devtmpfs_automount: bool, distro: bool, modules_dep: bool, network: bool, updatedb_disabled: bool>, id: int, interfaces: table<ipam_address: string, label: string, purpose: string>, kernel: string, label: string, memory_limit: int, root_device: string, run_level: string, virt_mode: string>
# operationId: getLinodeConfig
export def "get-linode-config" [
  linode_id: int
  config_id: int
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
    path: "/linode/instances/{linodeId}/configs/{configId}"
    path_params: [{name: linodeId, var: linode_id}, {name: configId, var: config_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configuration Profile Update
#
# PUT /linode/instances/{linodeId}/configs/{configId}
# Returns: record<comments: string, devices: record<sda: record<disk_id: int, volume_id: int>, sdb: record<disk_id: int, volume_id: int>, sdc: record<disk_id: int, volume_id: int>, sdd: record<disk_id: int, volume_id: int>, sde: record<disk_id: int, volume_id: int>, sdf: record<disk_id: int, volume_id: int>, sdg: record<disk_id: int, volume_id: int>, sdh: record<disk_id: int, volume_id: int>>, helpers: record<devtmpfs_automount: bool, distro: bool, modules_dep: bool, network: bool, updatedb_disabled: bool>, id: int, interfaces: table<ipam_address: string, label: string, purpose: string>, kernel: string, label: string, memory_limit: int, root_device: string, run_level: string, virt_mode: string>
# operationId: updateLinodeConfig
export def "update-linode-config" [
  linode_id: int
  config_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comments: string # Optional field for arbitrary User comments on this Config. (nullable, e.g. This is my main Config)
  --devices: record # A dictionary of device disks to use as a device map in a Linode's configuration profile. * An empty device disk dictionary or a dictionary with empty values for device slots is allowed. * If no devices are specified, booting from this configuration will hold until a device exists that allows the boot process to start. — shape: {sda?: record, sdb?: record, sdc?: record, sdd?: record, sde?: record, sdf?: record, sdg?: record, sdh?: record}
  --helpers: record # Helpers enabled when booting to this Linode Config. — shape: {devtmpfs_automount?: bool, distro?: bool, modules_dep?: bool, network?: bool, updatedb_disabled?: bool}
  --interfaces: list # An array of Network Interfaces to add to this Linode's Configuration Profile. Up to three interface objects can be entered in this array. The position in the array determines the interface to which the settings apply: - First/0: eth0 - Second/1: eth1 - Third/2: eth2 When updating a Linode's interfaces, *each interface must be redefined*. An empty interfaces array results in a default public interface configuration only. If no public interface is configured, public IP addresses are still assigned to the Linode but will not be usable without manual configuration. **Note:** Changes to Linode interface configurations can be enabled by rebooting the Linode. **Note:** Only Next Generation Network (NGN) data centers support VLANs. Use the Regions ([/regions](/docs/api/regions/)) endpoint to view the capabilities of data center regions. If a VLAN is attached to your Linode and you attempt to migrate or clone it to a non-NGN data center, the migration or cloning will not initiate. If a Linode cannot be migrated because of an incompatibility, you will be prompted to select a different data center or contact support. **Note:** See the [VLANs Overview](/docs/products/networking/vlans/#technical-specifications) guide to view additional specifications and limitations. — item shape: {ipam_address?: string, label?: string, purpose?: "public"|"vlan"}
  --kernel: string # A Kernel ID to boot a Linode with. Defaults to "linode/latest-64bit". (e.g. linode/latest-64bit)
  --label: string # The Config's label is for display purposes only. (e.g. My Config)
  --memory-limit: int # Defaults to the total RAM of the Linode. (e.g. 2048)
  --root-device: string # The root device to boot. * If no value or an invalid value is provided, root device will default to `/dev/sda`. * If the device specified at the root device location is not mounted, the Linode will not boot until a device is mounted. (e.g. /dev/sda)
  --run-level: string@run-level-completer # Defines the state of your Linode after booting. Defaults to `default`. (e.g. default)
  --virt-mode: string@virt-mode-completer # Controls the virtualization mode. Defaults to `paravirt`. * `paravirt` is suitable for most cases. Linodes running in paravirt mode share some qualities with the host, ultimately making it run faster since there is less transition between it and the host. * `fullvirt` affords more customization, but is slower because 100% of the VM is virtualized. (e.g. paravirt)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/linode/instances/{linodeId}/configs/{configId}"
    path_params: [{name: linodeId, var: linode_id}, {name: configId, var: config_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: comments, var: comments}, {name: devices, var: devices}, {name: helpers, var: helpers}, {name: interfaces, var: interfaces}, {name: kernel, var: kernel}, {name: label, var: label}, {name: memory_limit, var: memory_limit}, {name: root_device, var: root_device}, {name: run_level, var: run_level}, {name: virt_mode, var: virt_mode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, config_id: $config_id, comments: $comments, devices: $devices, helpers: $helpers, interfaces: $interfaces, kernel: $kernel, label: $label, memory_limit: $memory_limit, root_device: $root_device, run_level: $run_level, virt_mode: $virt_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disks List
#
# GET /linode/instances/{linodeId}/disks
# Returns: record<data: table<created: string, filesystem: string, id: int, label: string, size: int, status: string, updated: string>, page: int, pages: int, results: int>
# operationId: getLinodeDisks
export def "get-linode-disks" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/linode/instances/{linodeId}/disks"
    path_params: [{name: linodeId, var: linode_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disk Create
#
# POST /linode/instances/{linodeId}/disks
# Returns: record<created: string, filesystem: string, id: int, label: string, size: int, status: string, updated: string>
# operationId: addLinodeDisk
export def "add-linode-disk" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorized-keys: list<string> # A list of public SSH keys that will be automatically appended to the root user's `~/.ssh/authorized_keys` file when deploying from an Image. (e.g. [ssh-rsa AAAA_valid_public_ssh_key_123456785== user@their-computer])
  --authorized-users: list<string> # A list of usernames. If the usernames have associated SSH keys, the keys will be appended to the root users `~/.ssh/authorized_keys` file automatically when deploying from an Image. (e.g. [myUser, secondaryUser])
  --filesystem: string@filesystem-completer # The Disk filesystem can be one of: * raw - No filesystem, just a raw binary stream. * swap - Linux swap area. * ext3 - The ext3 journaling filesystem for Linux. * ext4 - The ext4 journaling filesystem for Linux. * initrd - initrd (uncompressed initrd, ext2, max 32 MB). (e.g. ext4)
  --image: string # An Image ID to deploy the Linode Disk from. Access the Images List ([GET /images](/docs/api/images/#images-list)) endpoint with authentication to view all available Images. Official Linode Images start with `linode/`, while your Account's Images start with `private/`. Creating a disk from a Private Image requires `read_only` or `read_write` permissions for that Image. Access the User's Grant Update ([PUT /account/users/{username}/grants](/docs/api/account/#users-grants-update)) endpoint to adjust permissions for an Account Image. (e.g. linode/debian9)
  --label: string # The Disk's label is for display purposes only. (e.g. Debian 9 Disk)
  --root-pass: string # This sets the root user's password on a newly-created Linode Disk when deploying from an Image. * **Required** when creating a Linode Disk from an Image, including when using a StackScript. * Must meet a password strength score requirement that is calculated internally by the API. If the strength requirement is not met, you will receive a `Password does not meet strength requirement` error. (format: password, e.g. aComplexP@ssword)
  size: int # The size of the Disk in MB. Images require a minimum size. Access the Image View ([GET /images/{imageID}](/docs/api/images/#image-view)) endpoint to view its size. (e.g. 48640)
  --stackscript-data: record # This field is required only if the StackScript being deployed requires input data from the User for successful completion. See [User Defined Fields (UDFs)](/docs/guides/writing-scripts-for-use-with-linode-stackscripts-a-tutorial/#user-defined-fields-udfs) for more details. This field is required to be valid JSON. Total length cannot exceed 65,535 characters. (e.g. {gh_username: linode})
  --stackscript-id: int # A StackScript ID that will cause the referenced StackScript to be run during deployment of this Linode. A compatible `image` is required to use a StackScript. To get a list of available StackScript and their permitted Images see [/stackscripts](/docs/api/stackscripts/#stackscripts-list). This field cannot be used when deploying from a Backup or a Private Image. (e.g. 10079)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/instances/{linodeId}/disks"
    path_params: [{name: linodeId, var: linode_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorized_keys, var: authorized_keys}, {name: authorized_users, var: authorized_users}, {name: filesystem, var: filesystem}, {name: image, var: image}, {name: label, var: label}, {name: root_pass, var: root_pass}, {name: size, var: size}, {name: stackscript_data, var: stackscript_data}, {name: stackscript_id, var: stackscript_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, authorized_keys: $authorized_keys, authorized_users: $authorized_users, filesystem: $filesystem, image: $image, label: $label, root_pass: $root_pass, size: $size, stackscript_data: $stackscript_data, stackscript_id: $stackscript_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disk Delete
#
# DELETE /linode/instances/{linodeId}/disks/{diskId}
# Returns: record
# operationId: deleteDisk
export def "delete-disk" [
  linode_id: int
  disk_id: int
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
    path: "/linode/instances/{linodeId}/disks/{diskId}"
    path_params: [{name: linodeId, var: linode_id}, {name: diskId, var: disk_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, disk_id: $disk_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disk View
#
# GET /linode/instances/{linodeId}/disks/{diskId}
# Returns: record<created: string, filesystem: string, id: int, label: string, size: int, status: string, updated: string>
# operationId: getLinodeDisk
export def "get-linode-disk" [
  linode_id: int
  disk_id: int
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
    path: "/linode/instances/{linodeId}/disks/{diskId}"
    path_params: [{name: linodeId, var: linode_id}, {name: diskId, var: disk_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, disk_id: $disk_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disk Update
#
# PUT /linode/instances/{linodeId}/disks/{diskId}
# Returns: record<created: string, filesystem: string, id: int, label: string, size: int, status: string, updated: string>
# operationId: updateDisk
export def "update-disk" [
  linode_id: int
  disk_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filesystem: string@filesystem-completer # The Disk filesystem can be one of: * raw - No filesystem, just a raw binary stream. * swap - Linux swap area. * ext3 - The ext3 journaling filesystem for Linux. * ext4 - The ext4 journaling filesystem for Linux. * initrd - initrd (uncompressed initrd, ext2, max 32 MB). (e.g. ext4)
  --label: string # The Disk's label is for display purposes only. (e.g. Debian 9 Disk)
  --size: int # The size of the Disk in MB. (e.g. 48640)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/linode/instances/{linodeId}/disks/{diskId}"
    path_params: [{name: linodeId, var: linode_id}, {name: diskId, var: disk_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: filesystem, var: filesystem}, {name: label, var: label}, {name: size, var: size}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, disk_id: $disk_id, filesystem: $filesystem, label: $label, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disk Clone
#
# POST /linode/instances/{linodeId}/disks/{diskId}/clone
# Returns: record<created: string, filesystem: string, id: int, label: string, size: int, status: string, updated: string>
# operationId: cloneLinodeDisk
export def "clone-linode-disk" [
  linode_id: int
  disk_id: int
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
    method: post
    path: "/linode/instances/{linodeId}/disks/{diskId}/clone"
    path_params: [{name: linodeId, var: linode_id}, {name: diskId, var: disk_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, disk_id: $disk_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disk Root Password Reset
#
# POST /linode/instances/{linodeId}/disks/{diskId}/password
# Returns: record
# operationId: resetDiskPassword
export def "reset-disk-password" [
  linode_id: int
  disk_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # The new root password for the OS installed on this Disk. The password must meet the complexity strength validation requirements for a strong password. (e.g. another@complex^Password123)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/instances/{linodeId}/disks/{diskId}/password"
    path_params: [{name: linodeId, var: linode_id}, {name: diskId, var: disk_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, disk_id: $disk_id, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disk Resize
#
# POST /linode/instances/{linodeId}/disks/{diskId}/resize
# Returns: record
# operationId: resizeDisk
export def "resize-disk" [
  linode_id: int
  disk_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  size: int # The desired size, in MB, of the disk. (e.g. 2048)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/instances/{linodeId}/disks/{diskId}/resize"
    path_params: [{name: linodeId, var: linode_id}, {name: diskId, var: disk_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: size, var: size}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, disk_id: $disk_id, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Firewalls List
#
# GET /linode/instances/{linodeId}/firewalls
# Returns: record<data: table<created: string, id: int, label: string, rules: record, status: string, tags: list, updated: string>, page: int, pages: int, results: int>
# operationId: getLinodeFirewalls
export def "get-linode-firewalls" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/linode/instances/{linodeId}/firewalls"
    path_params: [{name: linodeId, var: linode_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Networking Information List
#
# GET /linode/instances/{linodeId}/ips
# Returns: record<ipv4: record<private: list<record>, public: list<record>, reserved: list<record>, shared: list<record>>, ipv6: record<global: record<prefix: int, range: string, region: string, route_target: string>, link_local: record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>, slaac: record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>>>
# operationId: getLinodeIPs
export def "get-linode-i-ps" [
  linode_id: int
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
    path: "/linode/instances/{linodeId}/ips"
    path_params: [{name: linodeId, var: linode_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IPv4 Address Allocate
#
# POST /linode/instances/{linodeId}/ips
# Returns: record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>
# operationId: addLinodeIP
export def "add-linode-ip" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --public: oneof<nothing, bool> # Whether to create a public or private IPv4 address. (e.g. true)
  type: string@type-completer-3 # The type of address you are allocating. Only IPv4 addresses may be allocated through this endpoint. (e.g. ipv4)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/instances/{linodeId}/ips"
    path_params: [{name: linodeId, var: linode_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: public, var: public, required: true}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, public: $public, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IPv4 Address Delete
#
# DELETE /linode/instances/{linodeId}/ips/{address}
# Returns: record
# operationId: removeLinodeIP
export def "remove-linode-ip" [
  linode_id: int
  address: string
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
    path: "/linode/instances/{linodeId}/ips/{address}"
    path_params: [{name: linodeId, var: linode_id}, {name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IP Address View
#
# GET /linode/instances/{linodeId}/ips/{address}
# Returns: record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>
# operationId: getLinodeIP
export def "get-linode-ip" [
  linode_id: int
  address: string
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
    path: "/linode/instances/{linodeId}/ips/{address}"
    path_params: [{name: linodeId, var: linode_id}, {name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IP Address Update
#
# PUT /linode/instances/{linodeId}/ips/{address}
# Returns: record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>
# operationId: updateLinodeIP
export def "update-linode-ip" [
  linode_id: int
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rdns: string # The reverse DNS assigned to this address. For public IPv4 addresses, this will be set to a default value provided by Linode if not explicitly set. (nullable, e.g. test.example.org)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/linode/instances/{linodeId}/ips/{address}"
    path_params: [{name: linodeId, var: linode_id}, {name: address, var: address}]
    body: {content_type: "application/json", kind: json, fields: [{name: rdns, var: rdns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, address: $address, rdns: $rdns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DC Migration/Pending Host Migration Initiate
#
# POST /linode/instances/{linodeId}/migrate
# Returns: record
# operationId: migrateLinodeInstance
export def "migrate-linode-instance" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --region: string # The region to which the Linode will be migrated. Must be a valid region slug. A list of regions can be viewed by using the [GET /regions](/docs/api/regions/#regions-list) endpoint. A cross data center migration will cancel a pending migration that has not yet been initiated. A cross data center migration will initiate a `linode_migrate_datacenter_create` event. (e.g. us-east)
  --upgrade: oneof<nothing, bool> # When initiating a cross DC migration, setting this value to true will also ensure that the Linode is upgraded to the latest generation of hardware that corresponds to your Linode's Type, if any free upgrades are available for it. If no free upgrades are available, and this value is set to true, then the endpoint will return a 400 error code and the migration will not be performed. If the data center set in the `region` field does not allow upgrades, then the endpoint will return a 400 error code and the migration will not be performed. (default: false, e.g. false)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/instances/{linodeId}/migrate"
    path_params: [{name: linodeId, var: linode_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: region, var: region}, {name: upgrade, var: upgrade}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, region: $region, upgrade: $upgrade
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode Upgrade
#
# POST /linode/instances/{linodeId}/mutate
# Returns: record
# operationId: mutateLinodeInstance
export def "mutate-linode-instance" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-auto-disk-resize: oneof<nothing, bool> # Automatically resize disks when resizing a Linode. When resizing down to a smaller plan your Linode's data must fit within the smaller disk size. (default: true, e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/instances/{linodeId}/mutate"
    path_params: [{name: linodeId, var: linode_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allow_auto_disk_resize, var: allow_auto_disk_resize}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, allow_auto_disk_resize: $allow_auto_disk_resize
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode NodeBalancers View
#
# GET /linode/instances/{linodeId}/nodebalancers
# Returns: record<data: table<client_conn_throttle: int, created: string, hostname: string, id: int, ipv4: string, ipv6: string, label: string, region: string, tags: list, transfer: record, updated: string>, page: int, pages: int, results: int>
# operationId: getLinodeNodeBalancers
export def "get-linode-node-balancers" [
  linode_id: int
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
    path: "/linode/instances/{linodeId}/nodebalancers"
    path_params: [{name: linodeId, var: linode_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode Root Password Reset
#
# POST /linode/instances/{linodeId}/password
# Returns: record
# operationId: resetLinodePassword
export def "reset-linode-password" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  root_pass: string # The root user's password on this Linode. Linode passwords must meet a password strength score requirement that is calculated internally by the API. If the strength requirement is not met, you will receive a Password does not meet strength requirement error. (e.g. a$eCure4assw0rd!43v51)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/instances/{linodeId}/password"
    path_params: [{name: linodeId, var: linode_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: root_pass, var: root_pass}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, root_pass: $root_pass
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode Reboot
#
# POST /linode/instances/{linodeId}/reboot
# Returns: record
# operationId: rebootLinodeInstance
export def "reboot-linode-instance" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-id: int # The Linode Config ID to reboot into. If null or omitted, the last booted config will be used. If there was no last booted config and this Linode only has one config, it will be used. If a config cannot be determined, an error will be returned.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/instances/{linodeId}/reboot"
    path_params: [{name: linodeId, var: linode_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config_id, var: config_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode Rebuild
#
# POST /linode/instances/{linodeId}/rebuild
# Returns: record<alerts: record<cpu: int, io: int, network_in: int, network_out: int, transfer_quota: int>, backups: record<available: bool, enabled: bool, last_successful: string, schedule: record<day: string, window: string>>, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: string, ipv4: list<string>, ipv6: string, label: string, region: string, specs: record<disk: int, memory: int, transfer: int, vcpus: int>, status: string, tags: list<string>, type: string, updated: string, watchdog_enabled: bool>
# operationId: rebuildLinodeInstance
export def "rebuild-linode-instance" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorized-keys: list<string> # A list of public SSH keys that will be automatically appended to the root user's `~/.ssh/authorized_keys` file when deploying from an Image. (e.g. [ssh-rsa AAAA_valid_public_ssh_key_123456785== user@their-computer])
  --authorized-users: list<string> # A list of usernames. If the usernames have associated SSH keys, the keys will be appended to the root users `~/.ssh/authorized_keys` file automatically when deploying from an Image. (e.g. [myUser, secondaryUser])
  --booted: oneof<nothing, bool> # This field defaults to `true` if the Linode is created with an Image or from a Backup. If it is deployed from an Image or a Backup and you wish it to remain `offline` after deployment, set this to `false`. (default: true)
  image: string # An Image ID to deploy the Linode Disk from. Access the Images List ([GET /images](/docs/api/images/#images-list)) endpoint with authentication to view all available Images. Official Linode Images start with `linode/`, while your Account's Images start with `private/`. Creating a disk from a Private Image requires `read_only` or `read_write` permissions for that Image. Access the User's Grant Update ([PUT /account/users/{username}/grants](/docs/api/account/#users-grants-update)) endpoint to adjust permissions for an Account Image. (e.g. linode/debian9)
  root_pass: string # This sets the root user's password on a newly-created Linode Disk when deploying from an Image. * **Required** when creating a Linode Disk from an Image, including when using a StackScript. * Must meet a password strength score requirement that is calculated internally by the API. If the strength requirement is not met, you will receive a `Password does not meet strength requirement` error. (format: password, e.g. aComplexP@ssword)
  --stackscript-data: record # This field is required only if the StackScript being deployed requires input data from the User for successful completion. See [User Defined Fields (UDFs)](/docs/guides/writing-scripts-for-use-with-linode-stackscripts-a-tutorial/#user-defined-fields-udfs) for more details. This field is required to be valid JSON. Total length cannot exceed 65,535 characters. (e.g. {gh_username: linode})
  --stackscript-id: int # A StackScript ID that will cause the referenced StackScript to be run during deployment of this Linode. A compatible `image` is required to use a StackScript. To get a list of available StackScript and their permitted Images see [/stackscripts](/docs/api/stackscripts/#stackscripts-list). This field cannot be used when deploying from a Backup or a Private Image. (e.g. 10079)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/instances/{linodeId}/rebuild"
    path_params: [{name: linodeId, var: linode_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorized_keys, var: authorized_keys}, {name: authorized_users, var: authorized_users}, {name: booted, var: booted}, {name: image, var: image}, {name: root_pass, var: root_pass}, {name: stackscript_data, var: stackscript_data}, {name: stackscript_id, var: stackscript_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, authorized_keys: $authorized_keys, authorized_users: $authorized_users, booted: $booted, image: $image, root_pass: $root_pass, stackscript_data: $stackscript_data, stackscript_id: $stackscript_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode Boot into Rescue Mode
#
# POST /linode/instances/{linodeId}/rescue
# Returns: record
# operationId: rescueLinodeInstance
export def "rescue-linode-instance" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --devices: record # shape: {sda?: record, sdb?: record, sdc?: record, sdd?: record, sde?: record, sdf?: record, sdg?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/instances/{linodeId}/rescue"
    path_params: [{name: linodeId, var: linode_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: devices, var: devices}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, devices: $devices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode Resize
#
# POST /linode/instances/{linodeId}/resize
# Returns: record
# operationId: resizeLinodeInstance
export def "resize-linode-instance" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-auto-disk-resize: oneof<nothing, bool> # Automatically resize disks when resizing a Linode. When resizing down to a smaller plan your Linode's data must fit within the smaller disk size. (default: true, e.g. true)
  type: string # The ID representing the Linode Type. (e.g. g6-standard-2)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/instances/{linodeId}/resize"
    path_params: [{name: linodeId, var: linode_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allow_auto_disk_resize, var: allow_auto_disk_resize}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, allow_auto_disk_resize: $allow_auto_disk_resize, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode Shut Down
#
# POST /linode/instances/{linodeId}/shutdown
# Returns: record
# operationId: shutdownLinodeInstance
export def "shutdown-linode-instance" [
  linode_id: int
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
    method: post
    path: "/linode/instances/{linodeId}/shutdown"
    path_params: [{name: linodeId, var: linode_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode Statistics View
#
# GET /linode/instances/{linodeId}/stats
# Returns: record<cpu: list<list<float>>, io: record<io: list<list>, swap: list<list>>, netv4: record<in: list<list>, out: list<list>, private_in: list<list>, private_out: list<list>>, netv6: record<in: list<list>, out: list<list>, private_in: list<list>, private_out: list<list>>, title: string>
# operationId: getLinodeStats
export def "get-linode-stats" [
  linode_id: int
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
    path: "/linode/instances/{linodeId}/stats"
    path_params: [{name: linodeId, var: linode_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Statistics View (year/month)
#
# GET /linode/instances/{linodeId}/stats/{year}/{month}
# Returns: record<cpu: list<list<float>>, io: record<io: list<list>, swap: list<list>>, netv4: record<in: list<list>, out: list<list>, private_in: list<list>, private_out: list<list>>, netv6: record<in: list<list>, out: list<list>, private_in: list<list>, private_out: list<list>>, title: string>
# operationId: getLinodeStatsByYearMonth
export def "get-linode-stats-by-year-month" [
  linode_id: int
  year: int
  month: int
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
    path: "/linode/instances/{linodeId}/stats/{year}/{month}"
    path_params: [{name: linodeId, var: linode_id}, {name: year, var: year}, {name: month, var: month}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, year: $year, month: $month
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Network Transfer View
#
# GET /linode/instances/{linodeId}/transfer
# Returns: record<billable: int, quota: int, used: int>
# operationId: getLinodeTransfer
export def "get-linode-transfer" [
  linode_id: int
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
    path: "/linode/instances/{linodeId}/transfer"
    path_params: [{name: linodeId, var: linode_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Network Transfer View (year/month)
#
# GET /linode/instances/{linodeId}/transfer/{year}/{month}
# Returns: record<bytes_in: int, bytes_out: int, bytes_total: int>
# operationId: getLinodeTransferByYearMonth
export def "get-linode-transfer-by-year-month" [
  linode_id: int
  year: int
  month: int
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
    path: "/linode/instances/{linodeId}/transfer/{year}/{month}"
    path_params: [{name: linodeId, var: linode_id}, {name: year, var: year}, {name: month, var: month}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, year: $year, month: $month
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode's Volumes List
#
# GET /linode/instances/{linodeId}/volumes
# Returns: record<data: table<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: string, size: int, status: string, tags: list, updated: string>, page: int, pages: int, results: int>
# operationId: getLinodeVolumes
export def "get-linode-volumes" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/linode/instances/{linodeId}/volumes"
    path_params: [{name: linodeId, var: linode_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kernels List
#
# GET /linode/kernels
# Returns: record<data: table<architecture: string, built: string, deprecated: bool, id: string, kvm: bool, label: string, pvops: bool, version: string, xen: bool>, page: int, pages: int, results: int>
# operationId: getKernels
export def "get-kernels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/linode/kernels"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kernel View
#
# GET /linode/kernels/{kernelId}
# Returns: record<architecture: string, built: string, deprecated: bool, id: string, kvm: bool, label: string, pvops: bool, version: string, xen: bool>
# operationId: getKernel
export def "get-kernel" [
  kernel_id: string
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
    path: "/linode/kernels/{kernelId}"
    path_params: [{name: kernelId, var: kernel_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    kernel_id: $kernel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# StackScripts List
#
# GET /linode/stackscripts
# Returns: record<data: table<created: string, deployments_active: int, deployments_total: int, description: string, id: int, images: list, is_public: bool, label: string, mine: bool, rev_note: string, script: string, updated: string, user_defined_fields: list, user_gravatar_id: string, username: string>, page: int, pages: int, results: int>
# operationId: getStackScripts
export def "get-stack-scripts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/linode/stackscripts"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# StackScript Create
#
# POST /linode/stackscripts
# Returns: record<created: string, deployments_active: int, deployments_total: int, description: string, id: int, images: list<string>, is_public: bool, label: string, mine: bool, rev_note: string, script: string, updated: string, user_defined_fields: table<default: string, example: string, label: string, manyOf: string, name: string, oneOf: string>, user_gravatar_id: string, username: string>
# operationId: addStackScript
export def "add-stack-script" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A description for the StackScript. (e.g. This StackScript installs and configures MySQL )
  images: list<string> # An array of Image IDs. These are the Images that can be deployed with this StackScript. `any/all` indicates that all available Images, including private Images, are accepted. (e.g. [linode/debian9, linode/debian8])
  --is-public: oneof<nothing, bool> # This determines whether other users can use your StackScript. **Once a StackScript is made public, it cannot be made private.** (e.g. true)
  label: string # The StackScript's label is for display purposes only. (e.g. a-stackscript)
  --rev-note: string # This field allows you to add notes for the set of revisions made to this StackScript. (e.g. Set up MySQL)
  script: string # The script to execute when provisioning a new Linode with this StackScript. (e.g. "#!/bin/bash" )
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/linode/stackscripts"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: images, var: images}, {name: is_public, var: is_public}, {name: label, var: label}, {name: rev_note, var: rev_note}, {name: script, var: script}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, images: $images, is_public: $is_public, label: $label, rev_note: $rev_note, script: $script
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# StackScript Delete
#
# DELETE /linode/stackscripts/{stackscriptId}
# Returns: record
# operationId: deleteStackScript
export def "delete-stack-script" [
  stackscript_id: string
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
    path: "/linode/stackscripts/{stackscriptId}"
    path_params: [{name: stackscriptId, var: stackscript_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    stackscript_id: $stackscript_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# StackScript View
#
# GET /linode/stackscripts/{stackscriptId}
# Returns: record<created: string, deployments_active: int, deployments_total: int, description: string, id: int, images: list<string>, is_public: bool, label: string, mine: bool, rev_note: string, script: string, updated: string, user_defined_fields: table<default: string, example: string, label: string, manyOf: string, name: string, oneOf: string>, user_gravatar_id: string, username: string>
# operationId: getStackScript
export def "get-stack-script" [
  stackscript_id: string
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
    path: "/linode/stackscripts/{stackscriptId}"
    path_params: [{name: stackscriptId, var: stackscript_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    stackscript_id: $stackscript_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# StackScript Update
#
# PUT /linode/stackscripts/{stackscriptId}
# Returns: record<created: string, deployments_active: int, deployments_total: int, description: string, id: int, images: list<string>, is_public: bool, label: string, mine: bool, rev_note: string, script: string, updated: string, user_defined_fields: table<default: string, example: string, label: string, manyOf: string, name: string, oneOf: string>, user_gravatar_id: string, username: string>
# operationId: updateStackScript
export def "update-stack-script" [
  stackscript_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A description for the StackScript. (e.g. This StackScript installs and configures MySQL )
  --images: list<string> # An array of Image IDs. These are the Images that can be deployed with this StackScript. `any/all` indicates that all available Images, including private Images, are accepted. (e.g. [linode/debian9, linode/debian8])
  --is-public: oneof<nothing, bool> # This determines whether other users can use your StackScript. **Once a StackScript is made public, it cannot be made private.** (e.g. true)
  --label: string # The StackScript's label is for display purposes only. (e.g. a-stackscript)
  --rev-note: string # This field allows you to add notes for the set of revisions made to this StackScript. (e.g. Set up MySQL)
  --script: string # The script to execute when provisioning a new Linode with this StackScript. (e.g. "#!/bin/bash" )
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/linode/stackscripts/{stackscriptId}"
    path_params: [{name: stackscriptId, var: stackscript_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: images, var: images}, {name: is_public, var: is_public}, {name: label, var: label}, {name: rev_note, var: rev_note}, {name: script, var: script}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    stackscript_id: $stackscript_id, description: $description, images: $images, is_public: $is_public, label: $label, rev_note: $rev_note, script: $script
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Types List
#
# GET /linode/types
# Returns: record<data: table<addons: record, class: string, disk: int, gpus: int, id: string, label: string, memory: int, network_out: int, price: record, successor: string, transfer: int, vcpus: int>, page: int, pages: int, results: int>
# operationId: getLinodeTypes
export def "get-linode-types" [
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
    path: "/linode/types"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Type View
#
# GET /linode/types/{typeId}
# Returns: record<addons: record<backups: record<price: record>>, class: string, disk: int, gpus: int, id: string, label: string, memory: int, network_out: int, price: record<hourly: int, monthly: int>, successor: string, transfer: int, vcpus: int>
# operationId: getLinodeType
export def "get-linode-type" [
  type_id: string
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
    path: "/linode/types/{typeId}"
    path_params: [{name: typeId, var: type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kubernetes Clusters List
#
# GET /lke/clusters
# Returns: record<data: table<control_plane: record, created: string, id: int, k8s_version: string, label: string, region: string, tags: list, updated: string>, page: int, pages: int, results: int>
# operationId: getLKEClusters
export def "get-lke-clusters" [
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
    path: "/lke/clusters"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kubernetes Cluster Create
#
# POST /lke/clusters
# Returns: record<control_plane: record<high_availability: bool>, created: string, id: int, k8s_version: string, label: string, region: string, tags: list<string>, updated: string>
# operationId: createLKECluster
export def "create-lke-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --control-plane: record # Defines settings for the Kubernetes Control Plane. Allows for the enabling of High Availability (HA) for Control Plane Components. Enabling High Availability for LKE is an **irreversible** change. — shape: {high_availability?: bool}
  k8s_version: string # The desired Kubernetes version for this Kubernetes cluster in the format of <major>.<minor>, and the latest supported patch version will be deployed. (e.g. 1.25)
  label: string # This Kubernetes cluster's unique label for display purposes only. Labels have the following constraints: * UTF-8 characters will be returned by the API using escape sequences of their Unicode code points. For example, the Japanese character *か* is 3 bytes in UTF-8 (`0xE382AB`). Its Unicode code point is 2 bytes (`0x30AB`). APIv4 supports this character and the API will return it as the escape sequence using six 1 byte characters which represent 2 bytes of Unicode code point (`"\u30ab"`). * 4 byte UTF-8 characters are not supported. * If the label is entirely composed of UTF-8 characters, the API response will return the code points using up to 193 1 byte characters. (e.g. lkecluster12345)
  node_pools: list # item shape: {autoscaler?: record, count?: int, disks?: list, tags?: list<string>, type?: string}
  region: string # This Kubernetes cluster's location. (e.g. us-central)
  --tags: list<string> # An array of tags applied to the Kubernetes cluster. Tags are for organizational purposes only. (e.g. [ecomm, blogs])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/lke/clusters"
    body: {content_type: "application/json", kind: json, fields: [{name: control_plane, var: control_plane}, {name: k8s_version, var: k8s_version}, {name: label, var: label}, {name: node_pools, var: node_pools}, {name: region, var: region}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    control_plane: $control_plane, k8s_version: $k8s_version, label: $label, node_pools: $node_pools, region: $region, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kubernetes Cluster Delete
#
# DELETE /lke/clusters/{clusterId}
# Returns: record
# operationId: deleteLKECluster
export def "delete-lke-cluster" [
  cluster_id: int
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
    path: "/lke/clusters/{clusterId}"
    path_params: [{name: clusterId, var: cluster_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kubernetes Cluster View
#
# GET /lke/clusters/{clusterId}
# Returns: record<control_plane: record<high_availability: bool>, created: string, id: int, k8s_version: string, label: string, region: string, tags: list<string>, updated: string>
# operationId: getLKECluster
export def "get-lke-cluster" [
  cluster_id: int
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
    path: "/lke/clusters/{clusterId}"
    path_params: [{name: clusterId, var: cluster_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kubernetes Cluster Update
#
# PUT /lke/clusters/{clusterId}
# Returns: record<created: string, k8s_version: string, label: string, region: string, tags: list<string>, updated: string>
# operationId: putLKECluster
export def "put-lke-cluster" [
  cluster_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --control-plane: record # Defines settings for the Kubernetes Control Plane. Allows for the enabling of High Availability (HA) for Control Plane Components. Enabling High Availability for LKE is an **irreversible** change. When upgrading pre-existing LKE clusters to use the HA Control Plane, the following changes will additionally occur: - All nodes will be deleted and new nodes will be created to replace them. - Any local storage (such as `hostPath` volumes) will be erased. - The upgrade process may take several minutes to complete, as nodes will be replaced on a rolling basis. — shape: {high_availability?: bool}
  --k8s-version: string # The desired Kubernetes version for this Kubernetes cluster in the format of <major>.<minor>. New and recycled Nodes in this cluster will be installed with the latest available patch for the Cluster's Kubernetes version. When upgrading the Kubernetes version, only the next latest minor version following the current version can be deployed. For example, a cluster with Kubernetes version 1.19 can be upgraded to version 1.20, but not directly to 1.21. The Kubernetes version of a cluster can not be downgraded.
  --label: string # This Kubernetes cluster's unique label for display purposes only. Labels have the following constraints: * UTF-8 characters will be returned by the API using escape sequences of their Unicode code points. For example, the Japanese character *か* is 3 bytes in UTF-8 (`0xE382AB`). Its Unicode code point is 2 bytes (`0x30AB`). APIv4 supports this character and the API will return it as the escape sequence using six 1 byte characters which represent 2 bytes of Unicode code point (`"\u30ab"`). * 4 byte UTF-8 characters are not supported. * If the label is entirely composed of UTF-8 characters, the API response will return the code points using up to 193 1 byte characters. (e.g. lkecluster12345)
  --tags: list<string> # An array of tags applied to the Kubernetes cluster. Tags are for organizational purposes only. To delete a tag, exclude it from your `tags` array. (e.g. [prod, monitoring, ecomm, blog])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/lke/clusters/{clusterId}"
    path_params: [{name: clusterId, var: cluster_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: control_plane, var: control_plane}, {name: k8s_version, var: k8s_version}, {name: label, var: label}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id, control_plane: $control_plane, k8s_version: $k8s_version, label: $label, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kubernetes API Endpoints List
#
# GET /lke/clusters/{clusterId}/api-endpoints
# Returns: record<data: table<endpoint: string>, page: int, pages: int, results: int>
# operationId: getLKEClusterAPIEndpoints
export def "get-lke-cluster-api-endpoints" [
  cluster_id: int
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
    path: "/lke/clusters/{clusterId}/api-endpoints"
    path_params: [{name: clusterId, var: cluster_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kubernetes Cluster Dashboard URL View
#
# GET /lke/clusters/{clusterId}/dashboard
# Returns: record<url: string>
# operationId: getLKEClusterDashboard
export def "get-lke-cluster-dashboard" [
  cluster_id: int
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
    path: "/lke/clusters/{clusterId}/dashboard"
    path_params: [{name: clusterId, var: cluster_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kubeconfig Delete
#
# DELETE /lke/clusters/{clusterId}/kubeconfig
# Returns: record
# operationId: deleteLKEClusterKubeconfig
export def "delete-lke-cluster-kubeconfig" [
  cluster_id: int
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
    path: "/lke/clusters/{clusterId}/kubeconfig"
    path_params: [{name: clusterId, var: cluster_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kubeconfig View
#
# GET /lke/clusters/{clusterId}/kubeconfig
# Returns: record<kubeconfig: string>
# operationId: getLKEClusterKubeconfig
export def "get-lke-cluster-kubeconfig" [
  cluster_id: int
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
    path: "/lke/clusters/{clusterId}/kubeconfig"
    path_params: [{name: clusterId, var: cluster_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Node Delete
#
# DELETE /lke/clusters/{clusterId}/nodes/{nodeId}
# Returns: record
# operationId: deleteLKEClusterNode
export def "delete-lke-cluster-node" [
  cluster_id: int
  node_id: string
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
    path: "/lke/clusters/{clusterId}/nodes/{nodeId}"
    path_params: [{name: clusterId, var: cluster_id}, {name: nodeId, var: node_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id, node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Node View
#
# GET /lke/clusters/{clusterId}/nodes/{nodeId}
# Returns: record<id: string, instance_id: int, status: string>
# operationId: getLKEClusterNode
export def "get-lke-cluster-node" [
  cluster_id: int
  node_id: string
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
    path: "/lke/clusters/{clusterId}/nodes/{nodeId}"
    path_params: [{name: clusterId, var: cluster_id}, {name: nodeId, var: node_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id, node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Node Recycle
#
# POST /lke/clusters/{clusterId}/nodes/{nodeId}/recycle
# Returns: record
# operationId: postLKEClusterNodeRecycle
export def "post-lke-cluster-node-recycle" [
  cluster_id: int
  node_id: string
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
    method: post
    path: "/lke/clusters/{clusterId}/nodes/{nodeId}/recycle"
    path_params: [{name: clusterId, var: cluster_id}, {name: nodeId, var: node_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id, node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Node Pools List
#
# GET /lke/clusters/{clusterId}/pools
# Returns: record<data: table<autoscaler: record, count: int, disks: list, id: int, nodes: list, tags: list, type: string>, page: int, pages: int, results: int>
# operationId: getLKEClusterPools
export def "get-lke-cluster-pools" [
  cluster_id: int
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
    path: "/lke/clusters/{clusterId}/pools"
    path_params: [{name: clusterId, var: cluster_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Node Pool Create
#
# POST /lke/clusters/{clusterId}/pools
# Returns: record<autoscaler: record<enabled: bool, max: int, min: int>, count: int, disks: table<size: int, type: string>, id: int, nodes: table<id: string, instance_id: string, status: string>, tags: list<string>, type: string>
# operationId: postLKEClusterPools
export def "post-lke-cluster-pools" [
  cluster_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --autoscaler: record # When enabled, the number of nodes autoscales within the defined minimum and maximum values. When making a request, `max` and `min` require each other. — shape: {enabled?: bool, max?: int, min?: int}
  count: int # The number of nodes in the Node Pool. (e.g. 6)
  --disks: list # **Note**: This field should be omitted except for special use cases. The disks specified here are partitions in *addition* to the primary partition and reduce the size of the primary partition, which can lead to stability problems for the Node. This Node Pool's custom disk layout. Each item in this array will create a new disk partition for each node in this Node Pool. * The custom disk layout is applied to each node in this Node Pool. * The maximum number of custom disk partitions that can be configured is 7. * Once the requested disk paritions are allocated, the remaining disk space is allocated to the node's boot disk. * A Node Pool's custom disk layout is immutable over the lifetime of the Node Pool. — item shape: {size?: int, type?: "raw"|"ext4"}
  --tags: list<string> # An array of tags applied to this object. Tags are for organizational purposes only. (e.g. [example tag, another example])
  type: string # The Linode Type for all of the nodes in the Node Pool. (e.g. g6-standard-4)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/lke/clusters/{clusterId}/pools"
    path_params: [{name: clusterId, var: cluster_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoscaler, var: autoscaler}, {name: count, var: count}, {name: disks, var: disks}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id, autoscaler: $autoscaler, count: $count, disks: $disks, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Node Pool Delete
#
# DELETE /lke/clusters/{clusterId}/pools/{poolId}
# Returns: record
# operationId: deleteLKENodePool
export def "delete-lke-node-pool" [
  cluster_id: int
  pool_id: int
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
    path: "/lke/clusters/{clusterId}/pools/{poolId}"
    path_params: [{name: clusterId, var: cluster_id}, {name: poolId, var: pool_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id, pool_id: $pool_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Node Pool View
#
# GET /lke/clusters/{clusterId}/pools/{poolId}
# Returns: record<autoscaler: record<enabled: bool, max: int, min: int>, count: int, disks: table<size: int, type: string>, id: int, nodes: table<id: string, instance_id: string, status: string>, tags: list<string>, type: string>
# operationId: getLKENodePool
export def "get-lke-node-pool" [
  cluster_id: int
  pool_id: int
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
    path: "/lke/clusters/{clusterId}/pools/{poolId}"
    path_params: [{name: clusterId, var: cluster_id}, {name: poolId, var: pool_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id, pool_id: $pool_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Node Pool Update
#
# PUT /lke/clusters/{clusterId}/pools/{poolId}
# Returns: record<autoscaler: record<enabled: bool, max: int, min: int>, count: int, disks: table<size: int, type: string>, id: int, nodes: table<id: string, instance_id: string, status: string>, tags: list<string>, type: string>
# operationId: putLKENodePool
export def "put-lke-node-pool" [
  cluster_id: int
  pool_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --autoscaler: record # When enabled, the number of nodes autoscales within the defined minimum and maximum values. When making a request, `max` and `min` require each other. — shape: {enabled?: bool, max?: int, min?: int}
  --count: int # The number of nodes in the Node Pool. (e.g. 6)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/lke/clusters/{clusterId}/pools/{poolId}"
    path_params: [{name: clusterId, var: cluster_id}, {name: poolId, var: pool_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoscaler, var: autoscaler}, {name: count, var: count}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id, pool_id: $pool_id, autoscaler: $autoscaler, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Node Pool Recycle
#
# POST /lke/clusters/{clusterId}/pools/{poolId}/recycle
# Returns: record
# operationId: postLKEClusterPoolRecycle
export def "post-lke-cluster-pool-recycle" [
  cluster_id: int
  pool_id: int
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
    method: post
    path: "/lke/clusters/{clusterId}/pools/{poolId}/recycle"
    path_params: [{name: clusterId, var: cluster_id}, {name: poolId, var: pool_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id, pool_id: $pool_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cluster Nodes Recycle
#
# POST /lke/clusters/{clusterId}/recycle
# Returns: record
# operationId: postLKEClusterRecycle
export def "post-lke-cluster-recycle" [
  cluster_id: int
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
    method: post
    path: "/lke/clusters/{clusterId}/recycle"
    path_params: [{name: clusterId, var: cluster_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kubernetes Cluster Regenerate
#
# POST /lke/clusters/{clusterId}/regenerate
# Returns: record
# operationId: postLKEClusterRegenerate
export def "post-lke-cluster-regenerate" [
  cluster_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kubeconfig: oneof<nothing, bool> # Whether to delete and regenerate the Kubeconfig file for this Cluster. (default: false, e.g. true)
  --servicetoken: oneof<nothing, bool> # Whether to delete and regenerate the service access token for this Cluster. (default: false, e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/lke/clusters/{clusterId}/regenerate"
    path_params: [{name: clusterId, var: cluster_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: kubeconfig, var: kubeconfig}, {name: servicetoken, var: servicetoken}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id, kubeconfig: $kubeconfig, servicetoken: $servicetoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Service Token Delete
#
# DELETE /lke/clusters/{clusterId}/servicetoken
# Returns: record
# operationId: postLKECServiceTokenDelete
export def "post-lkec-service-token-delete" [
  cluster_id: int
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
    path: "/lke/clusters/{clusterId}/servicetoken"
    path_params: [{name: clusterId, var: cluster_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kubernetes Versions List
#
# GET /lke/versions
# Returns: record<data: table<id: string>, page: int, pages: int, results: int>
# operationId: getLKEVersions
export def "get-lke-versions" [
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
    path: "/lke/versions"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kubernetes Version View
#
# GET /lke/versions/{version}
# Returns: record<id: string>
# operationId: getLKEVersion
export def "get-lke-version" [
  version: string
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
    path: "/lke/versions/{version}"
    path_params: [{name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Longview Clients List
#
# GET /longview/clients
# Returns: record<data: table<api_key: string, apps: record, created: string, id: int, install_code: string, label: string, updated: string>, page: int, pages: int, results: int>
# operationId: getLongviewClients
export def "get-longview-clients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/longview/clients"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Longview Client Create
#
# POST /longview/clients
# Returns: record<api_key: string, apps: record<apache: bool, mysql: bool, nginx: bool>, created: string, id: int, install_code: string, label: string, updated: string>
# operationId: createLongviewClient
export def "create-longview-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # This Client's unique label. This is for display purposes only. (e.g. client789)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/longview/clients"
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Longview Client Delete
#
# DELETE /longview/clients/{clientId}
# Returns: record
# operationId: deleteLongviewClient
export def "delete-longview-client" [
  client_id: int
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
    path: "/longview/clients/{clientId}"
    path_params: [{name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Longview Client View
#
# GET /longview/clients/{clientId}
# Returns: record<api_key: string, apps: record<apache: bool, mysql: bool, nginx: bool>, created: string, id: int, install_code: string, label: string, updated: string>
# operationId: getLongviewClient
export def "get-longview-client" [
  client_id: int
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
    path: "/longview/clients/{clientId}"
    path_params: [{name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Longview Client Update
#
# PUT /longview/clients/{clientId}
# Returns: record<api_key: string, apps: record<apache: bool, mysql: bool, nginx: bool>, created: string, id: int, install_code: string, label: string, updated: string>
# operationId: updateLongviewClient
export def "update-longview-client" [
  client_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # This Client's unique label. This is for display purposes only. (e.g. client789)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/longview/clients/{clientId}"
    path_params: [{name: clientId, var: client_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Longview Plan View
#
# GET /longview/plan
# Returns: record<clients_included: int, id: string, label: string, price: record<hourly: float, monthly: float>>
# operationId: getLongviewPlan
export def "get-longview-plan" [
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
    path: "/longview/plan"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Longview Plan Update
#
# PUT /longview/plan
# Returns: record<clients_included: int, id: string, label: string, price: record<hourly: float, monthly: float>>
# operationId: updateLongviewPlan
export def "update-longview-plan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --longview-subscription: string@longview-subscription-completer # The subscription ID for a particular Longview plan. A value of `null` corresponds to Longview Free. You can send a request to the [List Longview Subscriptions](/docs/api/longview/#longview-subscriptions-list) endpoint to receive the details of each plan. (nullable, e.g. longview-10)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/longview/plan"
    body: {content_type: "application/json", kind: json, fields: [{name: longview_subscription, var: longview_subscription}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    longview_subscription: $longview_subscription
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Longview Subscriptions List
#
# GET /longview/subscriptions
# Returns: record<data: table<clients_included: int, id: string, label: string, price: record>, page: int, pages: int, results: int>
# operationId: getLongviewSubscriptions
export def "get-longview-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/longview/subscriptions"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Longview Subscription View
#
# GET /longview/subscriptions/{subscriptionId}
# Returns: record<clients_included: int, id: string, label: string, price: record<hourly: float, monthly: float>>
# operationId: getLongviewSubscription
export def "get-longview-subscription" [
  subscription_id: string
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
    path: "/longview/subscriptions/{subscriptionId}"
    path_params: [{name: subscriptionId, var: subscription_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Contacts List
#
# GET /managed/contacts
# Returns: record<data: table<email: string, group: string, id: int, name: string, phone: record, updated: string>, page: int, pages: int, results: int>
# operationId: getManagedContacts
export def "get-managed-contacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/managed/contacts"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Contact Create
#
# POST /managed/contacts
# Returns: record<email: string, group: string, id: int, name: string, phone: record<primary: string, secondary: string>, updated: string>
# operationId: createManagedContact
export def "create-managed-contact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The address to email this Contact to alert them of issues. (format: email, e.g. john.doe@example.org)
  --group: string # A grouping for this Contact. This is for display purposes only. (nullable, e.g. on-call)
  --name: string # The name of this Contact. (e.g. John Doe)
  --phone: record # Information about how to reach this Contact by phone. — shape: {primary?: string, secondary?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/managed/contacts"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: group, var: group}, {name: name, var: name}, {name: phone, var: phone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, group: $group, name: $name, phone: $phone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Contact Delete
#
# DELETE /managed/contacts/{contactId}
# Returns: record
# operationId: deleteManagedContact
export def "delete-managed-contact" [
  contact_id: int
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
    path: "/managed/contacts/{contactId}"
    path_params: [{name: contactId, var: contact_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contact_id: $contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Contact View
#
# GET /managed/contacts/{contactId}
# Returns: record<email: string, group: string, id: int, name: string, phone: record<primary: string, secondary: string>, updated: string>
# operationId: getManagedContact
export def "get-managed-contact" [
  contact_id: int
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
    path: "/managed/contacts/{contactId}"
    path_params: [{name: contactId, var: contact_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contact_id: $contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Contact Update
#
# PUT /managed/contacts/{contactId}
# Returns: record<email: string, group: string, id: int, name: string, phone: record<primary: string, secondary: string>, updated: string>
# operationId: updateManagedContact
export def "update-managed-contact" [
  contact_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The address to email this Contact to alert them of issues. (format: email, e.g. john.doe@example.org)
  --group: string # A grouping for this Contact. This is for display purposes only. (nullable, e.g. on-call)
  --name: string # The name of this Contact. (e.g. John Doe)
  --phone: record # Information about how to reach this Contact by phone. — shape: {primary?: string, secondary?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/managed/contacts/{contactId}"
    path_params: [{name: contactId, var: contact_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: group, var: group}, {name: name, var: name}, {name: phone, var: phone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contact_id: $contact_id, email: $email, group: $group, name: $name, phone: $phone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Credentials List
#
# GET /managed/credentials
# Returns: record<data: table<id: int, label: string, last_decrypted: string>, page: int, pages: int, results: int>
# operationId: getManagedCredentials
export def "get-managed-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/managed/credentials"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Credential Create
#
# POST /managed/credentials
# Returns: record<id: int, label: string, last_decrypted: string>
# operationId: createManagedCredential
export def "create-managed-credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string # The unique label for this Credential. This is for display purposes only. (e.g. prod-password-1)
  password: string # The password to use when accessing the Managed Service. (e.g. s3cur3P@ssw0rd)
  --username: string # The username to use when accessing the Managed Service. (e.g. johndoe)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/managed/credentials"
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}, {name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    label: $label, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed SSH Key View
#
# GET /managed/credentials/sshkey
# Returns: record<ssh_key: string>
# operationId: viewManagedSSHKey
export def "view-managed-ssh-key" [
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
    path: "/managed/credentials/sshkey"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Credential View
#
# GET /managed/credentials/{credentialId}
# Returns: record<id: int, label: string, last_decrypted: string>
# operationId: getManagedCredential
export def "get-managed-credential" [
  credential_id: int
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
    path: "/managed/credentials/{credentialId}"
    path_params: [{name: credentialId, var: credential_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    credential_id: $credential_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Credential Update
#
# PUT /managed/credentials/{credentialId}
# Returns: record<id: int, label: string, last_decrypted: string>
# operationId: updateManagedCredential
export def "update-managed-credential" [
  credential_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # The unique label for this Credential. This is for display purposes only. (e.g. prod-password-1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/managed/credentials/{credentialId}"
    path_params: [{name: credentialId, var: credential_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    credential_id: $credential_id, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Credential Delete
#
# POST /managed/credentials/{credentialId}/revoke
# Returns: record
# operationId: deleteManagedCredential
export def "delete-managed-credential" [
  credential_id: int
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
    method: post
    path: "/managed/credentials/{credentialId}/revoke"
    path_params: [{name: credentialId, var: credential_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    credential_id: $credential_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Credential Username and Password Update
#
# POST /managed/credentials/{credentialId}/update
# Returns: record
# operationId: updateManagedCredentialUsernamePassword
export def "update-managed-credential-username-password" [
  credential_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # The password to use when accessing the Managed Service. (e.g. s3cur3P@ssw0rd)
  --username: string # The username to use when accessing the Managed Service. (e.g. johndoe)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/managed/credentials/{credentialId}/update"
    path_params: [{name: credentialId, var: credential_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    credential_id: $credential_id, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Issues List
#
# GET /managed/issues
# Returns: record<data: table<created: string, entity: record, id: int, services: list>, page: int, pages: int, results: int>
# operationId: getManagedIssues
export def "get-managed-issues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/managed/issues"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Issue View
#
# GET /managed/issues/{issueId}
# Returns: record<created: string, entity: record<id: int, label: string, type: string, url: string>, id: int, services: list<int>>
# operationId: getManagedIssue
export def "get-managed-issue" [
  issue_id: int
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
    path: "/managed/issues/{issueId}"
    path_params: [{name: issueId, var: issue_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Linode Settings List
#
# GET /managed/linode-settings
# Returns: record<data: table<group: string, id: int, label: string, ssh: record>, page: int, pages: int, results: int>
# operationId: getManagedLinodeSettings
export def "get-managed-linode-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/managed/linode-settings"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode's Managed Settings View
#
# GET /managed/linode-settings/{linodeId}
# Returns: record<group: string, id: int, label: string, ssh: record<access: bool, ip: string, port: int, user: string>>
# operationId: getManagedLinodeSetting
export def "get-managed-linode-setting" [
  linode_id: int
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
    path: "/managed/linode-settings/{linodeId}"
    path_params: [{name: linodeId, var: linode_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linode's Managed Settings Update
#
# PUT /managed/linode-settings/{linodeId}
# Returns: record<group: string, id: int, label: string, ssh: record<access: bool, ip: string, port: int, user: string>>
# operationId: updateManagedLinodeSetting
export def "update-managed-linode-setting" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ssh: record # The SSH settings for this Linode. — shape: {access?: bool, ip?: string, port?: int, user?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/managed/linode-settings/{linodeId}"
    path_params: [{name: linodeId, var: linode_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ssh, var: ssh}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, ssh: $ssh
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Services List
#
# GET /managed/services
# Returns: record<data: table<address: string, body: string, consultation_group: string, created: string, credentials: list, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string>, page: int, pages: int, results: int>
# operationId: getManagedServices
export def "get-managed-services" [
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
    path: "/managed/services"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Service Create
#
# POST /managed/services
# Returns: record<address: string, body: string, consultation_group: string, created: string, credentials: list<int>, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string>
# operationId: createManagedService
export def "create-managed-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # The URL at which this Service is monitored. URL parameters such as `?no-cache=1` are preserved. URL fragments/anchors such as `#monitor` are **not** preserved. (format: url, e.g. https://example.org)
  --body: string # What to expect to find in the response body for the Service to be considered up. (nullable, e.g. it worked)
  --consultation-group: string # The group of ManagedContacts who should be notified or consulted with when an Issue is detected. (e.g. on-call)
  --credentials: list<int> # An array of ManagedCredential IDs that should be used when attempting to resolve issues with this Service.
  label: string # The label for this Service. This is for display purposes only. (e.g. prod-1)
  --notes: string # Any information relevant to the Service that Linode special forces should know when attempting to resolve Issues. (nullable, e.g. The service name is my-cool-application)
  --region: string # The Region in which this Service is located. This is required if address is a private IP, and may not be set otherwise.
  service_type: string@service-type-completer # How this Service is monitored. (e.g. url)
  timeout: int # How long to wait, in seconds, for a response before considering the Service to be down. (e.g. 30)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/managed/services"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: body, var: body}, {name: consultation_group, var: consultation_group}, {name: credentials, var: credentials}, {name: label, var: label}, {name: notes, var: notes}, {name: region, var: region}, {name: service_type, var: service_type}, {name: timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address: $address, body: $body, consultation_group: $consultation_group, credentials: $credentials, label: $label, notes: $notes, region: $region, service_type: $service_type, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Service Delete
#
# DELETE /managed/services/{serviceId}
# Returns: record
# operationId: deleteManagedService
export def "delete-managed-service" [
  service_id: int
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
    path: "/managed/services/{serviceId}"
    path_params: [{name: serviceId, var: service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Service View
#
# GET /managed/services/{serviceId}
# Returns: record<address: string, body: string, consultation_group: string, created: string, credentials: list<int>, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string>
# operationId: getManagedService
export def "get-managed-service" [
  service_id: int
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
    path: "/managed/services/{serviceId}"
    path_params: [{name: serviceId, var: service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Service Update
#
# PUT /managed/services/{serviceId}
# Returns: record<address: string, body: string, consultation_group: string, created: string, credentials: list<int>, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string>
# operationId: updateManagedService
export def "update-managed-service" [
  service_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # The URL at which this Service is monitored. URL parameters such as `?no-cache=1` are preserved. URL fragments/anchors such as `#monitor` are **not** preserved. (format: url, e.g. https://example.org)
  --body: string # What to expect to find in the response body for the Service to be considered up. (nullable, e.g. it worked)
  --consultation-group: string # The group of ManagedContacts who should be notified or consulted with when an Issue is detected. (e.g. on-call)
  --credentials: list<int> # An array of ManagedCredential IDs that should be used when attempting to resolve issues with this Service.
  --label: string # The label for this Service. This is for display purposes only. (e.g. prod-1)
  --notes: string # Any information relevant to the Service that Linode special forces should know when attempting to resolve Issues. (nullable, e.g. The service name is my-cool-application)
  --region: string # The Region in which this Service is located. This is required if address is a private IP, and may not be set otherwise.
  --service-type: string@service-type-completer # How this Service is monitored. (e.g. url)
  --timeout: int # How long to wait, in seconds, for a response before considering the Service to be down. (e.g. 30)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/managed/services/{serviceId}"
    path_params: [{name: serviceId, var: service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: body, var: body}, {name: consultation_group, var: consultation_group}, {name: credentials, var: credentials}, {name: label, var: label}, {name: notes, var: notes}, {name: region, var: region}, {name: service_type, var: service_type}, {name: timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, address: $address, body: $body, consultation_group: $consultation_group, credentials: $credentials, label: $label, notes: $notes, region: $region, service_type: $service_type, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Service Disable
#
# POST /managed/services/{serviceId}/disable
# Returns: record<address: string, body: string, consultation_group: string, created: string, credentials: list<int>, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string>
# operationId: disableManagedService
export def "disable-managed-service" [
  service_id: int
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
    method: post
    path: "/managed/services/{serviceId}/disable"
    path_params: [{name: serviceId, var: service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Service Enable
#
# POST /managed/services/{serviceId}/enable
# Returns: record<address: string, body: string, consultation_group: string, created: string, credentials: list<int>, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string>
# operationId: enableManagedService
export def "enable-managed-service" [
  service_id: int
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
    method: post
    path: "/managed/services/{serviceId}/enable"
    path_params: [{name: serviceId, var: service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Managed Stats List
#
# GET /managed/stats
# Returns: record<data: record>
# operationId: getManagedStats
export def "get-managed-stats" [
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
    path: "/managed/stats"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Firewalls List
#
# GET /networking/firewalls
# Returns: record<data: table<created: string, id: int, label: string, rules: record, status: string, tags: list, updated: string>, page: int, pages: int, results: int>
# operationId: getFirewalls
export def "get-firewalls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networking/firewalls"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Firewall Create
#
# POST /networking/firewalls
# Returns: record<created: string, id: int, label: string, rules: record<inbound: list<record>, inbound_policy: string, outbound: list<record>, outbound_policy: string>, status: string, tags: list<string>, updated: string>
# operationId: createFirewalls
export def "create-firewalls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --devices: record # Devices to create for this Firewall. When a Device is created, the Firewall is assigned to its associated service. Currently, Devices can only be created for Linode instances. — shape: {linodes?: list<int>}
  rules: record # The inbound and outbound access rules to apply to the Firewall. A Firewall may have up to 25 rules across its inbound and outbound rulesets. — shape: {inbound?: list, inbound_policy?: "ACCEPT"|"DROP", outbound?: list, outbound_policy?: "ACCEPT"|"DROP"}
  label: string # The Firewall's label, for display purposes only. Firewall labels have the following constraints: * Must begin and end with an alphanumeric character. * May only consist of alphanumeric characters, dashes (`-`), underscores (`_`) or periods (`.`). * Cannot have two dashes (`--`), underscores (`__`) or periods (`..`) in a row. * Must be between 3 and 32 characters. * Must be unique. (e.g. firewall123)
  --tags: list<string> # An array of tags applied to this object. Tags are for organizational purposes only. (e.g. [example tag, another example])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networking/firewalls"
    body: {content_type: "application/json", kind: json, fields: [{name: devices, var: devices}, {name: rules, var: rules}, {name: label, var: label}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    devices: $devices, rules: $rules, label: $label, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Firewall Delete
#
# DELETE /networking/firewalls/{firewallId}
# Returns: record
# operationId: deleteFirewall
export def "delete-firewall" [
  firewall_id: int
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
    path: "/networking/firewalls/{firewallId}"
    path_params: [{name: firewallId, var: firewall_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    firewall_id: $firewall_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Firewall View
#
# GET /networking/firewalls/{firewallId}
# Returns: record<created: string, id: int, label: string, rules: record<inbound: list<record>, inbound_policy: string, outbound: list<record>, outbound_policy: string>, status: string, tags: list<string>, updated: string>
# operationId: getFirewall
export def "get-firewall" [
  firewall_id: int
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
    path: "/networking/firewalls/{firewallId}"
    path_params: [{name: firewallId, var: firewall_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    firewall_id: $firewall_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Firewall Update
#
# PUT /networking/firewalls/{firewallId}
# Returns: record<created: string, id: int, label: string, rules: record<inbound: list<record>, inbound_policy: string, outbound: list<record>, outbound_policy: string>, status: string, tags: list<string>, updated: string>
# operationId: updateFirewall
export def "update-firewall" [
  firewall_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # The Firewall's label, for display purposes only. Firewall labels have the following constraints: * Must begin and end with an alphanumeric character. * May only consist of alphanumeric characters, dashes (`-`), underscores (`_`) or periods (`.`). * Cannot have two dashes (`--`), underscores (`__`) or periods (`..`) in a row. * Must be between 3 and 32 characters. * Must be unique. (e.g. firewall123)
  --status: string@status-completer-1 # The status to be applied to this Firewall. * When a Firewall is first created its status is `enabled`. * Use the [Delete Firewall](/docs/api/networking/#firewall-delete) endpoint to delete a Firewall. (e.g. enabled)
  --tags: list<string> # An array of tags applied to this object. Tags are for organizational purposes only. (e.g. [example tag, another example])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networking/firewalls/{firewallId}"
    path_params: [{name: firewallId, var: firewall_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}, {name: status, var: status}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    firewall_id: $firewall_id, label: $label, status: $status, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Firewall Devices List
#
# GET /networking/firewalls/{firewallId}/devices
# Returns: record<data: table<created: string, entity: record, id: int, updated: string>, page: int, pages: int, results: int>
# operationId: getFirewallDevices
export def "get-firewall-devices" [
  firewall_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networking/firewalls/{firewallId}/devices"
    path_params: [{name: firewallId, var: firewall_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    firewall_id: $firewall_id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Firewall Device Create
#
# POST /networking/firewalls/{firewallId}/devices
# Returns: record<created: string, entity: record<id: int, label: string, type: string, url: string>, id: int, updated: string>
# operationId: createFirewallDevice
export def "create-firewall-device" [
  firewall_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # The entity's ID (e.g. 123)
  type: string@type-completer-4 # The entity's type. (e.g. linode)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networking/firewalls/{firewallId}/devices"
    path_params: [{name: firewallId, var: firewall_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    firewall_id: $firewall_id, id: $id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Firewall Device Delete
#
# DELETE /networking/firewalls/{firewallId}/devices/{deviceId}
# Returns: record
# operationId: deleteFirewallDevice
export def "delete-firewall-device" [
  firewall_id: int
  device_id: int
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
    path: "/networking/firewalls/{firewallId}/devices/{deviceId}"
    path_params: [{name: firewallId, var: firewall_id}, {name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    firewall_id: $firewall_id, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Firewall Device View
#
# GET /networking/firewalls/{firewallId}/devices/{deviceId}
# Returns: record<created: string, entity: record<id: int, label: string, type: string, url: string>, id: int, updated: string>
# operationId: getFirewallDevice
export def "get-firewall-device" [
  firewall_id: int
  device_id: int
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
    path: "/networking/firewalls/{firewallId}/devices/{deviceId}"
    path_params: [{name: firewallId, var: firewall_id}, {name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    firewall_id: $firewall_id, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Firewall Rules List
#
# GET /networking/firewalls/{firewallId}/rules
# Returns: record<inbound: table<action: string, addresses: record, description: string, label: string, ports: string, protocol: string>, inbound_policy: string, outbound: table<action: string, addresses: record, description: string, label: string, ports: string, protocol: string>, outbound_policy: string>
# operationId: getFirewallRules
export def "get-firewall-rules" [
  firewall_id: int
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
    path: "/networking/firewalls/{firewallId}/rules"
    path_params: [{name: firewallId, var: firewall_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    firewall_id: $firewall_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Firewall Rules Update
#
# PUT /networking/firewalls/{firewallId}/rules
# Returns: record<inbound: table<action: string, addresses: record, description: string, label: string, ports: string, protocol: string>, inbound_policy: string, outbound: table<action: string, addresses: record, description: string, label: string, ports: string, protocol: string>, outbound_policy: string>
# operationId: updateFirewallRules
export def "update-firewall-rules" [
  firewall_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --inbound: list # The inbound rules for the firewall, as a JSON array. — item shape: {action?: "ACCEPT"|"DROP", addresses?: record, description?: string, label?: string, ports?: string, protocol?: "TCP"|"UDP"|"ICMP"|"IPENCAP"}
  --outbound: list # The outbound rules for the firewall, as a JSON array. — item shape: {action?: "ACCEPT"|"DROP", addresses?: record, description?: string, label?: string, ports?: string, protocol?: "TCP"|"UDP"|"ICMP"|"IPENCAP"}
  --inbound-policy: string@inbound-policy-completer # The default behavior for inbound traffic. This setting can be overridden by [updating](/docs/api/networking/#firewall-rules-update) the `inbound.action` property of the Firewall Rule. (e.g. DROP)
  --outbound-policy: string@outbound-policy-completer # The default behavior for outbound traffic. This setting can be overridden by [updating](/docs/api/networking/#firewall-rules-update) the `outbound.action` property of the Firewall Rule. (e.g. DROP)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networking/firewalls/{firewallId}/rules"
    path_params: [{name: firewallId, var: firewall_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: inbound, var: inbound}, {name: outbound, var: outbound}, {name: inbound_policy, var: inbound_policy}, {name: outbound_policy, var: outbound_policy}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    firewall_id: $firewall_id, inbound: $inbound, outbound: $outbound, inbound_policy: $inbound_policy, outbound_policy: $outbound_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IP Addresses List
#
# GET /networking/ips
# Returns: record<data: table<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>, page: int, pages: int, results: int>
# operationId: getIPs
export def "get-i-ps" [
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
    path: "/networking/ips"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IP Address Allocate
#
# POST /networking/ips
# Returns: record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>
# operationId: allocateIP
export def "allocate-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  linode_id: int # The ID of a Linode you you have access to that this address will be allocated to. (e.g. 123)
  --public: oneof<nothing, bool> # Whether to create a public or private IPv4 address. (e.g. true)
  type: string@type-completer-3 # The type of address you are requesting. Only IPv4 addresses may be allocated through this endpoint. (e.g. ipv4)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networking/ips"
    body: {content_type: "application/json", kind: json, fields: [{name: linode_id, var: linode_id}, {name: public, var: public, required: true}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, public: $public, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IP Addresses Assign
#
# POST /networking/ips/assign
# Returns: record
# operationId: assignIPs
export def "assign-i-ps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assignments: list # The list of assignments to make. You must have read_write access to all IPs being assigned and all Linodes being assigned to in order for the assignments to succeed. — item shape: {address?: string, linode_id?: int}
  region: string # The ID of the Region in which these assignments are to take place. All IPs and Linodes must exist in this Region. (e.g. us-east)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networking/ips/assign"
    body: {content_type: "application/json", kind: json, fields: [{name: assignments, var: assignments}, {name: region, var: region}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    assignments: $assignments, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IP Addresses Share
#
# POST /networking/ips/share
# Returns: record
# operationId: shareIPs
export def "share-i-ps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ips: list<string> # A list of secondary Linode IPs to share with the primary Linode. * Can include both IPv4 addresses and IPv6 ranges (omit /56 and /64 prefix lengths) * Can include both private and public IPv4 addresses. * You must have access to all of these addresses and they must be in the same Region as the primary Linode. * Enter an empty array to remove all shared IP addresses. (e.g. [192.0.2.1, 2001:db8:3c4d:15::])
  linode_id: int # The ID of the primary Linode that the addresses will be shared with. (e.g. 123)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networking/ips/share"
    body: {content_type: "application/json", kind: json, fields: [{name: ips, var: ips}, {name: linode_id, var: linode_id}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4beta"
    auth: bearer
  } {
    ips: $ips, linode_id: $linode_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IP Address View
#
# GET /networking/ips/{address}
# Returns: record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>
# operationId: getIP
export def "get-ip" [
  address: string
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
    path: "/networking/ips/{address}"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IP Address RDNS Update
#
# PUT /networking/ips/{address}
# Returns: record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>
# operationId: updateIP
export def "update-ip" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rdns: string # The reverse DNS assigned to this address. For public IPv4 addresses, this will be set to a default value provided by Linode if not explicitly set. (nullable, e.g. test.example.org)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networking/ips/{address}"
    path_params: [{name: address, var: address}]
    body: {content_type: "application/json", kind: json, fields: [{name: rdns, var: rdns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address: $address, rdns: $rdns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linodes Assign IPv4s
#
# POST /networking/ipv4/assign
# Returns: record
# operationId: assignIPv4s
export def "assign-i-pv4s" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assignments: list # The list of assignments to make. You must have read_write access to all IPs being assigned and all Linodes being assigned to in order for the assignments to succeed. — item shape: {address?: string, linode_id?: int}
  region: string # The ID of the Region in which these assignments are to take place. All IPs and Linodes must exist in this Region. (e.g. us-east)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networking/ipv4/assign"
    body: {content_type: "application/json", kind: json, fields: [{name: assignments, var: assignments}, {name: region, var: region}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    assignments: $assignments, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IPv4 Sharing Configure
#
# POST /networking/ipv4/share
# Returns: record
# operationId: shareIPv4s
export def "share-i-pv4s" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ips: list<string> # A list of secondary Linode IPs to share with the primary Linode. * Can include both IPv4 addresses and IPv6 ranges (omit /56 and /64 prefix lengths) * Can include both private and public IPv4 addresses. * You must have access to all of these addresses and they must be in the same Region as the primary Linode. * Enter an empty array to remove all shared IP addresses. (e.g. [192.0.2.1, 2001:db8:3c4d:15::])
  linode_id: int # The ID of the primary Linode that the addresses will be shared with. (e.g. 123)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networking/ipv4/share"
    body: {content_type: "application/json", kind: json, fields: [{name: ips, var: ips}, {name: linode_id, var: linode_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ips: $ips, linode_id: $linode_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IPv6 Pools List
#
# GET /networking/ipv6/pools
# Returns: record<data: table<prefix: int, range: string, region: string, route_target: string>, page: int, pages: int, results: int>
# operationId: getIPv6Pools
export def "get-i-pv6-pools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networking/ipv6/pools"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IPv6 Ranges List
#
# GET /networking/ipv6/ranges
# Returns: record<data: table<prefix: int, range: string, region: string, route_target: string>, page: int, pages: int, results: int>
# operationId: getIPv6Ranges
export def "get-i-pv6-ranges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networking/ipv6/ranges"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IPv6 Range Create
#
# POST /networking/ipv6/ranges
# Returns: record<range: string, route_target: string>
# operationId: postIPv6Range
export def "post-i-pv6-range" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --linode-id: int # The ID of the Linode to assign this range to. The SLAAC address for the provided Linode is used as the range's `route_target`. * **Required** if `route_target` is omitted from the request. * Mutually exclusive with `route_target`. Submitting values for both properties in a request results in an error. (e.g. 123)
  prefix_length: int@prefix-length-completer # The prefix length of the IPv6 range.
  --route-target: string # The IPv6 SLAAC address to assign this range to. * **Required** if `linode_id` is omitted from the request. * Mutually exclusive with `linode_id`. Submitting values for both properties in a request results in an error. * **Note**: Omit the `/128` prefix length of the SLAAC address when using this property. (format: ipv6, e.g. 2001:0db8::1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networking/ipv6/ranges"
    body: {content_type: "application/json", kind: json, fields: [{name: linode_id, var: linode_id}, {name: prefix_length, var: prefix_length}, {name: route_target, var: route_target}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linode_id: $linode_id, prefix_length: $prefix_length, route_target: $route_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IPv6 Range Delete
#
# DELETE /networking/ipv6/ranges/{range}
# Returns: record
# operationId: deleteIPv6Range
export def "delete-i-pv6-range" [
  range: string
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
    path: "/networking/ipv6/ranges/{range}"
    path_params: [{name: range, var: range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IPv6 Range View
#
# GET /networking/ipv6/ranges/{range}
# Returns: record<is_bgp: bool, linodes: list<int>, prefix: int, range: string, region: string>
# operationId: getIPv6Range
export def "get-i-pv6-range" [
  range: string
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
    path: "/networking/ipv6/ranges/{range}"
    path_params: [{name: range, var: range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# VLANs List
#
# GET /networking/vlans
# Returns: record<data: table<created: string, label: string, linodes: list, region: string>, page: int, pages: int, results: int>
# operationId: getVLANs
export def "get-vla-ns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networking/vlans"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4beta"
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# NodeBalancers List
#
# GET /nodebalancers
# Returns: record<data: table<client_conn_throttle: int, created: string, hostname: string, id: int, ipv4: string, ipv6: string, label: string, region: string, tags: list, transfer: record, updated: string>, page: int, pages: int, results: int>
# operationId: getNodeBalancers
export def "get-node-balancers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nodebalancers"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# NodeBalancer Create
#
# POST /nodebalancers
# Returns: record<client_conn_throttle: int, created: string, hostname: string, id: int, ipv4: string, ipv6: string, label: string, region: string, tags: list<string>, transfer: record<in: float, out: float, total: float>, updated: string>
# operationId: createNodeBalancer
export def "create-node-balancer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-conn-throttle: int # Throttle connections per second. Set to 0 (zero) to disable throttling. (e.g. 0)
  --configs: list # The port Config(s) to create for this NodeBalancer. Each Config must have a unique port and at least one Node. — item shape: {algorithm?: "roundrobin"|"leastconn"|"source", check?: "none"|"connection"|"http"|"http_body", check_attempts?: int, check_body?: string, check_interval?: int, check_passive?: bool, check_path?: string, check_timeout?: int, cipher_suite?: "recommended"|"legacy", nodes?: list, port?: int, protocol?: "http"|"https"|"tcp", proxy_protocol?: "none"|"v1"|"v2", ssl_cert?: string, ssl_key?: string, stickiness?: "none"|"table"|"http_cookie"}
  --label: string # This NodeBalancer's label. These must be unique on your Account. (e.g. balancer12345)
  region: string # The ID of the Region to create this NodeBalancer in. (e.g. us-east)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/nodebalancers"
    body: {content_type: "application/json", kind: json, fields: [{name: client_conn_throttle, var: client_conn_throttle}, {name: configs, var: configs}, {name: label, var: label}, {name: region, var: region}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_conn_throttle: $client_conn_throttle, configs: $configs, label: $label, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# NodeBalancer Delete
#
# DELETE /nodebalancers/{nodeBalancerId}
# Returns: record
# operationId: deleteNodeBalancer
export def "delete-node-balancer" [
  node_balancer_id: int
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
    path: "/nodebalancers/{nodeBalancerId}"
    path_params: [{name: nodeBalancerId, var: node_balancer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_balancer_id: $node_balancer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# NodeBalancer View
#
# GET /nodebalancers/{nodeBalancerId}
# Returns: record<client_conn_throttle: int, created: string, hostname: string, id: int, ipv4: string, ipv6: string, label: string, region: string, tags: list<string>, transfer: record<in: float, out: float, total: float>, updated: string>
# operationId: getNodeBalancer
export def "get-node-balancer" [
  node_balancer_id: int
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
    path: "/nodebalancers/{nodeBalancerId}"
    path_params: [{name: nodeBalancerId, var: node_balancer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_balancer_id: $node_balancer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# NodeBalancer Update
#
# PUT /nodebalancers/{nodeBalancerId}
# Returns: record<client_conn_throttle: int, created: string, hostname: string, id: int, ipv4: string, ipv6: string, label: string, region: string, tags: list<string>, transfer: record<in: float, out: float, total: float>, updated: string>
# operationId: updateNodeBalancer
export def "update-node-balancer" [
  node_balancer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-conn-throttle: int # Throttle connections per second. Set to 0 (zero) to disable throttling. (e.g. 0)
  --label: string # This NodeBalancer's label. These must be unique on your Account. (e.g. balancer12345)
  --tags: list<string> # An array of Tags applied to this object. Tags are for organizational purposes only. (e.g. [example tag, another example])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/nodebalancers/{nodeBalancerId}"
    path_params: [{name: nodeBalancerId, var: node_balancer_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_conn_throttle, var: client_conn_throttle}, {name: label, var: label}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_balancer_id: $node_balancer_id, client_conn_throttle: $client_conn_throttle, label: $label, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configs List
#
# GET /nodebalancers/{nodeBalancerId}/configs
# Returns: record<data: table<algorithm: string, check: string, check_attempts: int, check_body: string, check_interval: int, check_passive: bool, check_path: string, check_timeout: int, cipher_suite: string, id: int, nodebalancer_id: int, nodes_status: record, port: int, protocol: string, proxy_protocol: string, ssl_cert: string, ssl_commonname: string, ssl_fingerprint: string, ssl_key: string, stickiness: string>, page: int, pages: int, results: int>
# operationId: getNodeBalancerConfigs
export def "get-node-balancer-configs" [
  node_balancer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nodebalancers/{nodeBalancerId}/configs"
    path_params: [{name: nodeBalancerId, var: node_balancer_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_balancer_id: $node_balancer_id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Config Create
#
# POST /nodebalancers/{nodeBalancerId}/configs
# Returns: record<algorithm: string, check: string, check_attempts: int, check_body: string, check_interval: int, check_passive: bool, check_path: string, check_timeout: int, cipher_suite: string, id: int, nodebalancer_id: int, nodes_status: record<down: int, up: int>, port: int, protocol: string, proxy_protocol: string, ssl_cert: string, ssl_commonname: string, ssl_fingerprint: string, ssl_key: string, stickiness: string>
# operationId: createNodeBalancerConfig
export def "create-node-balancer-config" [
  node_balancer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string@algorithm-completer # What algorithm this NodeBalancer should use for routing traffic to backends. (default: roundrobin, e.g. roundrobin)
  --check: string@check-completer # The type of check to perform against backends to ensure they are serving requests. This is used to determine if backends are up or down. * If `none` no check is performed. * `connection` requires only a connection to the backend to succeed. * `http` and `http_body` rely on the backend serving HTTP, and that the response returned matches what is expected. (default: none, e.g. http_body)
  --check-attempts: int # How many times to attempt a check before considering a backend to be down. (default: 3, e.g. 3)
  --check-body: string # This value must be present in the response body of the check in order for it to pass. If this value is not present in the response body of a check request, the backend is considered to be down. (e.g. it works)
  --check-interval: int # How often, in seconds, to check that backends are up and serving requests. Must be greater than `check_timeout`. (default: 31, e.g. 90)
  --check-passive: oneof<nothing, bool> # If true, any response from this backend with a `5xx` status code will be enough for it to be considered unhealthy and taken out of rotation. (default: true, e.g. true)
  --check-path: string # The URL path to check on each backend. If the backend does not respond to this request it is considered to be down. (e.g. /test)
  --check-timeout: int # How long, in seconds, to wait for a check attempt before considering it failed. Must be less than `check_interval`. (default: 30, e.g. 10)
  --cipher-suite: string@cipher-suite-completer # What ciphers to use for SSL connections served by this NodeBalancer. * `legacy` is considered insecure and should only be used if necessary. (default: recommended, e.g. recommended)
  --port: int # The port this Config is for. These values must be unique across configs on a single NodeBalancer (you can't have two configs for port 80, for example). While some ports imply some protocols, no enforcement is done and you may configure your NodeBalancer however is useful to you. For example, while port 443 is generally used for HTTPS, you do not need SSL configured to have a NodeBalancer listening on port 443. (default: 80, e.g. 80)
  --protocol: string@protocol-completer # The protocol this port is configured to serve. * The `http` and `tcp` protocols do not support `ssl_cert` and `ssl_key`. * The `https` protocol is mutually required with `ssl_cert` and `ssl_key`. Review our guide on [Available Protocols](/docs/products/networking/nodebalancers/guides/protocols/) for information on protocol features. (default: http, e.g. http)
  --proxy-protocol: string@proxy-protocol-completer # ProxyProtocol is a TCP extension that sends initial TCP connection information such as source/destination IPs and ports to backend devices. This information would be lost otherwise. Backend devices must be configured to work with ProxyProtocol if enabled. * If ommited, or set to `none`, the NodeBalancer doesn't send any auxilary data over TCP connections. This is the default. * If set to `v1`, the human-readable header format (Version 1) is used. Requires `tcp` protocol. * If set to `v2`, the binary header format (Version 2) is used. Requires `tcp` protocol. (default: none, e.g. none)
  --ssl-cert: string # The PEM-formatted public SSL certificate (or the combined PEM-formatted SSL certificate and Certificate Authority chain) that should be served on this NodeBalancerConfig's port. Line breaks must be represented as "\n" in the string for requests (but not when using the Linode CLI). [Diffie-Hellman Parameters](/docs/products/networking/nodebalancers/guides/ssl-termination/#diffie-hellman-parameters) can be included in this value to enable forward secrecy. The contents of this field will not be shown in any responses that display the NodeBalancerConfig. Instead, `` will be printed where the field appears. The read-only `ssl_commonname` and `ssl_fingerprint` fields in a NodeBalancerConfig response are automatically derived from your certificate. Please refer to these fields to verify that the appropriate certificate was assigned to your NodeBalancerConfig. (nullable, format: ssl-cert, e.g. <REDACTED>)
  --ssl-key: string # The PEM-formatted private key for the SSL certificate set in the `ssl_cert` field. Line breaks must be represented as "\n" in the string for requests (but not when using the Linode CLI). The contents of this field will not be shown in any responses that display the NodeBalancerConfig. Instead, `` will be printed where the field appears. The read-only `ssl_commonname` and `ssl_fingerprint` fields in a NodeBalancerConfig response are automatically derived from your certificate. Please refer to these fields to verify that the appropriate certificate was assigned to your NodeBalancerConfig. (nullable, format: ssl-key, e.g. <REDACTED>)
  --stickiness: string@stickiness-completer # Controls how session stickiness is handled on this port. * If set to `none` connections will always be assigned a backend based on the algorithm configured. * If set to `table` sessions from the same remote address will be routed to the same backend. * For HTTP or HTTPS clients, `http_cookie` allows sessions to be routed to the same backend based on a cookie set by the NodeBalancer. (default: none, e.g. http_cookie)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/nodebalancers/{nodeBalancerId}/configs"
    path_params: [{name: nodeBalancerId, var: node_balancer_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: algorithm, var: algorithm}, {name: check, var: check}, {name: check_attempts, var: check_attempts}, {name: check_body, var: check_body}, {name: check_interval, var: check_interval}, {name: check_passive, var: check_passive}, {name: check_path, var: check_path}, {name: check_timeout, var: check_timeout}, {name: cipher_suite, var: cipher_suite}, {name: port, var: port}, {name: protocol, var: protocol}, {name: proxy_protocol, var: proxy_protocol}, {name: ssl_cert, var: ssl_cert}, {name: ssl_key, var: ssl_key}, {name: stickiness, var: stickiness}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_balancer_id: $node_balancer_id, algorithm: $algorithm, check: $check, check_attempts: $check_attempts, check_body: $check_body, check_interval: $check_interval, check_passive: $check_passive, check_path: $check_path, check_timeout: $check_timeout, cipher_suite: $cipher_suite, port: $port, protocol: $protocol, proxy_protocol: $proxy_protocol, ssl_cert: $ssl_cert, ssl_key: $ssl_key, stickiness: $stickiness
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Config Delete
#
# DELETE /nodebalancers/{nodeBalancerId}/configs/{configId}
# Returns: record
# operationId: deleteNodeBalancerConfig
export def "delete-node-balancer-config" [
  node_balancer_id: int
  config_id: int
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
    path: "/nodebalancers/{nodeBalancerId}/configs/{configId}"
    path_params: [{name: nodeBalancerId, var: node_balancer_id}, {name: configId, var: config_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_balancer_id: $node_balancer_id, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Config View
#
# GET /nodebalancers/{nodeBalancerId}/configs/{configId}
# Returns: record<algorithm: string, check: string, check_attempts: int, check_body: string, check_interval: int, check_passive: bool, check_path: string, check_timeout: int, cipher_suite: string, id: int, nodebalancer_id: int, nodes_status: record<down: int, up: int>, port: int, protocol: string, proxy_protocol: string, ssl_cert: string, ssl_commonname: string, ssl_fingerprint: string, ssl_key: string, stickiness: string>
# operationId: getNodeBalancerConfig
export def "get-node-balancer-config" [
  node_balancer_id: int
  config_id: int
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
    path: "/nodebalancers/{nodeBalancerId}/configs/{configId}"
    path_params: [{name: nodeBalancerId, var: node_balancer_id}, {name: configId, var: config_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_balancer_id: $node_balancer_id, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Config Update
#
# PUT /nodebalancers/{nodeBalancerId}/configs/{configId}
# Returns: record<algorithm: string, check: string, check_attempts: int, check_body: string, check_interval: int, check_passive: bool, check_path: string, check_timeout: int, cipher_suite: string, id: int, nodebalancer_id: int, nodes_status: record<down: int, up: int>, port: int, protocol: string, proxy_protocol: string, ssl_cert: string, ssl_commonname: string, ssl_fingerprint: string, ssl_key: string, stickiness: string>
# operationId: updateNodeBalancerConfig
export def "update-node-balancer-config" [
  node_balancer_id: int
  config_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string@algorithm-completer # What algorithm this NodeBalancer should use for routing traffic to backends. (default: roundrobin, e.g. roundrobin)
  --check: string@check-completer # The type of check to perform against backends to ensure they are serving requests. This is used to determine if backends are up or down. * If `none` no check is performed. * `connection` requires only a connection to the backend to succeed. * `http` and `http_body` rely on the backend serving HTTP, and that the response returned matches what is expected. (default: none, e.g. http_body)
  --check-attempts: int # How many times to attempt a check before considering a backend to be down. (default: 3, e.g. 3)
  --check-body: string # This value must be present in the response body of the check in order for it to pass. If this value is not present in the response body of a check request, the backend is considered to be down. (e.g. it works)
  --check-interval: int # How often, in seconds, to check that backends are up and serving requests. Must be greater than `check_timeout`. (default: 31, e.g. 90)
  --check-passive: oneof<nothing, bool> # If true, any response from this backend with a `5xx` status code will be enough for it to be considered unhealthy and taken out of rotation. (default: true, e.g. true)
  --check-path: string # The URL path to check on each backend. If the backend does not respond to this request it is considered to be down. (e.g. /test)
  --check-timeout: int # How long, in seconds, to wait for a check attempt before considering it failed. Must be less than `check_interval`. (default: 30, e.g. 10)
  --cipher-suite: string@cipher-suite-completer # What ciphers to use for SSL connections served by this NodeBalancer. * `legacy` is considered insecure and should only be used if necessary. (default: recommended, e.g. recommended)
  --port: int # The port this Config is for. These values must be unique across configs on a single NodeBalancer (you can't have two configs for port 80, for example). While some ports imply some protocols, no enforcement is done and you may configure your NodeBalancer however is useful to you. For example, while port 443 is generally used for HTTPS, you do not need SSL configured to have a NodeBalancer listening on port 443. (default: 80, e.g. 80)
  --protocol: string@protocol-completer # The protocol this port is configured to serve. * The `http` and `tcp` protocols do not support `ssl_cert` and `ssl_key`. * The `https` protocol is mutually required with `ssl_cert` and `ssl_key`. Review our guide on [Available Protocols](/docs/products/networking/nodebalancers/guides/protocols/) for information on protocol features. (default: http, e.g. http)
  --proxy-protocol: string@proxy-protocol-completer # ProxyProtocol is a TCP extension that sends initial TCP connection information such as source/destination IPs and ports to backend devices. This information would be lost otherwise. Backend devices must be configured to work with ProxyProtocol if enabled. * If ommited, or set to `none`, the NodeBalancer doesn't send any auxilary data over TCP connections. This is the default. * If set to `v1`, the human-readable header format (Version 1) is used. Requires `tcp` protocol. * If set to `v2`, the binary header format (Version 2) is used. Requires `tcp` protocol. (default: none, e.g. none)
  --ssl-cert: string # The PEM-formatted public SSL certificate (or the combined PEM-formatted SSL certificate and Certificate Authority chain) that should be served on this NodeBalancerConfig's port. Line breaks must be represented as "\n" in the string for requests (but not when using the Linode CLI). [Diffie-Hellman Parameters](/docs/products/networking/nodebalancers/guides/ssl-termination/#diffie-hellman-parameters) can be included in this value to enable forward secrecy. The contents of this field will not be shown in any responses that display the NodeBalancerConfig. Instead, `` will be printed where the field appears. The read-only `ssl_commonname` and `ssl_fingerprint` fields in a NodeBalancerConfig response are automatically derived from your certificate. Please refer to these fields to verify that the appropriate certificate was assigned to your NodeBalancerConfig. (nullable, format: ssl-cert, e.g. <REDACTED>)
  --ssl-key: string # The PEM-formatted private key for the SSL certificate set in the `ssl_cert` field. Line breaks must be represented as "\n" in the string for requests (but not when using the Linode CLI). The contents of this field will not be shown in any responses that display the NodeBalancerConfig. Instead, `` will be printed where the field appears. The read-only `ssl_commonname` and `ssl_fingerprint` fields in a NodeBalancerConfig response are automatically derived from your certificate. Please refer to these fields to verify that the appropriate certificate was assigned to your NodeBalancerConfig. (nullable, format: ssl-key, e.g. <REDACTED>)
  --stickiness: string@stickiness-completer # Controls how session stickiness is handled on this port. * If set to `none` connections will always be assigned a backend based on the algorithm configured. * If set to `table` sessions from the same remote address will be routed to the same backend. * For HTTP or HTTPS clients, `http_cookie` allows sessions to be routed to the same backend based on a cookie set by the NodeBalancer. (default: none, e.g. http_cookie)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/nodebalancers/{nodeBalancerId}/configs/{configId}"
    path_params: [{name: nodeBalancerId, var: node_balancer_id}, {name: configId, var: config_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: algorithm, var: algorithm}, {name: check, var: check}, {name: check_attempts, var: check_attempts}, {name: check_body, var: check_body}, {name: check_interval, var: check_interval}, {name: check_passive, var: check_passive}, {name: check_path, var: check_path}, {name: check_timeout, var: check_timeout}, {name: cipher_suite, var: cipher_suite}, {name: port, var: port}, {name: protocol, var: protocol}, {name: proxy_protocol, var: proxy_protocol}, {name: ssl_cert, var: ssl_cert}, {name: ssl_key, var: ssl_key}, {name: stickiness, var: stickiness}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_balancer_id: $node_balancer_id, config_id: $config_id, algorithm: $algorithm, check: $check, check_attempts: $check_attempts, check_body: $check_body, check_interval: $check_interval, check_passive: $check_passive, check_path: $check_path, check_timeout: $check_timeout, cipher_suite: $cipher_suite, port: $port, protocol: $protocol, proxy_protocol: $proxy_protocol, ssl_cert: $ssl_cert, ssl_key: $ssl_key, stickiness: $stickiness
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Nodes List
#
# GET /nodebalancers/{nodeBalancerId}/configs/{configId}/nodes
# Returns: record<data: table<address: string, config_id: int, id: int, label: string, mode: string, nodebalancer_id: int, status: string, weight: int>, page: int, pages: int, results: int>
# operationId: getNodeBalancerConfigNodes
export def "get-node-balancer-config-nodes" [
  node_balancer_id: int
  config_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nodebalancers/{nodeBalancerId}/configs/{configId}/nodes"
    path_params: [{name: nodeBalancerId, var: node_balancer_id}, {name: configId, var: config_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_balancer_id: $node_balancer_id, config_id: $config_id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Node Create
#
# POST /nodebalancers/{nodeBalancerId}/configs/{configId}/nodes
# Returns: record<address: string, config_id: int, id: int, label: string, mode: string, nodebalancer_id: int, status: string, weight: int>
# operationId: createNodeBalancerNode
export def "create-node-balancer-node" [
  node_balancer_id: int
  config_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # The private IP Address where this backend can be reached. This _must_ be a private IP address. (format: ip, e.g. 192.168.210.120:80)
  label: string # The label for this node. This is for display purposes only. (e.g. node54321)
  --mode: string@mode-completer # The mode this NodeBalancer should use when sending traffic to this backend. * If set to `accept` this backend is accepting traffic. * If set to `reject` this backend will not receive traffic. * If set to `drain` this backend will not receive _new_ traffic, but connections already pinned to it will continue to be routed to it. * If set to `backup`, this backend will only receive traffic if all `accept` nodes are down. (e.g. accept)
  --weight: int # Used when picking a backend to serve a request and is not pinned to a single backend yet. Nodes with a higher weight will receive more traffic. (e.g. 50)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/nodebalancers/{nodeBalancerId}/configs/{configId}/nodes"
    path_params: [{name: nodeBalancerId, var: node_balancer_id}, {name: configId, var: config_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: label, var: label}, {name: mode, var: mode}, {name: weight, var: weight}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_balancer_id: $node_balancer_id, config_id: $config_id, address: $address, label: $label, mode: $mode, weight: $weight
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Node Delete
#
# DELETE /nodebalancers/{nodeBalancerId}/configs/{configId}/nodes/{nodeId}
# Returns: record
# operationId: deleteNodeBalancerConfigNode
export def "delete-node-balancer-config-node" [
  node_balancer_id: int
  config_id: int
  node_id: int
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
    path: "/nodebalancers/{nodeBalancerId}/configs/{configId}/nodes/{nodeId}"
    path_params: [{name: nodeBalancerId, var: node_balancer_id}, {name: configId, var: config_id}, {name: nodeId, var: node_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_balancer_id: $node_balancer_id, config_id: $config_id, node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Node View
#
# GET /nodebalancers/{nodeBalancerId}/configs/{configId}/nodes/{nodeId}
# Returns: record<address: string, config_id: int, id: int, label: string, mode: string, nodebalancer_id: int, status: string, weight: int>
# operationId: getNodeBalancerNode
export def "get-node-balancer-node" [
  node_balancer_id: int
  config_id: int
  node_id: int
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
    path: "/nodebalancers/{nodeBalancerId}/configs/{configId}/nodes/{nodeId}"
    path_params: [{name: nodeBalancerId, var: node_balancer_id}, {name: configId, var: config_id}, {name: nodeId, var: node_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_balancer_id: $node_balancer_id, config_id: $config_id, node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Node Update
#
# PUT /nodebalancers/{nodeBalancerId}/configs/{configId}/nodes/{nodeId}
# Returns: record<address: string, config_id: int, id: int, label: string, mode: string, nodebalancer_id: int, status: string, weight: int>
# operationId: updateNodeBalancerNode
export def "update-node-balancer-node" [
  node_balancer_id: int
  config_id: int
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # The private IP Address where this backend can be reached. This _must_ be a private IP address. (format: ip, e.g. 192.168.210.120:80)
  --label: string # The label for this node. This is for display purposes only. (e.g. node54321)
  --mode: string@mode-completer # The mode this NodeBalancer should use when sending traffic to this backend. * If set to `accept` this backend is accepting traffic. * If set to `reject` this backend will not receive traffic. * If set to `drain` this backend will not receive _new_ traffic, but connections already pinned to it will continue to be routed to it. * If set to `backup`, this backend will only receive traffic if all `accept` nodes are down. (e.g. accept)
  --weight: int # Used when picking a backend to serve a request and is not pinned to a single backend yet. Nodes with a higher weight will receive more traffic. (e.g. 50)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/nodebalancers/{nodeBalancerId}/configs/{configId}/nodes/{nodeId}"
    path_params: [{name: nodeBalancerId, var: node_balancer_id}, {name: configId, var: config_id}, {name: nodeId, var: node_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: label, var: label}, {name: mode, var: mode}, {name: weight, var: weight}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_balancer_id: $node_balancer_id, config_id: $config_id, node_id: $node_id, address: $address, label: $label, mode: $mode, weight: $weight
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Config Rebuild
#
# POST /nodebalancers/{nodeBalancerId}/configs/{configId}/rebuild
# Returns: record<algorithm: string, check: string, check_attempts: int, check_body: string, check_interval: int, check_passive: bool, check_path: string, check_timeout: int, cipher_suite: string, id: int, nodebalancer_id: int, nodes_status: record<down: int, up: int>, port: int, protocol: string, proxy_protocol: string, ssl_cert: string, ssl_commonname: string, ssl_fingerprint: string, ssl_key: string, stickiness: string>
# operationId: rebuildNodeBalancerConfig
export def "rebuild-node-balancer-config" [
  node_balancer_id: int
  config_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string@algorithm-completer # What algorithm this NodeBalancer should use for routing traffic to backends. (default: roundrobin, e.g. roundrobin)
  --check: string@check-completer # The type of check to perform against backends to ensure they are serving requests. This is used to determine if backends are up or down. * If `none` no check is performed. * `connection` requires only a connection to the backend to succeed. * `http` and `http_body` rely on the backend serving HTTP, and that the response returned matches what is expected. (default: none, e.g. http_body)
  --check-attempts: int # How many times to attempt a check before considering a backend to be down. (default: 3, e.g. 3)
  --check-body: string # This value must be present in the response body of the check in order for it to pass. If this value is not present in the response body of a check request, the backend is considered to be down. (e.g. it works)
  --check-interval: int # How often, in seconds, to check that backends are up and serving requests. Must be greater than `check_timeout`. (default: 31, e.g. 90)
  --check-passive: oneof<nothing, bool> # If true, any response from this backend with a `5xx` status code will be enough for it to be considered unhealthy and taken out of rotation. (default: true, e.g. true)
  --check-path: string # The URL path to check on each backend. If the backend does not respond to this request it is considered to be down. (e.g. /test)
  --check-timeout: int # How long, in seconds, to wait for a check attempt before considering it failed. Must be less than `check_interval`. (default: 30, e.g. 10)
  --cipher-suite: string@cipher-suite-completer # What ciphers to use for SSL connections served by this NodeBalancer. * `legacy` is considered insecure and should only be used if necessary. (default: recommended, e.g. recommended)
  --port: int # The port this Config is for. These values must be unique across configs on a single NodeBalancer (you can't have two configs for port 80, for example). While some ports imply some protocols, no enforcement is done and you may configure your NodeBalancer however is useful to you. For example, while port 443 is generally used for HTTPS, you do not need SSL configured to have a NodeBalancer listening on port 443. (default: 80, e.g. 80)
  --protocol: string@protocol-completer # The protocol this port is configured to serve. * The `http` and `tcp` protocols do not support `ssl_cert` and `ssl_key`. * The `https` protocol is mutually required with `ssl_cert` and `ssl_key`. Review our guide on [Available Protocols](/docs/products/networking/nodebalancers/guides/protocols/) for information on protocol features. (default: http, e.g. http)
  --proxy-protocol: string@proxy-protocol-completer # ProxyProtocol is a TCP extension that sends initial TCP connection information such as source/destination IPs and ports to backend devices. This information would be lost otherwise. Backend devices must be configured to work with ProxyProtocol if enabled. * If ommited, or set to `none`, the NodeBalancer doesn't send any auxilary data over TCP connections. This is the default. * If set to `v1`, the human-readable header format (Version 1) is used. Requires `tcp` protocol. * If set to `v2`, the binary header format (Version 2) is used. Requires `tcp` protocol. (default: none, e.g. none)
  --ssl-cert: string # The PEM-formatted public SSL certificate (or the combined PEM-formatted SSL certificate and Certificate Authority chain) that should be served on this NodeBalancerConfig's port. Line breaks must be represented as "\n" in the string for requests (but not when using the Linode CLI). [Diffie-Hellman Parameters](/docs/products/networking/nodebalancers/guides/ssl-termination/#diffie-hellman-parameters) can be included in this value to enable forward secrecy. The contents of this field will not be shown in any responses that display the NodeBalancerConfig. Instead, `` will be printed where the field appears. The read-only `ssl_commonname` and `ssl_fingerprint` fields in a NodeBalancerConfig response are automatically derived from your certificate. Please refer to these fields to verify that the appropriate certificate was assigned to your NodeBalancerConfig. (nullable, format: ssl-cert, e.g. <REDACTED>)
  --ssl-key: string # The PEM-formatted private key for the SSL certificate set in the `ssl_cert` field. Line breaks must be represented as "\n" in the string for requests (but not when using the Linode CLI). The contents of this field will not be shown in any responses that display the NodeBalancerConfig. Instead, `` will be printed where the field appears. The read-only `ssl_commonname` and `ssl_fingerprint` fields in a NodeBalancerConfig response are automatically derived from your certificate. Please refer to these fields to verify that the appropriate certificate was assigned to your NodeBalancerConfig. (nullable, format: ssl-key, e.g. <REDACTED>)
  --stickiness: string@stickiness-completer # Controls how session stickiness is handled on this port. * If set to `none` connections will always be assigned a backend based on the algorithm configured. * If set to `table` sessions from the same remote address will be routed to the same backend. * For HTTP or HTTPS clients, `http_cookie` allows sessions to be routed to the same backend based on a cookie set by the NodeBalancer. (default: none, e.g. http_cookie)
  nodes: list # The NodeBalancer Node(s) that serve this Config. Some considerations for Nodes when rebuilding a config: * Current Nodes excluded from the request body will be deleted from the Config. * Current Nodes (identified by their Node ID) will be updated. * New Nodes (included without a Node ID) will be created. — item shape: {address?: string, id?: int, label?: string, mode?: "accept"|"reject"|"drain"|"backup", weight?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/nodebalancers/{nodeBalancerId}/configs/{configId}/rebuild"
    path_params: [{name: nodeBalancerId, var: node_balancer_id}, {name: configId, var: config_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: algorithm, var: algorithm}, {name: check, var: check}, {name: check_attempts, var: check_attempts}, {name: check_body, var: check_body}, {name: check_interval, var: check_interval}, {name: check_passive, var: check_passive}, {name: check_path, var: check_path}, {name: check_timeout, var: check_timeout}, {name: cipher_suite, var: cipher_suite}, {name: port, var: port}, {name: protocol, var: protocol}, {name: proxy_protocol, var: proxy_protocol}, {name: ssl_cert, var: ssl_cert}, {name: ssl_key, var: ssl_key}, {name: stickiness, var: stickiness}, {name: nodes, var: nodes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_balancer_id: $node_balancer_id, config_id: $config_id, algorithm: $algorithm, check: $check, check_attempts: $check_attempts, check_body: $check_body, check_interval: $check_interval, check_passive: $check_passive, check_path: $check_path, check_timeout: $check_timeout, cipher_suite: $cipher_suite, port: $port, protocol: $protocol, proxy_protocol: $proxy_protocol, ssl_cert: $ssl_cert, ssl_key: $ssl_key, stickiness: $stickiness, nodes: $nodes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# NodeBalancer Statistics View
#
# GET /nodebalancers/{nodeBalancerId}/stats
# Returns: record<data: record<connections: list<float>, traffic: record<in: list, out: list>>, title: string>
export def "get-nodebalancers-node-balancer-id-stats" [
  node_balancer_id: int
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
    path: "/nodebalancers/{nodeBalancerId}/stats"
    path_params: [{name: nodeBalancerId, var: node_balancer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_balancer_id: $node_balancer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Buckets List
#
# GET /object-storage/buckets
# Returns: record<data: table<cluster: string, created: string, hostname: string, label: string, objects: int, size: int>, page: int, pages: int, results: int>
# operationId: getObjectStorageBuckets
export def "get-object-storage-buckets" [
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
    path: "/object-storage/buckets"
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Bucket Create
#
# POST /object-storage/buckets
# Returns: record<cluster: string, created: string, hostname: string, label: string, objects: int, size: int>
# operationId: createObjectStorageBucket
export def "create-object-storage-bucket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --acl: string@acl-completer # The Access Control Level of the bucket using a canned ACL string. For more fine-grained control of ACLs, use the S3 API directly. (default: private, e.g. private)
  cluster: string # The ID of the Object Storage Cluster where this bucket should be created. (e.g. us-east-1)
  --cors-enabled: oneof<nothing, bool> # If true, the bucket will be created with CORS enabled for all origins. For more fine-grained controls of CORS, use the S3 API directly. (default: false, e.g. true)
  label: string # The name for this bucket. Must be unique in the cluster you are creating the bucket in, or an error will be returned. Labels will be reserved only for the cluster that active buckets are created and stored in. If you want to reserve this bucket's label in another cluster, you must create a new bucket with the same label in the new cluster. (e.g. example-bucket)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/object-storage/buckets"
    body: {content_type: "application/json", kind: json, fields: [{name: acl, var: acl}, {name: cluster, var: cluster}, {name: cors_enabled, var: cors_enabled}, {name: label, var: label}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    acl: $acl, cluster: $cluster, cors_enabled: $cors_enabled, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Buckets in Cluster List
#
# GET /object-storage/buckets/{clusterId}
# Returns: record<data: table<cluster: string, created: string, hostname: string, label: string, objects: int, size: int>, page: int, pages: int, results: int>
# operationId: getObjectStorageBucketinCluster
export def "get-object-storage-bucketin-cluster" [
  cluster_id: string
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
    path: "/object-storage/buckets/{clusterId}"
    path_params: [{name: clusterId, var: cluster_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Bucket Remove
#
# DELETE /object-storage/buckets/{clusterId}/{bucket}
# Returns: record
# operationId: deleteObjectStorageBucket
export def "delete-object-storage-bucket" [
  cluster_id: string
  bucket: string
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
    path: "/object-storage/buckets/{clusterId}/{bucket}"
    path_params: [{name: clusterId, var: cluster_id}, {name: bucket, var: bucket}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    cluster_id: $cluster_id, bucket: $bucket
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Bucket View
#
# GET /object-storage/buckets/{clusterId}/{bucket}
# Returns: record<cluster: string, created: string, hostname: string, label: string, objects: int, size: int>
# operationId: getObjectStorageBucket
export def "get-object-storage-bucket" [
  cluster_id: string
  bucket: string
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
    path: "/object-storage/buckets/{clusterId}/{bucket}"
    path_params: [{name: clusterId, var: cluster_id}, {name: bucket, var: bucket}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    cluster_id: $cluster_id, bucket: $bucket
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Bucket Access Modify
#
# POST /object-storage/buckets/{clusterId}/{bucket}/access
# Returns: record
# operationId: modifyObjectStorageBucketAccess
export def "modify-object-storage-bucket-access" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --acl: string@acl-completer-1 # The Access Control Level of the bucket, as a canned ACL string. For more fine-grained control of ACLs, use the S3 API directly. (e.g. private)
  --cors-enabled: oneof<nothing, bool> # If true, the bucket will be created with CORS enabled for all origins. For more fine-grained controls of CORS, use the S3 API directly. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/object-storage/buckets/{clusterId}/{bucket}/access"
    path_params: [{name: clusterId, var: cluster_id}, {name: bucket, var: bucket}]
    body: {content_type: "application/json", kind: json, fields: [{name: acl, var: acl}, {name: cors_enabled, var: cors_enabled}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    cluster_id: $cluster_id, bucket: $bucket, acl: $acl, cors_enabled: $cors_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Bucket Access Update
#
# PUT /object-storage/buckets/{clusterId}/{bucket}/access
# Returns: record
# operationId: updateObjectStorageBucketAccess
export def "update-object-storage-bucket-access" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --acl: string@acl-completer-1 # The Access Control Level of the bucket, as a canned ACL string. For more fine-grained control of ACLs, use the S3 API directly. (e.g. private)
  --cors-enabled: oneof<nothing, bool> # If true, the bucket will be created with CORS enabled for all origins. For more fine-grained controls of CORS, use the S3 API directly. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/object-storage/buckets/{clusterId}/{bucket}/access"
    path_params: [{name: clusterId, var: cluster_id}, {name: bucket, var: bucket}]
    body: {content_type: "application/json", kind: json, fields: [{name: acl, var: acl}, {name: cors_enabled, var: cors_enabled}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    cluster_id: $cluster_id, bucket: $bucket, acl: $acl, cors_enabled: $cors_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Object ACL Config View
#
# GET /object-storage/buckets/{clusterId}/{bucket}/object-acl
# Returns: record<acl: string, acl_xml: string>
# operationId: viewObjectStorageBucketACL
export def "view-object-storage-bucket-acl" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The `name` of the object for which to retrieve its Access Control List (ACL). Use the [Object Storage Bucket Contents List](/docs/api/object-storage/#object-storage-bucket-contents-list) endpoint to access all object names in a bucket. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/object-storage/buckets/{clusterId}/{bucket}/object-acl"
    path_params: [{name: clusterId, var: cluster_id}, {name: bucket, var: bucket}]
    query: [{name: name, var: name, required: true}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    cluster_id: $cluster_id, bucket: $bucket, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Object ACL Config Update
#
# PUT /object-storage/buckets/{clusterId}/{bucket}/object-acl
# Returns: record<acl: string, acl_xml: string>
# operationId: updateObjectStorageBucketACL
export def "update-object-storage-bucket-acl" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  acl: string@acl-completer-1 # The Access Control Level of the bucket, as a canned ACL string. For more fine-grained control of ACLs, use the S3 API directly. (e.g. public-read)
  name: string # The `name` of the object for which to update its Access Control List (ACL). Use the [Object Storage Bucket Contents List](/docs/api/object-storage/#object-storage-bucket-contents-list) endpoint to access all object names in a bucket.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/object-storage/buckets/{clusterId}/{bucket}/object-acl"
    path_params: [{name: clusterId, var: cluster_id}, {name: bucket, var: bucket}]
    body: {content_type: "application/json", kind: json, fields: [{name: acl, var: acl}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    cluster_id: $cluster_id, bucket: $bucket, acl: $acl, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Bucket Contents List
#
# GET /object-storage/buckets/{clusterId}/{bucket}/object-list
# Returns: record<data: table<etag: string, is_truncated: bool, last_modified: string, name: string, next_marker: string, owner: string, size: int>>
# operationId: getObjectStorageBucketContent
export def "get-object-storage-bucket-content" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # The "marker" for this request, which can be used to paginate through large buckets. Its value should be the value of the `next_marker` property returned with the last page. Listing bucket contents *does not* support arbitrary page access. See the `next_marker` property in the responses section for more details.
  --delimiter: string # The delimiter for object names; if given, object names will be returned up to the first occurrence of this character. This is most commonly used with the `/` character to allow bucket transversal in a manner similar to a filesystem, however any delimiter may be used. Use in conjunction with `prefix` to see object names past the first occurrence of the delimiter.
  --prefix: string # Filters objects returned to only those whose name start with the given prefix. Commonly used in conjunction with `delimiter` to allow transversal of bucket contents in a manner similar to a filesystem.
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/object-storage/buckets/{clusterId}/{bucket}/object-list"
    path_params: [{name: clusterId, var: cluster_id}, {name: bucket, var: bucket}]
    query: [{name: marker, var: marker}, {name: delimiter, var: delimiter}, {name: prefix, var: prefix}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    cluster_id: $cluster_id, bucket: $bucket, marker: $marker, delimiter: $delimiter, prefix: $prefix, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Object URL Create
#
# POST /object-storage/buckets/{clusterId}/{bucket}/object-url
# Returns: record<url: string>
# operationId: createObjectStorageObjectURL
export def "create-object-storage-object-url" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The expected `Content-type` header of the request this signed URL will be valid for. If provided, the `Content-type` header _must_ be sent with the request when this URL is used, and _must_ be the same as it was when the signed URL was created. Required for all methods *except* "GET" or "DELETE".
  --expires-in: int # How long this signed URL will be valid for, in seconds. If omitted, the URL will be valid for 3600 seconds (1 hour). (default: 3600)
  method: string # The HTTP method allowed to be used with the pre-signed URL. (default: GET, e.g. GET)
  name: string # The name of the object that will be accessed with the pre-signed URL. This object need not exist, and no error will be returned if it doesn't. This behavior is useful for generating pre-signed URLs to upload new objects to by setting the `method` to "PUT". (e.g. example)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/object-storage/buckets/{clusterId}/{bucket}/object-url"
    path_params: [{name: clusterId, var: cluster_id}, {name: bucket, var: bucket}]
    body: {content_type: "application/json", kind: json, fields: [{name: content_type, var: content_type}, {name: expires_in, var: expires_in}, {name: method, var: method}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    cluster_id: $cluster_id, bucket: $bucket, content_type: $content_type, expires_in: $expires_in, method: $method, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage TLS/SSL Cert Delete
#
# DELETE /object-storage/buckets/{clusterId}/{bucket}/ssl
# Returns: record
# operationId: deleteObjectStorageSSL
export def "delete-object-storage-ssl" [
  cluster_id: string
  bucket: string
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
    path: "/object-storage/buckets/{clusterId}/{bucket}/ssl"
    path_params: [{name: clusterId, var: cluster_id}, {name: bucket, var: bucket}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    cluster_id: $cluster_id, bucket: $bucket
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage TLS/SSL Cert View
#
# GET /object-storage/buckets/{clusterId}/{bucket}/ssl
# Returns: record<ssl: bool>
# operationId: getObjectStorageSSL
export def "get-object-storage-ssl" [
  cluster_id: string
  bucket: string
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
    path: "/object-storage/buckets/{clusterId}/{bucket}/ssl"
    path_params: [{name: clusterId, var: cluster_id}, {name: bucket, var: bucket}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    cluster_id: $cluster_id, bucket: $bucket
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage TLS/SSL Cert Upload
#
# POST /object-storage/buckets/{clusterId}/{bucket}/ssl
# Returns: record<ssl: bool>
# operationId: createObjectStorageSSL
export def "create-object-storage-ssl" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  certificate: string # Your Base64 encoded and PEM formatted SSL certificate. Line breaks must be represented as "\n" in the string for requests (but not when using the Linode CLI) (e.g. -----BEGIN CERTIFICATE----- CERTIFICATE_INFORMATION -----END CERTIFICATE-----)
  private_key: string # The private key associated with this TLS/SSL certificate. Line breaks must be represented as "\n" in the string for requests (but not when using the Linode CLI) (e.g. -----BEGIN PRIVATE KEY----- PRIVATE_KEY_INFORMATION -----END PRIVATE KEY-----)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/object-storage/buckets/{clusterId}/{bucket}/ssl"
    path_params: [{name: clusterId, var: cluster_id}, {name: bucket, var: bucket}]
    body: {content_type: "application/json", kind: json, fields: [{name: certificate, var: certificate}, {name: private_key, var: private_key}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    cluster_id: $cluster_id, bucket: $bucket, certificate: $certificate, private_key: $private_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Cancel
#
# POST /object-storage/cancel
# Returns: record
# operationId: cancelObjectStorage
export def "cancel-object-storage" [
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
    method: post
    path: "/object-storage/cancel"
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clusters List
#
# GET /object-storage/clusters
# Returns: record<data: table<domain: string, id: string, region: string, static_site_domain: string, status: string>, page: int, pages: int, results: int>
# operationId: getObjectStorageClusters
export def "get-object-storage-clusters" [
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
    path: "/object-storage/clusters"
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cluster View
#
# GET /object-storage/clusters/{clusterId}
# Returns: record<domain: string, id: string, region: string, static_site_domain: string, status: string>
# operationId: getObjectStorageCluster
export def "get-object-storage-cluster" [
  cluster_id: string
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
    path: "/object-storage/clusters/{clusterId}"
    path_params: [{name: clusterId, var: cluster_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Keys List
#
# GET /object-storage/keys
# Returns: record<data: table<access_key: string, bucket_access: list, id: int, label: string, limited: bool, secret_key: string>, page: int, pages: int, results: int>
# operationId: getObjectStorageKeys
export def "get-object-storage-keys" [
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
    path: "/object-storage/keys"
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Key Create
#
# POST /object-storage/keys
# Returns: record<access_key: string, bucket_access: table<bucket_name: string, cluster: string, permissions: string>, id: int, label: string, limited: bool, secret_key: string>
# operationId: createObjectStorageKeys
export def "create-object-storage-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bucket-access: list # Defines this key as a Limited Access Key. Limited Access Keys restrict this Object Storage key's access to only the bucket(s) declared in this array and define their bucket-level permissions. Limited Access Keys can: * [list all buckets](/docs/api/object-storage/#object-storage-buckets-list) available on this Account, but cannot perform any actions on a bucket unless it has access to the bucket. * [create new buckets](/docs/api/object-storage/#object-storage-bucket-create), but do not have any access to the buckets it creates, unless explicitly given access to them. **Note:** You can create an Object Storage Limited Access Key without access to any buckets. This is achieved by sending a request with an empty `bucket_access` array. **Note:** If this field is omitted, a regular unlimited access key is issued. — item shape: {bucket_name?: string, cluster?: string, permissions?: "read_write"|"read_only"}
  --label: string # The label given to this key. For display purposes only. (e.g. my-key)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/object-storage/keys"
    body: {content_type: "application/json", kind: json, fields: [{name: bucket_access, var: bucket_access}, {name: label, var: label}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    bucket_access: $bucket_access, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Key Revoke
#
# DELETE /object-storage/keys/{keyId}
# Returns: record
# operationId: deleteObjectStorageKey
export def "delete-object-storage-key" [
  key_id: int
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
    path: "/object-storage/keys/{keyId}"
    path_params: [{name: keyId, var: key_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Key View
#
# GET /object-storage/keys/{keyId}
# Returns: record<access_key: string, bucket_access: table<bucket_name: string, cluster: string, permissions: string>, id: int, label: string, limited: bool, secret_key: string>
# operationId: getObjectStorageKey
export def "get-object-storage-key" [
  key_id: int
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
    path: "/object-storage/keys/{keyId}"
    path_params: [{name: keyId, var: key_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Key Update
#
# PUT /object-storage/keys/{keyId}
# Returns: record<access_key: string, bucket_access: table<bucket_name: string, cluster: string, permissions: string>, id: int, label: string, limited: bool, secret_key: string>
# operationId: updateObjectStorageKey
export def "update-object-storage-key" [
  key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # The label for this keypair, for display purposes only. (e.g. my-key)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/object-storage/keys/{keyId}"
    path_params: [{name: keyId, var: key_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    key_id: $key_id, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Object Storage Transfer View
#
# GET /object-storage/transfer
# Returns: record<used: int>
# operationId: getObjectStorageTransfer
export def "get-object-storage-transfer" [
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
    path: "/object-storage/transfer"
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Profile View
#
# GET /profile
# Returns: record<authentication_type: string, authorized_keys: list<string>, email: string, email_notifications: bool, ip_whitelist_enabled: bool, lish_auth_method: string, referrals: record<code: string, completed: int, credit: int, pending: int, total: int, url: string>, restricted: bool, timezone: string, two_factor_auth: bool, uid: int, username: string, verified_phone_number: string>
# operationId: getProfile
export def "get-profile" [
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
    path: "/profile"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Profile Update
#
# PUT /profile
# Returns: record<authentication_type: string, authorized_keys: list<string>, email: string, email_notifications: bool, ip_whitelist_enabled: bool, lish_auth_method: string, referrals: record<code: string, completed: int, credit: int, pending: int, total: int, url: string>, restricted: bool, timezone: string, two_factor_auth: bool, uid: int, username: string, verified_phone_number: string>
# operationId: updateProfile
@deprecated --flag ip-whitelist-enabled
export def "update-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorized-keys: list<string> # The list of SSH Keys authorized to use Lish for your User. This value is ignored if `lish_auth_method` is "disabled." (nullable)
  --email: string # Your email address. This address will be used for communication with Linode as necessary. (format: email, e.g. example-user@gmail.com)
  --email-notifications: oneof<nothing, bool> # If true, you will receive email notifications about account activity. If false, you may still receive business-critical communications through email. (e.g. true)
  --ip-whitelist-enabled: oneof<nothing, bool> # If true, logins for your User will only be allowed from whitelisted IPs. This setting is currently deprecated, and cannot be enabled. If you disable this setting, you will not be able to re-enable it. (DEPRECATED, e.g. false)
  --lish-auth-method: string@lish-auth-method-completer # The authentication methods that are allowed when connecting to [the Linode Shell (Lish)](/docs/guides/lish/). * `keys_only` is the most secure if you intend to use Lish. * `disabled` is recommended if you do not intend to use Lish at all. * If this account's Cloud Manager authentication type is set to a Third-Party Authentication method, `password_keys` cannot be used as your Lish authentication method. To view this account's Cloud Manager `authentication_type` field, send a request to the [View Profile](/docs/api/profile/#profile-view) endpoint. (e.g. keys_only)
  --restricted: oneof<nothing, bool> # If true, your User has restrictions on what can be accessed on your Account. To get details on what entities/actions you can access/perform, see [/profile/grants](/docs/api/profile/#grants-list). (e.g. false)
  --timezone: string # The timezone you prefer to see times in. This is not used by the API directly. It is provided for the benefit of clients such as the Linode Cloud Manager and other clients built on the API. All times returned by the API are in UTC. (e.g. US/Eastern)
  --two-factor-auth: oneof<nothing, bool> # If true, logins from untrusted computers will require Two Factor Authentication. See [/profile/tfa-enable](/docs/api/profile/#two-factor-secret-create) to enable Two Factor Authentication. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/profile"
    body: {content_type: "application/json", kind: json, fields: [{name: authorized_keys, var: authorized_keys}, {name: email, var: email}, {name: email_notifications, var: email_notifications}, {name: ip_whitelist_enabled, var: ip_whitelist_enabled}, {name: lish_auth_method, var: lish_auth_method}, {name: restricted, var: restricted}, {name: timezone, var: timezone}, {name: two_factor_auth, var: two_factor_auth}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorized_keys: $authorized_keys, email: $email, email_notifications: $email_notifications, ip_whitelist_enabled: $ip_whitelist_enabled, lish_auth_method: $lish_auth_method, restricted: $restricted, timezone: $timezone, two_factor_auth: $two_factor_auth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authorized Apps List
#
# GET /profile/apps
# Returns: record<data: table<created: string, expiry: string, id: int, label: string, scopes: string, thumbnail_url: string, website: string>, page: int, pages: int, results: int>
# operationId: getProfileApps
export def "get-profile-apps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/profile/apps"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# App Access Revoke
#
# DELETE /profile/apps/{appId}
# Returns: record
# operationId: deleteProfileApp
export def "delete-profile-app" [
  app_id: int
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
    path: "/profile/apps/{appId}"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authorized App View
#
# GET /profile/apps/{appId}
# Returns: record<created: string, expiry: string, id: int, label: string, scopes: string, thumbnail_url: string, website: string>
# operationId: getProfileApp
export def "get-profile-app" [
  app_id: int
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
    path: "/profile/apps/{appId}"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trusted Devices List
#
# GET /profile/devices
# Returns: record<data: table<created: string, expiry: string, id: int, last_authenticated: string, last_remote_addr: string, user_agent: string>, page: int, pages: int, results: int>
# operationId: getDevices
export def "get-devices" [
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
    path: "/profile/devices"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trusted Device Revoke
#
# DELETE /profile/devices/{deviceId}
# Returns: record
# operationId: revokeTrustedDevice
export def "revoke-trusted-device" [
  device_id: int
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
    path: "/profile/devices/{deviceId}"
    path_params: [{name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trusted Device View
#
# GET /profile/devices/{deviceId}
# Returns: record<created: string, expiry: string, id: int, last_authenticated: string, last_remote_addr: string, user_agent: string>
# operationId: getTrustedDevice
export def "get-trusted-device" [
  device_id: int
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
    path: "/profile/devices/{deviceId}"
    path_params: [{name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Grants List
#
# GET /profile/grants
# Returns: record<database: table<id: int, label: string, permissions: string>, domain: table<id: int, label: string, permissions: string>, global: record<account_access: string, add_databases: bool, add_domains: bool, add_firewalls: bool, add_images: bool, add_linodes: bool, add_longview: bool, add_nodebalancers: bool, add_stackscripts: bool, add_volumes: bool, cancel_account: bool, longview_subscription: bool>, image: table<id: int, label: string, permissions: string>, linode: table<id: int, label: string, permissions: string>, longview: table<id: int, label: string, permissions: string>, nodebalancer: table<id: int, label: string, permissions: string>, stackscript: table<id: int, label: string, permissions: string>, volume: table<id: int, label: string, permissions: string>>
# operationId: getProfileGrants
export def "get-profile-grants" [
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
    path: "/profile/grants"
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Logins List
#
# GET /profile/logins
# Returns: record<data: table<datetime: string, id: int, ip: string, restricted: bool, username: string>, page: int, pages: int, results: int>
# operationId: getProfileLogins
export def "get-profile-logins" [
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
    path: "/profile/logins"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Login View
#
# GET /profile/logins/{loginId}
# Returns: record<datetime: string, id: int, ip: string, restricted: bool, username: string>
# operationId: getProfileLogin
export def "get-profile-login" [
  login_id: int
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
    path: "/profile/logins/{loginId}"
    path_params: [{name: loginId, var: login_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login_id: $login_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Phone Number Delete
#
# DELETE /profile/phone-number
# Returns: record
# operationId: deleteProfilePhoneNumber
export def "delete-profile-phone-number" [
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
    path: "/profile/phone-number"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Phone Number Verification Code Send
#
# POST /profile/phone-number
# Returns: record
# operationId: postProfilePhoneNumber
export def "post-profile-phone-number" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  iso_code: string # The two-letter ISO 3166 country code associated with the phone number. (e.g. US)
  phone_number: string # A valid phone number. (format: phone, e.g. 555-555-5555)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/profile/phone-number"
    body: {content_type: "application/json", kind: json, fields: [{name: iso_code, var: iso_code}, {name: phone_number, var: phone_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    iso_code: $iso_code, phone_number: $phone_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Phone Number Verify
#
# POST /profile/phone-number/verify
# Returns: record
# operationId: postProfilePhoneNumberVerify
export def "post-profile-phone-number-verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  otp_code: string # The one-time code received via SMS message after accessing the **Phone Verification Code Send** ([POST /profile/phone-number](/docs/api/profile/#phone-number-verification-code-send)) command. (e.g. US)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/profile/phone-number/verify"
    body: {content_type: "application/json", kind: json, fields: [{name: otp_code, var: otp_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    otp_code: $otp_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User Preferences View
#
# GET /profile/preferences
# Returns: record
# operationId: getUserPreferences
export def "get-user-preferences" [
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
    path: "/profile/preferences"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User Preferences Update
#
# PUT /profile/preferences
# Returns: record
# operationId: updateUserPreferences
export def "update-user-preferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/profile/preferences"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Security Questions List
#
# GET /profile/security-questions
# Returns: record<security_questions: table<id: int, question: string, response: string>>
# operationId: getSecurityQuestions
export def "get-security-questions" [
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
    path: "/profile/security-questions"
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.linode.com/v4"
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Security Questions Answer
#
# POST /profile/security-questions
# Returns: record<security_questions: table<question_id: int, response: string, security_question: string>>
# operationId: postSecurityQuestions
export def "post-security-questions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --security-questions: list # item shape: {question_id?: int, response?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/profile/security-questions"
    body: {content_type: "application/json", kind: json, fields: [{name: security_questions, var: security_questions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    security_questions: $security_questions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SSH Keys List
#
# GET /profile/sshkeys
# Returns: record<data: table<created: string, id: int, label: string, ssh_key: string>, page: int, pages: int, results: int>
# operationId: getSSHKeys
export def "get-ssh-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/profile/sshkeys"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SSH Key Add
#
# POST /profile/sshkeys
# Returns: record<created: string, id: int, label: string, ssh_key: string>
# operationId: addSSHKey
export def "add-ssh-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # A label for the SSH Key. (e.g. My SSH Key)
  --ssh-key: string # The public SSH Key, which is used to authenticate to the root user of the Linodes you deploy. Accepted formats: * ssh-dss * ssh-rsa * ecdsa-sha2-nistp * ssh-ed25519 * sk-ecdsa-sha2-nistp256 (Akamai-specific) (format: ssh-key, e.g. ssh-rsa AAAA_valid_public_ssh_key_123456785== user@their-computer)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/profile/sshkeys"
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}, {name: ssh_key, var: ssh_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    label: $label, ssh_key: $ssh_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SSH Key Delete
#
# DELETE /profile/sshkeys/{sshKeyId}
# Returns: record
# operationId: deleteSSHKey
export def "delete-ssh-key" [
  ssh_key_id: int
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
    path: "/profile/sshkeys/{sshKeyId}"
    path_params: [{name: sshKeyId, var: ssh_key_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ssh_key_id: $ssh_key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SSH Key View
#
# GET /profile/sshkeys/{sshKeyId}
# Returns: record<created: string, id: int, label: string, ssh_key: string>
# operationId: getSSHKey
export def "get-ssh-key" [
  ssh_key_id: int
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
    path: "/profile/sshkeys/{sshKeyId}"
    path_params: [{name: sshKeyId, var: ssh_key_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ssh_key_id: $ssh_key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SSH Key Update
#
# PUT /profile/sshkeys/{sshKeyId}
# Returns: record<created: string, id: int, label: string, ssh_key: string>
# operationId: updateSSHKey
export def "update-ssh-key" [
  ssh_key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # A label for the SSH Key. (e.g. My SSH Key)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/profile/sshkeys/{sshKeyId}"
    path_params: [{name: sshKeyId, var: ssh_key_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ssh_key_id: $ssh_key_id, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Two Factor Authentication Disable
#
# POST /profile/tfa-disable
# Returns: record
# operationId: tfaDisable
export def "tfa-disable" [
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
    method: post
    path: "/profile/tfa-disable"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Two Factor Secret Create
#
# POST /profile/tfa-enable
# Returns: record<expiry: string, secret: string>
# operationId: tfaEnable
export def "tfa-enable" [
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
    method: post
    path: "/profile/tfa-enable"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Two Factor Authentication Confirm/Enable
#
# POST /profile/tfa-enable-confirm
# Returns: record<scratch: string>
# operationId: tfaConfirm
export def "tfa-confirm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tfa-code: string # The Two Factor code you generated with your Two Factor secret. These codes are time-based, so be sure it is current. (e.g. 213456)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/profile/tfa-enable-confirm"
    body: {content_type: "application/json", kind: json, fields: [{name: tfa_code, var: tfa_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tfa_code: $tfa_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Personal Access Tokens List
#
# GET /profile/tokens
# Returns: record<data: table<created: string, expiry: string, id: int, label: string, scopes: string, token: string>, page: int, pages: int, results: int>
# operationId: getPersonalAccessTokens
export def "get-personal-access-tokens" [
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
    path: "/profile/tokens"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Personal Access Token Create
#
# POST /profile/tokens
# Returns: record<created: string, expiry: string, id: int, label: string, scopes: string, token: string>
# operationId: createPersonalAccessToken
export def "create-personal-access-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry: string # When this token should be valid until. If omitted, the new token will be valid until it is manually revoked. (format: date-time)
  --label: string # This token's label. This is for display purposes only, but can be used to more easily track what you're using each token for. (e.g. linode-cli)
  --scopes: string # The scopes to create the token with. These cannot be changed after creation, and may not exceed the scopes of the acting token. If omitted, the new token will have the same scopes as the acting token. (format: oauth-scope, e.g. *)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/profile/tokens"
    body: {content_type: "application/json", kind: json, fields: [{name: expiry, var: expiry}, {name: label, var: label}, {name: scopes, var: scopes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expiry: $expiry, label: $label, scopes: $scopes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Personal Access Token Revoke
#
# DELETE /profile/tokens/{tokenId}
# Returns: record
# operationId: deletePersonalAccessToken
export def "delete-personal-access-token" [
  token_id: int
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
    path: "/profile/tokens/{tokenId}"
    path_params: [{name: tokenId, var: token_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_id: $token_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Personal Access Token View
#
# GET /profile/tokens/{tokenId}
# Returns: record<created: string, expiry: string, id: int, label: string, scopes: string, token: string>
# operationId: getPersonalAccessToken
export def "get-personal-access-token" [
  token_id: int
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
    path: "/profile/tokens/{tokenId}"
    path_params: [{name: tokenId, var: token_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_id: $token_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Personal Access Token Update
#
# PUT /profile/tokens/{tokenId}
# Returns: record<created: string, expiry: string, id: int, label: string, scopes: string, token: string>
# operationId: updatePersonalAccessToken
export def "update-personal-access-token" [
  token_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # This token's label. This is for display purposes only, but can be used to more easily track what you're using each token for. (e.g. linode-cli)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/profile/tokens/{tokenId}"
    path_params: [{name: tokenId, var: token_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_id: $token_id, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Regions List
#
# GET /regions
# Returns: record<data: table<capabilities: list, country: string, id: string, label: string, resolvers: record, status: string>, page: int, pages: int, results: int>
# operationId: getRegions
export def "get-regions" [
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
    path: "/regions"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Region View
#
# GET /regions/{regionId}
# Returns: record<capabilities: list<string>, country: string, id: string, label: string, resolvers: record<ipv4: string, ipv6: string>, status: string>
# operationId: getRegion
export def "get-region" [
  region_id: string
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
    path: "/regions/{regionId}"
    path_params: [{name: regionId, var: region_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    region_id: $region_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Support Tickets List
#
# GET /support/tickets
# Returns: record<data: table<attachments: list, closable: bool, closed: string, description: string, entity: record, gravatar_id: string, id: int, opened: string, opened_by: string, status: string, summary: string, updated: string, updated_by: string>, page: int, pages: int, results: int>
# operationId: getTickets
export def "get-tickets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/support/tickets"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Support Ticket Open
#
# POST /support/tickets
# Returns: record<attachments: list<string>, closable: bool, closed: string, description: string, entity: record<id: int, label: string, type: string, url: string>, gravatar_id: string, id: int, opened: string, opened_by: string, status: string, summary: string, updated: string, updated_by: string>
# operationId: createTicket
export def "create-ticket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --database-id: int # The ID of the Managed Database this ticket is regarding, if relevant.
  description: string # The full details of the issue or question. (e.g. I'm having trouble setting the root password on my Linode. I tried following the instructions but something is not working and I'm not sure what I'm doing wrong. Can you please help me figure out how I can reset it? )
  --domain-id: int # The ID of the Domain this ticket is regarding, if relevant.
  --firewall-id: int # The ID of the Firewall this ticket is regarding, if relevant.
  --linode-id: int # The ID of the Linode this ticket is regarding, if relevant. (e.g. 123)
  --lkecluster-id: int # The ID of the Kubernetes cluster this ticket is regarding, if relevant. (e.g. 123)
  --longviewclient-id: int # The ID of the Longview client this ticket is regarding, if relevant.
  --managed-issue: oneof<nothing, bool> # Designates if this ticket is related to a [Managed service](https://www.linode.com/products/managed/). If `true`, the following constraints will apply: * No ID attributes (i.e. `linode_id`, `domain_id`, etc.) should be provided with this request. * Your account must have a [Managed service enabled](/docs/api/managed/#managed-service-enable). (e.g. false)
  --nodebalancer-id: int # The ID of the NodeBalancer this ticket is regarding, if relevant.
  --region: string # The [Region](/docs/api/regions/) ID for the associated VLAN this ticket is regarding. Only allowed when submitting a VLAN ticket.
  summary: string # The summary or title for this SupportTicket. (e.g. Having trouble resetting root password on my Linode )
  --vlan: string # The label of the VLAN this ticket is regarding, if relevant. To view your VLANs, use the VLANs List ([GET /networking/vlans](/docs/api/networking/#vlans-list)) endpoint. Requires a specified `region` to identify the VLAN.
  --volume-id: int # The ID of the Volume this ticket is regarding, if relevant.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/support/tickets"
    body: {content_type: "application/json", kind: json, fields: [{name: database_id, var: database_id}, {name: description, var: description}, {name: domain_id, var: domain_id}, {name: firewall_id, var: firewall_id}, {name: linode_id, var: linode_id}, {name: lkecluster_id, var: lkecluster_id}, {name: longviewclient_id, var: longviewclient_id}, {name: managed_issue, var: managed_issue}, {name: nodebalancer_id, var: nodebalancer_id}, {name: region, var: region}, {name: summary, var: summary}, {name: vlan, var: vlan}, {name: volume_id, var: volume_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    database_id: $database_id, description: $description, domain_id: $domain_id, firewall_id: $firewall_id, linode_id: $linode_id, lkecluster_id: $lkecluster_id, longviewclient_id: $longviewclient_id, managed_issue: $managed_issue, nodebalancer_id: $nodebalancer_id, region: $region, summary: $summary, vlan: $vlan, volume_id: $volume_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Support Ticket View
#
# GET /support/tickets/{ticketId}
# Returns: record<attachments: list<string>, closable: bool, closed: string, description: string, entity: record<id: int, label: string, type: string, url: string>, gravatar_id: string, id: int, opened: string, opened_by: string, status: string, summary: string, updated: string, updated_by: string>
# operationId: getTicket
export def "get-ticket" [
  ticket_id: int
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
    path: "/support/tickets/{ticketId}"
    path_params: [{name: ticketId, var: ticket_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ticket_id: $ticket_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Support Ticket Attachment Create
#
# POST /support/tickets/{ticketId}/attachments
# Returns: record
# operationId: createTicketAttachment
export def "create-ticket-attachment" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # The local, absolute path to the file you want to attach to your Support Ticket. (e.g. /Users/LinodeGuy/pictures/screen_shot.jpg)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/support/tickets/{ticketId}/attachments"
    path_params: [{name: ticketId, var: ticket_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ticket_id: $ticket_id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Support Ticket Close
#
# POST /support/tickets/{ticketId}/close
# Returns: record
# operationId: closeTicket
export def "close-ticket" [
  ticket_id: int
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
    method: post
    path: "/support/tickets/{ticketId}/close"
    path_params: [{name: ticketId, var: ticket_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ticket_id: $ticket_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replies List
#
# GET /support/tickets/{ticketId}/replies
# Returns: record<data: table<created: string, created_by: string, description: string, from_linode: bool, gravatar_id: string, id: int>, page: int, pages: int, results: int>
# operationId: getTicketReplies
export def "get-ticket-replies" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/support/tickets/{ticketId}/replies"
    path_params: [{name: ticketId, var: ticket_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ticket_id: $ticket_id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reply Create
#
# POST /support/tickets/{ticketId}/replies
# Returns: record<created: string, created_by: string, description: string, from_linode: bool, gravatar_id: string, id: int>
# operationId: createTicketReply
export def "create-ticket-reply" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # The content of your reply. (e.g. Thank you for your help. I was able to figure out what the problem was and I successfully reset my password. You guys are the best! )
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/support/tickets/{ticketId}/replies"
    path_params: [{name: ticketId, var: ticket_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ticket_id: $ticket_id, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tags List
#
# GET /tags
# Returns: record<data: table<label: string>, page: int, pages: int, results: int>
# operationId: getTags
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
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tags"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# New Tag Create
#
# POST /tags
# Returns: record<label: string>
# operationId: createTag
export def "create-tag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domains: list<int> # A list of Domain IDs to apply the new Tag to. You must be allowed to `read_write` all of the requested Domains, or the Tag will not be created and an error will be returned. (e.g. [564, 565])
  label: string # The new Tag. (e.g. example tag)
  --linodes: list<int> # A list of Linode IDs to apply the new Tag to. You must be allowed to `read_write` all of the requested Linodes, or the Tag will not be created and an error will be returned. (e.g. [123, 456])
  --nodebalancers: list<int> # A list of NodeBalancer IDs to apply the new Tag to. You must be allowed to `read_write` all of the requested NodeBalancers, or the Tag will not be created and an error will be returned. (e.g. [10301, 10501])
  --volumes: list<int> # A list of Volume IDs to apply the new Tag to. You must be allowed to `read_write` all of the requested Volumes, or the Tag will not be created and an error will be returned. (e.g. [9082, 10003])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags"
    body: {content_type: "application/json", kind: json, fields: [{name: domains, var: domains}, {name: label, var: label}, {name: linodes, var: linodes}, {name: nodebalancers, var: nodebalancers}, {name: volumes, var: volumes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domains: $domains, label: $label, linodes: $linodes, nodebalancers: $nodebalancers, volumes: $volumes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tag Delete
#
# DELETE /tags/{label}
# Returns: record
# operationId: deleteTag
export def "delete-tag" [
  label: string
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
    path: "/tags/{label}"
    path_params: [{name: label, var: label}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tagged Objects List
#
# GET /tags/{label}
# Returns: record<data: table<data: any, type: string>, page: int, pages: int, results: int>
# operationId: getTaggedObjects
export def "get-tagged-objects" [
  label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tags/{label}"
    path_params: [{name: label, var: label}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    label: $label, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Volumes List
#
# GET /volumes
# Returns: record<data: table<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: string, size: int, status: string, tags: list, updated: string>, page: int, pages: int, results: int>
# operationId: getVolumes
export def "get-volumes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/volumes"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Volume Create
#
# POST /volumes
# Returns: record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: string, size: int, status: string, tags: list<string>, updated: string>
# operationId: createVolume
export def "create-volume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-id: int # When creating a Volume attached to a Linode, the ID of the Linode Config to include the new Volume in. This Config must belong to the Linode referenced by `linode_id`. Must _not_ be provided if `linode_id` is not sent. If a `linode_id` is sent without a `config_id`, the volume will be attached: * to the Linode's only config if it only has one config. * to the Linode's last used config, if possible. If no config can be selected for attachment, an error will be returned. (e.g. 23456)
  label: string # The Volume's label, which is also used in the `filesystem_path` of the resulting volume. (e.g. my-volume)
  --linode-id: int # The Linode this volume should be attached to upon creation. If not given, the volume will be created without an attachment. (e.g. 123)
  --region: string # The Region to deploy this Volume in. This is only required if a linode_id is not given.
  --size: int # The initial size of this volume, in GB. Be aware that volumes may only be resized up after creation. (default: 20, e.g. 20)
  --tags: list<string> # An array of Tags applied to this object. Tags are for organizational purposes only. (e.g. [example tag, another example])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/volumes"
    body: {content_type: "application/json", kind: json, fields: [{name: config_id, var: config_id}, {name: label, var: label}, {name: linode_id, var: linode_id}, {name: region, var: region}, {name: size, var: size}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    config_id: $config_id, label: $label, linode_id: $linode_id, region: $region, size: $size, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Volume Delete
#
# DELETE /volumes/{volumeId}
# Returns: record
# operationId: deleteVolume
export def "delete-volume" [
  volume_id: int
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
    path: "/volumes/{volumeId}"
    path_params: [{name: volumeId, var: volume_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_id: $volume_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Volume View
#
# GET /volumes/{volumeId}
# Returns: record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: string, size: int, status: string, tags: list<string>, updated: string>
# operationId: getVolume
export def "get-volume" [
  volume_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/volumes/{volumeId}"
    path_params: [{name: volumeId, var: volume_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_id: $volume_id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Volume Update
#
# PUT /volumes/{volumeId}
# Returns: record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: string, size: int, status: string, tags: list<string>, updated: string>
# operationId: updateVolume
export def "update-volume" [
  volume_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # The Volume's label is for display purposes only. (e.g. my-volume)
  --tags: list<string> # An array of Tags applied to this object. Tags are for organizational purposes only. (e.g. [example tag, another example])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/volumes/{volumeId}"
    path_params: [{name: volumeId, var: volume_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_id: $volume_id, label: $label, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Volume Attach
#
# POST /volumes/{volumeId}/attach
# Returns: record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: string, size: int, status: string, tags: list<string>, updated: string>
# operationId: attachVolume
export def "attach-volume" [
  volume_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-id: int # The ID of the Linode Config to include this Volume in. Must belong to the Linode referenced by `linode_id`. If not given, the last booted Config will be chosen. (e.g. 23456)
  linode_id: int # The ID of the Linode to attach the volume to.
  --persist-across-boots: oneof<nothing, bool> # Defaults to true, if false is provided, the Volume will not be attached to the Linode Config. In this case more than 8 Volumes may be attached to a Linode if a Linode has 16GB of RAM or more. The number of volumes that can be attached is equal to the number of GB of RAM that the Linode has, up to a maximum of 64. `config_id` should not be passed if this is set to false and linode_id must be passed. The Linode must be running.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/volumes/{volumeId}/attach"
    path_params: [{name: volumeId, var: volume_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config_id, var: config_id}, {name: linode_id, var: linode_id}, {name: persist_across_boots, var: persist_across_boots}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_id: $volume_id, config_id: $config_id, linode_id: $linode_id, persist_across_boots: $persist_across_boots
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Volume Clone
#
# POST /volumes/{volumeId}/clone
# Returns: record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: string, size: int, status: string, tags: list<string>, updated: string>
# operationId: cloneVolume
export def "clone-volume" [
  volume_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string # The Volume's label is for display purposes only. (e.g. my-volume)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/volumes/{volumeId}/clone"
    path_params: [{name: volumeId, var: volume_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_id: $volume_id, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Volume Detach
#
# POST /volumes/{volumeId}/detach
# Returns: record
# operationId: detachVolume
export def "detach-volume" [
  volume_id: int
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
    method: post
    path: "/volumes/{volumeId}/detach"
    path_params: [{name: volumeId, var: volume_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_id: $volume_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Volume Resize
#
# POST /volumes/{volumeId}/resize
# Returns: record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: string, size: int, status: string, tags: list<string>, updated: string>
# operationId: resizeVolume
export def "resize-volume" [
  volume_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  size: int # The Volume's size, in GiB. (e.g. 30)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/volumes/{volumeId}/resize"
    path_params: [{name: volumeId, var: volume_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: size, var: size}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_id: $volume_id, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
