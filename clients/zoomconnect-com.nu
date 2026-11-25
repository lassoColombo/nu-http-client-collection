# Auto-generated client for www.zoomconnect.com v1
# Source: https://api.apis.guru/v2/specs/zoomconnect.com/1/swagger.json
# Auth: --token flag or $env.WWW_ZOOMCONNECT_COM_TOKEN

const CLIENT = {
  base_url: "https://www.zoomconnect.com/app"
  token_env_var: "WWW_ZOOMCONNECT_COM_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: email, in: header, header_name: email, prefix: ""}
    {name: token, in: header, header_name: token, prefix: ""}
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

def base-url-completer [] { ["https://www.zoomconnect.com/app"] }
def auth-scheme-completer [] { ["email" "token"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def type-completer [] { ["INBOUND" "OUTBOUND"] }
def status-completer [] { ["DELIVERED" "FAILED" "FAILED_OPTOUT" "FAILED_REFUNDED" "SCHEDULED" "SENT" "UNKNOWN"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-balance: "record<creditBalance: float, links: table<href: string, rel: string, templated: bool>>"
    get-statistics: "record<from: string, grandTotal: record<delivered: float, failed: float, failedOptout: float, failedRefunded: float, sent: float, total: float>, showingCreditValue: bool, to: string, users: table<campaigns: list, total: record, user: record>>"
    transfer: "record<company: string, contactNumber: string, creditBalance: float, emailAddress: string, firstName: string, lastName: string, password: string, userId: int>"
    search: "record<webServiceUserList: table<company: string, contactNumber: string, creditBalance: float, emailAddress: string, firstName: string, lastName: string, password: string, userId: int>>"
    put-api-rest-v1-account-user: "record<company: string, contactNumber: string, creditBalance: float, emailAddress: string, firstName: string, lastName: string, password: string, userId: int>"
    get-user: "record<company: string, contactNumber: string, creditBalance: float, emailAddress: string, firstName: string, lastName: string, password: string, userId: int>"
    post-api-rest-v1-account-user-user-id: "record<company: string, contactNumber: string, creditBalance: float, emailAddress: string, firstName: string, lastName: string, password: string, userId: int>"
    get-api-rest-v1-contacts-all: "record<links: table<href: string, rel: string, templated: bool>, webServiceContacts: table<contactId: string, contactNumber: string, firstName: string, lastName: string, links: list, title: string>>"
    post-api-rest-v1-contacts-create: "record<contactId: string, contactNumber: string, firstName: string, lastName: string, links: table<href: string, rel: string, templated: bool>, title: string>"
    get-api-rest-v1-contacts-contact-id: "record<contactId: string, contactNumber: string, firstName: string, lastName: string, links: table<href: string, rel: string, templated: bool>, title: string>"
    post-api-rest-v1-contacts-contact-id: "record<contactId: string, contactNumber: string, firstName: string, lastName: string, links: table<href: string, rel: string, templated: bool>, title: string>"
    get-api-rest-v1-groups-all: "record<links: table<href: string, rel: string, templated: bool>, webServiceGroups: table<groupId: string, links: list, name: string>>"
    post-api-rest-v1-groups-create: "record<groupId: string, links: table<href: string, rel: string, templated: bool>, name: string>"
    get-api-rest-v1-groups-group-id: "record<groupId: string, links: table<href: string, rel: string, templated: bool>, name: string>"
    post-api-rest-v1-groups-group-id: "record<groupId: string, links: table<href: string, rel: string, templated: bool>, name: string>"
    get-api-rest-v1-messages-all: "record<elements: int, links: table<href: string, rel: string, templated: bool>, page: int, pageSize: int, totalElements: int, totalPages: int, webServiceMessages: table<campaign: string, contact: record, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: list, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record, toNumber: string, userDataField: string>>"
    analyse-full: "record<characterAnalysis: list<list<any>>, messageCreditCost: float, messageEncoding: string, messageLength: int, messageLengthWithinMaximumAllowed: bool, numberOfMessages: int>"
    analyse-message-credit-cost: "float"
    analyse-message-encoding: "string"
    analyse-message-length: "int"
    analyse: "bool"
    analyse-number-of-messages: "int"
    get-api-rest-v1-messages-message-id: "record<campaign: string, contact: record<contactId: string, links: list<record>>, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: table<href: string, rel: string, templated: bool>, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record<links: list<record>, messageId: string>, toNumber: string, userDataField: string>"
    post-api-rest-v1-messages-message-id-mark-read: "record<campaign: string, contact: record<contactId: string, links: list<record>>, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: table<href: string, rel: string, templated: bool>, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record<links: list<record>, messageId: string>, toNumber: string, userDataField: string>"
    put-api-rest-v1-messages-message-id-mark-read: "record<campaign: string, contact: record<contactId: string, links: list<record>>, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: table<href: string, rel: string, templated: bool>, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record<links: list<record>, messageId: string>, toNumber: string, userDataField: string>"
    post-api-rest-v1-messages-message-id-mark-unread: "record<campaign: string, contact: record<contactId: string, links: list<record>>, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: table<href: string, rel: string, templated: bool>, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record<links: list<record>, messageId: string>, toNumber: string, userDataField: string>"
    put-api-rest-v1-messages-message-id-mark-unread: "record<campaign: string, contact: record<contactId: string, links: list<record>>, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: table<href: string, rel: string, templated: bool>, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record<links: list<record>, messageId: string>, toNumber: string, userDataField: string>"
    get-api-rest-v1-sms-send: "record<campaign: string, dataField: string, dateToSend: string, message: string, recipientNumber: string>"
    post-api-rest-v1-sms-send: "record<error: string, messageId: string>"
    get-api-rest-v1-sms-send-bulk: "record<defaultDateToSend: string, messagesPerMinute: int, sendSmsRequests: table<campaign: string, dataField: string, dateToSend: string, message: string, recipientNumber: string>>"
    post-api-rest-v1-sms-send-bulk: "record<sendSmsResponses: table<error: string, messageId: string>>"
    get-api-rest-v1-sms-send-url-parameters: "string"
    post-api-rest-v1-sms-send-url-parameters: "string"
    get-api-rest-v1-sms-send-url-token: "string"
    post-api-rest-v1-sms-send-url-token: "string"
    get-api-rest-v1-templates-all: "record<links: table<href: string, rel: string, templated: bool>, webServiceTemplates: table<data: string, links: list, name: string, templateId: int>>"
    get-api-rest-v1-templates-template-id: "record<data: string, links: table<href: string, rel: string, templated: bool>, name: string, templateId: int>"
    get-api-rest-v1-voice-all: "record<elements: int, links: table<href: string, rel: string, templated: bool>, messages: table<audioFileUrl: string, campaign: string, dateTimeSent: string, deleted: bool, language: string, links: list, message: string, messageStatus: string, toNumber: string, userDataField: string, voiceMessageId: string>, page: int, pageSize: int, totalElements: int, totalPages: int>"
    single-audio: "record<error: string, voiceMessageId: string>"
    single-text: "record<error: string, voiceMessageId: string>"
    get-api-rest-v1-voice-message-id: "record<audioFileUrl: string, campaign: string, dateTimeSent: string, deleted: bool, language: string, links: table<href: string, rel: string, templated: bool>, message: string, messageStatus: string, toNumber: string, userDataField: string, voiceMessageId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-balance" "get-statistics" "transfer" "search" "put-api-rest-v1-account-user" "get-user" "post-api-rest-v1-account-user-user-id" "get-api-rest-v1-contacts-all" "post-api-rest-v1-contacts-create" "delete-api-rest-v1-contacts-contact-id" "get-api-rest-v1-contacts-contact-id" "post-api-rest-v1-contacts-contact-id" "get-api-rest-v1-contacts-contact-id-add-from-group-group-id" "post-api-rest-v1-contacts-contact-id-add-from-group-group-id" "get-api-rest-v1-contacts-contact-id-add-to-group-group-id" "post-api-rest-v1-contacts-contact-id-add-to-group-group-id" "get-api-rest-v1-groups-all" "post-api-rest-v1-groups-create" "delete-api-rest-v1-groups-group-id" "get-api-rest-v1-groups-group-id" "post-api-rest-v1-groups-group-id" "get-api-rest-v1-groups-group-id-add-contact-contact-id" "post-api-rest-v1-groups-group-id-add-contact-contact-id" "get-api-rest-v1-groups-group-id-remove-contact-contact-id" "post-api-rest-v1-groups-group-id-remove-contact-contact-id" "get-api-rest-v1-messages-all" "analyse-full" "analyse-message-credit-cost" "analyse-message-encoding" "analyse-message-length" "analyse" "analyse-number-of-messages" "delete-api-rest-v1-messages-message-id" "get-api-rest-v1-messages-message-id" "post-api-rest-v1-messages-message-id-mark-read" "put-api-rest-v1-messages-message-id-mark-read" "post-api-rest-v1-messages-message-id-mark-unread" "put-api-rest-v1-messages-message-id-mark-unread" "get-api-rest-v1-sms-send" "post-api-rest-v1-sms-send" "get-api-rest-v1-sms-send-bulk" "post-api-rest-v1-sms-send-bulk" "get-api-rest-v1-sms-send-url-parameters" "post-api-rest-v1-sms-send-url-parameters" "get-api-rest-v1-sms-send-url-token" "post-api-rest-v1-sms-send-url-token" "get-api-rest-v1-templates-all" "delete-api-rest-v1-templates-template-id" "get-api-rest-v1-templates-template-id" "get-api-rest-v1-voice-all" "single-audio" "single-text" "delete-api-rest-v1-voice-message-id" "get-api-rest-v1-voice-message-id" "commands"] | sort) } | get name | first)
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

# balance
#
# GET /api/rest/v1/account/balance
# Returns: record<creditBalance: float, links: table<href: string, rel: string, templated: bool>>
# operationId: getBalance
export def "get-balance" [
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
    path: "/api/rest/v1/account/balance"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# statistics
#
# GET /api/rest/v1/account/statistics
# Returns: record<from: string, grandTotal: record<delivered: float, failed: float, failedOptout: float, failedRefunded: float, sent: float, total: float>, showingCreditValue: bool, to: string, users: table<campaigns: list, total: record, user: record>>
# operationId: getStatistics
export def "get-statistics" [
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
  --from: string # date format: dd-MM-yyyy (format: date-time)
  --to: string # date format: dd-MM-yyyy (format: date-time)
  --user-email-address: string # optional email address of user to return statistics for a single user, default is to return statistics for all users if administrator, or statistics for your own account if not an administrator
  --campaign: string # optional campaign name
  --include-refunded-and-optout: oneof<nothing, bool> # optionally include refunded and optout counts, default is false
  --calculate-credit-value: oneof<nothing, bool> # optionally calculate using credit value rather than message count, default is false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/account/statistics"
    query: [{name: from, var: from}, {name: to, var: to}, {name: userEmailAddress, var: user_email_address}, {name: campaign, var: campaign}, {name: includeRefundedAndOptout, var: include_refunded_and_optout}, {name: calculateCreditValue, var: calculate_credit_value}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    from: $from, to: $to, user_email_address: $user_email_address, campaign: $campaign, include_refunded_and_optout: $include_refunded_and_optout, calculate_credit_value: $calculate_credit_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# transfer
#
# POST /api/rest/v1/account/transfer
# Returns: record<company: string, contactNumber: string, creditBalance: float, emailAddress: string, firstName: string, lastName: string, password: string, userId: int>
# operationId: transfer
export def "transfer" [
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
  --number-of-credits-to-transfer: int # format: int32
  --transfer-from-email-address: string
  --transfer-to-email-address: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rest/v1/account/transfer"
    body: {content_type: "application/json", kind: json, fields: [{name: numberOfCreditsToTransfer, var: number_of_credits_to_transfer}, {name: transferFromEmailAddress, var: transfer_from_email_address}, {name: transferToEmailAddress, var: transfer_to_email_address}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    number_of_credits_to_transfer: $number_of_credits_to_transfer, transfer_from_email_address: $transfer_from_email_address, transfer_to_email_address: $transfer_to_email_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# search
#
# GET /api/rest/v1/account/user
# Returns: record<webServiceUserList: table<company: string, contactNumber: string, creditBalance: float, emailAddress: string, firstName: string, lastName: string, password: string, userId: int>>
# operationId: search
export def "search" [
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
  --search-email: string # search by email address (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/account/user"
    query: [{name: searchEmail, var: search_email, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    search_email: $search_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# create
#
# PUT /api/rest/v1/account/user
# Returns: record<company: string, contactNumber: string, creditBalance: float, emailAddress: string, firstName: string, lastName: string, password: string, userId: int>
export def "put-api-rest-v1-account-user" [
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
  --company: string
  --contact-number: string
  --credit-balance: float # format: double
  --email-address: string
  --first-name: string
  --last-name: string
  --password: string
  --user-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/rest/v1/account/user"
    body: {content_type: "application/json", kind: json, fields: [{name: company, var: company}, {name: contactNumber, var: contact_number}, {name: creditBalance, var: credit_balance}, {name: emailAddress, var: email_address}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: password, var: password}, {name: userId, var: user_id}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    company: $company, contact_number: $contact_number, credit_balance: $credit_balance, email_address: $email_address, first_name: $first_name, last_name: $last_name, password: $password, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# getUser
#
# GET /api/rest/v1/account/user/{userId}
# Returns: record<company: string, contactNumber: string, creditBalance: float, emailAddress: string, firstName: string, lastName: string, password: string, userId: int>
# operationId: getUser
export def "get-user" [
  user_id: int
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
    path: "/api/rest/v1/account/user/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# update
#
# POST /api/rest/v1/account/user/{userId}
# Returns: record<company: string, contactNumber: string, creditBalance: float, emailAddress: string, firstName: string, lastName: string, password: string, userId: int>
export def "post-api-rest-v1-account-user-user-id" [
  user_id: int
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
  --company: string
  --contact-number: string
  --credit-balance: float # format: double
  --email-address: string
  --first-name: string
  --last-name: string
  --password: string
  --body-user-id: int # format: int64 (spec name: userId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rest/v1/account/user/{userId}"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: company, var: company}, {name: contactNumber, var: contact_number}, {name: creditBalance, var: credit_balance}, {name: emailAddress, var: email_address}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: password, var: password}, {name: userId, var: body_user_id}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    user_id: $user_id, company: $company, contact_number: $contact_number, credit_balance: $credit_balance, email_address: $email_address, first_name: $first_name, last_name: $last_name, password: $password, body_user_id: $body_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# all
#
# GET /api/rest/v1/contacts/all
# Returns: record<links: table<href: string, rel: string, templated: bool>, webServiceContacts: table<contactId: string, contactNumber: string, firstName: string, lastName: string, links: list, title: string>>
export def "get-api-rest-v1-contacts-all" [
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
    path: "/api/rest/v1/contacts/all"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# create
#
# POST /api/rest/v1/contacts/create
# Returns: record<contactId: string, contactNumber: string, firstName: string, lastName: string, links: table<href: string, rel: string, templated: bool>, title: string>
export def "post-api-rest-v1-contacts-create" [
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
  --contact-id: string
  --contact-number: string
  --first-name: string
  --last-name: string
  --links: list # item shape: {href?: string, rel?: string, templated?: bool}
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rest/v1/contacts/create"
    body: {content_type: "application/json", kind: json, fields: [{name: contactId, var: contact_id}, {name: contactNumber, var: contact_number}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: links, var: links}, {name: title, var: title}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    contact_id: $contact_id, contact_number: $contact_number, first_name: $first_name, last_name: $last_name, links: $links, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# delete
#
# DELETE /api/rest/v1/contacts/{contactId}
export def "delete-api-rest-v1-contacts-contact-id" [
  contact_id: string
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
    path: "/api/rest/v1/contacts/{contactId}"
    path_params: [{name: contactId, var: contact_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 204]
    auth: email
  } {
    contact_id: $contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get
#
# GET /api/rest/v1/contacts/{contactId}
# Returns: record<contactId: string, contactNumber: string, firstName: string, lastName: string, links: table<href: string, rel: string, templated: bool>, title: string>
export def "get-api-rest-v1-contacts-contact-id" [
  contact_id: string
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
    path: "/api/rest/v1/contacts/{contactId}"
    path_params: [{name: contactId, var: contact_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    contact_id: $contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# update
#
# POST /api/rest/v1/contacts/{contactId}
# Returns: record<contactId: string, contactNumber: string, firstName: string, lastName: string, links: table<href: string, rel: string, templated: bool>, title: string>
export def "post-api-rest-v1-contacts-contact-id" [
  contact_id: string
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
  --body-contact-id: string # (spec name: contactId)
  --contact-number: string
  --first-name: string
  --last-name: string
  --links: list # item shape: {href?: string, rel?: string, templated?: bool}
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rest/v1/contacts/{contactId}"
    path_params: [{name: contactId, var: contact_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: contactId, var: body_contact_id}, {name: contactNumber, var: contact_number}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: links, var: links}, {name: title, var: title}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    contact_id: $contact_id, body_contact_id: $body_contact_id, contact_number: $contact_number, first_name: $first_name, last_name: $last_name, links: $links, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# removeFromGroup
#
# GET /api/rest/v1/contacts/{contactId}/addFromGroup/{groupId}
export def "get-api-rest-v1-contacts-contact-id-add-from-group-group-id" [
  contact_id: string
  group_id: string
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
    path: "/api/rest/v1/contacts/{contactId}/addFromGroup/{groupId}"
    path_params: [{name: contactId, var: contact_id}, {name: groupId, var: group_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    contact_id: $contact_id, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# removeFromGroup
#
# POST /api/rest/v1/contacts/{contactId}/addFromGroup/{groupId}
export def "post-api-rest-v1-contacts-contact-id-add-from-group-group-id" [
  contact_id: string
  group_id: string
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
    path: "/api/rest/v1/contacts/{contactId}/addFromGroup/{groupId}"
    path_params: [{name: contactId, var: contact_id}, {name: groupId, var: group_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    contact_id: $contact_id, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# addToGroup
#
# GET /api/rest/v1/contacts/{contactId}/addToGroup/{groupId}
export def "get-api-rest-v1-contacts-contact-id-add-to-group-group-id" [
  contact_id: string
  group_id: string
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
    path: "/api/rest/v1/contacts/{contactId}/addToGroup/{groupId}"
    path_params: [{name: contactId, var: contact_id}, {name: groupId, var: group_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    contact_id: $contact_id, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# addToGroup
#
# POST /api/rest/v1/contacts/{contactId}/addToGroup/{groupId}
export def "post-api-rest-v1-contacts-contact-id-add-to-group-group-id" [
  contact_id: string
  group_id: string
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
    path: "/api/rest/v1/contacts/{contactId}/addToGroup/{groupId}"
    path_params: [{name: contactId, var: contact_id}, {name: groupId, var: group_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    contact_id: $contact_id, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# all
#
# GET /api/rest/v1/groups/all
# Returns: record<links: table<href: string, rel: string, templated: bool>, webServiceGroups: table<groupId: string, links: list, name: string>>
export def "get-api-rest-v1-groups-all" [
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
    path: "/api/rest/v1/groups/all"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# create
#
# POST /api/rest/v1/groups/create
# Returns: record<groupId: string, links: table<href: string, rel: string, templated: bool>, name: string>
export def "post-api-rest-v1-groups-create" [
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
  --group-id: string
  --links: list # item shape: {href?: string, rel?: string, templated?: bool}
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rest/v1/groups/create"
    body: {content_type: "application/json", kind: json, fields: [{name: groupId, var: group_id}, {name: links, var: links}, {name: name, var: name}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    group_id: $group_id, links: $links, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# delete
#
# DELETE /api/rest/v1/groups/{groupId}
export def "delete-api-rest-v1-groups-group-id" [
  group_id: string
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
    path: "/api/rest/v1/groups/{groupId}"
    path_params: [{name: groupId, var: group_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 204]
    auth: email
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get
#
# GET /api/rest/v1/groups/{groupId}
# Returns: record<groupId: string, links: table<href: string, rel: string, templated: bool>, name: string>
export def "get-api-rest-v1-groups-group-id" [
  group_id: string
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
    path: "/api/rest/v1/groups/{groupId}"
    path_params: [{name: groupId, var: group_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# update
#
# POST /api/rest/v1/groups/{groupId}
# Returns: record<groupId: string, links: table<href: string, rel: string, templated: bool>, name: string>
export def "post-api-rest-v1-groups-group-id" [
  group_id: string
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
  --body-group-id: string # (spec name: groupId)
  --links: list # item shape: {href?: string, rel?: string, templated?: bool}
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rest/v1/groups/{groupId}"
    path_params: [{name: groupId, var: group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: groupId, var: body_group_id}, {name: links, var: links}, {name: name, var: name}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    group_id: $group_id, body_group_id: $body_group_id, links: $links, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# addContact
#
# GET /api/rest/v1/groups/{groupId}/addContact/{contactId}
export def "get-api-rest-v1-groups-group-id-add-contact-contact-id" [
  group_id: string
  contact_id: string
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
    path: "/api/rest/v1/groups/{groupId}/addContact/{contactId}"
    path_params: [{name: groupId, var: group_id}, {name: contactId, var: contact_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    group_id: $group_id, contact_id: $contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# addContact
#
# POST /api/rest/v1/groups/{groupId}/addContact/{contactId}
export def "post-api-rest-v1-groups-group-id-add-contact-contact-id" [
  group_id: string
  contact_id: string
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
    path: "/api/rest/v1/groups/{groupId}/addContact/{contactId}"
    path_params: [{name: groupId, var: group_id}, {name: contactId, var: contact_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    group_id: $group_id, contact_id: $contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# removeContact
#
# GET /api/rest/v1/groups/{groupId}/removeContact/{contactId}
export def "get-api-rest-v1-groups-group-id-remove-contact-contact-id" [
  group_id: string
  contact_id: string
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
    path: "/api/rest/v1/groups/{groupId}/removeContact/{contactId}"
    path_params: [{name: groupId, var: group_id}, {name: contactId, var: contact_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    group_id: $group_id, contact_id: $contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# removeContact
#
# POST /api/rest/v1/groups/{groupId}/removeContact/{contactId}
export def "post-api-rest-v1-groups-group-id-remove-contact-contact-id" [
  group_id: string
  contact_id: string
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
    path: "/api/rest/v1/groups/{groupId}/removeContact/{contactId}"
    path_params: [{name: groupId, var: group_id}, {name: contactId, var: contact_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    group_id: $group_id, contact_id: $contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# all
#
# GET /api/rest/v1/messages/all
# Returns: record<elements: int, links: table<href: string, rel: string, templated: bool>, page: int, pageSize: int, totalElements: int, totalPages: int, webServiceMessages: table<campaign: string, contact: record, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: list, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record, toNumber: string, userDataField: string>>
export def "get-api-rest-v1-messages-all" [
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
  --page-size: int # number of elements to return at a time (format: int32, default: 100)
  --page: int # page number (format: int32, default: 1)
  --type: string@type-completer # filter by message type
  --status: string@status-completer # filter by message status
  --from-date-time-sent: string # date format: yyyyMMdd (format: date-time)
  --to-date-time-sent: string # date format: yyyyMMdd (format: date-time)
  --from-date-time-received: string # date format: yyyyMMdd (format: date-time)
  --to-date-time-received: string # date format: yyyyMMdd (format: date-time)
  --from-number: string # phone number the message was sent from
  --to-number: string # phone number the message was sent to
  --message: string # search matching message text
  --campaign: string # search by campaign
  --data-field: string # search by data field
  --deleted: oneof<nothing, bool> # return only deleted / not deleted messages
  --read: oneof<nothing, bool> # return only read / unread messages (inbox messages only)
  --replies-to-message-id: string # return only inbox messages which are a reply to the message with the given message id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/messages/all"
    query: [{name: pageSize, var: page_size}, {name: page, var: page}, {name: type, var: type}, {name: status, var: status}, {name: fromDateTimeSent, var: from_date_time_sent}, {name: toDateTimeSent, var: to_date_time_sent}, {name: fromDateTimeReceived, var: from_date_time_received}, {name: toDateTimeReceived, var: to_date_time_received}, {name: fromNumber, var: from_number}, {name: toNumber, var: to_number}, {name: message, var: message}, {name: campaign, var: campaign}, {name: dataField, var: data_field}, {name: deleted, var: deleted}, {name: read, var: read}, {name: repliesToMessageId, var: replies_to_message_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    page_size: $page_size, page: $page, type: $type, status: $status, from_date_time_sent: $from_date_time_sent, to_date_time_sent: $to_date_time_sent, from_date_time_received: $from_date_time_received, to_date_time_received: $to_date_time_received, from_number: $from_number, to_number: $to_number, message: $message, campaign: $campaign, data_field: $data_field, deleted: $deleted, read: $read, replies_to_message_id: $replies_to_message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# analyse-full
#
# POST /api/rest/v1/messages/analyse/full
# Returns: record<characterAnalysis: list<list<any>>, messageCreditCost: float, messageEncoding: string, messageLength: int, messageLengthWithinMaximumAllowed: bool, numberOfMessages: int>
# operationId: analyse-full
export def "analyse-full" [
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
  --recipient-number: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rest/v1/messages/analyse/full"
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: recipientNumber, var: recipient_number}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    message: $message, recipient_number: $recipient_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# analyse-message-credit-cost
#
# POST /api/rest/v1/messages/analyse/message-credit-cost
# Returns: float
# operationId: analyse-message-credit-cost
export def "analyse-message-credit-cost" [
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
  --recipient-number: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/messages/analyse/message-credit-cost"
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: recipientNumber, var: recipient_number}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    message: $message, recipient_number: $recipient_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# analyse-message-encoding
#
# POST /api/rest/v1/messages/analyse/message-encoding
# Returns: string
# operationId: analyse-message-encoding
export def "analyse-message-encoding" [
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
  --recipient-number: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/messages/analyse/message-encoding"
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: recipientNumber, var: recipient_number}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    message: $message, recipient_number: $recipient_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# analyse-message-length
#
# POST /api/rest/v1/messages/analyse/message-length
# Returns: int
# operationId: analyse-message-length
export def "analyse-message-length" [
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
  --recipient-number: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/messages/analyse/message-length"
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: recipientNumber, var: recipient_number}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    message: $message, recipient_number: $recipient_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# analyse-
#
# POST /api/rest/v1/messages/analyse/message-length-within-max-allowed
# Returns: bool
# operationId: analyse-
export def "analyse" [
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
  --recipient-number: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/messages/analyse/message-length-within-max-allowed"
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: recipientNumber, var: recipient_number}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    message: $message, recipient_number: $recipient_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# analyse-number-of-messages
#
# POST /api/rest/v1/messages/analyse/number-of-messages
# Returns: int
# operationId: analyse-number-of-messages
export def "analyse-number-of-messages" [
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
  --recipient-number: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/messages/analyse/number-of-messages"
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: recipientNumber, var: recipient_number}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    message: $message, recipient_number: $recipient_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# delete
#
# DELETE /api/rest/v1/messages/{messageId}
export def "delete-api-rest-v1-messages-message-id" [
  message_id: string
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
    path: "/api/rest/v1/messages/{messageId}"
    path_params: [{name: messageId, var: message_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 204]
    auth: email
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get
#
# GET /api/rest/v1/messages/{messageId}
# Returns: record<campaign: string, contact: record<contactId: string, links: list<record>>, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: table<href: string, rel: string, templated: bool>, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record<links: list<record>, messageId: string>, toNumber: string, userDataField: string>
export def "get-api-rest-v1-messages-message-id" [
  message_id: string
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
    path: "/api/rest/v1/messages/{messageId}"
    path_params: [{name: messageId, var: message_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# markRead
#
# POST /api/rest/v1/messages/{messageId}/markRead
# Returns: record<campaign: string, contact: record<contactId: string, links: list<record>>, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: table<href: string, rel: string, templated: bool>, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record<links: list<record>, messageId: string>, toNumber: string, userDataField: string>
export def "post-api-rest-v1-messages-message-id-mark-read" [
  message_id: string
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
    method: post
    path: "/api/rest/v1/messages/{messageId}/markRead"
    path_params: [{name: messageId, var: message_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# markRead
#
# PUT /api/rest/v1/messages/{messageId}/markRead
# Returns: record<campaign: string, contact: record<contactId: string, links: list<record>>, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: table<href: string, rel: string, templated: bool>, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record<links: list<record>, messageId: string>, toNumber: string, userDataField: string>
export def "put-api-rest-v1-messages-message-id-mark-read" [
  message_id: string
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
    method: put
    path: "/api/rest/v1/messages/{messageId}/markRead"
    path_params: [{name: messageId, var: message_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# markUnread
#
# POST /api/rest/v1/messages/{messageId}/markUnread
# Returns: record<campaign: string, contact: record<contactId: string, links: list<record>>, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: table<href: string, rel: string, templated: bool>, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record<links: list<record>, messageId: string>, toNumber: string, userDataField: string>
export def "post-api-rest-v1-messages-message-id-mark-unread" [
  message_id: string
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
    method: post
    path: "/api/rest/v1/messages/{messageId}/markUnread"
    path_params: [{name: messageId, var: message_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# markUnread
#
# PUT /api/rest/v1/messages/{messageId}/markUnread
# Returns: record<campaign: string, contact: record<contactId: string, links: list<record>>, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: table<href: string, rel: string, templated: bool>, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record<links: list<record>, messageId: string>, toNumber: string, userDataField: string>
export def "put-api-rest-v1-messages-message-id-mark-unread" [
  message_id: string
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
    method: put
    path: "/api/rest/v1/messages/{messageId}/markUnread"
    path_params: [{name: messageId, var: message_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# send
#
# GET /api/rest/v1/sms/send
# Returns: record<campaign: string, dataField: string, dateToSend: string, message: string, recipientNumber: string>
export def "get-api-rest-v1-sms-send" [
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
    path: "/api/rest/v1/sms/send"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# send
#
# POST /api/rest/v1/sms/send
# Returns: record<error: string, messageId: string>
export def "post-api-rest-v1-sms-send" [
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
  --campaign: string
  --data-field: string
  --date-to-send: string # format: date-time
  --message: string
  --recipient-number: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rest/v1/sms/send"
    body: {content_type: "application/json", kind: json, fields: [{name: campaign, var: campaign}, {name: dataField, var: data_field}, {name: dateToSend, var: date_to_send}, {name: message, var: message}, {name: recipientNumber, var: recipient_number}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    campaign: $campaign, data_field: $data_field, date_to_send: $date_to_send, message: $message, recipient_number: $recipient_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# send-bulk
#
# GET /api/rest/v1/sms/send-bulk
# Returns: record<defaultDateToSend: string, messagesPerMinute: int, sendSmsRequests: table<campaign: string, dataField: string, dateToSend: string, message: string, recipientNumber: string>>
export def "get-api-rest-v1-sms-send-bulk" [
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
    path: "/api/rest/v1/sms/send-bulk"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# send-bulk
#
# POST /api/rest/v1/sms/send-bulk
# Returns: record<sendSmsResponses: table<error: string, messageId: string>>
export def "post-api-rest-v1-sms-send-bulk" [
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
  --default-date-to-send: string # format: date-time
  --messages-per-minute: int # format: int32
  --send-sms-requests: list # item shape: {campaign?: string, dataField?: string, dateToSend?: string, message?: string, recipientNumber?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rest/v1/sms/send-bulk"
    body: {content_type: "application/json", kind: json, fields: [{name: defaultDateToSend, var: default_date_to_send}, {name: messagesPerMinute, var: messages_per_minute}, {name: sendSmsRequests, var: send_sms_requests}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    default_date_to_send: $default_date_to_send, messages_per_minute: $messages_per_minute, send_sms_requests: $send_sms_requests
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# send-url-parameters
#
# GET /api/rest/v1/sms/send-url-parameters
# Returns: string
export def "get-api-rest-v1-sms-send-url-parameters" [
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
  --recipient-number: string # the phone number of the recipient to send to (required)
  --message: string # the message to send (required)
  --date-to-send: string # date format: yyyyMMddHHmm (format: date-time)
  --campaign: string # optional campaign name
  --data-field: string # optional extra data
]: nothing -> any {
  http-request {
    method: get
    path: "/api/rest/v1/sms/send-url-parameters"
    query: [{name: recipientNumber, var: recipient_number, required: true}, {name: message, var: message, required: true}, {name: dateToSend, var: date_to_send}, {name: campaign, var: campaign}, {name: dataField, var: data_field}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    recipient_number: $recipient_number, message: $message, date_to_send: $date_to_send, campaign: $campaign, data_field: $data_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# send-url-parameters
#
# POST /api/rest/v1/sms/send-url-parameters
# Returns: string
export def "post-api-rest-v1-sms-send-url-parameters" [
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
  --recipient-number: string # the phone number of the recipient to send to (required)
  --message: string # the message to send (required)
  --date-to-send: string # date format: yyyyMMddHHmm (format: date-time)
  --campaign: string # optional campaign name
  --data-field: string # optional extra data
]: nothing -> any {
  http-request {
    method: post
    path: "/api/rest/v1/sms/send-url-parameters"
    query: [{name: recipientNumber, var: recipient_number, required: true}, {name: message, var: message, required: true}, {name: dateToSend, var: date_to_send}, {name: campaign, var: campaign}, {name: dataField, var: data_field}]
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    recipient_number: $recipient_number, message: $message, date_to_send: $date_to_send, campaign: $campaign, data_field: $data_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# send-url
#
# GET /api/rest/v1/sms/send-url/{token}
# Returns: string
export def "get-api-rest-v1-sms-send-url-token" [
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
  --recipient-number: string # the phone number of the recipient to send to (required)
  --message: string # the message to send (required)
  --date-to-send: string # date format: yyyyMMddHHmm (format: date-time)
  --campaign: string # optional campaign name
  --data-field: string # optional extra data
]: nothing -> any {
  http-request {
    method: get
    path: "/api/rest/v1/sms/send-url/{token}"
    path_params: [{name: token, var: token_arg}]
    query: [{name: recipientNumber, var: recipient_number, required: true}, {name: message, var: message, required: true}, {name: dateToSend, var: date_to_send}, {name: campaign, var: campaign}, {name: dataField, var: data_field}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    token_arg: $token_arg, recipient_number: $recipient_number, message: $message, date_to_send: $date_to_send, campaign: $campaign, data_field: $data_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# send-url
#
# POST /api/rest/v1/sms/send-url/{token}
# Returns: string
export def "post-api-rest-v1-sms-send-url-token" [
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
  --recipient-number: string # the phone number of the recipient to send to (required)
  --message: string # the message to send (required)
  --date-to-send: string # date format: yyyyMMddHHmm (format: date-time)
  --campaign: string # optional campaign name
  --data-field: string # optional extra data
]: nothing -> any {
  http-request {
    method: post
    path: "/api/rest/v1/sms/send-url/{token}"
    path_params: [{name: token, var: token_arg}]
    query: [{name: recipientNumber, var: recipient_number, required: true}, {name: message, var: message, required: true}, {name: dateToSend, var: date_to_send}, {name: campaign, var: campaign}, {name: dataField, var: data_field}]
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    token_arg: $token_arg, recipient_number: $recipient_number, message: $message, date_to_send: $date_to_send, campaign: $campaign, data_field: $data_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# all
#
# GET /api/rest/v1/templates/all
# Returns: record<links: table<href: string, rel: string, templated: bool>, webServiceTemplates: table<data: string, links: list, name: string, templateId: int>>
export def "get-api-rest-v1-templates-all" [
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
    path: "/api/rest/v1/templates/all"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# delete
#
# DELETE /api/rest/v1/templates/{templateId}
export def "delete-api-rest-v1-templates-template-id" [
  template_id: int
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
    path: "/api/rest/v1/templates/{templateId}"
    path_params: [{name: templateId, var: template_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 204]
    auth: email
  } {
    template_id: $template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get
#
# GET /api/rest/v1/templates/{templateId}
# Returns: record<data: string, links: table<href: string, rel: string, templated: bool>, name: string, templateId: int>
export def "get-api-rest-v1-templates-template-id" [
  template_id: int
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
    path: "/api/rest/v1/templates/{templateId}"
    path_params: [{name: templateId, var: template_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    template_id: $template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# all
#
# GET /api/rest/v1/voice/all
# Returns: record<elements: int, links: table<href: string, rel: string, templated: bool>, messages: table<audioFileUrl: string, campaign: string, dateTimeSent: string, deleted: bool, language: string, links: list, message: string, messageStatus: string, toNumber: string, userDataField: string, voiceMessageId: string>, page: int, pageSize: int, totalElements: int, totalPages: int>
export def "get-api-rest-v1-voice-all" [
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
  --page-size: int # number of elements to return at a time (format: int32, default: 100)
  --page: int # page number (format: int32, default: 1)
  --status: string@status-completer # filter by message status
  --from-date-time-sent: string # date format: yyyyMMdd (format: date-time)
  --to-date-time-sent: string # date format: yyyyMMdd (format: date-time)
  --to-number: string # phone number the message was sent to
  --message: string # search matching message text
  --campaign: string # search by campaign
  --data-field: string # search by data field
  --deleted: oneof<nothing, bool> # return only deleted / not deleted messages
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/voice/all"
    query: [{name: pageSize, var: page_size}, {name: page, var: page}, {name: status, var: status}, {name: fromDateTimeSent, var: from_date_time_sent}, {name: toDateTimeSent, var: to_date_time_sent}, {name: toNumber, var: to_number}, {name: message, var: message}, {name: campaign, var: campaign}, {name: dataField, var: data_field}, {name: deleted, var: deleted}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    page_size: $page_size, page: $page, status: $status, from_date_time_sent: $from_date_time_sent, to_date_time_sent: $to_date_time_sent, to_number: $to_number, message: $message, campaign: $campaign, data_field: $data_field, deleted: $deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# single-audio
#
# POST /api/rest/v1/voice/single-audio
# Returns: record<error: string, voiceMessageId: string>
# operationId: single-audio
export def "single-audio" [
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
  --recipient-number: string # the phone number of the recipient to send to (required)
  --campaign: string # optional campaign name
  --data-field: string # optional extra data
  --retry-count: int # optional number of times to retry unanswered call (format: int32)
  --retry-minimum-interval: int # optional minimum interval in minutes between retry attempts (format: int32)
  --retry-maximum-interval: int # optional maximum interval in minutes between retry attempts (format: int32)
  file: path # audio file to play, supports MP3 or WAV format
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rest/v1/voice/single-audio"
    query: [{name: recipientNumber, var: recipient_number, required: true}, {name: campaign, var: campaign}, {name: dataField, var: data_field}, {name: retryCount, var: retry_count}, {name: retryMinimumInterval, var: retry_minimum_interval}, {name: retryMaximumInterval, var: retry_maximum_interval}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    recipient_number: $recipient_number, campaign: $campaign, data_field: $data_field, retry_count: $retry_count, retry_minimum_interval: $retry_minimum_interval, retry_maximum_interval: $retry_maximum_interval, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# single-text
#
# POST /api/rest/v1/voice/single-text
# Returns: record<error: string, voiceMessageId: string>
# operationId: single-text
export def "single-text" [
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
  --campaign: string
  --data-field: string
  --language: string
  --message: string
  --recipient-number: string
  --retry-count: int # format: int32
  --retry-maximum-interval: int # format: int32
  --retry-minimum-interval: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rest/v1/voice/single-text"
    body: {content_type: "application/json", kind: json, fields: [{name: campaign, var: campaign}, {name: dataField, var: data_field}, {name: language, var: language}, {name: message, var: message}, {name: recipientNumber, var: recipient_number}, {name: retryCount, var: retry_count}, {name: retryMaximumInterval, var: retry_maximum_interval}, {name: retryMinimumInterval, var: retry_minimum_interval}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: email
  } {
    campaign: $campaign, data_field: $data_field, language: $language, message: $message, recipient_number: $recipient_number, retry_count: $retry_count, retry_maximum_interval: $retry_maximum_interval, retry_minimum_interval: $retry_minimum_interval
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# delete
#
# DELETE /api/rest/v1/voice/{messageId}
export def "delete-api-rest-v1-voice-message-id" [
  message_id: string
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
    path: "/api/rest/v1/voice/{messageId}"
    path_params: [{name: messageId, var: message_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 204]
    auth: email
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# get
#
# GET /api/rest/v1/voice/{messageId}
# Returns: record<audioFileUrl: string, campaign: string, dateTimeSent: string, deleted: bool, language: string, links: table<href: string, rel: string, templated: bool>, message: string, messageStatus: string, toNumber: string, userDataField: string, voiceMessageId: string>
export def "get-api-rest-v1-voice-message-id" [
  message_id: string
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
    path: "/api/rest/v1/voice/{messageId}"
    path_params: [{name: messageId, var: message_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: email
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
