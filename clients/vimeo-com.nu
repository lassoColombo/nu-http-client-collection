# Auto-generated client for Vimeo v3.4
# Source: https://api.apis.guru/v2/specs/vimeo.com/3.4/openapi.json
# Auth: --token flag or $env.VIMEO_TOKEN

const CLIENT = {
  base_url: "https://api.vimeo.com"
  token_env_var: "VIMEO_TOKEN"
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

def base-url-completer [] { ["https://api.vimeo.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def direction-completer [] { ["asc" "desc"] }
def sort-completer [] { ["last_video_featured_time" "name"] }
def sort-completer-1 [] { ["alphabetical" "date" "followers" "videos"] }
def sort-completer-2 [] { ["alphabetical" "date" "members" "videos"] }
def filter-completer [] { ["conditional_featured" "embeddable"] }
def sort-completer-3 [] { ["alphabetical" "comments" "date" "duration" "featured" "likes" "plays" "relevant"] }
def filter-completer-1 [] { ["featured"] }
def sort-completer-4 [] { ["alphabetical" "date" "followers" "relevant" "videos"] }
def privacy-completer [] { ["anybody" "moderators" "user"] }
def privacy-completer-1 [] { ["anybody" "moderators" "users"] }
def sort-completer-5 [] { ["alphabetical" "date"] }
def filter-completer-2 [] { ["moderators"] }
def filter-completer-3 [] { ["embeddable"] }
def sort-completer-6 [] { ["added" "alphabetical" "comments" "date" "default" "duration" "likes" "manual" "modified_time" "plays"] }
def type-completer [] { ["captions" "chapters" "descriptions" "metadata" "subtitles"] }
def sort-completer-7 [] { ["alphabetical" "comments" "date" "duration" "likes" "plays"] }
def filter-completer-4 [] { ["texttracks"] }
def sort-completer-8 [] { ["alphabetical" "date" "duration" "videos"] }
def layout-completer [] { ["grid" "player"] }
def privacy-completer-2 [] { ["anybody" "embed_only" "password"] }
def sort-completer-9 [] { ["added_first" "added_last" "alphabetical" "arranged" "comments" "likes" "newest" "oldest" "plays"] }
def theme-completer [] { ["dark" "standard"] }
def sort-completer-10 [] { ["alphabetical" "comments" "date" "default" "duration" "likes" "manual" "modified_time" "plays"] }
def sort-completer-11 [] { ["alphabetical" "date" "name"] }
def filter-completer-5 [] { ["moderated"] }
def type-completer-1 [] { ["appears" "category_featured" "channel" "facebook_feed" "following" "group" "likes" "ondemand_publish" "share" "tagged_with" "twitter_timeline" "uploads"] }
def filter-completer-6 [] { ["online"] }
def filter-completer-7 [] { ["film" "series"] }
def sort-completer-12 [] { ["added" "alphabetical" "date" "modified_time" "name" "publish.time" "rating"] }
def accepted-currencies-completer [] { ["AUD" "CAD" "CHF" "DKK" "EUR" "GBP" "JPY" "KRW" "NOK" "PLN" "SEK" "USD"] }
def content-rating-completer [] { ["drugs" "language" "nudity" "safe" "unrated" "violence"] }
def type-completer-2 [] { ["film" "series"] }
def filter-completer-8 [] { ["all" "expiring_soon" "film" "important" "purchased" "rented" "series" "subscription" "unwatched" "watched"] }
def sort-completer-13 [] { ["added" "alphabetical" "date" "name" "purchase_time" "rating" "release_date"] }
def sort-completer-14 [] { ["alphabetical" "comments" "date" "default" "likes" "manual" "plays"] }
def outro-completer [] { ["nothing"] }
def sort-completer-15 [] { ["date" "default" "modified_time" "name"] }
def sort-completer-16 [] { ["alphabetical" "date" "default" "duration" "last_user_action_event_date"] }
def filter-completer-9 [] { ["app_only" "embeddable" "featured" "playable"] }
def sort-completer-17 [] { ["alphabetical" "comments" "date" "default" "duration" "last_user_action_event_date" "likes" "modified_time" "plays"] }
def license-completer [] { ["by" "by-nc" "by-nc-nd" "by-nc-sa" "by-nd" "by-sa" "cc0"] }
def grant-type-completer [] { ["authorization_code"] }
def grant-type-completer-1 [] { ["client_credentials"] }
def grant-type-completer-2 [] { ["vimeo_oauth1"] }
def filter-completer-10 [] { ["country" "my_region"] }
def sort-completer-18 [] { ["alphabetical" "date" "name" "publish.time" "videos"] }
def filter-completer-11 [] { ["extra" "main" "trailer"] }
def filter-completer-12 [] { ["batch" "default" "single" "vip"] }
def access-type-completer [] { ["default" "vip"] }
def discount-type-completer [] { ["free" "percent"] }
def product-type-completer [] { ["any" "buy" "buy_episode" "rent" "rent_episode" "subscribe"] }
def stream-period-completer [] { ["1_week" "1_year" "24_hour" "30_day" "3_month" "48_hour" "6_month" "72_hour"] }
def type-completer-3 [] { ["batch" "single"] }
def filter-completer-13 [] { ["viewable"] }
def sort-completer-19 [] { ["date" "manual"] }
def sort-completer-20 [] { ["date" "default" "manual" "name" "purchase_time" "release_date"] }
def filter-completer-14 [] { ["all" "buy" "expiring_soon" "extra" "main" "main.viewable" "rent" "trailer" "unwatched" "viewable" "watched"] }
def sort-completer-21 [] { ["date" "default" "episode" "manual" "name" "purchase_time" "release_date"] }
def type-completer-4 [] { ["extra" "main" "trailer"] }
def sort-completer-22 [] { ["created_time" "duration" "name"] }
def filter-completer-15 [] { ["CC" "CC-BY" "CC-BY-NC" "CC-BY-NC-ND" "CC-BY-NC-SA" "CC-BY-ND" "CC-BY-SA" "CC0" "categories" "duration" "in-progress" "minimum_likes" "trending" "upload_date"] }
def sort-completer-23 [] { ["alphabetical" "comments" "date" "duration" "likes" "plays" "relevant"] }
def filter-completer-16 [] { ["related"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-endpoints: "record<methods: list<string>, path: string>"
    get-categories: "table<icon: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, last_video_featured_time: string, link: string, metadata: record<connections: record, interactions: record>, name: string, parent: record<link: string, name: string, uri: string>, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, resource_key: string, subcategories: list<record>, top_level: bool, uri: string>"
    get-category: "record<icon: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, last_video_featured_time: string, link: string, metadata: record<connections: record<channels: record, groups: record, users: record, videos: record>, interactions: record<follow: record>>, name: string, parent: record<link: string, name: string, uri: string>, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, resource_key: string, subcategories: table<link: string, name: string, uri: string>, top_level: bool, uri: string>"
    get-category-channels: "table<categories: list<record>, created_time: string, description: string, header: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<view: string>, resource_key: string, tags: list<record>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    get-category-groups: "table<created_time: string, description: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<comment: string, invite: string, join: string, videos: string, view: string>, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    get-category-videos: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    check-category-for-video: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    get-channels: "table<categories: list<record>, created_time: string, description: string, header: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<view: string>, resource_key: string, tags: list<record>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    create-channel: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, created_time: string, description: string, header: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, link: string, metadata: record<connections: record<privacy_users: record, users: record, videos: record>, interactions: record<add_moderators: record, add_to: record, follow: record, moderate_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<view: string>, resource_key: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-channel: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, created_time: string, description: string, header: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, link: string, metadata: record<connections: record<privacy_users: record, users: record, videos: record>, interactions: record<add_moderators: record, add_to: record, follow: record, moderate_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<view: string>, resource_key: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    edit-channel: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, created_time: string, description: string, header: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, link: string, metadata: record<connections: record<privacy_users: record, users: record, videos: record>, interactions: record<add_moderators: record, add_to: record, follow: record, moderate_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<view: string>, resource_key: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-channel-categories: "table<icon: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, last_video_featured_time: string, link: string, metadata: record<connections: record, interactions: record>, name: string, parent: record<link: string, name: string, uri: string>, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, resource_key: string, subcategories: list<record>, top_level: bool, uri: string>"
    remove-channel-moderators: "record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record<albums: record, appearances: record, block: record, categories: record, channels: record, feed: record, folders: record, followers: record, following: record, groups: record, likes: record, moderated_channels: record, pictures: record, portfolios: record, recommended_channels: record, recommended_users: record, shared: record, videos: record, watched_videos: record, watchlater: record>, interactions: record<add_privacy_user: record, block: record, follow: record, report: record>>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preferences: record<videos: record<privacy: record>>, resource_key: string, upload_quota: record<lifetime: record<free: float, max: float, used: float>, periodic: record<free: float, max: float, reset_date: string, used: float>, space: record<free: float, max: float, showing: string, used: float>>, uri: string, websites: table<description: string, link: string, name: string>>"
    get-channel-moderators: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    replace-channel-moderators: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    get-channel-moderator: "record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record<albums: record, appearances: record, block: record, categories: record, channels: record, feed: record, folders: record, followers: record, following: record, groups: record, likes: record, moderated_channels: record, pictures: record, portfolios: record, recommended_channels: record, recommended_users: record, shared: record, videos: record, watched_videos: record, watchlater: record>, interactions: record<add_privacy_user: record, block: record, follow: record, report: record>>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preferences: record<videos: record<privacy: record>>, resource_key: string, upload_quota: record<lifetime: record<free: float, max: float, used: float>, periodic: record<free: float, max: float, reset_date: string, used: float>, space: record<free: float, max: float, showing: string, used: float>>, uri: string, websites: table<description: string, link: string, name: string>>"
    get-channel-privacy-users: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    set-channel-privacy-users: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    get-channel-tags: "table<canonical: string, metadata: record<connections: record>, name: string, resource_key: string, uri: string>"
    add-tags-to-channel: "table<canonical: string, metadata: record<connections: record>, name: string, resource_key: string, uri: string>"
    get-channel-subscribers: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    remove-videos-from-channel: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    get-channel-videos: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-channel-video: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    get-comments-alt1: "table<created_on: string, metadata: record<connections: record>, resource_key: string, text: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    create-comment-alt1: "record<created_on: string, metadata: record<connections: record<replies: record>>, resource_key: string, text: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-video-credits-alt1: "table<name: string, role: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, video: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>>"
    add-video-credit-alt1: "record<name: string, role: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, video: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>>"
    get-video-likes-alt1: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    get-video-thumbnails-alt1: "table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>"
    create-video-thumbnail-alt1: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-video-privacy-users-alt1: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    add-video-privacy-users-alt1: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    get-text-tracks-alt1: "table<active: bool, hls_link: string, hls_link_expires_time: string, language: string, link: string, link_expires_time: string, name: string, type: string, uri: string>"
    create-text-track-alt1: "record<active: bool, hls_link: string, hls_link_expires_time: string, language: string, link: string, link_expires_time: string, name: string, type: string, uri: string>"
    get-content-ratings: "table<code: string, name: string, uri: string>"
    get-cc-licenses: "table<code: string, name: string, uri: string>"
    get-groups: "table<created_time: string, description: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<comment: string, invite: string, join: string, videos: string, view: string>, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    create-group: "record<created_time: string, description: string, link: string, metadata: record<connections: record<users: record, videos: record>, interactions: record<join: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<comment: string, invite: string, join: string, videos: string, view: string>, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-group: "record<created_time: string, description: string, link: string, metadata: record<connections: record<users: record, videos: record>, interactions: record<join: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<comment: string, invite: string, join: string, videos: string, view: string>, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-group-members: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    get-group-videos: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-group-video: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    add-video-to-group: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    get-languages: "table<code: string, name: string>"
    get-user-alt1: "record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record<albums: record, appearances: record, block: record, categories: record, channels: record, feed: record, folders: record, followers: record, following: record, groups: record, likes: record, moderated_channels: record, pictures: record, portfolios: record, recommended_channels: record, recommended_users: record, shared: record, videos: record, watched_videos: record, watchlater: record>, interactions: record<add_privacy_user: record, block: record, follow: record, report: record>>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preferences: record<videos: record<privacy: record>>, resource_key: string, upload_quota: record<lifetime: record<free: float, max: float, used: float>, periodic: record<free: float, max: float, reset_date: string, used: float>, space: record<free: float, max: float, showing: string, used: float>>, uri: string, websites: table<description: string, link: string, name: string>>"
    edit-user-alt1: "record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record<albums: record, appearances: record, block: record, categories: record, channels: record, feed: record, folders: record, followers: record, following: record, groups: record, likes: record, moderated_channels: record, pictures: record, portfolios: record, recommended_channels: record, recommended_users: record, shared: record, videos: record, watched_videos: record, watchlater: record>, interactions: record<add_privacy_user: record, block: record, follow: record, report: record>>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preferences: record<videos: record<privacy: record>>, resource_key: string, upload_quota: record<lifetime: record<free: float, max: float, used: float>, periodic: record<free: float, max: float, reset_date: string, used: float>, space: record<free: float, max: float, showing: string, used: float>>, uri: string, websites: table<description: string, link: string, name: string>>"
    get-albums-alt1: "table<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, web_brand_color: bool, web_custom_logo: bool>"
    create-album-alt1: "record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool>"
    get-album-alt1: "record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool>"
    edit-album-alt1: "record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool>"
    get-album-videos-alt1: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-album-video-alt1: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    set-video-as-album-thumbnail-alt1: "record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool>"
    get-appearances-alt1: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-category-subscriptions-alt1: "table<icon: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, last_video_featured_time: string, link: string, metadata: record<connections: record, interactions: record>, name: string, parent: record<link: string, name: string, uri: string>, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, resource_key: string, subcategories: list<record>, top_level: bool, uri: string>"
    get-channel-subscriptions-alt1: "table<categories: list<record>, created_time: string, description: string, header: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<view: string>, resource_key: string, tags: list<record>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    get-custom-logos-alt1: "table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>"
    create-custom-logo-alt1: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-custom-logo-alt1: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-feed-alt1: "table<category: record<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, channel: record<categories: list, created_time: string, description: string, header: record, link: string, metadata: record, modified_time: string, name: string, pictures: record, privacy: record, resource_key: string, tags: list, uri: string, user: record>, clip: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, group: record<created_time: string, description: string, link: string, metadata: record, modified_time: string, name: string, pictures: record, privacy: record, resource_key: string, uri: string, user: record>, metadata: record<connections: record>, tag: record<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, time: string, type: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    get-followers-alt1: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    get-user-following-alt1: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    get-user-groups-alt1: "table<created_time: string, description: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<comment: string, invite: string, join: string, videos: string, view: string>, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    get-likes-alt1: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-user-vods-alt1: "table<background: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record, rent: record>, film: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, genres: list<record>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, trailer: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    create-vod-alt1: "record<background: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record<active: bool, price: float>, rent: record<active: bool, period: string, price: float>>, film: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, genres: table<canonical: string, interactions: record, link: string, metadata: record, name: string, uri: string>, link: string, metadata: record<connections: record<metadata: record>, interactions: record<buy: record, rent: record, subscribe: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, trailer: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-vod-purchases: "table<background: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record, rent: record>, film: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, genres: list<record>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, trailer: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    check-if-vod-was-purchased-alt1: "record<background: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record<active: bool, price: float>, rent: record<active: bool, period: string, price: float>>, film: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, genres: table<canonical: string, interactions: record, link: string, metadata: record, name: string, uri: string>, link: string, metadata: record<connections: record<metadata: record>, interactions: record<buy: record, rent: record, subscribe: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, trailer: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-pictures-alt1: "table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>"
    create-picture-alt1: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-picture-alt1: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    edit-picture-alt1: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-portfolios-alt1: "table<created_time: string, description: string, link: string, metadata: record<connections: record>, modified_time: string, name: string, sort: string, uri: string>"
    get-portfolio-alt1: "record<created_time: string, description: string, link: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, sort: string, uri: string>"
    get-portfolio-videos-alt1: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-portfolio-video-alt1: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    get-embed-presets-alt1: "table<metadata: record<connections: record>, name: string, settings: record<buttons: record, logos: record, outro: record>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    get-embed-preset-alt1: "record<metadata: record<connections: record<videos: record>>, name: string, settings: record<buttons: record<embed: bool, hd: bool, like: bool, share: bool, vote: bool, watchlater: bool>, logos: record<custom: bool, sticky_custom: bool, vimeo: bool>, outro: record<clips: string, link: record, text: string, type: string, videos: string>>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    edit-embed-preset-alt1: "record<metadata: record<connections: record<videos: record>>, name: string, settings: record<buttons: record<embed: bool, hd: bool, like: bool, share: bool, vote: bool, watchlater: bool>, logos: record<custom: bool, sticky_custom: bool, vimeo: bool>, outro: record<clips: string, link: record, text: string, type: string, videos: string>>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-embed-preset-videos-alt1: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-projects-alt1: "table<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    create-project-alt1: "record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-project-alt1: "record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    edit-project-alt1: "record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-project-videos-alt1: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-videos-alt1: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    upload-video-alt1: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    check-if-user-owns-video-alt1: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    get-watch-history: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-watch-later-queue-alt1: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    check-watch-later-queue-alt1: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    exchange-auth-code: "record<access_token: string, app: record<name: string, uri: string>, expires_on: string, refresh_token: string, scope: string, token_type: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    client-auth: "record<access_token: string, app: record<name: string, uri: string>, expires_on: string, refresh_token: string, scope: string, token_type: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    convert-access-token: "record<access_token: string, app: record<name: string, uri: string>, expires_on: string, refresh_token: string, scope: string, token_type: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    verify-token: "record<access_token: string, app: record<name: string, uri: string>, expires_on: string, refresh_token: string, scope: string, token_type: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-vod-genres: "table<canonical: string, interactions: record<page: record>, link: string, metadata: record<connections: record>, name: string, uri: string>"
    get-vod-genre: "record<canonical: string, interactions: record<page: record<added: bool, options: list, uri: string>>, link: string, metadata: record<connections: record<pages: record>>, name: string, uri: string>"
    get-genre-vods: "table<background: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record, rent: record>, film: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, genres: list<record>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, trailer: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    get-genre-vod: "record<background: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record<active: bool, price: float>, rent: record<active: bool, period: string, price: float>>, film: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, genres: table<canonical: string, interactions: record, link: string, metadata: record, name: string, uri: string>, link: string, metadata: record<connections: record<metadata: record>, interactions: record<buy: record, rent: record, subscribe: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, trailer: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-vod: "record<background: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record<active: bool, price: float>, rent: record<active: bool, period: string, price: float>>, film: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, genres: table<canonical: string, interactions: record, link: string, metadata: record, name: string, uri: string>, link: string, metadata: record<connections: record<metadata: record>, interactions: record<buy: record, rent: record, subscribe: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, trailer: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    edit-vod: "record<background: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record<active: bool, price: float>, rent: record<active: bool, period: string, price: float>>, film: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, genres: table<canonical: string, interactions: record, link: string, metadata: record, name: string, uri: string>, link: string, metadata: record<connections: record<metadata: record>, interactions: record<buy: record, rent: record, subscribe: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, trailer: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-vod-backgrounds: "table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>"
    create-vod-background: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    delete-vod-background: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-vod-background: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    edit-vod-background: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-vod-genres-by-ondemand-id: "table<canonical: string, interactions: record<page: record>, link: string, metadata: record<connections: record>, name: string, uri: string>"
    get-vod-genre-by-ondemand-id: "record<canonical: string, interactions: record<page: record<added: bool, options: list, uri: string>>, link: string, metadata: record<connections: record<pages: record>>, name: string, uri: string>"
    add-vod-genre: "record<canonical: string, interactions: record<page: record<added: bool, options: list, uri: string>>, link: string, metadata: record<connections: record<pages: record>>, name: string, uri: string>"
    get-vod-likes: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    get-vod-posters: "table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>"
    add-vod-poster: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-vod-poster: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    edit-vod-poster: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-vod-promotions: "record<access_type: string, discount_type: string, download: bool, label: string, metadata: record<connections: record<codes: record>>, percent_off: float, product_type: string, stream_period: string, total: float, type: string, uri: string>"
    create-vod-promotion: "record<access_type: string, discount_type: string, download: bool, label: string, metadata: record<connections: record<codes: record>>, percent_off: float, product_type: string, stream_period: string, total: float, type: string, uri: string>"
    get-vod-promotion: "record<access_type: string, discount_type: string, download: bool, label: string, metadata: record<connections: record<codes: record>>, percent_off: float, product_type: string, stream_period: string, total: float, type: string, uri: string>"
    get-vod-promotion-codes: "record<code: string, link: string, max_uses: float, uses: float>"
    delete-vod-regions: "table<country_code: string, country_name: string, uri: string>"
    get-vod-regions: "table<country_code: string, country_name: string, uri: string>"
    set-vod-regions: "record<country_code: string, country_name: string, uri: string>"
    get-vod-region: "record<country_code: string, country_name: string, uri: string>"
    add-vod-region: "record<country_code: string, country_name: string, uri: string>"
    get-vod-seasons: "table<description: string, metadata: record<connections: record>, name: string, position: float, resource_key: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    get-vod-season: "record<description: string, metadata: record<connections: record<videos: record>>, name: string, position: float, resource_key: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-vod-season-videos: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-vod-videos: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-vod-video: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    add-video-to-vod: "record<buy: record<active: bool, price: record, purchased: bool>, description: string, duration: string, episode: float, interactions: record<page: record<added: bool, options: list, uri: string>>, link: string, metadata: record<connections: record<season: record>, interactions: record<likes: record, watchlater: record>>, name: string, options: list<string>, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, play_progress: float, position: float, release_date: string, release_year: float, rent: record<active: bool, price: record, purchased: bool>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-regions: "table<country_code: string, country_name: string, uri: string>"
    get-region: "record<country_code: string, country_name: string, uri: string>"
    get-tag: "record<canonical: string, metadata: record<connections: record<videos: record>>, name: string, resource_key: string, uri: string>"
    get-videos-with-tag: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    delete-token: "record<access_token: string, app: record<name: string, uri: string>, expires_on: string, refresh_token: string, scope: string, token_type: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    search-users: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    get-user: "record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record<albums: record, appearances: record, block: record, categories: record, channels: record, feed: record, folders: record, followers: record, following: record, groups: record, likes: record, moderated_channels: record, pictures: record, portfolios: record, recommended_channels: record, recommended_users: record, shared: record, videos: record, watched_videos: record, watchlater: record>, interactions: record<add_privacy_user: record, block: record, follow: record, report: record>>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preferences: record<videos: record<privacy: record>>, resource_key: string, upload_quota: record<lifetime: record<free: float, max: float, used: float>, periodic: record<free: float, max: float, reset_date: string, used: float>, space: record<free: float, max: float, showing: string, used: float>>, uri: string, websites: table<description: string, link: string, name: string>>"
    edit-user: "record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record<albums: record, appearances: record, block: record, categories: record, channels: record, feed: record, folders: record, followers: record, following: record, groups: record, likes: record, moderated_channels: record, pictures: record, portfolios: record, recommended_channels: record, recommended_users: record, shared: record, videos: record, watched_videos: record, watchlater: record>, interactions: record<add_privacy_user: record, block: record, follow: record, report: record>>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preferences: record<videos: record<privacy: record>>, resource_key: string, upload_quota: record<lifetime: record<free: float, max: float, used: float>, periodic: record<free: float, max: float, reset_date: string, used: float>, space: record<free: float, max: float, showing: string, used: float>>, uri: string, websites: table<description: string, link: string, name: string>>"
    get-albums: "table<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, web_brand_color: bool, web_custom_logo: bool>"
    create-album: "record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool>"
    get-album: "record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool>"
    edit-album: "record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool>"
    get-album-custom-thumbs: "table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>"
    create-album-custom-thumb: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-album-custom-thumbnail: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    replace-album-custom-thumb: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-album-logos: "table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>"
    create-album-logo: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-album-logo: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    replace-album-logo: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-album-videos: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-album-video: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    set-video-as-album-thumbnail: "record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool>"
    get-appearances: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-category-subscriptions: "table<icon: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, last_video_featured_time: string, link: string, metadata: record<connections: record, interactions: record>, name: string, parent: record<link: string, name: string, uri: string>, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, resource_key: string, subcategories: list<record>, top_level: bool, uri: string>"
    get-channel-subscriptions: "table<categories: list<record>, created_time: string, description: string, header: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<view: string>, resource_key: string, tags: list<record>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    get-custom-logos: "table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>"
    create-custom-logo: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-custom-logo: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-feed: "table<category: record<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, channel: record<categories: list, created_time: string, description: string, header: record, link: string, metadata: record, modified_time: string, name: string, pictures: record, privacy: record, resource_key: string, tags: list, uri: string, user: record>, clip: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, group: record<created_time: string, description: string, link: string, metadata: record, modified_time: string, name: string, pictures: record, privacy: record, resource_key: string, uri: string, user: record>, metadata: record<connections: record>, tag: record<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, time: string, type: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    get-followers: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    get-user-following: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    get-user-groups: "table<created_time: string, description: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<comment: string, invite: string, join: string, videos: string, view: string>, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    get-likes: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-user-vods: "table<background: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record, rent: record>, film: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, genres: list<record>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, trailer: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    create-vod: "record<background: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record<active: bool, price: float>, rent: record<active: bool, period: string, price: float>>, film: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, genres: table<canonical: string, interactions: record, link: string, metadata: record, name: string, uri: string>, link: string, metadata: record<connections: record<metadata: record>, interactions: record<buy: record, rent: record, subscribe: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, trailer: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    check-if-vod-was-purchased: "record<background: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record<active: bool, price: float>, rent: record<active: bool, period: string, price: float>>, film: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, genres: table<canonical: string, interactions: record, link: string, metadata: record, name: string, uri: string>, link: string, metadata: record<connections: record<metadata: record>, interactions: record<buy: record, rent: record, subscribe: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, trailer: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-pictures: "table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>"
    create-picture: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-picture: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    edit-picture: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-portfolios: "table<created_time: string, description: string, link: string, metadata: record<connections: record>, modified_time: string, name: string, sort: string, uri: string>"
    get-portfolio: "record<created_time: string, description: string, link: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, sort: string, uri: string>"
    get-portfolio-videos: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-portfolio-video: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    get-embed-presets: "table<metadata: record<connections: record>, name: string, settings: record<buttons: record, logos: record, outro: record>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    get-embed-preset: "record<metadata: record<connections: record<videos: record>>, name: string, settings: record<buttons: record<embed: bool, hd: bool, like: bool, share: bool, vote: bool, watchlater: bool>, logos: record<custom: bool, sticky_custom: bool, vimeo: bool>, outro: record<clips: string, link: record, text: string, type: string, videos: string>>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    edit-embed-preset: "record<metadata: record<connections: record<videos: record>>, name: string, settings: record<buttons: record<embed: bool, hd: bool, like: bool, share: bool, vote: bool, watchlater: bool>, logos: record<custom: bool, sticky_custom: bool, vimeo: bool>, outro: record<clips: string, link: record, text: string, type: string, videos: string>>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-embed-preset-videos: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-projects: "table<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    create-project: "record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-project: "record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    edit-project: "record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-project-videos: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-upload-attempt: "record<clip: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, complete_uri: string, form: string, ticket_id: string, upload_link: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-videos: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    upload-video: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    check-if-user-owns-video: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    get-watch-later-queue: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    check-watch-later-queue: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    search-videos: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
    get-video: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    edit-video: "record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>"
    get-available-video-channels: "table<categories: list<record>, created_time: string, description: string, header: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<view: string>, resource_key: string, tags: list<record>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    get-video-categories: "table<icon: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, last_video_featured_time: string, link: string, metadata: record<connections: record, interactions: record>, name: string, parent: record<link: string, name: string, uri: string>, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, resource_key: string, subcategories: list<record>, top_level: bool, uri: string>"
    suggest-video-category: "record<icon: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, last_video_featured_time: string, link: string, metadata: record<connections: record<channels: record, groups: record, users: record, videos: record>, interactions: record<follow: record>>, name: string, parent: record<link: string, name: string, uri: string>, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, resource_key: string, subcategories: table<link: string, name: string, uri: string>, top_level: bool, uri: string>"
    get-comments: "table<created_on: string, metadata: record<connections: record>, resource_key: string, text: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    create-comment: "record<created_on: string, metadata: record<connections: record<replies: record>>, resource_key: string, text: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-comment: "record<created_on: string, metadata: record<connections: record<replies: record>>, resource_key: string, text: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    edit-comment: "record<created_on: string, metadata: record<connections: record<replies: record>>, resource_key: string, text: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-comment-replies: "table<created_on: string, metadata: record<connections: record>, resource_key: string, text: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>"
    create-comment-reply: "record<created_on: string, metadata: record<connections: record<replies: record>>, resource_key: string, text: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-video-credits: "table<name: string, role: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, video: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>>"
    add-video-credit: "record<name: string, role: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, video: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>>"
    get-video-credit: "record<name: string, role: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, video: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>>"
    edit-video-credit: "record<name: string, role: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, video: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>>"
    get-video-likes: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    get-video-thumbnails: "table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>"
    create-video-thumbnail: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-video-thumbnail: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    edit-video-thumbnail: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-video-privacy-domains: "table<allow_hd: bool, domain: string, uri: string>"
    get-video-privacy-users: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    add-video-privacy-users: "table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>"
    add-video-privacy-user: "record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record<albums: record, appearances: record, block: record, categories: record, channels: record, feed: record, folders: record, followers: record, following: record, groups: record, likes: record, moderated_channels: record, pictures: record, portfolios: record, recommended_channels: record, recommended_users: record, shared: record, videos: record, watched_videos: record, watchlater: record>, interactions: record<add_privacy_user: record, block: record, follow: record, report: record>>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preferences: record<videos: record<privacy: record>>, resource_key: string, upload_quota: record<lifetime: record<free: float, max: float, used: float>, periodic: record<free: float, max: float, reset_date: string, used: float>, space: record<free: float, max: float, showing: string, used: float>>, uri: string, websites: table<description: string, link: string, name: string>>"
    get-video-tags: "table<canonical: string, metadata: record<connections: record>, name: string, resource_key: string, uri: string>"
    add-video-tags: "table<canonical: string, metadata: record<connections: record>, name: string, resource_key: string, uri: string>"
    check-video-for-tag: "record<canonical: string, metadata: record<connections: record<videos: record>>, name: string, resource_key: string, uri: string>"
    add-video-tag: "record<canonical: string, metadata: record<connections: record<videos: record>>, name: string, resource_key: string, uri: string>"
    get-text-tracks: "table<active: bool, hls_link: string, hls_link_expires_time: string, language: string, link: string, link_expires_time: string, name: string, type: string, uri: string>"
    create-text-track: "record<active: bool, hls_link: string, hls_link_expires_time: string, language: string, link: string, link_expires_time: string, name: string, type: string, uri: string>"
    get-text-track: "record<active: bool, hls_link: string, hls_link_expires_time: string, language: string, link: string, link_expires_time: string, name: string, type: string, uri: string>"
    edit-text-track: "record<active: bool, hls_link: string, hls_link_expires_time: string, language: string, link: string, link_expires_time: string, name: string, type: string, uri: string>"
    create-video-custom-logo: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    get-video-custom-logo: "record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>"
    create-video-version: "record<active: bool, app: record<name: string, uri: string>, created_time: string, duration: float, filename: string, filesize: float, metadata: record<connections: record<video: record>>, modified_time: string, play: record<progressive: list<record>, status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, upload_date: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>"
    get-related-videos: "table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-endpoints" "get-categories" "get-category" "get-category-channels" "get-category-groups" "get-category-videos" "check-category-for-video" "get-channels" "create-channel" "delete-channel" "get-channel" "edit-channel" "get-channel-categories" "add-channel-categories" "delete-channel-category" "categorize-channel" "remove-channel-moderators" "get-channel-moderators" "replace-channel-moderators" "add-channel-moderators" "remove-channel-moderator" "get-channel-moderator" "add-channel-moderator" "get-channel-privacy-users" "set-channel-privacy-users" "delete-channel-privacy-user" "set-channel-privacy-user" "get-channel-tags" "add-tags-to-channel" "delete-tag-from-channel" "check-if-channel-has-tag" "add-channel-tag" "get-channel-subscribers" "remove-videos-from-channel" "get-channel-videos" "add-videos-to-channel" "delete-video-from-channel" "get-channel-video" "add-video-to-channel" "get-comments-alt1" "create-comment-alt1" "get-video-credits-alt1" "add-video-credit-alt1" "get-video-likes-alt1" "get-video-thumbnails-alt1" "create-video-thumbnail-alt1" "get-video-privacy-users-alt1" "add-video-privacy-users-alt1" "get-text-tracks-alt1" "create-text-track-alt1" "get-content-ratings" "get-cc-licenses" "get-groups" "create-group" "delete-group" "get-group" "get-group-members" "get-group-videos" "delete-video-from-group" "get-group-video" "add-video-to-group" "get-languages" "get-user-alt1" "edit-user-alt1" "get-albums-alt1" "create-album-alt1" "delete-album-alt1" "get-album-alt1" "edit-album-alt1" "get-album-videos-alt1" "replace-videos-in-album-alt1" "remove-video-from-album-alt1" "get-album-video-alt1" "add-video-to-album-alt1" "set-video-as-album-thumbnail-alt1" "get-appearances-alt1" "get-category-subscriptions-alt1" "unsubscribe-from-category-alt1" "check-if-user-subscribed-to-category-alt1" "subscribe-to-category-alt1" "get-channel-subscriptions-alt1" "unsubscribe-from-channel-alt1" "check-if-user-subscribed-to-channel-alt1" "subscribe-to-channel-alt1" "get-custom-logos-alt1" "create-custom-logo-alt1" "get-custom-logo-alt1" "get-feed-alt1" "get-followers-alt1" "get-user-following-alt1" "follow-users-alt1" "unfollow-user-alt1" "check-if-user-is-following-alt1" "follow-user-alt1" "get-user-groups-alt1" "leave-group-alt1" "check-if-user-joined-group-alt1" "join-group-alt1" "get-likes-alt1" "unlike-video-alt1" "check-if-user-liked-video-alt1" "like-video-alt1" "get-user-vods-alt1" "create-vod-alt1" "get-vod-purchases" "check-if-vod-was-purchased-alt1" "get-pictures-alt1" "create-picture-alt1" "delete-picture-alt1" "get-picture-alt1" "edit-picture-alt1" "get-portfolios-alt1" "get-portfolio-alt1" "get-portfolio-videos-alt1" "delete-video-from-portfolio-alt1" "get-portfolio-video-alt1" "add-video-to-portfolio-alt1" "get-embed-presets-alt1" "get-embed-preset-alt1" "edit-embed-preset-alt1" "get-embed-preset-videos-alt1" "get-projects-alt1" "create-project-alt1" "delete-project-alt1" "get-project-alt1" "edit-project-alt1" "remove-videos-from-project-alt1" "get-project-videos-alt1" "add-videos-to-project-alt1" "remove-video-from-project-alt1" "add-video-to-project-alt1" "get-videos-alt1" "upload-video-alt1" "check-if-user-owns-video-alt1" "delete-watch-history" "get-watch-history" "delete-from-watch-history" "get-watch-later-queue-alt1" "delete-video-from-watch-later-alt1" "check-watch-later-queue-alt1" "add-video-to-watch-later-alt1" "exchange-auth-code" "client-auth" "convert-access-token" "verify-token" "get-vod-genres" "get-vod-genre" "get-genre-vods" "get-genre-vod" "delete-vod-draft" "get-vod" "edit-vod" "get-vod-backgrounds" "create-vod-background" "delete-vod-background" "get-vod-background" "edit-vod-background" "get-vod-genres-by-ondemand-id" "delete-vod-genre" "get-vod-genre-by-ondemand-id" "add-vod-genre" "get-vod-likes" "get-vod-posters" "add-vod-poster" "get-vod-poster" "edit-vod-poster" "get-vod-promotions" "create-vod-promotion" "delete-vod-promotion" "get-vod-promotion" "get-vod-promotion-codes" "delete-vod-regions" "get-vod-regions" "set-vod-regions" "delete-vod-region" "get-vod-region" "add-vod-region" "get-vod-seasons" "get-vod-season" "get-vod-season-videos" "get-vod-videos" "delete-video-from-vod" "get-vod-video" "add-video-to-vod" "get-regions" "get-region" "get-tag" "get-videos-with-tag" "delete-token" "search-users" "get-user" "edit-user" "get-albums" "create-album" "delete-album" "get-album" "edit-album" "get-album-custom-thumbs" "create-album-custom-thumb" "delete-album-custom-thumbnail" "get-album-custom-thumbnail" "replace-album-custom-thumb" "get-album-logos" "create-album-logo" "delete-album-logo" "get-album-logo" "replace-album-logo" "get-album-videos" "replace-videos-in-album" "remove-video-from-album" "get-album-video" "add-video-to-album" "set-video-as-album-thumbnail" "get-appearances" "get-category-subscriptions" "unsubscribe-from-category" "check-if-user-subscribed-to-category" "subscribe-to-category" "get-channel-subscriptions" "unsubscribe-from-channel" "check-if-user-subscribed-to-channel" "subscribe-to-channel" "get-custom-logos" "create-custom-logo" "get-custom-logo" "get-feed" "get-followers" "get-user-following" "follow-users" "unfollow-user" "check-if-user-is-following" "follow-user" "get-user-groups" "leave-group" "check-if-user-joined-group" "join-group" "get-likes" "unlike-video" "check-if-user-liked-video" "like-video" "get-user-vods" "create-vod" "check-if-vod-was-purchased" "get-pictures" "create-picture" "delete-picture" "get-picture" "edit-picture" "get-portfolios" "get-portfolio" "get-portfolio-videos" "delete-video-from-portfolio" "get-portfolio-video" "add-video-to-portfolio" "get-embed-presets" "get-embed-preset" "edit-embed-preset" "get-embed-preset-videos" "get-projects" "create-project" "delete-project" "get-project" "edit-project" "remove-videos-from-project" "get-project-videos" "add-videos-to-project" "remove-video-from-project" "add-video-to-project" "complete-streaming-upload" "get-upload-attempt" "get-videos" "upload-video" "check-if-user-owns-video" "get-watch-later-queue" "delete-video-from-watch-later" "check-watch-later-queue" "add-video-to-watch-later" "search-videos" "delete-video" "get-video" "edit-video" "get-available-video-channels" "get-video-categories" "suggest-video-category" "get-comments" "create-comment" "delete-comment" "get-comment" "edit-comment" "get-comment-replies" "create-comment-reply" "get-video-credits" "add-video-credit" "delete-video-credit" "get-video-credit" "edit-video-credit" "get-video-likes" "get-video-thumbnails" "create-video-thumbnail" "delete-video-thumbnail" "get-video-thumbnail" "edit-video-thumbnail" "delete-video-embed-preset" "get-video-embed-preset" "add-video-embed-preset" "get-video-privacy-domains" "delete-video-privacy-domain" "add-video-privacy-domain" "get-video-privacy-users" "add-video-privacy-users" "delete-video-privacy-user" "add-video-privacy-user" "get-video-tags" "add-video-tags" "delete-video-tag" "check-video-for-tag" "add-video-tag" "get-text-tracks" "create-text-track" "delete-text-track" "get-text-track" "edit-text-track" "create-video-custom-logo" "get-video-custom-logo" "create-video-version" "get-related-videos" "commands"] | sort) } | get name | first)
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

# Get an API specification
#
# GET /
# Returns: record<methods: list<string>, path: string>
# operationId: get_endpoints
export def "get-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --openapi: oneof<nothing, bool> # Return an OpenAPI specification. (e.g. true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/"
    query: [{name: openapi, var: openapi}]
    accept: ["application/vnd.vimeo.endpoint+json"]
    ok: [200]
    auth: bearer
  } {
    openapi: $openapi
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all categories
#
# GET /categories
# Returns: table<icon: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, last_video_featured_time: string, link: string, metadata: record<connections: record, interactions: record>, name: string, parent: record<link: string, name: string, uri: string>, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, resource_key: string, subcategories: list<record>, top_level: bool, uri: string>
# operationId: get_categories
export def "get-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/categories"
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.category+json"]
    ok: [200]
    auth: bearer
  } {
    direction: $direction, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific category
#
# GET /categories/{category}
# Returns: record<icon: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, last_video_featured_time: string, link: string, metadata: record<connections: record<channels: record, groups: record, users: record, videos: record>, interactions: record<follow: record>>, name: string, parent: record<link: string, name: string, uri: string>, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, resource_key: string, subcategories: table<link: string, name: string, uri: string>, top_level: bool, uri: string>
# operationId: get_category
export def "get-category" [
  category: string
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
    path: "/categories/{category}"
    path_params: [{name: category, var: category}]
    accept: ["application/vnd.vimeo.category+json"]
    ok: [200]
    auth: bearer
  } {
    category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the channels in a category
#
# GET /categories/{category}/channels
# Returns: table<categories: list<record>, created_time: string, description: string, header: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<view: string>, resource_key: string, tags: list<record>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_category_channels
export def "get-category-channels" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-1 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/categories/{category}/channels"
    path_params: [{name: category, var: category}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.channel+json"]
    ok: [200]
    auth: bearer
  } {
    category: $category, direction: $direction, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the groups in a category
#
# GET /categories/{category}/groups
# Returns: table<created_time: string, description: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<comment: string, invite: string, join: string, videos: string, view: string>, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_category_groups
export def "get-category-groups" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-2 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/categories/{category}/groups"
    path_params: [{name: category, var: category}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.group+json"]
    ok: [200]
    auth: bearer
  } {
    category: $category, direction: $direction, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos in a category
#
# GET /categories/{category}/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_category_videos
export def "get-category-videos" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer # The attribute by which to filter the results. Option descriptions: * `conditional_featured` - Featured (promoted) videos
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-3 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/categories/{category}/videos"
    path_params: [{name: category, var: category}]
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: filter_embeddable, var: filter_embeddable}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    category: $category, direction: $direction, filter: $filter, filter_embeddable: $filter_embeddable, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check for a video in a category
#
# GET /categories/{category}/videos/{video_id}
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: check_category_for_video
export def "check-category-for-video" [
  category: string
  video_id: float
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
    path: "/categories/{category}/videos/{video_id}"
    path_params: [{name: category, var: category}, {name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    category: $category, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all channels
#
# GET /channels
# Returns: table<categories: list<record>, created_time: string, description: string, header: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<view: string>, resource_key: string, tags: list<record>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_channels
export def "get-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-1 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-4 # The way to sort the results. Option descriptions: * `relevant` - Relevant sorting is available only for search queries.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/channels"
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.channel+json"]
    ok: [200]
    auth: bearer
  } {
    direction: $direction, filter: $filter, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a channel
#
# POST /channels
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, created_time: string, description: string, header: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, link: string, metadata: record<connections: record<privacy_users: record, users: record, videos: record>, interactions: record<add_moderators: record, add_to: record, follow: record, moderate_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<view: string>, resource_key: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: create_channel
export def "create-channel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the channel. (e.g. We really love videos, and these are the videos we really, really love.)
  --link: string # The link to access the channel. You can use a custom name in the URL in place of a numeric channel ID, as in `/channels/{url_custom}`. (e.g. staffpicks)
  name: string # The name of the channel. (e.g. Vimeo Staff Picks)
  privacy: string@privacy-completer # The privacy level of the channel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels"
    body: {content_type: "application/vnd.vimeo.channel+json", kind: json, fields: [{name: description, var: description}, {name: link, var: link}, {name: name, var: name}, {name: privacy, var: privacy}]}
    accept: ["application/vnd.vimeo.channel+json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, link: $link, name: $name, privacy: $privacy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a channel
#
# DELETE /channels/{channel_id}
# operationId: delete_channel
export def "delete-channel" [
  channel_id: float
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
    path: "/channels/{channel_id}"
    path_params: [{name: channel_id, var: channel_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific channel
#
# GET /channels/{channel_id}
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, created_time: string, description: string, header: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, link: string, metadata: record<connections: record<privacy_users: record, users: record, videos: record>, interactions: record<add_moderators: record, add_to: record, follow: record, moderate_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<view: string>, resource_key: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: get_channel
export def "get-channel" [
  channel_id: float
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
    path: "/channels/{channel_id}"
    path_params: [{name: channel_id, var: channel_id}]
    accept: ["application/vnd.vimeo.channel+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a channel
#
# PATCH /channels/{channel_id}
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, created_time: string, description: string, header: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, link: string, metadata: record<connections: record<privacy_users: record, users: record, videos: record>, interactions: record<add_moderators: record, add_to: record, follow: record, moderate_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<view: string>, resource_key: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: edit_channel
export def "edit-channel" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the channel. (e.g. We really love videos, and these are the videos we really, really love.)
  --link: string # The link to access the channel. You can use a custom name in the URL in place of a numeric channel ID, as in `/channels/{url_custom}`. Submitting `""` for this field removes the link alias. (e.g. staffpicks)
  --name: string # The name of the channel. (e.g. Vimeo Staff Picks)
  --privacy: string@privacy-completer-1 # The privacy level of the channel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/channels/{channel_id}"
    path_params: [{name: channel_id, var: channel_id}]
    body: {content_type: "application/vnd.vimeo.channel+json", kind: json, fields: [{name: description, var: description}, {name: link, var: link}, {name: name, var: name}, {name: privacy, var: privacy}]}
    accept: ["application/vnd.vimeo.channel+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, description: $description, link: $link, name: $name, privacy: $privacy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the categories in a channel
#
# GET /channels/{channel_id}/categories
# Returns: table<icon: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, last_video_featured_time: string, link: string, metadata: record<connections: record, interactions: record>, name: string, parent: record<link: string, name: string, uri: string>, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, resource_key: string, subcategories: list<record>, top_level: bool, uri: string>
# operationId: get_channel_categories
export def "get-channel-categories" [
  channel_id: float
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
    path: "/channels/{channel_id}/categories"
    path_params: [{name: channel_id, var: channel_id}]
    accept: ["application/vnd.vimeo.category+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a list of categories to a channel
#
# PUT /channels/{channel_id}/categories
# operationId: add_channel_categories
export def "add-channel-categories" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channels: list<string> # The array of category URIs to add.
]: any -> any {
  $in | http-request {
    method: put
    path: "/channels/{channel_id}/categories"
    path_params: [{name: channel_id, var: channel_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: channels, var: channels}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id, channels: $channels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a category from a channel
#
# DELETE /channels/{channel_id}/categories/{category}
# operationId: delete_channel_category
export def "delete-channel-category" [
  channel_id: float
  category: string
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
    path: "/channels/{channel_id}/categories/{category}"
    path_params: [{name: channel_id, var: channel_id}, {name: category, var: category}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Categorize a channel
#
# PUT /channels/{channel_id}/categories/{category}
# operationId: categorize_channel
export def "categorize-channel" [
  channel_id: float
  category: string
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
    method: put
    path: "/channels/{channel_id}/categories/{category}"
    path_params: [{name: channel_id, var: channel_id}, {name: category, var: category}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a list of channel moderators
#
# DELETE /channels/{channel_id}/moderators
# Returns: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record<albums: record, appearances: record, block: record, categories: record, channels: record, feed: record, folders: record, followers: record, following: record, groups: record, likes: record, moderated_channels: record, pictures: record, portfolios: record, recommended_channels: record, recommended_users: record, shared: record, videos: record, watched_videos: record, watchlater: record>, interactions: record<add_privacy_user: record, block: record, follow: record, report: record>>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preferences: record<videos: record<privacy: record>>, resource_key: string, upload_quota: record<lifetime: record<free: float, max: float, used: float>, periodic: record<free: float, max: float, reset_date: string, used: float>, space: record<free: float, max: float, showing: string, used: float>>, uri: string, websites: table<description: string, link: string, name: string>>
# operationId: remove_channel_moderators
export def "remove-channel-moderators" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_uri: string # The URI of a user to remove as a moderator. (e.g. /users/152184)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/channels/{channel_id}/moderators"
    path_params: [{name: channel_id, var: channel_id}]
    body: {content_type: "application/vnd.vimeo.user+json", kind: json, fields: [{name: user_uri, var: user_uri}]}
    accept: ["application/vnd.vimeo.user+json"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id, user_uri: $user_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the moderators in a channel
#
# GET /channels/{channel_id}/moderators
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: get_channel_moderators
export def "get-channel-moderators" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channel_id}/moderators"
    path_params: [{name: channel_id, var: channel_id}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, direction: $direction, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace the moderators of a channel
#
# PATCH /channels/{channel_id}/moderators
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: replace_channel_moderators
export def "replace-channel-moderators" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_uri: string # The URI of the user to add as a moderator. (e.g. /users/152184)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/channels/{channel_id}/moderators"
    path_params: [{name: channel_id, var: channel_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: user_uri, var: user_uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, user_uri: $user_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a list of channel moderators
#
# PUT /channels/{channel_id}/moderators
# operationId: add_channel_moderators
export def "add-channel-moderators" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_uri: string # The URI of a user to add as a moderator. (e.g. /users/152184)
]: any -> any {
  $in | http-request {
    method: put
    path: "/channels/{channel_id}/moderators"
    path_params: [{name: channel_id, var: channel_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: user_uri, var: user_uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, user_uri: $user_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a specific channel moderator
#
# DELETE /channels/{channel_id}/moderators/{user_id}
# operationId: remove_channel_moderator
export def "remove-channel-moderator" [
  channel_id: float
  user_id: float
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
    path: "/channels/{channel_id}/moderators/{user_id}"
    path_params: [{name: channel_id, var: channel_id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific channel moderator
#
# GET /channels/{channel_id}/moderators/{user_id}
# Returns: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record<albums: record, appearances: record, block: record, categories: record, channels: record, feed: record, folders: record, followers: record, following: record, groups: record, likes: record, moderated_channels: record, pictures: record, portfolios: record, recommended_channels: record, recommended_users: record, shared: record, videos: record, watched_videos: record, watchlater: record>, interactions: record<add_privacy_user: record, block: record, follow: record, report: record>>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preferences: record<videos: record<privacy: record>>, resource_key: string, upload_quota: record<lifetime: record<free: float, max: float, used: float>, periodic: record<free: float, max: float, reset_date: string, used: float>, space: record<free: float, max: float, showing: string, used: float>>, uri: string, websites: table<description: string, link: string, name: string>>
# operationId: get_channel_moderator
export def "get-channel-moderator" [
  channel_id: float
  user_id: float
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
    path: "/channels/{channel_id}/moderators/{user_id}"
    path_params: [{name: channel_id, var: channel_id}, {name: user_id, var: user_id}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a specific channel moderator
#
# PUT /channels/{channel_id}/moderators/{user_id}
# operationId: add_channel_moderator
export def "add-channel-moderator" [
  channel_id: float
  user_id: float
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
    method: put
    path: "/channels/{channel_id}/moderators/{user_id}"
    path_params: [{name: channel_id, var: channel_id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    channel_id: $channel_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the users who can view a private channel
#
# GET /channels/{channel_id}/privacy/users
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: get_channel_privacy_users
export def "get-channel-privacy-users" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channel_id}/privacy/users"
    path_params: [{name: channel_id, var: channel_id}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, direction: $direction, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permit a list of users to view a private channel
#
# PUT /channels/{channel_id}/privacy/users
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: set_channel_privacy_users
export def "set-channel-privacy-users" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  users: list<string> # The array of either the user URIs or the user IDs to permit to view the private channel.
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/channels/{channel_id}/privacy/users"
    path_params: [{name: channel_id, var: channel_id}]
    body: {content_type: "application/vnd.vimeo.user+json", kind: json, fields: [{name: users, var: users}]}
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restrict a user from viewing a private channel
#
# DELETE /channels/{channel_id}/privacy/users/{user_id}
# operationId: delete_channel_privacy_user
export def "delete-channel-privacy-user" [
  channel_id: float
  user_id: float
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
    path: "/channels/{channel_id}/privacy/users/{user_id}"
    path_params: [{name: channel_id, var: channel_id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permit a specific user to view a private channel
#
# PUT /channels/{channel_id}/privacy/users/{user_id}
# operationId: set_channel_privacy_user
export def "set-channel-privacy-user" [
  channel_id: float
  user_id: float
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
    method: put
    path: "/channels/{channel_id}/privacy/users/{user_id}"
    path_params: [{name: channel_id, var: channel_id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the tags that have been added to a channel
#
# GET /channels/{channel_id}/tags
# Returns: table<canonical: string, metadata: record<connections: record>, name: string, resource_key: string, uri: string>
# operationId: get_channel_tags
export def "get-channel-tags" [
  channel_id: float
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
    path: "/channels/{channel_id}/tags"
    path_params: [{name: channel_id, var: channel_id}]
    accept: ["application/vnd.vimeo.tag+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a list of tags to a channel
#
# PUT /channels/{channel_id}/tags
# Returns: table<canonical: string, metadata: record<connections: record>, name: string, resource_key: string, uri: string>
# operationId: add_tags_to_channel
export def "add-tags-to-channel" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  tag: list<string> # An array of tags to assign.
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/channels/{channel_id}/tags"
    path_params: [{name: channel_id, var: channel_id}]
    body: {content_type: "application/vnd.vimeo.tag+json", kind: json, fields: [{name: tag, var: tag}]}
    accept: ["application/vnd.vimeo.tag+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a tag from a channel
#
# DELETE /channels/{channel_id}/tags/{word}
# operationId: delete_tag_from_channel
export def "delete-tag-from-channel" [
  channel_id: float
  word: string
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
    path: "/channels/{channel_id}/tags/{word}"
    path_params: [{name: channel_id, var: channel_id}, {name: word, var: word}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id, word: $word
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a tag has been added to a channel
#
# GET /channels/{channel_id}/tags/{word}
# operationId: check_if_channel_has_tag
export def "check-if-channel-has-tag" [
  channel_id: float
  word: string
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
    path: "/channels/{channel_id}/tags/{word}"
    path_params: [{name: channel_id, var: channel_id}, {name: word, var: word}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id, word: $word
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a specific tag to a channel
#
# PUT /channels/{channel_id}/tags/{word}
# operationId: add_channel_tag
export def "add-channel-tag" [
  channel_id: float
  word: string
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
    method: put
    path: "/channels/{channel_id}/tags/{word}"
    path_params: [{name: channel_id, var: channel_id}, {name: word, var: word}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id, word: $word
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the followers of a channel
#
# GET /channels/{channel_id}/users
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: get_channel_subscribers
export def "get-channel-subscribers" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-2 # The attribute by which to filter the results. (required)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channel_id}/users"
    path_params: [{name: channel_id, var: channel_id}]
    query: [{name: direction, var: direction}, {name: filter, var: filter, required: true, default: moderators}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, direction: $direction, filter: $filter, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a list of videos from a channel
#
# DELETE /channels/{channel_id}/videos
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: remove_videos_from_channel
export def "remove-videos-from-channel" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  video_uri: string # The URI of a video to remove. (e.g. /videos/258684937)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/channels/{channel_id}/videos"
    path_params: [{name: channel_id, var: channel_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: video_uri, var: video_uri}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id, video_uri: $video_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos in a channel
#
# GET /channels/{channel_id}/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_channel_videos
export def "get-channel-videos" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page that contains the video URI. (e.g. /videos/258684937)
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-6 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channel_id}/videos"
    path_params: [{name: channel_id, var: channel_id}]
    query: [{name: containing_uri, var: containing_uri}, {name: direction, var: direction}, {name: filter, var: filter}, {name: filter_embeddable, var: filter_embeddable}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200, 304]
    auth: bearer
  } {
    channel_id: $channel_id, containing_uri: $containing_uri, direction: $direction, filter: $filter, filter_embeddable: $filter_embeddable, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a list of videos to a channel
#
# PUT /channels/{channel_id}/videos
# operationId: add_videos_to_channel
export def "add-videos-to-channel" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  video_uri: string # The URI of a video to add. (e.g. /videos/258684937)
]: any -> any {
  $in | http-request {
    method: put
    path: "/channels/{channel_id}/videos"
    path_params: [{name: channel_id, var: channel_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: video_uri, var: video_uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, video_uri: $video_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a specific video from a channel
#
# DELETE /channels/{channel_id}/videos/{video_id}
# operationId: delete_video_from_channel
export def "delete-video-from-channel" [
  channel_id: float
  video_id: float
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
    path: "/channels/{channel_id}/videos/{video_id}"
    path_params: [{name: channel_id, var: channel_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific video in a channel
#
# GET /channels/{channel_id}/videos/{video_id}
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: get_channel_video
export def "get-channel-video" [
  channel_id: float
  video_id: float
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
    path: "/channels/{channel_id}/videos/{video_id}"
    path_params: [{name: channel_id, var: channel_id}, {name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a specific video to a channel
#
# PUT /channels/{channel_id}/videos/{video_id}
# operationId: add_video_to_channel
export def "add-video-to-channel" [
  channel_id: float
  video_id: float
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
    method: put
    path: "/channels/{channel_id}/videos/{video_id}"
    path_params: [{name: channel_id, var: channel_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the comments on a video
#
# GET /channels/{channel_id}/videos/{video_id}/comments
# Returns: table<created_on: string, metadata: record<connections: record>, resource_key: string, text: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_comments_alt1
export def "get-comments-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channel_id}/videos/{video_id}/comments"
    path_params: [{name: channel_id, var: channel_id}, {name: video_id, var: video_id}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.comment+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, video_id: $video_id, direction: $direction, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a comment to a video
#
# POST /channels/{channel_id}/videos/{video_id}/comments
# Returns: record<created_on: string, metadata: record<connections: record<replies: record>>, resource_key: string, text: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: create_comment_alt1
export def "create-comment-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # The text of the comment. (e.g. I love this!)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{channel_id}/videos/{video_id}/comments"
    path_params: [{name: channel_id, var: channel_id}, {name: video_id, var: video_id}]
    body: {content_type: "application/vnd.vimeo.comment+json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/vnd.vimeo.comment+json"]
    ok: [201]
    auth: bearer
  } {
    channel_id: $channel_id, video_id: $video_id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the credited users in a video
#
# GET /channels/{channel_id}/videos/{video_id}/credits
# Returns: table<name: string, role: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, video: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>>
# operationId: get_video_credits_alt1
export def "get-video-credits-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channel_id}/videos/{video_id}/credits"
    path_params: [{name: channel_id, var: channel_id}, {name: video_id, var: video_id}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.credit+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, video_id: $video_id, direction: $direction, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Credit a user in a video
#
# POST /channels/{channel_id}/videos/{video_id}/credits
# Returns: record<name: string, role: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, video: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>>
# operationId: add_video_credit_alt1
export def "add-video-credit-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email address of the credited person. (e.g. user@example.com)
  name: string # The name of the credited person. (e.g. Sam Doe)
  role: string # The role of the credited person. (e.g. Producer)
  user_uri: string # The URI of the Vimeo user who should be given credit in this video. (e.g. /users/152184)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{channel_id}/videos/{video_id}/credits"
    path_params: [{name: channel_id, var: channel_id}, {name: video_id, var: video_id}]
    body: {content_type: "application/vnd.vimeo.credit+json", kind: json, fields: [{name: email, var: email}, {name: name, var: name}, {name: role, var: role}, {name: user_uri, var: user_uri}]}
    accept: ["application/vnd.vimeo.credit+json"]
    ok: [201]
    auth: bearer
  } {
    channel_id: $channel_id, video_id: $video_id, email: $email, name: $name, role: $role, user_uri: $user_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the users who have liked a video
#
# GET /channels/{channel_id}/videos/{video_id}/likes
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: get_video_likes_alt1
export def "get-video-likes-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channel_id}/videos/{video_id}/likes"
    path_params: [{name: channel_id, var: channel_id}, {name: video_id, var: video_id}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, video_id: $video_id, direction: $direction, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the thumbnails of a video
#
# GET /channels/{channel_id}/videos/{video_id}/pictures
# Returns: table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>
# operationId: get_video_thumbnails_alt1
export def "get-video-thumbnails-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channel_id}/videos/{video_id}/pictures"
    path_params: [{name: channel_id, var: channel_id}, {name: video_id, var: video_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, video_id: $video_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a video thumbnail
#
# POST /channels/{channel_id}/videos/{video_id}/pictures
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: create_video_thumbnail_alt1
export def "create-video-thumbnail-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Whether the image created by the `time` field should be the default thumbnail for the video. (e.g. true)
  --time: float # Creates an image of the video from the given time offset. (e.g. 300)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{channel_id}/videos/{video_id}/pictures"
    path_params: [{name: channel_id, var: channel_id}, {name: video_id, var: video_id}]
    body: {content_type: "application/vnd.vimeo.picture+json", kind: json, fields: [{name: active, var: active}, {name: time, var: time}]}
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [201]
    auth: bearer
  } {
    channel_id: $channel_id, video_id: $video_id, active: $active, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the users who can view a user's private videos by default
#
# GET /channels/{channel_id}/videos/{video_id}/privacy/users
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: get_video_privacy_users_alt1
export def "get-video-privacy-users-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channel_id}/videos/{video_id}/privacy/users"
    path_params: [{name: channel_id, var: channel_id}, {name: video_id, var: video_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, video_id: $video_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permit a list of users to view a private video
#
# PUT /channels/{channel_id}/videos/{video_id}/privacy/users
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: add_video_privacy_users_alt1
export def "add-video-privacy-users-alt1" [
  channel_id: float
  video_id: float
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
    method: put
    path: "/channels/{channel_id}/videos/{video_id}/privacy/users"
    path_params: [{name: channel_id, var: channel_id}, {name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the text tracks of a video
#
# GET /channels/{channel_id}/videos/{video_id}/texttracks
# Returns: table<active: bool, hls_link: string, hls_link_expires_time: string, language: string, link: string, link_expires_time: string, name: string, type: string, uri: string>
# operationId: get_text_tracks_alt1
export def "get-text-tracks-alt1" [
  channel_id: float
  video_id: float
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
    path: "/channels/{channel_id}/videos/{video_id}/texttracks"
    path_params: [{name: channel_id, var: channel_id}, {name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.video.texttrack+json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a text track to a video
#
# POST /channels/{channel_id}/videos/{video_id}/texttracks
# Returns: record<active: bool, hls_link: string, hls_link_expires_time: string, language: string, link: string, link_expires_time: string, name: string, type: string, uri: string>
# operationId: create_text_track_alt1
export def "create-text-track-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Active text tracks appear in the player and are visible to other users. Only one text track per language can be active. (e.g. true)
  language: string # The language of the text track. For a complete list of valid languages, use the [/languages?filter=texttracks](https://developer.vimeo.com/api/endpoints/videos#GET/languages) endpoint. (e.g. en-US)
  name: string # The name of the text track. (e.g. Commentary)
  type: string@type-completer # The type of the text track.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{channel_id}/videos/{video_id}/texttracks"
    path_params: [{name: channel_id, var: channel_id}, {name: video_id, var: video_id}]
    body: {content_type: "application/vnd.vimeo.video.texttrack+json", kind: json, fields: [{name: active, var: active}, {name: language, var: language}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/vnd.vimeo.video.texttrack+json"]
    ok: [201]
    auth: bearer
  } {
    channel_id: $channel_id, video_id: $video_id, active: $active, language: $language, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all content ratings
#
# GET /contentratings
# Returns: table<code: string, name: string, uri: string>
# operationId: get_content_ratings
export def "get-content-ratings" [
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
    path: "/contentratings"
    accept: ["application/vnd.vimeo.contentrating+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Creative Commons licenses
#
# GET /creativecommons
# Returns: table<code: string, name: string, uri: string>
# operationId: get_cc_licenses
export def "get-cc-licenses" [
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
    path: "/creativecommons"
    accept: ["application/vnd.vimeo.creativecommons+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all groups
#
# GET /groups
# Returns: table<created_time: string, description: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<comment: string, invite: string, join: string, videos: string, view: string>, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_groups
export def "get-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-1 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-4 # The way to sort the results. Option descriptions: * `relevant` - Relevant sorting is available only for search queries.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/groups"
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.group+json"]
    ok: [200]
    auth: bearer
  } {
    direction: $direction, filter: $filter, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a group
#
# POST /groups
# Returns: record<created_time: string, description: string, link: string, metadata: record<connections: record<users: record, videos: record>, interactions: record<join: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<comment: string, invite: string, join: string, videos: string, view: string>, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: create_group
export def "create-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the new group. (e.g. Want to participate in our weekly Challenges? Join the Group to receive messages and new Challenges!)
  name: string # The name of the new group. (e.g. Vimeo Weekend Challenge)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups"
    body: {content_type: "application/vnd.vimeo.group+json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/vnd.vimeo.group+json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a group
#
# DELETE /groups/{group_id}
# operationId: delete_group
export def "delete-group" [
  group_id: float
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
    path: "/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific group
#
# GET /groups/{group_id}
# Returns: record<created_time: string, description: string, link: string, metadata: record<connections: record<users: record, videos: record>, interactions: record<join: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<comment: string, invite: string, join: string, videos: string, view: string>, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: get_group
export def "get-group" [
  group_id: float
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
    path: "/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    accept: ["application/vnd.vimeo.group+json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the members of a group
#
# GET /groups/{group_id}/users
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: get_group_members
export def "get-group-members" [
  group_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-2 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{group_id}/users"
    path_params: [{name: group_id, var: group_id}]
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, direction: $direction, filter: $filter, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos in a group
#
# GET /groups/{group_id}/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_group_videos
export def "get-group-videos" [
  group_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{group_id}/videos"
    path_params: [{name: group_id, var: group_id}]
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: filter_embeddable, var: filter_embeddable}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200, 304]
    auth: bearer
  } {
    group_id: $group_id, direction: $direction, filter: $filter, filter_embeddable: $filter_embeddable, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a video from a group
#
# DELETE /groups/{group_id}/videos/{video_id}
# operationId: delete_video_from_group
export def "delete-video-from-group" [
  group_id: float
  video_id: float
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
    path: "/groups/{group_id}/videos/{video_id}"
    path_params: [{name: group_id, var: group_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific video in a group
#
# GET /groups/{group_id}/videos/{video_id}
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: get_group_video
export def "get-group-video" [
  group_id: float
  video_id: float
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
    path: "/groups/{group_id}/videos/{video_id}"
    path_params: [{name: group_id, var: group_id}, {name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a video to a group
#
# PUT /groups/{group_id}/videos/{video_id}
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: add_video_to_group
export def "add-video-to-group" [
  group_id: float
  video_id: float
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
    method: put
    path: "/groups/{group_id}/videos/{video_id}"
    path_params: [{name: group_id, var: group_id}, {name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200, 202]
    auth: bearer
  } {
    group_id: $group_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all languages
#
# GET /languages
# Returns: table<code: string, name: string>
# operationId: get_languages
export def "get-languages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-4 # The attribute by which to filter the results. Option descriptions: * `texttracks` - Only return text track supported languages
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/languages"
    query: [{name: filter, var: filter}]
    accept: ["application/vnd.vimeo.language+json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user
#
# GET /me
# Returns: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record<albums: record, appearances: record, block: record, categories: record, channels: record, feed: record, folders: record, followers: record, following: record, groups: record, likes: record, moderated_channels: record, pictures: record, portfolios: record, recommended_channels: record, recommended_users: record, shared: record, videos: record, watched_videos: record, watchlater: record>, interactions: record<add_privacy_user: record, block: record, follow: record, report: record>>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preferences: record<videos: record<privacy: record>>, resource_key: string, upload_quota: record<lifetime: record<free: float, max: float, used: float>, periodic: record<free: float, max: float, reset_date: string, used: float>, space: record<free: float, max: float, showing: string, used: float>>, uri: string, websites: table<description: string, link: string, name: string>>
# operationId: get_user_alt1
export def "get-user-alt1" [
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
    path: "/me"
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a user
#
# PATCH /me
# Returns: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record<albums: record, appearances: record, block: record, categories: record, channels: record, feed: record, folders: record, followers: record, following: record, groups: record, likes: record, moderated_channels: record, pictures: record, portfolios: record, recommended_channels: record, recommended_users: record, shared: record, videos: record, watched_videos: record, watchlater: record>, interactions: record<add_privacy_user: record, block: record, follow: record, report: record>>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preferences: record<videos: record<privacy: record>>, resource_key: string, upload_quota: record<lifetime: record<free: float, max: float, used: float>, periodic: record<free: float, max: float, reset_date: string, used: float>, space: record<free: float, max: float, showing: string, used: float>>, uri: string, websites: table<description: string, link: string, name: string>>
# operationId: edit_user_alt1
export def "edit-user-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bio: string # The user's bio. (e.g. This is where you will find videos and news updates from the staff)
  --content-filter: list<string> # A list of values describing the content in this video. Find the full list in the [/contentratings](https://developer.vimeo.com/api/endpoints/videos#GET/contentratings) endpoint. You must provide a comma-separated list if you are using a query string or an array if you are using JSON.
  --link: string # The user's custom Vimeo URL slug. (e.g. staff)
  --location: string # The user's location. (e.g. New York City)
  --name: string # The user's display name. (e.g. Vimeo Staff)
  --password: string # The default password for all future videos that this user uploads. To use this field, the `videos.privacy.view` field must be `password`. (e.g. hunter1)
  --videos: record # shape: {privacy?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/me"
    body: {content_type: "application/vnd.vimeo.user+json", kind: json, fields: [{name: bio, var: bio}, {name: content_filter, var: content_filter}, {name: link, var: link}, {name: location, var: location}, {name: name, var: name}, {name: password, var: password}, {name: videos, var: videos}]}
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    bio: $bio, content_filter: $content_filter, link: $link, location: $location, name: $name, password: $password, videos: $videos
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the albums that belong to a user
#
# GET /me/albums
# Returns: table<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, web_brand_color: bool, web_custom_logo: bool>
# operationId: get_albums_alt1
export def "get-albums-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-8 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/albums"
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    direction: $direction, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an album
#
# POST /me/albums
# Returns: record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool>
# operationId: create_album_alt1
export def "create-album-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brand-color: string # The hexadecimal code for the color of the player buttons. (e.g. ff66ee)
  --description: string # The description of the album. (e.g. Vimeo holiday videos!)
  --hide-nav: oneof<nothing, bool> # Whether to hide Vimeo navigation when displaying the album. (e.g. true)
  --layout: string@layout-completer # The type of layout for presenting the album.
  name: string # The name of the album. (e.g. Vimeo Holiday Videos!)
  --password: string # The album's password. Required only if **privacy** is `password`. (e.g. hunter1)
  --privacy: string@privacy-completer-2 # The privacy level of the album.
  --review-mode: oneof<nothing, bool> # Whether album videos should use the review mode URL. (e.g. true)
  --sort: string@sort-completer-9 # The default sort order of the album's videos.
  --theme: string@theme-completer # The color theme of the album.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/me/albums"
    body: {content_type: "application/vnd.vimeo.album+json", kind: json, fields: [{name: brand_color, var: brand_color}, {name: description, var: description}, {name: hide_nav, var: hide_nav}, {name: layout, var: layout}, {name: name, var: name}, {name: password, var: password}, {name: privacy, var: privacy}, {name: review_mode, var: review_mode}, {name: sort, var: sort}, {name: theme, var: theme}]}
    accept: ["application/vnd.vimeo.album+json"]
    ok: [201]
    auth: bearer
  } {
    brand_color: $brand_color, description: $description, hide_nav: $hide_nav, layout: $layout, name: $name, password: $password, privacy: $privacy, review_mode: $review_mode, sort: $sort, theme: $theme
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an album
#
# DELETE /me/albums/{album_id}
# operationId: delete_album_alt1
export def "delete-album-alt1" [
  album_id: float
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
    path: "/me/albums/{album_id}"
    path_params: [{name: album_id, var: album_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    album_id: $album_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific album
#
# GET /me/albums/{album_id}
# Returns: record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool>
# operationId: get_album_alt1
export def "get-album-alt1" [
  album_id: float
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
    path: "/me/albums/{album_id}"
    path_params: [{name: album_id, var: album_id}]
    accept: ["application/vnd.vimeo.album+json"]
    ok: [200]
    auth: bearer
  } {
    album_id: $album_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit an album
#
# PATCH /me/albums/{album_id}
# Returns: record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool>
# operationId: edit_album_alt1
export def "edit-album-alt1" [
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brand-color: string # The hexadecimal code for the color of the player buttons. (e.g. ff66ee)
  --description: string # The description of the album. (e.g. Vimeo holiday videos!)
  --domain: string # The custom domain a user has selected for their album. (nullable, e.g. mycustomdomain.com)
  --hide-nav: oneof<nothing, bool> # Whether to hide Vimeo navigation when displaying the album. (e.g. true)
  --layout: string@layout-completer # The type of layout for presenting the album.
  --name: string # The name of the album. (e.g. Vimeo Holiday Videos!)
  --password: string # The album's password. Required only if **privacy** is `password`. (e.g. hunter1)
  --privacy: string@privacy-completer-2 # The privacy level of the album.
  --review-mode: oneof<nothing, bool> # Whether album videos should use the review mode URL. (e.g. true)
  --sort: string@sort-completer-9 # The default sort order of the album's videos.
  --theme: string@theme-completer # The color theme of the album.
  --url: string # The custom Vimeo URL a user has selected for their album. (nullable, e.g. my-custom-url)
  --use-custom-domain: oneof<nothing, bool> # Whether the user has opted in to use a custom domain for their album. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/me/albums/{album_id}"
    path_params: [{name: album_id, var: album_id}]
    body: {content_type: "application/vnd.vimeo.album+json", kind: json, fields: [{name: brand_color, var: brand_color}, {name: description, var: description}, {name: domain, var: domain}, {name: hide_nav, var: hide_nav}, {name: layout, var: layout}, {name: name, var: name}, {name: password, var: password}, {name: privacy, var: privacy}, {name: review_mode, var: review_mode}, {name: sort, var: sort}, {name: theme, var: theme}, {name: url, var: url}, {name: use_custom_domain, var: use_custom_domain}]}
    accept: ["application/vnd.vimeo.album+json"]
    ok: [200]
    auth: bearer
  } {
    album_id: $album_id, brand_color: $brand_color, description: $description, domain: $domain, hide_nav: $hide_nav, layout: $layout, name: $name, password: $password, privacy: $privacy, review_mode: $review_mode, sort: $sort, theme: $theme, url: $url, use_custom_domain: $use_custom_domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos in an album
#
# GET /me/albums/{album_id}/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_album_videos_alt1
export def "get-album-videos-alt1" [
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page containing the video URI. (e.g. /videos/258684937)
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --password: string # The password of the album. (e.g. hunter1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-10 # The way to sort the results.
  --weak-search: oneof<nothing, bool> # Whether to include private videos in the search. Please note that a separate search service provides this functionality. The service performs a partial text search on the video's name. (e.g. false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/albums/{album_id}/videos"
    path_params: [{name: album_id, var: album_id}]
    query: [{name: containing_uri, var: containing_uri}, {name: direction, var: direction}, {name: filter, var: filter}, {name: filter_embeddable, var: filter_embeddable}, {name: page, var: page}, {name: password, var: password}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}, {name: weak_search, var: weak_search}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    album_id: $album_id, containing_uri: $containing_uri, direction: $direction, filter: $filter, filter_embeddable: $filter_embeddable, page: $page, password: $password, per_page: $per_page, query: $query, sort: $sort, weak_search: $weak_search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace all the videos in an album
#
# PUT /me/albums/{album_id}/videos
# operationId: replace_videos_in_album_alt1
export def "replace-videos-in-album-alt1" [
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  videos: string # A comma-separated list of video URIs. (e.g. /videos/258684937,/videos/273576296)
]: any -> any {
  $in | http-request {
    method: put
    path: "/me/albums/{album_id}/videos"
    path_params: [{name: album_id, var: album_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: videos, var: videos}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    album_id: $album_id, videos: $videos
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a video from an album
#
# DELETE /me/albums/{album_id}/videos/{video_id}
# operationId: remove_video_from_album_alt1
export def "remove-video-from-album-alt1" [
  album_id: float
  video_id: float
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
    path: "/me/albums/{album_id}/videos/{video_id}"
    path_params: [{name: album_id, var: album_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    album_id: $album_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific video in an album
#
# GET /me/albums/{album_id}/videos/{video_id}
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: get_album_video_alt1
export def "get-album-video-alt1" [
  album_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # The password of the album. (e.g. hunter1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/albums/{album_id}/videos/{video_id}"
    path_params: [{name: album_id, var: album_id}, {name: video_id, var: video_id}]
    query: [{name: password, var: password}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    album_id: $album_id, video_id: $video_id, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a specific video to an album
#
# PUT /me/albums/{album_id}/videos/{video_id}
# operationId: add_video_to_album_alt1
export def "add-video-to-album-alt1" [
  album_id: float
  video_id: float
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
    method: put
    path: "/me/albums/{album_id}/videos/{video_id}"
    path_params: [{name: album_id, var: album_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    album_id: $album_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set a video as the album thumbnail
#
# POST /me/albums/{album_id}/videos/{video_id}/set_album_thumbnail
# Returns: record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool>
# operationId: set_video_as_album_thumbnail_alt1
export def "set-video-as-album-thumbnail-alt1" [
  album_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --time-code: float # The video frame time in seconds to use as the album thumbnail. (e.g. 300)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/me/albums/{album_id}/videos/{video_id}/set_album_thumbnail"
    path_params: [{name: album_id, var: album_id}, {name: video_id, var: video_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: time_code, var: time_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    album_id: $album_id, video_id: $video_id, time_code: $time_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos in which a user appears
#
# GET /me/appearances
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_appearances_alt1
export def "get-appearances-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/appearances"
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: filter_embeddable, var: filter_embeddable}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    direction: $direction, filter: $filter, filter_embeddable: $filter_embeddable, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the categories that a user follows
#
# GET /me/categories
# Returns: table<icon: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, last_video_featured_time: string, link: string, metadata: record<connections: record, interactions: record>, name: string, parent: record<link: string, name: string, uri: string>, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, resource_key: string, subcategories: list<record>, top_level: bool, uri: string>
# operationId: get_category_subscriptions_alt1
export def "get-category-subscriptions-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-11 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/categories"
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.category+json"]
    ok: [200]
    auth: bearer
  } {
    direction: $direction, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsubscribe a user from a category
#
# DELETE /me/categories/{category}
# operationId: unsubscribe_from_category_alt1
export def "unsubscribe-from-category-alt1" [
  category: string
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
    path: "/me/categories/{category}"
    path_params: [{name: category, var: category}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user follows a category
#
# GET /me/categories/{category}
# operationId: check_if_user_subscribed_to_category_alt1
export def "check-if-user-subscribed-to-category-alt1" [
  category: string
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
    path: "/me/categories/{category}"
    path_params: [{name: category, var: category}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe a user to a single category
#
# PUT /me/categories/{category}
# operationId: subscribe_to_category_alt1
export def "subscribe-to-category-alt1" [
  category: float
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
    method: put
    path: "/me/categories/{category}"
    path_params: [{name: category, var: category}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the channels to which a user subscribes
#
# GET /me/channels
# Returns: table<categories: list<record>, created_time: string, description: string, header: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<view: string>, resource_key: string, tags: list<record>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_channel_subscriptions_alt1
export def "get-channel-subscriptions-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-5 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-1 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/channels"
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.channel+json"]
    ok: [200, 304]
    auth: bearer
  } {
    direction: $direction, filter: $filter, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsubscribe a user from a specific channel
#
# DELETE /me/channels/{channel_id}
# operationId: unsubscribe_from_channel_alt1
export def "unsubscribe-from-channel-alt1" [
  channel_id: float
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
    path: "/me/channels/{channel_id}"
    path_params: [{name: channel_id, var: channel_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user follows a channel
#
# GET /me/channels/{channel_id}
# operationId: check_if_user_subscribed_to_channel_alt1
export def "check-if-user-subscribed-to-channel-alt1" [
  channel_id: float
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
    path: "/me/channels/{channel_id}"
    path_params: [{name: channel_id, var: channel_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe a user to a specific channel
#
# PUT /me/channels/{channel_id}
# operationId: subscribe_to_channel_alt1
export def "subscribe-to-channel-alt1" [
  channel_id: float
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
    method: put
    path: "/me/channels/{channel_id}"
    path_params: [{name: channel_id, var: channel_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the custom logos that belong to a user
#
# GET /me/customlogos
# Returns: table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>
# operationId: get_custom_logos_alt1
export def "get-custom-logos-alt1" [
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
    path: "/me/customlogos"
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a custom logo
#
# POST /me/customlogos
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: create_custom_logo_alt1
export def "create-custom-logo-alt1" [
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
    path: "/me/customlogos"
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [201]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific custom logo
#
# GET /me/customlogos/{logo_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: get_custom_logo_alt1
export def "get-custom-logo-alt1" [
  logo_id: float
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
    path: "/me/customlogos/{logo_id}"
    path_params: [{name: logo_id, var: logo_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    logo_id: $logo_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all videos in a user's feed
#
# GET /me/feed
# Returns: table<category: record<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, channel: record<categories: list, created_time: string, description: string, header: record, link: string, metadata: record, modified_time: string, name: string, pictures: record, privacy: record, resource_key: string, tags: list, uri: string, user: record>, clip: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, group: record<created_time: string, description: string, link: string, metadata: record, modified_time: string, name: string, pictures: record, privacy: record, resource_key: string, uri: string, user: record>, metadata: record<connections: record>, tag: record<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, time: string, type: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_feed_alt1
export def "get-feed-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Necessary for proper pagination. You shouldn't provide this value yourself, and instead use the pagination links in the feed response. Please see our [pagination documentation](https://developer.vimeo.com/api/common-formats#using-the-pagination-parameter) for more information. (e.g. 280)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --type: string@type-completer-1 # The feed type.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/feed"
    query: [{name: offset, var: offset}, {name: page, var: page}, {name: per_page, var: per_page}, {name: type, var: type}]
    accept: ["application/vnd.vimeo.activity+json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, page: $page, per_page: $per_page, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the followers of a user
#
# GET /me/followers
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: get_followers_alt1
export def "get-followers-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/followers"
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    direction: $direction, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the users that a user is following
#
# GET /me/following
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: get_user_following_alt1
export def "get-user-following-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-6 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/following"
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    direction: $direction, filter: $filter, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow a list of users
#
# POST /me/following
# operationId: follow_users_alt1
export def "follow-users-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  users: list<string> # An array of user URIs for the list of users to follow.
]: any -> any {
  $in | http-request {
    method: post
    path: "/me/following"
    body: {content_type: "application/json", kind: json, fields: [{name: users, var: users}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfollow a user
#
# DELETE /me/following/{follow_user_id}
# operationId: unfollow_user_alt1
export def "unfollow-user-alt1" [
  follow_user_id: float
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
    path: "/me/following/{follow_user_id}"
    path_params: [{name: follow_user_id, var: follow_user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    follow_user_id: $follow_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user is following another user
#
# GET /me/following/{follow_user_id}
# operationId: check_if_user_is_following_alt1
export def "check-if-user-is-following-alt1" [
  follow_user_id: float
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
    path: "/me/following/{follow_user_id}"
    path_params: [{name: follow_user_id, var: follow_user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    follow_user_id: $follow_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow a specific user
#
# PUT /me/following/{follow_user_id}
# operationId: follow_user_alt1
export def "follow-user-alt1" [
  follow_user_id: float
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
    method: put
    path: "/me/following/{follow_user_id}"
    path_params: [{name: follow_user_id, var: follow_user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    follow_user_id: $follow_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the groups that a user has joined
#
# GET /me/groups
# Returns: table<created_time: string, description: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<comment: string, invite: string, join: string, videos: string, view: string>, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_user_groups_alt1
export def "get-user-groups-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-5 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-2 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/groups"
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.group+json"]
    ok: [200]
    auth: bearer
  } {
    direction: $direction, filter: $filter, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a user from a group
#
# DELETE /me/groups/{group_id}
# operationId: leave_group_alt1
export def "leave-group-alt1" [
  group_id: float
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
    path: "/me/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user has joined a group
#
# GET /me/groups/{group_id}
# operationId: check_if_user_joined_group_alt1
export def "check-if-user-joined-group-alt1" [
  group_id: float
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
    path: "/me/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a user to a group
#
# PUT /me/groups/{group_id}
# operationId: join_group_alt1
export def "join-group-alt1" [
  group_id: float
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
    method: put
    path: "/me/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos that a user has liked
#
# GET /me/likes
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_likes_alt1
export def "get-likes-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/likes"
    query: [{name: filter, var: filter}, {name: filter_embeddable, var: filter_embeddable}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, filter_embeddable: $filter_embeddable, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cause a user to unlike a video
#
# DELETE /me/likes/{video_id}
# operationId: unlike_video_alt1
export def "unlike-video-alt1" [
  video_id: float
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
    path: "/me/likes/{video_id}"
    path_params: [{name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user has liked a video
#
# GET /me/likes/{video_id}
# operationId: check_if_user_liked_video_alt1
export def "check-if-user-liked-video-alt1" [
  video_id: float
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
    path: "/me/likes/{video_id}"
    path_params: [{name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cause a user to like a video
#
# PUT /me/likes/{video_id}
# operationId: like_video_alt1
export def "like-video-alt1" [
  video_id: float
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
    method: put
    path: "/me/likes/{video_id}"
    path_params: [{name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the On Demand pages of a user
#
# GET /me/ondemand/pages
# Returns: table<background: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record, rent: record>, film: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, genres: list<record>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, trailer: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_user_vods_alt1
export def "get-user-vods-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-7 # The type of On Demand pages to return.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-12 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/ondemand/pages"
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.ondemand.page+json"]
    ok: [200]
    auth: bearer
  } {
    direction: $direction, filter: $filter, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an On Demand page
#
# POST /me/ondemand/pages
# Returns: record<background: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record<active: bool, price: float>, rent: record<active: bool, period: string, price: float>>, film: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, genres: table<canonical: string, interactions: record, link: string, metadata: record, name: string, uri: string>, link: string, metadata: record<connections: record<metadata: record>, interactions: record<buy: record, rent: record, subscribe: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, trailer: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: create_vod_alt1
export def "create-vod-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accepted-currencies: string@accepted-currencies-completer # An array of accepted currencies. Option descriptions: * `AUD` - Australian Dollar * `CAD` - Canadian Dollar * `CHF` - Swiss Franc * `DKK` - Danish Krone * `EUR` - Euro * `GBP` - British Pound * `JPY` - Japanese Yen * `KRW` - South Korean Won * `NOK` - Norwegian Krone * `PLN` - Polish Zloty * `SEK` - Swedish Krona * `USD` - US Dollar
  --buy: record # shape: {active?: bool, download?: bool, price?: record}
  content_rating: string@content-rating-completer # One or more ratings, either as a comma-separated list or as a JSON array depending on the request format.
  description: string # The description of the On Demand page. (e.g. DARBY FOREVER follows the fantasies of Darby, a shopgirl at "Bobbins & Notions".)
  --domain-link: string # The custom domain of the On Demand page. (e.g. https://example.com)
  --episodes: record # shape: {buy?: record, rent?: record}
  --link: string # The custom string to use in this On Demand page's Vimeo URL. (e.g. darbyforever)
  name: string # The name of the On Demand page. (e.g. Darby Forever)
  --rent: record # shape: {active?: bool, period?: "1 week"|"1 year"|"24 hour"|"3 month"|"30 day"|"48 hour"|"6 month"|"72 hour", price?: record}
  --subscription: record # shape: {monthly?: record}
  type: string@type-completer-2 # The type of On Demand page.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/me/ondemand/pages"
    body: {content_type: "application/json", kind: json, fields: [{name: accepted_currencies, var: accepted_currencies}, {name: buy, var: buy}, {name: content_rating, var: content_rating}, {name: description, var: description}, {name: domain_link, var: domain_link}, {name: episodes, var: episodes}, {name: link, var: link}, {name: name, var: name}, {name: rent, var: rent}, {name: subscription, var: subscription}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    accepted_currencies: $accepted_currencies, buy: $buy, content_rating: $content_rating, description: $description, domain_link: $domain_link, episodes: $episodes, link: $link, name: $name, rent: $rent, subscription: $subscription, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the On Demand purchases and rentals that a user has made
#
# GET /me/ondemand/purchases
# Returns: table<background: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record, rent: record>, film: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, genres: list<record>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, trailer: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_vod_purchases
export def "get-vod-purchases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-8 # The type of On Demand videos to show. Option descriptions: * `important` - Will show all pages which are about to expire.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-13 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/ondemand/purchases"
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.ondemand.page+json"]
    ok: [200]
    auth: bearer
  } {
    direction: $direction, filter: $filter, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user has made a purchase or rental from an On Demand page
#
# GET /me/ondemand/purchases/{ondemand_id}
# Returns: record<background: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record<active: bool, price: float>, rent: record<active: bool, period: string, price: float>>, film: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, genres: table<canonical: string, interactions: record, link: string, metadata: record, name: string, uri: string>, link: string, metadata: record<connections: record<metadata: record>, interactions: record<buy: record, rent: record, subscribe: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, trailer: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: check_if_vod_was_purchased_alt1
export def "check-if-vod-was-purchased-alt1" [
  ondemand_id: float
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
    path: "/me/ondemand/purchases/{ondemand_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}]
    accept: ["application/vnd.vimeo.ondemand.page+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the pictures that belong to a user
#
# GET /me/pictures
# Returns: table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>
# operationId: get_pictures_alt1
export def "get-pictures-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/pictures"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a user picture
#
# POST /me/pictures
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: create_picture_alt1
export def "create-picture-alt1" [
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
    path: "/me/pictures"
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user picture
#
# DELETE /me/pictures/{portraitset_id}
# operationId: delete_picture_alt1
export def "delete-picture-alt1" [
  portraitset_id: float
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
    path: "/me/pictures/{portraitset_id}"
    path_params: [{name: portraitset_id, var: portraitset_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    portraitset_id: $portraitset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific user picture
#
# GET /me/pictures/{portraitset_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: get_picture_alt1
export def "get-picture-alt1" [
  portraitset_id: float
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
    path: "/me/pictures/{portraitset_id}"
    path_params: [{name: portraitset_id, var: portraitset_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    portraitset_id: $portraitset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a user picture
#
# PATCH /me/pictures/{portraitset_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: edit_picture_alt1
export def "edit-picture-alt1" [
  portraitset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Whether the picture is the user's active portrait. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/me/pictures/{portraitset_id}"
    path_params: [{name: portraitset_id, var: portraitset_id}]
    body: {content_type: "application/vnd.vimeo.picture+json", kind: json, fields: [{name: active, var: active}]}
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    portraitset_id: $portraitset_id, active: $active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the portfolios that belong to a user
#
# GET /me/portfolios
# Returns: table<created_time: string, description: string, link: string, metadata: record<connections: record>, modified_time: string, name: string, sort: string, uri: string>
# operationId: get_portfolios_alt1
export def "get-portfolios-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/portfolios"
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.portfolio+json"]
    ok: [200]
    auth: bearer
  } {
    direction: $direction, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific portfolio
#
# GET /me/portfolios/{portfolio_id}
# Returns: record<created_time: string, description: string, link: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, sort: string, uri: string>
# operationId: get_portfolio_alt1
export def "get-portfolio-alt1" [
  portfolio_id: float
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
    path: "/me/portfolios/{portfolio_id}"
    path_params: [{name: portfolio_id, var: portfolio_id}]
    accept: ["application/vnd.vimeo.portfolio+json"]
    ok: [200]
    auth: bearer
  } {
    portfolio_id: $portfolio_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos in a portfolio
#
# GET /me/portfolios/{portfolio_id}/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_portfolio_videos_alt1
export def "get-portfolio-videos-alt1" [
  portfolio_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page that contains the video URI. (e.g. /videos/258684937)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-14 # The way to sort the results. Option descriptions: * `default` - This will sort to the default sort set on the portfolio.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/portfolios/{portfolio_id}/videos"
    path_params: [{name: portfolio_id, var: portfolio_id}]
    query: [{name: containing_uri, var: containing_uri}, {name: filter, var: filter}, {name: filter_embeddable, var: filter_embeddable}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    portfolio_id: $portfolio_id, containing_uri: $containing_uri, filter: $filter, filter_embeddable: $filter_embeddable, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a video from a portfolio
#
# DELETE /me/portfolios/{portfolio_id}/videos/{video_id}
# operationId: delete_video_from_portfolio_alt1
export def "delete-video-from-portfolio-alt1" [
  portfolio_id: float
  video_id: float
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
    path: "/me/portfolios/{portfolio_id}/videos/{video_id}"
    path_params: [{name: portfolio_id, var: portfolio_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    portfolio_id: $portfolio_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific video in a portfolio
#
# GET /me/portfolios/{portfolio_id}/videos/{video_id}
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: get_portfolio_video_alt1
export def "get-portfolio-video-alt1" [
  portfolio_id: float
  video_id: float
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
    path: "/me/portfolios/{portfolio_id}/videos/{video_id}"
    path_params: [{name: portfolio_id, var: portfolio_id}, {name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    portfolio_id: $portfolio_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a video to a portfolio
#
# PUT /me/portfolios/{portfolio_id}/videos/{video_id}
# operationId: add_video_to_portfolio_alt1
export def "add-video-to-portfolio-alt1" [
  portfolio_id: float
  video_id: float
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
    method: put
    path: "/me/portfolios/{portfolio_id}/videos/{video_id}"
    path_params: [{name: portfolio_id, var: portfolio_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    portfolio_id: $portfolio_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the embed presets that a user has created
#
# GET /me/presets
# Returns: table<metadata: record<connections: record>, name: string, settings: record<buttons: record, logos: record, outro: record>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_embed_presets_alt1
export def "get-embed-presets-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/presets"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.preset+json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific embed preset
#
# GET /me/presets/{preset_id}
# Returns: record<metadata: record<connections: record<videos: record>>, name: string, settings: record<buttons: record<embed: bool, hd: bool, like: bool, share: bool, vote: bool, watchlater: bool>, logos: record<custom: bool, sticky_custom: bool, vimeo: bool>, outro: record<clips: string, link: record, text: string, type: string, videos: string>>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: get_embed_preset_alt1
export def "get-embed-preset-alt1" [
  preset_id: float
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
    path: "/me/presets/{preset_id}"
    path_params: [{name: preset_id, var: preset_id}]
    accept: ["application/vnd.vimeo.preset+json"]
    ok: [200]
    auth: bearer
  } {
    preset_id: $preset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit an embed preset
#
# PATCH /me/presets/{preset_id}
# Returns: record<metadata: record<connections: record<videos: record>>, name: string, settings: record<buttons: record<embed: bool, hd: bool, like: bool, share: bool, vote: bool, watchlater: bool>, logos: record<custom: bool, sticky_custom: bool, vimeo: bool>, outro: record<clips: string, link: record, text: string, type: string, videos: string>>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: edit_embed_preset_alt1
export def "edit-embed-preset-alt1" [
  preset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --outro: string@outro-completer # Disable the outro.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/me/presets/{preset_id}"
    path_params: [{name: preset_id, var: preset_id}]
    body: {content_type: "application/vnd.vimeo.preset+json", kind: json, fields: [{name: outro, var: outro}]}
    accept: ["application/vnd.vimeo.preset+json"]
    ok: [200]
    auth: bearer
  } {
    preset_id: $preset_id, outro: $outro
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos that have been added to an embed preset
#
# GET /me/presets/{preset_id}/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_embed_preset_videos_alt1
export def "get-embed-preset-videos-alt1" [
  preset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/presets/{preset_id}/videos"
    path_params: [{name: preset_id, var: preset_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    preset_id: $preset_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the projects that belong to a user
#
# GET /me/projects
# Returns: table<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_projects_alt1
export def "get-projects-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-15 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/projects"
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    direction: $direction, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a project
#
# POST /me/projects
# Returns: record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: create_project_alt1
export def "create-project-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the project. (e.g. Rough cuts)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/me/projects"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a project
#
# DELETE /me/projects/{project_id}
# operationId: delete_project_alt1
export def "delete-project-alt1" [
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --should-delete-clips: oneof<nothing, bool> # Whether to delete all the videos in the project along with the project itself. (e.g. true)
]: nothing -> any {
  http-request {
    method: delete
    path: "/me/projects/{project_id}"
    path_params: [{name: project_id, var: project_id}]
    query: [{name: should_delete_clips, var: should_delete_clips}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id, should_delete_clips: $should_delete_clips
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific project
#
# GET /me/projects/{project_id}
# Returns: record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: get_project_alt1
export def "get-project-alt1" [
  project_id: float
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
    path: "/me/projects/{project_id}"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a project
#
# PATCH /me/projects/{project_id}
# Returns: record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: edit_project_alt1
export def "edit-project-alt1" [
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the project. (e.g. Rough cuts)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/me/projects/{project_id}"
    path_params: [{name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a list of videos from a project
#
# DELETE /me/projects/{project_id}/videos
# operationId: remove_videos_from_project_alt1
export def "remove-videos-from-project-alt1" [
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --should-delete-clips: oneof<nothing, bool> # Whether to delete the videos when removing them from the project. (e.g. false)
  --uris: string # A comma-separated list of the video URIs to remove. (required, e.g. /videos/258684937,/videos/273576296)
]: nothing -> any {
  http-request {
    method: delete
    path: "/me/projects/{project_id}/videos"
    path_params: [{name: project_id, var: project_id}]
    query: [{name: should_delete_clips, var: should_delete_clips}, {name: uris, var: uris, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id, should_delete_clips: $should_delete_clips, uris: $uris
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos in a project
#
# GET /me/projects/{project_id}/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_project_videos_alt1
export def "get-project-videos-alt1" [
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-16 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/projects/{project_id}/videos"
    path_params: [{name: project_id, var: project_id}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, direction: $direction, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a list of videos to a project
#
# PUT /me/projects/{project_id}/videos
# operationId: add_videos_to_project_alt1
export def "add-videos-to-project-alt1" [
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uris: string # A comma-separated list of video URIs to add. (required, e.g. /videos/258684937,/videos/273576296)
]: nothing -> any {
  http-request {
    method: put
    path: "/me/projects/{project_id}/videos"
    path_params: [{name: project_id, var: project_id}]
    query: [{name: uris, var: uris, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id, uris: $uris
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a specific video from a project
#
# DELETE /me/projects/{project_id}/videos/{video_id}
# operationId: remove_video_from_project_alt1
export def "remove-video-from-project-alt1" [
  project_id: float
  video_id: float
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
    path: "/me/projects/{project_id}/videos/{video_id}"
    path_params: [{name: project_id, var: project_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a specific video to a project
#
# PUT /me/projects/{project_id}/videos/{video_id}
# operationId: add_video_to_project_alt1
export def "add-video-to-project-alt1" [
  project_id: float
  video_id: float
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
    method: put
    path: "/me/projects/{project_id}/videos/{video_id}"
    path_params: [{name: project_id, var: project_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos that a user has uploaded
#
# GET /me/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_videos_alt1
export def "get-videos-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page that contains the video URI. Only available when not paired with `query`. (e.g. /videos/258684937)
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-9 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --filter-playable: oneof<nothing, bool> # Whether to filter by all playable videos or by all videos that are not playable. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-17 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/videos"
    query: [{name: containing_uri, var: containing_uri}, {name: direction, var: direction}, {name: filter, var: filter}, {name: filter_embeddable, var: filter_embeddable}, {name: filter_playable, var: filter_playable}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200, 304]
    auth: bearer
  } {
    containing_uri: $containing_uri, direction: $direction, filter: $filter, filter_embeddable: $filter_embeddable, filter_playable: $filter_playable, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a video
#
# POST /me/videos
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: upload_video_alt1
export def "upload-video-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-rating: list<string> # A list of values describing the content in this video. Find the full list in the [/contentratings](https://developer.vimeo.com/api/endpoints/videos#GET/contentratings) endpoint.
  --description: string # The description of the video. (e.g. A celebration of 10 years of Staff Picks.)
  --embed: record # shape: {buttons?: record, color?: string, logos?: record, playbar?: bool, title?: record, volume?: bool}
  --license: string@license-completer # The Creative Commons license.
  --locale: string # The video's default language. For a full list of valid languages, use the [/languages?filter=texttracks](https://developer.vimeo.com/api/endpoints/videos#GET/languages) endpoint. (e.g. en_US)
  --name: string # The title of the video. (e.g. Celebrating 10 Years of Staff Picks)
  --password: string # The password. When you set `privacy.view` to `password`, you must provide the password as an additional parameter. (e.g. hunter1)
  --privacy: record # shape: {add?: bool, comments?: "anybody"|"contacts"|"nobody", download?: bool, embed?: "private"|"public"|"whitelist", view?: "anybody"|"contacts"|"disable"|"nobody"|"password"|"unlisted"|"users"}
  --ratings: record # shape: {mpaa?: record, tv?: record}
  --review-page: record # shape: {active?: bool}
  --spatial: record # shape: {director_timeline?: list, field_of_view?: float, projection?: "cubical"|"cylindrical"|"dome"|"equirectangular"|"pyramid", stereo_format?: "left-right"|"mono"|"top-bottom"}
  upload: record # shape: {approach: "post"|"pull"|"streaming"|"tus", link?: string, redirect_url?: string, size?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/me/videos"
    body: {content_type: "application/vnd.vimeo.video+json", kind: json, fields: [{name: content_rating, var: content_rating}, {name: description, var: description}, {name: embed, var: embed}, {name: license, var: license}, {name: locale, var: locale}, {name: name, var: name}, {name: password, var: password}, {name: privacy, var: privacy}, {name: ratings, var: ratings}, {name: review_page, var: review_page}, {name: spatial, var: spatial}, {name: upload, var: upload}]}
    accept: ["application/vnd.vimeo.video+json"]
    ok: [201]
    auth: bearer
  } {
    content_rating: $content_rating, description: $description, embed: $embed, license: $license, locale: $locale, name: $name, password: $password, privacy: $privacy, ratings: $ratings, review_page: $review_page, spatial: $spatial, upload: $upload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user owns a video
#
# GET /me/videos/{video_id}
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: check_if_user_owns_video_alt1
export def "check-if-user-owns-video-alt1" [
  video_id: float
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
    path: "/me/videos/{video_id}"
    path_params: [{name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user's watch history
#
# DELETE /me/watched/videos
# operationId: delete_watch_history
export def "delete-watch-history" [
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
    path: "/me/watched/videos"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos that a user has watched
#
# GET /me/watched/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_watch_history
export def "get-watch-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/watched/videos"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific video from a user's watch history
#
# DELETE /me/watched/videos/{video_id}
# operationId: delete_from_watch_history
export def "delete-from-watch-history" [
  video_id: float
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
    path: "/me/watched/videos/{video_id}"
    path_params: [{name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos in a user's Watch Later queue
#
# GET /me/watchlater
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_watch_later_queue_alt1
export def "get-watch-later-queue-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/watchlater"
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: filter_embeddable, var: filter_embeddable}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200, 304]
    auth: bearer
  } {
    direction: $direction, filter: $filter, filter_embeddable: $filter_embeddable, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a video from a user's Watch Later queue
#
# DELETE /me/watchlater/{video_id}
# operationId: delete_video_from_watch_later_alt1
export def "delete-video-from-watch-later-alt1" [
  video_id: float
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
    path: "/me/watchlater/{video_id}"
    path_params: [{name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user has added a specific video to their Watch Later queue
#
# GET /me/watchlater/{video_id}
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: check_watch_later_queue_alt1
export def "check-watch-later-queue-alt1" [
  video_id: float
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
    path: "/me/watchlater/{video_id}"
    path_params: [{name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a video to a user's Watch Later queue
#
# PUT /me/watchlater/{video_id}
# operationId: add_video_to_watch_later_alt1
export def "add-video-to-watch-later-alt1" [
  video_id: float
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
    method: put
    path: "/me/watchlater/{video_id}"
    path_params: [{name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exchange an authorization code for an access token
#
# POST /oauth/access_token
# Returns: record<access_token: string, app: record<name: string, uri: string>, expires_on: string, refresh_token: string, scope: string, token_type: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: exchange_auth_code
export def "exchange-auth-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # The authorization code received from the authorization server. (e.g. 1234abcd)
  grant_type: string@grant-type-completer # The grant type. Must be set to `authorization_code`.
  redirect_uri: string # The redirect URI. Must match the URI from `/oauth/authorize`. (e.g. https://example.com)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth/access_token"
    body: {content_type: "application/vnd.vimeo.auth+json", kind: json, fields: [{name: code, var: code}, {name: grant_type, var: grant_type}, {name: redirect_uri, var: redirect_uri}]}
    accept: ["application/vnd.vimeo.auth+json"]
    ok: [200]
    auth: bearer
  } {
    code: $code, grant_type: $grant_type, redirect_uri: $redirect_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authorize a client with OAuth
#
# POST /oauth/authorize/client
# Returns: record<access_token: string, app: record<name: string, uri: string>, expires_on: string, refresh_token: string, scope: string, token_type: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: client_auth
export def "client-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  grant_type: string@grant-type-completer-1 # The grant type. Must be set to `client_credentials`.
  scope: string # A space-separated list of the authentication [scopes](https://developer.vimeo.com/api/authentication#supported-scopes) that you want to access. The default is `public`. (e.g. public)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth/authorize/client"
    body: {content_type: "application/vnd.vimeo.auth+json", kind: json, fields: [{name: grant_type, var: grant_type}, {name: scope, var: scope}]}
    accept: ["application/vnd.vimeo.auth+json"]
    ok: [200]
    auth: bearer
  } {
    grant_type: $grant_type, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Convert OAuth 1 access tokens to OAuth 2 access tokens
#
# POST /oauth/authorize/vimeo_oauth1
# Returns: record<access_token: string, app: record<name: string, uri: string>, expires_on: string, refresh_token: string, scope: string, token_type: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: convert_access_token
export def "convert-access-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  grant_type: string@grant-type-completer-2 # The grant type. Must be set to `vimeo_oauth1`.
  --body-token: string # The OAuth 1 token. (e.g. 58037c0078d5f54e15e638cc0dd882a570b13c50) (spec name: token)
  token_secret: string # The OAuth 1 token secret. (e.g. NTgwMzdjMDA3OGQ1ZjU0ZTE1ZTYzOGNjMGRkODgyYTU3MGIxM2M1MA==)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth/authorize/vimeo_oauth1"
    body: {content_type: "application/vnd.vimeo.auth+json", kind: json, fields: [{name: grant_type, var: grant_type}, {name: token, var: body_token, required: true}, {name: token_secret, var: token_secret}]}
    accept: ["application/vnd.vimeo.auth+json"]
    ok: [200]
    auth: bearer
  } {
    grant_type: $grant_type, body_token: $body_token, token_secret: $token_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify an OAuth 2 token
#
# GET /oauth/verify
# Returns: record<access_token: string, app: record<name: string, uri: string>, expires_on: string, refresh_token: string, scope: string, token_type: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: verify_token
export def "verify-token" [
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
    path: "/oauth/verify"
    accept: ["application/vnd.vimeo.auth+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all On Demand genres
#
# GET /ondemand/genres
# Returns: table<canonical: string, interactions: record<page: record>, link: string, metadata: record<connections: record>, name: string, uri: string>
# operationId: get_vod_genres
export def "get-vod-genres" [
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
    path: "/ondemand/genres"
    accept: ["application/vnd.vimeo.ondemand.genre+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific On Demand genre
#
# GET /ondemand/genres/{genre_id}
# Returns: record<canonical: string, interactions: record<page: record<added: bool, options: list, uri: string>>, link: string, metadata: record<connections: record<pages: record>>, name: string, uri: string>
# operationId: get_vod_genre
export def "get-vod-genre" [
  genre_id: string
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
    path: "/ondemand/genres/{genre_id}"
    path_params: [{name: genre_id, var: genre_id}]
    accept: ["application/vnd.vimeo.ondemand.genre+json"]
    ok: [200]
    auth: bearer
  } {
    genre_id: $genre_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the On Demand pages in a genre
#
# GET /ondemand/genres/{genre_id}/pages
# Returns: table<background: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record, rent: record>, film: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, genres: list<record>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, trailer: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_genre_vods
export def "get-genre-vods" [
  genre_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-10 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-18 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ondemand/genres/{genre_id}/pages"
    path_params: [{name: genre_id, var: genre_id}]
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.ondemand.page+json"]
    ok: [200]
    auth: bearer
  } {
    genre_id: $genre_id, direction: $direction, filter: $filter, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific On Demand page in a genre
#
# GET /ondemand/genres/{genre_id}/pages/{ondemand_id}
# Returns: record<background: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record<active: bool, price: float>, rent: record<active: bool, period: string, price: float>>, film: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, genres: table<canonical: string, interactions: record, link: string, metadata: record, name: string, uri: string>, link: string, metadata: record<connections: record<metadata: record>, interactions: record<buy: record, rent: record, subscribe: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, trailer: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: get_genre_vod
export def "get-genre-vod" [
  genre_id: string
  ondemand_id: float
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
    path: "/ondemand/genres/{genre_id}/pages/{ondemand_id}"
    path_params: [{name: genre_id, var: genre_id}, {name: ondemand_id, var: ondemand_id}]
    accept: ["application/vnd.vimeo.ondemand.page+json"]
    ok: [200]
    auth: bearer
  } {
    genre_id: $genre_id, ondemand_id: $ondemand_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a draft of an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}
# operationId: delete_vod_draft
export def "delete-vod-draft" [
  ondemand_id: float
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
    path: "/ondemand/pages/{ondemand_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ondemand_id: $ondemand_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific On Demand page
#
# GET /ondemand/pages/{ondemand_id}
# Returns: record<background: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record<active: bool, price: float>, rent: record<active: bool, period: string, price: float>>, film: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, genres: table<canonical: string, interactions: record, link: string, metadata: record, name: string, uri: string>, link: string, metadata: record<connections: record<metadata: record>, interactions: record<buy: record, rent: record, subscribe: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, trailer: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: get_vod
export def "get-vod" [
  ondemand_id: float
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
    path: "/ondemand/pages/{ondemand_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}]
    accept: ["application/vnd.vimeo.ondemand.page+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit an On Demand page
#
# PATCH /ondemand/pages/{ondemand_id}
# Returns: record<background: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record<active: bool, price: float>, rent: record<active: bool, period: string, price: float>>, film: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, genres: table<canonical: string, interactions: record, link: string, metadata: record, name: string, uri: string>, link: string, metadata: record<connections: record<metadata: record>, interactions: record<buy: record, rent: record, subscribe: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, trailer: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: edit_vod
export def "edit-vod" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --link: string # The custom string to use in this On Demand page's Vimeo URL. (e.g. darbyforever)
  --preorder: record # shape: {active?: bool, publish_time?: string}
  --publish: record # shape: {active?: bool}
  --publish-when-ready: oneof<nothing, bool> # Whether to publish the On Demand page automatically after all videos are finished transcoding. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/ondemand/pages/{ondemand_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}]
    body: {content_type: "application/vnd.vimeo.ondemand.page+json", kind: json, fields: [{name: link, var: link}, {name: preorder, var: preorder}, {name: publish, var: publish}, {name: publish_when_ready, var: publish_when_ready}]}
    accept: ["application/vnd.vimeo.ondemand.page+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, link: $link, preorder: $preorder, publish: $publish, publish_when_ready: $publish_when_ready
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the backgrounds of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/backgrounds
# Returns: table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>
# operationId: get_vod_backgrounds
export def "get-vod-backgrounds" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ondemand/pages/{ondemand_id}/backgrounds"
    path_params: [{name: ondemand_id, var: ondemand_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a background to an On Demand page
#
# POST /ondemand/pages/{ondemand_id}/backgrounds
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: create_vod_background
export def "create-vod-background" [
  ondemand_id: float
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
    path: "/ondemand/pages/{ondemand_id}/backgrounds"
    path_params: [{name: ondemand_id, var: ondemand_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a background from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/backgrounds/{background_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: delete_vod_background
export def "delete-vod-background" [
  ondemand_id: float
  background_id: float
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
    path: "/ondemand/pages/{ondemand_id}/backgrounds/{background_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: background_id, var: background_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [204]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, background_id: $background_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific background of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/backgrounds/{background_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: get_vod_background
export def "get-vod-background" [
  ondemand_id: float
  background_id: float
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
    path: "/ondemand/pages/{ondemand_id}/backgrounds/{background_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: background_id, var: background_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, background_id: $background_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a background of an On Demand page
#
# PATCH /ondemand/pages/{ondemand_id}/backgrounds/{background_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: edit_vod_background
export def "edit-vod-background" [
  ondemand_id: float
  background_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Whether to make this background the active background. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/ondemand/pages/{ondemand_id}/backgrounds/{background_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: background_id, var: background_id}]
    body: {content_type: "application/vnd.vimeo.picture+json", kind: json, fields: [{name: active, var: active}]}
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, background_id: $background_id, active: $active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the genres of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/genres
# Returns: table<canonical: string, interactions: record<page: record>, link: string, metadata: record<connections: record>, name: string, uri: string>
# operationId: get_vod_genres_by_ondemand_id
export def "get-vod-genres-by-ondemand-id" [
  ondemand_id: float
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
    path: "/ondemand/pages/{ondemand_id}/genres"
    path_params: [{name: ondemand_id, var: ondemand_id}]
    accept: ["application/vnd.vimeo.ondemand.genre+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a genre from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/genres/{genre_id}
# operationId: delete_vod_genre
export def "delete-vod-genre" [
  ondemand_id: float
  genre_id: string
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
    path: "/ondemand/pages/{ondemand_id}/genres/{genre_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: genre_id, var: genre_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, genre_id: $genre_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check whether an On Demand page belongs to a genre
#
# GET /ondemand/pages/{ondemand_id}/genres/{genre_id}
# Returns: record<canonical: string, interactions: record<page: record<added: bool, options: list, uri: string>>, link: string, metadata: record<connections: record<pages: record>>, name: string, uri: string>
# operationId: get_vod_genre_by_ondemand_id
export def "get-vod-genre-by-ondemand-id" [
  ondemand_id: float
  genre_id: string
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
    path: "/ondemand/pages/{ondemand_id}/genres/{genre_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: genre_id, var: genre_id}]
    accept: ["application/vnd.vimeo.ondemand.genre+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, genre_id: $genre_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a genre to an On Demand page
#
# PUT /ondemand/pages/{ondemand_id}/genres/{genre_id}
# Returns: record<canonical: string, interactions: record<page: record<added: bool, options: list, uri: string>>, link: string, metadata: record<connections: record<pages: record>>, name: string, uri: string>
# operationId: add_vod_genre
export def "add-vod-genre" [
  ondemand_id: float
  genre_id: string
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
    method: put
    path: "/ondemand/pages/{ondemand_id}/genres/{genre_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: genre_id, var: genre_id}]
    accept: ["application/vnd.vimeo.ondemand.genre+json"]
    ok: [201]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, genre_id: $genre_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the users who have liked a video on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/likes
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: get_vod_likes
export def "get-vod-likes" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-11 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ondemand/pages/{ondemand_id}/likes"
    path_params: [{name: ondemand_id, var: ondemand_id}]
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, direction: $direction, filter: $filter, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the posters of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/pictures
# Returns: table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>
# operationId: get_vod_posters
export def "get-vod-posters" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ondemand/pages/{ondemand_id}/pictures"
    path_params: [{name: ondemand_id, var: ondemand_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a poster to an On Demand page
#
# POST /ondemand/pages/{ondemand_id}/pictures
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: add_vod_poster
export def "add-vod-poster" [
  ondemand_id: float
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
    path: "/ondemand/pages/{ondemand_id}/pictures"
    path_params: [{name: ondemand_id, var: ondemand_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [201]
    auth: bearer
  } {
    ondemand_id: $ondemand_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific poster of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/pictures/{poster_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: get_vod_poster
export def "get-vod-poster" [
  ondemand_id: float
  poster_id: float
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
    path: "/ondemand/pages/{ondemand_id}/pictures/{poster_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: poster_id, var: poster_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, poster_id: $poster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a poster of an On Demand page
#
# PATCH /ondemand/pages/{ondemand_id}/pictures/{poster_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: edit_vod_poster
export def "edit-vod-poster" [
  ondemand_id: float
  poster_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Whether to make this picture the active picture. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/ondemand/pages/{ondemand_id}/pictures/{poster_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: poster_id, var: poster_id}]
    body: {content_type: "application/vnd.vimeo.picture+json", kind: json, fields: [{name: active, var: active}]}
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, poster_id: $poster_id, active: $active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the promotions on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/promotions
# Returns: record<access_type: string, discount_type: string, download: bool, label: string, metadata: record<connections: record<codes: record>>, percent_off: float, product_type: string, stream_period: string, total: float, type: string, uri: string>
# operationId: get_vod_promotions
export def "get-vod-promotions" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-12 # The filter to apply to the results. (required)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ondemand/pages/{ondemand_id}/promotions"
    path_params: [{name: ondemand_id, var: ondemand_id}]
    query: [{name: filter, var: filter, required: true}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.ondemand.promotion+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, filter: $filter, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a promotion to an On Demand page
#
# POST /ondemand/pages/{ondemand_id}/promotions
# Returns: record<access_type: string, discount_type: string, download: bool, label: string, metadata: record<connections: record<codes: record>>, percent_off: float, product_type: string, stream_period: string, total: float, type: string, uri: string>
# operationId: create_vod_promotion
export def "create-vod-promotion" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-type: string@access-type-completer # The promotion access type, which is a purchase option that isn't available on the container. VIP promotions always make the content free of charge. If you use this type, you must further define the promotion with the `download` or `stream_period` fields. Option descriptions: * `default` - Promotions grant discount on the existing purchase options for an On Demand Container. * `vip` - Promotions can be used to grant free access to VOD content before it is released, or to offer a purchase option that isn't available on the container. "vip" promotions will always make the content free, and must be further defined with the `download` or `stream_period` fields.
  --code: string # The promotion code. This field is ignored for batch promotions. (e.g. sxsw2018)
  --discount-type: string@discount-type-completer # The type of discount offered by the promo code. When `access_type` is `vip`, the value of this field must be `free`. Option descriptions: * `free` - Reduces the price to zero. * `percent` - Reduces the price by an amount defined in the "percent_off" field.
  --download: oneof<nothing, bool> # Whether the promotion grants download access to VOD content. This is necessary only when not previously defined in the On Demand container or when `access_type` is `vip` or `product_type` is `buy`. (e.g. true)
  --end-time: string # The end of the promotion period. If you don't specify a value, the promotion will never expire. (e.g. 1526089920)
  --label: string # The description of a batch promotion. This field is ignored for single promotions. (e.g. sxsw)
  --percent-off: float # The percentage of the discount by using this promo code. This field is applicable only when `discount_type` is `percent`. (e.g. 50)
  --product-type: string@product-type-completer # The type of transaction to which the promotion applies. When `access_type` is `default`, the default value is `any`, but the default value is `rent` when `access_type` is `vip`. Also, when `access_type` is `vip`, the only valid product types are `buy` and `rent`.
  --start-time: string # The start of the promotion period. If you don't specify a value, the start time defaults to the time that the promotion was created. (e.g. 1526089920)
  stream_period: string@stream-period-completer # The amount of time that a user has access to the VOD content upon redeeming a promo code. This field is necessary only when not defined in the On Demand container or when creating promotions when `access_type` is `vip` or `product_type` is `rent`.
  total: float # The number of promotions to generate when `type` is `batch`, or the number of uses of the promotion when `type` is `single`. (e.g. 9)
  type: string@type-completer-3 # The type of promotion. When `access_type` is `vip`, the value for this field must be `batch`. Option descriptions: * `batch` - Generates many random promo codes with one use each. * `single` - Generates one promo code that can be used many times.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ondemand/pages/{ondemand_id}/promotions"
    path_params: [{name: ondemand_id, var: ondemand_id}]
    body: {content_type: "application/vnd.vimeo.ondemand.promotion+json", kind: json, fields: [{name: access_type, var: access_type}, {name: code, var: code}, {name: discount_type, var: discount_type}, {name: download, var: download, required: true}, {name: end_time, var: end_time}, {name: label, var: label}, {name: percent_off, var: percent_off}, {name: product_type, var: product_type}, {name: start_time, var: start_time}, {name: stream_period, var: stream_period}, {name: total, var: total}, {name: type, var: type}]}
    accept: ["application/vnd.vimeo.ondemand.promotion+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, access_type: $access_type, code: $code, discount_type: $discount_type, download: $download, end_time: $end_time, label: $label, percent_off: $percent_off, product_type: $product_type, start_time: $start_time, stream_period: $stream_period, total: $total, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a promotion from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/promotions/{promotion_id}
# operationId: delete_vod_promotion
export def "delete-vod-promotion" [
  ondemand_id: float
  promotion_id: float
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
    path: "/ondemand/pages/{ondemand_id}/promotions/{promotion_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: promotion_id, var: promotion_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, promotion_id: $promotion_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific promotion on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/promotions/{promotion_id}
# Returns: record<access_type: string, discount_type: string, download: bool, label: string, metadata: record<connections: record<codes: record>>, percent_off: float, product_type: string, stream_period: string, total: float, type: string, uri: string>
# operationId: get_vod_promotion
export def "get-vod-promotion" [
  ondemand_id: float
  promotion_id: float
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
    path: "/ondemand/pages/{ondemand_id}/promotions/{promotion_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: promotion_id, var: promotion_id}]
    accept: ["application/vnd.vimeo.ondemand.promotion+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, promotion_id: $promotion_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the codes of a promotion on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/promotions/{promotion_id}/codes
# Returns: record<code: string, link: string, max_uses: float, uses: float>
# operationId: get_vod_promotion_codes
export def "get-vod-promotion-codes" [
  ondemand_id: float
  promotion_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ondemand/pages/{ondemand_id}/promotions/{promotion_id}/codes"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: promotion_id, var: promotion_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.ondemand.promocode+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, promotion_id: $promotion_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a list of regions from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/regions
# Returns: table<country_code: string, country_name: string, uri: string>
# operationId: delete_vod_regions
export def "delete-vod-regions" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --countries: list<string> # An array of country codes.
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/ondemand/pages/{ondemand_id}/regions"
    path_params: [{name: ondemand_id, var: ondemand_id}]
    body: {content_type: "application/vnd.vimeo.ondemand.region+json", kind: json, fields: [{name: countries, var: countries}]}
    accept: ["application/vnd.vimeo.ondemand.region+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, countries: $countries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the regions of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/regions
# Returns: table<country_code: string, country_name: string, uri: string>
# operationId: get_vod_regions
export def "get-vod-regions" [
  ondemand_id: float
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
    path: "/ondemand/pages/{ondemand_id}/regions"
    path_params: [{name: ondemand_id, var: ondemand_id}]
    accept: ["application/vnd.vimeo.ondemand.region+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a list of regions to an On Demand page
#
# PUT /ondemand/pages/{ondemand_id}/regions
# Returns: record<country_code: string, country_name: string, uri: string>
# operationId: set_vod_regions
export def "set-vod-regions" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  countries: list<string> # An array of country codes.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/ondemand/pages/{ondemand_id}/regions"
    path_params: [{name: ondemand_id, var: ondemand_id}]
    body: {content_type: "application/vnd.vimeo.ondemand.region+json", kind: json, fields: [{name: countries, var: countries}]}
    accept: ["application/vnd.vimeo.ondemand.region+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, countries: $countries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a specific region from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/regions/{country}
# operationId: delete_vod_region
export def "delete-vod-region" [
  ondemand_id: float
  country: string
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
    path: "/ondemand/pages/{ondemand_id}/regions/{country}"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: country, var: country}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific region of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/regions/{country}
# Returns: record<country_code: string, country_name: string, uri: string>
# operationId: get_vod_region
export def "get-vod-region" [
  ondemand_id: float
  country: string
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
    path: "/ondemand/pages/{ondemand_id}/regions/{country}"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: country, var: country}]
    accept: ["application/vnd.vimeo.ondemand.region+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a specific region to an On Demand page
#
# PUT /ondemand/pages/{ondemand_id}/regions/{country}
# Returns: record<country_code: string, country_name: string, uri: string>
# operationId: add_vod_region
export def "add-vod-region" [
  ondemand_id: float
  country: string
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
    method: put
    path: "/ondemand/pages/{ondemand_id}/regions/{country}"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: country, var: country}]
    accept: ["application/vnd.vimeo.ondemand.region+json"]
    ok: [201]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the seasons on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/seasons
# Returns: table<description: string, metadata: record<connections: record>, name: string, position: float, resource_key: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_vod_seasons
export def "get-vod-seasons" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-13 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-19 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ondemand/pages/{ondemand_id}/seasons"
    path_params: [{name: ondemand_id, var: ondemand_id}]
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.ondemand.season+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, direction: $direction, filter: $filter, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific season on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/seasons/{season_id}
# Returns: record<description: string, metadata: record<connections: record<videos: record>>, name: string, position: float, resource_key: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: get_vod_season
export def "get-vod-season" [
  ondemand_id: float
  season_id: float
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
    path: "/ondemand/pages/{ondemand_id}/seasons/{season_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: season_id, var: season_id}]
    accept: ["application/vnd.vimeo.ondemand.season+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, season_id: $season_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos in a season on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/seasons/{season_id}/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_vod_season_videos
export def "get-vod-season-videos" [
  ondemand_id: float
  season_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-13 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-20 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ondemand/pages/{ondemand_id}/seasons/{season_id}/videos"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: season_id, var: season_id}]
    query: [{name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, season_id: $season_id, filter: $filter, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_vod_videos
export def "get-vod-videos" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-14 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-21 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ondemand/pages/{ondemand_id}/videos"
    path_params: [{name: ondemand_id, var: ondemand_id}]
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.ondemand.video+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, direction: $direction, filter: $filter, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a video from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/videos/{video_id}
# operationId: delete_video_from_vod
export def "delete-video-from-vod" [
  ondemand_id: float
  video_id: float
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
    path: "/ondemand/pages/{ondemand_id}/videos/{video_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific video on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/videos/{video_id}
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: get_vod_video
export def "get-vod-video" [
  ondemand_id: float
  video_id: float
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
    path: "/ondemand/pages/{ondemand_id}/videos/{video_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.ondemand.video+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a video to an On Demand page
#
# PUT /ondemand/pages/{ondemand_id}/videos/{video_id}
# Returns: record<buy: record<active: bool, price: record, purchased: bool>, description: string, duration: string, episode: float, interactions: record<page: record<added: bool, options: list, uri: string>>, link: string, metadata: record<connections: record<season: record>, interactions: record<likes: record, watchlater: record>>, name: string, options: list<string>, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, play_progress: float, position: float, release_date: string, release_year: float, rent: record<active: bool, price: record, purchased: bool>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: add_video_to_vod
export def "add-video-to-vod" [
  ondemand_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --buy: record # shape: {price?: record}
  --position: float # The position of this video in the On Demand collection. (e.g. 10)
  --release-year: float # The video release year. (e.g. 2018)
  --rent: record # shape: {price?: record}
  type: string@type-completer-4 # The type of video that you are adding to the On Demand page.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/ondemand/pages/{ondemand_id}/videos/{video_id}"
    path_params: [{name: ondemand_id, var: ondemand_id}, {name: video_id, var: video_id}]
    body: {content_type: "application/vnd.vimeo.ondemand.video+json", kind: json, fields: [{name: buy, var: buy}, {name: position, var: position}, {name: release_year, var: release_year}, {name: rent, var: rent}, {name: type, var: type}]}
    accept: ["application/vnd.vimeo.ondemand.video+json"]
    ok: [200]
    auth: bearer
  } {
    ondemand_id: $ondemand_id, video_id: $video_id, buy: $buy, position: $position, release_year: $release_year, rent: $rent, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the On Demand regions
#
# GET /ondemand/regions
# Returns: table<country_code: string, country_name: string, uri: string>
# operationId: get_regions
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ondemand/regions"
    accept: ["application/vnd.vimeo.ondemand.region+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific On Demand region
#
# GET /ondemand/regions/{country}
# Returns: record<country_code: string, country_name: string, uri: string>
# operationId: get_region
export def "get-region" [
  country: string
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
    path: "/ondemand/regions/{country}"
    path_params: [{name: country, var: country}]
    accept: ["application/vnd.vimeo.ondemand.region+json"]
    ok: [200]
    auth: bearer
  } {
    country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific tag
#
# GET /tags/{word}
# Returns: record<canonical: string, metadata: record<connections: record<videos: record>>, name: string, resource_key: string, uri: string>
# operationId: get_tag
export def "get-tag" [
  word: string
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
    path: "/tags/{word}"
    path_params: [{name: word, var: word}]
    accept: ["application/vnd.vimeo.tag+json"]
    ok: [200]
    auth: bearer
  } {
    word: $word
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos with a specific tag
#
# GET /tags/{word}/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_videos_with_tag
export def "get-videos-with-tag" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-22 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tags/{word}/videos"
    path_params: [{name: word, var: word}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    word: $word, direction: $direction, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke the current access token
#
# DELETE /tokens
# Returns: record<access_token: string, app: record<name: string, uri: string>, expires_on: string, refresh_token: string, scope: string, token_type: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: delete_token
export def "delete-token" [
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
    path: "/tokens"
    accept: ["application/vnd.vimeo.auth+json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for users
#
# GET /users
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: search_users
export def "search-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-4 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    direction: $direction, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user
#
# GET /users/{user_id}
# Returns: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record<albums: record, appearances: record, block: record, categories: record, channels: record, feed: record, folders: record, followers: record, following: record, groups: record, likes: record, moderated_channels: record, pictures: record, portfolios: record, recommended_channels: record, recommended_users: record, shared: record, videos: record, watched_videos: record, watchlater: record>, interactions: record<add_privacy_user: record, block: record, follow: record, report: record>>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preferences: record<videos: record<privacy: record>>, resource_key: string, upload_quota: record<lifetime: record<free: float, max: float, used: float>, periodic: record<free: float, max: float, reset_date: string, used: float>, space: record<free: float, max: float, showing: string, used: float>>, uri: string, websites: table<description: string, link: string, name: string>>
# operationId: get_user
export def "get-user" [
  user_id: float
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
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a user
#
# PATCH /users/{user_id}
# Returns: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record<albums: record, appearances: record, block: record, categories: record, channels: record, feed: record, folders: record, followers: record, following: record, groups: record, likes: record, moderated_channels: record, pictures: record, portfolios: record, recommended_channels: record, recommended_users: record, shared: record, videos: record, watched_videos: record, watchlater: record>, interactions: record<add_privacy_user: record, block: record, follow: record, report: record>>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preferences: record<videos: record<privacy: record>>, resource_key: string, upload_quota: record<lifetime: record<free: float, max: float, used: float>, periodic: record<free: float, max: float, reset_date: string, used: float>, space: record<free: float, max: float, showing: string, used: float>>, uri: string, websites: table<description: string, link: string, name: string>>
# operationId: edit_user
export def "edit-user" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bio: string # The user's bio. (e.g. This is where you will find videos and news updates from the staff)
  --content-filter: list<string> # A list of values describing the content in this video. Find the full list in the [/contentratings](https://developer.vimeo.com/api/endpoints/videos#GET/contentratings) endpoint. You must provide a comma-separated list if you are using a query string or an array if you are using JSON.
  --link: string # The user's custom Vimeo URL slug. (e.g. staff)
  --location: string # The user's location. (e.g. New York City)
  --name: string # The user's display name. (e.g. Vimeo Staff)
  --password: string # The default password for all future videos that this user uploads. To use this field, the `videos.privacy.view` field must be `password`. (e.g. hunter1)
  --videos: record # shape: {privacy?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/vnd.vimeo.user+json", kind: json, fields: [{name: bio, var: bio}, {name: content_filter, var: content_filter}, {name: link, var: link}, {name: location, var: location}, {name: name, var: name}, {name: password, var: password}, {name: videos, var: videos}]}
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, bio: $bio, content_filter: $content_filter, link: $link, location: $location, name: $name, password: $password, videos: $videos
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the albums that belong to a user
#
# GET /users/{user_id}/albums
# Returns: table<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, web_brand_color: bool, web_custom_logo: bool>
# operationId: get_albums
export def "get-albums" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-8 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/albums"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, direction: $direction, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an album
#
# POST /users/{user_id}/albums
# Returns: record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool>
# operationId: create_album
export def "create-album" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brand-color: string # The hexadecimal code for the color of the player buttons. (e.g. ff66ee)
  --description: string # The description of the album. (e.g. Vimeo holiday videos!)
  --hide-nav: oneof<nothing, bool> # Whether to hide Vimeo navigation when displaying the album. (e.g. true)
  --layout: string@layout-completer # The type of layout for presenting the album.
  name: string # The name of the album. (e.g. Vimeo Holiday Videos!)
  --password: string # The album's password. Required only if **privacy** is `password`. (e.g. hunter1)
  --privacy: string@privacy-completer-2 # The privacy level of the album.
  --review-mode: oneof<nothing, bool> # Whether album videos should use the review mode URL. (e.g. true)
  --sort: string@sort-completer-9 # The default sort order of the album's videos.
  --theme: string@theme-completer # The color theme of the album.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{user_id}/albums"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/vnd.vimeo.album+json", kind: json, fields: [{name: brand_color, var: brand_color}, {name: description, var: description}, {name: hide_nav, var: hide_nav}, {name: layout, var: layout}, {name: name, var: name}, {name: password, var: password}, {name: privacy, var: privacy}, {name: review_mode, var: review_mode}, {name: sort, var: sort}, {name: theme, var: theme}]}
    accept: ["application/vnd.vimeo.album+json"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, brand_color: $brand_color, description: $description, hide_nav: $hide_nav, layout: $layout, name: $name, password: $password, privacy: $privacy, review_mode: $review_mode, sort: $sort, theme: $theme
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an album
#
# DELETE /users/{user_id}/albums/{album_id}
# operationId: delete_album
export def "delete-album" [
  user_id: float
  album_id: float
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
    path: "/users/{user_id}/albums/{album_id}"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific album
#
# GET /users/{user_id}/albums/{album_id}
# Returns: record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool>
# operationId: get_album
export def "get-album" [
  user_id: float
  album_id: float
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
    path: "/users/{user_id}/albums/{album_id}"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}]
    accept: ["application/vnd.vimeo.album+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit an album
#
# PATCH /users/{user_id}/albums/{album_id}
# Returns: record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool>
# operationId: edit_album
export def "edit-album" [
  user_id: float
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brand-color: string # The hexadecimal code for the color of the player buttons. (e.g. ff66ee)
  --description: string # The description of the album. (e.g. Vimeo holiday videos!)
  --domain: string # The custom domain a user has selected for their album. (nullable, e.g. mycustomdomain.com)
  --hide-nav: oneof<nothing, bool> # Whether to hide Vimeo navigation when displaying the album. (e.g. true)
  --layout: string@layout-completer # The type of layout for presenting the album.
  --name: string # The name of the album. (e.g. Vimeo Holiday Videos!)
  --password: string # The album's password. Required only if **privacy** is `password`. (e.g. hunter1)
  --privacy: string@privacy-completer-2 # The privacy level of the album.
  --review-mode: oneof<nothing, bool> # Whether album videos should use the review mode URL. (e.g. true)
  --sort: string@sort-completer-9 # The default sort order of the album's videos.
  --theme: string@theme-completer # The color theme of the album.
  --url: string # The custom Vimeo URL a user has selected for their album. (nullable, e.g. my-custom-url)
  --use-custom-domain: oneof<nothing, bool> # Whether the user has opted in to use a custom domain for their album. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{user_id}/albums/{album_id}"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}]
    body: {content_type: "application/vnd.vimeo.album+json", kind: json, fields: [{name: brand_color, var: brand_color}, {name: description, var: description}, {name: domain, var: domain}, {name: hide_nav, var: hide_nav}, {name: layout, var: layout}, {name: name, var: name}, {name: password, var: password}, {name: privacy, var: privacy}, {name: review_mode, var: review_mode}, {name: sort, var: sort}, {name: theme, var: theme}, {name: url, var: url}, {name: use_custom_domain, var: use_custom_domain}]}
    accept: ["application/vnd.vimeo.album+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id, brand_color: $brand_color, description: $description, domain: $domain, hide_nav: $hide_nav, layout: $layout, name: $name, password: $password, privacy: $privacy, review_mode: $review_mode, sort: $sort, theme: $theme, url: $url, use_custom_domain: $use_custom_domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the custom upload thumbnails of an album
#
# GET /users/{user_id}/albums/{album_id}/custom_thumbnails
# Returns: table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>
# operationId: get_album_custom_thumbs
export def "get-album-custom-thumbs" [
  user_id: float
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/albums/{album_id}/custom_thumbnails"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a custom uploaded thumbnail
#
# POST /users/{user_id}/albums/{album_id}/custom_thumbnails
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: create_album_custom_thumb
export def "create-album-custom-thumb" [
  user_id: float
  album_id: float
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
    path: "/users/{user_id}/albums/{album_id}/custom_thumbnails"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a custom uploaded album thumbnail
#
# DELETE /users/{user_id}/albums/{album_id}/custom_thumbnails/{thumbnail_id}
# operationId: delete_album_custom_thumbnail
export def "delete-album-custom-thumbnail" [
  user_id: float
  album_id: float
  thumbnail_id: float
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
    path: "/users/{user_id}/albums/{album_id}/custom_thumbnails/{thumbnail_id}"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}, {name: thumbnail_id, var: thumbnail_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id, thumbnail_id: $thumbnail_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific custom uploaded album thumbnail
#
# GET /users/{user_id}/albums/{album_id}/custom_thumbnails/{thumbnail_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: get_album_custom_thumbnail
export def "get-album-custom-thumbnail" [
  user_id: float
  album_id: float
  thumbnail_id: float
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
    path: "/users/{user_id}/albums/{album_id}/custom_thumbnails/{thumbnail_id}"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}, {name: thumbnail_id, var: thumbnail_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id, thumbnail_id: $thumbnail_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace a custom uploaded album thumbnail
#
# PATCH /users/{user_id}/albums/{album_id}/custom_thumbnails/{thumbnail_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: replace_album_custom_thumb
export def "replace-album-custom-thumb" [
  user_id: float
  album_id: float
  thumbnail_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Whether to make this the active album thumbnail. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{user_id}/albums/{album_id}/custom_thumbnails/{thumbnail_id}"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}, {name: thumbnail_id, var: thumbnail_id}]
    body: {content_type: "application/vnd.vimeo.picture+json", kind: json, fields: [{name: active, var: active}]}
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id, thumbnail_id: $thumbnail_id, active: $active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the custom logos of an album
#
# GET /users/{user_id}/albums/{album_id}/logos
# Returns: table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>
# operationId: get_album_logos
export def "get-album-logos" [
  user_id: float
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/albums/{album_id}/logos"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a custom album logo
#
# POST /users/{user_id}/albums/{album_id}/logos
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: create_album_logo
export def "create-album-logo" [
  user_id: float
  album_id: float
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
    path: "/users/{user_id}/albums/{album_id}/logos"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a custom album logo
#
# DELETE /users/{user_id}/albums/{album_id}/logos/{logo_id}
# operationId: delete_album_logo
export def "delete-album-logo" [
  user_id: float
  album_id: float
  logo_id: float
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
    path: "/users/{user_id}/albums/{album_id}/logos/{logo_id}"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}, {name: logo_id, var: logo_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id, logo_id: $logo_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific custom album logo
#
# GET /users/{user_id}/albums/{album_id}/logos/{logo_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: get_album_logo
export def "get-album-logo" [
  user_id: float
  album_id: float
  logo_id: float
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
    path: "/users/{user_id}/albums/{album_id}/logos/{logo_id}"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}, {name: logo_id, var: logo_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id, logo_id: $logo_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace a custom album logo
#
# PATCH /users/{user_id}/albums/{album_id}/logos/{logo_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: replace_album_logo
export def "replace-album-logo" [
  user_id: float
  album_id: float
  logo_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Whether to make this the active album logo. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{user_id}/albums/{album_id}/logos/{logo_id}"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}, {name: logo_id, var: logo_id}]
    body: {content_type: "application/vnd.vimeo.picture+json", kind: json, fields: [{name: active, var: active}]}
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id, logo_id: $logo_id, active: $active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos in an album
#
# GET /users/{user_id}/albums/{album_id}/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_album_videos
export def "get-album-videos" [
  user_id: float
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page containing the video URI. (e.g. /videos/258684937)
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --password: string # The password of the album. (e.g. hunter1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-10 # The way to sort the results.
  --weak-search: oneof<nothing, bool> # Whether to include private videos in the search. Please note that a separate search service provides this functionality. The service performs a partial text search on the video's name. (e.g. false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/albums/{album_id}/videos"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}]
    query: [{name: containing_uri, var: containing_uri}, {name: direction, var: direction}, {name: filter, var: filter}, {name: filter_embeddable, var: filter_embeddable}, {name: page, var: page}, {name: password, var: password}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}, {name: weak_search, var: weak_search}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id, containing_uri: $containing_uri, direction: $direction, filter: $filter, filter_embeddable: $filter_embeddable, page: $page, password: $password, per_page: $per_page, query: $query, sort: $sort, weak_search: $weak_search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace all the videos in an album
#
# PUT /users/{user_id}/albums/{album_id}/videos
# operationId: replace_videos_in_album
export def "replace-videos-in-album" [
  user_id: float
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  videos: string # A comma-separated list of video URIs. (e.g. /videos/258684937,/videos/273576296)
]: any -> any {
  $in | http-request {
    method: put
    path: "/users/{user_id}/albums/{album_id}/videos"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: videos, var: videos}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id, videos: $videos
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a video from an album
#
# DELETE /users/{user_id}/albums/{album_id}/videos/{video_id}
# operationId: remove_video_from_album
export def "remove-video-from-album" [
  user_id: float
  album_id: float
  video_id: float
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
    path: "/users/{user_id}/albums/{album_id}/videos/{video_id}"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific video in an album
#
# GET /users/{user_id}/albums/{album_id}/videos/{video_id}
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: get_album_video
export def "get-album-video" [
  user_id: float
  album_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # The password of the album. (e.g. hunter1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/albums/{album_id}/videos/{video_id}"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}, {name: video_id, var: video_id}]
    query: [{name: password, var: password}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id, video_id: $video_id, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a specific video to an album
#
# PUT /users/{user_id}/albums/{album_id}/videos/{video_id}
# operationId: add_video_to_album
export def "add-video-to-album" [
  user_id: float
  album_id: float
  video_id: float
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
    method: put
    path: "/users/{user_id}/albums/{album_id}/videos/{video_id}"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set a video as the album thumbnail
#
# POST /users/{user_id}/albums/{album_id}/videos/{video_id}/set_album_thumbnail
# Returns: record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool>
# operationId: set_video_as_album_thumbnail
export def "set-video-as-album-thumbnail" [
  user_id: float
  album_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --time-code: float # The video frame time in seconds to use as the album thumbnail. (e.g. 300)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{user_id}/albums/{album_id}/videos/{video_id}/set_album_thumbnail"
    path_params: [{name: user_id, var: user_id}, {name: album_id, var: album_id}, {name: video_id, var: video_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: time_code, var: time_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, album_id: $album_id, video_id: $video_id, time_code: $time_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos in which a user appears
#
# GET /users/{user_id}/appearances
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_appearances
export def "get-appearances" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/appearances"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: filter_embeddable, var: filter_embeddable}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, direction: $direction, filter: $filter, filter_embeddable: $filter_embeddable, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the categories that a user follows
#
# GET /users/{user_id}/categories
# Returns: table<icon: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, last_video_featured_time: string, link: string, metadata: record<connections: record, interactions: record>, name: string, parent: record<link: string, name: string, uri: string>, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, resource_key: string, subcategories: list<record>, top_level: bool, uri: string>
# operationId: get_category_subscriptions
export def "get-category-subscriptions" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-11 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/categories"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.category+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, direction: $direction, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsubscribe a user from a category
#
# DELETE /users/{user_id}/categories/{category}
# operationId: unsubscribe_from_category
export def "unsubscribe-from-category" [
  user_id: float
  category: string
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
    path: "/users/{user_id}/categories/{category}"
    path_params: [{name: user_id, var: user_id}, {name: category, var: category}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user follows a category
#
# GET /users/{user_id}/categories/{category}
# operationId: check_if_user_subscribed_to_category
export def "check-if-user-subscribed-to-category" [
  user_id: float
  category: string
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
    path: "/users/{user_id}/categories/{category}"
    path_params: [{name: user_id, var: user_id}, {name: category, var: category}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe a user to a single category
#
# PUT /users/{user_id}/categories/{category}
# operationId: subscribe_to_category
export def "subscribe-to-category" [
  user_id: float
  category: float
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
    method: put
    path: "/users/{user_id}/categories/{category}"
    path_params: [{name: user_id, var: user_id}, {name: category, var: category}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the channels to which a user subscribes
#
# GET /users/{user_id}/channels
# Returns: table<categories: list<record>, created_time: string, description: string, header: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<view: string>, resource_key: string, tags: list<record>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_channel_subscriptions
export def "get-channel-subscriptions" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-5 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-1 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/channels"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.channel+json"]
    ok: [200, 304]
    auth: bearer
  } {
    user_id: $user_id, direction: $direction, filter: $filter, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsubscribe a user from a specific channel
#
# DELETE /users/{user_id}/channels/{channel_id}
# operationId: unsubscribe_from_channel
export def "unsubscribe-from-channel" [
  user_id: float
  channel_id: float
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
    path: "/users/{user_id}/channels/{channel_id}"
    path_params: [{name: user_id, var: user_id}, {name: channel_id, var: channel_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user follows a channel
#
# GET /users/{user_id}/channels/{channel_id}
# operationId: check_if_user_subscribed_to_channel
export def "check-if-user-subscribed-to-channel" [
  user_id: float
  channel_id: float
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
    path: "/users/{user_id}/channels/{channel_id}"
    path_params: [{name: user_id, var: user_id}, {name: channel_id, var: channel_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe a user to a specific channel
#
# PUT /users/{user_id}/channels/{channel_id}
# operationId: subscribe_to_channel
export def "subscribe-to-channel" [
  user_id: float
  channel_id: float
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
    method: put
    path: "/users/{user_id}/channels/{channel_id}"
    path_params: [{name: user_id, var: user_id}, {name: channel_id, var: channel_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the custom logos that belong to a user
#
# GET /users/{user_id}/customlogos
# Returns: table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>
# operationId: get_custom_logos
export def "get-custom-logos" [
  user_id: float
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
    path: "/users/{user_id}/customlogos"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a custom logo
#
# POST /users/{user_id}/customlogos
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: create_custom_logo
export def "create-custom-logo" [
  user_id: float
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
    path: "/users/{user_id}/customlogos"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific custom logo
#
# GET /users/{user_id}/customlogos/{logo_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: get_custom_logo
export def "get-custom-logo" [
  user_id: float
  logo_id: float
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
    path: "/users/{user_id}/customlogos/{logo_id}"
    path_params: [{name: user_id, var: user_id}, {name: logo_id, var: logo_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, logo_id: $logo_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all videos in a user's feed
#
# GET /users/{user_id}/feed
# Returns: table<category: record<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, channel: record<categories: list, created_time: string, description: string, header: record, link: string, metadata: record, modified_time: string, name: string, pictures: record, privacy: record, resource_key: string, tags: list, uri: string, user: record>, clip: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, group: record<created_time: string, description: string, link: string, metadata: record, modified_time: string, name: string, pictures: record, privacy: record, resource_key: string, uri: string, user: record>, metadata: record<connections: record>, tag: record<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, time: string, type: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_feed
export def "get-feed" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Necessary for proper pagination. You shouldn't provide this value yourself, and instead use the pagination links in the feed response. Please see our [pagination documentation](https://developer.vimeo.com/api/common-formats#using-the-pagination-parameter) for more information. (e.g. 280)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --type: string@type-completer-1 # The feed type.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/feed"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: offset, var: offset}, {name: page, var: page}, {name: per_page, var: per_page}, {name: type, var: type}]
    accept: ["application/vnd.vimeo.activity+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, offset: $offset, page: $page, per_page: $per_page, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the followers of a user
#
# GET /users/{user_id}/followers
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: get_followers
export def "get-followers" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/followers"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, direction: $direction, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the users that a user is following
#
# GET /users/{user_id}/following
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: get_user_following
export def "get-user-following" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-6 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/following"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, direction: $direction, filter: $filter, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow a list of users
#
# POST /users/{user_id}/following
# operationId: follow_users
export def "follow-users" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  users: list<string> # An array of user URIs for the list of users to follow.
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/{user_id}/following"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: users, var: users}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfollow a user
#
# DELETE /users/{user_id}/following/{follow_user_id}
# operationId: unfollow_user
export def "unfollow-user" [
  user_id: float
  follow_user_id: float
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
    path: "/users/{user_id}/following/{follow_user_id}"
    path_params: [{name: user_id, var: user_id}, {name: follow_user_id, var: follow_user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, follow_user_id: $follow_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user is following another user
#
# GET /users/{user_id}/following/{follow_user_id}
# operationId: check_if_user_is_following
export def "check-if-user-is-following" [
  user_id: float
  follow_user_id: float
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
    path: "/users/{user_id}/following/{follow_user_id}"
    path_params: [{name: user_id, var: user_id}, {name: follow_user_id, var: follow_user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, follow_user_id: $follow_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow a specific user
#
# PUT /users/{user_id}/following/{follow_user_id}
# operationId: follow_user
export def "follow-user" [
  user_id: float
  follow_user_id: float
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
    method: put
    path: "/users/{user_id}/following/{follow_user_id}"
    path_params: [{name: user_id, var: user_id}, {name: follow_user_id, var: follow_user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, follow_user_id: $follow_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the groups that a user has joined
#
# GET /users/{user_id}/groups
# Returns: table<created_time: string, description: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<comment: string, invite: string, join: string, videos: string, view: string>, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_user_groups
export def "get-user-groups" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-5 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-2 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/groups"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.group+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, direction: $direction, filter: $filter, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a user from a group
#
# DELETE /users/{user_id}/groups/{group_id}
# operationId: leave_group
export def "leave-group" [
  user_id: float
  group_id: float
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
    path: "/users/{user_id}/groups/{group_id}"
    path_params: [{name: user_id, var: user_id}, {name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user has joined a group
#
# GET /users/{user_id}/groups/{group_id}
# operationId: check_if_user_joined_group
export def "check-if-user-joined-group" [
  user_id: float
  group_id: float
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
    path: "/users/{user_id}/groups/{group_id}"
    path_params: [{name: user_id, var: user_id}, {name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a user to a group
#
# PUT /users/{user_id}/groups/{group_id}
# operationId: join_group
export def "join-group" [
  user_id: float
  group_id: float
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
    method: put
    path: "/users/{user_id}/groups/{group_id}"
    path_params: [{name: user_id, var: user_id}, {name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos that a user has liked
#
# GET /users/{user_id}/likes
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_likes
export def "get-likes" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/likes"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: filter, var: filter}, {name: filter_embeddable, var: filter_embeddable}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, filter: $filter, filter_embeddable: $filter_embeddable, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cause a user to unlike a video
#
# DELETE /users/{user_id}/likes/{video_id}
# operationId: unlike_video
export def "unlike-video" [
  user_id: float
  video_id: float
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
    path: "/users/{user_id}/likes/{video_id}"
    path_params: [{name: user_id, var: user_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user has liked a video
#
# GET /users/{user_id}/likes/{video_id}
# operationId: check_if_user_liked_video
export def "check-if-user-liked-video" [
  user_id: float
  video_id: float
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
    path: "/users/{user_id}/likes/{video_id}"
    path_params: [{name: user_id, var: user_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cause a user to like a video
#
# PUT /users/{user_id}/likes/{video_id}
# operationId: like_video
export def "like-video" [
  user_id: float
  video_id: float
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
    method: put
    path: "/users/{user_id}/likes/{video_id}"
    path_params: [{name: user_id, var: user_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the On Demand pages of a user
#
# GET /users/{user_id}/ondemand/pages
# Returns: table<background: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record, rent: record>, film: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, genres: list<record>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, trailer: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_user_vods
export def "get-user-vods" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-7 # The type of On Demand pages to return.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-12 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/ondemand/pages"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.ondemand.page+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, direction: $direction, filter: $filter, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an On Demand page
#
# POST /users/{user_id}/ondemand/pages
# Returns: record<background: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record<active: bool, price: float>, rent: record<active: bool, period: string, price: float>>, film: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, genres: table<canonical: string, interactions: record, link: string, metadata: record, name: string, uri: string>, link: string, metadata: record<connections: record<metadata: record>, interactions: record<buy: record, rent: record, subscribe: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, trailer: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: create_vod
export def "create-vod" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accepted-currencies: string@accepted-currencies-completer # An array of accepted currencies. Option descriptions: * `AUD` - Australian Dollar * `CAD` - Canadian Dollar * `CHF` - Swiss Franc * `DKK` - Danish Krone * `EUR` - Euro * `GBP` - British Pound * `JPY` - Japanese Yen * `KRW` - South Korean Won * `NOK` - Norwegian Krone * `PLN` - Polish Zloty * `SEK` - Swedish Krona * `USD` - US Dollar
  --buy: record # shape: {active?: bool, download?: bool, price?: record}
  content_rating: string@content-rating-completer # One or more ratings, either as a comma-separated list or as a JSON array depending on the request format.
  description: string # The description of the On Demand page. (e.g. DARBY FOREVER follows the fantasies of Darby, a shopgirl at "Bobbins & Notions".)
  --domain-link: string # The custom domain of the On Demand page. (e.g. https://example.com)
  --episodes: record # shape: {buy?: record, rent?: record}
  --link: string # The custom string to use in this On Demand page's Vimeo URL. (e.g. darbyforever)
  name: string # The name of the On Demand page. (e.g. Darby Forever)
  --rent: record # shape: {active?: bool, period?: "1 week"|"1 year"|"24 hour"|"3 month"|"30 day"|"48 hour"|"6 month"|"72 hour", price?: record}
  --subscription: record # shape: {monthly?: record}
  type: string@type-completer-2 # The type of On Demand page.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{user_id}/ondemand/pages"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accepted_currencies, var: accepted_currencies}, {name: buy, var: buy}, {name: content_rating, var: content_rating}, {name: description, var: description}, {name: domain_link, var: domain_link}, {name: episodes, var: episodes}, {name: link, var: link}, {name: name, var: name}, {name: rent, var: rent}, {name: subscription, var: subscription}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, accepted_currencies: $accepted_currencies, buy: $buy, content_rating: $content_rating, description: $description, domain_link: $domain_link, episodes: $episodes, link: $link, name: $name, rent: $rent, subscription: $subscription, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user has made a purchase or rental from an On Demand page
#
# GET /users/{user_id}/ondemand/purchases
# Returns: record<background: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record<active: bool, price: float>, rent: record<active: bool, period: string, price: float>>, film: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, genres: table<canonical: string, interactions: record, link: string, metadata: record, name: string, uri: string>, link: string, metadata: record<connections: record<metadata: record>, interactions: record<buy: record, rent: record, subscribe: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, trailer: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: check_if_vod_was_purchased
export def "check-if-vod-was-purchased" [
  user_id: float
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
    path: "/users/{user_id}/ondemand/purchases"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/vnd.vimeo.ondemand.page+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the pictures that belong to a user
#
# GET /users/{user_id}/pictures
# Returns: table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>
# operationId: get_pictures
export def "get-pictures" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/pictures"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a user picture
#
# POST /users/{user_id}/pictures
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: create_picture
export def "create-picture" [
  user_id: float
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
    path: "/users/{user_id}/pictures"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user picture
#
# DELETE /users/{user_id}/pictures/{portraitset_id}
# operationId: delete_picture
export def "delete-picture" [
  user_id: float
  portraitset_id: float
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
    path: "/users/{user_id}/pictures/{portraitset_id}"
    path_params: [{name: user_id, var: user_id}, {name: portraitset_id, var: portraitset_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, portraitset_id: $portraitset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific user picture
#
# GET /users/{user_id}/pictures/{portraitset_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: get_picture
export def "get-picture" [
  user_id: float
  portraitset_id: float
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
    path: "/users/{user_id}/pictures/{portraitset_id}"
    path_params: [{name: user_id, var: user_id}, {name: portraitset_id, var: portraitset_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, portraitset_id: $portraitset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a user picture
#
# PATCH /users/{user_id}/pictures/{portraitset_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: edit_picture
export def "edit-picture" [
  user_id: float
  portraitset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Whether the picture is the user's active portrait. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{user_id}/pictures/{portraitset_id}"
    path_params: [{name: user_id, var: user_id}, {name: portraitset_id, var: portraitset_id}]
    body: {content_type: "application/vnd.vimeo.picture+json", kind: json, fields: [{name: active, var: active}]}
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, portraitset_id: $portraitset_id, active: $active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the portfolios that belong to a user
#
# GET /users/{user_id}/portfolios
# Returns: table<created_time: string, description: string, link: string, metadata: record<connections: record>, modified_time: string, name: string, sort: string, uri: string>
# operationId: get_portfolios
export def "get-portfolios" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/portfolios"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.portfolio+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, direction: $direction, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific portfolio
#
# GET /users/{user_id}/portfolios/{portfolio_id}
# Returns: record<created_time: string, description: string, link: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, sort: string, uri: string>
# operationId: get_portfolio
export def "get-portfolio" [
  user_id: float
  portfolio_id: float
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
    path: "/users/{user_id}/portfolios/{portfolio_id}"
    path_params: [{name: user_id, var: user_id}, {name: portfolio_id, var: portfolio_id}]
    accept: ["application/vnd.vimeo.portfolio+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, portfolio_id: $portfolio_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos in a portfolio
#
# GET /users/{user_id}/portfolios/{portfolio_id}/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_portfolio_videos
export def "get-portfolio-videos" [
  user_id: float
  portfolio_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page that contains the video URI. (e.g. /videos/258684937)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-14 # The way to sort the results. Option descriptions: * `default` - This will sort to the default sort set on the portfolio.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/portfolios/{portfolio_id}/videos"
    path_params: [{name: user_id, var: user_id}, {name: portfolio_id, var: portfolio_id}]
    query: [{name: containing_uri, var: containing_uri}, {name: filter, var: filter}, {name: filter_embeddable, var: filter_embeddable}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, portfolio_id: $portfolio_id, containing_uri: $containing_uri, filter: $filter, filter_embeddable: $filter_embeddable, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a video from a portfolio
#
# DELETE /users/{user_id}/portfolios/{portfolio_id}/videos/{video_id}
# operationId: delete_video_from_portfolio
export def "delete-video-from-portfolio" [
  user_id: float
  portfolio_id: float
  video_id: float
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
    path: "/users/{user_id}/portfolios/{portfolio_id}/videos/{video_id}"
    path_params: [{name: user_id, var: user_id}, {name: portfolio_id, var: portfolio_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, portfolio_id: $portfolio_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific video in a portfolio
#
# GET /users/{user_id}/portfolios/{portfolio_id}/videos/{video_id}
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: get_portfolio_video
export def "get-portfolio-video" [
  user_id: float
  portfolio_id: float
  video_id: float
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
    path: "/users/{user_id}/portfolios/{portfolio_id}/videos/{video_id}"
    path_params: [{name: user_id, var: user_id}, {name: portfolio_id, var: portfolio_id}, {name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, portfolio_id: $portfolio_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a video to a portfolio
#
# PUT /users/{user_id}/portfolios/{portfolio_id}/videos/{video_id}
# operationId: add_video_to_portfolio
export def "add-video-to-portfolio" [
  user_id: float
  portfolio_id: float
  video_id: float
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
    method: put
    path: "/users/{user_id}/portfolios/{portfolio_id}/videos/{video_id}"
    path_params: [{name: user_id, var: user_id}, {name: portfolio_id, var: portfolio_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, portfolio_id: $portfolio_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the embed presets that a user has created
#
# GET /users/{user_id}/presets
# Returns: table<metadata: record<connections: record>, name: string, settings: record<buttons: record, logos: record, outro: record>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_embed_presets
export def "get-embed-presets" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/presets"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.preset+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific embed preset
#
# GET /users/{user_id}/presets/{preset_id}
# Returns: record<metadata: record<connections: record<videos: record>>, name: string, settings: record<buttons: record<embed: bool, hd: bool, like: bool, share: bool, vote: bool, watchlater: bool>, logos: record<custom: bool, sticky_custom: bool, vimeo: bool>, outro: record<clips: string, link: record, text: string, type: string, videos: string>>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: get_embed_preset
export def "get-embed-preset" [
  user_id: float
  preset_id: float
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
    path: "/users/{user_id}/presets/{preset_id}"
    path_params: [{name: user_id, var: user_id}, {name: preset_id, var: preset_id}]
    accept: ["application/vnd.vimeo.preset+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, preset_id: $preset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit an embed preset
#
# PATCH /users/{user_id}/presets/{preset_id}
# Returns: record<metadata: record<connections: record<videos: record>>, name: string, settings: record<buttons: record<embed: bool, hd: bool, like: bool, share: bool, vote: bool, watchlater: bool>, logos: record<custom: bool, sticky_custom: bool, vimeo: bool>, outro: record<clips: string, link: record, text: string, type: string, videos: string>>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: edit_embed_preset
export def "edit-embed-preset" [
  user_id: float
  preset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --outro: string@outro-completer # Disable the outro.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{user_id}/presets/{preset_id}"
    path_params: [{name: user_id, var: user_id}, {name: preset_id, var: preset_id}]
    body: {content_type: "application/vnd.vimeo.preset+json", kind: json, fields: [{name: outro, var: outro}]}
    accept: ["application/vnd.vimeo.preset+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, preset_id: $preset_id, outro: $outro
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos that have been added to an embed preset
#
# GET /users/{user_id}/presets/{preset_id}/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_embed_preset_videos
export def "get-embed-preset-videos" [
  user_id: float
  preset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/presets/{preset_id}/videos"
    path_params: [{name: user_id, var: user_id}, {name: preset_id, var: preset_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, preset_id: $preset_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the projects that belong to a user
#
# GET /users/{user_id}/projects
# Returns: table<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_projects
export def "get-projects" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-15 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/projects"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, direction: $direction, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a project
#
# POST /users/{user_id}/projects
# Returns: record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: create_project
export def "create-project" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the project. (e.g. Rough cuts)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{user_id}/projects"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a project
#
# DELETE /users/{user_id}/projects/{project_id}
# operationId: delete_project
export def "delete-project" [
  user_id: float
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --should-delete-clips: oneof<nothing, bool> # Whether to delete all the videos in the project along with the project itself. (e.g. true)
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/{user_id}/projects/{project_id}"
    path_params: [{name: user_id, var: user_id}, {name: project_id, var: project_id}]
    query: [{name: should_delete_clips, var: should_delete_clips}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, project_id: $project_id, should_delete_clips: $should_delete_clips
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific project
#
# GET /users/{user_id}/projects/{project_id}
# Returns: record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: get_project
export def "get-project" [
  user_id: float
  project_id: float
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
    path: "/users/{user_id}/projects/{project_id}"
    path_params: [{name: user_id, var: user_id}, {name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a project
#
# PATCH /users/{user_id}/projects/{project_id}
# Returns: record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: edit_project
export def "edit-project" [
  user_id: float
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the project. (e.g. Rough cuts)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{user_id}/projects/{project_id}"
    path_params: [{name: user_id, var: user_id}, {name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, project_id: $project_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a list of videos from a project
#
# DELETE /users/{user_id}/projects/{project_id}/videos
# operationId: remove_videos_from_project
export def "remove-videos-from-project" [
  user_id: float
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --should-delete-clips: oneof<nothing, bool> # Whether to delete the videos when removing them from the project. (e.g. false)
  --uris: string # A comma-separated list of the video URIs to remove. (required, e.g. /videos/258684937,/videos/273576296)
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/{user_id}/projects/{project_id}/videos"
    path_params: [{name: user_id, var: user_id}, {name: project_id, var: project_id}]
    query: [{name: should_delete_clips, var: should_delete_clips}, {name: uris, var: uris, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, project_id: $project_id, should_delete_clips: $should_delete_clips, uris: $uris
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos in a project
#
# GET /users/{user_id}/projects/{project_id}/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_project_videos
export def "get-project-videos" [
  user_id: float
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-16 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/projects/{project_id}/videos"
    path_params: [{name: user_id, var: user_id}, {name: project_id, var: project_id}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, project_id: $project_id, direction: $direction, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a list of videos to a project
#
# PUT /users/{user_id}/projects/{project_id}/videos
# operationId: add_videos_to_project
export def "add-videos-to-project" [
  user_id: float
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uris: string # A comma-separated list of video URIs to add. (required, e.g. /videos/258684937,/videos/273576296)
]: nothing -> any {
  http-request {
    method: put
    path: "/users/{user_id}/projects/{project_id}/videos"
    path_params: [{name: user_id, var: user_id}, {name: project_id, var: project_id}]
    query: [{name: uris, var: uris, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, project_id: $project_id, uris: $uris
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a specific video from a project
#
# DELETE /users/{user_id}/projects/{project_id}/videos/{video_id}
# operationId: remove_video_from_project
export def "remove-video-from-project" [
  user_id: float
  project_id: float
  video_id: float
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
    path: "/users/{user_id}/projects/{project_id}/videos/{video_id}"
    path_params: [{name: user_id, var: user_id}, {name: project_id, var: project_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, project_id: $project_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a specific video to a project
#
# PUT /users/{user_id}/projects/{project_id}/videos/{video_id}
# operationId: add_video_to_project
export def "add-video-to-project" [
  user_id: float
  project_id: float
  video_id: float
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
    method: put
    path: "/users/{user_id}/projects/{project_id}/videos/{video_id}"
    path_params: [{name: user_id, var: user_id}, {name: project_id, var: project_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, project_id: $project_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete a user's streaming upload
#
# DELETE /users/{user_id}/uploads/{upload}
# operationId: complete_streaming_upload
export def "complete-streaming-upload" [
  user_id: float
  upload: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --signature: string # The crypto signature of the completed upload. (required, e.g. cd89a20adde7a608f3331e71c37bdfa087bacbf3)
  --video-file-id: float # The ID of the uploaded file. (required, e.g. 1234)
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/{user_id}/uploads/{upload}"
    path_params: [{name: user_id, var: user_id}, {name: upload, var: upload}]
    query: [{name: signature, var: signature, required: true}, {name: video_file_id, var: video_file_id, required: true}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, upload: $upload, signature: $signature, video_file_id: $video_file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user's upload attempt
#
# GET /users/{user_id}/uploads/{upload}
# Returns: record<clip: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, complete_uri: string, form: string, ticket_id: string, upload_link: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: get_upload_attempt
export def "get-upload-attempt" [
  user_id: float
  upload: float
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
    path: "/users/{user_id}/uploads/{upload}"
    path_params: [{name: user_id, var: user_id}, {name: upload, var: upload}]
    accept: ["application/vnd.vimeo.uploadattempt+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, upload: $upload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos that a user has uploaded
#
# GET /users/{user_id}/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_videos
export def "get-videos" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page that contains the video URI. Only available when not paired with `query`. (e.g. /videos/258684937)
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-9 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --filter-playable: oneof<nothing, bool> # Whether to filter by all playable videos or by all videos that are not playable. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-17 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/videos"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: containing_uri, var: containing_uri}, {name: direction, var: direction}, {name: filter, var: filter}, {name: filter_embeddable, var: filter_embeddable}, {name: filter_playable, var: filter_playable}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200, 304]
    auth: bearer
  } {
    user_id: $user_id, containing_uri: $containing_uri, direction: $direction, filter: $filter, filter_embeddable: $filter_embeddable, filter_playable: $filter_playable, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a video
#
# POST /users/{user_id}/videos
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: upload_video
export def "upload-video" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-rating: list<string> # A list of values describing the content in this video. Find the full list in the [/contentratings](https://developer.vimeo.com/api/endpoints/videos#GET/contentratings) endpoint.
  --description: string # The description of the video. (e.g. A celebration of 10 years of Staff Picks.)
  --embed: record # shape: {buttons?: record, color?: string, logos?: record, playbar?: bool, title?: record, volume?: bool}
  --license: string@license-completer # The Creative Commons license.
  --locale: string # The video's default language. For a full list of valid languages, use the [/languages?filter=texttracks](https://developer.vimeo.com/api/endpoints/videos#GET/languages) endpoint. (e.g. en_US)
  --name: string # The title of the video. (e.g. Celebrating 10 Years of Staff Picks)
  --password: string # The password. When you set `privacy.view` to `password`, you must provide the password as an additional parameter. (e.g. hunter1)
  --privacy: record # shape: {add?: bool, comments?: "anybody"|"contacts"|"nobody", download?: bool, embed?: "private"|"public"|"whitelist", view?: "anybody"|"contacts"|"disable"|"nobody"|"password"|"unlisted"|"users"}
  --ratings: record # shape: {mpaa?: record, tv?: record}
  --review-page: record # shape: {active?: bool}
  --spatial: record # shape: {director_timeline?: list, field_of_view?: float, projection?: "cubical"|"cylindrical"|"dome"|"equirectangular"|"pyramid", stereo_format?: "left-right"|"mono"|"top-bottom"}
  upload: record # shape: {approach: "post"|"pull"|"streaming"|"tus", link?: string, redirect_url?: string, size?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{user_id}/videos"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/vnd.vimeo.video+json", kind: json, fields: [{name: content_rating, var: content_rating}, {name: description, var: description}, {name: embed, var: embed}, {name: license, var: license}, {name: locale, var: locale}, {name: name, var: name}, {name: password, var: password}, {name: privacy, var: privacy}, {name: ratings, var: ratings}, {name: review_page, var: review_page}, {name: spatial, var: spatial}, {name: upload, var: upload}]}
    accept: ["application/vnd.vimeo.video+json"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, content_rating: $content_rating, description: $description, embed: $embed, license: $license, locale: $locale, name: $name, password: $password, privacy: $privacy, ratings: $ratings, review_page: $review_page, spatial: $spatial, upload: $upload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user owns a video
#
# GET /users/{user_id}/videos/{video_id}
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: check_if_user_owns_video
export def "check-if-user-owns-video" [
  user_id: float
  video_id: float
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
    path: "/users/{user_id}/videos/{video_id}"
    path_params: [{name: user_id, var: user_id}, {name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the videos in a user's Watch Later queue
#
# GET /users/{user_id}/watchlater
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_watch_later_queue
export def "get-watch-later-queue" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/watchlater"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: filter_embeddable, var: filter_embeddable}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200, 304]
    auth: bearer
  } {
    user_id: $user_id, direction: $direction, filter: $filter, filter_embeddable: $filter_embeddable, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a video from a user's Watch Later queue
#
# DELETE /users/{user_id}/watchlater/{video_id}
# operationId: delete_video_from_watch_later
export def "delete-video-from-watch-later" [
  user_id: float
  video_id: float
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
    path: "/users/{user_id}/watchlater/{video_id}"
    path_params: [{name: user_id, var: user_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user has added a specific video to their Watch Later queue
#
# GET /users/{user_id}/watchlater/{video_id}
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: check_watch_later_queue
export def "check-watch-later-queue" [
  user_id: float
  video_id: float
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
    path: "/users/{user_id}/watchlater/{video_id}"
    path_params: [{name: user_id, var: user_id}, {name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a video to a user's Watch Later queue
#
# PUT /users/{user_id}/watchlater/{video_id}
# operationId: add_video_to_watch_later
export def "add-video-to-watch-later" [
  user_id: float
  video_id: float
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
    method: put
    path: "/users/{user_id}/watchlater/{video_id}"
    path_params: [{name: user_id, var: user_id}, {name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for videos
#
# GET /videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: search_videos
export def "search-videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-15 # The attribute by which to filter the results. `CC` and related filters target videos with the corresponding Creative Commons licenses. For more information, see our [Creative Commons](https://vimeo.com/creativecommons) page.
  --links: string # A comma-separated list of video URLs to find. (e.g. https://vimeo.com/122375452,https://vimeo.com/273576296)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # Search query. (required, e.g. staff picks)
  --sort: string@sort-completer-23 # The way to sort the results.
  --uris: string # The comma-separated list of videos to find. (e.g. /videos/122375452,/videos/273576296)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/videos"
    query: [{name: direction, var: direction}, {name: filter, var: filter}, {name: links, var: links}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query, required: true}, {name: sort, var: sort}, {name: uris, var: uris}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    direction: $direction, filter: $filter, links: $links, page: $page, per_page: $per_page, query: $query, sort: $sort, uris: $uris
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a video
#
# DELETE /videos/{video_id}
# operationId: delete_video
export def "delete-video" [
  video_id: float
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
    path: "/videos/{video_id}"
    path_params: [{name: video_id, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific video
#
# GET /videos/{video_id}
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: get_video
export def "get-video" [
  video_id: float
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
    path: "/videos/{video_id}"
    path_params: [{name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a video
#
# PATCH /videos/{video_id}
# Returns: record<categories: table<icon: record, last_video_featured_time: string, link: string, metadata: record, name: string, parent: record, pictures: record, resource_key: string, subcategories: list, top_level: bool, uri: string>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record<embed: bool, fullscreen: bool, hd: bool, like: bool, scaling: bool, share: bool, watchlater: bool>, color: string, logos: record<custom: record, vimeo: bool>, playbar: bool, speed: bool, title: record<name: string, owner: string, portrait: string>, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record<comments: record, credits: record, likes: record, ondemand: record, pictures: record, playback: record, recommendations: record, related: record, season: record, texttracks: record, trailer: record, users_with_access: record, versions: record>, interactions: record<buy: record, channel: record, like: record, rent: record, report: record, subscribe: record, watched: record, watchlater: record>>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list<record>, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: table<canonical: string, metadata: record, name: string, resource_key: string, uri: string>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, width: float>
# operationId: edit_video
export def "edit-video" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-rating: list<string> # A list of values describing the content in this video. You can find the full list in the [`/contentratings`](https://developer.vimeo.com/api/endpoints/videos#GET/contentratings) endpoint.
  --description: string # The new description of the video. (e.g. A celebration of 10 years of Staff Picks.)
  --embed: record # shape: {buttons?: record, color?: string, logos?: record, playbar?: bool, title?: record, volume?: bool}
  --license: string@license-completer # The Creative Commons license.
  --locale: string # The video's default language. For a full list of valid languages, use the [/languages?filter=texttracks](https://developer.vimeo.com/api/endpoints/videos#GET/languages) endpoint. (e.g. en-US)
  --name: string # The new title for the video. (e.g. Celebrating 10 Years of Staff Picks)
  --password: string # The password. When you set `privacy.view` to `password`, you must provide the password as an additional parameter. (e.g. hunter1)
  --privacy: record # shape: {add?: bool, comments?: "anybody"|"contacts"|"nobody", download?: bool, embed?: "private"|"public"|"whitelist", view?: "anybody"|"contacts"|"disable"|"nobody"|"password"|"unlisted"|"users"}
  --ratings: record # shape: {mpaa?: record, tv?: record}
  --review-page: record # shape: {active?: bool}
  --spatial: record # shape: {director_timeline?: list, field_of_view?: float, projection?: "cubical"|"cylindrical"|"dome"|"equirectangular"|"pyramid", stereo_format?: "left-right"|"mono"|"top-bottom"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/videos/{video_id}"
    path_params: [{name: video_id, var: video_id}]
    body: {content_type: "application/vnd.vimeo.video+json", kind: json, fields: [{name: content_rating, var: content_rating}, {name: description, var: description}, {name: embed, var: embed}, {name: license, var: license}, {name: locale, var: locale}, {name: name, var: name}, {name: password, var: password}, {name: privacy, var: privacy}, {name: ratings, var: ratings}, {name: review_page, var: review_page}, {name: spatial, var: spatial}]}
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, content_rating: $content_rating, description: $description, embed: $embed, license: $license, locale: $locale, name: $name, password: $password, privacy: $privacy, ratings: $ratings, review_page: $review_page, spatial: $spatial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the channels to which a user can add or remove a specific video
#
# GET /videos/{video_id}/available_channels
# Returns: table<categories: list<record>, created_time: string, description: string, header: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<view: string>, resource_key: string, tags: list<record>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_available_video_channels
export def "get-available-video-channels" [
  video_id: float
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
    path: "/videos/{video_id}/available_channels"
    path_params: [{name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.channel+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the categories to which a video belongs
#
# GET /videos/{video_id}/categories
# Returns: table<icon: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, last_video_featured_time: string, link: string, metadata: record<connections: record, interactions: record>, name: string, parent: record<link: string, name: string, uri: string>, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, resource_key: string, subcategories: list<record>, top_level: bool, uri: string>
# operationId: get_video_categories
export def "get-video-categories" [
  video_id: float
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
    path: "/videos/{video_id}/categories"
    path_params: [{name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.category+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suggest categories for a video
#
# PUT /videos/{video_id}/categories
# Returns: record<icon: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, last_video_featured_time: string, link: string, metadata: record<connections: record<channels: record, groups: record, users: record, videos: record>, interactions: record<follow: record>>, name: string, parent: record<link: string, name: string, uri: string>, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, resource_key: string, subcategories: table<link: string, name: string, uri: string>, top_level: bool, uri: string>
# operationId: suggest_video_category
export def "suggest-video-category" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  category: list<string> # The array of the names of the categories that you're suggesting.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/videos/{video_id}/categories"
    path_params: [{name: video_id, var: video_id}]
    body: {content_type: "application/vnd.vimeo.category+json", kind: json, fields: [{name: category, var: category}]}
    accept: ["application/vnd.vimeo.category+json"]
    ok: [201]
    auth: bearer
  } {
    video_id: $video_id, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the comments on a video
#
# GET /videos/{video_id}/comments
# Returns: table<created_on: string, metadata: record<connections: record>, resource_key: string, text: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_comments
export def "get-comments" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/videos/{video_id}/comments"
    path_params: [{name: video_id, var: video_id}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.comment+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, direction: $direction, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a comment to a video
#
# POST /videos/{video_id}/comments
# Returns: record<created_on: string, metadata: record<connections: record<replies: record>>, resource_key: string, text: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: create_comment
export def "create-comment" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # The text of the comment. (e.g. I love this!)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/videos/{video_id}/comments"
    path_params: [{name: video_id, var: video_id}]
    body: {content_type: "application/vnd.vimeo.comment+json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/vnd.vimeo.comment+json"]
    ok: [201]
    auth: bearer
  } {
    video_id: $video_id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a video comment
#
# DELETE /videos/{video_id}/comments/{comment_id}
# operationId: delete_comment
export def "delete-comment" [
  video_id: float
  comment_id: float
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
    path: "/videos/{video_id}/comments/{comment_id}"
    path_params: [{name: video_id, var: video_id}, {name: comment_id, var: comment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id, comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific video comment
#
# GET /videos/{video_id}/comments/{comment_id}
# Returns: record<created_on: string, metadata: record<connections: record<replies: record>>, resource_key: string, text: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: get_comment
export def "get-comment" [
  video_id: float
  comment_id: float
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
    path: "/videos/{video_id}/comments/{comment_id}"
    path_params: [{name: video_id, var: video_id}, {name: comment_id, var: comment_id}]
    accept: ["application/vnd.vimeo.comment+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a video comment
#
# PATCH /videos/{video_id}/comments/{comment_id}
# Returns: record<created_on: string, metadata: record<connections: record<replies: record>>, resource_key: string, text: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: edit_comment
export def "edit-comment" [
  video_id: float
  comment_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # The next text of the comment. (e.g. I love this!)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/videos/{video_id}/comments/{comment_id}"
    path_params: [{name: video_id, var: video_id}, {name: comment_id, var: comment_id}]
    body: {content_type: "application/vnd.vimeo.comment+json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/vnd.vimeo.comment+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, comment_id: $comment_id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the replies to a video comment
#
# GET /videos/{video_id}/comments/{comment_id}/replies
# Returns: table<created_on: string, metadata: record<connections: record>, resource_key: string, text: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>>
# operationId: get_comment_replies
export def "get-comment-replies" [
  video_id: float
  comment_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/videos/{video_id}/comments/{comment_id}/replies"
    path_params: [{name: video_id, var: video_id}, {name: comment_id, var: comment_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.comment+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, comment_id: $comment_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a reply to a video comment
#
# POST /videos/{video_id}/comments/{comment_id}/replies
# Returns: record<created_on: string, metadata: record<connections: record<replies: record>>, resource_key: string, text: string, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: create_comment_reply
export def "create-comment-reply" [
  video_id: float
  comment_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # The reply to the comment. (e.g. I love this!)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/videos/{video_id}/comments/{comment_id}/replies"
    path_params: [{name: video_id, var: video_id}, {name: comment_id, var: comment_id}]
    body: {content_type: "application/vnd.vimeo.comment+json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/vnd.vimeo.comment+json"]
    ok: [201]
    auth: bearer
  } {
    video_id: $video_id, comment_id: $comment_id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the credited users in a video
#
# GET /videos/{video_id}/credits
# Returns: table<name: string, role: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, video: record<categories: list, content_rating: list, context: record, created_time: string, description: string, duration: float, embed: record, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record, modified_time: string, name: string, parent_folder: record, password: string, pictures: record, privacy: record, release_time: string, resource_key: string, spatial: record, stats: record, status: string, tags: list, transcode: record, upload: record, uri: string, user: record, width: float>>
# operationId: get_video_credits
export def "get-video-credits" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/videos/{video_id}/credits"
    path_params: [{name: video_id, var: video_id}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: query, var: query}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.credit+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, direction: $direction, page: $page, per_page: $per_page, query: $query, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Credit a user in a video
#
# POST /videos/{video_id}/credits
# Returns: record<name: string, role: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, video: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>>
# operationId: add_video_credit
export def "add-video-credit" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email address of the credited person. (e.g. user@example.com)
  name: string # The name of the credited person. (e.g. Sam Doe)
  role: string # The role of the credited person. (e.g. Producer)
  user_uri: string # The URI of the Vimeo user who should be given credit in this video. (e.g. /users/152184)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/videos/{video_id}/credits"
    path_params: [{name: video_id, var: video_id}]
    body: {content_type: "application/vnd.vimeo.credit+json", kind: json, fields: [{name: email, var: email}, {name: name, var: name}, {name: role, var: role}, {name: user_uri, var: user_uri}]}
    accept: ["application/vnd.vimeo.credit+json"]
    ok: [201]
    auth: bearer
  } {
    video_id: $video_id, email: $email, name: $name, role: $role, user_uri: $user_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a credit for a user in a video
#
# DELETE /videos/{video_id}/credits/{credit_id}
# operationId: delete_video_credit
export def "delete-video-credit" [
  video_id: float
  credit_id: float
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
    path: "/videos/{video_id}/credits/{credit_id}"
    path_params: [{name: video_id, var: video_id}, {name: credit_id, var: credit_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id, credit_id: $credit_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific credited user in a video
#
# GET /videos/{video_id}/credits/{credit_id}
# Returns: record<name: string, role: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, video: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>>
# operationId: get_video_credit
export def "get-video-credit" [
  video_id: float
  credit_id: float
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
    path: "/videos/{video_id}/credits/{credit_id}"
    path_params: [{name: video_id, var: video_id}, {name: credit_id, var: credit_id}]
    accept: ["application/vnd.vimeo.credit+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, credit_id: $credit_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a credit for a user in a video
#
# PATCH /videos/{video_id}/credits/{credit_id}
# Returns: record<name: string, role: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, video: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>>
# operationId: edit_video_credit
export def "edit-video-credit" [
  video_id: float
  credit_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the person being credited. (e.g. Sam Doe)
  --role: string # The role of the person being credited. (e.g. Producer)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/videos/{video_id}/credits/{credit_id}"
    path_params: [{name: video_id, var: video_id}, {name: credit_id, var: credit_id}]
    body: {content_type: "application/vnd.vimeo.credit+json", kind: json, fields: [{name: name, var: name}, {name: role, var: role}]}
    accept: ["application/vnd.vimeo.credit+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, credit_id: $credit_id, name: $name, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the users who have liked a video
#
# GET /videos/{video_id}/likes
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: get_video_likes
export def "get-video-likes" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/videos/{video_id}/likes"
    path_params: [{name: video_id, var: video_id}]
    query: [{name: direction, var: direction}, {name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, direction: $direction, page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the thumbnails of a video
#
# GET /videos/{video_id}/pictures
# Returns: table<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>
# operationId: get_video_thumbnails
export def "get-video-thumbnails" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/videos/{video_id}/pictures"
    path_params: [{name: video_id, var: video_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a video thumbnail
#
# POST /videos/{video_id}/pictures
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: create_video_thumbnail
export def "create-video-thumbnail" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Whether the image created by the `time` field should be the default thumbnail for the video. (e.g. true)
  --time: float # Creates an image of the video from the given time offset. (e.g. 300)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/videos/{video_id}/pictures"
    path_params: [{name: video_id, var: video_id}]
    body: {content_type: "application/vnd.vimeo.picture+json", kind: json, fields: [{name: active, var: active}, {name: time, var: time}]}
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [201]
    auth: bearer
  } {
    video_id: $video_id, active: $active, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a video thumbnail
#
# DELETE /videos/{video_id}/pictures/{picture_id}
# operationId: delete_video_thumbnail
export def "delete-video-thumbnail" [
  video_id: float
  picture_id: float
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
    path: "/videos/{video_id}/pictures/{picture_id}"
    path_params: [{name: video_id, var: video_id}, {name: picture_id, var: picture_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id, picture_id: $picture_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a video thumbnail
#
# GET /videos/{video_id}/pictures/{picture_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: get_video_thumbnail
export def "get-video-thumbnail" [
  video_id: float
  picture_id: float
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
    path: "/videos/{video_id}/pictures/{picture_id}"
    path_params: [{name: video_id, var: video_id}, {name: picture_id, var: picture_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, picture_id: $picture_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a video thumbnail
#
# PATCH /videos/{video_id}/pictures/{picture_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: edit_video_thumbnail
export def "edit-video-thumbnail" [
  video_id: float
  picture_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Whether this thumbnail is the default. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/videos/{video_id}/pictures/{picture_id}"
    path_params: [{name: video_id, var: video_id}, {name: picture_id, var: picture_id}]
    body: {content_type: "application/vnd.vimeo.picture+json", kind: json, fields: [{name: active, var: active}]}
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, picture_id: $picture_id, active: $active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an embed preset from a video
#
# DELETE /videos/{video_id}/presets/{preset_id}
# operationId: delete_video_embed_preset
export def "delete-video-embed-preset" [
  video_id: float
  preset_id: float
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
    path: "/videos/{video_id}/presets/{preset_id}"
    path_params: [{name: video_id, var: video_id}, {name: preset_id, var: preset_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id, preset_id: $preset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if an embed preset has been added to a video
#
# GET /videos/{video_id}/presets/{preset_id}
# operationId: get_video_embed_preset
export def "get-video-embed-preset" [
  video_id: float
  preset_id: float
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
    path: "/videos/{video_id}/presets/{preset_id}"
    path_params: [{name: video_id, var: video_id}, {name: preset_id, var: preset_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id, preset_id: $preset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an embed preset to a video
#
# PUT /videos/{video_id}/presets/{preset_id}
# operationId: add_video_embed_preset
export def "add-video-embed-preset" [
  video_id: float
  preset_id: float
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
    method: put
    path: "/videos/{video_id}/presets/{preset_id}"
    path_params: [{name: video_id, var: video_id}, {name: preset_id, var: preset_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id, preset_id: $preset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the domains on which a video can be embedded
#
# GET /videos/{video_id}/privacy/domains
# Returns: table<allow_hd: bool, domain: string, uri: string>
# operationId: get_video_privacy_domains
export def "get-video-privacy-domains" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/videos/{video_id}/privacy/domains"
    path_params: [{name: video_id, var: video_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.domain+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restrict a video from being embedded on a domain
#
# DELETE /videos/{video_id}/privacy/domains/{domain}
# operationId: delete_video_privacy_domain
export def "delete-video-privacy-domain" [
  video_id: float
  domain: string
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
    path: "/videos/{video_id}/privacy/domains/{domain}"
    path_params: [{name: video_id, var: video_id}, {name: domain, var: domain}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id, domain: $domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permit a video to be embedded on a domain
#
# PUT /videos/{video_id}/privacy/domains/{domain}
# operationId: add_video_privacy_domain
export def "add-video-privacy-domain" [
  video_id: float
  domain: string
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
    method: put
    path: "/videos/{video_id}/privacy/domains/{domain}"
    path_params: [{name: video_id, var: video_id}, {name: domain, var: domain}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id, domain: $domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the users who can view a user's private videos by default
#
# GET /videos/{video_id}/privacy/users
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: get_video_privacy_users
export def "get-video-privacy-users" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/videos/{video_id}/privacy/users"
    path_params: [{name: video_id, var: video_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permit a list of users to view a private video
#
# PUT /videos/{video_id}/privacy/users
# Returns: table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>
# operationId: add_video_privacy_users
export def "add-video-privacy-users" [
  video_id: float
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
    method: put
    path: "/videos/{video_id}/privacy/users"
    path_params: [{name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restrict a user from viewing a private video
#
# DELETE /videos/{video_id}/privacy/users/{user_id}
# operationId: delete_video_privacy_user
export def "delete-video-privacy-user" [
  video_id: float
  user_id: float
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
    path: "/videos/{video_id}/privacy/users/{user_id}"
    path_params: [{name: video_id, var: video_id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permit a specific user to view a private video
#
# PUT /videos/{video_id}/privacy/users/{user_id}
# Returns: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record<albums: record, appearances: record, block: record, categories: record, channels: record, feed: record, folders: record, followers: record, following: record, groups: record, likes: record, moderated_channels: record, pictures: record, portfolios: record, recommended_channels: record, recommended_users: record, shared: record, videos: record, watched_videos: record, watchlater: record>, interactions: record<add_privacy_user: record, block: record, follow: record, report: record>>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preferences: record<videos: record<privacy: record>>, resource_key: string, upload_quota: record<lifetime: record<free: float, max: float, used: float>, periodic: record<free: float, max: float, reset_date: string, used: float>, space: record<free: float, max: float, showing: string, used: float>>, uri: string, websites: table<description: string, link: string, name: string>>
# operationId: add_video_privacy_user
export def "add-video-privacy-user" [
  video_id: float
  user_id: float
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
    method: put
    path: "/videos/{video_id}/privacy/users/{user_id}"
    path_params: [{name: video_id, var: video_id}, {name: user_id, var: user_id}]
    accept: ["application/vnd.vimeo.user+json"]
    ok: [200, 204]
    auth: bearer
  } {
    video_id: $video_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the tags of a video
#
# GET /videos/{video_id}/tags
# Returns: table<canonical: string, metadata: record<connections: record>, name: string, resource_key: string, uri: string>
# operationId: get_video_tags
export def "get-video-tags" [
  video_id: float
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
    path: "/videos/{video_id}/tags"
    path_params: [{name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.tag+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a list of tags to a video
#
# PUT /videos/{video_id}/tags
# Returns: table<canonical: string, metadata: record<connections: record>, name: string, resource_key: string, uri: string>
# operationId: add_video_tags
export def "add-video-tags" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the tag to apply. See our documentation on [batch requests](https://developer.vimeo.com/api/common-formats#batch-requests) for more information. (e.g. awesome)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/videos/{video_id}/tags"
    path_params: [{name: video_id, var: video_id}]
    body: {content_type: "application/vnd.vimeo.tag+json", kind: json, fields: [{name: name, var: name}, {name: page, var: page}, {name: per_page, var: per_page}]}
    accept: ["application/vnd.vimeo.tag+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, name: $name, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a tag from a video
#
# DELETE /videos/{video_id}/tags/{word}
# operationId: delete_video_tag
export def "delete-video-tag" [
  video_id: float
  word: string
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
    path: "/videos/{video_id}/tags/{word}"
    path_params: [{name: video_id, var: video_id}, {name: word, var: word}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id, word: $word
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a tag has been added to a video
#
# GET /videos/{video_id}/tags/{word}
# Returns: record<canonical: string, metadata: record<connections: record<videos: record>>, name: string, resource_key: string, uri: string>
# operationId: check_video_for_tag
export def "check-video-for-tag" [
  video_id: float
  word: string
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
    path: "/videos/{video_id}/tags/{word}"
    path_params: [{name: video_id, var: video_id}, {name: word, var: word}]
    accept: ["application/vnd.vimeo.tag+json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id, word: $word
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a specific tag to a video
#
# PUT /videos/{video_id}/tags/{word}
# Returns: record<canonical: string, metadata: record<connections: record<videos: record>>, name: string, resource_key: string, uri: string>
# operationId: add_video_tag
export def "add-video-tag" [
  video_id: float
  word: string
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
    method: put
    path: "/videos/{video_id}/tags/{word}"
    path_params: [{name: video_id, var: video_id}, {name: word, var: word}]
    accept: ["application/vnd.vimeo.tag+json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id, word: $word
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the text tracks of a video
#
# GET /videos/{video_id}/texttracks
# Returns: table<active: bool, hls_link: string, hls_link_expires_time: string, language: string, link: string, link_expires_time: string, name: string, type: string, uri: string>
# operationId: get_text_tracks
export def "get-text-tracks" [
  video_id: float
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
    path: "/videos/{video_id}/texttracks"
    path_params: [{name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.video.texttrack+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a text track to a video
#
# POST /videos/{video_id}/texttracks
# Returns: record<active: bool, hls_link: string, hls_link_expires_time: string, language: string, link: string, link_expires_time: string, name: string, type: string, uri: string>
# operationId: create_text_track
export def "create-text-track" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Active text tracks appear in the player and are visible to other users. Only one text track per language can be active. (e.g. true)
  language: string # The language of the text track. For a complete list of valid languages, use the [/languages?filter=texttracks](https://developer.vimeo.com/api/endpoints/videos#GET/languages) endpoint. (e.g. en-US)
  name: string # The name of the text track. (e.g. Commentary)
  type: string@type-completer # The type of the text track.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/videos/{video_id}/texttracks"
    path_params: [{name: video_id, var: video_id}]
    body: {content_type: "application/vnd.vimeo.video.texttrack+json", kind: json, fields: [{name: active, var: active}, {name: language, var: language}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/vnd.vimeo.video.texttrack+json"]
    ok: [201]
    auth: bearer
  } {
    video_id: $video_id, active: $active, language: $language, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a text track
#
# DELETE /videos/{video_id}/texttracks/{texttrack_id}
# operationId: delete_text_track
export def "delete-text-track" [
  video_id: float
  texttrack_id: float
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
    path: "/videos/{video_id}/texttracks/{texttrack_id}"
    path_params: [{name: video_id, var: video_id}, {name: texttrack_id, var: texttrack_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id, texttrack_id: $texttrack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific text track
#
# GET /videos/{video_id}/texttracks/{texttrack_id}
# Returns: record<active: bool, hls_link: string, hls_link_expires_time: string, language: string, link: string, link_expires_time: string, name: string, type: string, uri: string>
# operationId: get_text_track
export def "get-text-track" [
  video_id: float
  texttrack_id: float
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
    path: "/videos/{video_id}/texttracks/{texttrack_id}"
    path_params: [{name: video_id, var: video_id}, {name: texttrack_id, var: texttrack_id}]
    accept: ["application/vnd.vimeo.video.texttrack+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, texttrack_id: $texttrack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a text track
#
# PATCH /videos/{video_id}/texttracks/{texttrack_id}
# Returns: record<active: bool, hls_link: string, hls_link_expires_time: string, language: string, link: string, link_expires_time: string, name: string, type: string, uri: string>
# operationId: edit_text_track
export def "edit-text-track" [
  video_id: float
  texttrack_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Whether the text track is active, meaning that it appears in the player. Only one text track per language, and type, can be active. (e.g. true)
  --language: string # The language of the text track. For a full list of valid languages, use the [/languages?filter=texttracks](https://developer.vimeo.com/api/endpoints/videos#GET/languages) endpoint. (e.g. en-US)
  --name: string # The name of the text track. (e.g. Commentary)
  --type: string@type-completer # The text track type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/videos/{video_id}/texttracks/{texttrack_id}"
    path_params: [{name: video_id, var: video_id}, {name: texttrack_id, var: texttrack_id}]
    body: {content_type: "application/vnd.vimeo.video.texttrack+json", kind: json, fields: [{name: active, var: active}, {name: language, var: language}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/vnd.vimeo.video.texttrack+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, texttrack_id: $texttrack_id, active: $active, language: $language, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new custom logo to a video
#
# POST /videos/{video_id}/timelinethumbnails
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: create_video_custom_logo
export def "create-video-custom-logo" [
  video_id: float
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
    path: "/videos/{video_id}/timelinethumbnails"
    path_params: [{name: video_id, var: video_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [201]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a custom video logo
#
# GET /videos/{video_id}/timelinethumbnails/{thumbnail_id}
# Returns: record<active: bool, link: string, resource_key: string, sizes: table<height: float, link: string, link_with_play_button: string, width: float>, type: string, uri: string>
# operationId: get_video_custom_logo
export def "get-video-custom-logo" [
  video_id: float
  thumbnail_id: float
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
    path: "/videos/{video_id}/timelinethumbnails/{thumbnail_id}"
    path_params: [{name: video_id, var: video_id}, {name: thumbnail_id, var: thumbnail_id}]
    accept: ["application/vnd.vimeo.picture+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, thumbnail_id: $thumbnail_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a version to a video
#
# POST /videos/{video_id}/versions
# Returns: record<active: bool, app: record<name: string, uri: string>, created_time: string, duration: float, filename: string, filesize: float, metadata: record<connections: record<video: record>>, modified_time: string, play: record<progressive: list<record>, status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, upload_date: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>>
# operationId: create_video_version
export def "create-video-version" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file_name: string # The name of the version (e.g. untitled.mp4)
  upload: record # shape: {approach: "post"|"pull"|"streaming"|"tus", link?: string, redirect_url?: string, size?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/videos/{video_id}/versions"
    path_params: [{name: video_id, var: video_id}]
    body: {content_type: "application/vnd.vimeo.video.version+json", kind: json, fields: [{name: file_name, var: file_name}, {name: upload, var: upload}]}
    accept: ["application/vnd.vimeo.video.version+json"]
    ok: [201]
    auth: bearer
  } {
    video_id: $video_id, file_name: $file_name, upload: $upload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the related videos of a video
#
# GET /videos/{video_id}/videos
# Returns: table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>
# operationId: get_related_videos
export def "get-related-videos" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-16 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/videos/{video_id}/videos"
    path_params: [{name: video_id, var: video_id}]
    query: [{name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/vnd.vimeo.video+json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, filter: $filter, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
