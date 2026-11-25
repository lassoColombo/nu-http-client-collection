# Auto-generated client for Getty Images v3
# Source: https://api.apis.guru/v2/specs/gettyimages.com/3/openapi.json
# Auth: --token flag or $env.GETTY_IMAGES_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru"
  token_env_var: "GETTY_IMAGES_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: api-key, in: header, header_name: Api-Key, prefix: ""}
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

def base-url-completer [] { ["https://api.apis.guru"] }
def auth-scheme-completer [] { ["api-key" "bearer"] }

# Completers for enum parameters
def style-completer [] { ["photography" "vector"] }
def accept-completer [] { ["application/json" "text/json" "text/plain"] }
def board-relationship-completer [] { ["invited" "owned"] }
def sort-order-completer [] { ["date_last_updated_ascending" "date_last_updated_descending" "name_ascending" "name_decending"] }
def product-type-completer [] { ["creditpack" "easyaccess" "editorialsubscription" "imagepack" "premiumaccess" "royaltyfreesubscription"] }
def file-type-completer [] { ["eps" "jpg"] }
def editorial-segment-completer [] { ["archival" "entertainment" "news" "publicity" "royalty" "sport"] }
def sort-order-completer-1 [] { ["newest" "oldest"] }
def collections-filter-type-completer [] { ["exclude" "include"] }
def graphical-styles-filter-type-completer [] { ["exclude" "include"] }
def minimum-size-completer [] { ["large" "medium" "small" "vector" "x_large" "x_small" "xx_large"] }
def sort-order-completer-2 [] { ["best_match" "most_popular" "newest" "random"] }
def sort-order-completer-3 [] { ["best_match" "most_popular" "newest" "oldest" "random"] }
def format-available-completer [] { ["4k" "hd" "hd_web" "sd"] }
def release-status-completer [] { ["fully_released" "release_not_important"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-v3-affiliates-search-images: "record<auto_corrections: record<phrase: string>, images: table<caption: string, destination_url: string, id: string, preview_urls: record, title: string>>"
    get-v3-affiliates-search-videos: "record<auto_corrections: record<phrase: string>, videos: table<caption: string, clip_length: string, destination_url: string, id: string, preview_urls: record, title: string>>"
    put-v3-asset-changes-change-sets: "record<change_set_id: string, changed_assets: table<asset_changed_utc_datetime: string, asset_lifecycle: string, asset_type: string, id: string, uri: string>>"
    get-v3-asset-changes-channels: "table<AssetChangeType: string, AssetFamily: string, AssetType: string, ChannelId: int, CreateDateUtc: string, Metadata: string, NotificationCount: int, OldestChangeNotificationDateUtc: string>"
    post-v3-asset-licensing-asset-id: "record<acquired_licenses: list<string>, credits_used: int>"
    get-v3-asset-management-assets-send-events: "record<asset_send_events: table<asset_id: string, email_address: string, timestamp: string>, last_offset: string>"
    get-v3-boards: "record<board_count: int, boards: table<asset_count: int, board_relationship: string, date_created: string, date_last_updated: string, description: string, hero_asset: record, id: string, name: string>>"
    post-v3-boards: "record<id: string>"
    get-v3-boards-board-id: "record<asset_count: int, assets: table<asset_type: string, date_added: string, display_sizes: list, id: string>, comment_count: int, date_created: string, date_last_updated: string, description: string, id: string, links: record<invitation: string, share: string>, name: string, permissions: record<can_add_assets: bool, can_delete_board: bool, can_invite_to_board: bool, can_remove_assets: bool, can_update_description: bool, can_update_name: bool>>"
    put-v3-boards-board-id-assets: "record<assets_added: table<asset_id: string>, assets_not_added: list<string>>"
    get-v3-boards-board-id-comments: "record<comments: table<created_by: record, date_created: string, id: string, permissions: record, text: string>, permissions: record<can_add_comment: bool>>"
    post-v3-boards-board-id-comments: "record<id: string>"
    get-v3-collections: "record<collections: table<asset_family: string, code: string, id: int, license_model: string, name: string, product_types: list>>"
    get-v3-countries: "record<countries: table<iso_alpha_2: string, iso_alpha_3: string, name: string>>"
    get-v3-customers-current: "record<first_name: string, last_name: string, middle_name: string>"
    get-v3-downloads: "record<downloads: table<agreement_name: string, asset_type: string, date_downloaded: string, dimensions: record, download_details: record, download_source: string, id: string, product_id: int, product_type: string, size_name: string, thumb_uri: string, user: record>, result_count: int>"
    get-v3-images: "record<images: any, images_not_found: list<string>>"
    get-v3-images-id: "record<images: any, images_not_found: list<string>>"
    get-v3-images-id-downloadhistory: "record<downloads: any, id: string>"
    get-v3-images-id-same-series: "record<images: table<allowed_use: record, alternative_ids: record, artist: string, asset_family: string, call_for_image: bool, caption: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_camera_shot: string, date_created: string, display_sizes: list, download_product: string, editorial_segments: list, event_ids: list, graphical_style: string, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, max_dimensions: record, orientation: string, people: list, product_types: list, quality_rank: int, referral_destinations: list, title: string, uri_oembed: string>, related_searches: table<phrase: string, url: string>, result_count: int>"
    get-v3-images-id-similar: "record<images: table<allowed_use: record, alternative_ids: record, artist: string, asset_family: string, call_for_image: bool, caption: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_camera_shot: string, date_created: string, display_sizes: list, download_product: string, editorial_segments: list, event_ids: list, graphical_style: string, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, max_dimensions: record, orientation: string, people: list, product_types: list, quality_rank: int, referral_destinations: list, title: string, uri_oembed: string>, related_searches: table<phrase: string, url: string>, result_count: int>"
    get-v3-orders-id: "record<assets: table<id: string>, end_client: string, id: string, invoice_number: string, notes: record<licensee_name: string, ordered_by: string, project_title: string, purchase_order_number: string>, order_date: string>"
    get-v3-products: "record<products: table<agreement_name: string, application_website: string, credits_remaining: int, download_limit: int, download_limit_duration: string, download_limit_reset_utc_date: string, download_requirements: record, downloads_remaining: int, expiration_utc_date: string, id: int, imagepack_resolution: string, name: string, overage: record, status: string, team_credits: int, type: string>>"
    get-v3-purchased-assets: "record<previous_purchases: table<asset_id: string, asset_type: string, date_purchased: string, download_uri: string, file_size_in_bytes: string, license_model: string, order_id: string, purchased_by: string, size_name: string, thumb_uri: string>, result_count: int>"
    get-v3-search-events: "record<events: table<child_event_count: int, editorial_segments: list, hero_image: record, id: int, image_count: int, location: record, name: string, start_date: string>, result_count: int>"
    get-v3-search-images: "record<images: table<allowed_use: record, alternative_ids: record, artist: string, asset_family: string, call_for_image: bool, caption: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_camera_shot: string, date_created: string, display_sizes: list, download_product: string, editorial_segments: list, event_ids: list, graphical_style: string, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, max_dimensions: record, orientation: string, people: list, product_types: list, quality_rank: int, referral_destinations: list, title: string, uri_oembed: string>, related_searches: table<phrase: string, url: string>, result_count: int>"
    get-v3-search-images-creative: "record<auto_corrections: record<phrase: string>, images: table<allowed_use: record, alternative_ids: record, artist: string, asset_family: string, call_for_image: bool, caption: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_camera_shot: string, date_created: string, display_sizes: list, download_product: string, graphical_style: string, id: string, keywords: list, largest_downloads: list, license_model: string, max_dimensions: record, orientation: string, quality_rank: int, referral_destinations: list, title: string, uri_oembed: string>, related_searches: table<phrase: string, url: string>, result_count: int>"
    get-v3-search-images-creative-by-image: "record<auto_corrections: record<phrase: string>, facets: record<artists: list<record>, entertainment: list<record>, events: list<record>, locations: list<record>, specific_people: list<record>>, image_fingerprint: string, images: any, related_searches: table<phrase: string, url: string>, result_count: int>"
    get-v3-search-images-editorial: "record<images: table<allowed_use: record, alternative_ids: record, artist: string, asset_family: string, call_for_image: bool, caption: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_camera_shot: string, date_created: string, display_sizes: list, download_product: string, editorial_segments: list, editorial_source: record, event_ids: list, graphical_style: string, id: string, keywords: list, largest_downloads: list, license_model: string, max_dimensions: record, orientation: string, people: list, product_types: list, quality_rank: int, referral_destinations: list, title: string, uri_oembed: string>, related_searches: table<phrase: string, url: string>, result_count: int>"
    get-v3-search-videos-creative: "record<auto_corrections: record<phrase: string>, facets: record<artists: list<record>, entertainment: list<record>, events: list<record>, locations: list<record>, specific_people: list<record>>, related_searches: table<phrase: string, url: string>, result_count: int, videos: table<allowed_use: record, artist: string, asset_family: string, caption: string, clip_length: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_created: string, display_sizes: list, download_product: string, era: string, event_ids: list, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, mastered_to: string, originally_shot_on: string, product_types: list, referral_destinations: list, shot_speed: string, title: string>>"
    get-v3-search-videos-creative-by-image: "record<auto_corrections: record<phrase: string>, facets: record<artists: list<record>, entertainment: list<record>, events: list<record>, locations: list<record>, specific_people: list<record>>, related_searches: table<phrase: string, url: string>, result_count: int, videos: table<allowed_use: record, artist: string, asset_family: string, caption: string, clip_length: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_created: string, display_sizes: list, download_product: string, era: string, event_ids: list, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, mastered_to: string, originally_shot_on: string, product_types: list, referral_destinations: list, shot_speed: string, title: string>>"
    get-v3-search-videos-editorial: "record<facets: record<artists: list<record>, entertainment: list<record>, events: list<record>, locations: list<record>, specific_people: list<record>>, related_searches: table<phrase: string, url: string>, result_count: int, videos: table<allowed_use: record, artist: string, asset_family: string, caption: string, clip_length: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_created: string, display_sizes: list, download_product: string, era: string, event_ids: list, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, mastered_to: string, originally_shot_on: string, product_types: list, referral_destinations: list, shot_speed: string, source: string, title: string>>"
    put-v3-usage-batches-id: "record<invalid_assets: list<string>, total_asset_usages_processed: int>"
    get-v3-videos-id-downloadhistory: "record<downloads: any, id: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-v3-affiliates-search-images" "get-v3-affiliates-search-videos" "get-v3-artists-images" "get-v3-artists-videos" "put-v3-asset-changes-change-sets" "delete-v3-asset-changes-change-sets-change-set-id" "get-v3-asset-changes-channels" "post-v3-asset-licensing-asset-id" "get-v3-asset-management-assets-send-events" "get-v3-boards" "post-v3-boards" "delete-v3-boards-board-id" "get-v3-boards-board-id" "put-v3-boards-board-id" "delete-v3-boards-board-id-assets" "put-v3-boards-board-id-assets" "delete-v3-boards-board-id-assets-asset-id" "put-v3-boards-board-id-assets-asset-id" "get-v3-boards-board-id-comments" "post-v3-boards-board-id-comments" "delete-v3-boards-board-id-comments-comment-id" "get-v3-collections" "get-v3-countries" "get-v3-customers-current" "get-v3-downloads" "post-v3-downloads-images-id" "post-v3-downloads-videos-id" "get-v3-events" "get-v3-events-id" "get-v3-images" "get-v3-images-id" "get-v3-images-id-downloadhistory" "get-v3-images-id-same-series" "get-v3-images-id-similar" "get-v3-orders-id" "get-v3-products" "get-v3-purchased-assets" "put-v3-search-by-image-uploads-file-name" "get-v3-search-events" "get-v3-search-images" "get-v3-search-images-creative" "get-v3-search-images-creative-by-image" "get-v3-search-images-editorial" "get-v3-search-videos-creative" "get-v3-search-videos-creative-by-image" "get-v3-search-videos-editorial" "put-v3-usage-batches-id" "get-v3-videos" "get-v3-videos-id" "get-v3-videos-id-downloadhistory" "get-v3-videos-id-same-series" "get-v3-videos-id-similar" "commands"] | sort) } | get name | first)
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

# GET /v3/affiliates/search/images
#
# Returns: record<auto_corrections: record<phrase: string>, images: table<caption: string, destination_url: string, id: string, preview_urls: record, title: string>>
export def "get-v3-affiliates-search-images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --phrase: string # Search images using a search phrase. (nullable)
  --style: string@style-completer # Filter based on graphical style of the image.
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/affiliates/search/images"
    query: [{name: phrase, var: phrase}, {name: style, var: style}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    phrase: $phrase, style: $style, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v3/affiliates/search/videos
#
# Returns: record<auto_corrections: record<phrase: string>, videos: table<caption: string, clip_length: string, destination_url: string, id: string, preview_urls: record, title: string>>
export def "get-v3-affiliates-search-videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --phrase: string # nullable
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/affiliates/search/videos"
    query: [{name: phrase, var: phrase}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    phrase: $phrase, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for images by a photographer
#
# GET /v3/artists/images
export def "get-v3-artists-images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --artist-name: string # Name of artist for desired images (nullable)
  --fields: list<string> # Comma separated list of fields. Allows restricting which fields are returned. If no fields are selected, the summary_set of fields are returned. (nullable)
  --page: int # Identifies page to return. Default page is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default page_size is 10, maximum page_size is 100. (format: int32, default: 10)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  http-request {
    method: get
    path: "/v3/artists/images"
    query: [{name: artist_name, var: artist_name}, {name: fields, var: fields, style: csv}, {name: page, var: page}, {name: page_size, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    artist_name: $artist_name, fields: $fields, page: $page, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for videos by a photographer
#
# GET /v3/artists/videos
export def "get-v3-artists-videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --artist-name: string # Name of artist for desired images (nullable)
  --fields: list<string> # Comma separated list of fields. Allows restricting which fields are returned. If no fields are selected, the summary_set of fields are returned. (nullable)
  --page: int # Identifies page to return. Default page is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default page_size is 10, maximum page_size is 100. (format: int32, default: 10)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  http-request {
    method: get
    path: "/v3/artists/videos"
    query: [{name: artist_name, var: artist_name}, {name: fields, var: fields, style: csv}, {name: page, var: page}, {name: page_size, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    artist_name: $artist_name, fields: $fields, page: $page, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get asset change notifications.
#
# PUT /v3/asset-changes/change-sets
# Returns: record<change_set_id: string, changed_assets: table<asset_changed_utc_datetime: string, asset_lifecycle: string, asset_type: string, id: string, uri: string>>
export def "put-v3-asset-changes-change-sets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-id: int # Specifies the id of the channel for the asset data. Valid channel ids can be found in the results of the Get Partner Channel query. (format: int32)
  --batch-size: int # Specifies the number of assets to return. The default is 2200; maximum is 2200. (nullable, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/v3/asset-changes/change-sets"
    query: [{name: channel_id, var: channel_id}, {name: batch_size, var: batch_size}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: api-key
  } {
    channel_id: $channel_id, batch_size: $batch_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirm asset change notifications.
#
# DELETE /v3/asset-changes/change-sets/{change-set-id}
export def "delete-v3-asset-changes-change-sets-change-set-id" [
  change_set_id: int
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
    path: "/v3/asset-changes/change-sets/{change-set-id}"
    path_params: [{name: change-set-id, var: change_set_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    change_set_id: $change_set_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of asset change notification channels.
#
# GET /v3/asset-changes/channels
# Returns: table<AssetChangeType: string, AssetFamily: string, AssetType: string, ChannelId: int, CreateDateUtc: string, Metadata: string, NotificationCount: int, OldestChangeNotificationDateUtc: string>
export def "get-v3-asset-changes-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v3/asset-changes/channels"
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Endpoint for acquiring extended licenses with iStock credits for an asset.
#
# POST /v3/asset-licensing/{assetId}
# Returns: record<acquired_licenses: list<string>, credits_used: int>
export def "post-v3-asset-licensing-asset-id" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  extended_licenses: list<string>
  --use-team-credits: oneof<nothing, bool> # Defaults to false.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/asset-licensing/{assetId}"
    path_params: [{name: assetId, var: asset_id}]
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: extended_licenses, var: extended_licenses}, {name: use_team_credits, var: use_team_credits}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    asset_id: $asset_id, accept_language: $accept_language, extended_licenses: $extended_licenses, use_team_credits: $use_team_credits
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v3/asset-management/assets/send-events
#
# Returns: record<asset_send_events: table<asset_id: string, email_address: string, timestamp: string>, last_offset: string>
export def "get-v3-asset-management-assets-send-events" [
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
  --last-offset: string # Specifies a date/time (with timezone information) for continuing retrieval of events. Events occuring _after_ the `last_offset` value provided will be returned. (nullable, format: date-time)
  --event-count: int # Specifies the number of events to return. Default is 50, maximum value is 100. (nullable, format: int32)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/asset-management/assets/send-events"
    query: [{name: last_offset, var: last_offset}, {name: event_count, var: event_count}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: api-key
  } {
    last_offset: $last_offset, event_count: $event_count, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all boards that the user participates in
#
# GET /v3/boards
# Returns: record<board_count: int, boards: table<asset_count: int, board_relationship: string, date_created: string, date_last_updated: string, description: string, hero_asset: record, id: string, name: string>>
export def "get-v3-boards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Request results starting at a page number (default is 1). (format: int32, default: 1)
  --board-relationship: string@board-relationship-completer # Search for boards the user owns or has been invited to as an editor.
  --sort-order: string@sort-order-completer # Sort the list of boards by last update date or name. Defaults to date_last_updated_descending.
  --page-size: int # Request number of boards to return in each page. (default is 30). (format: int32, default: 30)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/boards"
    query: [{name: page, var: page}, {name: board_relationship, var: board_relationship}, {name: sort_order, var: sort_order}, {name: pageSize, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    page: $page, board_relationship: $board_relationship, sort_order: $sort_order, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new board
#
# POST /v3/boards
# Returns: record<id: string>
export def "post-v3-boards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --description: string # nullable
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/boards"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: api-key
  } {
    accept_language: $accept_language, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a board
#
# DELETE /v3/boards/{board_id}
export def "delete-v3-boards-board-id" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  http-request {
    method: delete
    path: "/v3/boards/{board_id}"
    path_params: [{name: board_id, var: board_id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: api-key
  } {
    board_id: $board_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get assets and metadata for a specific board
#
# GET /v3/boards/{board_id}
# Returns: record<asset_count: int, assets: table<asset_type: string, date_added: string, display_sizes: list, id: string>, comment_count: int, date_created: string, date_last_updated: string, description: string, id: string, links: record<invitation: string, share: string>, name: string, permissions: record<can_add_assets: bool, can_delete_board: bool, can_invite_to_board: bool, can_remove_assets: bool, can_update_description: bool, can_update_name: bool>>
export def "get-v3-boards-board-id" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/boards/{board_id}"
    path_params: [{name: board_id, var: board_id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    board_id: $board_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a board
#
# PUT /v3/boards/{board_id}
export def "put-v3-boards-board-id" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --description: string # nullable
  name: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/boards/{board_id}"
    path_params: [{name: board_id, var: board_id}]
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: api-key
  } {
    board_id: $board_id, accept_language: $accept_language, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove assets from a board
#
# DELETE /v3/boards/{board_id}/assets
export def "delete-v3-boards-board-id-assets" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-ids: list<string> # List the assets to be removed from the board. (nullable)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  http-request {
    method: delete
    path: "/v3/boards/{board_id}/assets"
    path_params: [{name: board_id, var: board_id}]
    query: [{name: asset_ids, var: asset_ids, style: multi}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    board_id: $board_id, asset_ids: $asset_ids, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add assets to a board
#
# PUT /v3/boards/{board_id}/assets
# Returns: record<assets_added: table<asset_id: string>, assets_not_added: list<string>>
export def "put-v3-boards-board-id-assets" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/boards/{board_id}/assets"
    path_params: [{name: board_id, var: board_id}]
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: api-key
  } {
    board_id: $board_id, accept_language: $accept_language, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an asset from a board
#
# DELETE /v3/boards/{board_id}/assets/{asset_id}
export def "delete-v3-boards-board-id-assets-asset-id" [
  board_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  http-request {
    method: delete
    path: "/v3/boards/{board_id}/assets/{asset_id}"
    path_params: [{name: board_id, var: board_id}, {name: asset_id, var: asset_id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    board_id: $board_id, asset_id: $asset_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an asset to a board
#
# PUT /v3/boards/{board_id}/assets/{asset_id}
export def "put-v3-boards-board-id-assets-asset-id" [
  board_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  http-request {
    method: put
    path: "/v3/boards/{board_id}/assets/{asset_id}"
    path_params: [{name: board_id, var: board_id}, {name: asset_id, var: asset_id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [201]
    auth: api-key
  } {
    board_id: $board_id, asset_id: $asset_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get comments from a board
#
# GET /v3/boards/{board_id}/comments
# Returns: record<comments: table<created_by: record, date_created: string, id: string, permissions: record, text: string>, permissions: record<can_add_comment: bool>>
export def "get-v3-boards-board-id-comments" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/boards/{board_id}/comments"
    path_params: [{name: board_id, var: board_id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    board_id: $board_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a comment to a board
#
# POST /v3/boards/{board_id}/comments
# Returns: record<id: string>
export def "post-v3-boards-board-id-comments" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --text: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/boards/{board_id}/comments"
    path_params: [{name: board_id, var: board_id}]
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/json"]
    ok: [201]
    auth: api-key
  } {
    board_id: $board_id, accept_language: $accept_language, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a comment from a board
#
# DELETE /v3/boards/{board_id}/comments/{comment_id}
export def "delete-v3-boards-board-id-comments-comment-id" [
  board_id: string
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  http-request {
    method: delete
    path: "/v3/boards/{board_id}/comments/{comment_id}"
    path_params: [{name: board_id, var: board_id}, {name: comment_id, var: comment_id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: api-key
  } {
    board_id: $board_id, comment_id: $comment_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets collections applicable for the customer.
#
# GET /v3/collections
# Returns: record<collections: table<asset_family: string, code: string, id: int, license_model: string, name: string, product_types: list>>
export def "get-v3-collections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/collections"
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets countries codes and names.
#
# GET /v3/countries
# Returns: record<countries: table<iso_alpha_2: string, iso_alpha_3: string, name: string>>
export def "get-v3-countries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/countries"
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the current user.
#
# GET /v3/customers/current
# Returns: record<first_name: string, last_name: string, middle_name: string>
export def "get-v3-customers-current" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/customers/current"
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a customer's downloaded assets.
#
# GET /v3/downloads
# Returns: record<downloads: table<agreement_name: string, asset_type: string, date_downloaded: string, dimensions: record, download_details: record, download_source: string, id: string, product_id: int, product_type: string, size_name: string, thumb_uri: string, user: record>, result_count: int>
export def "get-v3-downloads" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # If specified, selects assets downloaded on or after this date. Dates should be submitted in ISO 8601 format (i.e., YYYY-MM-DD). Any hour, minute, second values in the request are not used, unless useTimePart parameter is included. Date/times in the response are UTC. Default is 30 days prior to date_to (nullable, format: date-time)
  --date-to: string # If specified, selects assets downloaded on or before this date. Dates should be submitted in ISO 8601 format (i.e., YYYY-MM-DD) Any hour, minute, second values in the request are not used, unless useTimePart parameter is included. Date/times in the response are UTC. Default is current date or 30 days after specified start date, whichever one is earlier. (nullable, format: date-time)
  --use-time: oneof<nothing, bool> # If specified, time values provided with date_to or date_from will be used. Time values should be appended to the date value in ISO 8601 format i.e.: 2019-09-19T19:30:37 or 2019-09-19 19:30:37. Time zone can be specified as optional. Default value is false (default: false)
  --page: int # Identifies page to return. Default is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --product-type: string@product-type-completer # Specifies product type to be included in the previous download results. Product types easyaccess, editorialsubscription, imagepack, and premiumaccess are for GettyImages API keys. Product types royaltyfreesubscription and creditpack are for iStock API keys. To get previous iStockPhoto credit downloads, creditpack must be selected.
  --company-downloads: oneof<nothing, bool> # If specified, returns the list of previously downloaded images for all users in your company. Your account must be enabled for this functionality. Contact your Getty Images account rep for more information. Default is false. (default: false)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/downloads"
    query: [{name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: use_time, var: use_time}, {name: page, var: page}, {name: page_size, var: page_size}, {name: product_type, var: product_type}, {name: company_downloads, var: company_downloads}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    date_from: $date_from, date_to: $date_to, use_time: $use_time, page: $page, page_size: $page_size, product_type: $product_type, company_downloads: $company_downloads, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download an image
#
# POST /v3/downloads/images/{id}
export def "post-v3-downloads-images-id" [
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
  --auto-download: oneof<nothing, bool> # Specifies whether to auto-download the image. If true is specified, a 303 SeeOther status is returned with a Location header set to the location of the image. If false is specified, the download URI will be returned in the response message. Default is true. (default: true)
  --file-type: string@file-type-completer # File Type expressed with three character file extension.
  --height: string # Specifies the pixel height of the particular image to download. Available heights can be found in the images/{ids} response for the specific image. If left blank, it will return the largest available size. (nullable)
  --product-id: int # Identifier of the instance for the selected product offering type. (nullable, format: int32)
  --product-type: string@product-type-completer # Product types easyaccess, editorialsubscription, imagepack, and premiumaccess are for GettyImages API keys. Product types royaltyfreesubscription and creditpack are for iStock API keys. Default product type for iStock API keys is creditpack.
  --use-team-credits: oneof<nothing, bool> # Specifies whether to download the image with iStock Team Credits. Only applicable to iStock API keys authenticated with a user that has Team Credits. Blank is the same as False. (nullable, default: false)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --download-notes: string # nullable
  --project-code: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/downloads/images/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: auto_download, var: auto_download}, {name: file_type, var: file_type}, {name: height, var: height}, {name: product_id, var: product_id}, {name: product_type, var: product_type}, {name: use_team_credits, var: use_team_credits}]
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: download_notes, var: download_notes}, {name: project_code, var: project_code}]}
    accept: ["application/json"]
    ok: [200, 303]
    auth: api-key
  } {
    id: $id, auto_download: $auto_download, file_type: $file_type, height: $height, product_id: $product_id, product_type: $product_type, use_team_credits: $use_team_credits, accept_language: $accept_language, download_notes: $download_notes, project_code: $project_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a video
#
# POST /v3/downloads/videos/{id}
export def "post-v3-downloads-videos-id" [
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
  --auto-download: oneof<nothing, bool> # Specifies whether to auto-download the video. If true is specified, a 303 SeeOther status is returned with a Location header set to the location of the video. If false is specified, the download URI will be returned in the response message. Default is false. (default: false)
  --size: string # Specifies the size to be downloaded. (nullable)
  --product-id: int # Identifier of the instance for the selected product offering type. (nullable, format: int32)
  --product-type: string@product-type-completer # Product types easyaccess, editorialsubscription, imagepack, and premiumaccess are for GettyImages API keys. Product types royaltyfreesubscription and creditpack are for iStock API keys. Default product type for iStock API keys is creditpack.
  --use-team-credits: oneof<nothing, bool> # Specifies whether to download the image with iStock Team Credits. Only applicable to iStock API keys authenticated with a user that has Team Credits. Blank is the same as False. (nullable)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --download-notes: string # nullable
  --project-code: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/downloads/videos/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: auto_download, var: auto_download}, {name: size, var: size}, {name: product_id, var: product_id}, {name: product_type, var: product_type}, {name: use_team_credits, var: use_team_credits}]
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: download_notes, var: download_notes}, {name: project_code, var: project_code}]}
    accept: ["application/json"]
    ok: [200, 303]
    auth: api-key
  } {
    id: $id, auto_download: $auto_download, size: $size, product_id: $product_id, product_type: $product_type, use_team_credits: $use_team_credits, accept_language: $accept_language, download_notes: $download_notes, project_code: $project_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata for multiple events
#
# GET /v3/events
export def "get-v3-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # A comma separated list of event ids. (nullable)
  --fields: list<string> # A comma separated list of fields to return in the response. (nullable)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  http-request {
    method: get
    path: "/v3/events"
    query: [{name: ids, var: ids, style: csv}, {name: fields, var: fields, style: csv}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    ids: $ids, fields: $fields, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata for a single event
#
# GET /v3/events/{id}
export def "get-v3-events-id" [
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
  --fields: list<string> # A comma separated list of fields to return in the response. (nullable)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  http-request {
    method: get
    path: "/v3/events/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields, style: csv}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    id: $id, fields: $fields, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata for multiple images by supplying multiple image ids
#
# GET /v3/images
# Returns: record<images: any, images_not_found: list<string>>
export def "get-v3-images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # Specifies one or more image ids to return. Use comma delimiter when requesting multiple ids. Maximum of 100 ids. (nullable)
  --fields: list<string> # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes, height, and width returned by 'download_sizes' field are estimates. (nullable)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/images"
    query: [{name: ids, var: ids, style: csv}, {name: fields, var: fields, style: csv}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    ids: $ids, fields: $fields, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata for a single image by supplying one image id
#
# GET /v3/images/{id}
# Returns: record<images: any, images_not_found: list<string>>
export def "get-v3-images-id" [
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
  --fields: list<string> # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes, height, and width returned by 'download_sizes' field are estimates. (nullable)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/images/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields, style: csv}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    id: $id, fields: $fields, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a customer's download history for a specific asset
#
# GET /v3/images/{id}/downloadhistory
# Returns: record<downloads: any, id: string>
export def "get-v3-images-id-downloadhistory" [
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
  --company-downloads: oneof<nothing, bool> # If specified, returns the list of previously downloaded images for all users in your company. Your account must be enabled for this functionality. Contact your Getty Images account rep for more information. Default is false.
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/images/{id}/downloadhistory"
    path_params: [{name: id, var: id}]
    query: [{name: company_downloads, var: company_downloads}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    id: $id, company_downloads: $company_downloads, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve creative images from the same series
#
# GET /v3/images/{id}/same-series
# Returns: record<images: table<allowed_use: record, alternative_ids: record, artist: string, asset_family: string, call_for_image: bool, caption: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_camera_shot: string, date_created: string, display_sizes: list, download_product: string, editorial_segments: list, event_ids: list, graphical_style: string, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, max_dimensions: record, orientation: string, people: list, product_types: list, quality_rank: int, referral_destinations: list, title: string, uri_oembed: string>, related_searches: table<phrase: string, url: string>, result_count: int>
export def "get-v3-images-id-same-series" [
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
  --fields: list<string> # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes, height, and width returned by 'download_sizes' field are estimates. (nullable)
  --page: int # Identifies page to return. Default is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/images/{id}/same-series"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields, style: csv}, {name: page, var: page}, {name: page_size, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    id: $id, fields: $fields, page: $page, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve similar images
#
# GET /v3/images/{id}/similar
# Returns: record<images: table<allowed_use: record, alternative_ids: record, artist: string, asset_family: string, call_for_image: bool, caption: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_camera_shot: string, date_created: string, display_sizes: list, download_product: string, editorial_segments: list, event_ids: list, graphical_style: string, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, max_dimensions: record, orientation: string, people: list, product_types: list, quality_rank: int, referral_destinations: list, title: string, uri_oembed: string>, related_searches: table<phrase: string, url: string>, result_count: int>
export def "get-v3-images-id-similar" [
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
  --fields: list<string> # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes, height, and width returned by 'download_sizes' field are estimates. (nullable)
  --page: int # Identifies page to return. Default is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/images/{id}/similar"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields, style: csv}, {name: page, var: page}, {name: page_size, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    id: $id, fields: $fields, page: $page, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get order metadata
#
# GET /v3/orders/{id}
# Returns: record<assets: table<id: string>, end_client: string, id: string, invoice_number: string, notes: record<licensee_name: string, ordered_by: string, project_title: string, purchase_order_number: string>, order_date: string>
export def "get-v3-orders-id" [
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
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/orders/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    id: $id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Products
#
# GET /v3/products
# Returns: record<products: table<agreement_name: string, application_website: string, credits_remaining: int, download_limit: int, download_limit_duration: string, download_limit_reset_utc_date: string, download_requirements: record, downloads_remaining: int, expiration_utc_date: string, id: int, imagepack_resolution: string, name: string, overage: record, status: string, team_credits: int, type: string>>
export def "get-v3-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Comma separated list of fields. Allows product download requirements to be returned. (nullable)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/products"
    query: [{name: fields, var: fields, style: csv}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    fields: $fields, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Previously Purchased Images and Video
#
# GET /v3/purchased-assets
# Returns: record<previous_purchases: table<asset_id: string, asset_type: string, date_purchased: string, download_uri: string, file_size_in_bytes: string, license_model: string, order_id: string, purchased_by: string, size_name: string, thumb_uri: string>, result_count: int>
export def "get-v3-purchased-assets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-to: string # If specified, retrieves previous purchases on or before this date. Dates should be submitted in ISO 8601 format (i.e., YYYY-MM-DD). (nullable, format: date-time)
  --page: int # Identifies page to return. Default is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default is 75, maximum page_size is 100. (format: int32, default: 75)
  --date-from: string # If specified, retrieves previous purchases on or after this date. Dates should be submitted in ISO 8601 format (i.e., YYYY-MM-DD). (nullable, format: date-time)
  --company-purchases: oneof<nothing, bool> # If specified, returns the list of previously purchased assets for all users in your company. Your account must be enabled for this functionality. Contact your Getty Images account rep for more information. Default is false. (default: false)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/purchased-assets"
    query: [{name: date_to, var: date_to}, {name: page, var: page}, {name: page_size, var: page_size}, {name: date_from, var: date_from}, {name: company_purchases, var: company_purchases}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    date_to: $date_to, page: $page, page_size: $page_size, date_from: $date_from, company_purchases: $company_purchases, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload image for use by the search creative images/videos operations
#
# PUT /v3/search/by-image/uploads/{file-name}
export def "put-v3-search-by-image-uploads-file-name" [
  file_name: string
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
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/search/by-image/uploads/{file-name}"
    path_params: [{name: file-name, var: file_name}]
    body: {content_type: "image/jpeg", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    file_name: $file_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for events
#
# GET /v3/search/events
# Returns: record<events: table<child_event_count: int, editorial_segments: list, hero_image: record, id: int, image_count: int, location: record, name: string, start_date: string>, result_count: int>
export def "get-v3-search-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --editorial-segment: string@editorial-segment-completer # Filters to events with a matching editorial segment.
  --date-from: string # Filters to events that start on or after this date. Use ISO 8601 format (e.g., 1999-12-31). Defaults to UTC unless otherwise specified. (nullable, format: date-time)
  --date-to: string # Filters to events that start on or before this date. Use ISO 8601 format (e.g., 1999-12-31). Defaults to UTC unless otherwise specified. (nullable, format: date-time)
  --fields: list<string> # Specifies fields to return. Default set is 'id','name','start_date'. (nullable)
  --page: int # Request results starting at a page number (default is 1, maximum is 50). (format: int32, default: 1)
  --page-size: int # Request number of events to return in each page. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --phrase: string # Filters to events related to this phrase (nullable, default: "")
  --sort-order: string@sort-order-completer-1 # Specifies the order in which to sort the results. Default is `newest`.
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --gi-country-code: string # Receive regionally relevant search results based on the value specified. Accepts only ISO Alpha-3 country codes. The Countries operation can be used to retrieve the codes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/search/events"
    query: [{name: editorial_segment, var: editorial_segment}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: fields, var: fields, style: csv}, {name: page, var: page}, {name: page_size, var: page_size}, {name: phrase, var: phrase}, {name: sort_order, var: sort_order}]
    header: [{name: Accept-Language, var: accept_language}, {name: GI-Country-Code, var: gi_country_code}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    editorial_segment: $editorial_segment, date_from: $date_from, date_to: $date_to, fields: $fields, page: $page, page_size: $page_size, phrase: $phrase, sort_order: $sort_order, accept_language: $accept_language, gi_country_code: $gi_country_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for both creative and editorial images - *** DEPRECATED ***
#
# GET /v3/search/images
# Returns: record<images: table<allowed_use: record, alternative_ids: record, artist: string, asset_family: string, call_for_image: bool, caption: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_camera_shot: string, date_created: string, display_sizes: list, download_product: string, editorial_segments: list, event_ids: list, graphical_style: string, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, max_dimensions: record, orientation: string, people: list, product_types: list, quality_rank: int, referral_destinations: list, title: string, uri_oembed: string>, related_searches: table<phrase: string, url: string>, result_count: int>
export def "get-v3-search-images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-of-people: list<string> # Filter based on the age of individuals in an image. (nullable)
  --artists: string # Search for images by specific artists (free-text, comma-separated list of artists). (nullable)
  --collection-codes: list<string> # Filter by collection codes (comma-separated list). Include or exclude based on collections_filter_type. (nullable)
  --collections-filter-type: string@collections-filter-type-completer # Provides searching based on specified collection(s). The default is Include
  --color: string # Filter based on predominant color in an image. Use 6 character hexidecimal format (e.g., #002244). Note: when specified, results will not contain editorial images. (nullable)
  --compositions: list<string> # Filter based on image composition. (nullable)
  --download-product: string # Filters based on which product the asset will download against. Allowed values are easyaccess, editorialsubscription, imagepack, premiumaccess and royaltyfreesubscription. If you have more than one instance of a product, you may also include the ID of the product instance you wish to filter on. For example, some users may have more than one premiumaccess product, so the download_product value would be premiumaccess:1234. Product ID can be obtained from the GET /products response. (nullable)
  --embed-content-only: oneof<nothing, bool> # Restrict search results to embeddable images. The default is false. (default: false)
  --event-ids: list<int> # Filter based on specific events (nullable)
  --ethnicity: list<string> # Filter search results based on the ethnicity of individuals in an image. (nullable)
  --exclude-nudity: oneof<nothing, bool> # Excludes images containing nudity. The default is false. (default: false)
  --fields: list<string> # Specifies fields to return. Defaults to 'summary_set'. (nullable)
  --file-types: list<string> # Return only images having a specific file type. (nullable)
  --graphical-styles: list<string> # Filter based on graphical style of the image. (nullable)
  --graphical-styles-filter-type: string@graphical-styles-filter-type-completer # Provides searching based on specified graphical style(s). The default is Include
  --include-related-searches: oneof<nothing, bool> # Specifies whether or not to include related searches in the response. The default is false. (default: false)
  --keyword-ids: list<int> # Return only images tagged with specific keyword(s). Specify using a comma-separated list of keyword Ids. If keyword Ids and phrase are both specified, only those images matching the query phrase which also contain the requested keyword(s) are returned. (nullable)
  --minimum-size: string@minimum-size-completer # Filter based on minimum size requested. The default is x-small
  --number-of-people: list<string> # Filter based on the number of people in the image. (nullable)
  --orientations: list<string> # Return only images with selected aspect ratios. (nullable)
  --page: int # Request results starting at a page number (default is 1). (format: int32, default: 1)
  --page-size: int # Request number of images to return in each page. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --phrase: string # Search images using a search phrase. (nullable)
  --sort-order: string@sort-order-completer-2 # Select sort order of results. The default is best_match
  --specific-people: list<string> # Return only images associated with specific people (using a comma-delimited list). (nullable)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --gi-country-code: string # Receive regionally relevant search results based on the value specified. Accepts only ISO Alpha-3 country codes. The Countries operation can be used to retrieve the codes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/search/images"
    query: [{name: age_of_people, var: age_of_people, style: csv}, {name: artists, var: artists}, {name: collection_codes, var: collection_codes, style: csv}, {name: collections_filter_type, var: collections_filter_type}, {name: color, var: color}, {name: compositions, var: compositions, style: csv}, {name: download_product, var: download_product}, {name: embed_content_only, var: embed_content_only}, {name: event_ids, var: event_ids, style: csv}, {name: ethnicity, var: ethnicity, style: csv}, {name: exclude_nudity, var: exclude_nudity}, {name: fields, var: fields, style: csv}, {name: file_types, var: file_types, style: csv}, {name: graphical_styles, var: graphical_styles, style: csv}, {name: graphical_styles_filter_type, var: graphical_styles_filter_type}, {name: include_related_searches, var: include_related_searches}, {name: keyword_ids, var: keyword_ids, style: csv}, {name: minimum_size, var: minimum_size}, {name: number_of_people, var: number_of_people, style: csv}, {name: orientations, var: orientations, style: csv}, {name: page, var: page}, {name: page_size, var: page_size}, {name: phrase, var: phrase}, {name: sort_order, var: sort_order}, {name: specific_people, var: specific_people, style: csv}]
    header: [{name: Accept-Language, var: accept_language}, {name: GI-Country-Code, var: gi_country_code}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    age_of_people: $age_of_people, artists: $artists, collection_codes: $collection_codes, collections_filter_type: $collections_filter_type, color: $color, compositions: $compositions, download_product: $download_product, embed_content_only: $embed_content_only, event_ids: $event_ids, ethnicity: $ethnicity, exclude_nudity: $exclude_nudity, fields: $fields, file_types: $file_types, graphical_styles: $graphical_styles, graphical_styles_filter_type: $graphical_styles_filter_type, include_related_searches: $include_related_searches, keyword_ids: $keyword_ids, minimum_size: $minimum_size, number_of_people: $number_of_people, orientations: $orientations, page: $page, page_size: $page_size, phrase: $phrase, sort_order: $sort_order, specific_people: $specific_people, accept_language: $accept_language, gi_country_code: $gi_country_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for creative images only
#
# GET /v3/search/images/creative
# Returns: record<auto_corrections: record<phrase: string>, images: table<allowed_use: record, alternative_ids: record, artist: string, asset_family: string, call_for_image: bool, caption: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_camera_shot: string, date_created: string, display_sizes: list, download_product: string, graphical_style: string, id: string, keywords: list, largest_downloads: list, license_model: string, max_dimensions: record, orientation: string, quality_rank: int, referral_destinations: list, title: string, uri_oembed: string>, related_searches: table<phrase: string, url: string>, result_count: int>
export def "get-v3-search-images-creative" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-of-people: list<string> # Filter based on the age of individuals in an image. (nullable)
  --artists: string # Search for images by specific artists (free-text, comma-separated list of artists). (nullable)
  --collection-codes: list<string> # Filter by collection codes (comma-separated list). Include or exclude based on collections_filter_type. (nullable)
  --collections-filter-type: string@collections-filter-type-completer # Use to include or exclude collections from search. The default is include
  --color: string # Filter based on predominant color in an image. Use 6 character hexadecimal format (e.g., #002244). (nullable)
  --compositions: list<string> # Filter based on image composition. (nullable)
  --download-product: string # Filters based on which product the asset will download against. Allowed values are easyaccess, editorialsubscription, imagepack, premiumaccess and royaltyfreesubscription. If you have more than one instance of a product, you may also include the ID of the product instance you wish to filter on. For example, some users may have more than one premiumaccess product, so the download_product value would be premiumaccess:1234. Product ID can be obtained from the GET /products response. (nullable)
  --embed-content-only: oneof<nothing, bool> # Restrict search results to embeddable images. The default is false. (default: false)
  --ethnicity: list<string> # Filter search results based on the ethnicity of individuals in an image. (nullable)
  --exclude-keyword-ids: list<int> # Return only images not tagged with specific keyword(s). Specify using a comma-separated list of keyword Ids. If keyword Ids and phrase are both specified, only those images matching the query phrase which also do not contain the requested keyword(s) are returned. (nullable)
  --exclude-nudity: oneof<nothing, bool> # Excludes images containing nudity. The default is false. (default: false)
  --exclude-editorial-use-only: oneof<nothing, bool> # Exclude images that are only available for editorial (non-commercial) use. Default value is false. (nullable)
  --fields: list<string> # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes, height, and width returned by 'download_sizes' field are estimates. (nullable)
  --file-types: list<string> # Return only images having a specific file type. (nullable)
  --graphical-styles: list<string> # Filter based on graphical style of the image. (nullable)
  --graphical-styles-filter-type: string@graphical-styles-filter-type-completer # Provides searching based on specified graphical style(s). The default is include.
  --include-related-searches: oneof<nothing, bool> # Specifies whether or not to include related searches in the response. The default is false. (default: false)
  --keyword-ids: list<int> # Return only images tagged with specific keyword(s). Specify using a comma-separated list of keyword Ids. If keyword Ids and phrase are both specified, only those images matching the query phrase which also contain the requested keyword(s) are returned. (nullable)
  --minimum-size: string@minimum-size-completer # Filter based on minimum size requested. The default is x-small.
  --number-of-people: list<string> # Filter based on the number of people in the image. (nullable)
  --orientations: list<string> # Return only images with selected aspect ratios. (nullable)
  --page: int # Request results starting at a page number (default is 1). (format: int32, default: 1)
  --page-size: int # Request number of images to return in each page. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --phrase: string # Search images using a search phrase. (nullable, default: "")
  --safe-search: oneof<nothing, bool> # Setting safe_search to "true" excludes images containing nudity, death, profanity, drugs and alcohol, suggestive content, and graphic content from the result set. The default is false. Because this is a keyword-based filter, it's possible that a small number of unsafe images may not be caught by the filter. Please direct feedback to your Getty Images Account or API support representative. (default: false)
  --sort-order: string@sort-order-completer-2 # Select sort order of results. The default is best_match
  --facet-fields: list<string> # Specifies the facets to return in the response. Facets provide additional search parameters to refine your results. The include_facets parameter must be set to "true" for facets to be returned. (nullable)
  --include-facets: oneof<nothing, bool> # Specifies whether or not to include facets in the result set. Default is "false". (nullable)
  --facet-max-count: int # Specifies the maximum number of facets to return per type. Default is 300. (format: int32, default: 300)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --gi-country-code: string # Receive regionally relevant search results based on the value specified. Accepts only ISO Alpha-3 country codes. The Countries operation can be used to retrieve the codes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/search/images/creative"
    query: [{name: age_of_people, var: age_of_people, style: csv}, {name: artists, var: artists}, {name: collection_codes, var: collection_codes, style: csv}, {name: collections_filter_type, var: collections_filter_type}, {name: color, var: color}, {name: compositions, var: compositions, style: csv}, {name: download_product, var: download_product}, {name: embed_content_only, var: embed_content_only}, {name: ethnicity, var: ethnicity, style: csv}, {name: exclude_keyword_ids, var: exclude_keyword_ids, style: csv}, {name: exclude_nudity, var: exclude_nudity}, {name: exclude_editorial_use_only, var: exclude_editorial_use_only}, {name: fields, var: fields, style: csv}, {name: file_types, var: file_types, style: csv}, {name: graphical_styles, var: graphical_styles, style: csv}, {name: graphical_styles_filter_type, var: graphical_styles_filter_type}, {name: include_related_searches, var: include_related_searches}, {name: keyword_ids, var: keyword_ids, style: csv}, {name: minimum_size, var: minimum_size}, {name: number_of_people, var: number_of_people, style: csv}, {name: orientations, var: orientations, style: csv}, {name: page, var: page}, {name: page_size, var: page_size}, {name: phrase, var: phrase}, {name: safe_search, var: safe_search}, {name: sort_order, var: sort_order}, {name: facet_fields, var: facet_fields, style: csv}, {name: include_facets, var: include_facets}, {name: facet_max_count, var: facet_max_count}]
    header: [{name: Accept-Language, var: accept_language}, {name: GI-Country-Code, var: gi_country_code}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    age_of_people: $age_of_people, artists: $artists, collection_codes: $collection_codes, collections_filter_type: $collections_filter_type, color: $color, compositions: $compositions, download_product: $download_product, embed_content_only: $embed_content_only, ethnicity: $ethnicity, exclude_keyword_ids: $exclude_keyword_ids, exclude_nudity: $exclude_nudity, exclude_editorial_use_only: $exclude_editorial_use_only, fields: $fields, file_types: $file_types, graphical_styles: $graphical_styles, graphical_styles_filter_type: $graphical_styles_filter_type, include_related_searches: $include_related_searches, keyword_ids: $keyword_ids, minimum_size: $minimum_size, number_of_people: $number_of_people, orientations: $orientations, page: $page, page_size: $page_size, phrase: $phrase, safe_search: $safe_search, sort_order: $sort_order, facet_fields: $facet_fields, include_facets: $include_facets, facet_max_count: $facet_max_count, accept_language: $accept_language, gi_country_code: $gi_country_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for creative images based on url
#
# GET /v3/search/images/creative/by-image
# Returns: record<auto_corrections: record<phrase: string>, facets: record<artists: list<record>, entertainment: list<record>, events: list<record>, locations: list<record>, specific_people: list<record>>, image_fingerprint: string, images: any, related_searches: table<phrase: string, url: string>, result_count: int>
export def "get-v3-search-images-creative-by-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-id: string # Specifies the Getty image id to use in the search. (nullable)
  --exclude-editorial-use-only: oneof<nothing, bool> # Exclude images that are only available for editorial (non-commercial) use. Default value is false. (nullable)
  --facet-fields: list<string> # Specifies the facets to return in the response. Facets provide additional search parameters to refine your results. The include_facets parameter must be set to "true" for facets to be returned. (nullable)
  --facet-max-count: int # Specifies the maximum number of facets to return per type. Default is 300. (format: int32, default: 300)
  --fields: list<string> # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes, height, and width returned by 'download_sizes' field are estimates. (nullable)
  --image-url: string # Specifies the location of the image to use in the search. (nullable)
  --include-facets: oneof<nothing, bool> # Specifies whether or not to include facets in the result set. Default is "false". (nullable)
  --page: int # Request results starting at a page number (default is 1). (format: int32, default: 1)
  --page-size: int # Request number of images to return in each page. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --product-types: list<string> # Filter images to those from one of your product types. Allowed values are easyaccess, imagepack, premiumaccess and royaltyfreesubscription. If you have more than one instance of a product, you may also include the ID of the product instance you wish to filter on. For example, some users may have more than one premiumaccess product, so the product_types value would be premiumaccess:1234. Product ID can be obtained from the GET /products response. (nullable)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --gi-country-code: string # Receive regionally relevant search results based on the value specified. Accepts only ISO Alpha-3 country codes. The Countries operation can be used to retrieve the codes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/search/images/creative/by-image"
    query: [{name: asset_id, var: asset_id}, {name: exclude_editorial_use_only, var: exclude_editorial_use_only}, {name: facet_fields, var: facet_fields, style: csv}, {name: facet_max_count, var: facet_max_count}, {name: fields, var: fields, style: csv}, {name: image_url, var: image_url}, {name: include_facets, var: include_facets}, {name: page, var: page}, {name: page_size, var: page_size}, {name: product_types, var: product_types, style: csv}]
    header: [{name: Accept-Language, var: accept_language}, {name: GI-Country-Code, var: gi_country_code}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    asset_id: $asset_id, exclude_editorial_use_only: $exclude_editorial_use_only, facet_fields: $facet_fields, facet_max_count: $facet_max_count, fields: $fields, image_url: $image_url, include_facets: $include_facets, page: $page, page_size: $page_size, product_types: $product_types, accept_language: $accept_language, gi_country_code: $gi_country_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for editorial images only
#
# GET /v3/search/images/editorial
# Returns: record<images: table<allowed_use: record, alternative_ids: record, artist: string, asset_family: string, call_for_image: bool, caption: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_camera_shot: string, date_created: string, display_sizes: list, download_product: string, editorial_segments: list, editorial_source: record, event_ids: list, graphical_style: string, id: string, keywords: list, largest_downloads: list, license_model: string, max_dimensions: record, orientation: string, people: list, product_types: list, quality_rank: int, referral_destinations: list, title: string, uri_oembed: string>, related_searches: table<phrase: string, url: string>, result_count: int>
export def "get-v3-search-images-editorial" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-of-people: list<string> # Filter based on the age of individuals in an image. (nullable)
  --artists: string # Search for images by specific artists (free-text, comma-separated list of artists). (nullable)
  --collection-codes: list<string> # Filter by collections (comma-separated list of collection codes). Include or exclude based on collections_filter_type. (nullable)
  --collections-filter-type: string@collections-filter-type-completer # Use to include or exclude collections from search. The default is include
  --compositions: list<string> # Filter based on image composition. (nullable)
  --date-from: string # Return only images that are created on or after this date. Use ISO 8601 format (e.g., 1999-12-31). (nullable, format: date-time)
  --date-to: string # Return only images that are created on or before this date. Use ISO 8601 format (e.g., 1999-12-31). (nullable, format: date-time)
  --download-product: string # Filters based on which product the asset will download against. Allowed values are easyaccess, editorialsubscription, imagepack, premiumaccess and royaltyfreesubscription. If you have more than one instance of a product, you may also include the ID of the product instance you wish to filter on. For example, some users may have more than one premiumaccess product, so the download_product value would be premiumaccess:1234. Product ID can be obtained from the GET /products response. (nullable)
  --editorial-segments: list<string> # Return only events with a matching editorial segment. (nullable)
  --embed-content-only: oneof<nothing, bool> # Restrict search results to embeddable images. The default is false. (default: false)
  --ethnicity: list<string> # Filter search results based on the ethnicity of individuals in an image. (nullable)
  --event-ids: list<int> # Filter based on specific events (nullable)
  --exclude-keyword-ids: list<int> # Return only images not tagged with specific keyword(s). Specify using a comma-separated list of keyword Ids. If keyword Ids and phrase are both specified, only those images matching the query phrase which also do not contain the requested keyword(s) are returned. (nullable)
  --fields: list<string> # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes, height, and width returned by 'download_sizes' field are estimates. (nullable)
  --file-types: list<string> # Return only images having a specific file type. (nullable)
  --graphical-styles: list<string> # Filter based on graphical style of the image. (nullable)
  --graphical-styles-filter-type: string@graphical-styles-filter-type-completer # Provides searching based on specified graphical style(s). The default is include.
  --include-related-searches: oneof<nothing, bool> # Specifies whether or not to include related searches in the response. The default is false. (default: false)
  --keyword-ids: list<int> # Return only images tagged with specific keyword(s). Specify using a comma-separated list of keyword Ids. If keyword Ids and phrase are both specified, only those images matching the query phrase which also contain the requested keyword(s) are returned. (nullable)
  --minimum-size: string@minimum-size-completer # Filter based on minimum size requested. The default is x-small.
  --number-of-people: list<string> # Filter based on the number of people in the image. (nullable)
  --orientations: list<string> # Return only images with selected aspect ratios. (nullable)
  --page: int # Request results starting at a page number (default is 1). (format: int32, default: 1)
  --page-size: int # Request number of images to return in each page. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --phrase: string # Search images using a search phrase. (nullable)
  --sort-order: string@sort-order-completer-3 # Select sort order of results. The default is best_match
  --specific-people: list<string> # Return only images associated with specific people (using a comma-delimited list). (nullable)
  --minimum-quality-rank: int # Filter search results based on minimum quality ranking. Possible values 1, 2, 3 with 1 being best. (nullable, format: int32)
  --facet-fields: list<string> # Specifies the facets to return in the response. Facets provide additional search parameters to refine your results. The include_facets parameter must be set to "true" for facets to be returned. (nullable)
  --include-facets: oneof<nothing, bool> # Specifies whether or not to include facets in the result set. Default is "false". (nullable)
  --facet-max-count: int # Specifies the maximum number of facets to return per type. Default is 300. (format: int32, default: 300)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --gi-country-code: string # Receive regionally relevant search results based on the value specified. Accepts only ISO Alpha-3 country codes. The Countries operation can be used to retrieve the codes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/search/images/editorial"
    query: [{name: age_of_people, var: age_of_people, style: csv}, {name: artists, var: artists}, {name: collection_codes, var: collection_codes, style: csv}, {name: collections_filter_type, var: collections_filter_type}, {name: compositions, var: compositions, style: csv}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: download_product, var: download_product}, {name: editorial_segments, var: editorial_segments, style: csv}, {name: embed_content_only, var: embed_content_only}, {name: ethnicity, var: ethnicity, style: csv}, {name: event_ids, var: event_ids, style: csv}, {name: exclude_keyword_ids, var: exclude_keyword_ids, style: csv}, {name: fields, var: fields, style: csv}, {name: file_types, var: file_types, style: csv}, {name: graphical_styles, var: graphical_styles, style: csv}, {name: graphical_styles_filter_type, var: graphical_styles_filter_type}, {name: include_related_searches, var: include_related_searches}, {name: keyword_ids, var: keyword_ids, style: csv}, {name: minimum_size, var: minimum_size}, {name: number_of_people, var: number_of_people, style: csv}, {name: orientations, var: orientations, style: csv}, {name: page, var: page}, {name: page_size, var: page_size}, {name: phrase, var: phrase}, {name: sort_order, var: sort_order}, {name: specific_people, var: specific_people, style: csv}, {name: minimum_quality_rank, var: minimum_quality_rank}, {name: facet_fields, var: facet_fields, style: csv}, {name: include_facets, var: include_facets}, {name: facet_max_count, var: facet_max_count}]
    header: [{name: Accept-Language, var: accept_language}, {name: GI-Country-Code, var: gi_country_code}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    age_of_people: $age_of_people, artists: $artists, collection_codes: $collection_codes, collections_filter_type: $collections_filter_type, compositions: $compositions, date_from: $date_from, date_to: $date_to, download_product: $download_product, editorial_segments: $editorial_segments, embed_content_only: $embed_content_only, ethnicity: $ethnicity, event_ids: $event_ids, exclude_keyword_ids: $exclude_keyword_ids, fields: $fields, file_types: $file_types, graphical_styles: $graphical_styles, graphical_styles_filter_type: $graphical_styles_filter_type, include_related_searches: $include_related_searches, keyword_ids: $keyword_ids, minimum_size: $minimum_size, number_of_people: $number_of_people, orientations: $orientations, page: $page, page_size: $page_size, phrase: $phrase, sort_order: $sort_order, specific_people: $specific_people, minimum_quality_rank: $minimum_quality_rank, facet_fields: $facet_fields, include_facets: $include_facets, facet_max_count: $facet_max_count, accept_language: $accept_language, gi_country_code: $gi_country_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for creative videos
#
# GET /v3/search/videos/creative
# Returns: record<auto_corrections: record<phrase: string>, facets: record<artists: list<record>, entertainment: list<record>, events: list<record>, locations: list<record>, specific_people: list<record>>, related_searches: table<phrase: string, url: string>, result_count: int, videos: table<allowed_use: record, artist: string, asset_family: string, caption: string, clip_length: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_created: string, display_sizes: list, download_product: string, era: string, event_ids: list, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, mastered_to: string, originally_shot_on: string, product_types: list, referral_destinations: list, shot_speed: string, title: string>>
export def "get-v3-search-videos-creative" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-of-people: list<string> # Provides filtering according to the age of individuals in a video. (nullable)
  --artists: string # Search for videos by specific artists (free-text, comma-separated list of artists). (nullable)
  --aspect-ratios: list<string> # Search for videos by specific aspect ratios. (nullable)
  --collection-codes: list<string> # Provides filtering by collection code. (nullable)
  --collections-filter-type: string@collections-filter-type-completer # Use to include or exclude collections from search. The default is include
  --compositions: list<string> # Filter based on video composition. (nullable)
  --download-product: string # Filters based on which product the asset will download against. Allowed values are easyaccess, editorialsubscription, imagepack, premiumaccess and royaltyfreesubscription. If you have more than one instance of a product, you may also include the ID of the product instance you wish to filter on. For example, some users may have more than one premiumaccess product, so the download_product value would be premiumaccess:1234. Product ID can be obtained from the GET /products response. (nullable)
  --exclude-nudity: oneof<nothing, bool> # Excludes videos containing nudity. The default is false. (default: false)
  --exclude-editorial-use-only: oneof<nothing, bool> # Exclude videos that are only available for editorial (non-commercial) use. Default value is false. (nullable)
  --exclude-keyword-ids: list<int> # Return only videos not tagged with specific keyword(s). Specify using a comma-separated list of keyword Ids. If keyword Ids and phrase are both specified, only those videos matching the query phrase which also do not contain the requested keyword(s) are returned. (nullable)
  --fields: list<string> # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes returned by 'download_sizes' field is an estimate. (nullable)
  --format-available: string@format-available-completer # Filters according to the digital video format available on a film asset.
  --frame-rates: list<string> # Provides filtering by video frame rate (frames/second). (nullable)
  --image-techniques: list<string> # Filter based on image technique. (nullable)
  --include-related-searches: oneof<nothing, bool> # Specifies whether or not to include related searches in the response. The default is false. (default: false)
  --keyword-ids: list<int> # Return only videos tagged with specific keyword(s). Specify using a comma-separated list of keyword Ids. If keyword Ids and phrase are both specified, only those videos matching the query phrase which also contain the requested keyword(s) are returned. (nullable)
  --license-models: list<string> # Specifies the video licensing model(s). (nullable)
  --orientations: list<string> # Return only videos with selected orientations. (nullable)
  --min-clip-length: int # Provides filtering by minimum length of video clip, in seconds (format: int32, default: 0)
  --max-clip-length: int # Provides filtering by maximum length of video, in seconds (format: int32, default: 0)
  --page: int # Identifies page to return. Default is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --phrase: string # Free-text search query. (nullable, default: "")
  --safe-search: oneof<nothing, bool> # Setting safe_search to "true" excludes images containing nudity, death, profanity, drugs and alcohol, suggestive content, and graphic content from the result set. The default is false. Because this is a keyword-based filter, it's possible that a small number of unsafe images may not be caught by the filter. Please direct feedback to your Getty Images Account or API support representative. (default: false)
  --sort-order: string@sort-order-completer-2 # Select sort order of results. The default is best_match
  --release-status: string@release-status-completer # Allows filtering by type of model release.
  --facet-fields: list<string> # Specifies the facets to return in the response. Facets provide additional search parameters to refine your results. The include_facets parameter must be set to "true" for facets to be returned. (nullable)
  --facet-max-count: int # Specifies the maximum number of facets to return per type. Default is 300. (format: int32, default: 300)
  --include-facets: oneof<nothing, bool> # Specifies whether or not to include facets in the result set. Default is "false". (nullable)
  --viewpoints: list<string> # Filter based on viewpoint. (nullable)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --gi-country-code: string # Receive regionally relevant search results based on the value specified. Accepts only ISO Alpha-3 country codes. The Countries operation can be used to retrieve the codes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/search/videos/creative"
    query: [{name: age_of_people, var: age_of_people, style: csv}, {name: artists, var: artists}, {name: aspect_ratios, var: aspect_ratios, style: csv}, {name: collection_codes, var: collection_codes, style: csv}, {name: collections_filter_type, var: collections_filter_type}, {name: compositions, var: compositions, style: csv}, {name: download_product, var: download_product}, {name: exclude_nudity, var: exclude_nudity}, {name: exclude_editorial_use_only, var: exclude_editorial_use_only}, {name: exclude_keyword_ids, var: exclude_keyword_ids, style: csv}, {name: fields, var: fields, style: csv}, {name: format_available, var: format_available}, {name: frame_rates, var: frame_rates, style: csv}, {name: image_techniques, var: image_techniques, style: csv}, {name: include_related_searches, var: include_related_searches}, {name: keyword_ids, var: keyword_ids, style: csv}, {name: license_models, var: license_models, style: csv}, {name: orientations, var: orientations, style: csv}, {name: min_clip_length, var: min_clip_length}, {name: max_clip_length, var: max_clip_length}, {name: page, var: page}, {name: page_size, var: page_size}, {name: phrase, var: phrase}, {name: safe_search, var: safe_search}, {name: sort_order, var: sort_order}, {name: release_status, var: release_status}, {name: facet_fields, var: facet_fields, style: csv}, {name: facet_max_count, var: facet_max_count}, {name: include_facets, var: include_facets}, {name: viewpoints, var: viewpoints, style: csv}]
    header: [{name: Accept-Language, var: accept_language}, {name: GI-Country-Code, var: gi_country_code}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    age_of_people: $age_of_people, artists: $artists, aspect_ratios: $aspect_ratios, collection_codes: $collection_codes, collections_filter_type: $collections_filter_type, compositions: $compositions, download_product: $download_product, exclude_nudity: $exclude_nudity, exclude_editorial_use_only: $exclude_editorial_use_only, exclude_keyword_ids: $exclude_keyword_ids, fields: $fields, format_available: $format_available, frame_rates: $frame_rates, image_techniques: $image_techniques, include_related_searches: $include_related_searches, keyword_ids: $keyword_ids, license_models: $license_models, orientations: $orientations, min_clip_length: $min_clip_length, max_clip_length: $max_clip_length, page: $page, page_size: $page_size, phrase: $phrase, safe_search: $safe_search, sort_order: $sort_order, release_status: $release_status, facet_fields: $facet_fields, facet_max_count: $facet_max_count, include_facets: $include_facets, viewpoints: $viewpoints, accept_language: $accept_language, gi_country_code: $gi_country_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for creative videos based on url
#
# GET /v3/search/videos/creative/by-image
# Returns: record<auto_corrections: record<phrase: string>, facets: record<artists: list<record>, entertainment: list<record>, events: list<record>, locations: list<record>, specific_people: list<record>>, related_searches: table<phrase: string, url: string>, result_count: int, videos: table<allowed_use: record, artist: string, asset_family: string, caption: string, clip_length: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_created: string, display_sizes: list, download_product: string, era: string, event_ids: list, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, mastered_to: string, originally_shot_on: string, product_types: list, referral_destinations: list, shot_speed: string, title: string>>
export def "get-v3-search-videos-creative-by-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-id: string # Specifies the Getty video id to use in the search. (nullable)
  --exclude-editorial-use-only: oneof<nothing, bool> # Exclude videos that are only available for editorial (non-commercial) use. Default value is false. (nullable)
  --facet-fields: list<string> # Specifies the facets to return in the response. Facets provide additional search parameters to refine your results. The include_facets parameter must be set to "true" for facets to be returned. (nullable)
  --facet-max-count: int # Specifies the maximum number of facets to return per type. Default is 300. (format: int32, default: 300)
  --fields: list<string> # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes returned by 'download_sizes' field is an estimate. (nullable)
  --image-url: string # Specifies the location of the image to use in the search. (nullable)
  --include-facets: oneof<nothing, bool> # Specifies whether or not to include facets in the result set. Default is "false". (nullable)
  --page: int # Request results starting at a page number (default is 1). (format: int32, default: 1)
  --page-size: int # Request number of images to return in each page. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --product-types: list<string> # Filter images to those from one of your product types. Allowed values are easyaccess, imagepack, premiumaccess and royaltyfreesubscription. If you have more than one instance of a product, you may also include the ID of the product instance you wish to filter on. For example, some users may have more than one premiumaccess product, so the product_types value would be premiumaccess:1234. Product ID can be obtained from the GET /products response. (nullable)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --gi-country-code: string # Receive regionally relevant search results based on the value specified. Accepts only ISO Alpha-3 country codes. The Countries operation can be used to retrieve the codes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/search/videos/creative/by-image"
    query: [{name: asset_id, var: asset_id}, {name: exclude_editorial_use_only, var: exclude_editorial_use_only}, {name: facet_fields, var: facet_fields, style: csv}, {name: facet_max_count, var: facet_max_count}, {name: fields, var: fields, style: csv}, {name: image_url, var: image_url}, {name: include_facets, var: include_facets}, {name: page, var: page}, {name: page_size, var: page_size}, {name: product_types, var: product_types, style: csv}]
    header: [{name: Accept-Language, var: accept_language}, {name: GI-Country-Code, var: gi_country_code}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    asset_id: $asset_id, exclude_editorial_use_only: $exclude_editorial_use_only, facet_fields: $facet_fields, facet_max_count: $facet_max_count, fields: $fields, image_url: $image_url, include_facets: $include_facets, page: $page, page_size: $page_size, product_types: $product_types, accept_language: $accept_language, gi_country_code: $gi_country_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for editorial videos
#
# GET /v3/search/videos/editorial
# Returns: record<facets: record<artists: list<record>, entertainment: list<record>, events: list<record>, locations: list<record>, specific_people: list<record>>, related_searches: table<phrase: string, url: string>, result_count: int, videos: table<allowed_use: record, artist: string, asset_family: string, caption: string, clip_length: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_created: string, display_sizes: list, download_product: string, era: string, event_ids: list, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, mastered_to: string, originally_shot_on: string, product_types: list, referral_destinations: list, shot_speed: string, source: string, title: string>>
export def "get-v3-search-videos-editorial" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-of-people: list<string> # Provides filtering according to the age of individuals in a video. (nullable)
  --artists: string # Search for videos by specific artists (free-text, comma-separated list of artists). (nullable)
  --aspect-ratios: list<string> # Search for videos by specific aspect ratios. (nullable)
  --collection-codes: list<string> # Provides filtering by collection code. (nullable)
  --collections-filter-type: string@collections-filter-type-completer # Use to include or exclude collections from search. The default is include
  --compositions: list<string> # Filter based on video composition. (nullable)
  --download-product: string # Filters based on which product the asset will download against. Allowed values are easyaccess, editorialsubscription, imagepack, premiumaccess and royaltyfreesubscription. If you have more than one instance of a product, you may also include the ID of the product instance you wish to filter on. For example, some users may have more than one premiumaccess product, so the download_product value would be premiumaccess:1234. Product ID can be obtained from the GET /products response. (nullable)
  --editorial-video-types: list<string> # Allows filtering by types of video. (nullable)
  --fields: list<string> # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes returned by 'download_sizes' field is an estimate. (nullable)
  --format-available: string@format-available-completer # Filters according to the digital video format available on a film asset.
  --frame-rates: list<string> # Provides filtering by video frame rate (frames/second). (nullable)
  --image-techniques: list<string> # Filter based on image technique. (nullable)
  --include-related-searches: oneof<nothing, bool> # Specifies whether or not to include related searches in the response. The default is false. (default: false)
  --keyword-ids: list<int> # Return only videos tagged with specific keyword(s). Specify using a comma-separated list of keyword Ids. If keyword Ids and phrase are both specified, only those videos matching the query phrase which also contain the requested keyword(s) are returned. (nullable)
  --min-clip-length: int # Provides filtering by minimum length of video clip, in seconds (format: int32, default: 0)
  --max-clip-length: int # Provides filtering by maximum length of video clip, in seconds (format: int32, default: 0)
  --orientations: list<string> # Return only videos with selected orientations. (nullable)
  --page: int # Identifies page to return. Default is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --phrase: string # Free-text search query. (nullable, default: "")
  --sort-order: string@sort-order-completer-3 # Select sort order of results. The default is best_match
  --specific-people: list<string> # Allows filtering by specific peoples' names. (nullable)
  --release-status: string@release-status-completer # Allows filtering by type of model release.
  --facet-fields: list<string> # Specifies the facets to return in the response. Facets provide additional search parameters to refine your results. The include_facets parameter must be set to "true" for facets to be returned. (nullable)
  --include-facets: oneof<nothing, bool> # Specifies whether or not to include facets in the result set. Default is "false". (nullable)
  --facet-max-count: int # Specifies the maximum number of facets to return per type. Default is 300. (format: int32, default: 300)
  --viewpoints: list<string> # Filter based on viewpoint. (nullable)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --gi-country-code: string # Receive regionally relevant search results based on the value specified. Accepts only ISO Alpha-3 country codes. The Countries operation can be used to retrieve the codes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/search/videos/editorial"
    query: [{name: age_of_people, var: age_of_people, style: csv}, {name: artists, var: artists}, {name: aspect_ratios, var: aspect_ratios, style: csv}, {name: collection_codes, var: collection_codes, style: csv}, {name: collections_filter_type, var: collections_filter_type}, {name: compositions, var: compositions, style: csv}, {name: download_product, var: download_product}, {name: editorial_video_types, var: editorial_video_types, style: csv}, {name: fields, var: fields, style: csv}, {name: format_available, var: format_available}, {name: frame_rates, var: frame_rates, style: csv}, {name: image_techniques, var: image_techniques, style: csv}, {name: include_related_searches, var: include_related_searches}, {name: keyword_ids, var: keyword_ids, style: csv}, {name: min_clip_length, var: min_clip_length}, {name: max_clip_length, var: max_clip_length}, {name: orientations, var: orientations, style: csv}, {name: page, var: page}, {name: page_size, var: page_size}, {name: phrase, var: phrase}, {name: sort_order, var: sort_order}, {name: specific_people, var: specific_people, style: csv}, {name: release_status, var: release_status}, {name: facet_fields, var: facet_fields, style: csv}, {name: include_facets, var: include_facets}, {name: facet_max_count, var: facet_max_count}, {name: viewpoints, var: viewpoints, style: csv}]
    header: [{name: Accept-Language, var: accept_language}, {name: GI-Country-Code, var: gi_country_code}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    age_of_people: $age_of_people, artists: $artists, aspect_ratios: $aspect_ratios, collection_codes: $collection_codes, collections_filter_type: $collections_filter_type, compositions: $compositions, download_product: $download_product, editorial_video_types: $editorial_video_types, fields: $fields, format_available: $format_available, frame_rates: $frame_rates, image_techniques: $image_techniques, include_related_searches: $include_related_searches, keyword_ids: $keyword_ids, min_clip_length: $min_clip_length, max_clip_length: $max_clip_length, orientations: $orientations, page: $page, page_size: $page_size, phrase: $phrase, sort_order: $sort_order, specific_people: $specific_people, release_status: $release_status, facet_fields: $facet_fields, include_facets: $include_facets, facet_max_count: $facet_max_count, viewpoints: $viewpoints, accept_language: $accept_language, gi_country_code: $gi_country_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Report usage of assets via a batch format.
#
# PUT /v3/usage-batches/{id}
# Returns: record<invalid_assets: list<string>, total_asset_usages_processed: int>
export def "put-v3-usage-batches-id" [
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
  --asset-usages: list # Identifies the list of asset id, usage count and date of usage combinations to record. (nullable) — item shape: {asset_id?: string, quantity?: int, usage_date?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/usage-batches/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: asset_usages, var: asset_usages}]}
    accept: ["application/json"]
    ok: [201]
    auth: api-key
  } {
    id: $id, asset_usages: $asset_usages
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata for multiple videos by supplying multiple video ids
#
# GET /v3/videos
export def "get-v3-videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # Specifies one or more video ids to return. Use comma delimiter when requesting multiple ids. Maximum of 100 ids. (nullable)
  --fields: list<string> # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes returned by 'download_sizes' field is an estimate. (nullable)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  http-request {
    method: get
    path: "/v3/videos"
    query: [{name: ids, var: ids, style: csv}, {name: fields, var: fields, style: csv}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    ids: $ids, fields: $fields, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata for a single video by supplying one video id
#
# GET /v3/videos/{id}
export def "get-v3-videos-id" [
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
  --fields: list<string> # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes returned by 'download_sizes' field is an estimate. (nullable)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  http-request {
    method: get
    path: "/v3/videos/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields, style: csv}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    id: $id, fields: $fields, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a customer's download history for a specific asset
#
# GET /v3/videos/{id}/downloadhistory
# Returns: record<downloads: any, id: string>
export def "get-v3-videos-id-downloadhistory" [
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
  --company-downloads: oneof<nothing, bool> # If specified, returns the list of previously downloaded videos for all users in your company. Your account must be enabled for this functionality. Contact your Getty Images account rep for more information. Default is false.
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/videos/{id}/downloadhistory"
    path_params: [{name: id, var: id}]
    query: [{name: company_downloads, var: company_downloads}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    id: $id, company_downloads: $company_downloads, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve creative videos from the same series
#
# GET /v3/videos/{id}/same-series
export def "get-v3-videos-id-same-series" [
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
  --fields: list<string> # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes returned by 'download_sizes' field is an estimate. (nullable)
  --page: int # Identifies page to return. Default is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  http-request {
    method: get
    path: "/v3/videos/{id}/same-series"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields, style: csv}, {name: page, var: page}, {name: page_size, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    id: $id, fields: $fields, page: $page, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve similar videos
#
# GET /v3/videos/{id}/similar
export def "get-v3-videos-id-similar" [
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
  --fields: list<string> # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes returned by 'download_sizes' field is an estimate. (nullable)
  --page: int # Identifies page to return. Default is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --accept-language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  http-request {
    method: get
    path: "/v3/videos/{id}/similar"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields, style: csv}, {name: page, var: page}, {name: page_size, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    id: $id, fields: $fields, page: $page, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
