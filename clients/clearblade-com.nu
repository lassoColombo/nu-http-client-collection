# Auto-generated client for ClearBlade API v3.0
# Source: https://api.apis.guru/v2/specs/clearblade.com/3.0/swagger.json
# Auth: --token flag or $env.CLEARBLADE_API_TOKEN

const CLIENT = {
  base_url: "https://platform.clearblade.com"
  token_env_var: "CLEARBLADE_API_TOKEN"
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

def base-url-completer [] { ["https://platform.clearblade.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-audit: "table<action_type: string, asset_class: string, asset_id: string, changes: string, email: string, id: int, response_time: int, system_key: string, time: string, user_type: string>"
    get-audit-dev: "table<action_type: string, asset_class: string, asset_id: string, changes: string, email: string, id: int, response_time: int, system_key: string, time: string, user_type: string>"
    auth-dev: "record<dev_token: string, expires_at: int, is_two_factor: bool, refresh_token: string, user_id: string>"
    create-rotating-keys: "record<active_key: string, keys: list<string>>"
    update-devices-admin: "record<DATA: list<record>, TOTAL: int>"
    get-system-updates: "table<developers: list<any>, disabled: bool, diskUsage: int, lastUpdated: int, name: string, numAPIReqsMonth: int, numAPIReqsTotal: int, numAPIReqsYear: int, numDeployments: int, numDevices: int, numDevs: int, numEdges: int, numLibraries: int, numPub: int, numPubMonth: int, numPubYear: int, numRecMonth: int, numRecTotal: int, numRecYear: int, numRoles: int, numServices: int, numUsers: int, owner: string, system_key: string>"
    get-system-updates-dev: "table<developers: list<any>, disabled: bool, diskUsage: int, lastUpdated: int, name: string, numAPIReqsMonth: int, numAPIReqsTotal: int, numAPIReqsYear: int, numDeployments: int, numDevices: int, numDevs: int, numEdges: int, numLibraries: int, numPub: int, numPubMonth: int, numPubYear: int, numRecMonth: int, numRecTotal: int, numRecYear: int, numRoles: int, numServices: int, numUsers: int, owner: string, system_key: string>"
    get-portal-info: "table<config: record, description: string, last_updated: string, name: string, namespace: string, system_key: string, type: string>"
    reg-dev: "record<dev_token: string, expires_at: int, is_two_factor: bool, refresh_token: string, user_id: string>"
    delete-email-settings: "record<success: bool>"
    email-settings: "record<encryption_type: string, from: string, host: string, password: string, port: string, protocol: string, two_factor_message: string, two_factor_subject: string, username: string, validation_message: string, validation_subject: string>"
    update-email-settings: "record<success: bool>"
    test-email: "record<success: bool>"
    view-security: "record<developer_token_ttl: int, two_factor_auth: record<enabled: bool>>"
    update-security: "record<developer_token_ttl: int, two_factor_auth: record<enabled: bool>>"
    delete-sms-settings: "record<success: bool>"
    sms-settings: "record<from: string, password: string, service_name: string, two_factor_message: string, url: string, username: string, validation_message: string>"
    create-sms-communication: "record<success: bool>"
    update-sms-settings: "record<success: bool>"
    test-sms: "record<success: bool>"
    get-systems-for-dev: "table<developers: list<any>, disabled: bool, diskUsage: int, lastUpdated: int, name: string, numAPIReqsMonth: int, numAPIReqsTotal: int, numAPIReqsYear: int, numDeployments: int, numDevices: int, numDevs: int, numEdges: int, numLibraries: int, numPub: int, numPubMonth: int, numPubYear: int, numRecMonth: int, numRecTotal: int, numRecYear: int, numRoles: int, numServices: int, numUsers: int, owner: string, system_key: string>"
    get-dev-info: "record<admin: bool, creation_date: int, email: string, email_validated: bool, fname: string, last_login: int, lname: string, org: string, phone: string, phone_validated: bool, two_factor_enabled: bool, \"two_factor_enabled_instance\\\"\": bool, two_factor_method: string, userid: string>"
    update-dev2-fa: "record<success: bool>"
    get-shared-cache: "table<description: string, id: string, name: string, system_key: string, ttl: int>"
    delete-shared-cache: "record<success: bool>"
    add-shared-cache: "record<success: bool>"
    update-shared-cache: "record<success: bool>"
    get-device-session: "table<device_key: string, issued: int>"
    get-device-session-count: "record"
    get-user-session: "table<issued: int, user_id: string>"
    get-user-session-count: "record"
    get-system-info: "record<Dev: string, appId: string, appSecret: string, auth_service: string, description: string, name: string, reg_service: string, registration: string, token_ttl: string, token_ttl_anon: int, token_ttl_device: string, token_ttl_user: string>"
    create-system: "record<Dev: string, appId: string, appSecret: string, auth_service: string, description: string, name: string, reg_service: string, registration: string, token_ttl: string, token_ttl_anon: int, token_ttl_device: string, token_ttl_user: string>"
    get-webhooks: "table<auth_method: string, description: string, id: string, name: string, service_name: string, system_key: string, system_secret: string>"
    delete-webhook: "record<success: bool>"
    create-webhook: "record<success: bool>"
    send-validation: "record<success: bool>"
    api-info: "record<about: record, buildId: string, version: string>"
    delete-collection-data: "record"
    get-collection-data: "record<CURRENTPAGE: int, DATA: list<record>, NEXTPAGEURL: string, PREVPAGEURL: int, TOTAL: int>"
    create-collection-data: "table<item_id: string>"
    update-collection-data: "record"
    delete-collection-data-alt: "record"
    get-collection-data-alt: "record<CURRENTPAGE: int, DATA: list<record>, NEXTPAGEURL: string, PREVPAGEURL: int, TOTAL: int>"
    create-collection-data-alt: "table<item_id: string>"
    update-collection-data-alt: "record"
    get-columns: "table<ColumnName: string, ColumnType: string, PK: bool>"
    get-users: "record<Data: table<creation_date: string, email: string, user_id: string>, Total: int>"
    auth-anon: "record<user_token: string>"
    auth-user: "record<expires_at: int, refresh_token: string, user_id: string, user_token: string>"
    user-check-auth: "record<is_authenticated: bool>"
    get-user-info: "record<creation_date: string, email: string, user_id: string>"
    reg-user: "record<creation_date: string, email: string, expires_at: int, options: string, refresh_token: string, user_id: string, user_token: string>"
    get-devices: "record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, created_date: int, description: string, device_key: string, enabled: bool, last_active_date: int, name: string, state: string, system_key: string, type: string>"
    update-devices: "record<DATA: list<record>, TOTAL: int>"
    auth-device: "record<deviceName: string, deviceToken: string, expiresAt: int, refreshToken: string>"
    add-device: "record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, created_date: int, description: string, device_key: string, enabled: bool, last_active_date: int, name: string, state: string, system_key: string, type: string>"
    update-device-info: "record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, created_date: int, description: string, device_key: string, enabled: bool, last_active_date: int, name: string, state: string, system_key: string, type: string>"
    get-collections: "table<appID: string, collectionID: string, name: string>"
    return-service-settings: "record<code: table<auto_balance: bool, auto_balance_euid: string, auto_restart: bool, concurrency: int, euid: string, execution_timeout: int, logging_enabled: bool, name: string, namespace: string, system_key: string, uuid: string, version: int, version_id: string>>"
    get-timer-by-name: "record<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string>"
    create-new-timer: "record<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string>"
    update-timer-by-name: "record<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string>"
    get-all-timers: "table<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string>"
    get-trigger-by-name: "table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string>"
    create-new-trigger: "table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string>"
    update-trigger-by-name: "table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string>"
    get-all-trigger: "table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string>"
    create-collection: "record<appID: string, collectionID: string, name: string>"
    get-device-table-schema: "table<ColumnName: string, ColumnType: string, PK: bool>"
    get-device-count: "record"
    get-all-deployments: "table<description: string, name: string>"
    get-buckets-data: "table<deployment_name: string, edge_config: list<any>, edge_storage: string, platform_config: list<any>, platform_storage: string, system_key: string>"
    get-single-bucket-data: "record<deployment_name: string, edge_config: list<any>, edge_storage: string, platform_config: list<any>, platform_storage: string, system_key: string>"
    create-bucket-file: "record<base_name: string, bucket_name: string, last_modified: string, path_name: string, permissions: string, relative_name: string, size: int>"
    get-box-files-meta: "record<base_name: string, bucket_name: string, last_modified: string, path_name: string, permissions: string, relative_name: string, size: int>"
    get-box-files: "record<\"example/full/path/to/file.txt\": record<base_name: string, bucket_name: string, last_modified: string, path_name: string, permissions: string, relative_name: string, size: int>>"
    delete-non-unique-index: "record<success: bool>"
    create-non-unique-index: "record<success: bool>"
    get-indexes: "record<Data: table<name: string, type: string>, Total: int>"
    delete-unique-index: "record<success: bool>"
    create-unique-index: "record<success: bool>"
    connected-device-count: "record<total_device_connections: int, total_devices: int, unique_device_connections: int>"
    get-connected-device-list: "record<device_name: table<client_id: string, time_connected: string>>"
    get-connected-device-info: "record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, connections: table<client_id: string, time_connected: string>, created_date: int, description: string, device_key: string, enabled: bool, has_keys: bool, last_active_date: int, name: string, state: string, system_key: string, type: string>"
    get-all-external-db: "table<dbtype: string, name: string>"
    create-external-db: "record<success: bool>"
    delete-external-db: "record<success: bool>"
    get-external-db: "record<credentials: record<address: string, dbname: string, password: string, port: string, user: string>, dbtype: string, id: int, name: string, system_key: string>"
    update-database-credentials: "record<address: string, dbname: string, password: string, port: string, user: string>"
    perform-db-operation: "record<Data: list<any>, Total: int>"
    get-topics: "table<ip: string, payload: string, payloadsize: int, pk: string, qos: int, time: int, topicid: string, userid: string>"
    get-topic-count: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["dev-get-assets" "dev-get-collections" "get-systems" "get-audit" "get-counts" "get-audit-dev" "get-counts-dev" "auth-dev" "verify-auth" "dev-delete-collection" "dev-create-collection" "dev-update-collection" "get-admin-dev-count" "get-system-count" "get-database-status" "admin-owner-change" "delete-device-keys" "create-rotating-keys" "delete-devices-admin" "get-system-devices" "update-devices-admin" "delete-system-device" "get-system-device" "create-system-device" "update-system-device" "get-edge-template" "update-edge-template" "get-edges" "get-adapter-edges" "delete-edge" "get-edge" "create-edge" "update-edge" "dev-logout" "get-license-key" "get-dev" "disable-dev" "get-devs" "get-system-updates" "get-system-updates-dev" "get-system-status" "get-portal-info" "change-dev-password" "reg-dev" "regen-secret" "reset-password" "delete-email-settings" "email-settings" "create-email-communication" "update-email-settings" "test-email" "view-security" "update-security" "delete-sms-settings" "sms-settings" "create-sms-communication" "update-sms-settings" "test-sms" "get-systems-for-dev" "get-triggers" "get-trigger-handlers" "delete-trigger-handler" "get-trigger-handler" "create-trigger" "update-trigger-handler" "get-timer-handlers" "delete-timer-handler" "get-timer-handler" "create-timer-handler" "update-timer-handler" "delete-user" "get-user-list" "add-user" "user-change-user-info" "get-user-column-data" "add-column" "delete-roles" "get-roles" "add-role" "settings-changes" "get-roles-count" "get-dev-info" "update-dev2-fa" "get-shared-cache" "delete-shared-cache" "add-shared-cache" "update-shared-cache" "delete-device-session" "get-device-session" "get-device-session-count" "delete-user-session" "get-user-session" "get-user-session-count" "delete-system" "get-system-info" "create-system" "update-system" "get-webhooks" "delete-webhook" "create-webhook" "update-webhook" "send-validation" "all-edge-sync-status" "get-sync-status" "edge-sync-status" "retry-sync" "api-info" "get-service" "execute-service" "delete-collection-data" "get-collection-data" "create-collection-data" "update-collection-data" "delete-collection-data-alt" "get-collection-data-alt" "create-collection-data-alt" "update-collection-data-alt" "get-columns" "delete-message-history" "get-message-history" "publish-message" "get-users" "auth-anon" "auth-user" "user-check-auth" "delete-user-as-user" "get-user-info" "update-user-info" "user-logout" "update-user-pass" "reg-user" "delete-devices" "get-devices" "update-devices" "auth-device" "add-device" "update-device-info" "get-all-edges" "get-collections" "return-service-settings" "delete-timer-by-name" "get-timer-by-name" "create-new-timer" "update-timer-by-name" "get-all-timers" "delete-trigger-by-name" "get-trigger-by-name" "create-new-trigger" "update-trigger-by-name" "get-all-trigger" "delete-collection" "create-collection" "update-collection" "get-device-table-schema" "get-device-count" "get-edge-table-schema" "get-edge-count" "delete-edge-by-name" "get-edge-data-by-name" "create-new-edge" "update-edge-by-name" "get-all-deployments" "create-deployment" "delete-deployment" "get-a-deployment" "update-deployment" "get-buckets-data" "get-single-bucket-data" "copy-bucket-file" "create-bucket-file" "delete-bucket-file" "get-box-files-meta" "move-bucket-file" "get-box-files" "delete-non-unique-index" "create-non-unique-index" "get-indexes" "delete-unique-index" "create-unique-index" "update-upsert" "connected-device-count" "get-connected-device-list" "get-connected-device-info" "get-all-external-db" "create-external-db" "delete-external-db" "get-external-db" "update-database-credentials" "perform-db-operation" "get-topics" "get-topic-count" "change-user-info" "payload-webhook-query" "execute-webhook" "get-adapters" "add-adapter" "delete-adapter" "map-adapter-command" "add-edge-command" "adapter-config" "update-file-info" "delete-file" "file-download" "update-existing-file-content" "get-failed-service-query" "get-failed-services" "delete-failed-service" "get-system-failed-services" "retry-failed-service" "library-history" "get-old-library-version" "get-libraries" "delete-library" "get-library" "create-library" "update-library" "get-logs" "delete-service" "add-service" "update-service" "commands"] | sort) } | get name | first)
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

# DEVELOPER - Get platform assets
#
# GET /admin/allapps
# operationId: DevGetAssets
export def "dev-get-assets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/allapps"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get collections
#
# GET /admin/allcollections
# operationId: DevGetCollections
export def "dev-get-collections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --appid: string # System Key that identifies the system the collections belong to. (required)
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/allcollections"
    query: [{name: appid, var: appid, required: true}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    appid: $appid, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get systems
#
# GET /admin/allsystems
# operationId: GetSystems
export def "get-systems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/allsystems"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AUDIT - Get Audit Info
#
# GET /admin/audit
# Returns: table<action_type: string, asset_class: string, asset_id: string, changes: string, email: string, id: int, response_time: int, system_key: string, time: string, user_type: string>
# operationId: GetAudit
export def "get-audit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/admin/audit"
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Audit - Get counts
#
# GET /admin/audit/count
# operationId: GetCounts
export def "get-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/audit/count"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AUDIT - Get Audit Info
#
# GET /admin/audit/{systemKey}
# Returns: table<action_type: string, asset_class: string, asset_id: string, changes: string, email: string, id: int, response_time: int, system_key: string, time: string, user_type: string>
# operationId: GetAuditDev
export def "get-audit-dev" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/admin/audit/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AUDIT - Get counts
#
# GET /admin/audit/{systemKey}/count
# operationId: GetCountsDev
export def "get-counts-dev" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/audit/{systemKey}/count"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Authenticate dev
#
# POST /admin/auth
# Returns: record<dev_token: string, expires_at: int, is_two_factor: bool, refresh_token: string, user_id: string>
# operationId: AuthDev
export def "auth-dev" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # e.g. cbman@clearblade.com
  --password: string # e.g. cl34rbl4d3
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/auth"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Verifies access to the system
#
# POST /admin/checkauth
# operationId: VerifyAuth
export def "verify-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/admin/checkauth"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Delete collection
#
# DELETE /admin/collectionmanagement
# operationId: DevDeleteCollection
export def "dev-delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # ID that identifies the collection to be deleted. (required)
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/collectionmanagement"
    query: [{name: id, var: id, required: true}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Create collection
#
# POST /admin/collectionmanagement
# operationId: DevCreateCollection
export def "dev-create-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through authentication. (required)
  app_id: string # This is the system key (e.g. c0f8e2c50bbeeaf87f5efa2eee301)
  --collection-id: string # e.g. c0f8e2c50bbeeafb87f5efa2eee301
  name: string # e.g. newCollection
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/collectionmanagement"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: appID, var: app_id}, {name: collectionID, var: collection_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token, app_id: $app_id, collection_id: $collection_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Update collection
#
# PUT /admin/collectionmanagement
# operationId: DevUpdateCollection
export def "dev-update-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --add-column: any # shape: {id: string, name: string, type: string}
  id: string # This is the collection ID (e.g. c0f8e2c50bbeeafb87f5efa2eee301)
]: any -> any {
  $in | http-request {
    method: put
    path: "/admin/collectionmanagement"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: addColumn, var: add_column}, {name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token, add_column: $add_column, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ADMIN - Get number of admin developers
#
# GET /admin/count/developers
# operationId: GetAdminDevCount
export def "get-admin-dev-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/count/developers"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ADMIN - Get number of systems available
#
# GET /admin/count/systems
# operationId: GetSystemCount
export def "get-system-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/count/systems"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATABASES - Retrieves all internal and external database statuses
#
# GET /admin/database/status
# operationId: GetDatabaseStatus
export def "get-database-status" [
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
    path: "/admin/database/status"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ADMIN - Add/Remove/Change owner
#
# PUT /admin/developers/{systemKey}
# operationId: AdminOwnerChange
export def "admin-owner-change" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  change: any
  owner: string # e.g. owner@clearblade.com
]: any -> any {
  $in | http-request {
    method: put
    path: "/admin/developers/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: change, var: change}, {name: owner, var: owner}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token, change: $change, owner: $owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Delete rotating keys for a device
#
# DELETE /admin/devices/keys/{systemKey}/{deviceName}
# operationId: DeleteDeviceKeys
export def "delete-device-keys" [
  system_key: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through developer authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/devices/keys/{systemKey}/{deviceName}"
    path_params: [{name: systemKey, var: system_key}, {name: deviceName, var: device_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, device_name: $device_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVICE -Creates rotating keys for a device.
#
# POST /admin/devices/keys/{systemKey}/{deviceName}
# Returns: record<active_key: string, keys: list<string>>
# operationId: CreateRotatingKeys
export def "create-rotating-keys" [
  system_key: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through developer authentication. (required)
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/devices/keys/{systemKey}/{deviceName}"
    path_params: [{name: systemKey, var: system_key}, {name: deviceName, var: device_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, device_name: $device_name, clear_blade_dev_token: $clear_blade_dev_token, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Delete devices using a query
#
# DELETE /admin/devices/{systemKey}
# operationId: DeleteDevicesAdmin
export def "delete-devices-admin" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter devices by. See the query model below for an example. (required)
  --clear-blade-dev-token: string # Token obtained through user authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/devices/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: query, var: query, required: true}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get devices with or without a query
#
# GET /admin/devices/{systemKey}
# operationId: GetSystemDevices
export def "get-system-devices" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter devices by. See the query model below for an example. All devices are returned if a query is not specified.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/devices/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Update devices using a query
#
# PUT /admin/devices/{systemKey}
# Returns: record<DATA: list<record>, TOTAL: int>
# operationId: UpdateDevicesAdmin
export def "update-devices-admin" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Token obtained through user authentication. (required)
  --set: record # shape: {[columnName]?: any}
  --query: list # item shape: {EQ?: list, GT?: list, GTE?: list, LT?: list, LTE?: list, NEQ?: list, RE?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/devices/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: "$set", var: set}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token, set: $set, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Delete device
#
# DELETE /admin/devices/{systemKey}/{name}
# operationId: DeleteSystemDevice
export def "delete-system-device" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/devices/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get device
#
# GET /admin/devices/{systemKey}/{name}
# operationId: GetSystemDevice
export def "get-system-device" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/devices/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Create device
#
# POST /admin/devices/{systemKey}/{name}
# operationId: CreateSystemDevice
export def "create-system-device" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --active-key: string
  --allow-certificate-auth: oneof<nothing, bool>
  --allow-key-auth: oneof<nothing, bool>
  --certificate: string
  --custom: string
  --description: string
  --enabled: oneof<nothing, bool>
  --keys: string
  --body-name: string # (spec name: name)
  state: string
  type: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/devices/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: active_key, var: active_key}, {name: allow_certificate_auth, var: allow_certificate_auth, required: true}, {name: allow_key_auth, var: allow_key_auth, required: true}, {name: certificate, var: certificate}, {name: custom, var: custom}, {name: description, var: description}, {name: enabled, var: enabled, required: true}, {name: keys, var: keys}, {name: name, var: body_name, required: true}, {name: state, var: state}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_dev_token: $clear_blade_dev_token, active_key: $active_key, allow_certificate_auth: $allow_certificate_auth, allow_key_auth: $allow_key_auth, certificate: $certificate, custom: $custom, description: $description, enabled: $enabled, keys: $keys, body_name: $body_name, state: $state, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Update device
#
# PUT /admin/devices/{systemKey}/{name}
# operationId: UpdateSystemDevice
export def "update-system-device" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --active-key: string
  --allow-certificate-auth: oneof<nothing, bool>
  --allow-key-auth: oneof<nothing, bool>
  --certificate: string
  --custom: string
  --description: string
  --enabled: oneof<nothing, bool>
  --keys: string
  --state: string
  --type: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/admin/devices/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: active_key, var: active_key}, {name: allow_certificate_auth, var: allow_certificate_auth}, {name: allow_key_auth, var: allow_key_auth}, {name: certificate, var: certificate}, {name: custom, var: custom}, {name: description, var: description}, {name: enabled, var: enabled}, {name: keys, var: keys}, {name: state, var: state}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_dev_token: $clear_blade_dev_token, active_key: $active_key, allow_certificate_auth: $allow_certificate_auth, allow_key_auth: $allow_key_auth, certificate: $certificate, custom: $custom, description: $description, enabled: $enabled, keys: $keys, state: $state, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get edge template
#
# GET /admin/edges/template/{systemKey}
# operationId: GetEdgeTemplate
export def "get-edge-template" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/edges/template/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Update edge template
#
# PUT /admin/edges/template/{systemKey}/{edgeName}
# operationId: UpdateEdgeTemplate
export def "update-edge-template" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --def-module: any # shape: {module?: "trigger"|"service"|"library"}
  def_name: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/admin/edges/template/{systemKey}/{edgeName}"
    path_params: [{name: systemKey, var: system_key}, {name: edgeName, var: edge_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: def_module, var: def_module}, {name: def_name, var: def_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, edge_name: $edge_name, clear_blade_dev_token: $clear_blade_dev_token, def_module: $def_module, def_name: $def_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get edges
#
# GET /admin/edges/{systemKey}
# operationId: GetEdges
export def "get-edges" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/edges/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get edges for the adapter
#
# GET /admin/edges/{systemKey}/control
# operationId: GetAdapterEdges
export def "get-adapter-edges" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/edges/{systemKey}/control"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Delete edge
#
# DELETE /admin/edges/{systemKey}/{edgeName}
# operationId: DeleteEdge
export def "delete-edge" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/edges/{systemKey}/{edgeName}"
    path_params: [{name: systemKey, var: system_key}, {name: edgeName, var: edge_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, edge_name: $edge_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get edge
#
# GET /admin/edges/{systemKey}/{edgeName}
# operationId: GetEdge
export def "get-edge" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/edges/{systemKey}/{edgeName}"
    path_params: [{name: systemKey, var: system_key}, {name: edgeName, var: edge_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, edge_name: $edge_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Create edge
#
# POST /admin/edges/{systemKey}/{edgeName}
# operationId: CreateEdge
export def "create-edge" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --description: string
  --local-addr: string
  --local-port: string
  --location: string
  --mac-address: string
  --public-addr: string
  --public-port: string
  --body-system-key: string # (spec name: system_key)
  system_secret: string
  --body-token: string # (spec name: token)
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/edges/{systemKey}/{edgeName}"
    path_params: [{name: systemKey, var: system_key}, {name: edgeName, var: edge_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: local_addr, var: local_addr}, {name: local_port, var: local_port}, {name: location, var: location}, {name: mac_address, var: mac_address}, {name: public_addr, var: public_addr}, {name: public_port, var: public_port}, {name: system_key, var: body_system_key, required: true}, {name: system_secret, var: system_secret}, {name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, edge_name: $edge_name, clear_blade_dev_token: $clear_blade_dev_token, description: $description, local_addr: $local_addr, local_port: $local_port, location: $location, mac_address: $mac_address, public_addr: $public_addr, public_port: $public_port, body_system_key: $body_system_key, system_secret: $system_secret, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Update edge
#
# PUT /admin/edges/{systemKey}/{edgeName}
# operationId: UpdateEdge
export def "update-edge" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --description: string
  --local-addr: string
  --local-port: string
  --location: string
  --mac-address: string
  --public-addr: string
  --public-port: string
  --body-system-key: string # (spec name: system_key)
  system_secret: string
  --body-token: string # (spec name: token)
]: any -> any {
  $in | http-request {
    method: put
    path: "/admin/edges/{systemKey}/{edgeName}"
    path_params: [{name: systemKey, var: system_key}, {name: edgeName, var: edge_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: local_addr, var: local_addr}, {name: local_port, var: local_port}, {name: location, var: location}, {name: mac_address, var: mac_address}, {name: public_addr, var: public_addr}, {name: public_port, var: public_port}, {name: system_key, var: body_system_key, required: true}, {name: system_secret, var: system_secret}, {name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, edge_name: $edge_name, clear_blade_dev_token: $clear_blade_dev_token, description: $description, local_addr: $local_addr, local_port: $local_port, location: $location, mac_address: $mac_address, public_addr: $public_addr, public_port: $public_port, body_system_key: $body_system_key, system_secret: $system_secret, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Log out dev
#
# POST /admin/logout
# operationId: DevLogout
export def "dev-logout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/admin/logout"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ADMIN - Get platform license key.
#
# GET /admin/pkey
# operationId: GetLicenseKey
export def "get-license-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/pkey"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ADMIN - Get developer
#
# GET /admin/platform/developer
# operationId: GetDev
export def "get-dev" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer: string # Email of the developer in question. (required)
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/platform/developer"
    query: [{name: developer, var: developer, required: true}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    developer: $developer, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Disable developer
#
# POST /admin/platform/developer
# operationId: DisableDev
export def "disable-dev" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --admin: oneof<nothing, bool>
  --disabled: oneof<nothing, bool>
  email: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/platform/developer"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: admin, var: admin, required: true}, {name: disabled, var: disabled, required: true}, {name: email, var: email}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token, admin: $admin, disabled: $disabled, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ADMIN - Get developers
#
# GET /admin/platform/developers
# operationId: GetDevs
export def "get-devs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: string # Response page size.
  --pagenum: string # Response page number.
  --total: string
  --filter: string # Filter response.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/platform/developers"
    query: [{name: pagesize, var: pagesize}, {name: pagenum, var: pagenum}, {name: total, var: total}, {name: filter, var: filter}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pagesize: $pagesize, pagenum: $pagenum, total: $total, filter: $filter, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AUDIT - Get list of systems that have been updated
#
# GET /admin/platform/systems
# Returns: table<developers: list<any>, disabled: bool, diskUsage: int, lastUpdated: int, name: string, numAPIReqsMonth: int, numAPIReqsTotal: int, numAPIReqsYear: int, numDeployments: int, numDevices: int, numDevs: int, numEdges: int, numLibraries: int, numPub: int, numPubMonth: int, numPubYear: int, numRecMonth: int, numRecTotal: int, numRecYear: int, numRoles: int, numServices: int, numUsers: int, owner: string, system_key: string>
# operationId: GetSystemUpdates
export def "get-system-updates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clearblade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/admin/platform/systems"
    query: [{name: query, var: query}]
    header: [{name: Clearblade-DevToken, var: clearblade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, clearblade_dev_token: $clearblade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AUDIT - Get list of systems that have been updated
#
# GET /admin/platform/systems/{systemKey}
# Returns: table<developers: list<any>, disabled: bool, diskUsage: int, lastUpdated: int, name: string, numAPIReqsMonth: int, numAPIReqsTotal: int, numAPIReqsYear: int, numDeployments: int, numDevices: int, numDevs: int, numEdges: int, numLibraries: int, numPub: int, numPubMonth: int, numPubYear: int, numRecMonth: int, numRecTotal: int, numRecYear: int, numRoles: int, numServices: int, numUsers: int, owner: string, system_key: string>
# operationId: GetSystemUpdatesDev
export def "get-system-updates-dev" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clearblade-devtoken: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/admin/platform/systems/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: query, var: query}]
    header: [{name: clearblade-devtoken, var: clearblade_devtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clearblade_devtoken: $clearblade_devtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ADMIN - Get system status
#
# GET /admin/platform/{systemKey}
# operationId: GetSystemStatus
export def "get-system-status" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/platform/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Gets the information for a portal
#
# GET /admin/portals/{systemKey}
# Returns: table<config: record, description: string, last_updated: string, name: string, namespace: string, system_key: string, type: string>
# operationId: GetPortalInfo
export def "get-portal-info" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through developer authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/admin/portals/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Change dev password
#
# PUT /admin/putpass
# operationId: ChangeDevPassword
export def "change-dev-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  new_password: string # e.g. bieberluver
  old_password: string # e.g. bieberboy
]: any -> any {
  $in | http-request {
    method: put
    path: "/admin/putpass"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: new_password, var: new_password}, {name: old_password, var: old_password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token, new_password: $new_password, old_password: $old_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Register new dev
#
# POST /admin/reg
# Returns: record<dev_token: string, expires_at: int, is_two_factor: bool, refresh_token: string, user_id: string>
# operationId: RegDev
export def "reg-dev" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # Developer's email. (e.g. martin@clearblade.com)
  fname: string # Developer's first name. (e.g. Martin)
  lname: string # Developer's last name. (e.g. theMachine)
  org: string # Developer's organization. (e.g. ClearBlade)
  password: string # Developer's password. (e.g. bieberboy)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/reg"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: fname, var: fname}, {name: lname, var: lname}, {name: org, var: org}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, fname: $fname, lname: $lname, org: $org, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Regen secret
#
# PUT /admin/regensystemsecret
# operationId: RegenSecret
export def "regen-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  id: string # e.g. [systemID]
]: any -> any {
  $in | http-request {
    method: put
    path: "/admin/regensystemsecret"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ADMIN - Change dev password (Admin)
#
# POST /admin/resetpassword
# operationId: ResetPassword
export def "reset-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --email: string # e.g. example@clearblade.com
  --new-password: string # e.g. password
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/resetpassword"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: new_password, var: new_password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token, email: $email, new_password: $new_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 2FA - Delete email settings
#
# DELETE /admin/settings/email-service
# Returns: record<success: bool>
# operationId: DeleteEmailSettings
export def "delete-email-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/admin/settings/email-service"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 2FA - Get Email Settings
#
# GET /admin/settings/email-service
# Returns: record<encryption_type: string, from: string, host: string, password: string, port: string, protocol: string, two_factor_message: string, two_factor_subject: string, username: string, validation_message: string, validation_subject: string>
# operationId: EmailSettings
export def "email-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/settings/email-service"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 2FA - Create Email Communication
#
# POST /admin/settings/email-service
# operationId: CreateEmailCommunication
export def "create-email-communication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --encryption-type: string # e.g. STARTTLS
  --from: string # e.g. example@gmail.com
  --host: string # e.g. smtp.gmail.com
  --password: string # e.g. test
  --port: string # e.g. 587
  --protocol: string # e.g. SMTP
  --two-factor-message: string # e.g. Please use the code to log in: $CODE
  --two-factor-subject: string # e.g. Login code
  --username: string # e.g. example@gmail.com
  --validation-message: string # e.g. Please validate your email here: $LINK
  --validation-subject: string # e.g. Email validation
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/settings/email-service"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: encryption_type, var: encryption_type}, {name: from, var: from}, {name: host, var: host}, {name: password, var: password}, {name: port, var: port}, {name: protocol, var: protocol}, {name: two_factor_message, var: two_factor_message}, {name: two_factor_subject, var: two_factor_subject}, {name: username, var: username}, {name: validation_message, var: validation_message}, {name: validation_subject, var: validation_subject}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token, encryption_type: $encryption_type, from: $from, host: $host, password: $password, port: $port, protocol: $protocol, two_factor_message: $two_factor_message, two_factor_subject: $two_factor_subject, username: $username, validation_message: $validation_message, validation_subject: $validation_subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 2FA - Update Email Settings
#
# PUT /admin/settings/email-service
# Returns: record<success: bool>
# operationId: UpdateEmailSettings
export def "update-email-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --encryption-type: string # e.g. STARTTLS
  --from: string # e.g. example@gmail.com
  --host: string # e.g. smtp.gmail.com
  --password: string # e.g. test
  --port: string # e.g. 587
  --protocol: string # e.g. SMTP
  --two-factor-message: string # e.g. Please use the code to log in: $CODE
  --two-factor-subject: string # e.g. Login code
  --username: string # e.g. example@gmail.com
  --validation-message: string # e.g. Please validate your email here: $LINK
  --validation-subject: string # e.g. Email validation
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/settings/email-service"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: encryption_type, var: encryption_type}, {name: from, var: from}, {name: host, var: host}, {name: password, var: password}, {name: port, var: port}, {name: protocol, var: protocol}, {name: two_factor_message, var: two_factor_message}, {name: two_factor_subject, var: two_factor_subject}, {name: username, var: username}, {name: validation_message, var: validation_message}, {name: validation_subject, var: validation_subject}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token, encryption_type: $encryption_type, from: $from, host: $host, password: $password, port: $port, protocol: $protocol, two_factor_message: $two_factor_message, two_factor_subject: $two_factor_subject, username: $username, validation_message: $validation_message, validation_subject: $validation_subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 2FA - Test Email Service
#
# POST /admin/settings/email-service/test
# Returns: record<success: bool>
# operationId: TestEmail
export def "test-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --recipient: string # e.g. example@companyname.com
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/settings/email-service/test"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: recipient, var: recipient}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token, recipient: $recipient
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 2FA - View Security Settings
#
# GET /admin/settings/security
# Returns: record<developer_token_ttl: int, two_factor_auth: record<enabled: bool>>
# operationId: ViewSecurity
export def "view-security" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/settings/security"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 2FA - Update Security Settings
#
# PUT /admin/settings/security
# Returns: record<developer_token_ttl: int, two_factor_auth: record<enabled: bool>>
# operationId: UpdateSecurity
export def "update-security" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --developer-token-ttl: int # e.g. 86400
  --two-factor-auth: any # shape: {enabled?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/settings/security"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: developer_token_ttl, var: developer_token_ttl}, {name: two_factor_auth, var: two_factor_auth}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token, developer_token_ttl: $developer_token_ttl, two_factor_auth: $two_factor_auth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 2FA - Delete SMS settings
#
# DELETE /admin/settings/sms-service
# Returns: record<success: bool>
# operationId: DeleteSMSSettings
export def "delete-sms-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/admin/settings/sms-service"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 2FA - Get SMS Settings
#
# GET /admin/settings/sms-service
# Returns: record<from: string, password: string, service_name: string, two_factor_message: string, url: string, username: string, validation_message: string>
# operationId: SMSSettings
export def "sms-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/settings/sms-service"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 2FA - Create SMS Communication
#
# POST /admin/settings/sms-service
# Returns: record<success: bool>
# operationId: CreateSMSCommunication
export def "create-sms-communication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --from: string # e.g. +15120000000
  --password: string # e.g. test
  --service-name: string # Only Twilio is supported. (e.g. Twilio)
  --two-factor-message: string # e.g. Please use the code to log in: $CODE
  --url: string # e.g. https://api.twilio.com
  --username: string # e.g. AC25b4eb989b9db8
  --validation-message: string # e.g. Please validate your email here: $LINK
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/settings/sms-service"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: from, var: from}, {name: password, var: password}, {name: service_name, var: service_name}, {name: two_factor_message, var: two_factor_message}, {name: url, var: url}, {name: username, var: username}, {name: validation_message, var: validation_message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token, from: $from, password: $password, service_name: $service_name, two_factor_message: $two_factor_message, url: $url, username: $username, validation_message: $validation_message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 2FA - Update SMS Settings
#
# PUT /admin/settings/sms-service
# Returns: record<success: bool>
# operationId: UpdateSMSSettings
export def "update-sms-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --from: string # e.g. +15120000000
  --password: string # e.g. test
  --service-name: string # Only Twilio is supported. (e.g. Twilio)
  --two-factor-message: string # e.g. Please use the code to log in: $CODE
  --url: string # e.g. https://api.twilio.com
  --username: string # e.g. AC25b4eb989b9db8
  --validation-message: string # e.g. Please validate your email here: $LINK
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/settings/sms-service"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: from, var: from}, {name: password, var: password}, {name: service_name, var: service_name}, {name: two_factor_message, var: two_factor_message}, {name: url, var: url}, {name: username, var: username}, {name: validation_message, var: validation_message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token, from: $from, password: $password, service_name: $service_name, two_factor_message: $two_factor_message, url: $url, username: $username, validation_message: $validation_message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 2FA - Test SMS Service
#
# POST /admin/settings/sms-service/test
# Returns: record<success: bool>
# operationId: TestSMS
export def "test-sms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --recipient: string # e.g. +15120000000
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/settings/sms-service/test"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: recipient, var: recipient}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token, recipient: $recipient
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Systems for a developer
#
# GET /admin/systems/{devEmail}
# Returns: table<developers: list<any>, disabled: bool, diskUsage: int, lastUpdated: int, name: string, numAPIReqsMonth: int, numAPIReqsTotal: int, numAPIReqsYear: int, numDeployments: int, numDevices: int, numDevs: int, numEdges: int, numLibraries: int, numPub: int, numPubMonth: int, numPubYear: int, numRecMonth: int, numRecTotal: int, numRecYear: int, numRoles: int, numServices: int, numUsers: int, owner: string, system_key: string>
# operationId: GetSystemsForDev
export def "get-systems-for-dev" [
  dev_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/admin/systems/{devEmail}"
    path_params: [{name: devEmail, var: dev_email}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dev_email: $dev_email, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get trigger definitions
#
# GET /admin/triggers/definitions
# operationId: GetTriggers
export def "get-triggers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/triggers/definitions"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get trigger handlers
#
# GET /admin/triggers/handlers/{systemKey}
# operationId: GetTriggerHandlers
export def "get-trigger-handlers" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/triggers/handlers/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Delete trigger handler
#
# DELETE /admin/triggers/handlers/{systemKey}/{name}
# operationId: DeleteTriggerHandler
export def "delete-trigger-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/triggers/handlers/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get trigger handler
#
# GET /admin/triggers/handlers/{systemKey}/{name}
# operationId: GetTriggerHandler
export def "get-trigger-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/triggers/handlers/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Create trigger handler
#
# POST /admin/triggers/handlers/{systemKey}/{name}
# operationId: CreateTrigger
export def "create-trigger" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  def_module: string # e.g. Messaging
  def_name: string # e.g. Publish
  --disabled: oneof<nothing, bool> # Enable or disable trigger (e.g. true)
  key_value_pairs: any # shape: {topic?: string}
  service_name: string # e.g. updateTemps
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/triggers/handlers/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: def_module, var: def_module}, {name: def_name, var: def_name}, {name: disabled, var: disabled, required: true}, {name: key_value_pairs, var: key_value_pairs}, {name: service_name, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_dev_token: $clear_blade_dev_token, def_module: $def_module, def_name: $def_name, disabled: $disabled, key_value_pairs: $key_value_pairs, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Update trigger handler
#
# PUT /admin/triggers/handlers/{systemKey}/{name}
# operationId: UpdateTriggerHandler
export def "update-trigger-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  def_module: string # e.g. Messaging
  def_name: string # e.g. Publish
  --disabled: oneof<nothing, bool> # Enable or disable trigger (e.g. true)
  key_value_pairs: any # shape: {topic?: string}
  service_name: string # e.g. updateTemps
]: any -> any {
  $in | http-request {
    method: put
    path: "/admin/triggers/handlers/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: def_module, var: def_module}, {name: def_name, var: def_name}, {name: disabled, var: disabled, required: true}, {name: key_value_pairs, var: key_value_pairs}, {name: service_name, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_dev_token: $clear_blade_dev_token, def_module: $def_module, def_name: $def_name, disabled: $disabled, key_value_pairs: $key_value_pairs, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get timer handlers
#
# GET /admin/triggers/timers/{systemKey}
# operationId: GetTimerHandlers
export def "get-timer-handlers" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/triggers/timers/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Delete trigger handler
#
# DELETE /admin/triggers/timers/{systemKey}/{name}
# operationId: DeleteTimerHandler
export def "delete-timer-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/triggers/timers/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get timer handler
#
# GET /admin/triggers/timers/{systemKey}/{name}
# operationId: GetTimerHandler
export def "get-timer-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/triggers/timers/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Create time handler
#
# POST /admin/triggers/timers/{systemKey}/{name}
# operationId: create_timer_handler
export def "create-timer-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --description: string # Information about the timer (e.g. My 10 second timer)
  --disabled: oneof<nothing, bool> # Enable or disable timer (e.g. true)
  frequency: int # Frequency (in seconds) between two consecutive invocations of a timer handler (e.g. 10)
  --body-name: string # Timer label (e.g. tenSecondTimer) (spec name: name)
  repeats: int # The number of times a timer handler is invoked. To invoke the handler indefinitely set 'repeats = -1' (e.g. 20)
  service_name: string # The handler service invoked by the timer (e.g. getTemps)
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/triggers/timers/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: disabled, var: disabled, required: true}, {name: frequency, var: frequency}, {name: name, var: body_name, required: true}, {name: repeats, var: repeats}, {name: service_name, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_dev_token: $clear_blade_dev_token, description: $description, disabled: $disabled, frequency: $frequency, body_name: $body_name, repeats: $repeats, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Update timer handler
#
# PUT /admin/triggers/timers/{systemKey}/{name}
# operationId: UpdateTimerHandler
export def "update-timer-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --description: string # Information about the timer (e.g. My 10 second timer)
  --disabled: oneof<nothing, bool> # Enable or disable timer (e.g. true)
  frequency: int # Frequency (in seconds) between two consecutive invocations of a timer handler (e.g. 10)
  --body-name: string # Timer label (e.g. tenSecondTimer) (spec name: name)
  repeats: int # The number of times a timer handler is invoked. To invoke the handler indefinitely set 'repeats = -1' (e.g. 20)
  service_name: string # The handler service invoked by the timer (e.g. getTemps)
]: any -> any {
  $in | http-request {
    method: put
    path: "/admin/triggers/timers/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: disabled, var: disabled, required: true}, {name: frequency, var: frequency}, {name: name, var: body_name, required: true}, {name: repeats, var: repeats}, {name: service_name, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_dev_token: $clear_blade_dev_token, description: $description, disabled: $disabled, frequency: $frequency, body_name: $body_name, repeats: $repeats, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Delete user
#
# DELETE /admin/user/{systemKey}
# operationId: DeleteUser
export def "delete-user" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # UserId of the user to delete
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/user/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: user, var: user}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, user: $user, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get list of users and information
#
# GET /admin/user/{systemKey}
# operationId: GetUserList
export def "get-user-list" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter users. Check 'users' model at the bottom of this page.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/user/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Add user
#
# POST /admin/user/{systemKey}
# operationId: AddUser
export def "add-user" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  email: string # e.g. helpme@clearblade.com
  password: string # e.g. c13rb1ad3ru13z
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/user/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token, email: $email, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Change user information and permissions
#
# PUT /admin/user/{systemKey}
# operationId: UserChangeUserInfo
export def "user-change-user-info" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  changes: any # Changes roles — shape: {roles: any}
  user: string # e.g. b4d8aaab0bf48e98dacbd78e9e50
]: any -> any {
  $in | http-request {
    method: put
    path: "/admin/user/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: changes, var: changes}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token, changes: $changes, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get users column info.
#
# GET /admin/user/{systemKey}/columns
# operationId: GetUserColumnData
export def "get-user-column-data" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/user/{systemKey}/columns"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Add new column
#
# POST /admin/user/{systemKey}/columns
# operationId: AddColumn
export def "add-column" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  column_name: string # e.g. phone_number
  type: string # e.g. string
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/user/{systemKey}/columns"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: column_name, var: column_name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token, column_name: $column_name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Delete roles
#
# DELETE /admin/user/{systemKey}/roles
# operationId: DeleteRoles
export def "delete-roles" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Role identification key. (required)
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/user/{systemKey}/roles"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: query, var: query, required: true}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get list of roles
#
# GET /admin/user/{systemKey}/roles
# operationId: GetRoles
export def "get-roles" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Refer to the example query above.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/user/{systemKey}/roles"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Add new role
#
# POST /admin/user/{systemKey}/roles
# operationId: AddRole
export def "add-role" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --collections: list # e.g. []
  --description: string # e.g. 
  name: string # e.g. Administrator
  --services: list # e.g. []
  --topics: list # e.g. []
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/user/{systemKey}/roles"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: collections, var: collections}, {name: description, var: description}, {name: name, var: name}, {name: services, var: services}, {name: topics, var: topics}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token, collections: $collections, description: $description, name: $name, services: $services, topics: $topics
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Changes roles settings
#
# PUT /admin/user/{systemKey}/roles
# operationId: SettingsChanges
export def "settings-changes" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  changes: any # Assets with permission changes — shape: {allcollections?: any, allservices?: record, collections?: any, deployments?: record, description?: string, devices?: record, edges?: any, msgHistory?: record, portals?: any, roles?: record, services?: any, topics?: any, triggers?: record, users?: record}
  id: string # e.g. Administrator
]: any -> any {
  $in | http-request {
    method: put
    path: "/admin/user/{systemKey}/roles"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: changes, var: changes}, {name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token, changes: $changes, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get number of roles
#
# GET /admin/user/{systemKey}/roles/count
# operationId: GetRolesCount
export def "get-roles-count" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # Identifies page size and page number for roles list. (required)
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/user/{systemKey}/roles/count"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: user, var: user, required: true}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, user: $user, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get dev info
#
# GET /admin/userinfo
# Returns: record<admin: bool, creation_date: int, email: string, email_validated: bool, fname: string, last_login: int, lname: string, org: string, phone: string, phone_validated: bool, two_factor_enabled: bool, "two_factor_enabled_instance\"": bool, two_factor_method: string, userid: string>
# operationId: GetDevInfo
export def "get-dev-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/userinfo"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 2FA - Update developer 2FA information.
#
# PUT /admin/userinfo
# Returns: record<success: bool>
# operationId: UpdateDev2FA
export def "update-dev2-fa" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --phone: string # e.g. +15120000000
  --two-factor-enabled: oneof<nothing, bool> # e.g. true
  --two-factor-method: string # e.g. sms
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/userinfo"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: phone, var: phone}, {name: two_factor_enabled, var: two_factor_enabled}, {name: two_factor_method, var: two_factor_method}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token, phone: $phone, two_factor_enabled: $two_factor_enabled, two_factor_method: $two_factor_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SHARED CACHE - Gets shared caches for a system
#
# GET /admin/v/4/service_caches/{systemKey}
# Returns: table<description: string, id: string, name: string, system_key: string, ttl: int>
# operationId: GetSharedCache
export def "get-shared-cache" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through user authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/admin/v/4/service_caches/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SHARED CACHE - Delete a shared cache
#
# DELETE /admin/v/4/service_caches/{systemKey}/{cacheName}
# Returns: record<success: bool>
# operationId: DeleteSharedCache
export def "delete-shared-cache" [
  system_key: string
  cache_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through user authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/admin/v/4/service_caches/{systemKey}/{cacheName}"
    path_params: [{name: systemKey, var: system_key}, {name: cacheName, var: cache_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, cache_name: $cache_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SHARED CACHE - Add a shared cache
#
# POST /admin/v/4/service_caches/{systemKey}/{cacheName}
# Returns: record<success: bool>
# operationId: addSharedCache
export def "add-shared-cache" [
  system_key: string
  cache_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through user authentication. (required)
  --description: string # Description of new shared cache
  --name: string # e.g. sharedCache
  ttl: int # e.g. 30
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/v/4/service_caches/{systemKey}/{cacheName}"
    path_params: [{name: systemKey, var: system_key}, {name: cacheName, var: cache_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, cache_name: $cache_name, clear_blade_dev_token: $clear_blade_dev_token, description: $description, name: $name, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SHARED CACHE - Update a shared cache
#
# PUT /admin/v/4/service_caches/{systemKey}/{cacheName}
# Returns: record<success: bool>
# operationId: UpdateSharedCache
export def "update-shared-cache" [
  system_key: string
  cache_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through user authentication. (required)
  --description: string
  ttl: int # e.g. 30
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/v/4/service_caches/{systemKey}/{cacheName}"
    path_params: [{name: systemKey, var: system_key}, {name: cacheName, var: cache_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, cache_name: $cache_name, clear_blade_dev_token: $clear_blade_dev_token, description: $description, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SESSION - Delete device session
#
# DELETE /admin/v/4/session/{systemKey}/device
# operationId: DeleteDeviceSession
export def "delete-device-session" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/v/4/session/{systemKey}/device"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SESSION - Get device session info
#
# GET /admin/v/4/session/{systemKey}/device
# Returns: table<device_key: string, issued: int>
# operationId: GetDeviceSession
export def "get-device-session" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/admin/v/4/session/{systemKey}/device"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SESSION - Get device session count
#
# GET /admin/v/4/session/{systemKey}/device/count
# Returns: record
# operationId: GetDeviceSessionCount
export def "get-device-session-count" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/v/4/session/{systemKey}/device/count"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SESSION - Delete user session
#
# DELETE /admin/v/4/session/{systemKey}/user
# operationId: DeleteUserSession
export def "delete-user-session" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/v/4/session/{systemKey}/user"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SESSION - Get user session info
#
# GET /admin/v/4/session/{systemKey}/user
# Returns: table<issued: int, user_id: string>
# operationId: GetUserSession
export def "get-user-session" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/admin/v/4/session/{systemKey}/user"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SESSION - Get user session count
#
# GET /admin/v/4/session/{systemKey}/user/count
# Returns: record
# operationId: GetUserSessionCount
export def "get-user-session-count" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/v/4/session/{systemKey}/user/count"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Delete system
#
# DELETE /admin/v/4/systemmanagement
# operationId: DeleteSystem
export def "delete-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # System Key that identifies the system you want to delete. (required)
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/v/4/systemmanagement"
    query: [{name: id, var: id, required: true}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get system info
#
# GET /admin/v/4/systemmanagement
# Returns: record<Dev: string, appId: string, appSecret: string, auth_service: string, description: string, name: string, reg_service: string, registration: string, token_ttl: string, token_ttl_anon: int, token_ttl_device: string, token_ttl_user: string>
# operationId: GetSystemInfo
export def "get-system-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # System Key that identifies the system you want the info about. (required)
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/v/4/systemmanagement"
    query: [{name: id, var: id, required: true}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Create system
#
# POST /admin/v/4/systemmanagement
# Returns: record<Dev: string, appId: string, appSecret: string, auth_service: string, description: string, name: string, reg_service: string, registration: string, token_ttl: string, token_ttl_anon: int, token_ttl_device: string, token_ttl_user: string>
# operationId: CreateSystem
export def "create-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through developer authentication. (required)
  description: string # e.g. Here is my new system.
  name: string # e.g. ExampleSystem
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/v/4/systemmanagement"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Update system info
#
# PUT /admin/v/4/systemmanagement
# operationId: UpdateSystem
export def "update-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --dev: string # Developer Id for the owner of the system (e.g. 92f8dbbb0bccb3fff4be5cdb601)
  --app-id: string # system key (e.g. a6e0f8e20bbefcec789de6b8f4cf01)
  --app-secret: string # system secret (e.g. A6E0F8E20BDEB0C2838EF2B6D09801)
  --auth-service: string # Configure the system to have all authentication requests go through a specific Code Service. (e.g. )
  --description: string # e.g. Here is my new system.
  --name: string # e.g. ExampleSystem
  --reg-service: string # Configure the system to have all registration requests go through a specific Code Service. (e.g. )
  --registration: string # e.g. 
  --token-ttl: string # ttl for developer tokens in seconds. Min - 86400 (1 day), Max- 2592000 (30 days), Default - 432000 Infinite - -1 (e.g. 432000)
  --token-ttl-anon: int # ttl for anonymous tokens in seconds. Min - 3600 (1 hour), Max- 7776000 (90 days), Default - 432000 (5 days) Infinite - -1 (e.g. 432000)
  --token-ttl-device: string # ttl for device tokens in seconds. Min - 3600 (1 hour), Max- 7776000 (90 days), Default - 432000 (5 days) Infinite - -1 (e.g. 432000)
  --token-ttl-user: string # ttl for user tokens in seconds. Min - 3600 (1 hour), Max- 7776000 (90 days), Default - 432000 (5 days) Infinite - -1 (e.g. 432000)
]: any -> any {
  $in | http-request {
    method: put
    path: "/admin/v/4/systemmanagement"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Dev, var: dev}, {name: appId, var: app_id}, {name: appSecret, var: app_secret}, {name: auth_service, var: auth_service}, {name: description, var: description}, {name: name, var: name}, {name: reg_service, var: reg_service}, {name: registration, var: registration}, {name: token_ttl, var: token_ttl}, {name: token_ttl_anon, var: token_ttl_anon}, {name: token_ttl_device, var: token_ttl_device}, {name: token_ttl_user, var: token_ttl_user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token, dev: $dev, app_id: $app_id, app_secret: $app_secret, auth_service: $auth_service, description: $description, name: $name, reg_service: $reg_service, registration: $registration, token_ttl: $token_ttl, token_ttl_anon: $token_ttl_anon, token_ttl_device: $token_ttl_device, token_ttl_user: $token_ttl_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# WEBHOOKS - Returns webhooks in the system
#
# GET /admin/v/4/webhook/{systemKey}
# Returns: table<auth_method: string, description: string, id: string, name: string, service_name: string, system_key: string, system_secret: string>
# operationId: GetWebhooks
export def "get-webhooks" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/admin/v/4/webhook/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# WEBHOOKS - Delete a webhook
#
# DELETE /admin/v/4/webhook/{systemKey}/{name}
# Returns: record<success: bool>
# operationId: DeleteWebhook
export def "delete-webhook" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/admin/v/4/webhook/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# WEBHOOKS - Creates a webhook
#
# POST /admin/v/4/webhook/{systemKey}/{name}
# Returns: record<success: bool>
# operationId: CreateWebhook
export def "create-webhook" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
  auth_method: string # e.g. http_basic_auth
  --description: string # e.g. Create a webhook
  --body-name: string # e.g. webhook_example (spec name: name)
  service_name: string # e.g. service_example
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/v/4/webhook/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: auth_method, var: auth_method}, {name: description, var: description}, {name: name, var: body_name, required: true}, {name: service_name, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_dev_token: $clear_blade_dev_token, auth_method: $auth_method, description: $description, body_name: $body_name, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# WEBHOOKS - Update a webhook
#
# PUT /admin/v/4/webhook/{systemKey}/{name}
# operationId: UpdateWebhook
export def "update-webhook" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
  auth_method: string # e.g. http_basic_auth
  --description: string # e.g. Create a webhook
]: any -> any {
  $in | http-request {
    method: put
    path: "/admin/v/4/webhook/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: auth_method, var: auth_method}, {name: description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_dev_token: $clear_blade_dev_token, auth_method: $auth_method, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 2FA - Send validation link
#
# POST /admin/validate
# Returns: record<success: bool>
# operationId: SendValidation
export def "send-validation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --type: string # e.g. email
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/validate"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# EDGE - Gets sync status for all edges
#
# GET /admin/{systemKey}/sync/alledges/status
# operationId: AllEdgeSyncStatus
export def "all-edge-sync-status" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Token obtained through dev authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/{systemKey}/sync/alledges/status"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEPLOYMENTS - Gets sync status for a deployment
#
# GET /admin/{systemKey}/sync/deployment/status/{deploymentName}
# operationId: GetSyncStatus
export def "get-sync-status" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through user authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/{systemKey}/sync/deployment/status/{deploymentName}"
    path_params: [{name: systemKey, var: system_key}, {name: deploymentName, var: deployment_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, deployment_name: $deployment_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# EDGE - Gets sync status for an edge
#
# GET /admin/{systemKey}/sync/edge/status/{edgeName}
# operationId: EdgeSyncStatus
export def "edge-sync-status" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Token obtained through dev authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/{systemKey}/sync/edge/status/{edgeName}"
    path_params: [{name: systemKey, var: system_key}, {name: edgeName, var: edge_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, edge_name: $edge_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEPLOYMENTS - Retries sync for an asset
#
# POST /admin/{systemKey}/sync/retry
# operationId: RetrySync
export def "retry-sync" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication. (required)
  --asset-class: string # Asset Type (e.g. services)
  --asset-id: string # e.g. c0f8e2c50bbeeafb87f5efa2eee301
  --edge: string # Edge Name (e.g. ExampleEdge)
  --is-collection: oneof<nothing, bool>
  --sync-event: int # e.g. 0 (Insert)/1 (Update)/2 (Delete)/5 (Upsert)
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/{systemKey}/sync/retry"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: asset_class, var: asset_class}, {name: asset_id, var: asset_id}, {name: edge, var: edge}, {name: is_collection, var: is_collection}, {name: sync_event, var: sync_event}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token, asset_class: $asset_class, asset_id: $asset_id, edge: $edge, is_collection: $is_collection, sync_event: $sync_event
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Gets the information for the platform
#
# GET /api/about
# Returns: record<about: record, buildId: string, version: string>
# operationId: APIInfo
export def "api-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/api/about"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CODE - Retrieve information about service
#
# GET /api/v/1/code/{systemKey}/{serviceName}
# operationId: GetService
export def "get-service" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v/1/code/{systemKey}/{serviceName}"
    path_params: [{name: systemKey, var: system_key}, {name: serviceName, var: service_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, service_name: $service_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CODE - Call/Execute code service
#
# POST /api/v/1/code/{systemKey}/{serviceName}
# operationId: ExecuteService
export def "execute-service" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v/1/code/{systemKey}/{serviceName}"
    path_params: [{name: systemKey, var: system_key}, {name: serviceName, var: service_name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, service_name: $service_name, clear_blade_user_token: $clear_blade_user_token, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA(name) - Delete items
#
# DELETE /api/v/1/collection/{systemKey}/{collectionName}
# Returns: record
# operationId: DeleteCollectionData
export def "delete-collection-data" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query to limit scope of deletion. (required)
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/v/1/collection/{systemKey}/{collectionName}"
    path_params: [{name: systemKey, var: system_key}, {name: collectionName, var: collection_name}]
    query: [{name: query, var: query, required: true}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, collection_name: $collection_name, query: $query, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA(name) - Get items
#
# GET /api/v/1/collection/{systemKey}/{collectionName}
# Returns: record<CURRENTPAGE: int, DATA: list<record>, NEXTPAGEURL: string, PREVPAGEURL: int, TOTAL: int>
# operationId: GetCollectionData
export def "get-collection-data" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model below for example.
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/1/collection/{systemKey}/{collectionName}"
    path_params: [{name: systemKey, var: system_key}, {name: collectionName, var: collection_name}]
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, collection_name: $collection_name, query: $query, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA(name) - Create items
#
# POST /api/v/1/collection/{systemKey}/{collectionName}
# Returns: table<item_id: string>
# operationId: CreateCollectionData
export def "create-collection-data" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v/1/collection/{systemKey}/{collectionName}"
    path_params: [{name: systemKey, var: system_key}, {name: collectionName, var: collection_name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, collection_name: $collection_name, clear_blade_user_token: $clear_blade_user_token, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA(name) - Update items
#
# PUT /api/v/1/collection/{systemKey}/{collectionName}
# Returns: record
# operationId: UpdateCollectionData
export def "update-collection-data" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  --set: record # shape: {columnName?: any}
  --query: any # shape: {FILTERS?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v/1/collection/{systemKey}/{collectionName}"
    path_params: [{name: systemKey, var: system_key}, {name: collectionName, var: collection_name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: "$set", var: set}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, collection_name: $collection_name, clear_blade_user_token: $clear_blade_user_token, set: $set, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA(id) - Delete items
#
# DELETE /api/v/1/data/{collectionID}
# Returns: record
# operationId: DeleteCollectionDataAlt
export def "delete-collection-data-alt" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query to limit scope of deletion. (required)
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/v/1/data/{collectionID}"
    path_params: [{name: collectionID, var: collection_id}]
    query: [{name: query, var: query, required: true}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, query: $query, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA(id) - Get items
#
# GET /api/v/1/data/{collectionID}
# Returns: record<CURRENTPAGE: int, DATA: list<record>, NEXTPAGEURL: string, PREVPAGEURL: int, TOTAL: int>
# operationId: GetCollectionDataAlt
export def "get-collection-data-alt" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model below for example.
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/1/data/{collectionID}"
    path_params: [{name: collectionID, var: collection_id}]
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, query: $query, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA(id) - Create items
#
# POST /api/v/1/data/{collectionID}
# Returns: table<item_id: string>
# operationId: CreateCollectionDataAlt
export def "create-collection-data-alt" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v/1/data/{collectionID}"
    path_params: [{name: collectionID, var: collection_id}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, clear_blade_user_token: $clear_blade_user_token, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA(id) - Update items
#
# PUT /api/v/1/data/{collectionID}
# Returns: record
# operationId: UpdateCollectionDataAlt
export def "update-collection-data-alt" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  --set: record # shape: {columnName?: any}
  --query: any # shape: {FILTERS?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v/1/data/{collectionID}"
    path_params: [{name: collectionID, var: collection_id}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: "$set", var: set}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, clear_blade_user_token: $clear_blade_user_token, set: $set, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA(id) - Get columns
#
# GET /api/v/1/data/{collectionID}/columns
# Returns: table<ColumnName: string, ColumnType: string, PK: bool>
# operationId: GetColumns
export def "get-columns" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  --clear-blade-system-key: string # System Key that identifies the system that holds the collection. (required)
  --clear-blade-system-secret: string # header parameter for ensuring authenticity (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/1/data/{collectionID}/columns"
    path_params: [{name: collectionID, var: collection_id}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}, {name: ClearBlade-SystemKey, var: clear_blade_system_key, required: true}, {name: ClearBlade-SystemSecret, var: clear_blade_system_secret, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, clear_blade_user_token: $clear_blade_user_token, clear_blade_system_key: $clear_blade_system_key, clear_blade_system_secret: $clear_blade_system_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# MESSAGING - Delete history
#
# DELETE /api/v/1/message/{systemKey}
# operationId: DeleteMessageHistory
export def "delete-message-history" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --topic: string # Messaging topic to delete the history for. (required)
  --count: string # Number of messages to delete. 0 deletes all messages. (required)
  --last: string # Point in time to start deleting. (epoch timestamp)
  --start: string # Start time for deleting within a timeframe. (epoch timestamp)
  --stop: string # End time for deleting within a timeframe. (epoch timestamp)
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v/1/message/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: topic, var: topic, required: true}, {name: count, var: count, required: true}, {name: last, var: last}, {name: start, var: start}, {name: stop, var: stop}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, topic: $topic, count: $count, last: $last, start: $start, stop: $stop, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# MESSAGING - Get history
#
# GET /api/v/1/message/{systemKey}
# operationId: GetMessageHistory
export def "get-message-history" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --topic: string # Messaging topic to retrieve the history for. (required)
  --count: string # Number of messages to retrieve. 0 retrieves all messages. (required)
  --last: string # Point in time to start search. (epoch timestamp)
  --start: string # Start time for searching within a timeframe. (epoch timestamp)
  --stop: string # End time for searching within a timeframe. (epoch timestamp)
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v/1/message/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: topic, var: topic, required: true}, {name: count, var: count, required: true}, {name: last, var: last}, {name: start, var: start}, {name: stop, var: stop}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, topic: $topic, count: $count, last: $last, start: $start, stop: $stop, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# MESSAGING - Publish message
#
# POST /api/v/1/message/{systemKey}/publish
# operationId: PublishMessage
export def "publish-message" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  --body: string # e.g. {"temperature":43}
  --qos: float # e.g. 0
  topic: string # e.g. /sensor/111111
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v/1/message/{systemKey}/publish"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: qos, var: qos}, {name: topic, var: topic}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_user_token: $clear_blade_user_token, body: $body, qos: $qos, topic: $topic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# USERS - Get all users
#
# GET /api/v/1/user
# Returns: record<Data: table<creation_date: string, email: string, user_id: string>, Total: int>
# operationId: GetUsers
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
  --query: string # Query object used to filter the user list. See the query model below for an example.
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/1/user"
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# USERS - Authenticate anonymous user
#
# POST /api/v/1/user/anon
# Returns: record<user_token: string>
# operationId: AuthAnon
export def "auth-anon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-system-key: string # System Key that identifies the system you're logging the user into. (required)
  --clear-blade-system-secret: string # System Secret that ensures authenticity. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/v/1/user/anon"
    header: [{name: ClearBlade-SystemKey, var: clear_blade_system_key, required: true}, {name: ClearBlade-SystemSecret, var: clear_blade_system_secret, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_system_key: $clear_blade_system_key, clear_blade_system_secret: $clear_blade_system_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# USERS - Authenticate user
#
# POST /api/v/1/user/auth
# Returns: record<expires_at: int, refresh_token: string, user_id: string, user_token: string>
# operationId: AuthUser
export def "auth-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-system-key: string # System Key that identifies the system you're logging the user into. (required)
  --clear-blade-system-secret: string # System Secret that ensures authenticity. (required)
  --email: string # e.g. cbman@clearblade.com
  --password: string # e.g. cl34rbl4d3
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v/1/user/auth"
    header: [{name: ClearBlade-SystemKey, var: clear_blade_system_key, required: true}, {name: ClearBlade-SystemSecret, var: clear_blade_system_secret, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_system_key: $clear_blade_system_key, clear_blade_system_secret: $clear_blade_system_secret, email: $email, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# USERS - Check user auth
#
# POST /api/v/1/user/checkauth
# Returns: record<is_authenticated: bool>
# operationId: UserCheckAuth
export def "user-check-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-system-key: string # System Key that identifies the system the user might be logged into. (required)
  --clear-blade-user-token: string # User Token obtained through previous authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/v/1/user/checkauth"
    header: [{name: ClearBlade-SystemKey, var: clear_blade_system_key, required: true}, {name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_system_key: $clear_blade_system_key, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows an user with adequate permissions to delete another user
#
# DELETE /api/v/1/user/info
# operationId: DeleteUserAsUser
export def "delete-user-as-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  --clear-blade-system-key: string # required
  --clear-blade-system-secret: string # required
  --user-id: string # e.g. c6b4cf0b8ca5b7c3fad793cb12
]: any -> any {
  $in | http-request {
    method: delete
    path: "/api/v/1/user/info"
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}, {name: ClearBlade-SystemKey, var: clear_blade_system_key, required: true}, {name: ClearBlade-SystemSecret, var: clear_blade_system_secret, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_user_token: $clear_blade_user_token, clear_blade_system_key: $clear_blade_system_key, clear_blade_system_secret: $clear_blade_system_secret, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# USERS - Get user info
#
# GET /api/v/1/user/info
# Returns: record<creation_date: string, email: string, user_id: string>
# operationId: GetUserInfo
export def "get-user-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/1/user/info"
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# USERS - Update user info
#
# PUT /api/v/1/user/info
# operationId: UpdateUserInfo
export def "update-user-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  --column-name: string # e.g. column_value
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v/1/user/info"
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: column_name, var: column_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_user_token: $clear_blade_user_token, column_name: $column_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# USERS - Log out user
#
# POST /api/v/1/user/logout
# operationId: UserLogout
export def "user-logout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v/1/user/logout"
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# USERS - Change user password
#
# PUT /api/v/1/user/pass
# operationId: UpdateUserPass
export def "update-user-pass" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  new_password: string # e.g. P@ssw0rd
  old_password: string # e.g. cl34rbl4d3
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v/1/user/pass"
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: new_password, var: new_password}, {name: old_password, var: old_password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_user_token: $clear_blade_user_token, new_password: $new_password, old_password: $old_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# USERS - Register new user
#
# POST /api/v/1/user/reg
# Returns: record<creation_date: string, email: string, expires_at: int, options: string, refresh_token: string, user_id: string, user_token: string>
# operationId: RegUser
export def "reg-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-system-key: string # System Key that identifies the system you're adding the user to. (required)
  --clear-blade-system-secret: string # System Secret that ensures authenticity. (required)
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  email: string # User's email. (e.g. cbman@clearblade.com)
  password: string # User's password. (e.g. cl34rbl4d3)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v/1/user/reg"
    header: [{name: ClearBlade-SystemKey, var: clear_blade_system_key, required: true}, {name: ClearBlade-SystemSecret, var: clear_blade_system_secret, required: true}, {name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_system_key: $clear_blade_system_key, clear_blade_system_secret: $clear_blade_system_secret, clear_blade_user_token: $clear_blade_user_token, email: $email, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVICES - Delete devices using a query
#
# DELETE /api/v/2/devices/{SystemKey}
# operationId: DeleteDevices
export def "delete-devices" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter devices by. See the query model below for an example. (required)
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v/2/devices/{SystemKey}"
    path_params: [{name: SystemKey, var: system_key}]
    query: [{name: query, var: query, required: true}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVICES - Get all devices
#
# GET /api/v/2/devices/{SystemKey}
# Returns: record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, created_date: int, description: string, device_key: string, enabled: bool, last_active_date: int, name: string, state: string, system_key: string, type: string>
# operationId: GetDevices
export def "get-devices" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter devices by. See the query model below for an example.
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/2/devices/{SystemKey}"
    path_params: [{name: SystemKey, var: system_key}]
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVICES - Update devices using a query
#
# PUT /api/v/2/devices/{SystemKey}
# Returns: record<DATA: list<record>, TOTAL: int>
# operationId: UpdateDevices
export def "update-devices" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  --set: record # shape: {[columnName]?: any}
  --query: list # item shape: {EQ?: list, GT?: list, GTE?: list, LT?: list, LTE?: list, NEQ?: list, RE?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v/2/devices/{SystemKey}"
    path_params: [{name: SystemKey, var: system_key}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: "$set", var: set}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_user_token: $clear_blade_user_token, set: $set, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVICES - Authenticate device
#
# POST /api/v/2/devices/{SystemKey}/auth
# Returns: record<deviceName: string, deviceToken: string, expiresAt: int, refreshToken: string>
# operationId: AuthDevice
export def "auth-device" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  active_key: string # e.g. 378BLE
  device_name: string # e.g. BLEdevice
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v/2/devices/{SystemKey}/auth"
    path_params: [{name: SystemKey, var: system_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: activeKey, var: active_key}, {name: deviceName, var: device_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, active_key: $active_key, device_name: $device_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVICES - Adds a device
#
# POST /api/v/2/devices/{systemKey}/{name}
# Returns: record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, created_date: int, description: string, device_key: string, enabled: bool, last_active_date: int, name: string, state: string, system_key: string, type: string>
# operationId: AddDevice
export def "add-device" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  --active-key: string # e.g. 1574445864
  --allow-certificate-auth: oneof<nothing, bool>
  --allow-key-auth: oneof<nothing, bool>
  --certificate: string
  --description: string # e.g. This is a sensor
  --body-name: string # e.g. device_name (spec name: name)
  --state: string # e.g. On
  --type: string # e.g. Sensor
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v/2/devices/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: active_key, var: active_key}, {name: allow_certificate_auth, var: allow_certificate_auth}, {name: allow_key_auth, var: allow_key_auth}, {name: certificate, var: certificate}, {name: description, var: description}, {name: name, var: body_name}, {name: state, var: state}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token, active_key: $active_key, allow_certificate_auth: $allow_certificate_auth, allow_key_auth: $allow_key_auth, certificate: $certificate, description: $description, body_name: $body_name, state: $state, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVICES - Update info
#
# PUT /api/v/2/devices/{systemKey}/{name}
# Returns: record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, created_date: int, description: string, device_key: string, enabled: bool, last_active_date: int, name: string, state: string, system_key: string, type: string>
# operationId: UpdateDeviceInfo
export def "update-device-info" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  --custom-attribute: string # e.g. custom_setting
  --state: string # e.g. On
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v/2/devices/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_attribute, var: custom_attribute}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token, custom_attribute: $custom_attribute, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# EDGE - Fetch all edges
#
# GET /api/v/2/edges/{systemKey}
# operationId: GetAllEdges
export def "get-all-edges" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # System Key that identifies the system you want the info about. (required)
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v/2/edges/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: id, var: id, required: true}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, id: $id, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA - Get collections
#
# GET /api/v/3/allcollections/{systemKey}
# Returns: table<appID: string, collectionID: string, name: string>
# operationId: GetCollections
export def "get-collections" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/3/allcollections/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CODE - Returns code services and settings
#
# GET /api/v/3/code/codemeta/{systemKey}
# Returns: record<code: table<auto_balance: bool, auto_balance_euid: string, auto_restart: bool, concurrency: int, euid: string, execution_timeout: int, logging_enabled: bool, name: string, namespace: string, system_key: string, uuid: string, version: int, version_id: string>>
# operationId: ReturnServiceSettings
export def "return-service-settings" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/3/code/codemeta/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# HANDLERS - Delete trigger handler
#
# DELETE /api/v/3/code/{systemKey}/timer/{name}
# operationId: DeleteTimerByName
export def "delete-timer-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v/3/code/{systemKey}/timer/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# HANDLERS - Get timer handler
#
# GET /api/v/3/code/{systemKey}/timer/{name}
# Returns: record<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string>
# operationId: GetTimerByName
export def "get-timer-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/3/code/{systemKey}/timer/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# HANDLERS - Create timer handler
#
# POST /api/v/3/code/{systemKey}/timer/{name}
# Returns: record<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string>
# operationId: CreateNewTimer
export def "create-new-timer" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  --description: string # Information about the timer (e.g. My 10 second timer)
  --disabled: oneof<nothing, bool> # Enable or disable timer (e.g. true)
  frequency: int # Frequency (in seconds) between two consecutive invocations of a timer handler (e.g. 10)
  --body-name: string # Timer label (e.g. tenSecondTimer) (spec name: name)
  repeats: int # The number of times a timer handler is invoked. To invoke the handler indefinitely set 'repeats = -1' (e.g. 20)
  service_name: string # The handler service invoked by the timer (e.g. getTemps)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v/3/code/{systemKey}/timer/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: disabled, var: disabled, required: true}, {name: frequency, var: frequency}, {name: name, var: body_name, required: true}, {name: repeats, var: repeats}, {name: service_name, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token, description: $description, disabled: $disabled, frequency: $frequency, body_name: $body_name, repeats: $repeats, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# HANDLERS - Update timer handler
#
# PUT /api/v/3/code/{systemKey}/timer/{name}
# Returns: record<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string>
# operationId: UpdateTimerByName
export def "update-timer-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  --description: string # Information about the timer (e.g. My 10 second timer)
  --disabled: oneof<nothing, bool> # Enable or disable timer (e.g. true)
  frequency: int # Frequency (in seconds) between two consecutive invocations of a timer handler (e.g. 10)
  --body-name: string # Timer label (e.g. tenSecondTimer) (spec name: name)
  repeats: int # The number of times a timer handler is invoked. To invoke the handler indefinitely set 'repeats = -1' (e.g. 20)
  service_name: string # The handler service invoked by the timer (e.g. getTemps)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v/3/code/{systemKey}/timer/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: disabled, var: disabled, required: true}, {name: frequency, var: frequency}, {name: name, var: body_name, required: true}, {name: repeats, var: repeats}, {name: service_name, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token, description: $description, disabled: $disabled, frequency: $frequency, body_name: $body_name, repeats: $repeats, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# HANDLERS - Get timer handlers
#
# GET /api/v/3/code/{systemKey}/timers
# Returns: table<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string>
# operationId: GetAllTimers
export def "get-all-timers" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/3/code/{systemKey}/timers"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# HANDLERS - Delete trigger handler
#
# DELETE /api/v/3/code/{systemKey}/trigger/{name}
# operationId: DeleteTriggerByName
export def "delete-trigger-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v/3/code/{systemKey}/trigger/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# HANDLERS - Get trigger handler
#
# GET /api/v/3/code/{systemKey}/trigger/{name}
# Returns: table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string>
# operationId: GetTriggerByName
export def "get-trigger-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/3/code/{systemKey}/trigger/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# HANDLERS - Create trigger handler
#
# POST /api/v/3/code/{systemKey}/trigger/{name}
# Returns: table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string>
# operationId: CreateNewTrigger
export def "create-new-trigger" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  def_module: string # e.g. Messaging
  def_name: string # e.g. Publish
  --disabled: oneof<nothing, bool> # Enable or disable trigger (e.g. true)
  key_value_pairs: any # shape: {topic?: string}
  service_name: string # e.g. updateTemps
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v/3/code/{systemKey}/trigger/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: def_module, var: def_module}, {name: def_name, var: def_name}, {name: disabled, var: disabled, required: true}, {name: key_value_pairs, var: key_value_pairs}, {name: service_name, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token, def_module: $def_module, def_name: $def_name, disabled: $disabled, key_value_pairs: $key_value_pairs, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# HANDLERS - Update trigger handler
#
# PUT /api/v/3/code/{systemKey}/trigger/{name}
# Returns: table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string>
# operationId: UpdateTriggerByName
export def "update-trigger-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  def_module: string # e.g. Messaging
  def_name: string # e.g. Publish
  --disabled: oneof<nothing, bool> # Enable or disable trigger (e.g. true)
  key_value_pairs: any # shape: {topic?: string}
  service_name: string # e.g. updateTemps
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v/3/code/{systemKey}/trigger/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: def_module, var: def_module}, {name: def_name, var: def_name}, {name: disabled, var: disabled, required: true}, {name: key_value_pairs, var: key_value_pairs}, {name: service_name, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token, def_module: $def_module, def_name: $def_name, disabled: $disabled, key_value_pairs: $key_value_pairs, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# HANDLERS - Get trigger handlers
#
# GET /api/v/3/code/{systemKey}/triggers
# Returns: table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string>
# operationId: GetAllTrigger
export def "get-all-trigger" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/3/code/{systemKey}/triggers"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA - Delete collection
#
# DELETE /api/v/3/collectionmanagement
# operationId: DeleteCollection
export def "delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # ID that identifies the collection to be deleted. (required)
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  --clear-blade-system-key: string # System Key that identifies the system you're adding the user to. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v/3/collectionmanagement"
    query: [{name: id, var: id, required: true}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}, {name: ClearBlade-SystemKey, var: clear_blade_system_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, clear_blade_user_token: $clear_blade_user_token, clear_blade_system_key: $clear_blade_system_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA - Create collection
#
# POST /api/v/3/collectionmanagement
# Returns: record<appID: string, collectionID: string, name: string>
# operationId: CreateCollection
export def "create-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  --clear-blade-system-key: string # System Key that identifies the system you're adding the user to. (required)
  app_id: string # This is the system key (e.g. c0f8e2c50bbeeaf87f5efa2eee301)
  --collection-id: string # e.g. c0f8e2c50bbeeafb87f5efa2eee301
  name: string # e.g. newCollection
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v/3/collectionmanagement"
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}, {name: ClearBlade-SystemKey, var: clear_blade_system_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: appID, var: app_id}, {name: collectionID, var: collection_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_user_token: $clear_blade_user_token, clear_blade_system_key: $clear_blade_system_key, app_id: $app_id, collection_id: $collection_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA - Update collection
#
# PUT /api/v/3/collectionmanagement
# operationId: UpdateCollection
export def "update-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  --clear-blade-system-key: string # System Key that identifies the system you're adding the user to. (required)
  --add-column: any # shape: {id: string, name: string, type: string}
  id: string # This is the collection ID (e.g. c0f8e2c50bbeeafb87f5efa2eee301)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v/3/collectionmanagement"
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}, {name: ClearBlade-SystemKey, var: clear_blade_system_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: addColumn, var: add_column}, {name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_user_token: $clear_blade_user_token, clear_blade_system_key: $clear_blade_system_key, add_column: $add_column, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# EDGE - Get device columns
#
# GET /api/v/3/devices/{systemKey}/columns
# Returns: table<ColumnName: string, ColumnType: string, PK: bool>
# operationId: GetDeviceTableSchema
export def "get-device-table-schema" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/3/devices/{systemKey}/columns"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVICES - Get count
#
# GET /api/v/3/devices/{systemKey}/count
# Returns: record
# operationId: GetDeviceCount
export def "get-device-count" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/3/devices/{systemKey}/count"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# EDGE - Get columns
#
# GET /api/v/3/edges/{systemKey}/columns
# operationId: GetEdgeTableSchema
export def "get-edge-table-schema" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v/3/edges/{systemKey}/columns"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# EDGE - Get count
#
# GET /api/v/3/edges/{systemKey}/count
# operationId: GetEdgeCount
export def "get-edge-count" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v/3/edges/{systemKey}/count"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edge - Delete edge
#
# DELETE /api/v/3/edges/{systemKey}/{name}
# operationId: DeleteEdgeByName
export def "delete-edge-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v/3/edges/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edge(name) - Get edge info
#
# GET /api/v/3/edges/{systemKey}/{name}
# operationId: GetEdgeDataByName
export def "get-edge-data-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v/3/edges/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# EDGE - Create edge
#
# POST /api/v/3/edges/{systemKey}/{name}
# operationId: CreateNewEdge
export def "create-new-edge" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Developer Token obtained through admin authentication. (required)
  --description: string
  --local-addr: string
  --local-port: string
  --location: string
  --mac-address: string
  --public-addr: string
  --public-port: string
  --body-system-key: string # (spec name: system_key)
  system_secret: string
  --body-token: string # (spec name: token)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v/3/edges/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: local_addr, var: local_addr}, {name: local_port, var: local_port}, {name: location, var: location}, {name: mac_address, var: mac_address}, {name: public_addr, var: public_addr}, {name: public_port, var: public_port}, {name: system_key, var: body_system_key, required: true}, {name: system_secret, var: system_secret}, {name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token, description: $description, local_addr: $local_addr, local_port: $local_port, location: $location, mac_address: $mac_address, public_addr: $public_addr, public_port: $public_port, body_system_key: $body_system_key, system_secret: $system_secret, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# EDGE - Update edge
#
# PUT /api/v/3/edges/{systemKey}/{name}
# operationId: UpdateEdgeByName
export def "update-edge-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Developer Token obtained through admin authentication. (required)
  --description: string
  --local-addr: string
  --local-port: string
  --location: string
  --mac-address: string
  --public-addr: string
  --public-port: string
  --body-system-key: string # (spec name: system_key)
  system_secret: string
  --body-token: string # (spec name: token)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v/3/edges/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: local_addr, var: local_addr}, {name: local_port, var: local_port}, {name: location, var: location}, {name: mac_address, var: mac_address}, {name: public_addr, var: public_addr}, {name: public_port, var: public_port}, {name: system_key, var: body_system_key, required: true}, {name: system_secret, var: system_secret}, {name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token, description: $description, local_addr: $local_addr, local_port: $local_port, location: $location, mac_address: $mac_address, public_addr: $public_addr, public_port: $public_port, body_system_key: $body_system_key, system_secret: $system_secret, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEPLOYMENTS - Gets all deployment names and descriptions for a system
#
# GET /api/v/3/{systemKey}/deployments
# Returns: table<description: string, name: string>
# operationId: GetAllDeployments
export def "get-all-deployments" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter deployments by. See the query model above for an example.
  --clear-blade-user-token: string # User Token obtained through user authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/3/{systemKey}/deployments"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEPLOYMENTS - Creates a deployment
#
# POST /api/v/3/{systemKey}/deployments
# operationId: CreateDeployment
export def "create-deployment" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through user authentication. (required)
  --assets: list # item shape: {asset_class?: string, asset_id?: string, sync_to_edge?: bool, sync_to_platform?: bool}
  --edges: list # Names of edges to be included in the deployment (e.g. [edge1, edge2, edge3])
  name: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v/3/{systemKey}/deployments"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: edges, var: edges}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_user_token: $clear_blade_user_token, assets: $assets, edges: $edges, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEPLOYMENT - Delete a deployment
#
# DELETE /api/v/3/{systemKey}/deployments/{deploymentName}
# operationId: DeleteDeployment
export def "delete-deployment" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through user authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v/3/{systemKey}/deployments/{deploymentName}"
    path_params: [{name: systemKey, var: system_key}, {name: deploymentName, var: deployment_name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, deployment_name: $deployment_name, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEPLOYMENTS - Gets a deloyment for a system
#
# GET /api/v/3/{systemKey}/deployments/{deploymentName}
# operationId: GetADeployment
export def "get-a-deployment" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clearblade-usertoken: string # User Token obtained through user authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v/3/{systemKey}/deployments/{deploymentName}"
    path_params: [{name: systemKey, var: system_key}, {name: deploymentName, var: deployment_name}]
    header: [{name: clearblade-usertoken, var: clearblade_usertoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, deployment_name: $deployment_name, clearblade_usertoken: $clearblade_usertoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEPLOYMENT - Update deployment
#
# PUT /api/v/3/{systemKey}/deployments/{deploymentName}
# operationId: UpdateDeployment
export def "update-deployment" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through user authentication. (required)
  assets: record # Assets to be added and removed from deployment — shape: {add?: list, remove?: list}
  edges: record # Edges to be added and removed from deployment — shape: {adds?: list<string>, removes?: list<string>}
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v/3/{systemKey}/deployments/{deploymentName}"
    path_params: [{name: systemKey, var: system_key}, {name: deploymentName, var: deployment_name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: edges, var: edges}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, deployment_name: $deployment_name, clear_blade_user_token: $clear_blade_user_token, assets: $assets, edges: $edges
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# FILES - Returns a list of metadata for buckets in system
#
# GET /api/v/4/bucket_sets/{systemKey}
# Returns: table<deployment_name: string, edge_config: list<any>, edge_storage: string, platform_config: list<any>, platform_storage: string, system_key: string>
# operationId: GetBucketsData
export def "get-buckets-data" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/4/bucket_sets/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# FILES - Returns metadata for specified bucket
#
# GET /api/v/4/bucket_sets/{systemKey}/{deploymentName}
# Returns: record<deployment_name: string, edge_config: list<any>, edge_storage: string, platform_config: list<any>, platform_storage: string, system_key: string>
# operationId: GetSingleBucketData
export def "get-single-bucket-data" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/4/bucket_sets/{systemKey}/{deploymentName}"
    path_params: [{name: systemKey, var: system_key}, {name: deploymentName, var: deployment_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, deployment_name: $deployment_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# FILES - Copies a file to a new location within buckets
#
# POST /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/copy
# operationId: CopyBucketFile
export def "copy-bucket-file" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --from-box: string # Box Name where file is being copied/moved (e.g. inbox)
  --from-path: string # Relative File Path Name where file is being copied/moved (e.g. /relative/file/path)
  --to-box: string # Box Name of where file is being copied/moved to (e.g. inbox)
  --to-path: string # Relative File Path Name where file is being copied/moved to (e.g. /relative/file/path)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/copy"
    path_params: [{name: systemKey, var: system_key}, {name: deploymentName, var: deployment_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: from_box, var: from_box}, {name: from_path, var: from_path}, {name: to_box, var: to_box}, {name: to_path, var: to_path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, deployment_name: $deployment_name, clear_blade_dev_token: $clear_blade_dev_token, from_box: $from_box, from_path: $from_path, to_box: $to_box, to_path: $to_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# FILES - Creates a new file in a bucket
#
# POST /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/create
# Returns: record<base_name: string, bucket_name: string, last_modified: string, path_name: string, permissions: string, relative_name: string, size: int>
# operationId: CreateBucketFile
export def "create-bucket-file" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --box: string # Box Name (e.g. inbox)
  --contents: string # base64 encoded file contents (e.g. IyEvYmluL2Jhc2gKbWtkaXIgU2hvd1RpbWVBZGFwdGVyCgptdiBzdGFydC5zaCBTaG93VGltZUFkYXB0ZXIKbXYgc3RvcC5zaCBTaG93VGltZUFkYXB0ZXIKbXYgc3RhdHVzLnNoIFNob3dUaW1lQWRhcHRlcgptdiBkZXBsb3kuc2ggU2hvd1RpbWVBZGFwdGVyCm12IHVuZGVwbG95LnNoIFNob3dUaW1lQWRhcHRlcgptdiBzaG93VGltZSBTaG93VGltZUFkYXB0ZXIKCmVjaG8gIlNob3dUaW1lQWRhcHRlciBEZXBsb3llZCI=)
  --path: string # Relative File Path (e.g. /relative/file/path)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/create"
    path_params: [{name: systemKey, var: system_key}, {name: deploymentName, var: deployment_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: box, var: box}, {name: contents, var: contents}, {name: path, var: path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, deployment_name: $deployment_name, clear_blade_dev_token: $clear_blade_dev_token, box: $box, contents: $contents, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# FILES - Deletes a file from the bucket.
#
# POST /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/delete
# operationId: DeleteBucketFile
export def "delete-bucket-file" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --box: string # Box Name of file being deleted (e.g. inbox)
  --path: string # Relative File Path Name of file being deleted (e.g. /relative/file/path)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/delete"
    path_params: [{name: systemKey, var: system_key}, {name: deploymentName, var: deployment_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: box, var: box}, {name: path, var: path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, deployment_name: $deployment_name, clear_blade_dev_token: $clear_blade_dev_token, box: $box, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# FILES - Get a file's metadata in a box
#
# GET /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/meta
# Returns: record<base_name: string, bucket_name: string, last_modified: string, path_name: string, permissions: string, relative_name: string, size: int>
# operationId: GetBoxFilesMeta
export def "get-box-files-meta" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --box: string # one of inbox, outbox or sandbox, defaults to 'inbox' if empty.
  --path: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/meta"
    path_params: [{name: systemKey, var: system_key}, {name: deploymentName, var: deployment_name}]
    query: [{name: box, var: box}, {name: path, var: path}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, deployment_name: $deployment_name, box: $box, path: $path, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# FILES - Moves a file to a new location within buckets.
#
# POST /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/move
# operationId: MoveBucketFile
export def "move-bucket-file" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --from-box: string # Box Name where file is being copied/moved (e.g. inbox)
  --from-path: string # Relative File Path Name where file is being copied/moved (e.g. /relative/file/path)
  --to-box: string # Box Name of where file is being copied/moved to (e.g. inbox)
  --to-path: string # Relative File Path Name where file is being copied/moved to (e.g. /relative/file/path)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/move"
    path_params: [{name: systemKey, var: system_key}, {name: deploymentName, var: deployment_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: from_box, var: from_box}, {name: from_path, var: from_path}, {name: to_box, var: to_box}, {name: to_path, var: to_path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, deployment_name: $deployment_name, clear_blade_dev_token: $clear_blade_dev_token, from_box: $from_box, from_path: $from_path, to_box: $to_box, to_path: $to_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# FILES - Get all files metadata in a box
#
# GET /api/v/4/bucket_sets/{systemKey}/{deploymentName}/files
# Returns: record<"example/full/path/to/file.txt": record<base_name: string, bucket_name: string, last_modified: string, path_name: string, permissions: string, relative_name: string, size: int>>
# operationId: GetBoxFiles
export def "get-box-files" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --box: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/4/bucket_sets/{systemKey}/{deploymentName}/files"
    path_params: [{name: systemKey, var: system_key}, {name: deploymentName, var: deployment_name}]
    query: [{name: box, var: box}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, deployment_name: $deployment_name, box: $box, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA - Delete collection
#
# DELETE /api/v/4/data/{systemKey}/{collectionName}/index
# Returns: record<success: bool>
# operationId: DeleteNonUniqueIndex
export def "delete-non-unique-index" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --column-name: string # required
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/v/4/data/{systemKey}/{collectionName}/index"
    path_params: [{name: systemKey, var: system_key}, {name: collectionName, var: collection_name}]
    query: [{name: columnName, var: column_name, required: true}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, collection_name: $collection_name, column_name: $column_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA - Create collection
#
# POST /api/v/4/data/{systemKey}/{collectionName}/index
# Returns: record<success: bool>
# operationId: CreateNonUniqueIndex
export def "create-non-unique-index" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --column-name: string # required
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/v/4/data/{systemKey}/{collectionName}/index"
    path_params: [{name: systemKey, var: system_key}, {name: collectionName, var: collection_name}]
    query: [{name: columnName, var: column_name, required: true}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, collection_name: $collection_name, column_name: $column_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA - Get list of indexes
#
# GET /api/v/4/data/{systemKey}/{collectionName}/listindexes
# Returns: record<Data: table<name: string, type: string>, Total: int>
# operationId: GetIndexes
export def "get-indexes" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/4/data/{systemKey}/{collectionName}/listindexes"
    path_params: [{name: systemKey, var: system_key}, {name: collectionName, var: collection_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, collection_name: $collection_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA - Delete unique index
#
# DELETE /api/v/4/data/{systemKey}/{collectionName}/uniqueindex
# Returns: record<success: bool>
# operationId: DeleteUniqueIndex
export def "delete-unique-index" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --column-name: string # required
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/v/4/data/{systemKey}/{collectionName}/uniqueindex"
    path_params: [{name: systemKey, var: system_key}, {name: collectionName, var: collection_name}]
    query: [{name: columnName, var: column_name, required: true}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, collection_name: $collection_name, column_name: $column_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA - Create Unique Index
#
# POST /api/v/4/data/{systemKey}/{collectionName}/uniqueindex
# Returns: record<success: bool>
# operationId: CreateUniqueIndex
export def "create-unique-index" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --column-name: string # required
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/v/4/data/{systemKey}/{collectionName}/uniqueindex"
    path_params: [{name: systemKey, var: system_key}, {name: collectionName, var: collection_name}]
    query: [{name: columnName, var: column_name, required: true}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, collection_name: $collection_name, column_name: $column_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATA - Update upsert values
#
# PUT /api/v/4/data/{systemKey}/{collectionName}/upsert
# operationId: UpdateUpsert
export def "update-upsert" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --conflict-column: string # A column in your table that has a unique constraint. `columnName` can be used. (required)
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication. (required)
]: nothing -> any {
  http-request {
    method: put
    path: "/api/v/4/data/{systemKey}/{collectionName}/upsert"
    path_params: [{name: systemKey, var: system_key}, {name: collectionName, var: collection_name}]
    query: [{name: conflictColumn, var: conflict_column, required: true}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, collection_name: $collection_name, conflict_column: $conflict_column, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVICES - Get total of connected devices
#
# GET /api/v/4/devices/{systemKey}/connectioncount
# Returns: record<total_device_connections: int, total_devices: int, unique_device_connections: int>
# operationId: ConnectedDeviceCount
export def "connected-device-count" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/4/devices/{systemKey}/connectioncount"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVICES - Get connected device list
#
# GET /api/v/4/devices/{systemKey}/connections
# Returns: record<device_name: table<client_id: string, time_connected: string>>
# operationId: GetConnectedDeviceList
export def "get-connected-device-list" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Dev Token obtained through authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/4/devices/{systemKey}/connections"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVICES - Get information for a connected device
#
# GET /api/v/4/devices/{systemKey}/connections/{name}
# Returns: record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, connections: table<client_id: string, time_connected: string>, created_date: int, description: string, device_key: string, enabled: bool, has_keys: bool, last_active_date: int, name: string, state: string, system_key: string, type: string>
# operationId: GetConnectedDeviceInfo
export def "get-connected-device-info" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/4/devices/{systemKey}/connections/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATABASES - Retrieves all external database connections
#
# GET /api/v/4/external-db/{systemKey}
# Returns: table<dbtype: string, name: string>
# operationId: GetAllExternalDB
export def "get-all-external-db" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/4/external-db/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATABASES - Create a external database connection
#
# POST /api/v/4/external-db/{systemKey}
# Returns: record<success: bool>
# operationId: CreateExternalDB
export def "create-external-db" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
  --credentials: any # shape: {address?: string, dbname?: string, password?: string, port?: string, user?: string}
  --dbtype: string # e.g. mysql
  --name: string # e.g. mysql_example
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v/4/external-db/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: credentials, var: credentials}, {name: dbtype, var: dbtype}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token, credentials: $credentials, dbtype: $dbtype, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATABASES - Delete a external database connection
#
# DELETE /api/v/4/external-db/{systemKey}/{name}
# Returns: record<success: bool>
# operationId: DeleteExternalDB
export def "delete-external-db" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/v/4/external-db/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATABASES - Retrieve a specific external database connection
#
# GET /api/v/4/external-db/{systemKey}/{name}
# Returns: record<credentials: record<address: string, dbname: string, password: string, port: string, user: string>, dbtype: string, id: int, name: string, system_key: string>
# operationId: GetExternalDB
export def "get-external-db" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/4/external-db/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATABASES - Update external database credentials
#
# PUT /api/v/4/external-db/{systemKey}/{name}
# Returns: record<address: string, dbname: string, password: string, port: string, user: string>
# operationId: UpdateDatabaseCredentials
export def "update-database-credentials" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through authentication. (required)
  --address: string # e.g. MYSQL_ADDRESS
  --dbname: string # e.g. MYSQL_DATABASE_NAME
  --password: string # e.g. MSQL_PASSWORD
  --port: string # e.g. 3306
  --user: string # e.g. MYSQL_USER
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v/4/external-db/{systemKey}/{name}"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: dbname, var: dbname}, {name: password, var: password}, {name: port, var: port}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token, address: $address, dbname: $dbname, password: $password, port: $port, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DATABASES - Create a external database connection
#
# POST /api/v/4/external-db/{systemKey}/{name}/data
# Returns: record<Data: list<any>, Total: int>
# operationId: PerformDBOperation
export def "perform-db-operation" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through authentication. (required)
  --operation: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v/4/external-db/{systemKey}/{name}/data"
    path_params: [{name: systemKey, var: system_key}, {name: name, var: name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: operation, var: operation}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, name: $name, clear_blade_user_token: $clear_blade_user_token, operation: $operation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# MESSAGING - Gets list of topics
#
# GET /api/v/4/message/{systemKey}/topics
# Returns: table<ip: string, payload: string, payloadsize: int, pk: string, qos: int, time: int, topicid: string, userid: string>
# operationId: GetTopics
export def "get-topics" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model in the description for example.
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/4/message/{systemKey}/topics"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# MESSAGING - Gets number of topics
#
# GET /api/v/4/message/{systemKey}/topics/count
# Returns: record
# operationId: GetTopicCount
export def "get-topic-count" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v/4/message/{systemKey}/topics/count"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# USER - Users change roles and passwords for other users
#
# PUT /api/v/4/user/manage
# operationId: ChangeUserInfo
export def "change-user-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  changes: any # Changes roles and password — shape: {password?: string, roles?: any}
  user: string # e.g. b4d8aaab0bf48e98dacbd78e9e50
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v/4/user/manage"
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: changes, var: changes}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_user_token: $clear_blade_user_token, changes: $changes, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# WEBHOOKS - Executes query string payload webhook
#
# GET /api/v/4/webhook/execute/{systemKey}/{webhookName}
# operationId: PayloadWebhookQuery
export def "payload-webhook-query" [
  system_key: string
  webhook_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # User authentication and data pushed through webhook (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v/4/webhook/execute/{systemKey}/{webhookName}"
    path_params: [{name: systemKey, var: system_key}, {name: webhookName, var: webhook_name}]
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, webhook_name: $webhook_name, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# WEBHOOKS - Executing a webhook
#
# POST /api/v/4/webhook/execute/{systemKey}/{webhookName}
# operationId: ExecuteWebhook
export def "execute-webhook" [
  system_key: string
  webhook_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication. (required)
  data: string # e.g. Third party server data
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v/4/webhook/execute/{systemKey}/{webhookName}"
    path_params: [{name: systemKey, var: system_key}, {name: webhookName, var: webhook_name}]
    header: [{name: ClearBlade-UserToken, var: clear_blade_user_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, webhook_name: $webhook_name, clear_blade_user_token: $clear_blade_user_token, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ADAPTERS - Get all adapters
#
# GET /api/v/4/{SystemKey}/adapters
# operationId: GetAdapters
export def "get-adapters" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v/4/{SystemKey}/adapters"
    path_params: [{name: SystemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ADAPTERS - Add an adapter
#
# POST /api/v/4/{SystemKey}/adapters
# operationId: addAdapter
export def "add-adapter" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.. (required)
  --architecture: string # The platform the adapter will be running on. (e.g. darwin-amd64)
  --deploy-command: string # The file name that will be running for the deploy command. (e.g. )
  --logs-command: string # A command or shell script that will be used to retrieve any logs printed out by the adapter while it is running. (e.g. )
  name: string # Name of the adapter. (e.g. example-adapter)
  --os: string # The os this adapter is going to run on. (e.g. linux)
  --start-command: string # A command or shell script that will be executed to start the adapter on a ClearBlade Edge. If a start-up command is not specified , the adapter would need to be manually started by connecting to the gateway device (via ssh) and issuing an appropriate start (e.g. )
  --status-command: string # A command or shell script that will be run to determine the status of the adapter on a specific ClearBlade Edge. A shell script that echoes the status of an adapter should be supplied (e.g. )
  --stop-command: string # A command or shell script that will be run to stop the adapter on a ClearBlade Edge. If the Stop Command is not specified, the adapter would need to be manually stopped by connecting to the gateway device (via ssh) and issuing an appropriate stop command. (e.g. )
  --undeploy-command: string # A command or shell script that will be run to uninstall the adapter from a ClearBlade Edge. If the Undeploy Command is not specified the default behavior of the ClearBlade platform is to remove the adapter files from the directory where Edge is running. (e.g. )
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v/4/{SystemKey}/adapters"
    path_params: [{name: SystemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: architecture, var: architecture}, {name: deploy_command, var: deploy_command}, {name: logs_command, var: logs_command}, {name: name, var: name}, {name: os, var: os}, {name: start_command, var: start_command}, {name: status_command, var: status_command}, {name: stop_command, var: stop_command}, {name: undeploy_command, var: undeploy_command}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token, architecture: $architecture, deploy_command: $deploy_command, logs_command: $logs_command, name: $name, os: $os, start_command: $start_command, status_command: $status_command, stop_command: $stop_command, undeploy_command: $undeploy_command
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ADAPTERS - Delete adapter
#
# DELETE /api/v/4/{SystemKey}/adapters/{AdapterName}
# operationId: DeleteAdapter
export def "delete-adapter" [
  system_key: string
  adapter_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v/4/{SystemKey}/adapters/{AdapterName}"
    path_params: [{name: SystemKey, var: system_key}, {name: AdapterName, var: adapter_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, adapter_name: $adapter_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ADAPTERS - Map Adapter command to execute a file
#
# PUT /api/v/4/{SystemKey}/adapters/{AdapterName}
# operationId: MapAdapterCommand
export def "map-adapter-command" [
  system_key: string
  adapter_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
  --architecture: string # The platform the adapter will be running on. (e.g. darwin-amd64)
  --deploy-command: string # The file name that will be running for the deploy command. (e.g. ./deploy.sh)
  --logs-command: string # e.g. ./logs.sh
  --os: string # The os this adapter is going to run on. (e.g. linux)
  --run-deploy-on-deploy: oneof<nothing, bool> # e.g. true
  --run-start-on-deploy: oneof<nothing, bool> # e.g. true
  --run-stop-on-deploy: oneof<nothing, bool> # e.g. true
  --start-command: string # A command or shell script that will be executed to start the adapter on a ClearBlade Edge. If a start-up command is not specified , the adapter would need to be manually started by connecting to the gateway device (via ssh) and issuing an appropriate start (e.g. ./start.sh)
  --status-command: string # A command or shell script that will be run to determine the status of the adapter on a specific ClearBlade Edge. A shell script that echoes the status of an adapter should be supplied (e.g. ./status.sh)
  --stop-command: string # A command or shell script that will be run to stop the adapter on a ClearBlade Edge. If the Stop Command is not specified, the adapter would need to be manually stopped by connecting to the gateway device (via ssh) and issuing an appropriate stop command. (e.g. ./stop.sh)
  --undeploy-command: string # A command or shell script that will be run to uninstall the adapter from a ClearBlade Edge. If the Undeploy Command is not specified the default behavior of the ClearBlade platform is to remove the adapter files from the directory where Edge is running. (e.g. ./undeploy.sh)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v/4/{SystemKey}/adapters/{AdapterName}"
    path_params: [{name: SystemKey, var: system_key}, {name: AdapterName, var: adapter_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: architecture, var: architecture}, {name: deploy_command, var: deploy_command}, {name: logs_command, var: logs_command}, {name: os, var: os}, {name: run_deploy_on_deploy, var: run_deploy_on_deploy}, {name: run_start_on_deploy, var: run_start_on_deploy}, {name: run_stop_on_deploy, var: run_stop_on_deploy}, {name: start_command, var: start_command}, {name: status_command, var: status_command}, {name: stop_command, var: stop_command}, {name: undeploy_command, var: undeploy_command}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, adapter_name: $adapter_name, clear_blade_dev_token: $clear_blade_dev_token, architecture: $architecture, deploy_command: $deploy_command, logs_command: $logs_command, os: $os, run_deploy_on_deploy: $run_deploy_on_deploy, run_start_on_deploy: $run_start_on_deploy, run_stop_on_deploy: $run_stop_on_deploy, start_command: $start_command, status_command: $status_command, stop_command: $stop_command, undeploy_command: $undeploy_command
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ADAPTERS - Send command to edge
#
# PUT /api/v/4/{SystemKey}/adapters/{AdapterName}/control
# operationId: AddEdgeCommand
export def "add-edge-command" [
  system_key: string
  adapter_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
  command: string # The command the edge is currently using. (e.g. status)
  edges: string # Name of edge(s) being used. (e.g. [edgeName])
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v/4/{SystemKey}/adapters/{AdapterName}/control"
    path_params: [{name: SystemKey, var: system_key}, {name: AdapterName, var: adapter_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: command, var: command}, {name: edges, var: edges}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, adapter_name: $adapter_name, clear_blade_dev_token: $clear_blade_dev_token, command: $command, edges: $edges
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets list of configuration information for all adapter files
#
# GET /api/v/4/{SystemKey}/adapters/{AdapterName}/files
# operationId: AdapterConfig
export def "adapter-config" [
  system_key: string
  adapter_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v/4/{SystemKey}/adapters/{AdapterName}/files"
    path_params: [{name: SystemKey, var: system_key}, {name: AdapterName, var: adapter_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, adapter_name: $adapter_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ADAPTERS - Add or replace file content & configuration
#
# POST /api/v/4/{SystemKey}/adapters/{AdapterName}/files
# operationId: updateFileInfo
export def "update-file-info" [
  system_key: string
  adapter_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
  --body-adapter-name: string # The adapter the file is a part of. (spec name: adapter_name)
  --file: string # The base64 encoded file content. (e.g. IyEvYmluL2Jhc2gKbWtkaXIgU2hvd1RpbWVBZGFwdGVyCgptdiBzdGFydC5zaCBTaG93VGltZUFkYXB0ZXIKbXYgc3RvcC5zaCBTaG93VGltZUFkYXB0ZXIKbXYgc3RhdHVzLnNoIFNob3dUaW1lQWRhcHRlcgptdiBkZXBsb3kuc2ggU2hvd1RpbWVBZGFwdGVyCm12IHVuZGVwbG95LnNoIFNob3dUaW1lQWRhcHRlcgptdiBzaG93VGltZSBTaG93VGltZUFkYXB0ZXIKCmVjaG8gIlNob3dUaW1lQWRhcHRlciBEZXBsb3llZCI=)
  name: string # The name of the file, spaces ` ` or `-` are not allowed
  --path-name: string # the file path where the adapter file is stored on the client side. For example, on the file system where edge is running. (e.g. start.sh)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v/4/{SystemKey}/adapters/{AdapterName}/files"
    path_params: [{name: SystemKey, var: system_key}, {name: AdapterName, var: adapter_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: adapter_name, var: body_adapter_name}, {name: file, var: file}, {name: name, var: name}, {name: path_name, var: path_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, adapter_name: $adapter_name, clear_blade_dev_token: $clear_blade_dev_token, body_adapter_name: $body_adapter_name, file: $file, name: $name, path_name: $path_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ADAPTERS - Delete adapter files
#
# DELETE /api/v/4/{SystemKey}/adapters/{AdapterName}/files/{fileName}
# operationId: DeleteFile
export def "delete-file" [
  system_key: string
  adapter_name: string
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
  --clear-blade-dev-token: string # Developer Token obtained through authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v/4/{SystemKey}/adapters/{AdapterName}/files/{fileName}"
    path_params: [{name: SystemKey, var: system_key}, {name: AdapterName, var: adapter_name}, {name: fileName, var: file_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, adapter_name: $adapter_name, file_name: $file_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ADAPTERS - Download file from adapter
#
# GET /api/v/4/{SystemKey}/adapters/{AdapterName}/files/{fileName}
# operationId: FileDownload
export def "file-download" [
  system_key: string
  adapter_name: string
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
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v/4/{SystemKey}/adapters/{AdapterName}/files/{fileName}"
    path_params: [{name: SystemKey, var: system_key}, {name: AdapterName, var: adapter_name}, {name: fileName, var: file_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, adapter_name: $adapter_name, file_name: $file_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ADAPTERS - Update Existing File's content
#
# PUT /api/v/4/{SystemKey}/adapters/{AdapterName}/files/{fileName}
# operationId: updateExistingFileContent
export def "update-existing-file-content" [
  system_key: string
  adapter_name: string
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
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
  file: string # base64 encoded string as file content to overwrite the existing content (e.g. IyEvYmluL2Jhc2gKZWNobyAiaGVsbG8gd29ybGQi)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v/4/{SystemKey}/adapters/{AdapterName}/files/{fileName}"
    path_params: [{name: SystemKey, var: system_key}, {name: AdapterName, var: adapter_name}, {name: fileName, var: file_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: file, var: file}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, adapter_name: $adapter_name, file_name: $file_name, clear_blade_dev_token: $clear_blade_dev_token, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CODE - Get all failed services using Query
#
# GET /api/v/4/{systemKey}/code/failed
# operationId: GetFailedServiceQuery
export def "get-failed-service-query" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Uses query to limit scope of list of failed services. Check FailQuery Model at the bottom of this page.
  --clear-blade-dev-token: string # Dev Token obtained through authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v/4/{systemKey}/code/failed"
    path_params: [{name: systemKey, var: system_key}]
    query: [{name: query, var: query}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, query: $query, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get all failed services
#
# GET /codeadmin/failed
# operationId: GetFailedServices
export def "get-failed-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/codeadmin/failed"
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Delete failed service run
#
# DELETE /codeadmin/failed/{systemKey}
# operationId: DeleteFailedService
export def "delete-failed-service" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --body: string
]: any -> any {
  $in | http-request {
    method: delete
    path: "/codeadmin/failed/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get system's failed services
#
# GET /codeadmin/failed/{systemKey}
# operationId: GetSystemFailedServices
export def "get-system-failed-services" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/codeadmin/failed/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Retry failed service
#
# POST /codeadmin/failed/{systemKey}
# operationId: RetryFailedService
export def "retry-failed-service" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/codeadmin/failed/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get library history
#
# GET /codeadmin/v/2/history/library/{systemKey}/{libName}
# operationId: LibraryHistory
export def "library-history" [
  system_key: string
  lib_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/codeadmin/v/2/history/library/{systemKey}/{libName}"
    path_params: [{name: systemKey, var: system_key}, {name: libName, var: lib_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, lib_name: $lib_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get old library version
#
# GET /codeadmin/v/2/history/library/{systemKey}/{libName}/{libVersion}
# operationId: GetOldLibraryVersion
export def "get-old-library-version" [
  system_key: string
  lib_name: string
  lib_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/codeadmin/v/2/history/library/{systemKey}/{libName}/{libVersion}"
    path_params: [{name: systemKey, var: system_key}, {name: libName, var: lib_name}, {name: libVersion, var: lib_version}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, lib_name: $lib_name, lib_version: $lib_version, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get all libraries
#
# GET /codeadmin/v/2/library/{systemKey}
# operationId: GetLibraries
export def "get-libraries" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/codeadmin/v/2/library/{systemKey}"
    path_params: [{name: systemKey, var: system_key}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Delete library
#
# DELETE /codeadmin/v/2/library/{systemKey}/{libName}
# operationId: DeleteLibrary
export def "delete-library" [
  system_key: string
  lib_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/codeadmin/v/2/library/{systemKey}/{libName}"
    path_params: [{name: systemKey, var: system_key}, {name: libName, var: lib_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, lib_name: $lib_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get library
#
# GET /codeadmin/v/2/library/{systemKey}/{libName}
# operationId: GetLibrary
export def "get-library" [
  system_key: string
  lib_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/codeadmin/v/2/library/{systemKey}/{libName}"
    path_params: [{name: systemKey, var: system_key}, {name: libName, var: lib_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, lib_name: $lib_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Create library
#
# POST /codeadmin/v/2/library/{systemKey}/{libName}
# operationId: CreateLibrary
export def "create-library" [
  system_key: string
  lib_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  code: string # e.g. function getter(uri){var r=Requests();r.get({'uri':uri},function(err,resp){log(JSON.stringify(resp));});}
  dependencies: string # e.g. http,log
  visibility: string # e.g. system
]: any -> any {
  $in | http-request {
    method: post
    path: "/codeadmin/v/2/library/{systemKey}/{libName}"
    path_params: [{name: systemKey, var: system_key}, {name: libName, var: lib_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: dependencies, var: dependencies}, {name: visibility, var: visibility}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, lib_name: $lib_name, clear_blade_dev_token: $clear_blade_dev_token, code: $code, dependencies: $dependencies, visibility: $visibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Update library
#
# PUT /codeadmin/v/2/library/{systemKey}/{libName}
# operationId: UpdateLibrary
export def "update-library" [
  system_key: string
  lib_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  code: string # e.g. function rand(){log('rolling die'); return 3;}
  dependencies: string # e.g. log
  description: string # e.g. Random number generator
]: any -> any {
  $in | http-request {
    method: put
    path: "/codeadmin/v/2/library/{systemKey}/{libName}"
    path_params: [{name: systemKey, var: system_key}, {name: libName, var: lib_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: dependencies, var: dependencies}, {name: description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, lib_name: $lib_name, clear_blade_dev_token: $clear_blade_dev_token, code: $code, dependencies: $dependencies, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Get services logs
#
# GET /codeadmin/v/2/logs/{systemKey}/{serviceName}
# operationId: GetLogs
export def "get-logs" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/codeadmin/v/2/logs/{systemKey}/{serviceName}"
    path_params: [{name: systemKey, var: system_key}, {name: serviceName, var: service_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, service_name: $service_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Delete code service
#
# DELETE /codeadmin/v/2/{systemKey}/{serviceName}
# operationId: DeleteService
export def "delete-service" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/codeadmin/v/2/{systemKey}/{serviceName}"
    path_params: [{name: systemKey, var: system_key}, {name: serviceName, var: service_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, service_name: $service_name, clear_blade_dev_token: $clear_blade_dev_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Add code service
#
# POST /codeadmin/v/2/{systemKey}/{serviceName}
# operationId: AddService
export def "add-service" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  code: string # e.g. function serviceName(req,resp){resp.success(“success”);}
  --dependencies: string # e.g. log
  name: string # e.g. serviceName
  parameters: string # e.g. [{}]
  --run-user: string # e.g. 
  system_id: string # e.g. c0f8e2c50bc6cc90b7a19abbbb8d01
]: any -> any {
  $in | http-request {
    method: post
    path: "/codeadmin/v/2/{systemKey}/{serviceName}"
    path_params: [{name: systemKey, var: system_key}, {name: serviceName, var: service_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: dependencies, var: dependencies}, {name: name, var: name}, {name: parameters, var: parameters}, {name: run_user, var: run_user}, {name: systemID, var: system_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, service_name: $service_name, clear_blade_dev_token: $clear_blade_dev_token, code: $code, dependencies: $dependencies, name: $name, parameters: $parameters, run_user: $run_user, system_id: $system_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEVELOPER - Update code service
#
# PUT /codeadmin/v/2/{systemKey}/{serviceName}
# operationId: UpdateService
export def "update-service" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication. (required)
  --auto-balance: oneof<nothing, bool> # If concurrency > 0 then auto_balance can be set to true if needed
  --auto-restart: oneof<nothing, bool> # If execution_timeout = -1 => Stream Service then auto_restart can be set to true if needed
  code: string # e.g. function serviceName(req,resp){resp.success(“success”);}
  concurrency: int # e.g. 0
  current_version: int # e.g. 4
  --dependencies: string # e.g. log
  --execution-timeout: int # e.g. 60
  --logging-enabled: oneof<nothing, bool>
  name: string # e.g. serviceName
  --parameters: list # e.g. []
  --run-user: string # Uses user_id. (e.g. e8b7f0cb0bdccdb7a8a7c78cdfcb01)
  --timers: list # e.g. []
  --triggers: list # e.g. []
]: any -> any {
  $in | http-request {
    method: put
    path: "/codeadmin/v/2/{systemKey}/{serviceName}"
    path_params: [{name: systemKey, var: system_key}, {name: serviceName, var: service_name}]
    header: [{name: ClearBlade-DevToken, var: clear_blade_dev_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: auto_balance, var: auto_balance, required: true}, {name: auto_restart, var: auto_restart, required: true}, {name: code, var: code}, {name: concurrency, var: concurrency}, {name: current_version, var: current_version}, {name: dependencies, var: dependencies}, {name: execution_timeout, var: execution_timeout}, {name: logging_enabled, var: logging_enabled, required: true}, {name: name, var: name}, {name: parameters, var: parameters}, {name: run_user, var: run_user}, {name: timers, var: timers}, {name: triggers, var: triggers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_key: $system_key, service_name: $service_name, clear_blade_dev_token: $clear_blade_dev_token, auto_balance: $auto_balance, auto_restart: $auto_restart, code: $code, concurrency: $concurrency, current_version: $current_version, dependencies: $dependencies, execution_timeout: $execution_timeout, logging_enabled: $logging_enabled, name: $name, parameters: $parameters, run_user: $run_user, timers: $timers, triggers: $triggers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
