# Auto-generated client for Figshare API v2.0.0
# Source: https://api.apis.guru/v2/specs/figshare.com/2.0.0/openapi.json
# Auth: --token flag or $env.FIGSHARE_API_TOKEN

const CLIENT = {
  base_url: "https://api.figshare.com/v2"
  token_env_var: "FIGSHARE_API_TOKEN"
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

def base-url-completer [] { ["https://api.figshare.com/v2"] }
def auth-scheme-completer [] { ["bearer" "none"] }

# Completers for enum parameters
def order-completer [] { ["cites" "downloads" "modified_date" "published_date" "shares" "views"] }
def order-direction-completer [] { ["asc" "desc"] }
def embargo-type-completer [] { ["article" "file"] }
def order-completer-1 [] { ["cites" "modified_date" "published_date" "shares" "views"] }
def status-completer [] { ["approved" "closed" "pending" "rejected"] }
def order-completer-2 [] { ["modified_date" "published_date" "views"] }
def storage-completer [] { ["group" "individual"] }
def role-name-completer [] { ["collaborator" "viewer"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    private-account: "record<active: int, created_date: string, email: string, first_name: string, group_id: int, id: int, institution_id: int, institution_user_id: string, last_name: string, maximum_file_size: int, modified_date: string, pending_quota_request: bool, quota: int, used_quota: int, used_quota_private: int, used_quota_public: int>"
    private-articles-list: "table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>"
    private-article-create: "record<entity_id: int, location: string, warnings: list<string>>"
    account-article-report: "table<account_id: int, created_date: string, download_url: string, group_id: int, id: int, status: string>"
    account-article-report-generate: "record<account_id: int, created_date: string, download_url: string, group_id: int, id: int, status: string>"
    private-articles-search: "table<project_id: int, defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>"
    private-article-details: "record<account_id: int, group_resource_id: string, authors: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>, custom_fields: table<is_mandatory: bool, name: string, value: string>, embargo_options: table<id: int, ip_name: string, type: string>, figshare_url: string, files: table<computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>, resource_doi: string, resource_title: string, categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, confidential_reason: string, created_date: string, description: string, embargo_date: string, embargo_reason: string, embargo_title: string, embargo_type: string, funding: string, funding_list: list<int>, has_linked_file: bool, is_active: bool, is_confidential: bool, is_embargoed: bool, is_metadata_record: bool, is_public: bool, license: record<name: string, url: string, value: int>, metadata_reason: string, modified_date: string, references: list<string>, size: int, status: string, tags: list<string>, version: int, defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>"
    private-article-update: "record<location: string, warnings: list<string>>"
    private-article-authors-list: "table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>"
    private-article-categories-list: "table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>"
    private-article-confidentiality-details: "record<is_confidential: bool, reason: string>"
    private-article-embargo-details: "record<embargo_date: string, embargo_options: list<record>, embargo_reason: string, embargo_title: string, embargo_type: string, is_embargoed: bool>"
    private-article-files-list: "table<is_attached_to_public_version: bool, preview_state: string, status: string, upload_token: string, upload_url: string, viewer_type: string, computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>"
    private-article-upload-initiate: "record<location: string>"
    private-article-file: "record<is_attached_to_public_version: bool, preview_state: string, status: string, upload_token: string, upload_url: string, viewer_type: string, computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>"
    private-article-private-link: "table<expires_date: string, html_location: string, id: string, is_active: bool>"
    private-article-private-link-create: "record<html_location: string, location: string, token: string>"
    private-article-publish: "record<location: string>"
    private-article-reserve-doi: "record<doi: string>"
    private-article-reserve-handle: "record<handle: string>"
    private-article-resource: "record<location: string>"
    article-version-update: "record<location: string, warnings: list<string>>"
    private-authors-search: "table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>"
    private-author-details: "record<first_name: string, group_id: int, institution_id: int, is_public: int, job_title: string, last_name: string, full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>"
    private-categories-list: "table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>"
    private-collections-list: "table<doi: string, handle: string, id: int, published_date: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string>"
    private-collection-create: "record<entity_id: int, location: string, warnings: list<string>>"
    private-collections-search: "table<doi: string, handle: string, id: int, published_date: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string>"
    private-collection-details: "record<account_id: int, articles_count: int, authors: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>, categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, created_date: string, custom_fields: table<is_mandatory: bool, name: string, value: string>, description: string, funding: table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string>, group_id: int, group_resource_id: string, institution_id: int, modified_date: string, public: bool, references: list<string>, resource_doi: string, resource_id: string, resource_link: string, resource_title: string, resource_version: int, tags: list<string>, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, version: int, doi: string, handle: string, id: int, published_date: string, title: string, url: string>"
    private-collection-update: "record<location: string, warnings: list<string>>"
    private-collection-articles-list: "table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>"
    private-collection-articles-add: "record<location: string>"
    private-collection-authors-list: "table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>"
    private-collection-authors-add: "record<location: string>"
    private-collection-categories-list: "table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>"
    private-collection-categories-add: "record<location: string>"
    private-collection-private-links-list: "table<expires_date: string, html_location: string, id: string, is_active: bool>"
    private-collection-private-link-create: "record<html_location: string, location: string, token: string>"
    private-collection-publish: "record<location: string>"
    private-collection-reserve-doi: "record<doi: string>"
    private-collection-reserve-handle: "record<handle: string>"
    private-collection-resource: "record<location: string>"
    private-funding-search: "table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string>"
    private-institution-details: "record<domain: string, id: int, name: string>"
    private-institution-accounts-list: "table<active: int, email: string, first_name: string, id: int, institution_id: int, institution_user_id: string, last_name: string, orcid_id: string, quota: int, used_quota: int, user_id: int>"
    private-institution-accounts-search: "table<active: int, email: string, first_name: string, id: int, institution_id: int, institution_user_id: string, last_name: string, orcid_id: string, quota: int, used_quota: int, user_id: int>"
    private-institution-articles: "table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>"
    custom-fields-list: "table<field_type: string, id: int, name: string>"
    custom-fields-upload: "record"
    private-institution-embargo-options-details: "table<id: int, ip_name: string, type: string>"
    private-institution-groups-list: "table<association_criteria: string, id: int, name: string, parent_id: int, resource_id: string>"
    private-group-embargo-options-details: "table<id: int, ip_name: string, type: string>"
    account-institution-curation: "record<item: record<authors: list<record>, custom_fields: list<record>, embargo_options: list<record>, figshare_url: string, files: list<record>, resource_doi: string, resource_title: string, categories: list<record>, citation: string, confidential_reason: string, created_date: string, description: string, embargo_date: string, embargo_reason: string, embargo_title: string, embargo_type: string, funding: string, funding_list: list<int>, has_linked_file: bool, is_active: bool, is_confidential: bool, is_embargoed: bool, is_metadata_record: bool, is_public: bool, license: record<name: string, url: string, value: int>, metadata_reason: string, modified_date: string, references: list<string>, size: int, status: string, tags: list<string>, version: int, defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>, account_id: int, article_id: int, assigned_to: int, comments_count: int, created_date: string, group_id: int, id: int, modified_date: string, review_date: string, status: string, version: int>"
    account-institution-curation-comments: "record<account_id: int, id: int, text: string, type: string>"
    account-institution-curations: "record<account_id: int, article_id: int, assigned_to: int, comments_count: int, created_date: string, group_id: int, id: int, modified_date: string, review_date: string, status: string, version: int>"
    private-institution-roles-list: "table<category: string, description: string, id: int, name: string>"
    private-institution-account-group-roles: "record"
    private-account-institution-user: "record<first_name: string, id: int, is_active: bool, is_public: bool, job_title: string, last_name: string, name: string, orcid_id: string, url_name: string>"
    private-licenses-list: "table<name: string, url: string, value: int>"
    private-projects-list: "table<role: string, storage: string, id: int, published_date: string, title: string, url: string>"
    private-project-create: "record<entity_id: int, location: string>"
    private-projects-search: "table<role: string, storage: string, id: int, published_date: string, title: string, url: string>"
    private-project-details: "record<account_id: int, collaborators: table<name: string, role_name: string, user_id: int>, created_date: string, custom_fields: table<is_mandatory: bool, name: string, value: string>, description: string, figshare_url: string, funding: string, funding_list: table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string>, group_id: int, modified_date: string, quota: int, used_quota: int, used_quota_private: int, used_quota_public: int, role: string, storage: string, id: int, published_date: string, title: string, url: string>"
    private-project-articles-list: "table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>"
    private-project-articles-create: "record<entity_id: int, location: string, warnings: list<string>>"
    private-project-article-details: "record<categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, confidential_reason: string, created_date: string, description: string, embargo_date: string, embargo_reason: string, embargo_title: string, embargo_type: string, funding: string, funding_list: list<int>, has_linked_file: bool, is_active: bool, is_confidential: bool, is_embargoed: bool, is_metadata_record: bool, is_public: bool, license: record<name: string, url: string, value: int>, metadata_reason: string, modified_date: string, references: list<string>, size: int, status: string, tags: list<string>, version: int, defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>"
    private-project-article-files: "table<is_attached_to_public_version: bool, preview_state: string, status: string, upload_token: string, upload_url: string, viewer_type: string, computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>"
    private-project-article-file: "record<is_attached_to_public_version: bool, preview_state: string, status: string, upload_token: string, upload_url: string, viewer_type: string, computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>"
    private-project-collaborators-list: "table<name: string, role_name: string, status: string, user_id: int>"
    private-project-collaborators-invite: "record<message: string>"
    private-project-notes-list: "table<abstract: string, created_date: string, id: int, modified_date: string, user_id: int, user_name: string>"
    private-project-notes-create: "record<location: string>"
    private-project-note: "record<text: string, abstract: string, created_date: string, id: int, modified_date: string, user_id: int, user_name: string>"
    private-project-publish: "record<message: string>"
    articles-list: "table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>"
    articles-search: "table<project_id: int, defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>"
    article-details: "record<authors: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>, custom_fields: table<is_mandatory: bool, name: string, value: string>, embargo_options: table<id: int, ip_name: string, type: string>, figshare_url: string, files: table<computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>, resource_doi: string, resource_title: string, categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, confidential_reason: string, created_date: string, description: string, embargo_date: string, embargo_reason: string, embargo_title: string, embargo_type: string, funding: string, funding_list: list<int>, has_linked_file: bool, is_active: bool, is_confidential: bool, is_embargoed: bool, is_metadata_record: bool, is_public: bool, license: record<name: string, url: string, value: int>, metadata_reason: string, modified_date: string, references: list<string>, size: int, status: string, tags: list<string>, version: int, defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>"
    article-files: "table<computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>"
    article-file-details: "record<computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>"
    article-versions: "table<url: string, version: int>"
    article-version-details: "record<authors: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>, custom_fields: table<is_mandatory: bool, name: string, value: string>, embargo_options: table<id: int, ip_name: string, type: string>, figshare_url: string, files: table<computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>, resource_doi: string, resource_title: string, categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, confidential_reason: string, created_date: string, description: string, embargo_date: string, embargo_reason: string, embargo_title: string, embargo_type: string, funding: string, funding_list: list<int>, has_linked_file: bool, is_active: bool, is_confidential: bool, is_embargoed: bool, is_metadata_record: bool, is_public: bool, license: record<name: string, url: string, value: int>, metadata_reason: string, modified_date: string, references: list<string>, size: int, status: string, tags: list<string>, version: int, defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>"
    article-version-confidentiality: "record<is_confidential: bool, reason: string>"
    article-version-embargo: "record<embargo_date: string, embargo_options: list<record>, embargo_reason: string, embargo_title: string, embargo_type: string, is_embargoed: bool>"
    categories-list: "table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>"
    collections-list: "table<doi: string, handle: string, id: int, published_date: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string>"
    collections-search: "table<doi: string, handle: string, id: int, published_date: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string>"
    collection-details: "record<articles_count: int, authors: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>, categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, created_date: string, custom_fields: table<is_mandatory: bool, name: string, value: string>, description: string, funding: table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string>, group_id: int, group_resource_id: string, institution_id: int, modified_date: string, public: bool, references: list<string>, resource_doi: string, resource_id: string, resource_link: string, resource_title: string, resource_version: int, tags: list<string>, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, version: int, doi: string, handle: string, id: int, published_date: string, title: string, url: string>"
    collection-articles: "table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>"
    collection-versions: "table<id: int, url: string>"
    collection-version-details: "record<articles_count: int, authors: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>, categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, created_date: string, custom_fields: table<is_mandatory: bool, name: string, value: string>, description: string, funding: table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string>, group_id: int, group_resource_id: string, institution_id: int, modified_date: string, public: bool, references: list<string>, resource_doi: string, resource_id: string, resource_link: string, resource_title: string, resource_version: int, tags: list<string>, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, version: int, doi: string, handle: string, id: int, published_date: string, title: string, url: string>"
    institution-hrfeed-upload: "record<message: string>"
    institution-articles: "table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>"
    item-types-list: "table<icon: string, id: int, is_selectable: bool, name: string, public_description: string, string_id: string, url_name: string>"
    licenses-list: "table<name: string, url: string, value: int>"
    projects-list: "table<id: int, published_date: string, title: string, url: string>"
    projects-search: "table<id: int, published_date: string, title: string, url: string>"
    project-details: "record<collaborators: table<name: string, role_name: string, user_id: int>, description: string, figshare_url: string, funding: string, funding_list: table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string>, id: int, published_date: string, title: string, url: string>"
    project-articles: "table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["private-account" "private-articles-list" "private-article-create" "account-article-report" "account-article-report-generate" "private-articles-search" "private-article-delete" "private-article-details" "private-article-update" "private-article-authors-list" "private-article-authors-add" "private-article-authors-replace" "private-article-author-delete" "private-article-categories-list" "private-article-categories-add" "private-article-categories-replace" "private-article-category-delete" "private-article-confidentiality-delete" "private-article-confidentiality-details" "private-article-confidentiality-update" "private-article-embargo-delete" "private-article-embargo-details" "private-article-embargo-update" "private-article-files-list" "private-article-upload-initiate" "private-article-file-delete" "private-article-file" "private-article-upload-complete" "private-article-private-link" "private-article-private-link-create" "private-article-private-link-delete" "private-article-private-link-update" "private-article-publish" "private-article-reserve-doi" "private-article-reserve-handle" "private-article-resource" "article-version-update" "article-version-update-thumb" "private-authors-search" "private-author-details" "private-categories-list" "private-collections-list" "private-collection-create" "private-collections-search" "private-collection-delete" "private-collection-details" "private-collection-update" "private-collection-articles-list" "private-collection-articles-add" "private-collection-articles-replace" "private-collection-article-delete" "private-collection-authors-list" "private-collection-authors-add" "private-collection-authors-replace" "private-collection-author-delete" "private-collection-categories-list" "private-collection-categories-add" "private-collection-categories-replace" "private-collection-category-delete" "private-collection-private-links-list" "private-collection-private-link-create" "private-collection-private-link-delete" "private-collection-private-link-update" "private-collection-publish" "private-collection-reserve-doi" "private-collection-reserve-handle" "private-collection-resource" "private-funding-search" "private-institution-details" "private-institution-accounts-list" "private-institution-accounts-create" "private-institution-accounts-search" "private-institution-accounts-update" "private-institution-articles" "custom-fields-list" "custom-fields-upload" "private-institution-embargo-options-details" "private-institution-groups-list" "private-group-embargo-options-details" "account-institution-curation" "account-institution-curation-comments" "post-account-institution-review-curation-id-comments" "account-institution-curations" "private-institution-roles-list" "private-institution-account-group-roles" "private-institution-account-group-roles-create" "private-institution-account-group-role-delete" "private-account-institution-user" "private-licenses-list" "private-projects-list" "private-project-create" "private-projects-search" "private-project-delete" "private-project-details" "private-project-update" "private-project-articles-list" "private-project-articles-create" "private-project-article-delete" "private-project-article-details" "private-project-article-files" "private-project-article-file" "private-project-collaborators-list" "private-project-collaborators-invite" "private-project-collaborator-delete" "private-project-leave" "private-project-notes-list" "private-project-notes-create" "private-project-note-delete" "private-project-note" "private-project-note-update" "private-project-publish" "articles-list" "articles-search" "article-details" "article-files" "article-file-details" "article-versions" "article-version-details" "article-version-confidentiality" "article-version-embargo" "categories-list" "collections-list" "collections-search" "collection-details" "collection-articles" "collection-versions" "collection-version-details" "file-download" "institution-hrfeed-upload" "institution-articles" "item-types-list" "licenses-list" "projects-list" "projects-search" "project-details" "project-articles" "commands"] | sort) } | get name | first)
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

# Private Account information
#
# GET /account
# Returns: record<active: int, created_date: string, email: string, first_name: string, group_id: int, id: int, institution_id: int, institution_user_id: string, last_name: string, maximum_file_size: int, modified_date: string, pending_quota_request: bool, quota: int, used_quota: int, used_quota_private: int, used_quota_public: int>
# operationId: private_account
export def "private-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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

# Private Articles
#
# GET /account/articles
# Returns: table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>
# operationId: private_articles_list
export def "private-articles-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/articles"
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new Article
#
# POST /account/articles
# Returns: record<entity_id: int, location: string, warnings: list<string>>
# operationId: private_article_create
export def "private-article-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authors: list # List of authors to be associated with the article. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (default: [], e.g. [{name: John Doe}, {id: 1000008}])
  --categories: list<int> # List of category ids to be associated with the article(e.g [1, 23, 33, 66]) (default: [], e.g. [1, 10, 11])
  --categories-by-source-id: list<string> # List of category source ids to be associated with the article, supersedes the categories property (default: [], e.g. [300204, 400207])
  --custom-fields: record # List of key, values pairs to be associated with the article (e.g. {defined_key: value for it})
  --custom-fields-list: list # List of custom fields values, supersedes custom_fields parameter — item shape: {name: string, value: any}
  --defined-type: string # One of: figure online resource preprint book conference contribution media dataset poster journal contribution presentation thesis software (e.g. media)
  --description: string # The article description. In a publisher case, usually this is the remote article description (default: "", e.g. Test description of article)
  --doi: string # Not applicable for regular users. In an institutional case, make sure your group supports setting DOIs. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: "")
  --funding: string # Grant number or funding authority (default: "")
  --funding-list: list # Funding creation / update items — item shape: {id?: int, title?: string}
  --group-id: int # Not applicable to regular users. This field is reserved to institutions/publishers with access to assign to specific groups (format: int64)
  --handle: string # Not applicable for regular users. In an institutional case, make sure your group supports setting Handles. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: "")
  --is-metadata-record: oneof<nothing, bool> # True if article has no files (e.g. true)
  --keywords: list<string> # List of tags to be associated with the article. Tags can be used instead (default: [], e.g. [tag1, tag2])
  --license: int # License id for this article. (format: int64, default: 0, e.g. 1)
  --metadata-reason: string # Article metadata reason (e.g. hosted somewhere else)
  --references: list<string> # List of links to be associated with the article (e.g ["http://link1", "http://link2", "http://link3"]) (default: [], e.g. [http://figshare.com, http://api.figshare.com])
  --resource-doi: string # Not applicable to regular users. In a publisher case, this is the publisher article DOI. (default: "")
  --resource-title: string # Not applicable to regular users. In a publisher case, this is the publisher article title. (default: "")
  --tags: list<string> # List of tags to be associated with the article. Keywords can be used instead (default: [], e.g. [tag1, tag2])
  --timeline: record # shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
  title: string # Title of article (e.g. Test article title)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/articles"
    body: {content_type: "application/json", kind: json, fields: [{name: authors, var: authors}, {name: categories, var: categories}, {name: categories_by_source_id, var: categories_by_source_id}, {name: custom_fields, var: custom_fields}, {name: custom_fields_list, var: custom_fields_list}, {name: defined_type, var: defined_type}, {name: description, var: description}, {name: doi, var: doi}, {name: funding, var: funding}, {name: funding_list, var: funding_list}, {name: group_id, var: group_id}, {name: handle, var: handle}, {name: is_metadata_record, var: is_metadata_record}, {name: keywords, var: keywords}, {name: license, var: license}, {name: metadata_reason, var: metadata_reason}, {name: references, var: references}, {name: resource_doi, var: resource_doi}, {name: resource_title, var: resource_title}, {name: tags, var: tags}, {name: timeline, var: timeline}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    authors: $authors, categories: $categories, categories_by_source_id: $categories_by_source_id, custom_fields: $custom_fields, custom_fields_list: $custom_fields_list, defined_type: $defined_type, description: $description, doi: $doi, funding: $funding, funding_list: $funding_list, group_id: $group_id, handle: $handle, is_metadata_record: $is_metadata_record, keywords: $keywords, license: $license, metadata_reason: $metadata_reason, references: $references, resource_doi: $resource_doi, resource_title: $resource_title, tags: $tags, timeline: $timeline, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Account Article Report
#
# GET /account/articles/export
# Returns: table<account_id: int, created_date: string, download_url: string, group_id: int, id: int, status: string>
# operationId: account_article_report
export def "account-article-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: int # A group ID to filter by (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/articles/export"
    query: [{name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiate a new Report
#
# POST /account/articles/export
# Returns: record<account_id: int, created_date: string, download_url: string, group_id: int, id: int, status: string>
# operationId: account_article_report_generate
export def "account-article-report-generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/articles/export"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Articles search
#
# POST /account/articles/search
# Returns: table<project_id: int, defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>
# operationId: private_articles_search
export def "private-articles-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-id: string # only return collections with this resource_id (e.g. 1407024)
  --doi: string # Only return articles with this doi (e.g. 10.6084/m9.figshare.1407024)
  --handle: string # Only return articles with this handle (e.g. 111084/m9.figshare.14074)
  --item-type: int # Only return articles with the respective type. Mapping for item_type is: 1 - Figure, 2 - Media, 3 - Dataset, 5 - Poster, 6 - Journal contribution, 7 - Presentation, 8 - Thesis, 9 - Software, 11 - Online resource, 12 - Preprint, 13 - Book, 14 - Conference contribution, 15 - Chapter, 16 - Peer review, 17 - Educational resource, 18 - Report, 19 - Standard, 20 - Composition, 21 - Funding, 22 - Physical object, 23 - Data management plan, 24 - Workflow, 25 - Monograph, 26 - Performance, 27 - Event, 28 - Service, 29 - Model (format: int64, e.g. 1)
  --order: string@order-completer # The field by which to order (default: created_date, e.g. published_date)
  --project-id: int # Only return articles in this project (format: int64, e.g. 1)
  --resource-doi: string # Only return articles with this resource_doi (e.g. 10.6084/m9.figshare.1407024)
  --group: int # only return collections from this group (format: int32, e.g. 2000013)
  --institution: int # only return collections from this institution (format: int32, e.g. 2000013)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64, e.g. 10)
  --modified-since: string # Filter by article modified date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64, e.g. 0)
  --order-direction: string@order-direction-completer # Direction of ordering (default: desc, e.g. desc)
  --page: int # Page number. Used for pagination with page_size (format: int64, e.g. 1)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10, e.g. 10)
  --published-since: string # Filter by article publishing date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --search-for: string # Search term (e.g. figshare)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/articles/search"
    body: {content_type: "application/json", kind: json, fields: [{name: resource_id, var: resource_id}, {name: doi, var: doi}, {name: handle, var: handle}, {name: item_type, var: item_type}, {name: order, var: order}, {name: project_id, var: project_id}, {name: resource_doi, var: resource_doi}, {name: group, var: group}, {name: institution, var: institution}, {name: limit, var: limit}, {name: modified_since, var: modified_since}, {name: offset, var: offset}, {name: order_direction, var: order_direction}, {name: page, var: page}, {name: page_size, var: page_size}, {name: published_since, var: published_since}, {name: search_for, var: search_for}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_id: $resource_id, doi: $doi, handle: $handle, item_type: $item_type, order: $order, project_id: $project_id, resource_doi: $resource_doi, group: $group, institution: $institution, limit: $limit, modified_since: $modified_since, offset: $offset, order_direction: $order_direction, page: $page, page_size: $page_size, published_since: $published_since, search_for: $search_for
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete article
#
# DELETE /account/articles/{article_id}
# operationId: private_article_delete
export def "private-article-delete" [
  article_id: int
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
    path: "/account/articles/{article_id}"
    path_params: [{name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Article details
#
# GET /account/articles/{article_id}
# Returns: record<account_id: int, group_resource_id: string, authors: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>, custom_fields: table<is_mandatory: bool, name: string, value: string>, embargo_options: table<id: int, ip_name: string, type: string>, figshare_url: string, files: table<computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>, resource_doi: string, resource_title: string, categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, confidential_reason: string, created_date: string, description: string, embargo_date: string, embargo_reason: string, embargo_title: string, embargo_type: string, funding: string, funding_list: list<int>, has_linked_file: bool, is_active: bool, is_confidential: bool, is_embargoed: bool, is_metadata_record: bool, is_public: bool, license: record<name: string, url: string, value: int>, metadata_reason: string, modified_date: string, references: list<string>, size: int, status: string, tags: list<string>, version: int, defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>
# operationId: private_article_details
export def "private-article-details" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/articles/{article_id}"
    path_params: [{name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update article
#
# PUT /account/articles/{article_id}
# Returns: record<location: string, warnings: list<string>>
# operationId: private_article_update
export def "private-article-update" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authors: list # List of authors to be associated with the article. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (default: [], e.g. [{name: John Doe}, {id: 1000008}])
  --categories: list<int> # List of category ids to be associated with the article(e.g [1, 23, 33, 66]) (default: [], e.g. [1, 10, 11])
  --categories-by-source-id: list<string> # List of category source ids to be associated with the article, supersedes the categories property (default: [], e.g. [300204, 400207])
  --custom-fields: record # List of key, values pairs to be associated with the article (e.g. {defined_key: value for it})
  --custom-fields-list: list # List of custom fields values, supersedes custom_fields parameter — item shape: {name: string, value: any}
  --defined-type: string # One of: figure online resource preprint book conference contribution media dataset poster journal contribution presentation thesis software (e.g. media)
  --description: string # The article description. In a publisher case, usually this is the remote article description (default: "", e.g. Test description of article)
  --doi: string # Not applicable for regular users. In an institutional case, make sure your group supports setting DOIs. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: "")
  --funding: string # Grant number or funding authority (default: "")
  --funding-list: list # Funding creation / update items — item shape: {id?: int, title?: string}
  --group-id: int # Not applicable to regular users. This field is reserved to institutions/publishers with access to assign to specific groups (format: int64)
  --handle: string # Not applicable for regular users. In an institutional case, make sure your group supports setting Handles. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: "")
  --is-metadata-record: oneof<nothing, bool> # True if article has no files (e.g. true)
  --keywords: list<string> # List of tags to be associated with the article. Tags can be used instead (default: [], e.g. [tag1, tag2])
  --license: int # License id for this article. (format: int64, default: 0, e.g. 1)
  --metadata-reason: string # Article metadata reason (e.g. hosted somewhere else)
  --references: list<string> # List of links to be associated with the article (e.g ["http://link1", "http://link2", "http://link3"]) (default: [], e.g. [http://figshare.com, http://api.figshare.com])
  --resource-doi: string # Not applicable to regular users. In a publisher case, this is the publisher article DOI. (default: "")
  --resource-title: string # Not applicable to regular users. In a publisher case, this is the publisher article title. (default: "")
  --tags: list<string> # List of tags to be associated with the article. Keywords can be used instead (default: [], e.g. [tag1, tag2])
  --timeline: record # shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
  --title: string # Title of article (e.g. Test article title)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/articles/{article_id}"
    path_params: [{name: article_id, var: article_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authors, var: authors}, {name: categories, var: categories}, {name: categories_by_source_id, var: categories_by_source_id}, {name: custom_fields, var: custom_fields}, {name: custom_fields_list, var: custom_fields_list}, {name: defined_type, var: defined_type}, {name: description, var: description}, {name: doi, var: doi}, {name: funding, var: funding}, {name: funding_list, var: funding_list}, {name: group_id, var: group_id}, {name: handle, var: handle}, {name: is_metadata_record, var: is_metadata_record}, {name: keywords, var: keywords}, {name: license, var: license}, {name: metadata_reason, var: metadata_reason}, {name: references, var: references}, {name: resource_doi, var: resource_doi}, {name: resource_title, var: resource_title}, {name: tags, var: tags}, {name: timeline, var: timeline}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    article_id: $article_id, authors: $authors, categories: $categories, categories_by_source_id: $categories_by_source_id, custom_fields: $custom_fields, custom_fields_list: $custom_fields_list, defined_type: $defined_type, description: $description, doi: $doi, funding: $funding, funding_list: $funding_list, group_id: $group_id, handle: $handle, is_metadata_record: $is_metadata_record, keywords: $keywords, license: $license, metadata_reason: $metadata_reason, references: $references, resource_doi: $resource_doi, resource_title: $resource_title, tags: $tags, timeline: $timeline, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List article authors
#
# GET /account/articles/{article_id}/authors
# Returns: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>
# operationId: private_article_authors_list
export def "private-article-authors-list" [
  article_id: int
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
    path: "/account/articles/{article_id}/authors"
    path_params: [{name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add article authors
#
# POST /account/articles/{article_id}/authors
# operationId: private_article_authors_add
export def "private-article-authors-add" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  authors: list # List of authors to be associated with the article. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (e.g. [{id: 12121}, {id: 34345}, {name: John Doe}])
]: any -> any {
  $in | http-request {
    method: post
    path: "/account/articles/{article_id}/authors"
    path_params: [{name: article_id, var: article_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authors, var: authors}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    article_id: $article_id, authors: $authors
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace article authors
#
# PUT /account/articles/{article_id}/authors
# operationId: private_article_authors_replace
export def "private-article-authors-replace" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  authors: list # List of authors to be associated with the article. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (e.g. [{id: 12121}, {id: 34345}, {name: John Doe}])
]: any -> any {
  $in | http-request {
    method: put
    path: "/account/articles/{article_id}/authors"
    path_params: [{name: article_id, var: article_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authors, var: authors}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    article_id: $article_id, authors: $authors
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete article author
#
# DELETE /account/articles/{article_id}/authors/{author_id}
# operationId: private_article_author_delete
export def "private-article-author-delete" [
  article_id: int
  author_id: int
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
    path: "/account/articles/{article_id}/authors/{author_id}"
    path_params: [{name: article_id, var: article_id}, {name: author_id, var: author_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    article_id: $article_id, author_id: $author_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List article categories
#
# GET /account/articles/{article_id}/categories
# Returns: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>
# operationId: private_article_categories_list
export def "private-article-categories-list" [
  article_id: int
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
    path: "/account/articles/{article_id}/categories"
    path_params: [{name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add article categories
#
# POST /account/articles/{article_id}/categories
# operationId: private_article_categories_add
export def "private-article-categories-add" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  categories: list<int> # List of category ids (e.g. [1, 10, 11])
]: any -> any {
  $in | http-request {
    method: post
    path: "/account/articles/{article_id}/categories"
    path_params: [{name: article_id, var: article_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    article_id: $article_id, categories: $categories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace article categories
#
# PUT /account/articles/{article_id}/categories
# operationId: private_article_categories_replace
export def "private-article-categories-replace" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  categories: list<int> # List of category ids (e.g. [1, 10, 11])
]: any -> any {
  $in | http-request {
    method: put
    path: "/account/articles/{article_id}/categories"
    path_params: [{name: article_id, var: article_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    article_id: $article_id, categories: $categories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete article category
#
# DELETE /account/articles/{article_id}/categories/{category_id}
# operationId: private_article_category_delete
export def "private-article-category-delete" [
  article_id: int
  category_id: int
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
    path: "/account/articles/{article_id}/categories/{category_id}"
    path_params: [{name: article_id, var: article_id}, {name: category_id, var: category_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    article_id: $article_id, category_id: $category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete article confidentiality
#
# DELETE /account/articles/{article_id}/confidentiality
# operationId: private_article_confidentiality_delete
export def "private-article-confidentiality-delete" [
  article_id: int
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
    path: "/account/articles/{article_id}/confidentiality"
    path_params: [{name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Article confidentiality details
#
# GET /account/articles/{article_id}/confidentiality
# Returns: record<is_confidential: bool, reason: string>
# operationId: private_article_confidentiality_details
export def "private-article-confidentiality-details" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/articles/{article_id}/confidentiality"
    path_params: [{name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update article confidentiality
#
# PUT /account/articles/{article_id}/confidentiality
# operationId: private_article_confidentiality_update
export def "private-article-confidentiality-update" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  reason: string # Reason for confidentiality
]: any -> any {
  $in | http-request {
    method: put
    path: "/account/articles/{article_id}/confidentiality"
    path_params: [{name: article_id, var: article_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    article_id: $article_id, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Article Embargo
#
# DELETE /account/articles/{article_id}/embargo
# operationId: private_article_embargo_delete
export def "private-article-embargo-delete" [
  article_id: int
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
    path: "/account/articles/{article_id}/embargo"
    path_params: [{name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Article Embargo Details
#
# GET /account/articles/{article_id}/embargo
# Returns: record<embargo_date: string, embargo_options: list<record>, embargo_reason: string, embargo_title: string, embargo_type: string, is_embargoed: bool>
# operationId: private_article_embargo_details
export def "private-article-embargo-details" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/articles/{article_id}/embargo"
    path_params: [{name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Article Embargo
#
# PUT /account/articles/{article_id}/embargo
# operationId: private_article_embargo_update
export def "private-article-embargo-update" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  embargo_date: string # Date when the embargo expires and the article gets published, '0' value will set up permanent embargo (e.g. 2018-05-22T04:04:04)
  --embargo-options: list # List of embargo permissions to be associated with the article. The list must contain `id` and can also contain `group_ids`(a field that only applies to 'logged_in' permissions). The new list replaces old options in the database, and an empty list removes all permissions for this article. Administration permission has to be set up alone but logged in and IP range permissions can be set up together. (e.g. [{id: 1321}, {id: 3345}, {group_ids: [4332, 5433, 678], id: 54621}])
  --embargo-reason: string # Reason for setting embargo (e.g. )
  --embargo-title: string # Title for embargo (e.g. File(s) under embargo)
  embargo_type: string@embargo-type-completer # Embargo can be enabled at the article or the file level. Possible values: article, file (e.g. file)
  --is-embargoed: oneof<nothing, bool> # Embargo status (e.g. true)
]: any -> any {
  $in | http-request {
    method: put
    path: "/account/articles/{article_id}/embargo"
    path_params: [{name: article_id, var: article_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: embargo_date, var: embargo_date}, {name: embargo_options, var: embargo_options}, {name: embargo_reason, var: embargo_reason}, {name: embargo_title, var: embargo_title}, {name: embargo_type, var: embargo_type}, {name: is_embargoed, var: is_embargoed, required: true}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    article_id: $article_id, embargo_date: $embargo_date, embargo_options: $embargo_options, embargo_reason: $embargo_reason, embargo_title: $embargo_title, embargo_type: $embargo_type, is_embargoed: $is_embargoed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List article files
#
# GET /account/articles/{article_id}/files
# Returns: table<is_attached_to_public_version: bool, preview_state: string, status: string, upload_token: string, upload_url: string, viewer_type: string, computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>
# operationId: private_article_files_list
export def "private-article-files-list" [
  article_id: int
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
    path: "/account/articles/{article_id}/files"
    path_params: [{name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiate Upload
#
# POST /account/articles/{article_id}/files
# Returns: record<location: string>
# operationId: private_article_upload_initiate
export def "private-article-upload-initiate" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --link: string # Url for an existing file that will not be uploaded to Figshare (e.g. http://figshare.com/file.txt)
  --md5: string # MD5 sum pre-computed on client side. (e.g. 6c16e6e7d7587bd078e5117dda01d565)
  --name: string # File name including the extension; can be omitted only for linked files. (e.g. test.py)
  --size: int # File size in bytes; can be omitted only for linked files. (format: int64, e.g. 70)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/articles/{article_id}/files"
    path_params: [{name: article_id, var: article_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: link, var: link}, {name: md5, var: md5}, {name: name, var: name}, {name: size, var: size}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    article_id: $article_id, link: $link, md5: $md5, name: $name, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# File Delete
#
# DELETE /account/articles/{article_id}/files/{file_id}
# operationId: private_article_file_delete
export def "private-article-file-delete" [
  article_id: int
  file_id: int
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
    path: "/account/articles/{article_id}/files/{file_id}"
    path_params: [{name: article_id, var: article_id}, {name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    article_id: $article_id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single File
#
# GET /account/articles/{article_id}/files/{file_id}
# Returns: record<is_attached_to_public_version: bool, preview_state: string, status: string, upload_token: string, upload_url: string, viewer_type: string, computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>
# operationId: private_article_file
export def "private-article-file" [
  article_id: int
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/articles/{article_id}/files/{file_id}"
    path_params: [{name: article_id, var: article_id}, {name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    article_id: $article_id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete Upload
#
# POST /account/articles/{article_id}/files/{file_id}
# operationId: private_article_upload_complete
export def "private-article-upload-complete" [
  article_id: int
  file_id: int
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
    method: post
    path: "/account/articles/{article_id}/files/{file_id}"
    path_params: [{name: article_id, var: article_id}, {name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    article_id: $article_id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List private links
#
# GET /account/articles/{article_id}/private_links
# Returns: table<expires_date: string, html_location: string, id: string, is_active: bool>
# operationId: private_article_private_link
export def "private-article-private-link" [
  article_id: int
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
    path: "/account/articles/{article_id}/private_links"
    path_params: [{name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create private link
#
# POST /account/articles/{article_id}/private_links
# Returns: record<html_location: string, location: string, token: string>
# operationId: private_article_private_link_create
export def "private-article-private-link-create" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expires-date: string # Date when this private link should expire - optional. By default private links expire in 365 days. (e.g. 2018-02-22 22:22:22)
  --read-only: oneof<nothing, bool> # Optional, default true. Set to false to give private link users editing rights for this collection. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/articles/{article_id}/private_links"
    path_params: [{name: article_id, var: article_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: expires_date, var: expires_date}, {name: read_only, var: read_only}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    article_id: $article_id, expires_date: $expires_date, read_only: $read_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable private link
#
# DELETE /account/articles/{article_id}/private_links/{link_id}
# operationId: private_article_private_link_delete
export def "private-article-private-link-delete" [
  article_id: int
  link_id: string
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
    path: "/account/articles/{article_id}/private_links/{link_id}"
    path_params: [{name: article_id, var: article_id}, {name: link_id, var: link_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    article_id: $article_id, link_id: $link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update private link
#
# PUT /account/articles/{article_id}/private_links/{link_id}
# operationId: private_article_private_link_update
export def "private-article-private-link-update" [
  article_id: int
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expires-date: string # Date when this private link should expire - optional. By default private links expire in 365 days. (e.g. 2018-02-22 22:22:22)
  --read-only: oneof<nothing, bool> # Optional, default true. Set to false to give private link users editing rights for this collection. (e.g. true)
]: any -> any {
  $in | http-request {
    method: put
    path: "/account/articles/{article_id}/private_links/{link_id}"
    path_params: [{name: article_id, var: article_id}, {name: link_id, var: link_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: expires_date, var: expires_date}, {name: read_only, var: read_only}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    article_id: $article_id, link_id: $link_id, expires_date: $expires_date, read_only: $read_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Article Publish
#
# POST /account/articles/{article_id}/publish
# Returns: record<location: string>
# operationId: private_article_publish
export def "private-article-publish" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/articles/{article_id}/publish"
    path_params: [{name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Article Reserve DOI
#
# POST /account/articles/{article_id}/reserve_doi
# Returns: record<doi: string>
# operationId: private_article_reserve_doi
export def "private-article-reserve-doi" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/articles/{article_id}/reserve_doi"
    path_params: [{name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Article Reserve Handle
#
# POST /account/articles/{article_id}/reserve_handle
# Returns: record<handle: string>
# operationId: private_article_reserve_handle
export def "private-article-reserve-handle" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/articles/{article_id}/reserve_handle"
    path_params: [{name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Article Resource
#
# POST /account/articles/{article_id}/resource
# Returns: record<location: string>
# operationId: private_article_resource
export def "private-article-resource" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --doi: string # DOI of resource item (default: "")
  --id: string # ID of resource item (default: "", e.g. aaaa23512)
  --link: string # Link of resource item (default: "", e.g. https://docs.figshare.com)
  --status: string # Status of resource item (default: "", e.g. frozen)
  --title: string # Title of resource item (default: "", e.g. Test title)
  --version: int # Version of resource item (format: int64, default: 0, e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/articles/{article_id}/resource"
    path_params: [{name: article_id, var: article_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: doi, var: doi}, {name: id, var: id}, {name: link, var: link}, {name: status, var: status}, {name: title, var: title}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    article_id: $article_id, doi: $doi, id: $id, link: $link, status: $status, title: $title, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update article version
#
# PUT /account/articles/{article_id}/versions/{version_id}/
# Returns: record<location: string, warnings: list<string>>
# operationId: article_version_update
export def "article-version-update" [
  article_id: int
  version_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authors: list # List of authors to be associated with the article. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (default: [], e.g. [{name: John Doe}, {id: 1000008}])
  --categories: list<int> # List of category ids to be associated with the article(e.g [1, 23, 33, 66]) (default: [], e.g. [1, 10, 11])
  --categories-by-source-id: list<string> # List of category source ids to be associated with the article, supersedes the categories property (default: [], e.g. [300204, 400207])
  --custom-fields: record # List of key, values pairs to be associated with the article (e.g. {defined_key: value for it})
  --custom-fields-list: list # List of custom fields values, supersedes custom_fields parameter — item shape: {name: string, value: any}
  --defined-type: string # One of: figure online resource preprint book conference contribution media dataset poster journal contribution presentation thesis software (e.g. media)
  --description: string # The article description. In a publisher case, usually this is the remote article description (default: "", e.g. Test description of article)
  --doi: string # Not applicable for regular users. In an institutional case, make sure your group supports setting DOIs. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: "")
  --funding: string # Grant number or funding authority (default: "")
  --funding-list: list # Funding creation / update items — item shape: {id?: int, title?: string}
  --group-id: int # Not applicable to regular users. This field is reserved to institutions/publishers with access to assign to specific groups (format: int64)
  --handle: string # Not applicable for regular users. In an institutional case, make sure your group supports setting Handles. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: "")
  --is-metadata-record: oneof<nothing, bool> # True if article has no files (e.g. true)
  --keywords: list<string> # List of tags to be associated with the article. Tags can be used instead (default: [], e.g. [tag1, tag2])
  --license: int # License id for this article. (format: int64, default: 0, e.g. 1)
  --metadata-reason: string # Article metadata reason (e.g. hosted somewhere else)
  --references: list<string> # List of links to be associated with the article (e.g ["http://link1", "http://link2", "http://link3"]) (default: [], e.g. [http://figshare.com, http://api.figshare.com])
  --resource-doi: string # Not applicable to regular users. In a publisher case, this is the publisher article DOI. (default: "")
  --resource-title: string # Not applicable to regular users. In a publisher case, this is the publisher article title. (default: "")
  --tags: list<string> # List of tags to be associated with the article. Keywords can be used instead (default: [], e.g. [tag1, tag2])
  --timeline: record # shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
  --title: string # Title of article (e.g. Test article title)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/articles/{article_id}/versions/{version_id}/"
    path_params: [{name: article_id, var: article_id}, {name: version_id, var: version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authors, var: authors}, {name: categories, var: categories}, {name: categories_by_source_id, var: categories_by_source_id}, {name: custom_fields, var: custom_fields}, {name: custom_fields_list, var: custom_fields_list}, {name: defined_type, var: defined_type}, {name: description, var: description}, {name: doi, var: doi}, {name: funding, var: funding}, {name: funding_list, var: funding_list}, {name: group_id, var: group_id}, {name: handle, var: handle}, {name: is_metadata_record, var: is_metadata_record}, {name: keywords, var: keywords}, {name: license, var: license}, {name: metadata_reason, var: metadata_reason}, {name: references, var: references}, {name: resource_doi, var: resource_doi}, {name: resource_title, var: resource_title}, {name: tags, var: tags}, {name: timeline, var: timeline}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    article_id: $article_id, version_id: $version_id, authors: $authors, categories: $categories, categories_by_source_id: $categories_by_source_id, custom_fields: $custom_fields, custom_fields_list: $custom_fields_list, defined_type: $defined_type, description: $description, doi: $doi, funding: $funding, funding_list: $funding_list, group_id: $group_id, handle: $handle, is_metadata_record: $is_metadata_record, keywords: $keywords, license: $license, metadata_reason: $metadata_reason, references: $references, resource_doi: $resource_doi, resource_title: $resource_title, tags: $tags, timeline: $timeline, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update article version thumbnail
#
# PUT /account/articles/{article_id}/versions/{version_id}/update_thumb
# operationId: article_version_update_thumb
export def "article-version-update-thumb" [
  article_id: int
  version_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-id: int # File ID (format: int64, e.g. 123)
]: any -> any {
  $in | http-request {
    method: put
    path: "/account/articles/{article_id}/versions/{version_id}/update_thumb"
    path_params: [{name: article_id, var: article_id}, {name: version_id, var: version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: file_id, var: file_id}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    article_id: $article_id, version_id: $version_id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search Authors
#
# POST /account/authors/search
# Returns: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>
# operationId: private_authors_search
export def "private-authors-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: int # Return only authors in this group or subgroups of the group (format: int64)
  --institution-id: int # Return only authors associated to this institution (format: int64, e.g. 1)
  --is-active: oneof<nothing, bool> # Return only active authors if True
  --is-public: oneof<nothing, bool> # Return only authors that have published items if True
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64, e.g. 10)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64, e.g. 0)
  --orcid: string # Orcid of author
  --order: string@order-completer # The field by which to order. Default varies by endpoint/resource. (default: published_date, e.g. published_date)
  --order-direction: string@order-direction-completer # Direction of ordering (default: desc, e.g. desc)
  --page: int # Page number. Used for pagination with page_size (format: int64, e.g. 1)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10, e.g. 10)
  --search-for: string # Search term (e.g. figshare)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/authors/search"
    body: {content_type: "application/json", kind: json, fields: [{name: group_id, var: group_id}, {name: institution_id, var: institution_id}, {name: is_active, var: is_active}, {name: is_public, var: is_public}, {name: limit, var: limit}, {name: offset, var: offset}, {name: orcid, var: orcid}, {name: order, var: order}, {name: order_direction, var: order_direction}, {name: page, var: page}, {name: page_size, var: page_size}, {name: search_for, var: search_for}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, institution_id: $institution_id, is_active: $is_active, is_public: $is_public, limit: $limit, offset: $offset, orcid: $orcid, order: $order, order_direction: $order_direction, page: $page, page_size: $page_size, search_for: $search_for
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Author details
#
# GET /account/authors/{author_id}
# Returns: record<first_name: string, group_id: int, institution_id: int, is_public: int, job_title: string, last_name: string, full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>
# operationId: private_author_details
export def "private-author-details" [
  author_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/authors/{author_id}"
    path_params: [{name: author_id, var: author_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    author_id: $author_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Account Categories
#
# GET /account/categories
# Returns: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>
# operationId: private_categories_list
export def "private-categories-list" [
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
    path: "/account/categories"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Collections List
#
# GET /account/collections
# Returns: table<doi: string, handle: string, id: int, published_date: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string>
# operationId: private_collections_list
export def "private-collections-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
  --order: string@order-completer-1 # The field by which to order. Default varies by endpoint/resource. (default: published_date)
  --order-direction: string@order-direction-completer # default: desc
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/collections"
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: limit, var: limit}, {name: offset, var: offset}, {name: order, var: order}, {name: order_direction, var: order_direction}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size, limit: $limit, offset: $offset, order: $order, order_direction: $order_direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create collection
#
# POST /account/collections
# Returns: record<entity_id: int, location: string, warnings: list<string>>
# operationId: private_collection_create
export def "private-collection-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --articles: list<int> # List of articles to be associated with the collection (e.g. [2000001, 2000005])
  --authors: list # List of authors to be associated with the collection. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (default: [], e.g. [{name: John Doe}, {id: 20005}])
  --categories: list<int> # List of category ids to be associated with the collection(e.g [1, 23, 33, 66]) (default: [], e.g. [1, 10, 11])
  --categories-by-source-id: list<string> # List of category source ids to be associated with the collection, supersedes the categories property (default: [], e.g. [300204, 400207])
  --custom-fields: record # List of key, values pairs to be associated with the collection (e.g. {defined_key: value for it})
  --custom-fields-list: list # List of custom fields values, supersedes custom_fields parameter — item shape: {name: string, value: any}
  --description: string # The collection description. In a publisher case, usually this is the remote collection description (default: "", e.g. Test description of article)
  --doi: string # Not applicable for regular users. In an institutional case, make sure your group supports setting DOIs. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: "")
  --funding: string # Grant number or funding authority (default: "")
  --funding-list: list # Funding creation / update items — item shape: {id?: int, title?: string}
  --group-id: int # Not applicable to regular users. This field is reserved to institutions/publishers with access to assign to specific groups (format: int64)
  --handle: string # Not applicable for regular users. In an institutional case, make sure your group supports setting Handles. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: "")
  --keywords: list<string> # List of tags to be associated with the collection. Tags can be used instead (default: [], e.g. [tag1, tag2])
  --references: list<string> # List of links to be associated with the collection (e.g ["http://link1", "http://link2", "http://link3"]) (default: [], e.g. [http://figshare.com, http://api.figshare.com])
  --resource-doi: string # Not applicable to regular users. In a publisher case, this is the publisher article DOI. (default: "")
  --resource-id: string # Not applicable to regular users. In a publisher case, this is the publisher article id
  --resource-link: string # Not applicable to regular users. In a publisher case, this is the publisher article link
  --resource-title: string # Not applicable to regular users. In a publisher case, this is the publisher article title. (default: "")
  --resource-version: int # Not applicable to regular users. In a publisher case, this is the publisher article version
  --tags: list<string> # List of tags to be associated with the collection. Keywords can be used instead (default: [], e.g. [tag1, tag2])
  --timeline: record # shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
  title: string # Title of collection (e.g. Test collection title)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/collections"
    body: {content_type: "application/json", kind: json, fields: [{name: articles, var: articles}, {name: authors, var: authors}, {name: categories, var: categories}, {name: categories_by_source_id, var: categories_by_source_id}, {name: custom_fields, var: custom_fields}, {name: custom_fields_list, var: custom_fields_list}, {name: description, var: description}, {name: doi, var: doi}, {name: funding, var: funding}, {name: funding_list, var: funding_list}, {name: group_id, var: group_id}, {name: handle, var: handle}, {name: keywords, var: keywords}, {name: references, var: references}, {name: resource_doi, var: resource_doi}, {name: resource_id, var: resource_id}, {name: resource_link, var: resource_link}, {name: resource_title, var: resource_title}, {name: resource_version, var: resource_version}, {name: tags, var: tags}, {name: timeline, var: timeline}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    articles: $articles, authors: $authors, categories: $categories, categories_by_source_id: $categories_by_source_id, custom_fields: $custom_fields, custom_fields_list: $custom_fields_list, description: $description, doi: $doi, funding: $funding, funding_list: $funding_list, group_id: $group_id, handle: $handle, keywords: $keywords, references: $references, resource_doi: $resource_doi, resource_id: $resource_id, resource_link: $resource_link, resource_title: $resource_title, resource_version: $resource_version, tags: $tags, timeline: $timeline, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Collections Search
#
# POST /account/collections/search
# Returns: table<doi: string, handle: string, id: int, published_date: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string>
# operationId: private_collections_search
export def "private-collections-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-id: string # only return collections with this resource_id (e.g. 1407024)
  --doi: string # Only return collections with this doi (e.g. 10.6084/m9.figshare.1407024)
  --handle: string # Only return collections with this handle (e.g. 10084/figshare.1407024)
  --order: string@order-completer-1 # The field by which to order. (default: created_date, e.g. published_date)
  --resource-doi: string # Only return collections with this resource_doi (e.g. 10.6084/m9.figshare.1407024)
  --group: int # only return collections from this group (format: int32, e.g. 2000013)
  --institution: int # only return collections from this institution (format: int32, e.g. 2000013)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64, e.g. 10)
  --modified-since: string # Filter by article modified date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64, e.g. 0)
  --order-direction: string@order-direction-completer # Direction of ordering (default: desc, e.g. desc)
  --page: int # Page number. Used for pagination with page_size (format: int64, e.g. 1)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10, e.g. 10)
  --published-since: string # Filter by article publishing date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --search-for: string # Search term (e.g. figshare)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/collections/search"
    body: {content_type: "application/json", kind: json, fields: [{name: resource_id, var: resource_id}, {name: doi, var: doi}, {name: handle, var: handle}, {name: order, var: order}, {name: resource_doi, var: resource_doi}, {name: group, var: group}, {name: institution, var: institution}, {name: limit, var: limit}, {name: modified_since, var: modified_since}, {name: offset, var: offset}, {name: order_direction, var: order_direction}, {name: page, var: page}, {name: page_size, var: page_size}, {name: published_since, var: published_since}, {name: search_for, var: search_for}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_id: $resource_id, doi: $doi, handle: $handle, order: $order, resource_doi: $resource_doi, group: $group, institution: $institution, limit: $limit, modified_since: $modified_since, offset: $offset, order_direction: $order_direction, page: $page, page_size: $page_size, published_since: $published_since, search_for: $search_for
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete collection
#
# DELETE /account/collections/{collection_id}
# operationId: private_collection_delete
export def "private-collection-delete" [
  collection_id: int
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
    path: "/account/collections/{collection_id}"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collection details
#
# GET /account/collections/{collection_id}
# Returns: record<account_id: int, articles_count: int, authors: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>, categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, created_date: string, custom_fields: table<is_mandatory: bool, name: string, value: string>, description: string, funding: table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string>, group_id: int, group_resource_id: string, institution_id: int, modified_date: string, public: bool, references: list<string>, resource_doi: string, resource_id: string, resource_link: string, resource_title: string, resource_version: int, tags: list<string>, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, version: int, doi: string, handle: string, id: int, published_date: string, title: string, url: string>
# operationId: private_collection_details
export def "private-collection-details" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/collections/{collection_id}"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update collection
#
# PUT /account/collections/{collection_id}
# Returns: record<location: string, warnings: list<string>>
# operationId: private_collection_update
export def "private-collection-update" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --articles: list<int> # List of articles to be associated with the collection (e.g. [2000001, 2000005])
  --authors: list # List of authors to be associated with the collection. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (default: [], e.g. [{name: John Doe}, {id: 20005}])
  --categories: list<int> # List of category ids to be associated with the collection (e.g [1, 23, 33, 66]) (default: [], e.g. [1, 10, 11])
  --categories-by-source-id: list<string> # List of category source ids to be associated with the article, supersedes the categories property (default: [], e.g. [300204, 400207])
  --custom-fields: record # List of key, values pairs to be associated with the collection (e.g. {defined_key: value for it})
  --custom-fields-list: list # List of custom fields values, supersedes custom_fields parameter — item shape: {name: string, value: any}
  --description: string # The collection description. In a publisher case, usually this is the remote collection description (default: "", e.g. Test description of collection)
  --doi: string # Not applicable for regular users. In an institutional case, make sure your group supports setting DOIs. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: "")
  --funding: string # Grant number or funding authority (default: "")
  --funding-list: list # Funding creation / update items — item shape: {id?: int, title?: string}
  --group-id: int # Not applicable to regular users. This field is reserved to institutions/publishers with access to assign to specific groups (format: int64)
  --handle: string # Not applicable for regular users. In an institutional case, make sure your group supports setting Handles. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: "")
  --keywords: list<string> # List of tags to be associated with the collection. Tags can be used instead (default: [], e.g. [tag1, tag2])
  --references: list<string> # List of links to be associated with the collection (e.g ["http://link1", "http://link2", "http://link3"]) (default: [], e.g. [http://figshare.com, http://api.figshare.com])
  --resource-doi: string # Not applicable to regular users. In a publisher case, this is the publisher article DOI. (default: "")
  --resource-id: string # Not applicable to regular users. In a publisher case, this is the publisher article id
  --resource-link: string # Not applicable to regular users. In a publisher case, this is the publisher article link
  --resource-title: string # Not applicable to regular users. In a publisher case, this is the publisher article title. (default: "")
  --resource-version: int # Not applicable to regular users. In a publisher case, this is the publisher article version
  --tags: list<string> # List of tags to be associated with the collection. Keywords can be used instead (default: [], e.g. [tag1, tag2])
  --timeline: record # shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
  --title: string # Title of collection (e.g. Test collection title)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/collections/{collection_id}"
    path_params: [{name: collection_id, var: collection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: articles, var: articles}, {name: authors, var: authors}, {name: categories, var: categories}, {name: categories_by_source_id, var: categories_by_source_id}, {name: custom_fields, var: custom_fields}, {name: custom_fields_list, var: custom_fields_list}, {name: description, var: description}, {name: doi, var: doi}, {name: funding, var: funding}, {name: funding_list, var: funding_list}, {name: group_id, var: group_id}, {name: handle, var: handle}, {name: keywords, var: keywords}, {name: references, var: references}, {name: resource_doi, var: resource_doi}, {name: resource_id, var: resource_id}, {name: resource_link, var: resource_link}, {name: resource_title, var: resource_title}, {name: resource_version, var: resource_version}, {name: tags, var: tags}, {name: timeline, var: timeline}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    collection_id: $collection_id, articles: $articles, authors: $authors, categories: $categories, categories_by_source_id: $categories_by_source_id, custom_fields: $custom_fields, custom_fields_list: $custom_fields_list, description: $description, doi: $doi, funding: $funding, funding_list: $funding_list, group_id: $group_id, handle: $handle, keywords: $keywords, references: $references, resource_doi: $resource_doi, resource_id: $resource_id, resource_link: $resource_link, resource_title: $resource_title, resource_version: $resource_version, tags: $tags, timeline: $timeline, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List collection articles
#
# GET /account/collections/{collection_id}/articles
# Returns: table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>
# operationId: private_collection_articles_list
export def "private-collection-articles-list" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/collections/{collection_id}/articles"
    path_params: [{name: collection_id, var: collection_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, page: $page, page_size: $page_size, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add collection articles
#
# POST /account/collections/{collection_id}/articles
# Returns: record<location: string>
# operationId: private_collection_articles_add
export def "private-collection-articles-add" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  articles: list<int> # List of article ids (e.g. [2000003, 2000004])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/collections/{collection_id}/articles"
    path_params: [{name: collection_id, var: collection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: articles, var: articles}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    collection_id: $collection_id, articles: $articles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace collection articles
#
# PUT /account/collections/{collection_id}/articles
# operationId: private_collection_articles_replace
export def "private-collection-articles-replace" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  articles: list<int> # List of article ids (e.g. [2000003, 2000004])
]: any -> any {
  $in | http-request {
    method: put
    path: "/account/collections/{collection_id}/articles"
    path_params: [{name: collection_id, var: collection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: articles, var: articles}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    collection_id: $collection_id, articles: $articles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete collection article
#
# DELETE /account/collections/{collection_id}/articles/{article_id}
# operationId: private_collection_article_delete
export def "private-collection-article-delete" [
  collection_id: int
  article_id: int
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
    path: "/account/collections/{collection_id}/articles/{article_id}"
    path_params: [{name: collection_id, var: collection_id}, {name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    collection_id: $collection_id, article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List collection authors
#
# GET /account/collections/{collection_id}/authors
# Returns: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>
# operationId: private_collection_authors_list
export def "private-collection-authors-list" [
  collection_id: int
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
    path: "/account/collections/{collection_id}/authors"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add collection authors
#
# POST /account/collections/{collection_id}/authors
# Returns: record<location: string>
# operationId: private_collection_authors_add
export def "private-collection-authors-add" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  authors: list # List of authors to be associated with the article. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (e.g. [{id: 12121}, {id: 34345}, {name: John Doe}])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/collections/{collection_id}/authors"
    path_params: [{name: collection_id, var: collection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authors, var: authors}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    collection_id: $collection_id, authors: $authors
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace collection authors
#
# PUT /account/collections/{collection_id}/authors
# operationId: private_collection_authors_replace
export def "private-collection-authors-replace" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  authors: list # List of authors to be associated with the article. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (e.g. [{id: 12121}, {id: 34345}, {name: John Doe}])
]: any -> any {
  $in | http-request {
    method: put
    path: "/account/collections/{collection_id}/authors"
    path_params: [{name: collection_id, var: collection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authors, var: authors}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    collection_id: $collection_id, authors: $authors
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete collection author
#
# DELETE /account/collections/{collection_id}/authors/{author_id}
# operationId: private_collection_author_delete
export def "private-collection-author-delete" [
  collection_id: int
  author_id: int
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
    path: "/account/collections/{collection_id}/authors/{author_id}"
    path_params: [{name: collection_id, var: collection_id}, {name: author_id, var: author_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    collection_id: $collection_id, author_id: $author_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List collection categories
#
# GET /account/collections/{collection_id}/categories
# Returns: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>
# operationId: private_collection_categories_list
export def "private-collection-categories-list" [
  collection_id: int
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
    path: "/account/collections/{collection_id}/categories"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add collection categories
#
# POST /account/collections/{collection_id}/categories
# Returns: record<location: string>
# operationId: private_collection_categories_add
export def "private-collection-categories-add" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  categories: list<int> # List of category ids (e.g. [1, 10, 11])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/collections/{collection_id}/categories"
    path_params: [{name: collection_id, var: collection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    collection_id: $collection_id, categories: $categories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace collection categories
#
# PUT /account/collections/{collection_id}/categories
# operationId: private_collection_categories_replace
export def "private-collection-categories-replace" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  categories: list<int> # List of category ids (e.g. [1, 10, 11])
]: any -> any {
  $in | http-request {
    method: put
    path: "/account/collections/{collection_id}/categories"
    path_params: [{name: collection_id, var: collection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    collection_id: $collection_id, categories: $categories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete collection category
#
# DELETE /account/collections/{collection_id}/categories/{category_id}
# operationId: private_collection_category_delete
export def "private-collection-category-delete" [
  collection_id: int
  category_id: int
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
    path: "/account/collections/{collection_id}/categories/{category_id}"
    path_params: [{name: collection_id, var: collection_id}, {name: category_id, var: category_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    collection_id: $collection_id, category_id: $category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List collection private links
#
# GET /account/collections/{collection_id}/private_links
# Returns: table<expires_date: string, html_location: string, id: string, is_active: bool>
# operationId: private_collection_private_links_list
export def "private-collection-private-links-list" [
  collection_id: int
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
    path: "/account/collections/{collection_id}/private_links"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create collection private link
#
# POST /account/collections/{collection_id}/private_links
# Returns: record<html_location: string, location: string, token: string>
# operationId: private_collection_private_link_create
export def "private-collection-private-link-create" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expires-date: string # Date when this private link should expire - optional. By default private links expire in 365 days. (e.g. 2018-02-22 22:22:22)
  --read-only: oneof<nothing, bool> # Optional, default true. Set to false to give private link users editing rights for this collection. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/collections/{collection_id}/private_links"
    path_params: [{name: collection_id, var: collection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: expires_date, var: expires_date}, {name: read_only, var: read_only}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    collection_id: $collection_id, expires_date: $expires_date, read_only: $read_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable private link
#
# DELETE /account/collections/{collection_id}/private_links/{link_id}
# operationId: private_collection_private_link_delete
export def "private-collection-private-link-delete" [
  collection_id: int
  link_id: string
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
    path: "/account/collections/{collection_id}/private_links/{link_id}"
    path_params: [{name: collection_id, var: collection_id}, {name: link_id, var: link_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    collection_id: $collection_id, link_id: $link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update collection private link
#
# PUT /account/collections/{collection_id}/private_links/{link_id}
# operationId: private_collection_private_link_update
export def "private-collection-private-link-update" [
  collection_id: int
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expires-date: string # Date when this private link should expire - optional. By default private links expire in 365 days. (e.g. 2018-02-22 22:22:22)
  --read-only: oneof<nothing, bool> # Optional, default true. Set to false to give private link users editing rights for this collection. (e.g. true)
]: any -> any {
  $in | http-request {
    method: put
    path: "/account/collections/{collection_id}/private_links/{link_id}"
    path_params: [{name: collection_id, var: collection_id}, {name: link_id, var: link_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: expires_date, var: expires_date}, {name: read_only, var: read_only}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    collection_id: $collection_id, link_id: $link_id, expires_date: $expires_date, read_only: $read_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Collection Publish
#
# POST /account/collections/{collection_id}/publish
# Returns: record<location: string>
# operationId: private_collection_publish
export def "private-collection-publish" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/collections/{collection_id}/publish"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Collection Reserve DOI
#
# POST /account/collections/{collection_id}/reserve_doi
# Returns: record<doi: string>
# operationId: private_collection_reserve_doi
export def "private-collection-reserve-doi" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/collections/{collection_id}/reserve_doi"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Collection Reserve Handle
#
# POST /account/collections/{collection_id}/reserve_handle
# Returns: record<handle: string>
# operationId: private_collection_reserve_handle
export def "private-collection-reserve-handle" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/collections/{collection_id}/reserve_handle"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Collection Resource
#
# POST /account/collections/{collection_id}/resource
# Returns: record<location: string>
# operationId: private_collection_resource
export def "private-collection-resource" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --doi: string # DOI of resource item (default: "")
  --id: string # ID of resource item (default: "", e.g. aaaa23512)
  --link: string # Link of resource item (default: "", e.g. https://docs.figshare.com)
  --status: string # Status of resource item (default: "", e.g. frozen)
  --title: string # Title of resource item (default: "", e.g. Test title)
  --version: int # Version of resource item (format: int64, default: 0, e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/collections/{collection_id}/resource"
    path_params: [{name: collection_id, var: collection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: doi, var: doi}, {name: id, var: id}, {name: link, var: link}, {name: status, var: status}, {name: title, var: title}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    collection_id: $collection_id, doi: $doi, id: $id, link: $link, status: $status, title: $title, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search Funding
#
# POST /account/funding/search
# Returns: table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string>
# operationId: private_funding_search
export def "private-funding-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-for: string # Search term
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/funding/search"
    body: {content_type: "application/json", kind: json, fields: [{name: search_for, var: search_for}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search_for: $search_for
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Account Institutions
#
# GET /account/institution
# Returns: record<domain: string, id: int, name: string>
# operationId: private_institution_details
export def "private-institution-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/institution"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Account Institution Accounts
#
# GET /account/institution/accounts
# Returns: table<active: int, email: string, first_name: string, id: int, institution_id: int, institution_user_id: string, last_name: string, orcid_id: string, quota: int, used_quota: int, user_id: int>
# operationId: private_institution_accounts_list
export def "private-institution-accounts-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
  --is-active: int # Filter by active status (format: int64)
  --institution-user-id: string # Filter by institution_user_id
  --email: string # Filter by email
  --id-lte: int # Retrieve accounts with an ID lower or equal to the specified value (format: int64)
  --id-gte: int # Retrieve accounts with an ID greater or equal to the specified value (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/institution/accounts"
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: limit, var: limit}, {name: offset, var: offset}, {name: is_active, var: is_active}, {name: institution_user_id, var: institution_user_id}, {name: email, var: email}, {name: id_lte, var: id_lte}, {name: id_gte, var: id_gte}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size, limit: $limit, offset: $offset, is_active: $is_active, institution_user_id: $institution_user_id, email: $email, id_lte: $id_lte, id_gte: $id_gte
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new Institution Account
#
# POST /account/institution/accounts
# operationId: private_institution_accounts_create
export def "private-institution-accounts-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # Email of account (e.g. johndoe@example.com)
  first_name: string # First Name (default: "", e.g. John)
  --group-id: int # Not applicable to regular users. This field is reserved to institutions/publishers with access to assign to specific groups (format: int64)
  --institution-user-id: string # Institution user id (default: "", e.g. johndoe)
  --is-active: oneof<nothing, bool> # Is account active
  --last-name: string # Last Name (default: "", e.g. Doe)
  --quota: int # Account quota (format: int64, e.g. 1000)
  --symplectic-user-id: string # Symplectic user id (default: "", e.g. johndoe)
]: any -> any {
  $in | http-request {
    method: post
    path: "/account/institution/accounts"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: first_name, var: first_name}, {name: group_id, var: group_id}, {name: institution_user_id, var: institution_user_id}, {name: is_active, var: is_active}, {name: last_name, var: last_name}, {name: quota, var: quota}, {name: symplectic_user_id, var: symplectic_user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    email: $email, first_name: $first_name, group_id: $group_id, institution_user_id: $institution_user_id, is_active: $is_active, last_name: $last_name, quota: $quota, symplectic_user_id: $symplectic_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Account Institution Accounts Search
#
# POST /account/institution/accounts/search
# Returns: table<active: int, email: string, first_name: string, id: int, institution_id: int, institution_user_id: string, last_name: string, orcid_id: string, quota: int, used_quota: int, user_id: int>
# operationId: private_institution_accounts_search
export def "private-institution-accounts-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # filter by email (e.g. alan@institution.com)
  --institution-user-id: string # filter by institution_user_id (e.g. alan)
  --is-active: int # Filter by active status (format: int64)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64, e.g. 10)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64, e.g. 0)
  --page: int # Page number. Used for pagination with page_size (format: int64, e.g. 1)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10, e.g. 10)
  --search-for: string # Search term (e.g. figshare)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/institution/accounts/search"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: institution_user_id, var: institution_user_id}, {name: is_active, var: is_active}, {name: limit, var: limit}, {name: offset, var: offset}, {name: page, var: page}, {name: page_size, var: page_size}, {name: search_for, var: search_for}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, institution_user_id: $institution_user_id, is_active: $is_active, limit: $limit, offset: $offset, page: $page, page_size: $page_size, search_for: $search_for
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Institution Account
#
# PUT /account/institution/accounts/{account_id}
# operationId: private_institution_accounts_update
export def "private-institution-accounts-update" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  group_id: int # Not applicable to regular users. This field is reserved to institutions/publishers with access to assign to specific groups (format: int64)
  --is-active: oneof<nothing, bool> # Is account active
]: any -> any {
  $in | http-request {
    method: put
    path: "/account/institution/accounts/{account_id}"
    path_params: [{name: account_id, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: group_id, var: group_id}, {name: is_active, var: is_active, required: true}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    account_id: $account_id, group_id: $group_id, is_active: $is_active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Institution Articles
#
# GET /account/institution/articles
# Returns: table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>
# operationId: private_institution_articles
export def "private-institution-articles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
  --order: string@order-completer # The field by which to order. Default varies by endpoint/resource. (default: published_date)
  --order-direction: string@order-direction-completer # default: desc
  --published-since: string # Filter by article publishing date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD
  --modified-since: string # Filter by article modified date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD
  --status: int # only return collections with this status (format: int64)
  --resource-doi: string # only return collections with this resource_doi
  --item-type: int # Only return articles with the respective type. Mapping for item_type is: 1 - Figure, 2 - Media, 3 - Dataset, 5 - Poster, 6 - Journal contribution, 7 - Presentation, 8 - Thesis, 9 - Software, 11 - Online resource, 12 - Preprint, 13 - Book, 14 - Conference contribution, 15 - Chapter, 16 - Peer review, 17 - Educational resource, 18 - Report, 19 - Standard, 20 - Composition, 21 - Funding, 22 - Physical object, 23 - Data management plan, 24 - Workflow, 25 - Monograph, 26 - Performance, 27 - Event, 28 - Service, 29 - Model (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/institution/articles"
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: limit, var: limit}, {name: offset, var: offset}, {name: order, var: order}, {name: order_direction, var: order_direction}, {name: published_since, var: published_since}, {name: modified_since, var: modified_since}, {name: status, var: status}, {name: resource_doi, var: resource_doi}, {name: item_type, var: item_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size, limit: $limit, offset: $offset, order: $order, order_direction: $order_direction, published_since: $published_since, modified_since: $modified_since, status: $status, resource_doi: $resource_doi, item_type: $item_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private account institution group custom fields
#
# GET /account/institution/custom_fields
# Returns: table<field_type: string, id: int, name: string>
# operationId: custom_fields_list
export def "custom-fields-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: int # Group_id (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/institution/custom_fields"
    query: [{name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Custom fields values files upload
#
# POST /account/institution/custom_fields/{custom_field_id}/items/upload
# Returns: record
# operationId: custom_fields_upload
export def "custom-fields-upload" [
  custom_field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-file: string # CSV file to be uploaded (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/institution/custom_fields/{custom_field_id}/items/upload"
    path_params: [{name: custom_field_id, var: custom_field_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: external_file, var: external_file}], files: [external_file]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    custom_field_id: $custom_field_id, external_file: $external_file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Account Institution embargo options
#
# GET /account/institution/embargo_options
# Returns: table<id: int, ip_name: string, type: string>
# operationId: private_institution_embargo_options_details
export def "private-institution-embargo-options-details" [
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
    path: "/account/institution/embargo_options"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Account Institution Groups
#
# GET /account/institution/groups
# Returns: table<association_criteria: string, id: int, name: string, parent_id: int, resource_id: string>
# operationId: private_institution_groups_list
export def "private-institution-groups-list" [
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
    path: "/account/institution/groups"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Account Institution Group Embargo Options
#
# GET /account/institution/groups/{group_id}/embargo_options
# Returns: table<id: int, ip_name: string, type: string>
# operationId: private_group_embargo_options_details
export def "private-group-embargo-options-details" [
  group_id: int
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
    path: "/account/institution/groups/{group_id}/embargo_options"
    path_params: [{name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Institution Curation Review
#
# GET /account/institution/review/{curation_id}
# Returns: record<item: record<authors: list<record>, custom_fields: list<record>, embargo_options: list<record>, figshare_url: string, files: list<record>, resource_doi: string, resource_title: string, categories: list<record>, citation: string, confidential_reason: string, created_date: string, description: string, embargo_date: string, embargo_reason: string, embargo_title: string, embargo_type: string, funding: string, funding_list: list<int>, has_linked_file: bool, is_active: bool, is_confidential: bool, is_embargoed: bool, is_metadata_record: bool, is_public: bool, license: record<name: string, url: string, value: int>, metadata_reason: string, modified_date: string, references: list<string>, size: int, status: string, tags: list<string>, version: int, defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>, account_id: int, article_id: int, assigned_to: int, comments_count: int, created_date: string, group_id: int, id: int, modified_date: string, review_date: string, status: string, version: int>
# operationId: account_institution_curation
export def "account-institution-curation" [
  curation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/institution/review/{curation_id}"
    path_params: [{name: curation_id, var: curation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    curation_id: $curation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Institution Curation Review Comments
#
# GET /account/institution/review/{curation_id}/comments
# Returns: record<account_id: int, id: int, text: string, type: string>
# operationId: account_institution_curation_comments
export def "account-institution-curation-comments" [
  curation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/institution/review/{curation_id}/comments"
    path_params: [{name: curation_id, var: curation_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    curation_id: $curation_id, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST Institution Curation Review Comment
#
# POST /account/institution/review/{curation_id}/comments
export def "post-account-institution-review-curation-id-comments" [
  curation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # The contents/value of the comment
]: any -> any {
  $in | http-request {
    method: post
    path: "/account/institution/review/{curation_id}/comments"
    path_params: [{name: curation_id, var: curation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    curation_id: $curation_id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Institution Curation Reviews
#
# GET /account/institution/reviews
# Returns: record<account_id: int, article_id: int, assigned_to: int, comments_count: int, created_date: string, group_id: int, id: int, modified_date: string, review_date: string, status: string, version: int>
# operationId: account_institution_curations
export def "account-institution-curations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: int # Filter by the group ID (format: int64)
  --article-id: int # Retrieve the reviews for this article (format: int64)
  --status: string@status-completer # Filter by the status of the review
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/institution/reviews"
    query: [{name: group_id, var: group_id}, {name: article_id, var: article_id}, {name: status, var: status}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, article_id: $article_id, status: $status, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Account Institution Roles
#
# GET /account/institution/roles
# Returns: table<category: string, description: string, id: int, name: string>
# operationId: private_institution_roles_list
export def "private-institution-roles-list" [
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
    path: "/account/institution/roles"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Institution Account Group Roles
#
# GET /account/institution/roles/{account_id}
# Returns: record
# operationId: private_institution_account_group_roles
export def "private-institution-account-group-roles" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/institution/roles/{account_id}"
    path_params: [{name: account_id, var: account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Institution Account Group Roles
#
# POST /account/institution/roles/{account_id}
# operationId: private_institution_account_group_roles_create
export def "private-institution-account-group-roles-create" [
  account_id: int
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
]: any -> any {
  $in | http-request {
    method: post
    path: "/account/institution/roles/{account_id}"
    path_params: [{name: account_id, var: account_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Institution Account Group Role
#
# DELETE /account/institution/roles/{account_id}/{group_id}/{role_id}
# operationId: private_institution_account_group_role_delete
export def "private-institution-account-group-role-delete" [
  account_id: int
  group_id: int
  role_id: int
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
    path: "/account/institution/roles/{account_id}/{group_id}/{role_id}"
    path_params: [{name: account_id, var: account_id}, {name: group_id, var: group_id}, {name: role_id, var: role_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, group_id: $group_id, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Account Institution User
#
# GET /account/institution/users/{account_id}
# Returns: record<first_name: string, id: int, is_active: bool, is_public: bool, job_title: string, last_name: string, name: string, orcid_id: string, url_name: string>
# operationId: private_account_institution_user
export def "private-account-institution-user" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/institution/users/{account_id}"
    path_params: [{name: account_id, var: account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Account Licenses
#
# GET /account/licenses
# Returns: table<name: string, url: string, value: int>
# operationId: private_licenses_list
export def "private-licenses-list" [
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
    path: "/account/licenses"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Projects
#
# GET /account/projects
# Returns: table<role: string, storage: string, id: int, published_date: string, title: string, url: string>
# operationId: private_projects_list
export def "private-projects-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
  --order: string@order-completer-2 # The field by which to order. (default: published_date)
  --order-direction: string@order-direction-completer # default: desc
  --storage: string@storage-completer # only return collections from this institution
  --roles: string # Any combination of owner, collaborator, viewer separated by comma. Examples: "owner" or "owner,collaborator".
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/projects"
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: limit, var: limit}, {name: offset, var: offset}, {name: order, var: order}, {name: order_direction, var: order_direction}, {name: storage, var: storage}, {name: roles, var: roles}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size, limit: $limit, offset: $offset, order: $order, order_direction: $order_direction, storage: $storage, roles: $roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create project
#
# POST /account/projects
# Returns: record<entity_id: int, location: string>
# operationId: private_project_create
export def "private-project-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # List of key, values pairs to be associated with the project (e.g. {defined_key: value for it})
  --custom-fields-list: list # List of custom fields values, supersedes custom_fields parameter — item shape: {name: string, value: any}
  --description: string # Project description (e.g. project description)
  --funding: string # Grant number or organization(s) that funded this project. Up to 2000 characters permitted. (e.g. )
  --funding-list: list # Funding creation / update items — item shape: {id?: int, title?: string}
  --group-id: int # Only if project type is group. (format: int64, e.g. 0)
  title: string # The title for this project - mandatory. 3 - 1000 characters. (e.g. project title)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/projects"
    body: {content_type: "application/json", kind: json, fields: [{name: custom_fields, var: custom_fields}, {name: custom_fields_list, var: custom_fields_list}, {name: description, var: description}, {name: funding, var: funding}, {name: funding_list, var: funding_list}, {name: group_id, var: group_id}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    custom_fields: $custom_fields, custom_fields_list: $custom_fields_list, description: $description, funding: $funding, funding_list: $funding_list, group_id: $group_id, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Projects search
#
# POST /account/projects/search
# Returns: table<role: string, storage: string, id: int, published_date: string, title: string, url: string>
# operationId: private_projects_search
export def "private-projects-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer-2 # The field by which to order. (default: published_date, e.g. published_date)
  --group: int # only return collections from this group (format: int32, e.g. 2000013)
  --institution: int # only return collections from this institution (format: int32, e.g. 2000013)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64, e.g. 10)
  --modified-since: string # Filter by article modified date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64, e.g. 0)
  --order-direction: string@order-direction-completer # Direction of ordering (default: desc, e.g. desc)
  --page: int # Page number. Used for pagination with page_size (format: int64, e.g. 1)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10, e.g. 10)
  --published-since: string # Filter by article publishing date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --search-for: string # Search term (e.g. figshare)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/projects/search"
    body: {content_type: "application/json", kind: json, fields: [{name: order, var: order}, {name: group, var: group}, {name: institution, var: institution}, {name: limit, var: limit}, {name: modified_since, var: modified_since}, {name: offset, var: offset}, {name: order_direction, var: order_direction}, {name: page, var: page}, {name: page_size, var: page_size}, {name: published_since, var: published_since}, {name: search_for, var: search_for}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order: $order, group: $group, institution: $institution, limit: $limit, modified_since: $modified_since, offset: $offset, order_direction: $order_direction, page: $page, page_size: $page_size, published_since: $published_since, search_for: $search_for
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete project
#
# DELETE /account/projects/{project_id}
# operationId: private_project_delete
export def "private-project-delete" [
  project_id: int
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
    path: "/account/projects/{project_id}"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View project details
#
# GET /account/projects/{project_id}
# Returns: record<account_id: int, collaborators: table<name: string, role_name: string, user_id: int>, created_date: string, custom_fields: table<is_mandatory: bool, name: string, value: string>, description: string, figshare_url: string, funding: string, funding_list: table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string>, group_id: int, modified_date: string, quota: int, used_quota: int, used_quota_private: int, used_quota_public: int, role: string, storage: string, id: int, published_date: string, title: string, url: string>
# operationId: private_project_details
export def "private-project-details" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/projects/{project_id}"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update project
#
# PUT /account/projects/{project_id}
# operationId: private_project_update
export def "private-project-update" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # List of key, values pairs to be associated with the project (e.g. {defined_key: value for it})
  --custom-fields-list: list # List of custom fields values, supersedes custom_fields parameter — item shape: {name: string, value: any}
  --description: string # Project description (e.g. project description)
  --funding: string # Grant number or organization(s) that funded this project. Up to 2000 characters permitted. (e.g. )
  --funding-list: list # Funding creation / update items — item shape: {id?: int, title?: string}
  --title: string # The title for this project - mandatory. 3 - 1000 characters. (e.g. project title)
]: any -> any {
  $in | http-request {
    method: put
    path: "/account/projects/{project_id}"
    path_params: [{name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_fields, var: custom_fields}, {name: custom_fields_list, var: custom_fields_list}, {name: description, var: description}, {name: funding, var: funding}, {name: funding_list, var: funding_list}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    project_id: $project_id, custom_fields: $custom_fields, custom_fields_list: $custom_fields_list, description: $description, funding: $funding, funding_list: $funding_list, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List project articles
#
# GET /account/projects/{project_id}/articles
# Returns: table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>
# operationId: private_project_articles_list
export def "private-project-articles-list" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/projects/{project_id}/articles"
    path_params: [{name: project_id, var: project_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, page: $page, page_size: $page_size, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create project article
#
# POST /account/projects/{project_id}/articles
# Returns: record<entity_id: int, location: string, warnings: list<string>>
# operationId: private_project_articles_create
export def "private-project-articles-create" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
  --authors: list # List of authors to be associated with the article. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (default: [], e.g. [{name: John Doe}, {id: 1000008}])
  --categories: list<int> # List of category ids to be associated with the article(e.g [1, 23, 33, 66]) (default: [], e.g. [1, 10, 11])
  --categories-by-source-id: list<string> # List of category source ids to be associated with the article, supersedes the categories property (default: [], e.g. [300204, 400207])
  --custom-fields: record # List of key, values pairs to be associated with the article (e.g. {defined_key: value for it})
  --custom-fields-list: list # List of custom fields values, supersedes custom_fields parameter — item shape: {name: string, value: any}
  --defined-type: string # One of: figure online resource preprint book conference contribution media dataset poster journal contribution presentation thesis software (e.g. media)
  --description: string # The article description. In a publisher case, usually this is the remote article description (default: "", e.g. Test description of article)
  --doi: string # Not applicable for regular users. In an institutional case, make sure your group supports setting DOIs. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: "")
  --funding: string # Grant number or funding authority (default: "")
  --funding-list: list # Funding creation / update items — item shape: {id?: int, title?: string}
  --handle: string # Not applicable for regular users. In an institutional case, make sure your group supports setting Handles. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: "")
  --keywords: list<string> # List of tags to be associated with the article. Tags can be used instead (default: [], e.g. [tag1, tag2])
  --license: int # License id for this article. (format: int64, default: 0, e.g. 1)
  --references: list<string> # List of links to be associated with the article (e.g ["http://link1", "http://link2", "http://link3"]) (default: [], e.g. [http://figshare.com, http://api.figshare.com])
  --resource-doi: string # Not applicable to regular users. In a publisher case, this is the publisher article DOI. (default: "")
  --resource-title: string # Not applicable to regular users. In a publisher case, this is the publisher article title. (default: "")
  --tags: list<string> # List of tags to be associated with the article. Keywords can be used instead (default: [], e.g. [tag1, tag2])
  --timeline: record # shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
  title: string # Title of article (e.g. Test article title)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/projects/{project_id}/articles"
    path_params: [{name: project_id, var: project_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: limit, var: limit}, {name: offset, var: offset}]
    body: {content_type: "application/json", kind: json, fields: [{name: authors, var: authors}, {name: categories, var: categories}, {name: categories_by_source_id, var: categories_by_source_id}, {name: custom_fields, var: custom_fields}, {name: custom_fields_list, var: custom_fields_list}, {name: defined_type, var: defined_type}, {name: description, var: description}, {name: doi, var: doi}, {name: funding, var: funding}, {name: funding_list, var: funding_list}, {name: handle, var: handle}, {name: keywords, var: keywords}, {name: license, var: license}, {name: references, var: references}, {name: resource_doi, var: resource_doi}, {name: resource_title, var: resource_title}, {name: tags, var: tags}, {name: timeline, var: timeline}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_id: $project_id, page: $page, page_size: $page_size, limit: $limit, offset: $offset, authors: $authors, categories: $categories, categories_by_source_id: $categories_by_source_id, custom_fields: $custom_fields, custom_fields_list: $custom_fields_list, defined_type: $defined_type, description: $description, doi: $doi, funding: $funding, funding_list: $funding_list, handle: $handle, keywords: $keywords, license: $license, references: $references, resource_doi: $resource_doi, resource_title: $resource_title, tags: $tags, timeline: $timeline, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete project article
#
# DELETE /account/projects/{project_id}/articles/{article_id}
# operationId: private_project_article_delete
export def "private-project-article-delete" [
  project_id: int
  article_id: int
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
    path: "/account/projects/{project_id}/articles/{article_id}"
    path_params: [{name: project_id, var: project_id}, {name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id, article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Project article details
#
# GET /account/projects/{project_id}/articles/{article_id}
# Returns: record<categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, confidential_reason: string, created_date: string, description: string, embargo_date: string, embargo_reason: string, embargo_title: string, embargo_type: string, funding: string, funding_list: list<int>, has_linked_file: bool, is_active: bool, is_confidential: bool, is_embargoed: bool, is_metadata_record: bool, is_public: bool, license: record<name: string, url: string, value: int>, metadata_reason: string, modified_date: string, references: list<string>, size: int, status: string, tags: list<string>, version: int, defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>
# operationId: private_project_article_details
export def "private-project-article-details" [
  project_id: int
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/projects/{project_id}/articles/{article_id}"
    path_params: [{name: project_id, var: project_id}, {name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Project article list files
#
# GET /account/projects/{project_id}/articles/{article_id}/files
# Returns: table<is_attached_to_public_version: bool, preview_state: string, status: string, upload_token: string, upload_url: string, viewer_type: string, computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>
# operationId: private_project_article_files
export def "private-project-article-files" [
  project_id: int
  article_id: int
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
    path: "/account/projects/{project_id}/articles/{article_id}/files"
    path_params: [{name: project_id, var: project_id}, {name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Project article file details
#
# GET /account/projects/{project_id}/articles/{article_id}/files/{file_id}
# Returns: record<is_attached_to_public_version: bool, preview_state: string, status: string, upload_token: string, upload_url: string, viewer_type: string, computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>
# operationId: private_project_article_file
export def "private-project-article-file" [
  project_id: int
  article_id: int
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/projects/{project_id}/articles/{article_id}/files/{file_id}"
    path_params: [{name: project_id, var: project_id}, {name: article_id, var: article_id}, {name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, article_id: $article_id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List project collaborators
#
# GET /account/projects/{project_id}/collaborators
# Returns: table<name: string, role_name: string, status: string, user_id: int>
# operationId: private_project_collaborators_list
export def "private-project-collaborators-list" [
  project_id: int
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
    path: "/account/projects/{project_id}/collaborators"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invite project collaborators
#
# POST /account/projects/{project_id}/collaborators
# Returns: record<message: string>
# operationId: private_project_collaborators_invite
export def "private-project-collaborators-invite" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # Text sent when inviting the user to the project (e.g. hey)
  --email: string # Collaborator email (e.g. user@domain.com)
  role_name: string@role-name-completer # Role of the the collaborator inside the project (e.g. viewer)
  --user-id: int # User id of the collaborator (format: int64, e.g. 100008)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/projects/{project_id}/collaborators"
    path_params: [{name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: email, var: email}, {name: role_name, var: role_name}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_id: $project_id, comment: $comment, email: $email, role_name: $role_name, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove project collaborator
#
# DELETE /account/projects/{project_id}/collaborators/{user_id}
# operationId: private_project_collaborator__Delete
export def "private-project-collaborator-delete" [
  project_id: int
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/account/projects/{project_id}/collaborators/{user_id}"
    path_params: [{name: project_id, var: project_id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Project Leave
#
# POST /account/projects/{project_id}/leave
# operationId: private_project_leave
export def "private-project-leave" [
  project_id: int
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
    method: post
    path: "/account/projects/{project_id}/leave"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List project notes
#
# GET /account/projects/{project_id}/notes
# Returns: table<abstract: string, created_date: string, id: int, modified_date: string, user_id: int, user_name: string>
# operationId: private_project_notes_list
export def "private-project-notes-list" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/projects/{project_id}/notes"
    path_params: [{name: project_id, var: project_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, page: $page, page_size: $page_size, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create project note
#
# POST /account/projects/{project_id}/notes
# Returns: record<location: string>
# operationId: private_project_notes_create
export def "private-project-notes-create" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # Text of the note (e.g. note to remember)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/projects/{project_id}/notes"
    path_params: [{name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_id: $project_id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete project note
#
# DELETE /account/projects/{project_id}/notes/{note_id}
# operationId: private_project_note_delete
export def "private-project-note-delete" [
  project_id: int
  note_id: int
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
    path: "/account/projects/{project_id}/notes/{note_id}"
    path_params: [{name: project_id, var: project_id}, {name: note_id, var: note_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id, note_id: $note_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Project note details
#
# GET /account/projects/{project_id}/notes/{note_id}
# Returns: record<text: string, abstract: string, created_date: string, id: int, modified_date: string, user_id: int, user_name: string>
# operationId: private_project_note
export def "private-project-note" [
  project_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/projects/{project_id}/notes/{note_id}"
    path_params: [{name: project_id, var: project_id}, {name: note_id, var: note_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, note_id: $note_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update project note
#
# PUT /account/projects/{project_id}/notes/{note_id}
# operationId: private_project_note_update
export def "private-project-note-update" [
  project_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # Text of the note (e.g. note to remember)
]: any -> any {
  $in | http-request {
    method: put
    path: "/account/projects/{project_id}/notes/{note_id}"
    path_params: [{name: project_id, var: project_id}, {name: note_id, var: note_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/json"]
    ok: [205]
    auth: bearer
  } {
    project_id: $project_id, note_id: $note_id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Project Publish
#
# POST /account/projects/{project_id}/publish
# Returns: record<message: string>
# operationId: private_project_publish
export def "private-project-publish" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/account/projects/{project_id}/publish"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Public Articles
#
# GET /articles
# Returns: table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>
# operationId: articles_list
export def "articles-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
  --order: string@order-completer # The field by which to order. Default varies by endpoint/resource. (default: published_date)
  --order-direction: string@order-direction-completer # default: desc
  --institution: int # only return articles from this institution (format: int64)
  --published-since: string # Filter by article publishing date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD
  --modified-since: string # Filter by article modified date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD
  --group: int # only return articles from this group (format: int64)
  --resource-doi: string # only return articles with this resource_doi
  --item-type: int # Only return articles with the respective type. Mapping for item_type is: 1 - Figure, 2 - Media, 3 - Dataset, 5 - Poster, 6 - Journal contribution, 7 - Presentation, 8 - Thesis, 9 - Software, 11 - Online resource, 12 - Preprint, 13 - Book, 14 - Conference contribution, 15 - Chapter, 16 - Peer review, 17 - Educational resource, 18 - Report, 19 - Standard, 20 - Composition, 21 - Funding, 22 - Physical object, 23 - Data management plan, 24 - Workflow, 25 - Monograph, 26 - Performance, 27 - Event, 28 - Service, 29 - Model (format: int64)
  --doi: string # only return articles with this doi
  --handle: string # only return articles with this handle
  --x-cursor: string # Unique hash used for bypassing the item retrieval limit of 9,000 entities. When using this parameter, please note that the offset parameter will not be available, but the limit parameter will still work as expected. (format: uuid)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/articles"
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: limit, var: limit}, {name: offset, var: offset}, {name: order, var: order}, {name: order_direction, var: order_direction}, {name: institution, var: institution}, {name: published_since, var: published_since}, {name: modified_since, var: modified_since}, {name: group, var: group}, {name: resource_doi, var: resource_doi}, {name: item_type, var: item_type}, {name: doi, var: doi}, {name: handle, var: handle}]
    header: [{name: X-Cursor, var: x_cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    page: $page, page_size: $page_size, limit: $limit, offset: $offset, order: $order, order_direction: $order_direction, institution: $institution, published_since: $published_since, modified_since: $modified_since, group: $group, resource_doi: $resource_doi, item_type: $item_type, doi: $doi, handle: $handle, x_cursor: $x_cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Public Articles Search
#
# POST /articles/search
# Returns: table<project_id: int, defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>
# operationId: articles_search
export def "articles-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-cursor: string # Unique hash used for bypassing the item retrieval limit of 9,000 entities. When using this parameter, please note that the offset parameter will not be available, but the limit parameter will still work as expected. (format: uuid)
  --doi: string # Only return articles with this doi (e.g. 10.6084/m9.figshare.1407024)
  --handle: string # Only return articles with this handle (e.g. 111084/m9.figshare.14074)
  --item-type: int # Only return articles with the respective type. Mapping for item_type is: 1 - Figure, 2 - Media, 3 - Dataset, 5 - Poster, 6 - Journal contribution, 7 - Presentation, 8 - Thesis, 9 - Software, 11 - Online resource, 12 - Preprint, 13 - Book, 14 - Conference contribution, 15 - Chapter, 16 - Peer review, 17 - Educational resource, 18 - Report, 19 - Standard, 20 - Composition, 21 - Funding, 22 - Physical object, 23 - Data management plan, 24 - Workflow, 25 - Monograph, 26 - Performance, 27 - Event, 28 - Service, 29 - Model (format: int64, e.g. 1)
  --order: string@order-completer # The field by which to order (default: created_date, e.g. published_date)
  --project-id: int # Only return articles in this project (format: int64, e.g. 1)
  --resource-doi: string # Only return articles with this resource_doi (e.g. 10.6084/m9.figshare.1407024)
  --group: int # only return collections from this group (format: int32, e.g. 2000013)
  --institution: int # only return collections from this institution (format: int32, e.g. 2000013)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64, e.g. 10)
  --modified-since: string # Filter by article modified date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64, e.g. 0)
  --order-direction: string@order-direction-completer # Direction of ordering (default: desc, e.g. desc)
  --page: int # Page number. Used for pagination with page_size (format: int64, e.g. 1)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10, e.g. 10)
  --published-since: string # Filter by article publishing date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --search-for: string # Search term (e.g. figshare)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/articles/search"
    header: [{name: X-Cursor, var: x_cursor}]
    body: {content_type: "application/json", kind: json, fields: [{name: doi, var: doi}, {name: handle, var: handle}, {name: item_type, var: item_type}, {name: order, var: order}, {name: project_id, var: project_id}, {name: resource_doi, var: resource_doi}, {name: group, var: group}, {name: institution, var: institution}, {name: limit, var: limit}, {name: modified_since, var: modified_since}, {name: offset, var: offset}, {name: order_direction, var: order_direction}, {name: page, var: page}, {name: page_size, var: page_size}, {name: published_since, var: published_since}, {name: search_for, var: search_for}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    x_cursor: $x_cursor, doi: $doi, handle: $handle, item_type: $item_type, order: $order, project_id: $project_id, resource_doi: $resource_doi, group: $group, institution: $institution, limit: $limit, modified_since: $modified_since, offset: $offset, order_direction: $order_direction, page: $page, page_size: $page_size, published_since: $published_since, search_for: $search_for
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View article details
#
# GET /articles/{article_id}
# Returns: record<authors: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>, custom_fields: table<is_mandatory: bool, name: string, value: string>, embargo_options: table<id: int, ip_name: string, type: string>, figshare_url: string, files: table<computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>, resource_doi: string, resource_title: string, categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, confidential_reason: string, created_date: string, description: string, embargo_date: string, embargo_reason: string, embargo_title: string, embargo_type: string, funding: string, funding_list: list<int>, has_linked_file: bool, is_active: bool, is_confidential: bool, is_embargoed: bool, is_metadata_record: bool, is_public: bool, license: record<name: string, url: string, value: int>, metadata_reason: string, modified_date: string, references: list<string>, size: int, status: string, tags: list<string>, version: int, defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>
# operationId: article_details
export def "article-details" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/articles/{article_id}"
    path_params: [{name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List article files
#
# GET /articles/{article_id}/files
# Returns: table<computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>
# operationId: article_files
export def "article-files" [
  article_id: int
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
    path: "/articles/{article_id}/files"
    path_params: [{name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Article file details
#
# GET /articles/{article_id}/files/{file_id}
# Returns: record<computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>
# operationId: article_file_details
export def "article-file-details" [
  article_id: int
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/articles/{article_id}/files/{file_id}"
    path_params: [{name: article_id, var: article_id}, {name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    article_id: $article_id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List article versions
#
# GET /articles/{article_id}/versions
# Returns: table<url: string, version: int>
# operationId: article_versions
export def "article-versions" [
  article_id: int
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
    path: "/articles/{article_id}/versions"
    path_params: [{name: article_id, var: article_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Article details for version
#
# GET /articles/{article_id}/versions/{v_number}
# Returns: record<authors: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>, custom_fields: table<is_mandatory: bool, name: string, value: string>, embargo_options: table<id: int, ip_name: string, type: string>, figshare_url: string, files: table<computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>, resource_doi: string, resource_title: string, categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, confidential_reason: string, created_date: string, description: string, embargo_date: string, embargo_reason: string, embargo_title: string, embargo_type: string, funding: string, funding_list: list<int>, has_linked_file: bool, is_active: bool, is_confidential: bool, is_embargoed: bool, is_metadata_record: bool, is_public: bool, license: record<name: string, url: string, value: int>, metadata_reason: string, modified_date: string, references: list<string>, size: int, status: string, tags: list<string>, version: int, defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>
# operationId: article_version_details
export def "article-version-details" [
  article_id: int
  v_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/articles/{article_id}/versions/{v_number}"
    path_params: [{name: article_id, var: article_id}, {name: v_number, var: v_number}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    article_id: $article_id, v_number: $v_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Public Article Confidentiality for article version
#
# GET /articles/{article_id}/versions/{v_number}/confidentiality
# Returns: record<is_confidential: bool, reason: string>
# operationId: article_version_confidentiality
export def "article-version-confidentiality" [
  article_id: int
  v_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/articles/{article_id}/versions/{v_number}/confidentiality"
    path_params: [{name: article_id, var: article_id}, {name: v_number, var: v_number}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    article_id: $article_id, v_number: $v_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Public Article Embargo for article version
#
# GET /articles/{article_id}/versions/{v_number}/embargo
# Returns: record<embargo_date: string, embargo_options: list<record>, embargo_reason: string, embargo_title: string, embargo_type: string, is_embargoed: bool>
# operationId: article_version_embargo
export def "article-version-embargo" [
  article_id: int
  v_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/articles/{article_id}/versions/{v_number}/embargo"
    path_params: [{name: article_id, var: article_id}, {name: v_number, var: v_number}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    article_id: $article_id, v_number: $v_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Public Categories
#
# GET /categories
# Returns: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>
# operationId: categories_list
export def "categories-list" [
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
    path: "/categories"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Public Collections
#
# GET /collections
# Returns: table<doi: string, handle: string, id: int, published_date: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string>
# operationId: collections_list
export def "collections-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
  --order: string@order-completer-1 # The field by which to order. Default varies by endpoint/resource. (default: published_date)
  --order-direction: string@order-direction-completer # default: desc
  --institution: int # only return collections from this institution (format: int64)
  --published-since: string # Filter by collection publishing date. Will only return collections published after the date. date(ISO 8601) YYYY-MM-DD
  --modified-since: string # Filter by collection modified date. Will only return collections published after the date. date(ISO 8601) YYYY-MM-DD
  --group: int # only return collections from this group (format: int64)
  --resource-doi: string # only return collections with this resource_doi
  --doi: string # only return collections with this doi
  --handle: string # only return collections with this handle
  --x-cursor: string # Unique hash used for bypassing the item retrieval limit of 9,000 entities. When using this parameter, please note that the offset parameter will not be available, but the limit parameter will still work as expected. (format: uuid)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/collections"
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: limit, var: limit}, {name: offset, var: offset}, {name: order, var: order}, {name: order_direction, var: order_direction}, {name: institution, var: institution}, {name: published_since, var: published_since}, {name: modified_since, var: modified_since}, {name: group, var: group}, {name: resource_doi, var: resource_doi}, {name: doi, var: doi}, {name: handle, var: handle}]
    header: [{name: X-Cursor, var: x_cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    page: $page, page_size: $page_size, limit: $limit, offset: $offset, order: $order, order_direction: $order_direction, institution: $institution, published_since: $published_since, modified_since: $modified_since, group: $group, resource_doi: $resource_doi, doi: $doi, handle: $handle, x_cursor: $x_cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Public Collections Search
#
# POST /collections/search
# Returns: table<doi: string, handle: string, id: int, published_date: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string>
# operationId: collections_search
export def "collections-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-cursor: string # Unique hash used for bypassing the item retrieval limit of 9,000 entities. When using this parameter, please note that the offset parameter will not be available, but the limit parameter will still work as expected. (format: uuid)
  --doi: string # Only return collections with this doi (e.g. 10.6084/m9.figshare.1407024)
  --handle: string # Only return collections with this handle (e.g. 10084/figshare.1407024)
  --order: string@order-completer-1 # The field by which to order. (default: created_date, e.g. published_date)
  --resource-doi: string # Only return collections with this resource_doi (e.g. 10.6084/m9.figshare.1407024)
  --group: int # only return collections from this group (format: int32, e.g. 2000013)
  --institution: int # only return collections from this institution (format: int32, e.g. 2000013)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64, e.g. 10)
  --modified-since: string # Filter by article modified date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64, e.g. 0)
  --order-direction: string@order-direction-completer # Direction of ordering (default: desc, e.g. desc)
  --page: int # Page number. Used for pagination with page_size (format: int64, e.g. 1)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10, e.g. 10)
  --published-since: string # Filter by article publishing date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --search-for: string # Search term (e.g. figshare)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/collections/search"
    header: [{name: X-Cursor, var: x_cursor}]
    body: {content_type: "application/json", kind: json, fields: [{name: doi, var: doi}, {name: handle, var: handle}, {name: order, var: order}, {name: resource_doi, var: resource_doi}, {name: group, var: group}, {name: institution, var: institution}, {name: limit, var: limit}, {name: modified_since, var: modified_since}, {name: offset, var: offset}, {name: order_direction, var: order_direction}, {name: page, var: page}, {name: page_size, var: page_size}, {name: published_since, var: published_since}, {name: search_for, var: search_for}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    x_cursor: $x_cursor, doi: $doi, handle: $handle, order: $order, resource_doi: $resource_doi, group: $group, institution: $institution, limit: $limit, modified_since: $modified_since, offset: $offset, order_direction: $order_direction, page: $page, page_size: $page_size, published_since: $published_since, search_for: $search_for
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collection details
#
# GET /collections/{collection_id}
# Returns: record<articles_count: int, authors: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>, categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, created_date: string, custom_fields: table<is_mandatory: bool, name: string, value: string>, description: string, funding: table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string>, group_id: int, group_resource_id: string, institution_id: int, modified_date: string, public: bool, references: list<string>, resource_doi: string, resource_id: string, resource_link: string, resource_title: string, resource_version: int, tags: list<string>, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, version: int, doi: string, handle: string, id: int, published_date: string, title: string, url: string>
# operationId: collection_details
export def "collection-details" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/collections/{collection_id}"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Public Collection Articles
#
# GET /collections/{collection_id}/articles
# Returns: table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>
# operationId: collection_articles
export def "collection-articles" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/collections/{collection_id}/articles"
    path_params: [{name: collection_id, var: collection_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    collection_id: $collection_id, page: $page, page_size: $page_size, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collection Versions list
#
# GET /collections/{collection_id}/versions
# Returns: table<id: int, url: string>
# operationId: collection_versions
export def "collection-versions" [
  collection_id: int
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
    path: "/collections/{collection_id}/versions"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collection Version details
#
# GET /collections/{collection_id}/versions/{version_id}
# Returns: record<articles_count: int, authors: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>, categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, created_date: string, custom_fields: table<is_mandatory: bool, name: string, value: string>, description: string, funding: table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string>, group_id: int, group_resource_id: string, institution_id: int, modified_date: string, public: bool, references: list<string>, resource_doi: string, resource_id: string, resource_link: string, resource_title: string, resource_version: int, tags: list<string>, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, version: int, doi: string, handle: string, id: int, published_date: string, title: string, url: string>
# operationId: collection_version_details
export def "collection-version-details" [
  collection_id: int
  version_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/collections/{collection_id}/versions/{version_id}"
    path_params: [{name: collection_id, var: collection_id}, {name: version_id, var: version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    collection_id: $collection_id, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Public File Download
#
# GET /file/download/{file_id}
# operationId: file_download
export def "file-download" [
  file_id: int
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
    path: "/file/download/{file_id}"
    path_params: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Private Institution HRfeed Upload
#
# POST /institution/hrfeed/upload
# Returns: record<message: string>
# operationId: institution_hrfeed_upload
export def "institution-hrfeed-upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hrfeed: string # You can find an example in the Hr Feed section (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/institution/hrfeed/upload"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: hrfeed, var: hrfeed}], files: [hrfeed]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hrfeed: $hrfeed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Public Licenses
#
# GET /institutions/{institution_string_id}/articles/filter-by
# Returns: table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>
# operationId: institution_articles
export def "institution-articles" [
  institution_string_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-id: string # required
  --filename: string # required
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/institutions/{institution_string_id}/articles/filter-by"
    path_params: [{name: institution_string_id, var: institution_string_id}]
    query: [{name: resource_id, var: resource_id, required: true}, {name: filename, var: filename, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    institution_string_id: $institution_string_id, resource_id: $resource_id, filename: $filename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Item Types
#
# GET /item_types
# Returns: table<icon: string, id: int, is_selectable: bool, name: string, public_description: string, string_id: string, url_name: string>
# operationId: item_types_list
export def "item-types-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: int # Identifier of the group for which the item types are requested (format: int64, default: 0)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/item_types"
    query: [{name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Public Licenses
#
# GET /licenses
# Returns: table<name: string, url: string, value: int>
# operationId: licenses_list
export def "licenses-list" [
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
    path: "/licenses"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Public Projects
#
# GET /projects
# Returns: table<id: int, published_date: string, title: string, url: string>
# operationId: projects_list
export def "projects-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
  --order: string@order-completer-2 # The field by which to order. Default varies by endpoint/resource. (default: published_date)
  --order-direction: string@order-direction-completer # default: desc
  --institution: int # only return collections from this institution (format: int64)
  --published-since: string # Filter by article publishing date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD
  --group: int # only return collections from this group (format: int64)
  --x-cursor: string # Unique hash used for bypassing the item retrieval limit of 9,000 entities. When using this parameter, please note that the offset parameter will not be available, but the limit parameter will still work as expected. (format: uuid)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/projects"
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: limit, var: limit}, {name: offset, var: offset}, {name: order, var: order}, {name: order_direction, var: order_direction}, {name: institution, var: institution}, {name: published_since, var: published_since}, {name: group, var: group}]
    header: [{name: X-Cursor, var: x_cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    page: $page, page_size: $page_size, limit: $limit, offset: $offset, order: $order, order_direction: $order_direction, institution: $institution, published_since: $published_since, group: $group, x_cursor: $x_cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Public Projects Search
#
# POST /projects/search
# Returns: table<id: int, published_date: string, title: string, url: string>
# operationId: projects_search
export def "projects-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-cursor: string # Unique hash used for bypassing the item retrieval limit of 9,000 entities. When using this parameter, please note that the offset parameter will not be available, but the limit parameter will still work as expected. (format: uuid)
  --order: string@order-completer-2 # The field by which to order. (default: published_date, e.g. published_date)
  --group: int # only return collections from this group (format: int32, e.g. 2000013)
  --institution: int # only return collections from this institution (format: int32, e.g. 2000013)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64, e.g. 10)
  --modified-since: string # Filter by article modified date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64, e.g. 0)
  --order-direction: string@order-direction-completer # Direction of ordering (default: desc, e.g. desc)
  --page: int # Page number. Used for pagination with page_size (format: int64, e.g. 1)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10, e.g. 10)
  --published-since: string # Filter by article publishing date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --search-for: string # Search term (e.g. figshare)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/search"
    header: [{name: X-Cursor, var: x_cursor}]
    body: {content_type: "application/json", kind: json, fields: [{name: order, var: order}, {name: group, var: group}, {name: institution, var: institution}, {name: limit, var: limit}, {name: modified_since, var: modified_since}, {name: offset, var: offset}, {name: order_direction, var: order_direction}, {name: page, var: page}, {name: page_size, var: page_size}, {name: published_since, var: published_since}, {name: search_for, var: search_for}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    x_cursor: $x_cursor, order: $order, group: $group, institution: $institution, limit: $limit, modified_since: $modified_since, offset: $offset, order_direction: $order_direction, page: $page, page_size: $page_size, published_since: $published_since, search_for: $search_for
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Public Project
#
# GET /projects/{project_id}
# Returns: record<collaborators: table<name: string, role_name: string, user_id: int>, description: string, figshare_url: string, funding: string, funding_list: table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string>, id: int, published_date: string, title: string, url: string>
# operationId: project_details
export def "project-details" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/projects/{project_id}"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Public Project Articles
#
# GET /projects/{project_id}/articles
# Returns: table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string, firstOnline: string, publisherAcceptance: string, publisherPublication: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string>
# operationId: project_articles
export def "project-articles" [
  project_id: int
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
    path: "/projects/{project_id}/articles"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
