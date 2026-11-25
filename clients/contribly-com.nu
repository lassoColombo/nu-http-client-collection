# Auto-generated client for Contribly v1.0.0
# Source: https://api.apis.guru/v2/specs/contribly.com/1.0.0/openapi.json
# Auth: --token flag or $env.CONTRIBLY_TOKEN

const CLIENT = {
  base_url: "https://api.contribly.com/1"
  token_env_var: "CONTRIBLY_TOKEN"
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

def base-url-completer [] { ["https://api.contribly.com/1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-artifact-formats: "record<contribution: table<contentType: string, fileExtension: string, forContentType: string, label: string, preserveAspectRatio: bool, public: bool, upscaleAllowed: bool>, cover: table<contentType: string, fileExtension: string, forContentType: string, label: string, preserveAspectRatio: bool, public: bool, upscaleAllowed: bool>, profileImage: table<contentType: string, fileExtension: string, forContentType: string, label: string, preserveAspectRatio: bool, public: bool, upscaleAllowed: bool>>"
    get-assignments: "table<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list, id: string, media: record>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: list<record>, urlWords: string, webUrl: string>"
    post-assignments: "record<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list<record>, id: string, media: record<duration: float, id: string, place: record, type: string>>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: table<colour: string, id: string, name: string, tagSet: record, urlWords: string>, urlWords: string, webUrl: string>"
    get-assignments-id: "record<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list<record>, id: string, media: record<duration: float, id: string, place: record, type: string>>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: table<colour: string, id: string, name: string, tagSet: record, urlWords: string>, urlWords: string, webUrl: string>"
    get-change-log: "table<date: string, description: string, title: string>"
    get-contribution-refinement-types: "list<string>"
    get-contribution-refinements: "record"
    get-contributions: "table<assignment: record<allowsAnonymousContributions: bool, callToAction: string, cover: record, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: list, urlWords: string, webUrl: string>, attribution: string, body: string, created: string, headline: string, id: string, mediaUsages: list<record>, moderationHistory: list<record>, place: record<country: string, geohash: string, google: string, latLong: record, name: string, osm: record>, urlWords: string, via: record<authority: record, ipAddress: string, ipAddressPlace: record>>"
    post-contributions: "record<assignment: record<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list, id: string, media: record>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: list<record>, urlWords: string, webUrl: string>, attribution: string, body: string, created: string, headline: string, id: string, mediaUsages: table<artifacts: list, id: string, media: record>, moderationHistory: table<action: record, date: string, notes: string>, place: record<country: string, geohash: string, google: string, latLong: record<latitude: float, longitude: float>, name: string, osm: record<osmId: float, osmType: string>>, urlWords: string, via: record<authority: record<client: record, id: string, user: record>, ipAddress: string, ipAddressPlace: record<country: string, geohash: string, google: string, latLong: record, name: string, osm: record>>>"
    delete-contributions-id: "record<assignment: record<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list, id: string, media: record>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: list<record>, urlWords: string, webUrl: string>, attribution: string, body: string, created: string, headline: string, id: string, mediaUsages: table<artifacts: list, id: string, media: record>, moderationHistory: table<action: record, date: string, notes: string>, place: record<country: string, geohash: string, google: string, latLong: record<latitude: float, longitude: float>, name: string, osm: record<osmId: float, osmType: string>>, urlWords: string, via: record<authority: record<client: record, id: string, user: record>, ipAddress: string, ipAddressPlace: record<country: string, geohash: string, google: string, latLong: record, name: string, osm: record>>>"
    get-contributions-id: "record<assignment: record<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list, id: string, media: record>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: list<record>, urlWords: string, webUrl: string>, attribution: string, body: string, created: string, headline: string, id: string, mediaUsages: table<artifacts: list, id: string, media: record>, moderationHistory: table<action: record, date: string, notes: string>, place: record<country: string, geohash: string, google: string, latLong: record<latitude: float, longitude: float>, name: string, osm: record<osmId: float, osmType: string>>, urlWords: string, via: record<authority: record<client: record, id: string, user: record>, ipAddress: string, ipAddressPlace: record<country: string, geohash: string, google: string, latLong: record, name: string, osm: record>>>"
    post-contributions-id-flag: "record<date: string, email: string, id: string, notes: string, type: string>"
    post-contributions-id-like: "float"
    get-contributions-id-likes: "list<string>"
    post-contributions-id-moderate: "string"
    get-credentials: "table<scopes: list<string>, type: string, user: string, value: string>"
    get-event-types: "table<id: string, name: string>"
    post-export: "record<downloadUrl: string, finished: string, id: string, owner: string, progress: float, started: string, step: string>"
    post-export-summary: "record<contributions: float, estimatedSize: string, media: float, totalMediaSize: float>"
    get-exports-id: "record<downloadUrl: string, finished: string, id: string, owner: string, progress: float, started: string, step: string>"
    get-form-responses: "table<contribution: string, date: string, form: string, id: string, responses: record, user: string>"
    post-form-responses: "record<contribution: string, date: string, form: string, id: string, responses: record, user: string>"
    get-form-responses-id: "record<contribution: string, date: string, form: string, id: string, responses: record, user: string>"
    get-forms: "table<callToAction: string, cssUrl: string, fields: list<record>, heading: string, id: string, name: string, noCss: bool, ownedBy: string, tags: list<record>>"
    post-forms: "record<callToAction: string, cssUrl: string, fields: table<description: string, label: string, name: string, options: list, public: bool, required: bool, type: string>, heading: string, id: string, name: string, noCss: bool, ownedBy: string, tags: table<colour: string, id: string, name: string, tagSet: record, urlWords: string>>"
    get-forms-id: "record<callToAction: string, cssUrl: string, fields: table<description: string, label: string, name: string, options: list, public: bool, required: bool, type: string>, heading: string, id: string, name: string, noCss: bool, ownedBy: string, tags: table<colour: string, id: string, name: string, tagSet: record, urlWords: string>>"
    post-media: "record<duration: float, id: string, place: record<country: string, geohash: string, google: string, latLong: record<latitude: float, longitude: float>, name: string, osm: record<osmId: float, osmType: string>>, type: string>"
    get-notifications-contributions-id-preview: "record<email: string, html: string, subject: string>"
    get-scopes: "list<string>"
    get-subscription-types: "table<id: string, name: string>"
    get-subscriptions: "table<assignment: string, email: string, id: string, includeBody: bool, includeThumbenail: bool, slackChannel: string, token: string, types: list<string>, user: string>"
    get-tags: "table<colour: string, id: string, name: string, tagSet: record<id: string, name: string>, urlWords: string>"
    post-tags: "record<colour: string, id: string, name: string, tagSet: record<id: string, name: string>, urlWords: string>"
    get-tags-id: "record<colour: string, id: string, name: string, tagSet: record<id: string, name: string>, urlWords: string>"
    get-tagsets: "table<id: string, name: string>"
    post-tagsets: "record<id: string, name: string>"
    get-tagsets-id: "record<id: string, name: string>"
    get-users: "table<bio: string, displayName: string, id: string, registered: string, username: string>"
    get-users-id: "record<bio: string, displayName: string, id: string, registered: string, username: string>"
    get-users-id-linked-type: "record<bio: string, email: string, id: string, name: string, picture: string, profile: string, registered: string>"
    post-verify: "record<client: record<id: string, name: string>, id: string, user: record<bio: string, displayName: string, id: string, registered: string, username: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-artifact-formats" "get-assignments" "post-assignments" "delete-assignments-id" "get-assignments-id" "get-change-log" "get-contribution-refinement-types" "get-contribution-refinements" "get-contributions" "post-contributions" "delete-contributions-id" "get-contributions-id" "post-contributions-id-flag" "post-contributions-id-like" "get-contributions-id-likes" "post-contributions-id-moderate" "get-credentials" "get-event-types" "post-export" "post-export-summary" "get-exports-id" "get-form-responses" "post-form-responses" "get-form-responses-id" "get-forms" "post-forms" "delete-forms-id" "get-forms-id" "post-media" "get-notifications-contributions-id-preview" "get-scopes" "get-subscription-types" "get-subscriptions" "delete-subscriptions-id" "get-tags" "post-tags" "get-tags-id" "get-tagsets" "post-tagsets" "get-tagsets-id" "get-users" "get-users-id" "get-users-id-linked-type" "post-verify" "commands"] | sort) } | get name | first)
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

# Artifact formats
#
# GET /artifact-formats
# Returns: record<contribution: table<contentType: string, fileExtension: string, forContentType: string, label: string, preserveAspectRatio: bool, public: bool, upscaleAllowed: bool>, cover: table<contentType: string, fileExtension: string, forContentType: string, label: string, preserveAspectRatio: bool, public: bool, upscaleAllowed: bool>, profileImage: table<contentType: string, fileExtension: string, forContentType: string, label: string, preserveAspectRatio: bool, public: bool, upscaleAllowed: bool>>
export def "get-artifact-formats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/artifact-formats"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List assignments
#
# GET /assignments
# Returns: table<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list, id: string, media: record>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: list<record>, urlWords: string, webUrl: string>
export def "get-assignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owned-by: string # Restrict results to assignments owned by this user.
  --page: int # Pagination page
  --page-size: int # Pagination page size
  --q: string # Restrict results to assignments whose name or description matches this keyword.
  --url-words: string # Select an assignment by urlWords.
  --open: oneof<nothing, bool> # Select open or closed assignments
  --always-open: oneof<nothing, bool> # Select assignments with no closing date.
  --tag: string # Restrict results to assignments which are tagged with this tag.
  --name: string # Restrict results to the assignment (or potentially assignments) with this exact name
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/assignments"
    query: [{name: ownedBy, var: owned_by}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: q, var: q}, {name: urlWords, var: url_words}, {name: open, var: open}, {name: alwaysOpen, var: always_open}, {name: tag, var: tag}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owned_by: $owned_by, page: $page, page_size: $page_size, q: $q, url_words: $url_words, open: $open, always_open: $always_open, tag: $tag, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new assignment
#
# POST /assignments
# Returns: record<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list<record>, id: string, media: record<duration: float, id: string, place: record, type: string>>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: table<colour: string, id: string, name: string, tagSet: record, urlWords: string>, urlWords: string, webUrl: string>
export def "post-assignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allows-anonymous-contributions: oneof<nothing, bool>
  --cover: record # shape: {artifacts?: list, id?: string, media?: record}
  --description: string
  --embargo: string # format: date-time
  --ends: string # format: date-time
  --featured: oneof<nothing, bool>
  --id: string
  --media-required: oneof<nothing, bool>
  --moderator: string # Optional credential id of the login which will moderator this assignment.
  name: string
  --receipt-message: string # An optional assignment specific message to be displayed on successful contribution submission. For example, this might be used to inform contributors of assignment specific moderation time frames.
  --starts: string # format: date-time
  --tags: list # item shape: {colour?: string, id: string, name: string, tagSet?: record, urlWords?: string}
  --url-words: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assignments"
    body: {content_type: "application/json", kind: json, fields: [{name: allowsAnonymousContributions, var: allows_anonymous_contributions}, {name: cover, var: cover}, {name: description, var: description}, {name: embargo, var: embargo}, {name: ends, var: ends}, {name: featured, var: featured}, {name: id, var: id}, {name: mediaRequired, var: media_required}, {name: moderator, var: moderator}, {name: name, var: name}, {name: receiptMessage, var: receipt_message}, {name: starts, var: starts}, {name: tags, var: tags}, {name: urlWords, var: url_words}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allows_anonymous_contributions: $allows_anonymous_contributions, cover: $cover, description: $description, embargo: $embargo, ends: $ends, featured: $featured, id: $id, media_required: $media_required, moderator: $moderator, name: $name, receipt_message: $receipt_message, starts: $starts, tags: $tags, url_words: $url_words
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete this assignment and all of it's contributions
#
# DELETE /assignments/{id}
export def "delete-assignments-id" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/assignments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single assigment by id
#
# GET /assignments/{id}
# Returns: record<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list<record>, id: string, media: record<duration: float, id: string, place: record, type: string>>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: table<colour: string, id: string, name: string, tagSet: record, urlWords: string>, urlWords: string, webUrl: string>
export def "get-assignments-id" [
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
    path: "/assignments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recent changes
#
# GET /change-log
# Returns: table<date: string, description: string, title: string>
export def "get-change-log" [
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
    path: "/change-log"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List valid contribution refinement types
#
# GET /contribution-refinement-types
# Returns: list<string>
export def "get-contribution-refinement-types" [
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
    path: "/contribution-refinement-types"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List contribution refinement options
#
# GET /contribution-refinements
# Returns: record
export def "get-contribution-refinements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignment: string # Restrict results to contributions submitted to this assignment.
  --country: string # Limit results to contributions which have a publicly visible location within the given country (specified by two letter country code).
  --created-before: string # Limit results to contributions created before this date time. (format: date-time)
  --created-after: string # Limit results to contributions created after this date time. (format: date-time)
  --geohash: string # Restrict results to contributions which have specified a location which falls within this geohash (or comma seperated list of multiple geohashes)
  --has-location: oneof<nothing, bool> # Restrict results to contributions which have a publicly visible location.
  --lat-long: string # Limit results to contributions with location near this latitude and longitude (comma seperated lat/long pair). Also see radius
  --radius: float # When limiting result by location with the latLong parameter, specify the radius in kilometers. (format: double)
  --media-type: string # Restrict results to contributions which include a media file of the given type (ie. image / video)
  --owned-by: string # Restrict results to contributions which are fall under the jurisdiction by this user.
  --q: string # Restrict results to contributions whose headline text matches this keyword.
  --url-words: string # Locate a specific contribution by URL words
  --user: string # Restrict results to contributions by this user identified by id.
  --refinements: string # Comma seperated list of refinement names.
  --refinement-size: float # Number of refinement options to return.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contribution-refinements"
    query: [{name: assignment, var: assignment}, {name: country, var: country}, {name: createdBefore, var: created_before}, {name: createdAfter, var: created_after}, {name: geohash, var: geohash}, {name: hasLocation, var: has_location}, {name: latLong, var: lat_long}, {name: radius, var: radius}, {name: mediaType, var: media_type}, {name: ownedBy, var: owned_by}, {name: q, var: q}, {name: urlWords, var: url_words}, {name: user, var: user}, {name: refinements, var: refinements}, {name: refinementSize, var: refinement_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    assignment: $assignment, country: $country, created_before: $created_before, created_after: $created_after, geohash: $geohash, has_location: $has_location, lat_long: $lat_long, radius: $radius, media_type: $media_type, owned_by: $owned_by, q: $q, url_words: $url_words, user: $user, refinements: $refinements, refinement_size: $refinement_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List contributions
#
# GET /contributions
# Returns: table<assignment: record<allowsAnonymousContributions: bool, callToAction: string, cover: record, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: list, urlWords: string, webUrl: string>, attribution: string, body: string, created: string, headline: string, id: string, mediaUsages: list<record>, moderationHistory: list<record>, place: record<country: string, geohash: string, google: string, latLong: record, name: string, osm: record>, urlWords: string, via: record<authority: record, ipAddress: string, ipAddressPlace: record>>
export def "get-contributions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignment: string # Restrict results to contributions submitted to this assignment.
  --country: string # Limit results to contributions which have a publicly visible location within the given country (specified by two letter country code).
  --created-before: string # Limit results to contributions created before this date time. (format: date-time)
  --created-after: string # Limit results to contributions created after this date time. (format: date-time)
  --created-day: string # Limit results to contributions created on this day. (format: date)
  --created-month: string # Limit results to contributions created during this month.
  --geohash: string # Restrict results to contributions which have specified a location which falls within this geohash (or comma seperated list of multiple geohashes)
  --has-location: oneof<nothing, bool> # Restrict results to contributions which have a publicly visible location.
  --lat-long: string # Limit results to contributions with location near this latitude and longitude (comma seperated lat/long pair). Also see radius
  --radius: float # When limiting result by location with the latLong parameter, specify the radius in kilometers. (format: double)
  --media-type: string # Restrict results to contributions which include a media file of the given type (ie. image / video)
  --owned-by: string # Restrict results to contributions which are fall under the jurisdiction by this user.
  --q: string # Restrict results to contributions whose headline text matches this keyword.
  --url-words: string # Locate a specific contribution by URL words
  --user: string # Restrict results to contributions by this user identified by id.
  --ids: string # Restrict results to a list of specific contributions identified by a comma seperated list of ids.
  --format: string # Select output format. 'json' or 'rss'. Defaults to JSON.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/contributions"
    query: [{name: assignment, var: assignment}, {name: country, var: country}, {name: createdBefore, var: created_before}, {name: createdAfter, var: created_after}, {name: createdDay, var: created_day}, {name: createdMonth, var: created_month}, {name: geohash, var: geohash}, {name: hasLocation, var: has_location}, {name: latLong, var: lat_long}, {name: radius, var: radius}, {name: mediaType, var: media_type}, {name: ownedBy, var: owned_by}, {name: q, var: q}, {name: urlWords, var: url_words}, {name: user, var: user}, {name: ids, var: ids}, {name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    assignment: $assignment, country: $country, created_before: $created_before, created_after: $created_after, created_day: $created_day, created_month: $created_month, geohash: $geohash, has_location: $has_location, lat_long: $lat_long, radius: $radius, media_type: $media_type, owned_by: $owned_by, q: $q, url_words: $url_words, user: $user, ids: $ids, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new contribution
#
# POST /contributions
# Returns: record<assignment: record<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list, id: string, media: record>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: list<record>, urlWords: string, webUrl: string>, attribution: string, body: string, created: string, headline: string, id: string, mediaUsages: table<artifacts: list, id: string, media: record>, moderationHistory: table<action: record, date: string, notes: string>, place: record<country: string, geohash: string, google: string, latLong: record<latitude: float, longitude: float>, name: string, osm: record<osmId: float, osmType: string>>, urlWords: string, via: record<authority: record<client: record, id: string, user: record>, ipAddress: string, ipAddressPlace: record<country: string, geohash: string, google: string, latLong: record, name: string, osm: record>>>
export def "post-contributions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignment: record # shape: {allowsAnonymousContributions?: bool, callToAction?: string, cover?: record, created?: string, description?: string, embargo?: string, ends?: string, featured?: bool, id?: string, mediaRequired?: bool, moderator?: string, name?: string, open?: bool, receiptMessage?: string, starts?: string, tags?: list, urlWords?: string, webUrl?: string}
  --attribution: string # The public attribution for this contribution. This will be the display name of the registered user or the contributor's first and last name if they provided them while making a non authenticated contribution. A blank attribution field indicates and anonymous contribution.
  --body: string
  --created: string # format: date-time
  --headline: string
  --id: string
  --media-usages: list # item shape: {artifacts?: list, id?: string, media?: record}
  --moderation-history: list # item shape: {action?: record, date: string, notes?: string}
  --place: record # shape: {country?: string, geohash?: string, google?: string, latLong?: record, name?: string, osm?: record}
  --url-words: string
  --via: record # shape: {authority?: record, ipAddress?: string, ipAddressPlace?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contributions"
    body: {content_type: "application/json", kind: json, fields: [{name: assignment, var: assignment}, {name: attribution, var: attribution}, {name: body, var: body}, {name: created, var: created}, {name: headline, var: headline}, {name: id, var: id}, {name: mediaUsages, var: media_usages}, {name: moderationHistory, var: moderation_history}, {name: place, var: place}, {name: urlWords, var: url_words}, {name: via, var: via}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    assignment: $assignment, attribution: $attribution, body: $body, created: $created, headline: $headline, id: $id, media_usages: $media_usages, moderation_history: $moderation_history, place: $place, url_words: $url_words, via: $via
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete this contribution
#
# DELETE /contributions/{id}
# Returns: record<assignment: record<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list, id: string, media: record>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: list<record>, urlWords: string, webUrl: string>, attribution: string, body: string, created: string, headline: string, id: string, mediaUsages: table<artifacts: list, id: string, media: record>, moderationHistory: table<action: record, date: string, notes: string>, place: record<country: string, geohash: string, google: string, latLong: record<latitude: float, longitude: float>, name: string, osm: record<osmId: float, osmType: string>>, urlWords: string, via: record<authority: record<client: record, id: string, user: record>, ipAddress: string, ipAddressPlace: record<country: string, geohash: string, google: string, latLong: record, name: string, osm: record>>>
export def "delete-contributions-id" [
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
    method: delete
    path: "/contributions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single contribution by id
#
# GET /contributions/{id}
# Returns: record<assignment: record<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list, id: string, media: record>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: list<record>, urlWords: string, webUrl: string>, attribution: string, body: string, created: string, headline: string, id: string, mediaUsages: table<artifacts: list, id: string, media: record>, moderationHistory: table<action: record, date: string, notes: string>, place: record<country: string, geohash: string, google: string, latLong: record<latitude: float, longitude: float>, name: string, osm: record<osmId: float, osmType: string>>, urlWords: string, via: record<authority: record<client: record, id: string, user: record>, ipAddress: string, ipAddressPlace: record<country: string, geohash: string, google: string, latLong: record, name: string, osm: record>>>
export def "get-contributions-id" [
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
    path: "/contributions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Raise a flag against this contribution
#
# POST /contributions/{id}/flag
# Returns: record<date: string, email: string, id: string, notes: string, type: string>
export def "post-contributions-id-flag" [
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
  --date: string # format: date-time
  --email: string
  --body-id: string # (spec name: id)
  --notes: string
  --type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contributions/{id}/flag"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: date, var: date}, {name: email, var: email}, {name: id, var: body_id}, {name: notes, var: notes}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, date: $date, email: $email, body_id: $body_id, notes: $notes, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows a user to mark a contribution as liked
#
# POST /contributions/{id}/like
# Returns: float
export def "post-contributions-id-like" [
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
]: nothing -> any {
  http-request {
    method: post
    path: "/contributions/{id}/like"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List users who have liked this contributions
#
# GET /contributions/{id}/likes
# Returns: list<string>
export def "get-contributions-id-likes" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/contributions/{id}/likes"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform a moderation action on this contribution
#
# POST /contributions/{id}/moderate
# Returns: string
export def "post-contributions-id-moderate" [
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
  --action: record # shape: {id: string, label: string, resultingState: record}
  --notes: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/contributions/{id}/moderate"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: notes, var: notes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, action: $action, notes: $notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the credentials associated with the authenticated user.
#
# GET /credentials
# Returns: table<scopes: list<string>, type: string, user: string, value: string>
export def "get-credentials" [
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
    path: "/credentials"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Event types
#
# GET /event-types
# Returns: table<id: string, name: string>
export def "get-event-types" [
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
    path: "/event-types"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export contributions.
#
# POST /export
# Returns: record<downloadUrl: string, finished: string, id: string, owner: string, progress: float, started: string, step: string>
export def "post-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignment: string # Restrict results to contributions submitted to this assignment.
  --country: string # Limit results to contributions which have a publicly visible location within the given country (specified by two letter country code).
  --created-before: string # Limit results to contributions created before this date time. (format: date-time)
  --created-after: string # Limit results to contributions created after this date time. (format: date-time)
  --geohash: string # Restrict results to contributions which have specified a location which falls within this geohash (or comma seperated list of multiple geohashes)
  --has-location: oneof<nothing, bool> # Restrict results to contributions which have a publicly visible location.
  --lat-long: string # Limit results to contributions with location near this latitude and longitude (comma seperated lat/long pair). Also see radius
  --radius: float # When limiting result by location with the latLong parameter, specify the radius in kilometers. (format: double)
  --media-type: string # Restrict results to contributions which include a media file of the given type (ie. image / video)
  --owned-by: string # Restrict results to contributions which are fall under the jurisdiction by this user.
  --q: string # Restrict results to contributions whose headline text matches this keyword.
  --url-words: string # Locate a specific contribution by URL words
  --user: string # Restrict results to contributions by this user identified by id.
  --tagged: oneof<nothing, bool> # Should exported media files be tagged with metadata. Deprecated; use format instead.
  --combined: oneof<nothing, bool> # Included a combined file with all contribution text.
  --individual: oneof<nothing, bool> # Include individual text files for each contribution.
  --format: string # Media format to export; none, fullsize, tagged or original.
  --json: oneof<nothing, bool> # Include raw JSON for each contribution.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/export"
    query: [{name: assignment, var: assignment}, {name: country, var: country}, {name: createdBefore, var: created_before}, {name: createdAfter, var: created_after}, {name: geohash, var: geohash}, {name: hasLocation, var: has_location}, {name: latLong, var: lat_long}, {name: radius, var: radius}, {name: mediaType, var: media_type}, {name: ownedBy, var: owned_by}, {name: q, var: q}, {name: urlWords, var: url_words}, {name: user, var: user}, {name: tagged, var: tagged}, {name: combined, var: combined}, {name: individual, var: individual}, {name: format, var: format}, {name: json, var: json}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    assignment: $assignment, country: $country, created_before: $created_before, created_after: $created_after, geohash: $geohash, has_location: $has_location, lat_long: $lat_long, radius: $radius, media_type: $media_type, owned_by: $owned_by, q: $q, url_words: $url_words, user: $user, tagged: $tagged, combined: $combined, individual: $individual, format: $format, json: $json
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export contributions preflight summary.
#
# POST /export-summary
# Returns: record<contributions: float, estimatedSize: string, media: float, totalMediaSize: float>
export def "post-export-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignment: string # Restrict results to contributions submitted to this assignment.
  --country: string # Limit results to contributions which have a publicly visible location within the given country (specified by two letter country code).
  --created-before: string # Limit results to contributions created before this date time. (format: date-time)
  --created-after: string # Limit results to contributions created after this date time. (format: date-time)
  --geohash: string # Restrict results to contributions which have specified a location which falls within this geohash (or comma seperated list of multiple geohashes)
  --has-location: oneof<nothing, bool> # Restrict results to contributions which have a publicly visible location.
  --lat-long: string # Limit results to contributions with location near this latitude and longitude (comma seperated lat/long pair). Also see radius
  --radius: float # When limiting result by location with the latLong parameter, specify the radius in kilometers. (format: double)
  --media-type: string # Restrict results to contributions which include a media file of the given type (ie. image / video)
  --owned-by: string # Restrict results to contributions which are fall under the jurisdiction by this user.
  --q: string # Restrict results to contributions whose headline text matches this keyword.
  --url-words: string # Locate a specific contribution by URL words
  --user: string # Restrict results to contributions by this user identified by id.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/export-summary"
    query: [{name: assignment, var: assignment}, {name: country, var: country}, {name: createdBefore, var: created_before}, {name: createdAfter, var: created_after}, {name: geohash, var: geohash}, {name: hasLocation, var: has_location}, {name: latLong, var: lat_long}, {name: radius, var: radius}, {name: mediaType, var: media_type}, {name: ownedBy, var: owned_by}, {name: q, var: q}, {name: urlWords, var: url_words}, {name: user, var: user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    assignment: $assignment, country: $country, created_before: $created_before, created_after: $created_after, geohash: $geohash, has_location: $has_location, lat_long: $lat_long, radius: $radius, media_type: $media_type, owned_by: $owned_by, q: $q, url_words: $url_words, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single export job; poll to follow export progress.
#
# GET /exports/{id}
# Returns: record<downloadUrl: string, finished: string, id: string, owner: string, progress: float, started: string, step: string>
export def "get-exports-id" [
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
    path: "/exports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List form responses
#
# GET /form-responses
# Returns: table<contribution: string, date: string, form: string, id: string, responses: record, user: string>
export def "get-form-responses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # Restrict results to responses submitted by this user.
  --form: string # Restrict results to responses submitted to this form.
  --contribution: string # Restrict results to responses relating to this contribution.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/form-responses"
    query: [{name: user, var: user}, {name: form, var: form}, {name: contribution, var: contribution}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, form: $form, contribution: $contribution
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a response to a form
#
# POST /form-responses
# Returns: record<contribution: string, date: string, form: string, id: string, responses: record, user: string>
export def "post-form-responses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contribution: string
  --form: string
  --responses: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/form-responses"
    body: {content_type: "application/json", kind: json, fields: [{name: contribution, var: contribution}, {name: form, var: form}, {name: responses, var: responses}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contribution: $contribution, form: $form, responses: $responses
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single form response by id
#
# GET /form-responses/{id}
# Returns: record<contribution: string, date: string, form: string, id: string, responses: record, user: string>
export def "get-form-responses-id" [
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
    path: "/form-responses/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List forms
#
# GET /forms
# Returns: table<callToAction: string, cssUrl: string, fields: list<record>, heading: string, id: string, name: string, noCss: bool, ownedBy: string, tags: list<record>>
export def "get-forms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owned-by: string # Restrict results to forms owned by this user. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/forms"
    query: [{name: ownedBy, var: owned_by, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owned_by: $owned_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a form
#
# POST /forms
# Returns: record<callToAction: string, cssUrl: string, fields: table<description: string, label: string, name: string, options: list, public: bool, required: bool, type: string>, heading: string, id: string, name: string, noCss: bool, ownedBy: string, tags: table<colour: string, id: string, name: string, tagSet: record, urlWords: string>>
export def "post-forms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-to-action: string
  --css-url: string
  --fields: list # item shape: {description?: string, label?: string, name?: string, options?: list<string>, public?: bool, required?: bool, type?: string}
  --heading: string
  --name: string
  --no-css: oneof<nothing, bool>
  --tags: list # item shape: {colour?: string, id: string, name: string, tagSet?: record, urlWords?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/forms"
    body: {content_type: "application/json", kind: json, fields: [{name: callToAction, var: call_to_action}, {name: cssUrl, var: css_url}, {name: fields, var: fields}, {name: heading, var: heading}, {name: name, var: name}, {name: noCss, var: no_css}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_to_action: $call_to_action, css_url: $css_url, fields: $fields, heading: $heading, name: $name, no_css: $no_css, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete this form and all of it's responses.
#
# DELETE /forms/{id}
export def "delete-forms-id" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/forms/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single form by id
#
# GET /forms/{id}
# Returns: record<callToAction: string, cssUrl: string, fields: table<description: string, label: string, name: string, options: list, public: bool, required: bool, type: string>, heading: string, id: string, name: string, noCss: bool, ownedBy: string, tags: table<colour: string, id: string, name: string, tagSet: record, urlWords: string>>
export def "get-forms-id" [
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
    path: "/forms/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a new media file
#
# POST /media
# Returns: record<duration: float, id: string, place: record<country: string, geohash: string, google: string, latLong: record<latitude: float, longitude: float>, name: string, osm: record<osmId: float, osmType: string>>, type: string>
export def "post-media" [
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
    method: post
    path: "/media"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /notifications/contributions/{id}/preview
#
# Returns: record<email: string, html: string, subject: string>
export def "get-notifications-contributions-id-preview" [
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
  --message: string # Type of message to preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notifications/contributions/{id}/preview"
    path_params: [{name: id, var: id}]
    query: [{name: message, var: message, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Scopes
#
# GET /scopes
# Returns: list<string>
export def "get-scopes" [
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
    path: "/scopes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscription types
#
# GET /subscription-types
# Returns: table<id: string, name: string>
export def "get-subscription-types" [
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
    path: "/subscription-types"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List subscriptions for the authorised user.
#
# GET /subscriptions
# Returns: table<assignment: string, email: string, id: string, includeBody: bool, includeThumbenail: bool, slackChannel: string, token: string, types: list<string>, user: string>
export def "get-subscriptions" [
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
    path: "/subscriptions"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a subscription.
#
# DELETE /subscriptions/{id}
export def "delete-subscriptions-id" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List tags
#
# GET /tags
# Returns: table<colour: string, id: string, name: string, tagSet: record<id: string, name: string>, urlWords: string>
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
  --owned-by: string # Restrict results to those owned by this user.
  --tag-set: string # Restrict results to tags belonging to this tag set.
  --url-words: string # Restrict results by urlWords. Should be used with ownedBy when searching for one of your own tags.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tags"
    query: [{name: ownedBy, var: owned_by}, {name: tagSet, var: tag_set}, {name: urlWords, var: url_words}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owned_by: $owned_by, tag_set: $tag_set, url_words: $url_words
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new tag
#
# POST /tags
# Returns: record<colour: string, id: string, name: string, tagSet: record<id: string, name: string>, urlWords: string>
export def "post-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --colour: string
  name: string
  --tag-set: record # shape: {id: string, name: string}
  --url-words: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags"
    body: {content_type: "application/json", kind: json, fields: [{name: colour, var: colour}, {name: name, var: name}, {name: tagSet, var: tag_set}, {name: urlWords, var: url_words}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    colour: $colour, name: $name, tag_set: $tag_set, url_words: $url_words
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single tag by id
#
# GET /tags/{id}
# Returns: record<colour: string, id: string, name: string, tagSet: record<id: string, name: string>, urlWords: string>
export def "get-tags-id" [
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
    path: "/tags/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List tag sets
#
# GET /tagsets
# Returns: table<id: string, name: string>
export def "get-tagsets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owned-by: string # Restrict results to those owned by this user.
  --url-words: string # Restrict results by urlWords. Should be used with ownedBy when searching for one of your own tag sets.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tagsets"
    query: [{name: ownedBy, var: owned_by}, {name: urlWords, var: url_words}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owned_by: $owned_by, url_words: $url_words
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new tag set
#
# POST /tagsets
# Returns: record<id: string, name: string>
export def "post-tagsets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  url_words: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tagsets"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: urlWords, var: url_words}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, url_words: $url_words
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single tag set by id
#
# GET /tagsets/{id}
# Returns: record<id: string, name: string>
export def "get-tagsets-id" [
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
    path: "/tagsets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List users
#
# GET /users
# Returns: table<bio: string, displayName: string, id: string, registered: string, username: string>
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
  --assignment: string # Restrict results to the users who have contributed to this assignment.
  --country: string # Restrict results to the users who have submitted a contribution with a public location located within this country.
  --minimum-contributions: float # Restrict results to the users who have submitted at least this many contributions.
  --linked-profile: string # Restrict results to the users who a linked profile of this type.
  --owned-by: string # Restrict results to the users who are owned by of this owner.
  --submitted-before: string # Limit results to users who have submitted at least one contribution before this date time. (format: date-time)
  --submitted-after: string # Limit results to users who have submitted at least one contribution after this date time. (format: date-time)
  --username: string # Restrict results to the user with this username.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: assignment, var: assignment}, {name: country, var: country}, {name: minimumContributions, var: minimum_contributions}, {name: linkedProfile, var: linked_profile}, {name: ownedBy, var: owned_by}, {name: submittedBefore, var: submitted_before}, {name: submittedAfter, var: submitted_after}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    assignment: $assignment, country: $country, minimum_contributions: $minimum_contributions, linked_profile: $linked_profile, owned_by: $owned_by, submitted_before: $submitted_before, submitted_after: $submitted_after, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single user by id
#
# GET /users/{id}
# Returns: record<bio: string, displayName: string, id: string, registered: string, username: string>
export def "get-users-id" [
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
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a users linked profile by type
#
# GET /users/{id}/linked/{type}
# Returns: record<bio: string, email: string, id: string, name: string, picture: string, profile: string, registered: string>
export def "get-users-id-linked-type" [
  id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/users/{id}/linked/{type}"
    path_params: [{name: id, var: id}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify token and return details of the owning user
#
# POST /verify
# Returns: record<client: record<id: string, name: string>, id: string, user: record<bio: string, displayName: string, id: string, registered: string, username: string>>
export def "post-verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/verify"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
