# Auto-generated client for Slicebox API v2.0
# Source: https://api.apis.guru/v2/specs/slicebox.local/2.0/swagger.json
# Auth: --token flag or $env.SLICEBOX_API_TOKEN

const CLIENT = {
  base_url: "http://slicebox.local/api"
  token_env_var: "SLICEBOX_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: []
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

def base-url-completer [] { ["http://slicebox.local/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/octet-stream"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    post-anonymization-anonymize: "table<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>"
    get-anonymization-keys: "table<anonPatientID: string, anonPatientName: string, anonSOPInstanceUID: string, anonSeriesInstanceUID: string, anonStudyInstanceUID: string, created: int, id: int, imageId: int, patientID: string, patientName: string, seriesInstanceUID: string, sopInstanceUID: string, studyInstanceUID: string>"
    get-anonymization-keys-export-csv: "string"
    post-anonymization-keys-query: "table<anonPatientID: string, anonPatientName: string, anonSOPInstanceUID: string, anonSeriesInstanceUID: string, anonStudyInstanceUID: string, created: int, id: int, imageId: int, patientID: string, patientName: string, seriesInstanceUID: string, sopInstanceUID: string, studyInstanceUID: string>"
    get-anonymization-keys-id: "record<anonPatientID: string, anonPatientName: string, anonSOPInstanceUID: string, anonSeriesInstanceUID: string, anonStudyInstanceUID: string, created: int, id: int, imageId: int, patientID: string, patientName: string, seriesInstanceUID: string, sopInstanceUID: string, studyInstanceUID: string>"
    get-anonymization-keys-id-keyvalues: "table<anonymizationKeyId: int, anonymizedValue: string, id: int, tagPath: record<previous: record, tag: int>, value: string>"
    get-anonymization-options: "table<description: string, name: string, rank: int, title: string>"
    get-boxes: "table<baseUrl: string, id: int, name: string, online: bool, profile: record<options: list>, sendMethod: string, token: string>"
    post-boxes-connect: "record<baseUrl: string, id: int, name: string, online: bool, profile: record<options: list<record>>, sendMethod: string, token: string>"
    post-boxes-createconnection: "record<baseUrl: string, id: int, name: string, online: bool, profile: record<options: list<record>>, sendMethod: string, token: string>"
    get-boxes-incoming: "table<boxId: int, boxName: string, id: int, outgoingTransactionId: int, receivedImageCount: int, status: string, totalImageCount: int, updated: int>"
    get-boxes-incoming-id-images: "table<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>"
    get-boxes-outgoing: "table<boxId: int, boxName: string, id: int, profile: record<options: list>, sentImageCount: int, status: string, totalImageCount: int, updated: int>"
    get-boxes-outgoing-id-images: "table<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>"
    get-destinations: "table<destinationId: int, destinationName: string, destinationType: string>"
    get-directorywatches: "table<id: int, path: string>"
    post-directorywatches: "record<id: int, path: string>"
    get-filtering-associations: "table<id: int, sourceId: int, sourceType: string, tagFilterId: int>"
    get-filtering-filters: "table<id: int, name: string, tagFilterType: string, tags: list<record>>"
    get-filtering-filters-id-tagpaths: "table<previous: record<item: string, previous: any, tag: int>, tag: int>"
    get-forwarding-rules: "table<destination: record<destinationId: int, destinationName: string, destinationType: string>, id: int, keepImages: bool, source: record<sourceId: int, sourceName: string, sourceType: string>>"
    post-forwarding-rules: "record<destination: record<destinationId: int, destinationName: string, destinationType: string>, id: int, keepImages: bool, source: record<sourceId: int, sourceName: string, sourceType: string>>"
    post-images: "record<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>"
    post-images-export: "record<value: int>"
    post-images-jpeg: "record<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>"
    put-images-id-anonymize: "record<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>"
    get-images-id-attributes: "table<depth: int, element: string, group: string, length: int, multiplicity: int, name: string, path: string, value: string, vr: string>"
    get-images-id-imageinformation: "record<frameIndex: int, maximumPixelValue: int, minimumPixelValue: int, numberOfFrames: int>"
    get-import-sessions: "table<created: int, filesAdded: int, filesImported: int, filesRejected: int, id: int, lastUpdated: int, name: string, user: string, userId: int>"
    post-import-sessions: "record<created: int, filesAdded: int, filesImported: int, filesRejected: int, id: int, lastUpdated: int, name: string, user: string, userId: int>"
    get-import-sessions-id: "record<created: int, filesAdded: int, filesImported: int, filesRejected: int, id: int, lastUpdated: int, name: string, user: string, userId: int>"
    get-import-sessions-id-images: "table<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>"
    post-import-sessions-id-images: "record<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>"
    get-log: "table<created: int, entryType: string, id: int, message: string, subject: string>"
    get-metadata-flatseries: "table<id: int, patient: record<id: int, patientBirthDate: record, patientID: record, patientName: record, patientSex: record>, series: record<bodyPartExamined: record, frameOfReferenceUID: record, id: int, manufacturer: record, modality: record, protocolName: record, seriesDate: record, seriesDescription: record, seriesInstanceUID: record, stationName: record, studyId: int>, study: record<accessionNumber: record, id: int, patientAge: record, patientId: int, studyDate: record, studyDescription: record, studyID: record, studyInstanceUID: record>>"
    post-metadata-flatseries-query: "table<id: int, patient: record<id: int, patientBirthDate: record, patientID: record, patientName: record, patientSex: record>, series: record<bodyPartExamined: record, frameOfReferenceUID: record, id: int, manufacturer: record, modality: record, protocolName: record, seriesDate: record, seriesDescription: record, seriesInstanceUID: record, stationName: record, studyId: int>, study: record<accessionNumber: record, id: int, patientAge: record, patientId: int, studyDate: record, studyDescription: record, studyID: record, studyInstanceUID: record>>"
    get-metadata-flatseries-id: "record<id: int, patient: record<id: int, patientBirthDate: record<value: string>, patientID: record<value: string>, patientName: record<value: string>, patientSex: record<value: string>>, series: record<bodyPartExamined: record<value: string>, frameOfReferenceUID: record<value: string>, id: int, manufacturer: record<value: string>, modality: record<value: string>, protocolName: record<value: string>, seriesDate: record<value: string>, seriesDescription: record<value: string>, seriesInstanceUID: record<value: string>, stationName: record<value: string>, studyId: int>, study: record<accessionNumber: record<value: string>, id: int, patientAge: record<value: string>, patientId: int, studyDate: record<value: string>, studyDescription: record<value: string>, studyID: record<value: string>, studyInstanceUID: record<value: string>>>"
    get-metadata-images: "table<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>"
    post-metadata-images-query: "table<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>"
    get-metadata-images-id: "record<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>"
    get-metadata-patients: "table<id: int, patientBirthDate: record<value: string>, patientID: record<value: string>, patientName: record<value: string>, patientSex: record<value: string>>"
    post-metadata-patients-query: "table<id: int, patientBirthDate: record<value: string>, patientID: record<value: string>, patientName: record<value: string>, patientSex: record<value: string>>"
    get-metadata-patients-id: "record<id: int, patientBirthDate: record<value: string>, patientID: record<value: string>, patientName: record<value: string>, patientSex: record<value: string>>"
    get-metadata-patients-id-images: "table<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>"
    get-metadata-series: "table<bodyPartExamined: record<value: string>, frameOfReferenceUID: record<value: string>, id: int, manufacturer: record<value: string>, modality: record<value: string>, protocolName: record<value: string>, seriesDate: record<value: string>, seriesDescription: record<value: string>, seriesInstanceUID: record<value: string>, stationName: record<value: string>, studyId: int>"
    post-metadata-series-query: "table<bodyPartExamined: record<value: string>, frameOfReferenceUID: record<value: string>, id: int, manufacturer: record<value: string>, modality: record<value: string>, protocolName: record<value: string>, seriesDate: record<value: string>, seriesDescription: record<value: string>, seriesInstanceUID: record<value: string>, stationName: record<value: string>, studyId: int>"
    get-metadata-series-id: "record<bodyPartExamined: record<value: string>, frameOfReferenceUID: record<value: string>, id: int, manufacturer: record<value: string>, modality: record<value: string>, protocolName: record<value: string>, seriesDate: record<value: string>, seriesDescription: record<value: string>, seriesInstanceUID: record<value: string>, stationName: record<value: string>, studyId: int>"
    get-metadata-series-id-seriestags: "table<id: int, name: string>"
    post-metadata-series-id-seriestags: "record<id: int, name: string>"
    get-metadata-series-id-seriestypes: "table<id: int, name: string>"
    get-metadata-series-id-source: "record<sourceId: int, sourceName: string, sourceType: string>"
    get-metadata-seriestags: "table<id: int, name: string>"
    get-metadata-studies: "table<accessionNumber: record<value: string>, id: int, patientAge: record<value: string>, patientId: int, studyDate: record<value: string>, studyDescription: record<value: string>, studyID: record<value: string>, studyInstanceUID: record<value: string>>"
    post-metadata-studies-query: "table<accessionNumber: record<value: string>, id: int, patientAge: record<value: string>, patientId: int, studyDate: record<value: string>, studyDescription: record<value: string>, studyID: record<value: string>, studyInstanceUID: record<value: string>>"
    get-metadata-studies-id: "record<accessionNumber: record<value: string>, id: int, patientAge: record<value: string>, patientId: int, studyDate: record<value: string>, studyDescription: record<value: string>, studyID: record<value: string>, studyInstanceUID: record<value: string>>"
    get-metadata-studies-id-images: "table<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>"
    get-scps: "table<aeTitle: string, id: int, name: string, port: int>"
    post-scps: "record<aeTitle: string, id: int, name: string, port: int>"
    get-scus: "table<aeTitle: string, host: string, id: int, name: string, port: int>"
    post-scus: "record<aeTitle: string, host: string, id: int, name: string, port: int>"
    get-seriestypes: "table<id: int, name: string>"
    post-seriestypes: "record<id: int, name: string>"
    get-seriestypes-rules: "table<id: int, seriesTypeId: int>"
    post-seriestypes-rules: "record<id: int, seriesTypeId: int>"
    get-seriestypes-rules-updatestatus: "record<running: bool>"
    get-seriestypes-rules-id-attributes: "table<element: int, group: int, id: int, path: string, seriesTypeRuleId: int, value: string>"
    post-seriestypes-rules-id-attributes: "record<element: int, group: int, id: int, path: string, seriesTypeRuleId: int, value: string>"
    post-seriestypes-series-query: "record<seriesidseriestypes: table<seriesid: int, seriestype: record>>"
    get-sources: "table<sourceId: int, sourceName: string, sourceType: string>"
    get-transactions-token-outgoing-poll: "table<image: record<id: int, imageId: int, outgoingTransactionId: int, sent: bool, sequenceNumber: int>, transaction: record<boxId: int, boxName: string, id: int, profile: record, sentImageCount: int, status: string, totalImageCount: int, updated: int>>"
    get-users: "table<hashedPassword: string, id: int, role: string, user: string>"
    post-users: "record<hashedPassword: string, id: int, role: string, user: string>"
    get-users-current: "record<id: int, role: string, user: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-anonymization-anonymize" "get-anonymization-keys" "get-anonymization-keys-export-csv" "post-anonymization-keys-query" "delete-anonymization-keys-id" "get-anonymization-keys-id" "get-anonymization-keys-id-keyvalues" "get-anonymization-options" "get-boxes" "post-boxes-connect" "post-boxes-createconnection" "get-boxes-incoming" "delete-boxes-incoming-id" "get-boxes-incoming-id-images" "get-boxes-outgoing" "delete-boxes-outgoing-id" "get-boxes-outgoing-id-images" "delete-boxes-id" "post-boxes-id-send" "get-destinations" "get-directorywatches" "post-directorywatches" "delete-directorywatches-id" "get-filtering-associations" "post-filtering-associations" "delete-filtering-associations-id" "get-filtering-filters" "post-filtering-filters" "delete-filtering-filters-id" "get-filtering-filters-id-tagpaths" "post-filtering-filters-id-tagpaths" "delete-filtering-filters-id-tagpaths-tagpathid" "delete-forwarding-rule-id" "get-forwarding-rules" "post-forwarding-rules" "post-images" "post-images-delete" "get-images-export" "post-images-export" "post-images-jpeg" "delete-images-id" "get-images-id" "put-images-id-anonymize" "post-images-id-anonymized" "get-images-id-attributes" "get-images-id-imageinformation" "put-images-id-modify" "get-images-id-png" "get-import-sessions" "post-import-sessions" "delete-import-sessions-id" "get-import-sessions-id" "get-import-sessions-id-images" "post-import-sessions-id-images" "delete-log" "get-log" "delete-log-id" "get-metadata-flatseries" "post-metadata-flatseries-query" "get-metadata-flatseries-id" "get-metadata-images" "post-metadata-images-query" "get-metadata-images-id" "get-metadata-patients" "post-metadata-patients-query" "get-metadata-patients-id" "get-metadata-patients-id-images" "get-metadata-series" "post-metadata-series-query" "get-metadata-series-id" "get-metadata-series-id-seriestags" "post-metadata-series-id-seriestags" "delete-metadata-series-id-seriestypes" "get-metadata-series-id-seriestypes" "get-metadata-series-id-source" "delete-metadata-series-series-id-seriestags-series-tag-id" "delete-metadata-series-series-id-seriestypes-series-type-id" "put-metadata-series-series-id-seriestypes-series-type-id" "get-metadata-seriestags" "get-metadata-studies" "post-metadata-studies-query" "get-metadata-studies-id" "get-metadata-studies-id-images" "get-scps" "post-scps" "delete-scps-id" "get-scus" "post-scus" "delete-scus-id" "post-scus-id-send" "get-seriestypes" "post-seriestypes" "get-seriestypes-rules" "post-seriestypes-rules" "get-seriestypes-rules-updatestatus" "delete-seriestypes-rules-id" "get-seriestypes-rules-id-attributes" "post-seriestypes-rules-id-attributes" "delete-seriestypes-rules-rule-id-attributes-attribute-id" "post-seriestypes-series-query" "delete-seriestypes-id" "put-seriestypes-id" "get-sources" "get-system-health" "post-system-stop" "post-transactions-token-image" "get-transactions-token-outgoing" "post-transactions-token-outgoing-done" "post-transactions-token-outgoing-failed" "get-transactions-token-outgoing-poll" "get-transactions-token-status" "put-transactions-token-status" "get-users" "post-users" "get-users-current" "post-users-login" "post-users-logout" "delete-users-id" "commands"] | sort) } | get name | first)
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

# anonymize the images corresponding to the supplied list of image IDs (each paired with a list of DICOM tag translation). This route corresponds to repeated use of the route /images/{id}/anonymize.
#
# POST /anonymization/anonymize
# Returns: table<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>
export def "post-anonymization-anonymize" [
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
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/anonymization/anonymize"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get a list of anonymization keys, each specifying how vital DICOM attributes have been anonymized for a particular image
#
# GET /anonymization/keys
# Returns: table<anonPatientID: string, anonPatientName: string, anonSOPInstanceUID: string, anonSeriesInstanceUID: string, anonStudyInstanceUID: string, created: int, id: int, imageId: int, patientID: string, patientName: string, seriesInstanceUID: string, sopInstanceUID: string, studyInstanceUID: string>
export def "get-anonymization-keys" [
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
  --startindex: int # start index of returned slice of anonymization keys (format: int64, default: 0)
  --count: int # size of returned slice of anonymization keys (format: int64, default: 20)
  --orderby: string # property to order results by
  --orderascending: oneof<nothing, bool> # order result ascendingly if true, descendingly otherwise (default: true)
  --filter: string # filter the results by matching substrings of properties against this value
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/anonymization/keys"
    query: [{name: startindex, var: startindex}, {name: count, var: count}, {name: orderby, var: orderby}, {name: orderascending, var: orderascending}, {name: filter, var: filter}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count, orderby: $orderby, orderascending: $orderascending, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# export all anonymization keys as a csv file
#
# GET /anonymization/keys/export/csv
# Returns: string
export def "get-anonymization-keys-export-csv" [
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
    path: "/anonymization/keys/export/csv"
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# submit a query for anonymization keys
#
# POST /anonymization/keys/query
# Returns: table<anonPatientID: string, anonPatientName: string, anonSOPInstanceUID: string, anonSeriesInstanceUID: string, anonStudyInstanceUID: string, created: int, id: int, imageId: int, patientID: string, patientName: string, seriesInstanceUID: string, sopInstanceUID: string, studyInstanceUID: string>
export def "post-anonymization-keys-query" [
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
  count: int # format: int64
  --order: record # shape: {orderAscending?: bool, orderBy?: string}
  query_properties: list # item shape: {operator?: string, propertyName?: string, propertyValue?: string}
  start_index: int # format: int64
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/anonymization/keys/query"
    body: {content_type: "application/json", kind: json, fields: [{name: count, var: count}, {name: order, var: order}, {name: queryProperties, var: query_properties}, {name: startIndex, var: start_index}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    count: $count, order: $order, query_properties: $query_properties, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# delete an anonymization key that is no longer of interest
#
# DELETE /anonymization/keys/{id}
export def "delete-anonymization-keys-id" [
  id: int
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
    method: delete
    path: "/anonymization/keys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get the anonymization key with the supplied ID
#
# GET /anonymization/keys/{id}
# Returns: record<anonPatientID: string, anonPatientName: string, anonSOPInstanceUID: string, anonSeriesInstanceUID: string, anonStudyInstanceUID: string, created: int, id: int, imageId: int, patientID: string, patientName: string, seriesInstanceUID: string, sopInstanceUID: string, studyInstanceUID: string>
export def "get-anonymization-keys-id" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/anonymization/keys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get pointers to the images corresponding to the anonymization key with the supplied ID
#
# GET /anonymization/keys/{id}/keyvalues
# Returns: table<anonymizationKeyId: int, anonymizedValue: string, id: int, tagPath: record<previous: record, tag: int>, value: string>
export def "get-anonymization-keys-id-keyvalues" [
  id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/anonymization/keys/{id}/keyvalues"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# list all supported anonymization options defining an anonymization profile
#
# GET /anonymization/options
# Returns: table<description: string, name: string, rank: int, title: string>
export def "get-anonymization-options" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/anonymization/options"
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get a list of box connections
#
# GET /boxes
# Returns: table<baseUrl: string, id: int, name: string, online: bool, profile: record<options: list>, sendMethod: string, token: string>
export def "get-boxes" [
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
  --startindex: int # start index of returned slice of boxes (format: int64, default: 0)
  --count: int # size of returned slice of boxes (format: int64, default: 20)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/boxes"
    query: [{name: startindex, var: startindex}, {name: count, var: count}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# connect to another box using a received URL. Used to connect to a public box.
#
# POST /boxes/connect
# Returns: record<baseUrl: string, id: int, name: string, online: bool, profile: record<options: list<record>>, sendMethod: string, token: string>
export def "post-boxes-connect" [
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
  --body-base-url: string # (spec name: baseUrl)
  --default-profile: record # shape: {options?: list}
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/boxes/connect"
    body: {content_type: "application/json", kind: json, fields: [{name: baseUrl, var: body_base_url}, {name: defaultProfile, var: default_profile}, {name: name, var: name}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    body_base_url: $body_base_url, default_profile: $default_profile, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# create a new box connection where the supplied entity holds the remote box name. Used by publicly available boxes.
#
# POST /boxes/createconnection
# Returns: record<baseUrl: string, id: int, name: string, online: bool, profile: record<options: list<record>>, sendMethod: string, token: string>
export def "post-boxes-createconnection" [
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
  --default-profile: record # shape: {options?: list}
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/boxes/createconnection"
    body: {content_type: "application/json", kind: json, fields: [{name: defaultProfile, var: default_profile}, {name: name, var: name}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    default_profile: $default_profile, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get incoming transactions (finished, currently receiving, waiting or failed)
#
# GET /boxes/incoming
# Returns: table<boxId: int, boxName: string, id: int, outgoingTransactionId: int, receivedImageCount: int, status: string, totalImageCount: int, updated: int>
export def "get-boxes-incoming" [
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
  --startindex: int # start index of returned slice of transactions (format: int64, default: 0)
  --count: int # size of returned slice of transactions (format: int64, default: 20)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/boxes/incoming"
    query: [{name: startindex, var: startindex}, {name: count, var: count}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# delete an incoming transaction. If a currently active transaction is deleted, a new transaction with the remainder of the images is created when receiving the next incoming image.
#
# DELETE /boxes/incoming/{id}
export def "delete-boxes-incoming-id" [
  id: int
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
    method: delete
    path: "/boxes/incoming/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get the received images corresponding to the incoming transaction with the supplied ID
#
# GET /boxes/incoming/{id}/images
# Returns: table<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>
export def "get-boxes-incoming-id-images" [
  id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/boxes/incoming/{id}/images"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get outgoing transactions (finished, currently sending, waiting or failed)
#
# GET /boxes/outgoing
# Returns: table<boxId: int, boxName: string, id: int, profile: record<options: list>, sentImageCount: int, status: string, totalImageCount: int, updated: int>
export def "get-boxes-outgoing" [
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
  --startindex: int # start index of returned slice of transactions (format: int64, default: 0)
  --count: int # size of returned slice of transactions (format: int64, default: 20)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/boxes/outgoing"
    query: [{name: startindex, var: startindex}, {name: count, var: count}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# delete an outgoing transaction. This will stop ongoing transactions.
#
# DELETE /boxes/outgoing/{id}
export def "delete-boxes-outgoing-id" [
  id: int
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
    method: delete
    path: "/boxes/outgoing/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get the sent images corresponding to the outgoing transaction with the supplied ID
#
# GET /boxes/outgoing/{id}/images
# Returns: table<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>
export def "get-boxes-outgoing-id-images" [
  id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/boxes/outgoing/{id}/images"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete the remote box with the supplied ID
#
# DELETE /boxes/{id}
export def "delete-boxes-id" [
  id: int
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
    method: delete
    path: "/boxes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# send images corresponding to the supplied image ids to the remote box with the supplied ID
#
# POST /boxes/{id}/send
export def "post-boxes-id-send" [
  id: int
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
  --image-tag-values-set: list # item shape: {imageId?: int, tagValues?: list}
  --profile: record # shape: {options?: list}
]: any -> any {
  $in | http-request {
    method: post
    path: "/boxes/{id}/send"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: imageTagValuesSet, var: image_tag_values_set}, {name: profile, var: profile}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    id: $id, image_tag_values_set: $image_tag_values_set, profile: $profile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of currently available destinations. Possible destinations are box - sending data to a remote box, and scu - sending data a receiving SCP.
#
# GET /destinations
# Returns: table<destinationId: int, destinationName: string, destinationType: string>
export def "get-destinations" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/destinations"
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get a list of watch directories. Each watch directory and its sub-directories are watched for incoming DICOM files, which are read and imported into slicebox.
#
# GET /directorywatches
# Returns: table<id: int, path: string>
export def "get-directorywatches" [
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
  --startindex: int # start index of returned slice of watched directories (format: int64, default: 0)
  --count: int # size of returned slice of watched directories (format: int64, default: 20)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/directorywatches"
    query: [{name: startindex, var: startindex}, {name: count, var: count}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# add a new directory to watch for incoming DICOM files
#
# POST /directorywatches
# Returns: record<id: int, path: string>
export def "post-directorywatches" [
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
  --id: int # format: int64
  --path: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/directorywatches"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: path, var: path}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    id: $id, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# stop watching and remove the directory corresponding to the supplied ID
#
# DELETE /directorywatches/{id}
export def "delete-directorywatches-id" [
  id: int
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
    method: delete
    path: "/directorywatches/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of source to filter associations.
#
# GET /filtering/associations
# Returns: table<id: int, sourceId: int, sourceType: string, tagFilterId: int>
export def "get-filtering-associations" [
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
  --startindex: int # start index of returned slice of source <-> filter associations (format: int64, default: 0)
  --count: int # size of returned slice of source <-> filter associations (format: int64, default: 20)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/filtering/associations"
    query: [{name: startindex, var: startindex}, {name: count, var: count}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Inserts or updates a source <-> filter associations. If the specified Source already has an association this is updated, otherwise a new is inserted.
#
# POST /filtering/associations
export def "post-filtering-associations" [
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
  --id: int # format: int64
  --source-id: int # format: int64
  --source-type: string
  --tag-filter-id: int # format: int64
]: any -> any {
  $in | http-request {
    method: post
    path: "/filtering/associations"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: sourceId, var: source_id}, {name: sourceType, var: source_type}, {name: tagFilterId, var: tag_filter_id}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    id: $id, source_id: $source_id, source_type: $source_type, tag_filter_id: $tag_filter_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# remove the source <-> filter association corresponding to the supplied ID
#
# DELETE /filtering/associations/{id}
export def "delete-filtering-associations-id" [
  id: int
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
    method: delete
    path: "/filtering/associations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List defined filters
#
# GET /filtering/filters
# Returns: table<id: int, name: string, tagFilterType: string, tags: list<record>>
export def "get-filtering-filters" [
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
  --startindex: int # start index of returned slice of filters (format: int64, default: 0)
  --count: int # size of returned slice of filters (format: int64, default: 20)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/filtering/filters"
    query: [{name: startindex, var: startindex}, {name: count, var: count}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Inserts or updates a filter. If a filter with same name as supplied filter exists this filter is updated, otherwise a new filter is inserted.
#
# POST /filtering/filters
export def "post-filtering-filters" [
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
  --id: int # format: int64
  --name: string
  --tag-filter-type: string
  --tags: list # item shape: {previous?: record, tag?: int}
]: any -> any {
  $in | http-request {
    method: post
    path: "/filtering/filters"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}, {name: tagFilterType, var: tag_filter_type}, {name: tags, var: tags}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    id: $id, name: $name, tag_filter_type: $tag_filter_type, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# remove the filter corresponding to the supplied ID
#
# DELETE /filtering/filters/{id}
export def "delete-filtering-filters-id" [
  id: int
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
    method: delete
    path: "/filtering/filters/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List tagpaths for the selected filter
#
# GET /filtering/filters/{id}/tagpaths
# Returns: table<previous: record<item: string, previous: any, tag: int>, tag: int>
export def "get-filtering-filters-id-tagpaths" [
  id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/filtering/filters/{id}/tagpaths"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# add a tagpath to a filter
#
# POST /filtering/filters/{id}/tagpaths
export def "post-filtering-filters-id-tagpaths" [
  id: int
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
  --previous: record # shape: {item?: string, previous?: record, tag?: int}
  --tag: int # format: int32
]: any -> any {
  $in | http-request {
    method: post
    path: "/filtering/filters/{id}/tagpaths"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: previous, var: previous}, {name: tag, var: tag}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    id: $id, previous: $previous, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# remove the tagpath corresponding to the supplied ID
#
# DELETE /filtering/filters/{id}/tagpaths/{tagpathid}
export def "delete-filtering-filters-id-tagpaths-tagpathid" [
  id: int
  tagpathid: int
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
    method: delete
    path: "/filtering/filters/{id}/tagpaths/{tagpathid}"
    path_params: [{name: id, var: id}, {name: tagpathid, var: tagpathid}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id, tagpathid: $tagpathid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# remove the forwarding rule corresponding to the supplied ID
#
# DELETE /forwarding/rule/{id}
export def "delete-forwarding-rule-id" [
  id: int
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
    method: delete
    path: "/forwarding/rule/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get a list of all forwarding rules. A forwarding rule specifies the automatic forwarding of images from a source (SCP, BOX, etc.) to a destimation (BOX, SCU, etc.)
#
# GET /forwarding/rules
# Returns: table<destination: record<destinationId: int, destinationName: string, destinationType: string>, id: int, keepImages: bool, source: record<sourceId: int, sourceName: string, sourceType: string>>
export def "get-forwarding-rules" [
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
  --startindex: int # start index of returned slice of rules (format: int64, default: 0)
  --count: int # size of returned slice of rules (format: int64, default: 20)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/forwarding/rules"
    query: [{name: startindex, var: startindex}, {name: count, var: count}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# add a new forwarding rule
#
# POST /forwarding/rules
# Returns: record<destination: record<destinationId: int, destinationName: string, destinationType: string>, id: int, keepImages: bool, source: record<sourceId: int, sourceName: string, sourceType: string>>
export def "post-forwarding-rules" [
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
  --destination: record # shape: {destinationId?: int, destinationName?: string, destinationType?: string}
  --id: int # format: int64
  --keep-images: oneof<nothing, bool>
  --source: record # shape: {sourceId?: int, sourceName?: string, sourceType?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/forwarding/rules"
    body: {content_type: "application/json", kind: json, fields: [{name: destination, var: destination}, {name: id, var: id}, {name: keepImages, var: keep_images}, {name: source, var: source}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    destination: $destination, id: $id, keep_images: $keep_images, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# add a DICOM dataset to slicebox
#
# POST /images
# Returns: record<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>
export def "post-images" [
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
  dataset: path # The dataset file
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/images"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: dataset, var: dataset}], files: [dataset]}
    accept: ["application/json", "application/octet-stream"]
    ok: [200, 201]
    auth: bearer
  } {
    dataset: $dataset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# bulk delete a sequence of images according to the supplied image IDs. This is the same as a sequence of DELETE requests to /images/{id}
#
# POST /images/delete
export def "post-images-delete" [
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
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/images/delete"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# download the export set with the supplied export set ID as a zip archive
#
# GET /images/export
export def "get-images-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # ID of export set to download (required, format: int64)
]: nothing -> any {
  http-request {
    method: get
    path: "/images/export"
    query: [{name: id, var: id, required: true}]
    accept: ["application/zip"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# create an export set, a group of image IDs of images to export. The export set will contain the selected images. The export set is available for download 12 hours before it is automatically deleted.
#
# POST /images/export
# Returns: record<value: int>
export def "post-images-export" [
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
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/images/export"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/octet-stream"]
    ok: [200, 201]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# add a JPEG image to slicebox. The image data will be wrapped in a DICOM file and added as a new series belonging to the study with the supplied ID
#
# POST /images/jpeg
# Returns: record<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>
export def "post-images-jpeg" [
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
  --studyid: int # ID of study to add new series to (required, format: int64)
  --description: string # DICOM series description of the resulting secondary capture series
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/images/jpeg"
    query: [{name: studyid, var: studyid, required: true}, {name: description, var: description}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    studyid: $studyid, description: $description, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete the image with the supplied ID
#
# DELETE /images/{id}
export def "delete-images-id" [
  id: int
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
    method: delete
    path: "/images/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# fetch dataset corresponding to the supplied image ID
#
# GET /images/{id}
export def "get-images-id" [
  id: int
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
    method: get
    path: "/images/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete the selected image and replace it with an anonymized version
#
# PUT /images/{id}/anonymize
# Returns: record<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>
export def "put-images-id-anonymize" [
  id: int
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
  --profile: record # shape: {options?: list}
  --tag-values: list # item shape: {tagPath?: record, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/images/{id}/anonymize"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: profile, var: profile}, {name: tagValues, var: tag_values}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, profile: $profile, tag_values: $tag_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get an anonymized version of the image with the supplied ID
#
# POST /images/{id}/anonymized
export def "post-images-id-anonymized" [
  id: int
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
  --profile: record # shape: {options?: list}
  --tag-values: list # item shape: {tagPath?: record, value?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/images/{id}/anonymized"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: profile, var: profile}, {name: tagValues, var: tag_values}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, profile: $profile, tag_values: $tag_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# list all DICOM attributes of the dataset corresponding to the supplied image ID
#
# GET /images/{id}/attributes
# Returns: table<depth: int, element: string, group: string, length: int, multiplicity: int, name: string, path: string, value: string, vr: string>
export def "get-images-id-attributes" [
  id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/images/{id}/attributes"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get basic information about the pixel data of an image
#
# GET /images/{id}/imageinformation
# Returns: record<frameIndex: int, maximumPixelValue: int, minimumPixelValue: int, numberOfFrames: int>
export def "get-images-id-imageinformation" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images/{id}/imageinformation"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# modify and/or insert image attributes according to the input tagpath-value mappings
#
# PUT /images/{id}/modify
export def "put-images-id-modify" [
  id: int
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
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/images/{id}/modify"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get a PNG image representation of the image corresponding to the supplied ID
#
# GET /images/{id}/png
export def "get-images-id-png" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --framenumber: int # frame/slice to show (format: int32, default: 1)
  --windowmin: int # intensity window minimum value. If not specified or set to zero, windowing will be selected from relevant DICOM attributes (format: int32, default: 0)
  --windowmax: int # intensity window maximum value. If not specified or set to zero, windowing will be selected from relevant DICOM attributes (format: int32, default: 0)
  --imageheight: int # height of PNG image. If not specified or set to zero, the image height will equal that of the data (format: int32, default: 0)
]: nothing -> any {
  http-request {
    method: get
    path: "/images/{id}/png"
    path_params: [{name: id, var: id}]
    query: [{name: framenumber, var: framenumber}, {name: windowmin, var: windowmin}, {name: windowmax, var: windowmax}, {name: imageheight, var: imageheight}]
    accept: ["image/png"]
    ok: [200]
    auth: bearer
  } {
    id: $id, framenumber: $framenumber, windowmin: $windowmin, windowmax: $windowmax, imageheight: $imageheight
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of available import sessions.
#
# GET /import/sessions
# Returns: table<created: int, filesAdded: int, filesImported: int, filesRejected: int, id: int, lastUpdated: int, name: string, user: string, userId: int>
export def "get-import-sessions" [
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
  --startindex: int # start index of returned slice of import sessions (format: int64, default: 0)
  --count: int # size of returned slice of import sessions (format: int64, default: 20)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/import/sessions"
    query: [{name: startindex, var: startindex}, {name: count, var: count}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# create a new import sessions
#
# POST /import/sessions
# Returns: record<created: int, filesAdded: int, filesImported: int, filesRejected: int, id: int, lastUpdated: int, name: string, user: string, userId: int>
export def "post-import-sessions" [
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
  --created: int # format: int64
  --files-added: int # format: int32
  --files-imported: int # format: int32
  --files-rejected: int # format: int32
  --id: int # format: int64
  --last-updated: int # format: int64
  --name: string
  --user: string
  --user-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/import/sessions"
    body: {content_type: "application/json", kind: json, fields: [{name: created, var: created}, {name: filesAdded, var: files_added}, {name: filesImported, var: files_imported}, {name: filesRejected, var: files_rejected}, {name: id, var: id}, {name: lastUpdated, var: last_updated}, {name: name, var: name}, {name: user, var: user}, {name: userId, var: user_id}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    created: $created, files_added: $files_added, files_imported: $files_imported, files_rejected: $files_rejected, id: $id, last_updated: $last_updated, name: $name, user: $user, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# deletes the import session with the supplied ID
#
# DELETE /import/sessions/{id}
export def "delete-import-sessions-id" [
  id: int
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
    method: delete
    path: "/import/sessions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns the import sessions with the supplied ID
#
# GET /import/sessions/{id}
# Returns: record<created: int, filesAdded: int, filesImported: int, filesRejected: int, id: int, lastUpdated: int, name: string, user: string, userId: int>
export def "get-import-sessions-id" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/import/sessions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get the imported images corresponding to the import session with the supplied ID
#
# GET /import/sessions/{id}/images
# Returns: table<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>
export def "get-import-sessions-id-images" [
  id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/import/sessions/{id}/images"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# add a DICOM dataset to the import session with the supplied ID
#
# POST /import/sessions/{id}/images
# Returns: record<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>
export def "post-import-sessions-id-images" [
  id: int
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
  dataset: path # The dataset file
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/import/sessions/{id}/images"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: dataset, var: dataset}], files: [dataset]}
    accept: ["application/json", "application/octet-stream"]
    ok: [200, 201]
    auth: bearer
  } {
    id: $id, dataset: $dataset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# delete all log messages
#
# DELETE /log
export def "delete-log" [
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
    method: delete
    path: "/log"
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get a list of slicebox log messages
#
# GET /log
# Returns: table<created: int, entryType: string, id: int, message: string, subject: string>
export def "get-log" [
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
  --startindex: int # start index of returned slice of log messages (format: int64, default: 0)
  --count: int # size of returned slice of log messages (format: int64, default: 20)
  --subject: string # log subject to filter results by
  --type: string # log type (DEFAULT, INFO, WARN, ERROR) to filter results by
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/log"
    query: [{name: startindex, var: startindex}, {name: count, var: count}, {name: subject, var: subject}, {name: type, var: type}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count, subject: $subject, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete the log entry with the supplied ID
#
# DELETE /log/{id}
export def "delete-log-id" [
  id: int
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
    method: delete
    path: "/log/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of flattened metadata on the patient, study and series levels
#
# GET /metadata/flatseries
# Returns: table<id: int, patient: record<id: int, patientBirthDate: record, patientID: record, patientName: record, patientSex: record>, series: record<bodyPartExamined: record, frameOfReferenceUID: record, id: int, manufacturer: record, modality: record, protocolName: record, seriesDate: record, seriesDescription: record, seriesInstanceUID: record, stationName: record, studyId: int>, study: record<accessionNumber: record, id: int, patientAge: record, patientId: int, studyDate: record, studyDescription: record, studyID: record, studyInstanceUID: record>>
export def "get-metadata-flatseries" [
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
  --startindex: int # start index of returned slice of flat series (format: int64, default: 0)
  --count: int # size of returned slice of flat series (format: int64, default: 20)
  --orderby: string # flat series property to order results by
  --orderascending: oneof<nothing, bool> # order result ascendingly if true, descendingly otherwise (default: true)
  --filter: string # filter the results by matching substrings of flat series properties against this value
  --sources: string # filter the results by matching on one or more series sources. Examples of sources are user, box, directory or scp. The list of sources to filter results by must have the form TYPE1:ID1,TYPE2:ID2,...,TYPEN:IDN. For instance, the argument sources=box:1,user:5 shows results either sent from (slice)box with id 1 or uploaded by user with id 5.
  --seriestypes: string # filter the results by matching on one or more series types. The supplied list of series types must be a comma separated list of series type ids. For instance, the argument seriestypes=3,7,22 shows series assigned to either of the series types with ids 3, 7 and 22.
  --seriestags: string # filter the results by matching on one or more series tags. The supplied list of series tags must be a comma separated list of series tag ids. For instance, the argument seriestags=6,2,11 shows series with either of the series tags with ids 6, 2 and 11.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/flatseries"
    query: [{name: startindex, var: startindex}, {name: count, var: count}, {name: orderby, var: orderby}, {name: orderascending, var: orderascending}, {name: filter, var: filter}, {name: sources, var: sources}, {name: seriestypes, var: seriestypes}, {name: seriestags, var: seriestags}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count, orderby: $orderby, orderascending: $orderascending, filter: $filter, sources: $sources, seriestypes: $seriestypes, seriestags: $seriestags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# submit a query for flat series
#
# POST /metadata/flatseries/query
# Returns: table<id: int, patient: record<id: int, patientBirthDate: record, patientID: record, patientName: record, patientSex: record>, series: record<bodyPartExamined: record, frameOfReferenceUID: record, id: int, manufacturer: record, modality: record, protocolName: record, seriesDate: record, seriesDescription: record, seriesInstanceUID: record, stationName: record, studyId: int>, study: record<accessionNumber: record, id: int, patientAge: record, patientId: int, studyDate: record, studyDescription: record, studyID: record, studyInstanceUID: record>>
export def "post-metadata-flatseries-query" [
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
  count: int # format: int64
  --filters: record # shape: {seriesTagIds?: list<int>, seriesTypeIds?: list<int>, sourceRefs?: list}
  --order: record # shape: {orderAscending?: bool, orderBy?: string}
  query_properties: list # item shape: {operator?: string, propertyName?: string, propertyValue?: string}
  start_index: int # format: int64
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata/flatseries/query"
    body: {content_type: "application/json", kind: json, fields: [{name: count, var: count}, {name: filters, var: filters}, {name: order, var: order}, {name: queryProperties, var: query_properties}, {name: startIndex, var: start_index}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    count: $count, filters: $filters, order: $order, query_properties: $query_properties, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return the flat series with the supplied ID
#
# GET /metadata/flatseries/{id}
# Returns: record<id: int, patient: record<id: int, patientBirthDate: record<value: string>, patientID: record<value: string>, patientName: record<value: string>, patientSex: record<value: string>>, series: record<bodyPartExamined: record<value: string>, frameOfReferenceUID: record<value: string>, id: int, manufacturer: record<value: string>, modality: record<value: string>, protocolName: record<value: string>, seriesDate: record<value: string>, seriesDescription: record<value: string>, seriesInstanceUID: record<value: string>, stationName: record<value: string>, studyId: int>, study: record<accessionNumber: record<value: string>, id: int, patientAge: record<value: string>, patientId: int, studyDate: record<value: string>, studyDescription: record<value: string>, studyID: record<value: string>, studyInstanceUID: record<value: string>>>
export def "get-metadata-flatseries-id" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/flatseries/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of metadata on the image level of the DICOM hierarchy
#
# GET /metadata/images
# Returns: table<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>
export def "get-metadata-images" [
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
  --startindex: int # start index of returned slice of images (format: int64, default: 0)
  --count: int # size of returned slice of images (format: int64, default: 20)
  --seriesid: int # reference to series to list images for (required, format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/images"
    query: [{name: startindex, var: startindex}, {name: count, var: count}, {name: seriesid, var: seriesid, required: true}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count, seriesid: $seriesid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# submit a query for images
#
# POST /metadata/images/query
# Returns: table<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>
export def "post-metadata-images-query" [
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
  count: int # format: int64
  --filters: record # shape: {seriesTagIds?: list<int>, seriesTypeIds?: list<int>, sourceRefs?: list}
  --order: record # shape: {orderAscending?: bool, orderBy?: string}
  query_properties: list # item shape: {operator?: string, propertyName?: string, propertyValue?: string}
  start_index: int # format: int64
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata/images/query"
    body: {content_type: "application/json", kind: json, fields: [{name: count, var: count}, {name: filters, var: filters}, {name: order, var: order}, {name: queryProperties, var: query_properties}, {name: startIndex, var: start_index}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    count: $count, filters: $filters, order: $order, query_properties: $query_properties, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return the image with the supplied ID
#
# GET /metadata/images/{id}
# Returns: record<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>
export def "get-metadata-images-id" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/images/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of metadata on the patient level of the DICOM hierarchy
#
# GET /metadata/patients
# Returns: table<id: int, patientBirthDate: record<value: string>, patientID: record<value: string>, patientName: record<value: string>, patientSex: record<value: string>>
export def "get-metadata-patients" [
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
  --startindex: int # start index of returned slice of patients (format: int64, default: 0)
  --count: int # size of returned slice of patients (format: int64, default: 20)
  --orderby: string # patient property to order results by
  --orderascending: oneof<nothing, bool> # order result ascendingly if true, descendingly otherwise (default: true)
  --filter: string # filter the results by matching substrings of patient properties against this value
  --sources: string # filter the results by matching on one or more underlying series sources. Examples of sources are user, box, directory or scp. The list of sources to filter results by must have the form TYPE1:ID1,TYPE2:ID2,...,TYPEN:IDN. For instance, the argument sources=box:1,user:5 shows results either sent from (slice)box with id 1 or uploaded by user with id 5.
  --seriestypes: string # filter the results by matching on one or more underlying series types. The supplied list of series types must be a comma separated list of series type ids. For instance, the argument seriestypes=3,7,22 shows results including series assigned to either of the series types with ids 3, 7 and 22.
  --seriestags: string # filter the results by matching on one or more underlying series tags. The supplied list of series tags must be a comma separated list of series tag ids. For instance, the argument seriestags=6,2,11 shows results including series with either of the series tags with ids 6, 2 and 11.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/patients"
    query: [{name: startindex, var: startindex}, {name: count, var: count}, {name: orderby, var: orderby}, {name: orderascending, var: orderascending}, {name: filter, var: filter}, {name: sources, var: sources}, {name: seriestypes, var: seriestypes}, {name: seriestags, var: seriestags}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count, orderby: $orderby, orderascending: $orderascending, filter: $filter, sources: $sources, seriestypes: $seriestypes, seriestags: $seriestags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# submit a query for patients
#
# POST /metadata/patients/query
# Returns: table<id: int, patientBirthDate: record<value: string>, patientID: record<value: string>, patientName: record<value: string>, patientSex: record<value: string>>
export def "post-metadata-patients-query" [
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
  count: int # format: int64
  --filters: record # shape: {seriesTagIds?: list<int>, seriesTypeIds?: list<int>, sourceRefs?: list}
  --order: record # shape: {orderAscending?: bool, orderBy?: string}
  query_properties: list # item shape: {operator?: string, propertyName?: string, propertyValue?: string}
  start_index: int # format: int64
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata/patients/query"
    body: {content_type: "application/json", kind: json, fields: [{name: count, var: count}, {name: filters, var: filters}, {name: order, var: order}, {name: queryProperties, var: query_properties}, {name: startIndex, var: start_index}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    count: $count, filters: $filters, order: $order, query_properties: $query_properties, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return the patient with the supplied ID
#
# GET /metadata/patients/{id}
# Returns: record<id: int, patientBirthDate: record<value: string>, patientID: record<value: string>, patientName: record<value: string>, patientSex: record<value: string>>
export def "get-metadata-patients-id" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/patients/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns all images for the patient with the supplied patient ID
#
# GET /metadata/patients/{id}/images
# Returns: table<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>
export def "get-metadata-patients-id-images" [
  id: int
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
  --sources: string # filter the results by matching on one or more series sources. Examples of sources are user, box, directory or scp. The list of sources to filter results by must have the form TYPE1:ID1,TYPE2:ID2,...,TYPEN:IDN. For instance, the argument sources=box:1,user:5 shows results either sent from (slice)box with id 1 or uploaded by user with id 5.
  --seriestypes: string # filter the results by matching on one or more series types. The supplied list of series types must be a comma separated list of series type ids. For instance, the argument seriestypes=3,7,22 shows series assigned to either of the series types with ids 3, 7 and 22.
  --seriestags: string # filter the results by matching on one or more series tags. The supplied list of series tags must be a comma separated list of series tag ids. For instance, the argument seriestags=6,2,11 shows series with either of the series tags with ids 6, 2 and 11.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/patients/{id}/images"
    path_params: [{name: id, var: id}]
    query: [{name: sources, var: sources}, {name: seriestypes, var: seriestypes}, {name: seriestags, var: seriestags}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sources: $sources, seriestypes: $seriestypes, seriestags: $seriestags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of metadata on the series level of the DICOM hierarchy
#
# GET /metadata/series
# Returns: table<bodyPartExamined: record<value: string>, frameOfReferenceUID: record<value: string>, id: int, manufacturer: record<value: string>, modality: record<value: string>, protocolName: record<value: string>, seriesDate: record<value: string>, seriesDescription: record<value: string>, seriesInstanceUID: record<value: string>, stationName: record<value: string>, studyId: int>
export def "get-metadata-series" [
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
  --startindex: int # start index of returned slice of series (format: int64, default: 0)
  --count: int # size of returned slice of series (format: int64, default: 20)
  --studyid: int # reference to study to list series for (required, format: int64)
  --sources: string # filter the results by matching on one or more series sources. Examples of sources are user, box, directory or scp. The list of sources to filter results by must have the form TYPE1:ID1,TYPE2:ID2,...,TYPEN:IDN. For instance, the argument sources=box:1,user:5 shows results either sent from (slice)box with id 1 or uploaded by user with id 5.
  --seriestypes: string # filter the results by matching on one or more series types. The supplied list of series types must be a comma separated list of series type ids. For instance, the argument seriestypes=3,7,22 shows series assigned to either of the series types with ids 3, 7 and 22.
  --seriestags: string # filter the results by matching on one or more series tags. The supplied list of series tags must be a comma separated list of series tag ids. For instance, the argument seriestags=6,2,11 shows series with either of the series tags with ids 6, 2 and 11.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/series"
    query: [{name: startindex, var: startindex}, {name: count, var: count}, {name: studyid, var: studyid, required: true}, {name: sources, var: sources}, {name: seriestypes, var: seriestypes}, {name: seriestags, var: seriestags}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count, studyid: $studyid, sources: $sources, seriestypes: $seriestypes, seriestags: $seriestags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# submit a query for series
#
# POST /metadata/series/query
# Returns: table<bodyPartExamined: record<value: string>, frameOfReferenceUID: record<value: string>, id: int, manufacturer: record<value: string>, modality: record<value: string>, protocolName: record<value: string>, seriesDate: record<value: string>, seriesDescription: record<value: string>, seriesInstanceUID: record<value: string>, stationName: record<value: string>, studyId: int>
export def "post-metadata-series-query" [
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
  count: int # format: int64
  --filters: record # shape: {seriesTagIds?: list<int>, seriesTypeIds?: list<int>, sourceRefs?: list}
  --order: record # shape: {orderAscending?: bool, orderBy?: string}
  query_properties: list # item shape: {operator?: string, propertyName?: string, propertyValue?: string}
  start_index: int # format: int64
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata/series/query"
    body: {content_type: "application/json", kind: json, fields: [{name: count, var: count}, {name: filters, var: filters}, {name: order, var: order}, {name: queryProperties, var: query_properties}, {name: startIndex, var: start_index}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    count: $count, filters: $filters, order: $order, query_properties: $query_properties, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return the series with the supplied ID
#
# GET /metadata/series/{id}
# Returns: record<bodyPartExamined: record<value: string>, frameOfReferenceUID: record<value: string>, id: int, manufacturer: record<value: string>, modality: record<value: string>, protocolName: record<value: string>, seriesDate: record<value: string>, seriesDescription: record<value: string>, seriesInstanceUID: record<value: string>, stationName: record<value: string>, studyId: int>
export def "get-metadata-series-id" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/series/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get the list of series tags for the series with the supplied ID.
#
# GET /metadata/series/{id}/seriestags
# Returns: table<id: int, name: string>
export def "get-metadata-series-id-seriestags" [
  id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/series/{id}/seriestags"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# add a series tag to the series with the supplied ID
#
# POST /metadata/series/{id}/seriestags
# Returns: record<id: int, name: string>
export def "post-metadata-series-id-seriestags" [
  id: int
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
  --body-id: int # format: int64 (spec name: id)
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata/series/{id}/seriestags"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id}, {name: name, var: name}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    id: $id, body_id: $body_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete all series types for the series with the supplied ID
#
# DELETE /metadata/series/{id}/seriestypes
export def "delete-metadata-series-id-seriestypes" [
  id: int
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
    method: delete
    path: "/metadata/series/{id}/seriestypes"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get the list of series types for the series with the supplied ID.
#
# GET /metadata/series/{id}/seriestypes
# Returns: table<id: int, name: string>
export def "get-metadata-series-id-seriestypes" [
  id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/series/{id}/seriestypes"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return the source of the series with the supplied ID
#
# GET /metadata/series/{id}/source
# Returns: record<sourceId: int, sourceName: string, sourceType: string>
export def "get-metadata-series-id-source" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/series/{id}/source"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete the series tag with the supplied series tag ID from the series with the supplied series ID
#
# DELETE /metadata/series/{seriesId}/seriestags/{seriesTagId}
export def "delete-metadata-series-series-id-seriestags-series-tag-id" [
  series_id: int
  series_tag_id: int
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
    method: delete
    path: "/metadata/series/{seriesId}/seriestags/{seriesTagId}"
    path_params: [{name: seriesId, var: series_id}, {name: seriesTagId, var: series_tag_id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    series_id: $series_id, series_tag_id: $series_tag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete the series type with the supplied series type ID from the series with the supplied series ID
#
# DELETE /metadata/series/{seriesId}/seriestypes/{seriesTypeId}
export def "delete-metadata-series-series-id-seriestypes-series-type-id" [
  series_id: int
  series_type_id: int
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
    method: delete
    path: "/metadata/series/{seriesId}/seriestypes/{seriesTypeId}"
    path_params: [{name: seriesId, var: series_id}, {name: seriesTypeId, var: series_type_id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    series_id: $series_id, series_type_id: $series_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add the series type with the supplied series type ID to the series with the supplied series ID
#
# PUT /metadata/series/{seriesId}/seriestypes/{seriesTypeId}
export def "put-metadata-series-series-id-seriestypes-series-type-id" [
  series_id: int
  series_type_id: int
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
    method: put
    path: "/metadata/series/{seriesId}/seriestypes/{seriesTypeId}"
    path_params: [{name: seriesId, var: series_id}, {name: seriesTypeId, var: series_type_id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    series_id: $series_id, series_type_id: $series_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of series tags currently currently in use.
#
# GET /metadata/seriestags
# Returns: table<id: int, name: string>
export def "get-metadata-seriestags" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/seriestags"
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of metadata on the study level of the DICOM hierarchy
#
# GET /metadata/studies
# Returns: table<accessionNumber: record<value: string>, id: int, patientAge: record<value: string>, patientId: int, studyDate: record<value: string>, studyDescription: record<value: string>, studyID: record<value: string>, studyInstanceUID: record<value: string>>
export def "get-metadata-studies" [
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
  --startindex: int # start index of returned slice of studies (format: int64, default: 0)
  --count: int # size of returned slice of studies (format: int64, default: 20)
  --patientid: int # reference to patient to list studies for (required, format: int64)
  --sources: string # filter the results by matching on one or more underlying series sources. Examples of sources are user, box, directory or scp. The list of sources to filter results by must have the form TYPE1:ID1,TYPE2:ID2,...,TYPEN:IDN. For instance, the argument sources=box:1,user:5 shows results either sent from (slice)box with id 1 or uploaded by user with id 5.
  --seriestypes: string # filter the results by matching on one or more underlying series types. The supplied list of series types must be a comma separated list of series type ids. For instance, the argument seriestypes=3,7,22 shows results including series assigned to either of the series types with ids 3, 7 and 22.
  --seriestags: string # filter the results by matching on one or more underlying series tags. The supplied list of series tags must be a comma separated list of series tag ids. For instance, the argument seriestags=6,2,11 shows results including series with either of the series tags with ids 6, 2 and 11.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/studies"
    query: [{name: startindex, var: startindex}, {name: count, var: count}, {name: patientid, var: patientid, required: true}, {name: sources, var: sources}, {name: seriestypes, var: seriestypes}, {name: seriestags, var: seriestags}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count, patientid: $patientid, sources: $sources, seriestypes: $seriestypes, seriestags: $seriestags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# submit a query for studies
#
# POST /metadata/studies/query
# Returns: table<accessionNumber: record<value: string>, id: int, patientAge: record<value: string>, patientId: int, studyDate: record<value: string>, studyDescription: record<value: string>, studyID: record<value: string>, studyInstanceUID: record<value: string>>
export def "post-metadata-studies-query" [
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
  count: int # format: int64
  --filters: record # shape: {seriesTagIds?: list<int>, seriesTypeIds?: list<int>, sourceRefs?: list}
  --order: record # shape: {orderAscending?: bool, orderBy?: string}
  query_properties: list # item shape: {operator?: string, propertyName?: string, propertyValue?: string}
  start_index: int # format: int64
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata/studies/query"
    body: {content_type: "application/json", kind: json, fields: [{name: count, var: count}, {name: filters, var: filters}, {name: order, var: order}, {name: queryProperties, var: query_properties}, {name: startIndex, var: start_index}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    count: $count, filters: $filters, order: $order, query_properties: $query_properties, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return the study with the supplied ID
#
# GET /metadata/studies/{id}
# Returns: record<accessionNumber: record<value: string>, id: int, patientAge: record<value: string>, patientId: int, studyDate: record<value: string>, studyDescription: record<value: string>, studyID: record<value: string>, studyInstanceUID: record<value: string>>
export def "get-metadata-studies-id" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/studies/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns all images for the study with the supplied study ID
#
# GET /metadata/studies/{id}/images
# Returns: table<id: int, imageType: record<value: string>, instanceNumber: record<value: string>, seriesId: int, sopInstanceUID: record<value: string>>
export def "get-metadata-studies-id-images" [
  id: int
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
  --sources: string # filter the results by matching on one or more series sources. Examples of sources are user, box, directory or scp. The list of sources to filter results by must have the form TYPE1:ID1,TYPE2:ID2,...,TYPEN:IDN. For instance, the argument sources=box:1,user:5 shows results either sent from (slice)box with id 1 or uploaded by user with id 5.
  --seriestypes: string # filter the results by matching on one or more series types. The supplied list of series types must be a comma separated list of series type ids. For instance, the argument seriestypes=3,7,22 shows series assigned to either of the series types with ids 3, 7 and 22.
  --seriestags: string # filter the results by matching on one or more series tags. The supplied list of series tags must be a comma separated list of series tag ids. For instance, the argument seriestags=6,2,11 shows series with either of the series tags with ids 6, 2 and 11.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/studies/{id}/images"
    path_params: [{name: id, var: id}]
    query: [{name: sources, var: sources}, {name: seriestypes, var: seriestypes}, {name: seriestags, var: seriestags}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sources: $sources, seriestypes: $seriestypes, seriestags: $seriestags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get a list of DICOM SCPs. Each SCP is a server for receiving DICOM images from e.g. a PACS system.
#
# GET /scps
# Returns: table<aeTitle: string, id: int, name: string, port: int>
export def "get-scps" [
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
  --startindex: int # start index of returned slice of SCPs (format: int64, default: 0)
  --count: int # size of returned slice of SCPs (format: int64, default: 20)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/scps"
    query: [{name: startindex, var: startindex}, {name: count, var: count}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# add a new SCP for receiving DICOM images
#
# POST /scps
# Returns: record<aeTitle: string, id: int, name: string, port: int>
export def "post-scps" [
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
  --ae-title: string
  --id: int # format: int64
  --name: string
  --port: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/scps"
    body: {content_type: "application/json", kind: json, fields: [{name: aeTitle, var: ae_title}, {name: id, var: id}, {name: name, var: name}, {name: port, var: port}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    ae_title: $ae_title, id: $id, name: $name, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# shut down and remove the SCP corresponding to the supplied ID
#
# DELETE /scps/{id}
export def "delete-scps-id" [
  id: int
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
    method: delete
    path: "/scps/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get a list of DICOM SCUs. Each SCU is a client for sending DICOM images to an SCP, e.g. a PACS system.
#
# GET /scus
# Returns: table<aeTitle: string, host: string, id: int, name: string, port: int>
export def "get-scus" [
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
  --startindex: int # start index of returned slice of SCUs (format: int64, default: 0)
  --count: int # size of returned slice of SCUs (format: int64, default: 20)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/scus"
    query: [{name: startindex, var: startindex}, {name: count, var: count}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# add a new SCU for sending DICOM images
#
# POST /scus
# Returns: record<aeTitle: string, host: string, id: int, name: string, port: int>
export def "post-scus" [
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
  --ae-title: string
  --host: string
  --id: int # format: int64
  --name: string
  --port: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/scus"
    body: {content_type: "application/json", kind: json, fields: [{name: aeTitle, var: ae_title}, {name: host, var: host}, {name: id, var: id}, {name: name, var: name}, {name: port, var: port}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    ae_title: $ae_title, host: $host, id: $id, name: $name, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# remove the SCU corresponding to the supplied ID
#
# DELETE /scus/{id}
export def "delete-scus-id" [
  id: int
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
    method: delete
    path: "/scus/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# send the images with the supplied image IDs to a DICOM SCP using the the SCU with the supplied scu ID
#
# POST /scus/{id}/send
export def "post-scus-id-send" [
  id: int
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
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/scus/{id}/send"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get a list of all added series types. By filtering search results for certain series types, it is easier for applications to ensure that they read images of applicable types.
#
# GET /seriestypes
# Returns: table<id: int, name: string>
export def "get-seriestypes" [
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
  --startindex: int # start index of returned slice of series types (format: int64, default: 0)
  --count: int # size of returned slice of series types (format: int64, default: 20)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/seriestypes"
    query: [{name: startindex, var: startindex}, {name: count, var: count}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# add a new series type
#
# POST /seriestypes
# Returns: record<id: int, name: string>
export def "post-seriestypes" [
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
  --id: int # format: int64
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/seriestypes"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get a list of rules for assigning series types to series. A rule connects to a series of attributes with values and a resulting series type. If a series has the required values of the listed attributes, it is assigned to the series type of the rule.
#
# GET /seriestypes/rules
# Returns: table<id: int, seriesTypeId: int>
export def "get-seriestypes-rules" [
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
  --seriestypeid: int # ID of series type to list rules for (required, format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/seriestypes/rules"
    query: [{name: seriestypeid, var: seriestypeid, required: true}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    seriestypeid: $seriestypeid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# add a new series type rule
#
# POST /seriestypes/rules
# Returns: record<id: int, seriesTypeId: int>
export def "post-seriestypes-rules" [
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
  --id: int # format: int64
  --series-type-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/seriestypes/rules"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: seriesTypeId, var: series_type_id}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    id: $id, series_type_id: $series_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get the status of the internal process of updating series types for series following a change of series types, rules or attributes.
#
# GET /seriestypes/rules/updatestatus
# Returns: record<running: bool>
export def "get-seriestypes-rules-updatestatus" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/seriestypes/rules/updatestatus"
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# remove the series type rule corresponding to the supplied ID
#
# DELETE /seriestypes/rules/{id}
export def "delete-seriestypes-rules-id" [
  id: int
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
    method: delete
    path: "/seriestypes/rules/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get the list of attributes for the series type rule with the supplied ID.
#
# GET /seriestypes/rules/{id}/attributes
# Returns: table<element: int, group: int, id: int, path: string, seriesTypeRuleId: int, value: string>
export def "get-seriestypes-rules-id-attributes" [
  id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/seriestypes/rules/{id}/attributes"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# add a new series type rule attribute
#
# POST /seriestypes/rules/{id}/attributes
# Returns: record<element: int, group: int, id: int, path: string, seriesTypeRuleId: int, value: string>
export def "post-seriestypes-rules-id-attributes" [
  id: int
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
  element: int # format: int32
  group: int # format: int32
  --body-id: int # format: int64 (spec name: id)
  --path: string
  series_type_rule_id: int # format: int64
  value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/seriestypes/rules/{id}/attributes"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: element, var: element}, {name: group, var: group}, {name: id, var: body_id, required: true}, {name: path, var: path}, {name: seriesTypeRuleId, var: series_type_rule_id}, {name: value, var: value}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    id: $id, element: $element, group: $group, body_id: $body_id, path: $path, series_type_rule_id: $series_type_rule_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# remove the series type rule attribute corresponding to the supplied series type and attribute IDs
#
# DELETE /seriestypes/rules/{ruleId}/attributes/{attributeId}
export def "delete-seriestypes-rules-rule-id-attributes-attribute-id" [
  rule_id: int
  attribute_id: int
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
    method: delete
    path: "/seriestypes/rules/{ruleId}/attributes/{attributeId}"
    path_params: [{name: ruleId, var: rule_id}, {name: attributeId, var: attribute_id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    rule_id: $rule_id, attribute_id: $attribute_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# submit a query for seriestypes for a list of series
#
# POST /seriestypes/series/query
# Returns: record<seriesidseriestypes: table<seriesid: int, seriestype: record>>
export def "post-seriestypes-series-query" [
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
  ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/seriestypes/series/query"
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# remove the series type corresponding to the supplied ID
#
# DELETE /seriestypes/{id}
export def "delete-seriestypes-id" [
  id: int
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
    method: delete
    path: "/seriestypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# request an asynchronous update of all series, labelling appropriate series with the series type corresponding to the supplied ID.
#
# PUT /seriestypes/{id}
export def "put-seriestypes-id" [
  id: int
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
    method: put
    path: "/seriestypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of currently available data sources. Possible source types are user - data imported by an API call by a user, box - data received from a remote box, directory - data imported via a watched directory, import - data imported into slicebox using import sessions, or scp - data received from a PACS.
#
# GET /sources
# Returns: table<sourceId: int, sourceName: string, sourceType: string>
export def "get-sources" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/sources"
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# No-op route for checking whether the service is alive or not
#
# GET /system/health
export def "get-system-health" [
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
    path: "/system/health"
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# stop and shut down slicebox
#
# POST /system/stop
export def "post-system-stop" [
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
    method: post
    path: "/system/stop"
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# add an image (dataset) as part of a transaction. This method is used when sending images using the push method to a public slicebox.
#
# POST /transactions/{token}/image
export def "post-transactions-token-image" [
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
  --accept: string@accept-completer # Response content type
  --transactionid: int # the ID of the client's outgoing transaction (required, format: int64)
  --sequencenumber: int # the index of this image in the transaction (required, format: int64)
  --totalimagecount: int # the total number of images in this transaction (required, format: int64)
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/transactions/{token}/image"
    path_params: [{name: token, var: token_arg}]
    query: [{name: transactionid, var: transactionid, required: true}, {name: sequencenumber, var: sequencenumber, required: true}, {name: totalimagecount, var: totalimagecount, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    token_arg: $token_arg, transactionid: $transactionid, sequencenumber: $sequencenumber, totalimagecount: $totalimagecount, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# fetch an image from the connected box as part of a transaction. This method is used when sending images using the poll method from a public slicebox.
#
# GET /transactions/{token}/outgoing
export def "get-transactions-token-outgoing" [
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
  --transactionid: int # the ID of the outgoing transaction (required, format: int64)
  --imageid: int # the ID of the outgoing transaction image (required, format: int64)
]: nothing -> any {
  http-request {
    method: get
    path: "/transactions/{token}/outgoing"
    path_params: [{name: token, var: token_arg}]
    query: [{name: transactionid, var: transactionid, required: true}, {name: imageid, var: imageid, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    token_arg: $token_arg, transactionid: $transactionid, imageid: $imageid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# signal that the supplied outgoing transaction and image was successfully received and can be marked as sent. This method is used when sending images using the poll method from a public slicebox.
#
# POST /transactions/{token}/outgoing/done
export def "post-transactions-token-outgoing-done" [
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
  --accept: string@accept-completer # Response content type
  --image: record # shape: {id?: int, imageId?: int, outgoingTransactionId?: int, sent?: bool, sequenceNumber?: int}
  --transaction: record # shape: {boxId?: int, boxName?: string, id?: int, profile?: record, sentImageCount?: int, status?: string, totalImageCount?: int, updated?: int}
]: any -> any {
  $in | http-request {
    method: post
    path: "/transactions/{token}/outgoing/done"
    path_params: [{name: token, var: token_arg}]
    body: {content_type: "application/json", kind: json, fields: [{name: image, var: image}, {name: transaction, var: transaction}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    token_arg: $token_arg, image: $image, transaction: $transaction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# signal that the image corresponding to the supplied outgoing transaction and image could not be read or stored properly on the receiving side, and that the transaction should be marked as failed.
#
# POST /transactions/{token}/outgoing/failed
export def "post-transactions-token-outgoing-failed" [
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
  --accept: string@accept-completer # Response content type
  --message: string
  --transaction-image: record # shape: {image?: record, transaction?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/transactions/{token}/outgoing/failed"
    path_params: [{name: token, var: token_arg}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: transactionImage, var: transaction_image}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    token_arg: $token_arg, message: $message, transaction_image: $transaction_image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get next outgoing transaction and image (information on the next image that the connected box wishes to send to you), if any. This method is used when sending images using the poll method from a public slicebox.
#
# GET /transactions/{token}/outgoing/poll
# Returns: table<image: record<id: int, imageId: int, outgoingTransactionId: int, sent: bool, sequenceNumber: int>, transaction: record<boxId: int, boxName: string, id: int, profile: record, sentImageCount: int, status: string, totalImageCount: int, updated: int>>
export def "get-transactions-token-outgoing-poll" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/transactions/{token}/outgoing/poll"
    path_params: [{name: token, var: token_arg}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get the status of the remote incoming transaction with the supplied transaction ID
#
# GET /transactions/{token}/status
export def "get-transactions-token-status" [
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
  --accept: string@accept-completer # Response content type
  --transactionid: int # the ID of the client's outgoing transaction (required, format: int64)
]: nothing -> any {
  http-request {
    method: get
    path: "/transactions/{token}/status"
    path_params: [{name: token, var: token_arg}]
    query: [{name: transactionid, var: transactionid, required: true}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    token_arg: $token_arg, transactionid: $transactionid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# update the status of the transaction with the supplied ID
#
# PUT /transactions/{token}/status
export def "put-transactions-token-status" [
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
  --accept: string@accept-completer # Response content type
  --transactionid: int # the ID of the client's outgoing transaction (required, format: int64)
  --body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/transactions/{token}/status"
    path_params: [{name: token, var: token_arg}]
    query: [{name: transactionid, var: transactionid, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    token_arg: $token_arg, transactionid: $transactionid, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns all users of slicebox
#
# GET /users
# Returns: table<hashedPassword: string, id: int, role: string, user: string>
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
  --accept: string@accept-completer # Response content type
  --startindex: int # start index of returned slice of users (format: int64, default: 0)
  --count: int # size of returned slice of users (format: int64, default: 20)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: startindex, var: startindex}, {name: count, var: count}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    startindex: $startindex, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new user. Dupicates are accepted but not added.
#
# POST /users
# Returns: record<hashedPassword: string, id: int, role: string, user: string>
export def "post-users" [
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
  --password: string
  --role: string
  --user: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: role, var: role}, {name: user, var: user}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    password: $password, role: $role, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# obtain information on the currently logged in user as specified by the supplied session cookie, IP address and user agent.
#
# GET /users/current
# Returns: record<id: int, role: string, user: string>
export def "get-users-current" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/current"
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Obtain a session cookie that can be used to authenticate future API calls from the present IP address and with the present user agent.
#
# POST /users/login
export def "post-users-login" [
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
  --pass: string
  --user: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/login"
    body: {content_type: "application/json", kind: json, fields: [{name: pass, var: pass}, {name: user, var: user}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    pass: $pass, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Logout the current user by responding with a delete cookie header removing the session cookie for this user.
#
# POST /users/logout
export def "post-users-logout" [
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
    method: post
    path: "/users/logout"
    accept: ["application/json", "application/octet-stream"]
    ok: [201]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# deletes a single user based on the ID supplied
#
# DELETE /users/{id}
export def "delete-users-id" [
  id: int
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
    method: delete
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
