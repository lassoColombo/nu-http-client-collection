# Auto-generated client for VictorOps v0.0.3
# Source: https://api.apis.guru/v2/specs/victorops.com/0.0.3/swagger.json
# Auth: --token flag or $env.VICTOROPS_TOKEN

const CLIENT = {
  base_url: "https://api.victorops.com"
  token_env_var: "VICTOROPS_TOKEN"
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

def base-url-completer [] { ["https://api.victorops.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["RoutingKeys"] }
def timeout-completer [] { ["1" "10" "15" "20" "25" "30" "45" "5" "60"] }
def type-completer-1 [] { ["email" "phone" "push" "sms"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-api-public-v1-alerts-uuid: "record<ackAuthor: string, ackMsg: string, entityDisplayName: string, entityId: string, messageType: string, monitoringTool: string, raw: string, stateMessage: string, stateStartTime: float, timestamp: float>"
    get-api-public-v1-incidents: "record<incidents: table<alertCount: float, currentPhase: string, entityId: string, host: string, incidentNumber: string, lastAlertId: string, lastAlertTime: string, pagedPolicies: list, pagedTeams: list, pagedUsers: list, service: string, startTime: string, transitions: list>>"
    post-api-public-v1-incidents: "record<error: string, incidentNumber: string>"
    patch-api-public-v1-incidents-ack: "record<results: table<cmdAccepted: bool, entityId: string, incidentNumber: string, message: string>>"
    patch-api-public-v1-incidents-by-user-ack: "record<results: table<cmdAccepted: bool, entityId: string, incidentNumber: string, message: string>>"
    patch-api-public-v1-incidents-by-user-resolve: "record<results: table<cmdAccepted: bool, entityId: string, incidentNumber: string, message: string>>"
    post-api-public-v1-incidents-reroute: "record<statuses: table<incidentNumber: string, message: string, success: bool, targetStatus: list>>"
    patch-api-public-v1-incidents-resolve: "record<results: table<cmdAccepted: bool, entityId: string, incidentNumber: string, message: string>>"
    get-api-public-v1-maintenancemode: "record<activeInstances: table<instanceId: string, isGlobal: bool, startedAt: float, startedBy: string, targets: list>, companyId: string>"
    post-api-public-v1-maintenancemode-start: "record<activeInstances: table<instanceId: string, isGlobal: bool, startedAt: float, startedBy: string, targets: list>, companyId: string>"
    put-api-public-v1-maintenancemode-maintenancemodeid-end: "record<activeInstances: table<instanceId: string, isGlobal: bool, startedAt: float, startedBy: string, targets: list>, companyId: string>"
    get-api-public-v1-oncall-current: "record<teamsOnCall: table<onCallNow: list, team: record>>"
    get-api-public-v1-org-routing-keys: "record<_selfUrl: string, routingKeys: table<isDefault: bool, routingKey: string, targets: list>>"
    get-api-public-v1-overrides: "record<_selfUrl: string, overrides: table<assignments: list, end: string, publicId: string, start: string, timezone: string, user: record>>"
    post-api-public-v1-overrides: "record<_selfUrl: string, schedule: record<assignments: list<record>, end: string, publicId: string, start: string, timezone: string, user: record<firstName: string, lastName: string, username: string>>>"
    get-api-public-v1-overrides-public-id: "record<_selfUrl: string, override: record<assignments: list<record>, end: string, publicId: string, start: string, timezone: string, user: record<firstName: string, lastName: string, username: string>>>"
    get-api-public-v1-overrides-public-id-assignments: "table<_selfUrl: string, assigned: bool, policy: string, team: string, user: string>"
    delete-api-public-v1-overrides-public-id-assignments-policy-slug: "record<_selfUrl: string, assigned: bool, policy: string, team: string, user: string>"
    get-api-public-v1-overrides-public-id-assignments-policy-slug: "record<_selfUrl: string, assigned: bool, policy: string, team: string, user: string>"
    put-api-public-v1-overrides-public-id-assignments-policy-slug: "record<_selfUrl: string, assigned: bool, policy: string, team: string, user: string>"
    get-api-public-v1-policies: "record<policies: table<policy: record, team: record>>"
    get-api-public-v1-policies-types-contacts: "record<_selfUrl: string, contactTypes: table<description: string, type: string>>"
    get-api-public-v1-policies-types-notifications: "record<_selfUrl: string, notificationTypes: table<description: string, type: string>>"
    get-api-public-v1-policies-types-timeouts: "record<_selfUrl: string, timeoutTypes: table<description: string, type: int>>"
    patch-api-public-v1-policies-policy-oncall-user: "record<result: string>"
    get-api-public-v1-profile-username-policies: "record<_selfUrl: string, steps: table<index: float, rules: list, timeout: int>>"
    post-api-public-v1-profile-username-policies: "record<_selfUrl: string, step: record<index: float, rules: list<record>, timeout: int>>"
    get-api-public-v1-profile-username-policies-step: "record<_selfUrl: string, step: record<index: float, rules: list<record>, timeout: int>>"
    post-api-public-v1-profile-username-policies-step: "record<_selfUrl: string, stepRule: record<contact: record<id: float, type: string>, index: float, type: string>>"
    put-api-public-v1-profile-username-policies-step: "record<_selfUrl: string, step: record<index: float, rules: list<record>, timeout: int>>"
    delete-api-public-v1-profile-username-policies-step-rule: "record<_selfUrl: string, stepRule: record<contact: record<id: float, type: string>, index: float, type: string>>"
    get-api-public-v1-profile-username-policies-step-rule: "record<_selfUrl: string, stepRule: record<contact: record<id: float, type: string>, index: float, type: string>>"
    put-api-public-v1-profile-username-policies-step-rule: "record<_selfUrl: string, stepRule: record<contact: record<id: float, type: string>, index: float, type: string>>"
    get-api-public-v1-team: "table<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, isDefaultTeam: bool, memberCount: float, name: string, slug: string, version: float>"
    post-api-public-v1-team: "record<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, isDefaultTeam: bool, memberCount: float, name: string, slug: string, version: float>"
    get-api-public-v1-team-team: "record<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, isDefaultTeam: bool, memberCount: float, name: string, slug: string, version: float>"
    put-api-public-v1-team-team: "record<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, isDefaultTeam: bool, memberCount: float, name: string, slug: string, version: float>"
    get-api-public-v1-team-team-admins: "record<teamAdmins: table<_selfUrl: string, firstName: string, lastName: string, username: string>>"
    get-api-public-v1-team-team-members: "record<_selfUrl: string, _teamUrl: string, members: table<firstName: string, lastName: string, username: string, verified: string, version: float>>"
    post-api-public-v1-team-team-members: "record<_selfUrl: string, _teamUrl: string, members: table<firstName: string, lastName: string, username: string, verified: string, version: float>>"
    get-api-public-v1-team-team-oncall-schedule: "record<overrides: table<end: float, orig: string, over: string, start: float>, schedule: table<oncall: string, overrideoncall: string, policyType: string, rolls: list, rotationName: string, shiftName: string, shiftRoll: float>, team: string>"
    patch-api-public-v1-team-team-oncall-user: "record<result: string>"
    get-api-public-v1-team-team-policies: "record<policies: table<name: string, slug: string>>"
    get-api-public-v1-user: "record<_selfUrl: string, users: table<_selfUrl: string, createdAt: string, email: string, firstName: string, lastName: string, passwordLastUpdated: string, username: string, verified: bool>>"
    post-api-public-v1-user: "record<_selfUrl: string, createdAt: string, email: string, firstName: string, lastName: string, passwordLastUpdated: string, username: string, verified: bool>"
    get-api-public-v1-user-user: "record<_selfUrl: string, createdAt: string, email: string, firstName: string, lastName: string, passwordLastUpdated: string, username: string, verified: bool>"
    put-api-public-v1-user-user: "record<_selfUrl: string, createdAt: string, email: string, firstName: string, lastName: string, passwordLastUpdated: string, username: string, verified: bool>"
    get-api-public-v1-user-user-contact-methods: "record<devices: table<_selfUrl: string, deviceType: string, extId: string, label: string>, emails: table<_selfUrl: string, deviceType: string, extId: string, label: string>, phones: table<_selfUrl: string, deviceType: string, extId: string, label: string>>"
    get-api-public-v1-user-user-contact-methods-devices: "table<_selfUrl: string, deviceType: string, extId: string, label: string>"
    delete-api-public-v1-user-user-contact-methods-devices-contact-id: "record<_selfUrl: string, deviceType: string, extId: string, label: string>"
    get-api-public-v1-user-user-contact-methods-devices-contact-id: "table<_selfUrl: string, deviceType: string, extId: string, label: string>"
    put-api-public-v1-user-user-contact-methods-devices-contact-id: "record<_selfUrl: string, deviceType: string, extId: string, label: string>"
    get-api-public-v1-user-user-contact-methods-emails: "table<_selfUrl: string, deviceType: string, extId: string, label: string>"
    post-api-public-v1-user-user-contact-methods-emails: "record<_selfUrl: string, deviceType: string, extId: string, label: string>"
    delete-api-public-v1-user-user-contact-methods-emails-contact-id: "record<_selfUrl: string, deviceType: string, extId: string, label: string>"
    get-api-public-v1-user-user-contact-methods-emails-contact-id: "table<_selfUrl: string, deviceType: string, extId: string, label: string>"
    get-api-public-v1-user-user-contact-methods-phones: "table<_selfUrl: string, deviceType: string, extId: string, label: string>"
    post-api-public-v1-user-user-contact-methods-phones: "record<_selfUrl: string, deviceType: string, extId: string, label: string>"
    delete-api-public-v1-user-user-contact-methods-phones-contact-id: "record<_selfUrl: string, deviceType: string, extId: string, label: string>"
    get-api-public-v1-user-user-contact-methods-phones-contact-id: "table<_selfUrl: string, deviceType: string, extId: string, label: string>"
    get-api-public-v1-user-user-oncall-schedule: "table<overrides: list<record>, schedule: list<record>, team: string>"
    get-api-public-v1-user-user-policies: "record<policies: table<contactType: string, extId: string, order: int, timeout: int>, userId: int, username: string>"
    get-api-public-v1-user-user-teams: "record<teams: table<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, name: string, slug: string>>"
    get-api-public-v2-team-team-oncall-schedule: "record<schedules: table<overrides: list, policy: record, schedule: list>, team: record<name: string, slug: string>>"
    get-api-public-v2-user-user-oncall-schedule: "record<teamSchedules: table<schedules: list, team: record>>"
    get-api-reporting-v1-incidents: "table<incidents: list<record>, limit: float, offset: float, total: float>"
    get-api-reporting-v1-team-team-oncall-log: "record<end: string, start: string, teamSlug: string, userLogs: table<adjustedTotal: record, log: list, total: record, userId: string>>"
    get-api-reporting-v2-incidents: "record<incidents: table<alertCount: float, currentPhase: string, entityId: string, host: string, incidentNumber: string, lastAlertId: string, lastAlertTime: string, pagedPolicies: list, pagedTeams: list, pagedUsers: list, service: string, startTime: string, transitions: list>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-api-public-v1-alerts-uuid" "get-api-public-v1-incidents" "post-api-public-v1-incidents" "patch-api-public-v1-incidents-ack" "patch-api-public-v1-incidents-by-user-ack" "patch-api-public-v1-incidents-by-user-resolve" "post-api-public-v1-incidents-reroute" "patch-api-public-v1-incidents-resolve" "get-api-public-v1-maintenancemode" "post-api-public-v1-maintenancemode-start" "put-api-public-v1-maintenancemode-maintenancemodeid-end" "get-api-public-v1-oncall-current" "get-api-public-v1-org-routing-keys" "get-api-public-v1-overrides" "post-api-public-v1-overrides" "delete-api-public-v1-overrides-public-id" "get-api-public-v1-overrides-public-id" "get-api-public-v1-overrides-public-id-assignments" "delete-api-public-v1-overrides-public-id-assignments-policy-slug" "get-api-public-v1-overrides-public-id-assignments-policy-slug" "put-api-public-v1-overrides-public-id-assignments-policy-slug" "get-api-public-v1-policies" "get-api-public-v1-policies-types-contacts" "get-api-public-v1-policies-types-notifications" "get-api-public-v1-policies-types-timeouts" "patch-api-public-v1-policies-policy-oncall-user" "get-api-public-v1-profile-username-policies" "post-api-public-v1-profile-username-policies" "get-api-public-v1-profile-username-policies-step" "post-api-public-v1-profile-username-policies-step" "put-api-public-v1-profile-username-policies-step" "delete-api-public-v1-profile-username-policies-step-rule" "get-api-public-v1-profile-username-policies-step-rule" "put-api-public-v1-profile-username-policies-step-rule" "get-api-public-v1-team" "post-api-public-v1-team" "delete-api-public-v1-team-team" "get-api-public-v1-team-team" "put-api-public-v1-team-team" "get-api-public-v1-team-team-admins" "get-api-public-v1-team-team-members" "post-api-public-v1-team-team-members" "delete-api-public-v1-team-team-members-user" "get-api-public-v1-team-team-oncall-schedule" "patch-api-public-v1-team-team-oncall-user" "get-api-public-v1-team-team-policies" "get-api-public-v1-user" "post-api-public-v1-user" "delete-api-public-v1-user-user" "get-api-public-v1-user-user" "put-api-public-v1-user-user" "get-api-public-v1-user-user-contact-methods" "get-api-public-v1-user-user-contact-methods-devices" "delete-api-public-v1-user-user-contact-methods-devices-contact-id" "get-api-public-v1-user-user-contact-methods-devices-contact-id" "put-api-public-v1-user-user-contact-methods-devices-contact-id" "get-api-public-v1-user-user-contact-methods-emails" "post-api-public-v1-user-user-contact-methods-emails" "delete-api-public-v1-user-user-contact-methods-emails-contact-id" "get-api-public-v1-user-user-contact-methods-emails-contact-id" "get-api-public-v1-user-user-contact-methods-phones" "post-api-public-v1-user-user-contact-methods-phones" "delete-api-public-v1-user-user-contact-methods-phones-contact-id" "get-api-public-v1-user-user-contact-methods-phones-contact-id" "get-api-public-v1-user-user-oncall-schedule" "get-api-public-v1-user-user-policies" "get-api-public-v1-user-user-teams" "get-api-public-v2-team-team-oncall-schedule" "get-api-public-v2-user-user-oncall-schedule" "get-api-reporting-v1-incidents" "get-api-reporting-v1-team-team-oncall-log" "get-api-reporting-v2-incidents" "commands"] | sort) } | get name | first)
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

# Retrieve alert details.
#
# GET /api-public/v1/alerts/{uuid}
# Returns: record<ackAuthor: string, ackMsg: string, entityDisplayName: string, entityId: string, messageType: string, monitoringTool: string, raw: string, stateMessage: string, stateStartTime: float, timestamp: float>
export def "get-api-public-v1-alerts-uuid" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/alerts/{uuid}"
    path_params: [{name: uuid, var: uuid}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    uuid: $uuid, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get current incident information
#
# GET /api-public/v1/incidents
# Returns: record<incidents: table<alertCount: float, currentPhase: string, entityId: string, host: string, incidentNumber: string, lastAlertId: string, lastAlertTime: string, pagedPolicies: list, pagedTeams: list, pagedUsers: list, service: string, startTime: string, transitions: list>>
export def "get-api-public-v1-incidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/incidents"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new incident
#
# POST /api-public/v1/incidents
# Returns: record<error: string, incidentNumber: string>
export def "post-api-public-v1-incidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  details: string
  summary: string
  targets: list # item shape: {slug: string, type: "User"|"EscalationPolicy"}
  user_name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api-public/v1/incidents"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: details, var: details}, {name: summary, var: summary}, {name: targets, var: targets}, {name: userName, var: user_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, details: $details, summary: $summary, targets: $targets, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Acknowledge an incident or list of incidents
#
# PATCH /api-public/v1/incidents/ack
# Returns: record<results: table<cmdAccepted: bool, entityId: string, incidentNumber: string, message: string>>
export def "patch-api-public-v1-incidents-ack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  incident_names: list<string>
  --message: string
  user_name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api-public/v1/incidents/ack"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: incidentNames, var: incident_names}, {name: message, var: message}, {name: userName, var: user_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, incident_names: $incident_names, message: $message, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Acknowledge all incidents for which a user was paged.
#
# PATCH /api-public/v1/incidents/byUser/ack
# Returns: record<results: table<cmdAccepted: bool, entityId: string, incidentNumber: string, message: string>>
export def "patch-api-public-v1-incidents-by-user-ack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  --message: string
  user_name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api-public/v1/incidents/byUser/ack"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: userName, var: user_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, message: $message, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resolve all incidents for which a user was paged.
#
# PATCH /api-public/v1/incidents/byUser/resolve
# Returns: record<results: table<cmdAccepted: bool, entityId: string, incidentNumber: string, message: string>>
export def "patch-api-public-v1-incidents-by-user-resolve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  --message: string
  user_name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api-public/v1/incidents/byUser/resolve"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: userName, var: user_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, message: $message, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reroute one or more incidents to one or more new routable destinations.
#
# POST /api-public/v1/incidents/reroute
# Returns: record<statuses: table<incidentNumber: string, message: string, success: bool, targetStatus: list>>
export def "post-api-public-v1-incidents-reroute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  reroutes: list # item shape: {incidentNumber: string, targets: list}
  user_name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api-public/v1/incidents/reroute"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: reroutes, var: reroutes}, {name: userName, var: user_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, reroutes: $reroutes, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resolve an incident or list of incidents
#
# PATCH /api-public/v1/incidents/resolve
# Returns: record<results: table<cmdAccepted: bool, entityId: string, incidentNumber: string, message: string>>
export def "patch-api-public-v1-incidents-resolve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  incident_names: list<string>
  --message: string
  user_name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api-public/v1/incidents/resolve"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: incidentNames, var: incident_names}, {name: message, var: message}, {name: userName, var: user_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, incident_names: $incident_names, message: $message, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an organization's current maintenance mode state
#
# GET /api-public/v1/maintenancemode
# Returns: record<activeInstances: table<instanceId: string, isGlobal: bool, startedAt: float, startedBy: string, targets: list>, companyId: string>
export def "get-api-public-v1-maintenancemode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/maintenancemode"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start maintenance mode for routing keys
#
# POST /api-public/v1/maintenancemode/start
# Returns: record<activeInstances: table<instanceId: string, isGlobal: bool, startedAt: float, startedBy: string, targets: list>, companyId: string>
export def "post-api-public-v1-maintenancemode-start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  --names: list<string> # Routing keys that maintenance mode state covers. An empty list indicates global maintenance mode
  --purpose: string # the reason for the maintenance mode
  --type: string@type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api-public/v1/maintenancemode/start"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: names, var: names}, {name: purpose, var: purpose}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, names: $names, purpose: $purpose, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# End maintenance mode for routing keys
#
# PUT /api-public/v1/maintenancemode/{maintenancemodeid}/end
# Returns: record<activeInstances: table<instanceId: string, isGlobal: bool, startedAt: float, startedBy: string, targets: list>, companyId: string>
export def "put-api-public-v1-maintenancemode-maintenancemodeid-end" [
  maintenancemodeid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/api-public/v1/maintenancemode/{maintenancemodeid}/end"
    path_params: [{name: maintenancemodeid, var: maintenancemodeid}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    maintenancemodeid: $maintenancemodeid, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an organization's on-call users
#
# GET /api-public/v1/oncall/current
# Returns: record<teamsOnCall: table<onCallNow: list, team: record>>
export def "get-api-public-v1-oncall-current" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/oncall/current"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List routing keys with associated teams
#
# GET /api-public/v1/org/routing-keys
# Returns: record<_selfUrl: string, routingKeys: table<isDefault: bool, routingKey: string, targets: list>>
export def "get-api-public-v1-org-routing-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/org/routing-keys"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the scheduled overrides
#
# GET /api-public/v1/overrides
# Returns: record<_selfUrl: string, overrides: table<assignments: list, end: string, publicId: string, start: string, timezone: string, user: record>>
export def "get-api-public-v1-overrides" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/overrides"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new scheduled override
#
# POST /api-public/v1/overrides
# Returns: record<_selfUrl: string, schedule: record<assignments: list<record>, end: string, publicId: string, start: string, timezone: string, user: record<firstName: string, lastName: string, username: string>>>
export def "post-api-public-v1-overrides" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  --end: string # The override end time (ISO 8601)
  --start: string # The override start time (ISO 8601)
  --timezone: string
  --username: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api-public/v1/overrides"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: end, var: end}, {name: start, var: start}, {name: timezone, var: timezone}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, end: $end, start: $start, timezone: $timezone, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a scheduled override
#
# DELETE /api-public/v1/overrides/{publicId}
export def "delete-api-public-v1-overrides-public-id" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api-public/v1/overrides/{publicId}"
    path_params: [{name: publicId, var: public_id}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    public_id: $public_id, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the specified scheduled override
#
# GET /api-public/v1/overrides/{publicId}
# Returns: record<_selfUrl: string, override: record<assignments: list<record>, end: string, publicId: string, start: string, timezone: string, user: record<firstName: string, lastName: string, username: string>>>
export def "get-api-public-v1-overrides-public-id" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/overrides/{publicId}"
    path_params: [{name: publicId, var: public_id}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    public_id: $public_id, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the specified scheduled override
#
# GET /api-public/v1/overrides/{publicId}/assignments
# Returns: table<_selfUrl: string, assigned: bool, policy: string, team: string, user: string>
export def "get-api-public-v1-overrides-public-id-assignments" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/overrides/{publicId}/assignments"
    path_params: [{name: publicId, var: public_id}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    public_id: $public_id, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the scheduled override assignment
#
# DELETE /api-public/v1/overrides/{publicId}/assignments/{policySlug}
# Returns: record<_selfUrl: string, assigned: bool, policy: string, team: string, user: string>
export def "delete-api-public-v1-overrides-public-id-assignments-policy-slug" [
  public_id: string
  policy_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api-public/v1/overrides/{publicId}/assignments/{policySlug}"
    path_params: [{name: publicId, var: public_id}, {name: policySlug, var: policy_slug}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    public_id: $public_id, policy_slug: $policy_slug, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the specified scheduled override assignment
#
# GET /api-public/v1/overrides/{publicId}/assignments/{policySlug}
# Returns: record<_selfUrl: string, assigned: bool, policy: string, team: string, user: string>
export def "get-api-public-v1-overrides-public-id-assignments-policy-slug" [
  public_id: string
  policy_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/overrides/{publicId}/assignments/{policySlug}"
    path_params: [{name: publicId, var: public_id}, {name: policySlug, var: policy_slug}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    public_id: $public_id, policy_slug: $policy_slug, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the scheduled override assignment
#
# PUT /api-public/v1/overrides/{publicId}/assignments/{policySlug}
# Returns: record<_selfUrl: string, assigned: bool, policy: string, team: string, user: string>
export def "put-api-public-v1-overrides-public-id-assignments-policy-slug" [
  public_id: string
  policy_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  policy: string # The policy slug
  --username: string # The username being assinged
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api-public/v1/overrides/{publicId}/assignments/{policySlug}"
    path_params: [{name: publicId, var: public_id}, {name: policySlug, var: policy_slug}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: policy, var: policy}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    public_id: $public_id, policy_slug: $policy_slug, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, policy: $policy, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get escalation policy info
#
# GET /api-public/v1/policies
# Returns: record<policies: table<policy: record, team: record>>
export def "get-api-public-v1-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/policies"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the available contact types
#
# GET /api-public/v1/policies/types/contacts
# Returns: record<_selfUrl: string, contactTypes: table<description: string, type: string>>
export def "get-api-public-v1-policies-types-contacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/policies/types/contacts"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the available notification types
#
# GET /api-public/v1/policies/types/notifications
# Returns: record<_selfUrl: string, notificationTypes: table<description: string, type: string>>
export def "get-api-public-v1-policies-types-notifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/policies/types/notifications"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the available timeout values
#
# GET /api-public/v1/policies/types/timeouts
# Returns: record<_selfUrl: string, timeoutTypes: table<description: string, type: int>>
export def "get-api-public-v1-policies-types-timeouts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/policies/types/timeouts"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an on-call override (take on-call)
#
# PATCH /api-public/v1/policies/{policy}/oncall/user
# Returns: record<result: string>
export def "patch-api-public-v1-policies-policy-oncall-user" [
  policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  from_user: string
  to_user: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api-public/v1/policies/{policy}/oncall/user"
    path_params: [{name: policy, var: policy}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: fromUser, var: from_user}, {name: toUser, var: to_user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy: $policy, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, from_user: $from_user, to_user: $to_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the user's paging policy
#
# GET /api-public/v1/profile/{username}/policies
# Returns: record<_selfUrl: string, steps: table<index: float, rules: list, timeout: int>>
export def "get-api-public-v1-profile-username-policies" [
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
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/profile/{username}/policies"
    path_params: [{name: username, var: username}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a paging policy step
#
# POST /api-public/v1/profile/{username}/policies
# Returns: record<_selfUrl: string, step: record<index: float, rules: list<record>, timeout: int>>
export def "post-api-public-v1-profile-username-policies" [
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
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  --rules: list # item shape: {contact?: record, type?: "push"|"email"|"sms"|"phone"}
  --timeout: int@timeout-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api-public/v1/profile/{username}/policies"
    path_params: [{name: username, var: username}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: rules, var: rules}, {name: timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, rules: $rules, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a paging policy step
#
# GET /api-public/v1/profile/{username}/policies/{step}
# Returns: record<_selfUrl: string, step: record<index: float, rules: list<record>, timeout: int>>
export def "get-api-public-v1-profile-username-policies-step" [
  username: string
  step: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/profile/{username}/policies/{step}"
    path_params: [{name: username, var: username}, {name: step, var: step}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, step: $step, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a rule for a paging policy step
#
# POST /api-public/v1/profile/{username}/policies/{step}
# Returns: record<_selfUrl: string, stepRule: record<contact: record<id: float, type: string>, index: float, type: string>>
export def "post-api-public-v1-profile-username-policies-step" [
  username: string
  step: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  --contact: record # shape: {id?: float, type?: "email"|"phone"}
  --type: string@type-completer-1 # e.g. email
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api-public/v1/profile/{username}/policies/{step}"
    path_params: [{name: username, var: username}, {name: step, var: step}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: contact, var: contact}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, step: $step, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, contact: $contact, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a paging policy step
#
# PUT /api-public/v1/profile/{username}/policies/{step}
# Returns: record<_selfUrl: string, step: record<index: float, rules: list<record>, timeout: int>>
export def "put-api-public-v1-profile-username-policies-step" [
  username: string
  step: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  --rules: list # item shape: {contact?: record, type?: "push"|"email"|"sms"|"phone"}
  --timeout: int@timeout-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api-public/v1/profile/{username}/policies/{step}"
    path_params: [{name: username, var: username}, {name: step, var: step}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: rules, var: rules}, {name: timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, step: $step, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, rules: $rules, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a rule from a paging policy step
#
# DELETE /api-public/v1/profile/{username}/policies/{step}/{rule}
# Returns: record<_selfUrl: string, stepRule: record<contact: record<id: float, type: string>, index: float, type: string>>
export def "delete-api-public-v1-profile-username-policies-step-rule" [
  username: string
  step: float
  rule: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api-public/v1/profile/{username}/policies/{step}/{rule}"
    path_params: [{name: username, var: username}, {name: step, var: step}, {name: rule, var: rule}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, step: $step, rule: $rule, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a rule from a paging policy step
#
# GET /api-public/v1/profile/{username}/policies/{step}/{rule}
# Returns: record<_selfUrl: string, stepRule: record<contact: record<id: float, type: string>, index: float, type: string>>
export def "get-api-public-v1-profile-username-policies-step-rule" [
  username: string
  step: float
  rule: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/profile/{username}/policies/{step}/{rule}"
    path_params: [{name: username, var: username}, {name: step, var: step}, {name: rule, var: rule}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, step: $step, rule: $rule, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a rule for a paging policy step
#
# PUT /api-public/v1/profile/{username}/policies/{step}/{rule}
# Returns: record<_selfUrl: string, stepRule: record<contact: record<id: float, type: string>, index: float, type: string>>
export def "put-api-public-v1-profile-username-policies-step-rule" [
  username: string
  step: float
  rule: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  --contact: record # shape: {id?: float, type?: "email"|"phone"}
  --type: string@type-completer-1 # e.g. email
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api-public/v1/profile/{username}/policies/{step}/{rule}"
    path_params: [{name: username, var: username}, {name: step, var: step}, {name: rule, var: rule}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: contact, var: contact}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, step: $step, rule: $rule, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, contact: $contact, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List teams
#
# GET /api-public/v1/team
# Returns: table<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, isDefaultTeam: bool, memberCount: float, name: string, slug: string, version: float>
export def "get-api-public-v1-team" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/team"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a team
#
# POST /api-public/v1/team
# Returns: record<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, isDefaultTeam: bool, memberCount: float, name: string, slug: string, version: float>
export def "post-api-public-v1-team" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api-public/v1/team"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a team
#
# DELETE /api-public/v1/team/{team}
export def "delete-api-public-v1-team-team" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api-public/v1/team/{team}"
    path_params: [{name: team, var: team}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team: $team, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve information for a team
#
# GET /api-public/v1/team/{team}
# Returns: record<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, isDefaultTeam: bool, memberCount: float, name: string, slug: string, version: float>
export def "get-api-public-v1-team-team" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/team/{team}"
    path_params: [{name: team, var: team}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team: $team, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a team
#
# PUT /api-public/v1/team/{team}
# Returns: record<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, isDefaultTeam: bool, memberCount: float, name: string, slug: string, version: float>
export def "put-api-public-v1-team-team" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api-public/v1/team/{team}"
    path_params: [{name: team, var: team}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team: $team, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of team admins for a team
#
# GET /api-public/v1/team/{team}/admins
# Returns: record<teamAdmins: table<_selfUrl: string, firstName: string, lastName: string, username: string>>
export def "get-api-public-v1-team-team-admins" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/team/{team}/admins"
    path_params: [{name: team, var: team}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team: $team, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of members for a team
#
# GET /api-public/v1/team/{team}/members
# Returns: record<_selfUrl: string, _teamUrl: string, members: table<firstName: string, lastName: string, username: string, verified: string, version: float>>
export def "get-api-public-v1-team-team-members" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/team/{team}/members"
    path_params: [{name: team, var: team}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team: $team, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a team member
#
# POST /api-public/v1/team/{team}/members
# Returns: record<_selfUrl: string, _teamUrl: string, members: table<firstName: string, lastName: string, username: string, verified: string, version: float>>
export def "post-api-public-v1-team-team-members" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  username: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api-public/v1/team/{team}/members"
    path_params: [{name: team, var: team}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team: $team, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a team member
#
# DELETE /api-public/v1/team/{team}/members/{user}
export def "delete-api-public-v1-team-team-members-user" [
  team: string
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  replacement: string
]: any -> any {
  $in | http-request {
    method: delete
    path: "/api-public/v1/team/{team}/members/{user}"
    path_params: [{name: team, var: team}, {name: user, var: user}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: replacement, var: replacement}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team: $team, user: $user, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, replacement: $replacement
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a team's on-call schedule
#
# GET /api-public/v1/team/{team}/oncall/schedule
# DEPRECATED
# Returns: record<overrides: table<end: float, orig: string, over: string, start: float>, schedule: table<oncall: string, overrideoncall: string, policyType: string, rolls: list, rotationName: string, shiftName: string, shiftRoll: float>, team: string>
@deprecated
export def "get-api-public-v1-team-team-oncall-schedule" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --days-forward: float # Days to include in returned schedule (30 max) (default: 14)
  --days-skip: float # Days to skip before computing schedule to return (90 max) (default: 0)
  --step: float # Step of escalation policy (3 max) (default: 0)
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/team/{team}/oncall/schedule"
    path_params: [{name: team, var: team}]
    query: [{name: daysForward, var: days_forward}, {name: daysSkip, var: days_skip}, {name: step, var: step}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team: $team, days_forward: $days_forward, days_skip: $days_skip, step: $step, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an on-call override (take on-call)
#
# PATCH /api-public/v1/team/{team}/oncall/user
# DEPRECATED
# Returns: record<result: string>
@deprecated
export def "patch-api-public-v1-team-team-oncall-user" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  from_user: string
  to_user: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api-public/v1/team/{team}/oncall/user"
    path_params: [{name: team, var: team}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: fromUser, var: from_user}, {name: toUser, var: to_user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team: $team, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, from_user: $from_user, to_user: $to_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of escalation policies for a team
#
# GET /api-public/v1/team/{team}/policies
# Returns: record<policies: table<name: string, slug: string>>
export def "get-api-public-v1-team-team-policies" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/team/{team}/policies"
    path_params: [{name: team, var: team}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team: $team, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List users
#
# GET /api-public/v1/user
# Returns: record<_selfUrl: string, users: table<_selfUrl: string, createdAt: string, email: string, firstName: string, lastName: string, passwordLastUpdated: string, username: string, verified: bool>>
export def "get-api-public-v1-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/user"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a user
#
# POST /api-public/v1/user
# Returns: record<_selfUrl: string, createdAt: string, email: string, firstName: string, lastName: string, passwordLastUpdated: string, username: string, verified: bool>
export def "post-api-public-v1-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  --admin: oneof<nothing, bool>
  email: string # format: email
  --expiration-hours: float # The validity duration for the invitatation/set password link sent to the added user. (default: 24)
  first_name: string
  last_name: string
  username: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api-public/v1/user"
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: admin, var: admin}, {name: email, var: email}, {name: expirationHours, var: expiration_hours}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, admin: $admin, email: $email, expiration_hours: $expiration_hours, first_name: $first_name, last_name: $last_name, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a user
#
# DELETE /api-public/v1/user/{user}
export def "delete-api-public-v1-user-user" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  --replacement: string # The user to take the place of the deleted user in escalations
]: any -> any {
  $in | http-request {
    method: delete
    path: "/api-public/v1/user/{user}"
    path_params: [{name: user, var: user}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: replacement, var: replacement}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, replacement: $replacement
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve information for a user
#
# GET /api-public/v1/user/{user}
# Returns: record<_selfUrl: string, createdAt: string, email: string, firstName: string, lastName: string, passwordLastUpdated: string, username: string, verified: bool>
export def "get-api-public-v1-user-user" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/user/{user}"
    path_params: [{name: user, var: user}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a user
#
# PUT /api-public/v1/user/{user}
# Returns: record<_selfUrl: string, createdAt: string, email: string, firstName: string, lastName: string, passwordLastUpdated: string, username: string, verified: bool>
export def "put-api-public-v1-user-user" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  --admin: oneof<nothing, bool>
  email: string # format: email
  --expiration-hours: float # The validity duration for the invitatation/set password link sent to the added user. (default: 24)
  first_name: string
  last_name: string
  username: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api-public/v1/user/{user}"
    path_params: [{name: user, var: user}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: admin, var: admin}, {name: email, var: email}, {name: expirationHours, var: expiration_hours}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, admin: $admin, email: $email, expiration_hours: $expiration_hours, first_name: $first_name, last_name: $last_name, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all contact methods for a user
#
# GET /api-public/v1/user/{user}/contact-methods
# Returns: record<devices: table<_selfUrl: string, deviceType: string, extId: string, label: string>, emails: table<_selfUrl: string, deviceType: string, extId: string, label: string>, phones: table<_selfUrl: string, deviceType: string, extId: string, label: string>>
export def "get-api-public-v1-user-user-contact-methods" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/user/{user}/contact-methods"
    path_params: [{name: user, var: user}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all contact devices for a user
#
# GET /api-public/v1/user/{user}/contact-methods/devices
# Returns: table<_selfUrl: string, deviceType: string, extId: string, label: string>
export def "get-api-public-v1-user-user-contact-methods-devices" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/user/{user}/contact-methods/devices"
    path_params: [{name: user, var: user}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a contact device for a user
#
# DELETE /api-public/v1/user/{user}/contact-methods/devices/{contactId}
# Returns: record<_selfUrl: string, deviceType: string, extId: string, label: string>
export def "delete-api-public-v1-user-user-contact-methods-devices-contact-id" [
  user: string
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
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api-public/v1/user/{user}/contact-methods/devices/{contactId}"
    path_params: [{name: user, var: user}, {name: contactId, var: contact_id}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, contact_id: $contact_id, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the indicated contact device for a user
#
# GET /api-public/v1/user/{user}/contact-methods/devices/{contactId}
# Returns: table<_selfUrl: string, deviceType: string, extId: string, label: string>
export def "get-api-public-v1-user-user-contact-methods-devices-contact-id" [
  user: string
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
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/user/{user}/contact-methods/devices/{contactId}"
    path_params: [{name: user, var: user}, {name: contactId, var: contact_id}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, contact_id: $contact_id, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a contact device for a user
#
# PUT /api-public/v1/user/{user}/contact-methods/devices/{contactId}
# Returns: record<_selfUrl: string, deviceType: string, extId: string, label: string>
export def "put-api-public-v1-user-user-contact-methods-devices-contact-id" [
  user: string
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
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  --chat-escalation-sound: string
  --device-label: string
  --escalation-notification-sound: string
  --resolved-notification-sound: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api-public/v1/user/{user}/contact-methods/devices/{contactId}"
    path_params: [{name: user, var: user}, {name: contactId, var: contact_id}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: chat_escalation_sound, var: chat_escalation_sound}, {name: device_label, var: device_label}, {name: escalation_notification_sound, var: escalation_notification_sound}, {name: resolved_notification_sound, var: resolved_notification_sound}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, contact_id: $contact_id, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, chat_escalation_sound: $chat_escalation_sound, device_label: $device_label, escalation_notification_sound: $escalation_notification_sound, resolved_notification_sound: $resolved_notification_sound
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all contact emails for a user
#
# GET /api-public/v1/user/{user}/contact-methods/emails
# Returns: table<_selfUrl: string, deviceType: string, extId: string, label: string>
export def "get-api-public-v1-user-user-contact-methods-emails" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/user/{user}/contact-methods/emails"
    path_params: [{name: user, var: user}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a contact emails for a user
#
# POST /api-public/v1/user/{user}/contact-methods/emails
# Returns: record<_selfUrl: string, deviceType: string, extId: string, label: string>
export def "post-api-public-v1-user-user-contact-methods-emails" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  email: string # format: email
  label: string
  --rank: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api-public/v1/user/{user}/contact-methods/emails"
    path_params: [{name: user, var: user}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: label, var: label}, {name: rank, var: rank}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, email: $email, label: $label, rank: $rank
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a contact email for a user
#
# DELETE /api-public/v1/user/{user}/contact-methods/emails/{contactId}
# Returns: record<_selfUrl: string, deviceType: string, extId: string, label: string>
export def "delete-api-public-v1-user-user-contact-methods-emails-contact-id" [
  user: string
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
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api-public/v1/user/{user}/contact-methods/emails/{contactId}"
    path_params: [{name: user, var: user}, {name: contactId, var: contact_id}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, contact_id: $contact_id, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the indicated contact email for a user
#
# GET /api-public/v1/user/{user}/contact-methods/emails/{contactId}
# Returns: table<_selfUrl: string, deviceType: string, extId: string, label: string>
export def "get-api-public-v1-user-user-contact-methods-emails-contact-id" [
  user: string
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
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/user/{user}/contact-methods/emails/{contactId}"
    path_params: [{name: user, var: user}, {name: contactId, var: contact_id}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, contact_id: $contact_id, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all contact phones for a user
#
# GET /api-public/v1/user/{user}/contact-methods/phones
# Returns: table<_selfUrl: string, deviceType: string, extId: string, label: string>
export def "get-api-public-v1-user-user-contact-methods-phones" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/user/{user}/contact-methods/phones"
    path_params: [{name: user, var: user}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a contact phones for a user
#
# POST /api-public/v1/user/{user}/contact-methods/phones
# Returns: record<_selfUrl: string, deviceType: string, extId: string, label: string>
export def "post-api-public-v1-user-user-contact-methods-phones" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
  label: string
  phone: string
  --rank: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api-public/v1/user/{user}/contact-methods/phones"
    path_params: [{name: user, var: user}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}, {name: phone, var: phone}, {name: rank, var: rank}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key, label: $label, phone: $phone, rank: $rank
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a contact phone for a user
#
# DELETE /api-public/v1/user/{user}/contact-methods/phones/{contactId}
# Returns: record<_selfUrl: string, deviceType: string, extId: string, label: string>
export def "delete-api-public-v1-user-user-contact-methods-phones-contact-id" [
  user: string
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
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api-public/v1/user/{user}/contact-methods/phones/{contactId}"
    path_params: [{name: user, var: user}, {name: contactId, var: contact_id}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, contact_id: $contact_id, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the indicated contact phone for a user
#
# GET /api-public/v1/user/{user}/contact-methods/phones/{contactId}
# Returns: table<_selfUrl: string, deviceType: string, extId: string, label: string>
export def "get-api-public-v1-user-user-contact-methods-phones-contact-id" [
  user: string
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
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/user/{user}/contact-methods/phones/{contactId}"
    path_params: [{name: user, var: user}, {name: contactId, var: contact_id}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, contact_id: $contact_id, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user's on-call schedule
#
# GET /api-public/v1/user/{user}/oncall/schedule
# DEPRECATED
# Returns: table<overrides: list<record>, schedule: list<record>, team: string>
@deprecated
export def "get-api-public-v1-user-user-oncall-schedule" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --days-forward: float # Days to include in returned schedule (30 max) (default: 14)
  --days-skip: float # Days to skip before computing schedule to return (90 max) (default: 0)
  --step: float # Step of escalation policy (3 max) (default: 0)
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/user/{user}/oncall/schedule"
    path_params: [{name: user, var: user}]
    query: [{name: daysForward, var: days_forward}, {name: daysSkip, var: days_skip}, {name: step, var: step}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, days_forward: $days_forward, days_skip: $days_skip, step: $step, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of paging policies for a user
#
# GET /api-public/v1/user/{user}/policies
# Returns: record<policies: table<contactType: string, extId: string, order: int, timeout: int>, userId: int, username: string>
export def "get-api-public-v1-user-user-policies" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/user/{user}/policies"
    path_params: [{name: user, var: user}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the user's team membership
#
# GET /api-public/v1/user/{user}/teams
# Returns: record<teams: table<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, name: string, slug: string>>
export def "get-api-public-v1-user-user-teams" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v1/user/{user}/teams"
    path_params: [{name: user, var: user}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a team's on-call schedule
#
# GET /api-public/v2/team/{team}/oncall/schedule
# Returns: record<schedules: table<overrides: list, policy: record, schedule: list>, team: record<name: string, slug: string>>
export def "get-api-public-v2-team-team-oncall-schedule" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --days-forward: float # Days to include in returned schedule (30 max) (default: 14)
  --days-skip: float # Days to skip before computing schedule to return (90 max) (default: 0)
  --step: float # Step of escalation policy (3 max) (default: 0)
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v2/team/{team}/oncall/schedule"
    path_params: [{name: team, var: team}]
    query: [{name: daysForward, var: days_forward}, {name: daysSkip, var: days_skip}, {name: step, var: step}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team: $team, days_forward: $days_forward, days_skip: $days_skip, step: $step, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user's on-call schedule
#
# GET /api-public/v2/user/{user}/oncall/schedule
# Returns: record<teamSchedules: table<schedules: list, team: record>>
export def "get-api-public-v2-user-user-oncall-schedule" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --days-forward: float # Days to include in returned schedule (30 max) (default: 14)
  --days-skip: float # Days to skip before computing schedule to return (90 max) (default: 0)
  --step: float # Step of escalation policy (3 max) (default: 0)
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-public/v2/user/{user}/oncall/schedule"
    path_params: [{name: user, var: user}]
    query: [{name: daysForward, var: days_forward}, {name: daysSkip, var: days_skip}, {name: step, var: step}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, days_forward: $days_forward, days_skip: $days_skip, step: $step, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get/search incident history
#
# GET /api-reporting/v1/incidents
# DEPRECATED
# Returns: table<incidents: list<record>, limit: float, offset: float, total: float>
@deprecated
export def "get-api-reporting-v1-incidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # The offset within the set of matching incidents (default: 0)
  --limit: float # The maximum number of matching incidents to return (100 max) (default: 20)
  --entity-id: string # The entity ID involved This is the unique identifier for the entity causing the incident.
  --incident-number: string # The incident number as shown in VictorOps Multiple values and ranges are allowed: 4,5,20:50
  --started-after: string # Return incidents started after this timestamp Specify the timestamp in ISO8601 format
  --started-before: string # Find incidents started before this timestamp Specify the timestamp in ISO8601 format
  --host: string # The host involved in the incident Multiple values can be separated with commas.
  --service: string # The service involved in the incident (if any) Multiple values can be separated with commas.
  --current-phase: string # The current phase of the incident "resolved", "triggered" or "acknowledged". Multiple values can be separated with commas.
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api-reporting/v1/incidents"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: entityId, var: entity_id}, {name: incidentNumber, var: incident_number}, {name: startedAfter, var: started_after}, {name: startedBefore, var: started_before}, {name: host, var: host}, {name: service, var: service}, {name: currentPhase, var: current_phase}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, entity_id: $entity_id, incident_number: $incident_number, started_after: $started_after, started_before: $started_before, host: $host, service: $service, current_phase: $current_phase, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A list of shift changes for a team
#
# GET /api-reporting/v1/team/{team}/oncall/log
# Returns: record<end: string, start: string, teamSlug: string, userLogs: table<adjustedTotal: record, log: list, total: record, userId: string>>
export def "get-api-reporting-v1-team-team-oncall-log" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Return shift changes occurring after this timestamp. The default is the start of the day at midnight. Specify the timestamp in ISO8601 format (format: date-time)
  --end: string # Return shift changes occurring before this timestamp. The default is the end of the day at 11:59:59. Specify the timestamp in ISO8601 format (format: date-time)
  --user-name: string # The VictorOps user ID. Return shift changes occurring during the interval specified for this user. Without this parameter, all relevant users (with respect to the specified interval) are returned
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-reporting/v1/team/{team}/oncall/log"
    path_params: [{name: team, var: team}]
    query: [{name: start, var: start}, {name: end, var: end}, {name: userName, var: user_name}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team: $team, start: $start, end: $end, user_name: $user_name, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get/search incident history
#
# GET /api-reporting/v2/incidents
# Returns: record<incidents: table<alertCount: float, currentPhase: string, entityId: string, host: string, incidentNumber: string, lastAlertId: string, lastAlertTime: string, pagedPolicies: list, pagedTeams: list, pagedUsers: list, service: string, startTime: string, transitions: list>>
export def "get-api-reporting-v2-incidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # The offset within the set of matching incidents (default: 0)
  --limit: float # The maximum number of matching incidents to return (100 max) (default: 20)
  --entity-id: string # The entity ID involved This is the unique identifier for the entity causing the incident.
  --incident-number: string # The incident number as shown in VictorOps Multiple values and ranges are allowed: 4,5,20:50
  --started-after: string # Return incidents started after this timestamp Specify the timestamp in ISO8601 format
  --started-before: string # Find incidents started before this timestamp Specify the timestamp in ISO8601 format
  --host: string # The host involved in the incident Multiple values can be separated with commas.
  --service: string # The service involved in the incident (if any) Multiple values can be separated with commas.
  --current-phase: string # The current phase of the incident "resolved", "triggered" or "acknowledged". Multiple values can be separated with commas. By default, response contains only "resolved" incidents
  --routing-key: string # The original routing of the incident
  --x-vo-api-id: string # Your API ID (required)
  --x-vo-api-key: string # Your API Key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api-reporting/v2/incidents"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: entityId, var: entity_id}, {name: incidentNumber, var: incident_number}, {name: startedAfter, var: started_after}, {name: startedBefore, var: started_before}, {name: host, var: host}, {name: service, var: service}, {name: currentPhase, var: current_phase}, {name: routingKey, var: routing_key}]
    header: [{name: X-VO-Api-Id, var: x_vo_api_id, required: true}, {name: X-VO-Api-Key, var: x_vo_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, entity_id: $entity_id, incident_number: $incident_number, started_after: $started_after, started_before: $started_before, host: $host, service: $service, current_phase: $current_phase, routing_key: $routing_key, x_vo_api_id: $x_vo_api_id, x_vo_api_key: $x_vo_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
