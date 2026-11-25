# Auto-generated client for OpenAQ v2.0.0
# Source: https://api.apis.guru/v2/specs/openaq.local/2.0.0/openapi.json
# Auth: --token flag or $env.OPENAQ_TOKEN

const CLIENT = {
  base_url: "http://openaq.local"
  token_env_var: "OPENAQ_TOKEN"
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

def base-url-completer [] { ["http://openaq.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["asc" "desc"] }
def order-by-completer [] { ["city" "country" "firstUpdated" "lastUpdated"] }
def order-by-completer-1 [] { ["count" "country" "firstUpdated" "lastUpdated" "locations"] }
def order-by-completer-2 [] { ["city" "count" "country" "firstUpdated" "lastUpdated" "location" "random" "sourceName"] }
def entity-completer [] { ["community" "government" "research"] }
def sensor-type-completer [] { ["low-cost sensor" "reference grade"] }
def order-by-completer-3 [] { ["city" "country" "datetime" "location"] }
def order-by-completer-4 [] { ["name"] }
def spatial-completer [] { ["country" "location" "project" "total"] }
def temporal-completer [] { ["day" "dow" "hod" "hour" "month" "moy" "year"] }
def order-by-completer-5 [] { ["firstUpdated" "id" "lastUpdated" "name" "subtitle"] }
def order-by-completer-6 [] { ["firstUpdated" "lastUpdated" "sourceName"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    cities-getv1-v1-cities-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<city: string, count: int, country: string, firstUpdated: string, lastUpdated: string, locations: int, parameters: list>>"
    countries-getv1-v1-countries-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<cities: int, code: string, count: int, firstUpdated: string, lastUpdated: string, locations: int, name: string, parameters: list, sources: int>>"
    countries-get-v1-countries-country-id-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<cities: int, code: string, count: int, firstUpdated: string, lastUpdated: string, locations: int, name: string, parameters: list, sources: int>>"
    latest-v1-get-v1-latest-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>"
    latest-v1-get-v1-latest-location-id-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>"
    locationsv1-get-v1-locations-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>"
    locationsv1-get-v1-locations-location-id-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>"
    parameters-getv1-v1-parameters-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<description: string, displayName: string, id: int, isCore: bool, maxColorValue: float, name: string, preferredUnit: string>>"
    sources-v1-get-v1-sources-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>"
    averages-v2-get-v2-averages-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>"
    cities-get-v2-cities-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<city: string, count: int, country: string, firstUpdated: string, lastUpdated: string, locations: int, parameters: list>>"
    countries-get-v2-countries-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<cities: int, code: string, count: int, firstUpdated: string, lastUpdated: string, locations: int, name: string, parameters: list, sources: int>>"
    countries-get-v2-countries-country-id-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<cities: int, code: string, count: int, firstUpdated: string, lastUpdated: string, locations: int, name: string, parameters: list, sources: int>>"
    latest-get-v2-latest-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>"
    latest-get-v2-latest-location-id-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>"
    locations-get-v2-locations-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>"
    mobilegentilejson-v2-locations-tiles-mobile-generalized-tiles-json-get: "record<attribution: string, bounds: list<float>, data: list<string>, description: string, grids: list<string>, legend: string, maxzoom: int, minzoom: int, name: string, scheme: string, template: string, tilejson: string, tiles: list<string>, version: string>"
    mobiletilejson-v2-locations-tiles-mobile-tiles-json-get: "record<attribution: string, bounds: list<float>, data: list<string>, description: string, grids: list<string>, legend: string, maxzoom: int, minzoom: int, name: string, scheme: string, template: string, tilejson: string, tiles: list<string>, version: string>"
    tilejson-v2-locations-tiles-tiles-json-get: "record<attribution: string, bounds: list<float>, data: list<string>, description: string, grids: list<string>, legend: string, maxzoom: int, minzoom: int, name: string, scheme: string, template: string, tilejson: string, tiles: list<string>, version: string>"
    demo-v2-locations-tiles-viewer-get: "string"
    locations-get-v2-locations-location-id-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>"
    mfr-get-v2-manufacturers-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>"
    model-get-v2-models-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>"
    parameters-get-v2-parameters-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<description: string, displayName: string, id: int, isCore: bool, maxColorValue: float, name: string, preferredUnit: string>>"
    projects-get-v2-projects-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<bbox: list, countries: list, entity: string, firstUpdated: string, id: int, isAnalysis: bool, isMobile: bool, lastUpdated: string, locationIds: list, locations: int, measurements: int, name: string, parameters: list, sensorType: string, sources: list, subtitle: string>>"
    projects-get-v2-projects-project-id-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<bbox: list, countries: list, entity: string, firstUpdated: string, id: int, isAnalysis: bool, isMobile: bool, lastUpdated: string, locationIds: list, locations: int, measurements: int, name: string, parameters: list, sensorType: string, sources: list, subtitle: string>>"
    sources-get-v2-sources-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>"
    summary-get-v2-summary-get: "record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["favico-favicon-ico-get" "pong-ping-get" "cities-getv1-v1-cities-get" "countries-getv1-v1-countries-get" "countries-get-v1-countries-country-id-get" "latest-v1-get-v1-latest-get" "latest-v1-get-v1-latest-location-id-get" "locationsv1-get-v1-locations-get" "locationsv1-get-v1-locations-location-id-get" "measurements-get-v1-v1-measurements-get" "parameters-getv1-v1-parameters-get" "sources-v1-get-v1-sources-get" "averages-v2-get-v2-averages-get" "cities-get-v2-cities-get" "countries-get-v2-countries-get" "countries-get-v2-countries-country-id-get" "latest-get-v2-latest-get" "latest-get-v2-latest-location-id-get" "locations-get-v2-locations-get" "mobilegentilejson-v2-locations-tiles-mobile-generalized-tiles-json-get" "get-mobilegentile-v2-locations-tiles-mobile-generalized-z-x-y-pbf-get" "mobiletilejson-v2-locations-tiles-mobile-tiles-json-get" "get-mobiletile-v2-locations-tiles-mobile-z-x-y-pbf-get" "tilejson-v2-locations-tiles-tiles-json-get" "demo-v2-locations-tiles-viewer-get" "get-tile-v2-locations-tiles-z-x-y-pbf-get" "locations-get-v2-locations-location-id-get" "mfr-get-v2-manufacturers-get" "measurements-get-v2-measurements-get" "model-get-v2-models-get" "parameters-get-v2-parameters-get" "projects-get-v2-projects-get" "projects-get-v2-projects-project-id-get" "sources-get-v2-sources-get" "readme-get-v2-sources-readme-slug-get" "summary-get-v2-summary-get" "commands"] | sort) } | get name | first)
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

# Favico
#
# GET /favicon.ico
# operationId: favico_favicon_ico_get
export def "favico-favicon-ico-get" [
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
    path: "/favicon.ico"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pong
#
# GET /ping
# operationId: pong_ping_get
export def "pong-ping-get" [
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
    path: "/ping"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a simple listing of cities within the platform
#
# GET /v1/cities
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<city: string, count: int, country: string, firstUpdated: string, lastUpdated: string, locations: int, parameters: list>>
# operationId: cities_getv1_v1_cities_get
export def "cities-getv1-v1-cities-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Define sort order. (default: asc)
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --order-by: string@order-by-completer # Order by a field (default: city)
  --entity: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/cities"
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: country_id, var: country_id}, {name: country, var: country, style: multi}, {name: city, var: city, style: multi}, {name: order_by, var: order_by}, {name: entity, var: entity}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, page: $page, offset: $offset, sort: $sort, country_id: $country_id, country: $country, city: $city, order_by: $order_by, entity: $entity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Countries Getv1
#
# GET /v1/countries
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<cities: int, code: string, count: int, firstUpdated: string, lastUpdated: string, locations: int, name: string, parameters: list, sources: int>>
# operationId: countries_getv1_v1_countries_get
export def "countries-getv1-v1-countries-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 200
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Define sort order. (default: asc)
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --order-by: string@order-by-completer-1 # default: country
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/countries"
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: country_id, var: country_id}, {name: country, var: country, style: multi}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, page: $page, offset: $offset, sort: $sort, country_id: $country_id, country: $country, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Countries Get
#
# GET /v1/countries/{country_id}
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<cities: int, code: string, count: int, firstUpdated: string, lastUpdated: string, locations: int, name: string, parameters: list, sources: int>>
# operationId: countries_get_v1_countries__country_id__get
export def "countries-get-v1-countries-country-id-get" [
  country_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 200
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Define sort order. (default: asc)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --order-by: string@order-by-completer-1 # default: country
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/countries/{country_id}"
    path_params: [{name: country_id, var: country_id}]
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: country, var: country, style: multi}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country_id: $country_id, limit: $limit, page: $page, offset: $offset, sort: $sort, country: $country, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Latest V1 Get
#
# GET /v1/latest
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>
# operationId: latest_v1_get_v1_latest_get
export def "latest-v1-get-v1-latest-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Sort Direction (default: desc)
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location-id: int
  --location: list
  --order-by: string@order-by-completer-2 # Order by a field (default: lastUpdated)
  --is-mobile: oneof<nothing, bool> # Location is mobile
  --is-analysis: oneof<nothing, bool> # Data is the product of a previous analysis/aggregation and not raw measurements
  --source-name: list<string> # Name of the data source
  --entity: string@entity-completer # Source entity type.
  --sensor-type: string@sensor-type-completer # Type of Sensor
  --model-name: list<string> # Model Name of Sensor
  --manufacturer-name: list<string> # Manufacturer of Sensor
  --dump-raw: oneof<nothing, bool> # default: false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/latest"
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: has_geo, var: has_geo}, {name: parameter_id, var: parameter_id}, {name: parameter, var: parameter, style: multi}, {name: unit, var: unit, style: multi}, {name: coordinates, var: coordinates}, {name: radius, var: radius}, {name: country_id, var: country_id}, {name: country, var: country, style: multi}, {name: city, var: city, style: multi}, {name: location_id, var: location_id}, {name: location, var: location, style: multi}, {name: order_by, var: order_by}, {name: isMobile, var: is_mobile}, {name: isAnalysis, var: is_analysis}, {name: sourceName, var: source_name, style: multi}, {name: entity, var: entity}, {name: sensorType, var: sensor_type}, {name: modelName, var: model_name, style: multi}, {name: manufacturerName, var: manufacturer_name, style: multi}, {name: dumpRaw, var: dump_raw}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, page: $page, offset: $offset, sort: $sort, has_geo: $has_geo, parameter_id: $parameter_id, parameter: $parameter, unit: $unit, coordinates: $coordinates, radius: $radius, country_id: $country_id, country: $country, city: $city, location_id: $location_id, location: $location, order_by: $order_by, is_mobile: $is_mobile, is_analysis: $is_analysis, source_name: $source_name, entity: $entity, sensor_type: $sensor_type, model_name: $model_name, manufacturer_name: $manufacturer_name, dump_raw: $dump_raw
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Latest V1 Get
#
# GET /v1/latest/{location_id}
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>
# operationId: latest_v1_get_v1_latest__location_id__get
export def "latest-v1-get-v1-latest-location-id-get" [
  location_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Sort Direction (default: desc)
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location: list
  --order-by: string@order-by-completer-2 # Order by a field (default: lastUpdated)
  --is-mobile: oneof<nothing, bool> # Location is mobile
  --is-analysis: oneof<nothing, bool> # Data is the product of a previous analysis/aggregation and not raw measurements
  --source-name: list<string> # Name of the data source
  --entity: string@entity-completer # Source entity type.
  --sensor-type: string@sensor-type-completer # Type of Sensor
  --model-name: list<string> # Model Name of Sensor
  --manufacturer-name: list<string> # Manufacturer of Sensor
  --dump-raw: oneof<nothing, bool> # default: false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/latest/{location_id}"
    path_params: [{name: location_id, var: location_id}]
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: has_geo, var: has_geo}, {name: parameter_id, var: parameter_id}, {name: parameter, var: parameter, style: multi}, {name: unit, var: unit, style: multi}, {name: coordinates, var: coordinates}, {name: radius, var: radius}, {name: country_id, var: country_id}, {name: country, var: country, style: multi}, {name: city, var: city, style: multi}, {name: location, var: location, style: multi}, {name: order_by, var: order_by}, {name: isMobile, var: is_mobile}, {name: isAnalysis, var: is_analysis}, {name: sourceName, var: source_name, style: multi}, {name: entity, var: entity}, {name: sensorType, var: sensor_type}, {name: modelName, var: model_name, style: multi}, {name: manufacturerName, var: manufacturer_name, style: multi}, {name: dumpRaw, var: dump_raw}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, limit: $limit, page: $page, offset: $offset, sort: $sort, has_geo: $has_geo, parameter_id: $parameter_id, parameter: $parameter, unit: $unit, coordinates: $coordinates, radius: $radius, country_id: $country_id, country: $country, city: $city, location: $location, order_by: $order_by, is_mobile: $is_mobile, is_analysis: $is_analysis, source_name: $source_name, entity: $entity, sensor_type: $sensor_type, model_name: $model_name, manufacturer_name: $manufacturer_name, dump_raw: $dump_raw
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Locationsv1 Get
#
# GET /v1/locations
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>
# operationId: locationsv1_get_v1_locations_get
export def "locationsv1-get-v1-locations-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Sort Direction (default: desc)
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location-id: int
  --location: list
  --order-by: string@order-by-completer-2 # Order by a field (default: lastUpdated)
  --is-mobile: oneof<nothing, bool> # Location is mobile
  --is-analysis: oneof<nothing, bool> # Data is the product of a previous analysis/aggregation and not raw measurements
  --source-name: list<string> # Name of the data source
  --entity: string@entity-completer # Source entity type.
  --sensor-type: string@sensor-type-completer # Type of Sensor
  --model-name: list<string> # Model Name of Sensor
  --manufacturer-name: list<string> # Manufacturer of Sensor
  --dump-raw: oneof<nothing, bool> # default: false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/locations"
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: has_geo, var: has_geo}, {name: parameter_id, var: parameter_id}, {name: parameter, var: parameter, style: multi}, {name: unit, var: unit, style: multi}, {name: coordinates, var: coordinates}, {name: radius, var: radius}, {name: country_id, var: country_id}, {name: country, var: country, style: multi}, {name: city, var: city, style: multi}, {name: location_id, var: location_id}, {name: location, var: location, style: multi}, {name: order_by, var: order_by}, {name: isMobile, var: is_mobile}, {name: isAnalysis, var: is_analysis}, {name: sourceName, var: source_name, style: multi}, {name: entity, var: entity}, {name: sensorType, var: sensor_type}, {name: modelName, var: model_name, style: multi}, {name: manufacturerName, var: manufacturer_name, style: multi}, {name: dumpRaw, var: dump_raw}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, page: $page, offset: $offset, sort: $sort, has_geo: $has_geo, parameter_id: $parameter_id, parameter: $parameter, unit: $unit, coordinates: $coordinates, radius: $radius, country_id: $country_id, country: $country, city: $city, location_id: $location_id, location: $location, order_by: $order_by, is_mobile: $is_mobile, is_analysis: $is_analysis, source_name: $source_name, entity: $entity, sensor_type: $sensor_type, model_name: $model_name, manufacturer_name: $manufacturer_name, dump_raw: $dump_raw
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Locationsv1 Get
#
# GET /v1/locations/{location_id}
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>
# operationId: locationsv1_get_v1_locations__location_id__get
export def "locationsv1-get-v1-locations-location-id-get" [
  location_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Sort Direction (default: desc)
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location: list
  --order-by: string@order-by-completer-2 # Order by a field (default: lastUpdated)
  --is-mobile: oneof<nothing, bool> # Location is mobile
  --is-analysis: oneof<nothing, bool> # Data is the product of a previous analysis/aggregation and not raw measurements
  --source-name: list<string> # Name of the data source
  --entity: string@entity-completer # Source entity type.
  --sensor-type: string@sensor-type-completer # Type of Sensor
  --model-name: list<string> # Model Name of Sensor
  --manufacturer-name: list<string> # Manufacturer of Sensor
  --dump-raw: oneof<nothing, bool> # default: false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/locations/{location_id}"
    path_params: [{name: location_id, var: location_id}]
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: has_geo, var: has_geo}, {name: parameter_id, var: parameter_id}, {name: parameter, var: parameter, style: multi}, {name: unit, var: unit, style: multi}, {name: coordinates, var: coordinates}, {name: radius, var: radius}, {name: country_id, var: country_id}, {name: country, var: country, style: multi}, {name: city, var: city, style: multi}, {name: location, var: location, style: multi}, {name: order_by, var: order_by}, {name: isMobile, var: is_mobile}, {name: isAnalysis, var: is_analysis}, {name: sourceName, var: source_name, style: multi}, {name: entity, var: entity}, {name: sensorType, var: sensor_type}, {name: modelName, var: model_name, style: multi}, {name: manufacturerName, var: manufacturer_name, style: multi}, {name: dumpRaw, var: dump_raw}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, limit: $limit, page: $page, offset: $offset, sort: $sort, has_geo: $has_geo, parameter_id: $parameter_id, parameter: $parameter, unit: $unit, coordinates: $coordinates, radius: $radius, country_id: $country_id, country: $country, city: $city, location: $location, order_by: $order_by, is_mobile: $is_mobile, is_analysis: $is_analysis, source_name: $source_name, entity: $entity, sensor_type: $sensor_type, model_name: $model_name, manufacturer_name: $manufacturer_name, dump_raw: $dump_raw
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Measurements Get V1
#
# GET /v1/measurements
# operationId: measurements_get_v1_v1_measurements_get
export def "measurements-get-v1-v1-measurements-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string
  --date-from: string # default: 2000-01-01T00:00:00+00:00
  --date-to: string # default: 2021-08-23T09:48:00+00:00
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # default: desc
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location-id: int
  --location: list
  --order-by: string@order-by-completer-3 # default: datetime
  --is-mobile: oneof<nothing, bool>
  --is-analysis: oneof<nothing, bool>
  --project: int
  --entity: string@entity-completer
  --sensor-type: string@sensor-type-completer
  --value-from: float
  --value-to: float
  --include-fields: string
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/measurements"
    query: [{name: format, var: format}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: has_geo, var: has_geo}, {name: parameter_id, var: parameter_id}, {name: parameter, var: parameter, style: multi}, {name: unit, var: unit, style: multi}, {name: coordinates, var: coordinates}, {name: radius, var: radius}, {name: country_id, var: country_id}, {name: country, var: country, style: multi}, {name: city, var: city, style: multi}, {name: location_id, var: location_id}, {name: location, var: location, style: multi}, {name: order_by, var: order_by}, {name: isMobile, var: is_mobile}, {name: isAnalysis, var: is_analysis}, {name: project, var: project}, {name: entity, var: entity}, {name: sensorType, var: sensor_type}, {name: value_from, var: value_from}, {name: value_to, var: value_to}, {name: include_fields, var: include_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    format: $format, date_from: $date_from, date_to: $date_to, limit: $limit, page: $page, offset: $offset, sort: $sort, has_geo: $has_geo, parameter_id: $parameter_id, parameter: $parameter, unit: $unit, coordinates: $coordinates, radius: $radius, country_id: $country_id, country: $country, city: $city, location_id: $location_id, location: $location, order_by: $order_by, is_mobile: $is_mobile, is_analysis: $is_analysis, project: $project, entity: $entity, sensor_type: $sensor_type, value_from: $value_from, value_to: $value_to, include_fields: $include_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Parameters Getv1
#
# GET /v1/parameters
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<description: string, displayName: string, id: int, isCore: bool, maxColorValue: float, name: string, preferredUnit: string>>
# operationId: parameters_getv1_v1_parameters_get
export def "parameters-getv1-v1-parameters-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Define sort order. (default: asc)
  --source-name: list<string>
  --source-id: list<int>
  --source-slug: list<string>
  --order-by: string # default: id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/parameters"
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: sourceName, var: source_name, style: multi}, {name: sourceId, var: source_id, style: multi}, {name: sourceSlug, var: source_slug, style: multi}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, page: $page, offset: $offset, sort: $sort, source_name: $source_name, source_id: $source_id, source_slug: $source_slug, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sources V1 Get
#
# GET /v1/sources
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>
# operationId: sources_v1_get_v1_sources_get
export def "sources-v1-get-v1-sources-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Define sort order. (default: asc)
  --name: string
  --order-by: string@order-by-completer-4 # default: name
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/sources"
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: name, var: name}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, page: $page, offset: $offset, sort: $sort, name: $name, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Averages V2 Get
#
# GET /v2/averages
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>
# operationId: averages_v2_get_v2_averages_get
export def "averages-v2-get-v2-averages-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # default: 2000-01-01T00:00:00+00:00
  --date-to: string # default: 2021-08-23T09:48:00+00:00
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --project-id: int
  --project: list
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Define sort order. (default: desc)
  --spatial: string@spatial-completer # required
  --temporal: string@temporal-completer # required
  --location: list<string>
  --group: oneof<nothing, bool> # default: false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/averages"
    query: [{name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: parameter_id, var: parameter_id}, {name: parameter, var: parameter, style: multi}, {name: unit, var: unit, style: multi}, {name: project_id, var: project_id}, {name: project, var: project, style: multi}, {name: country_id, var: country_id}, {name: country, var: country, style: multi}, {name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: spatial, var: spatial, required: true}, {name: temporal, var: temporal, required: true}, {name: location, var: location, style: multi}, {name: group, var: group}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date_from: $date_from, date_to: $date_to, parameter_id: $parameter_id, parameter: $parameter, unit: $unit, project_id: $project_id, project: $project, country_id: $country_id, country: $country, limit: $limit, page: $page, offset: $offset, sort: $sort, spatial: $spatial, temporal: $temporal, location: $location, group: $group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a simple listing of cities within the platform
#
# GET /v2/cities
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<city: string, count: int, country: string, firstUpdated: string, lastUpdated: string, locations: int, parameters: list>>
# operationId: cities_get_v2_cities_get
export def "cities-get-v2-cities-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Define sort order. (default: asc)
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --order-by: string@order-by-completer # Order by a field (default: city)
  --entity: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/cities"
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: country_id, var: country_id}, {name: country, var: country, style: multi}, {name: city, var: city, style: multi}, {name: order_by, var: order_by}, {name: entity, var: entity}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, page: $page, offset: $offset, sort: $sort, country_id: $country_id, country: $country, city: $city, order_by: $order_by, entity: $entity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Countries Get
#
# GET /v2/countries
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<cities: int, code: string, count: int, firstUpdated: string, lastUpdated: string, locations: int, name: string, parameters: list, sources: int>>
# operationId: countries_get_v2_countries_get
export def "countries-get-v2-countries-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 200
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Define sort order. (default: asc)
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --order-by: string@order-by-completer-1 # default: country
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/countries"
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: country_id, var: country_id}, {name: country, var: country, style: multi}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, page: $page, offset: $offset, sort: $sort, country_id: $country_id, country: $country, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Countries Get
#
# GET /v2/countries/{country_id}
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<cities: int, code: string, count: int, firstUpdated: string, lastUpdated: string, locations: int, name: string, parameters: list, sources: int>>
# operationId: countries_get_v2_countries__country_id__get
export def "countries-get-v2-countries-country-id-get" [
  country_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 200
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Define sort order. (default: asc)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --order-by: string@order-by-completer-1 # default: country
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/countries/{country_id}"
    path_params: [{name: country_id, var: country_id}]
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: country, var: country, style: multi}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country_id: $country_id, limit: $limit, page: $page, offset: $offset, sort: $sort, country: $country, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Latest Get
#
# GET /v2/latest
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>
# operationId: latest_get_v2_latest_get
export def "latest-get-v2-latest-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Sort Direction (default: desc)
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location-id: int
  --location: list
  --order-by: string@order-by-completer-2 # Order by a field (default: lastUpdated)
  --is-mobile: oneof<nothing, bool> # Location is mobile
  --is-analysis: oneof<nothing, bool> # Data is the product of a previous analysis/aggregation and not raw measurements
  --source-name: list<string> # Name of the data source
  --entity: string@entity-completer # Source entity type.
  --sensor-type: string@sensor-type-completer # Type of Sensor
  --model-name: list<string> # Model Name of Sensor
  --manufacturer-name: list<string> # Manufacturer of Sensor
  --dump-raw: oneof<nothing, bool> # default: false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/latest"
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: has_geo, var: has_geo}, {name: parameter_id, var: parameter_id}, {name: parameter, var: parameter, style: multi}, {name: unit, var: unit, style: multi}, {name: coordinates, var: coordinates}, {name: radius, var: radius}, {name: country_id, var: country_id}, {name: country, var: country, style: multi}, {name: city, var: city, style: multi}, {name: location_id, var: location_id}, {name: location, var: location, style: multi}, {name: order_by, var: order_by}, {name: isMobile, var: is_mobile}, {name: isAnalysis, var: is_analysis}, {name: sourceName, var: source_name, style: multi}, {name: entity, var: entity}, {name: sensorType, var: sensor_type}, {name: modelName, var: model_name, style: multi}, {name: manufacturerName, var: manufacturer_name, style: multi}, {name: dumpRaw, var: dump_raw}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, page: $page, offset: $offset, sort: $sort, has_geo: $has_geo, parameter_id: $parameter_id, parameter: $parameter, unit: $unit, coordinates: $coordinates, radius: $radius, country_id: $country_id, country: $country, city: $city, location_id: $location_id, location: $location, order_by: $order_by, is_mobile: $is_mobile, is_analysis: $is_analysis, source_name: $source_name, entity: $entity, sensor_type: $sensor_type, model_name: $model_name, manufacturer_name: $manufacturer_name, dump_raw: $dump_raw
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Latest Get
#
# GET /v2/latest/{location_id}
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>
# operationId: latest_get_v2_latest__location_id__get
export def "latest-get-v2-latest-location-id-get" [
  location_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Sort Direction (default: desc)
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location: list
  --order-by: string@order-by-completer-2 # Order by a field (default: lastUpdated)
  --is-mobile: oneof<nothing, bool> # Location is mobile
  --is-analysis: oneof<nothing, bool> # Data is the product of a previous analysis/aggregation and not raw measurements
  --source-name: list<string> # Name of the data source
  --entity: string@entity-completer # Source entity type.
  --sensor-type: string@sensor-type-completer # Type of Sensor
  --model-name: list<string> # Model Name of Sensor
  --manufacturer-name: list<string> # Manufacturer of Sensor
  --dump-raw: oneof<nothing, bool> # default: false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/latest/{location_id}"
    path_params: [{name: location_id, var: location_id}]
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: has_geo, var: has_geo}, {name: parameter_id, var: parameter_id}, {name: parameter, var: parameter, style: multi}, {name: unit, var: unit, style: multi}, {name: coordinates, var: coordinates}, {name: radius, var: radius}, {name: country_id, var: country_id}, {name: country, var: country, style: multi}, {name: city, var: city, style: multi}, {name: location, var: location, style: multi}, {name: order_by, var: order_by}, {name: isMobile, var: is_mobile}, {name: isAnalysis, var: is_analysis}, {name: sourceName, var: source_name, style: multi}, {name: entity, var: entity}, {name: sensorType, var: sensor_type}, {name: modelName, var: model_name, style: multi}, {name: manufacturerName, var: manufacturer_name, style: multi}, {name: dumpRaw, var: dump_raw}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, limit: $limit, page: $page, offset: $offset, sort: $sort, has_geo: $has_geo, parameter_id: $parameter_id, parameter: $parameter, unit: $unit, coordinates: $coordinates, radius: $radius, country_id: $country_id, country: $country, city: $city, location: $location, order_by: $order_by, is_mobile: $is_mobile, is_analysis: $is_analysis, source_name: $source_name, entity: $entity, sensor_type: $sensor_type, model_name: $model_name, manufacturer_name: $manufacturer_name, dump_raw: $dump_raw
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Locations Get
#
# GET /v2/locations
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>
# operationId: locations_get_v2_locations_get
export def "locations-get-v2-locations-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Sort Direction (default: desc)
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location-id: int
  --location: list
  --order-by: string@order-by-completer-2 # Order by a field (default: lastUpdated)
  --is-mobile: oneof<nothing, bool> # Location is mobile
  --is-analysis: oneof<nothing, bool> # Data is the product of a previous analysis/aggregation and not raw measurements
  --source-name: list<string> # Name of the data source
  --entity: string@entity-completer # Source entity type.
  --sensor-type: string@sensor-type-completer # Type of Sensor
  --model-name: list<string> # Model Name of Sensor
  --manufacturer-name: list<string> # Manufacturer of Sensor
  --dump-raw: oneof<nothing, bool> # default: false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/locations"
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: has_geo, var: has_geo}, {name: parameter_id, var: parameter_id}, {name: parameter, var: parameter, style: multi}, {name: unit, var: unit, style: multi}, {name: coordinates, var: coordinates}, {name: radius, var: radius}, {name: country_id, var: country_id}, {name: country, var: country, style: multi}, {name: city, var: city, style: multi}, {name: location_id, var: location_id}, {name: location, var: location, style: multi}, {name: order_by, var: order_by}, {name: isMobile, var: is_mobile}, {name: isAnalysis, var: is_analysis}, {name: sourceName, var: source_name, style: multi}, {name: entity, var: entity}, {name: sensorType, var: sensor_type}, {name: modelName, var: model_name, style: multi}, {name: manufacturerName, var: manufacturer_name, style: multi}, {name: dumpRaw, var: dump_raw}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, page: $page, offset: $offset, sort: $sort, has_geo: $has_geo, parameter_id: $parameter_id, parameter: $parameter, unit: $unit, coordinates: $coordinates, radius: $radius, country_id: $country_id, country: $country, city: $city, location_id: $location_id, location: $location, order_by: $order_by, is_mobile: $is_mobile, is_analysis: $is_analysis, source_name: $source_name, entity: $entity, sensor_type: $sensor_type, model_name: $model_name, manufacturer_name: $manufacturer_name, dump_raw: $dump_raw
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mobilegentilejson
#
# GET /v2/locations/tiles/mobile-generalized/tiles.json
# Returns: record<attribution: string, bounds: list<float>, data: list<string>, description: string, grids: list<string>, legend: string, maxzoom: int, minzoom: int, name: string, scheme: string, template: string, tilejson: string, tiles: list<string>, version: string>
# operationId: mobilegentilejson_v2_locations_tiles_mobile_generalized_tiles_json_get
export def "mobilegentilejson-v2-locations-tiles-mobile-generalized-tiles-json-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/v2/locations/tiles/mobile-generalized/tiles.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Mobilegentile
#
# GET /v2/locations/tiles/mobile-generalized/{z}/{x}/{y}.pbf
# operationId: get_mobilegentile_v2_locations_tiles_mobile_generalized__z___x___y__pbf_get
export def "get-mobilegentile-v2-locations-tiles-mobile-generalized-z-x-y-pbf-get" [
  z: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameter: string
  --location: list<int> # limit data to location id
  --last-updated-from: string
  --last-updated-to: string
  --is-mobile: oneof<nothing, bool>
  --project: int
  --is-analysis: oneof<nothing, bool>
]: nothing -> any {
  http-request {
    method: get
    path: "/v2/locations/tiles/mobile-generalized/{z}/{x}/{y}.pbf"
    path_params: [{name: z, var: z}, {name: x, var: x}, {name: y, var: y}]
    query: [{name: parameter, var: parameter}, {name: location, var: location, style: multi}, {name: lastUpdatedFrom, var: last_updated_from}, {name: lastUpdatedTo, var: last_updated_to}, {name: isMobile, var: is_mobile}, {name: project, var: project}, {name: isAnalysis, var: is_analysis}]
    accept: ["application/x-protobuf"]
    ok: [200]
    auth: bearer
  } {
    z: $z, x: $x, y: $y, parameter: $parameter, location: $location, last_updated_from: $last_updated_from, last_updated_to: $last_updated_to, is_mobile: $is_mobile, project: $project, is_analysis: $is_analysis
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mobiletilejson
#
# GET /v2/locations/tiles/mobile/tiles.json
# Returns: record<attribution: string, bounds: list<float>, data: list<string>, description: string, grids: list<string>, legend: string, maxzoom: int, minzoom: int, name: string, scheme: string, template: string, tilejson: string, tiles: list<string>, version: string>
# operationId: mobiletilejson_v2_locations_tiles_mobile_tiles_json_get
export def "mobiletilejson-v2-locations-tiles-mobile-tiles-json-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/v2/locations/tiles/mobile/tiles.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Mobiletile
#
# GET /v2/locations/tiles/mobile/{z}/{x}/{y}.pbf
# operationId: get_mobiletile_v2_locations_tiles_mobile__z___x___y__pbf_get
export def "get-mobiletile-v2-locations-tiles-mobile-z-x-y-pbf-get" [
  z: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # required
  --date-to: string # required
  --parameter: string
  --location: list<int> # limit data to location id
  --last-updated-from: string
  --last-updated-to: string
  --is-mobile: oneof<nothing, bool>
  --project: int
  --is-analysis: oneof<nothing, bool>
]: nothing -> any {
  http-request {
    method: get
    path: "/v2/locations/tiles/mobile/{z}/{x}/{y}.pbf"
    path_params: [{name: z, var: z}, {name: x, var: x}, {name: y, var: y}]
    query: [{name: dateFrom, var: date_from, required: true}, {name: dateTo, var: date_to, required: true}, {name: parameter, var: parameter}, {name: location, var: location, style: multi}, {name: lastUpdatedFrom, var: last_updated_from}, {name: lastUpdatedTo, var: last_updated_to}, {name: isMobile, var: is_mobile}, {name: project, var: project}, {name: isAnalysis, var: is_analysis}]
    accept: ["application/x-protobuf"]
    ok: [200]
    auth: bearer
  } {
    z: $z, x: $x, y: $y, date_from: $date_from, date_to: $date_to, parameter: $parameter, location: $location, last_updated_from: $last_updated_from, last_updated_to: $last_updated_to, is_mobile: $is_mobile, project: $project, is_analysis: $is_analysis
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tilejson
#
# GET /v2/locations/tiles/tiles.json
# Returns: record<attribution: string, bounds: list<float>, data: list<string>, description: string, grids: list<string>, legend: string, maxzoom: int, minzoom: int, name: string, scheme: string, template: string, tilejson: string, tiles: list<string>, version: string>
# operationId: tilejson_v2_locations_tiles_tiles_json_get
export def "tilejson-v2-locations-tiles-tiles-json-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/v2/locations/tiles/tiles.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Demo
#
# GET /v2/locations/tiles/viewer
# Returns: string
# operationId: demo_v2_locations_tiles_viewer_get
export def "demo-v2-locations-tiles-viewer-get" [
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
    path: "/v2/locations/tiles/viewer"
    accept: ["text/html"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Tile
#
# GET /v2/locations/tiles/{z}/{x}/{y}.pbf
# operationId: get_tile_v2_locations_tiles__z___x___y__pbf_get
export def "get-tile-v2-locations-tiles-z-x-y-pbf-get" [
  z: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameter: string
  --location: list<int> # limit data to location id
  --last-updated-from: string
  --last-updated-to: string
  --is-mobile: oneof<nothing, bool>
  --project: int
  --is-analysis: oneof<nothing, bool>
]: nothing -> any {
  http-request {
    method: get
    path: "/v2/locations/tiles/{z}/{x}/{y}.pbf"
    path_params: [{name: z, var: z}, {name: x, var: x}, {name: y, var: y}]
    query: [{name: parameter, var: parameter}, {name: location, var: location, style: multi}, {name: lastUpdatedFrom, var: last_updated_from}, {name: lastUpdatedTo, var: last_updated_to}, {name: isMobile, var: is_mobile}, {name: project, var: project}, {name: isAnalysis, var: is_analysis}]
    accept: ["application/x-protobuf"]
    ok: [200]
    auth: bearer
  } {
    z: $z, x: $x, y: $y, parameter: $parameter, location: $location, last_updated_from: $last_updated_from, last_updated_to: $last_updated_to, is_mobile: $is_mobile, project: $project, is_analysis: $is_analysis
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Locations Get
#
# GET /v2/locations/{location_id}
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>
# operationId: locations_get_v2_locations__location_id__get
export def "locations-get-v2-locations-location-id-get" [
  location_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Sort Direction (default: desc)
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location: list
  --order-by: string@order-by-completer-2 # Order by a field (default: lastUpdated)
  --is-mobile: oneof<nothing, bool> # Location is mobile
  --is-analysis: oneof<nothing, bool> # Data is the product of a previous analysis/aggregation and not raw measurements
  --source-name: list<string> # Name of the data source
  --entity: string@entity-completer # Source entity type.
  --sensor-type: string@sensor-type-completer # Type of Sensor
  --model-name: list<string> # Model Name of Sensor
  --manufacturer-name: list<string> # Manufacturer of Sensor
  --dump-raw: oneof<nothing, bool> # default: false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/locations/{location_id}"
    path_params: [{name: location_id, var: location_id}]
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: has_geo, var: has_geo}, {name: parameter_id, var: parameter_id}, {name: parameter, var: parameter, style: multi}, {name: unit, var: unit, style: multi}, {name: coordinates, var: coordinates}, {name: radius, var: radius}, {name: country_id, var: country_id}, {name: country, var: country, style: multi}, {name: city, var: city, style: multi}, {name: location, var: location, style: multi}, {name: order_by, var: order_by}, {name: isMobile, var: is_mobile}, {name: isAnalysis, var: is_analysis}, {name: sourceName, var: source_name, style: multi}, {name: entity, var: entity}, {name: sensorType, var: sensor_type}, {name: modelName, var: model_name, style: multi}, {name: manufacturerName, var: manufacturer_name, style: multi}, {name: dumpRaw, var: dump_raw}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, limit: $limit, page: $page, offset: $offset, sort: $sort, has_geo: $has_geo, parameter_id: $parameter_id, parameter: $parameter, unit: $unit, coordinates: $coordinates, radius: $radius, country_id: $country_id, country: $country, city: $city, location: $location, order_by: $order_by, is_mobile: $is_mobile, is_analysis: $is_analysis, source_name: $source_name, entity: $entity, sensor_type: $sensor_type, model_name: $model_name, manufacturer_name: $manufacturer_name, dump_raw: $dump_raw
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mfr Get
#
# GET /v2/manufacturers
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>
# operationId: mfr_get_v2_manufacturers_get
export def "mfr-get-v2-manufacturers-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/v2/manufacturers"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Measurements Get
#
# GET /v2/measurements
# operationId: measurements_get_v2_measurements_get
export def "measurements-get-v2-measurements-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string
  --date-from: string # default: 2000-01-01T00:00:00+00:00
  --date-to: string # default: 2021-08-23T09:48:00+00:00
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # default: desc
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location-id: int
  --location: list
  --order-by: string@order-by-completer-3 # default: datetime
  --is-mobile: oneof<nothing, bool>
  --is-analysis: oneof<nothing, bool>
  --project: int
  --entity: string@entity-completer
  --sensor-type: string@sensor-type-completer
  --value-from: float
  --value-to: float
  --include-fields: string
]: nothing -> any {
  http-request {
    method: get
    path: "/v2/measurements"
    query: [{name: format, var: format}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: has_geo, var: has_geo}, {name: parameter_id, var: parameter_id}, {name: parameter, var: parameter, style: multi}, {name: unit, var: unit, style: multi}, {name: coordinates, var: coordinates}, {name: radius, var: radius}, {name: country_id, var: country_id}, {name: country, var: country, style: multi}, {name: city, var: city, style: multi}, {name: location_id, var: location_id}, {name: location, var: location, style: multi}, {name: order_by, var: order_by}, {name: isMobile, var: is_mobile}, {name: isAnalysis, var: is_analysis}, {name: project, var: project}, {name: entity, var: entity}, {name: sensorType, var: sensor_type}, {name: value_from, var: value_from}, {name: value_to, var: value_to}, {name: include_fields, var: include_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    format: $format, date_from: $date_from, date_to: $date_to, limit: $limit, page: $page, offset: $offset, sort: $sort, has_geo: $has_geo, parameter_id: $parameter_id, parameter: $parameter, unit: $unit, coordinates: $coordinates, radius: $radius, country_id: $country_id, country: $country, city: $city, location_id: $location_id, location: $location, order_by: $order_by, is_mobile: $is_mobile, is_analysis: $is_analysis, project: $project, entity: $entity, sensor_type: $sensor_type, value_from: $value_from, value_to: $value_to, include_fields: $include_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Model Get
#
# GET /v2/models
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>
# operationId: model_get_v2_models_get
export def "model-get-v2-models-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/v2/models"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Parameters Get
#
# GET /v2/parameters
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<description: string, displayName: string, id: int, isCore: bool, maxColorValue: float, name: string, preferredUnit: string>>
# operationId: parameters_get_v2_parameters_get
export def "parameters-get-v2-parameters-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Define sort order. (default: asc)
  --source-name: list<string>
  --source-id: list<int>
  --source-slug: list<string>
  --order-by: string # default: id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/parameters"
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: sourceName, var: source_name, style: multi}, {name: sourceId, var: source_id, style: multi}, {name: sourceSlug, var: source_slug, style: multi}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, page: $page, offset: $offset, sort: $sort, source_name: $source_name, source_id: $source_id, source_slug: $source_slug, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Projects Get
#
# GET /v2/projects
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<bbox: list, countries: list, entity: string, firstUpdated: string, id: int, isAnalysis: bool, isMobile: bool, lastUpdated: string, locationIds: list, locations: int, measurements: int, name: string, parameters: list, sensorType: string, sources: list, subtitle: string>>
# operationId: projects_get_v2_projects_get
export def "projects-get-v2-projects-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Define sort order. (default: asc)
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --project-id: int
  --project: list
  --order-by: string@order-by-completer-5 # default: lastUpdated
  --is-mobile: oneof<nothing, bool>
  --is-analysis: oneof<nothing, bool>
  --entity: string
  --sensor-type: string
  --source-name: list<string>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/projects"
    query: [{name: country_id, var: country_id}, {name: country, var: country, style: multi}, {name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: parameter_id, var: parameter_id}, {name: parameter, var: parameter, style: multi}, {name: unit, var: unit, style: multi}, {name: project_id, var: project_id}, {name: project, var: project, style: multi}, {name: order_by, var: order_by}, {name: isMobile, var: is_mobile}, {name: isAnalysis, var: is_analysis}, {name: entity, var: entity}, {name: sensorType, var: sensor_type}, {name: sourceName, var: source_name, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country_id: $country_id, country: $country, limit: $limit, page: $page, offset: $offset, sort: $sort, parameter_id: $parameter_id, parameter: $parameter, unit: $unit, project_id: $project_id, project: $project, order_by: $order_by, is_mobile: $is_mobile, is_analysis: $is_analysis, entity: $entity, sensor_type: $sensor_type, source_name: $source_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Projects Get
#
# GET /v2/projects/{project_id}
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<bbox: list, countries: list, entity: string, firstUpdated: string, id: int, isAnalysis: bool, isMobile: bool, lastUpdated: string, locationIds: list, locations: int, measurements: int, name: string, parameters: list, sensorType: string, sources: list, subtitle: string>>
# operationId: projects_get_v2_projects__project_id__get
export def "projects-get-v2-projects-project-id-get" [
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
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Define sort order. (default: asc)
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --project: list
  --order-by: string@order-by-completer-5 # default: lastUpdated
  --is-mobile: oneof<nothing, bool>
  --is-analysis: oneof<nothing, bool>
  --entity: string
  --sensor-type: string
  --source-name: list<string>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/projects/{project_id}"
    path_params: [{name: project_id, var: project_id}]
    query: [{name: country_id, var: country_id}, {name: country, var: country, style: multi}, {name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: parameter_id, var: parameter_id}, {name: parameter, var: parameter, style: multi}, {name: unit, var: unit, style: multi}, {name: project, var: project, style: multi}, {name: order_by, var: order_by}, {name: isMobile, var: is_mobile}, {name: isAnalysis, var: is_analysis}, {name: entity, var: entity}, {name: sensorType, var: sensor_type}, {name: sourceName, var: source_name, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, country_id: $country_id, country: $country, limit: $limit, page: $page, offset: $offset, sort: $sort, parameter_id: $parameter_id, parameter: $parameter, unit: $unit, project: $project, order_by: $order_by, is_mobile: $is_mobile, is_analysis: $is_analysis, entity: $entity, sensor_type: $sensor_type, source_name: $source_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sources Get
#
# GET /v2/sources
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>
# operationId: sources_get_v2_sources_get
export def "sources-get-v2-sources-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --sort: string@sort-completer # Define sort order. (default: asc)
  --source-name: list<string>
  --source-id: list<int>
  --source-slug: list<string>
  --order-by: string@order-by-completer-6 # default: sourceName
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/sources"
    query: [{name: limit, var: limit}, {name: page, var: page}, {name: offset, var: offset}, {name: sort, var: sort}, {name: sourceName, var: source_name, style: multi}, {name: sourceId, var: source_id, style: multi}, {name: sourceSlug, var: source_slug, style: multi}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, page: $page, offset: $offset, sort: $sort, source_name: $source_name, source_id: $source_id, source_slug: $source_slug, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Readme Get
#
# GET /v2/sources/readme/{slug}
# operationId: readme_get_v2_sources_readme__slug__get
export def "readme-get-v2-sources-readme-slug-get" [
  slug: string
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
    path: "/v2/sources/readme/{slug}"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Summary Get
#
# GET /v2/summary
# Returns: record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>>
# operationId: summary_get_v2_summary_get
export def "summary-get-v2-summary-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/v2/summary"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
