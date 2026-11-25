# Auto-generated client for MDES Customer Service v2.0.7
# Source: https://api.apis.guru/v2/specs/mastercard.com/MDES/2.0.7/swagger.json
# Auth: --token flag or $env.MDES_CUSTOMER_SERVICE_TOKEN

const CLIENT = {
  base_url: "https://api.mastercard.com/mdes/csapi/v2"
  token_env_var: "MDES_CUSTOMER_SERVICE_TOKEN"
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

def base-url-completer [] { ["https://api.mastercard.com/mdes/csapi/v2"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    post-accountholdermessaging: "record<AccountHolderMessagingResponse: record<Token: record<TokenUniqueReference: string>>>"
    post-search: "record<SearchResponse: record<Accounts: record<Account: list>>>"
    get-systemstatus: "record<SystemStatusResponse: record<CommentText: string, LastStatusDateTime: string>>"
    post-token-activate: "record<TokenActivateResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>>"
    post-token-activationmethods: "record<TokenActivationMethodsResponse: record<ActivationMethods: record<ActivationMethod: list>>>"
    post-token-comments: "record<TokenCommentsResponse: record<Comments: record<Comment: list>>>"
    post-token-delete: "record<TokenDeleteResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>>"
    post-token-resendactivationcode: "record<TokenResendActivationCodeResponse: record<Token: record<TokenUniqueReference: string>>>"
    post-token-resetmobilepin: "record<TokenResetMobilePinResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>>"
    post-token-statushistory: "record<TokenStatusHistoryResponse: record<Statuses: record<Status: list>>>"
    post-token-suspend: "record<TokenSuspendResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>>"
    post-token-unsuspend: "record<TokenUnsuspendResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>>"
    post-token-update: "record<TokenUpdateResponse: record<Tokens: record<Token: list>>>"
    post-transactions: "record<TransactionsResponse: record<Transactions: record<Transaction: list>>>"
    post-updatetokenassurance: "record<UpdateTokenAssuranceResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-accountholdermessaging" "post-search" "get-systemstatus" "post-token-activate" "post-token-activationmethods" "post-token-comments" "post-token-delete" "post-token-resendactivationcode" "post-token-resetmobilepin" "post-token-statushistory" "post-token-suspend" "post-token-unsuspend" "post-token-update" "post-transactions" "post-updatetokenassurance" "commands"] | sort) } | get name | first)
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

# Allows issuers to display customized messages per token within the Apple Pay wallet, below the digitized image of the card.
#
# POST /accountholdermessaging
# Returns: record<AccountHolderMessagingResponse: record<Token: record<TokenUniqueReference: string>>>
export def "post-accountholdermessaging" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-holder-messaging-request: any # shape: {AuditInfo: any, IssuerApplicationMessageDisplay: string, MessageExpiration: string, MessageIdentifier: string, MessageLanguageCode: string, MessageText: string, TokenUniqueReference: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accountholdermessaging"
    body: {content_type: "application/json", kind: json, fields: [{name: AccountHolderMessagingRequest, var: account_holder_messaging_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_holder_messaging_request: $account_holder_messaging_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides the ability to search for tokens based on Account PAN, Alternate Account Identifier, Token Unique Reference, Token, Payment App Instance Id or Comment Id. Returns all of the tokens associated with an account according to the scope of the indicated search request criteria. The response includes key state and informational data for each token, including the Token Unique Reference which is needed for subsequent token lifecycle management activities._Notes:_ The Search API request MUST include only one of the available search methods Account PAN, Token Unique Reference, Token, Payment App Instance Id, Comment Id, or Alternate Account Identifier. They cannot be used together in a single request. Moreover, this function only retrieves results if the search criteria matches a current value from the token vault. In other words, if the search criteria is a PAN that has been replaced, the system will not retrieve any data.
#
# POST /search
# Returns: record<SearchResponse: record<Accounts: record<Account: list>>>
export def "post-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-request: any # shape: {AccountPan?: string, AlternateAccountIdentifier?: string, AuditInfo: any, CommentId?: string, ExcludeDeletedIndicator?: "true"|"false", PaymentAppInstanceId?: string, Token?: string, TokenUniqueReference?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/search"
    body: {content_type: "application/json", kind: json, fields: [{name: SearchRequest, var: search_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search_request: $search_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the overall system status of the Mastercard Digital Enablement Service.
#
# GET /systemstatus
# Returns: record<SystemStatusResponse: record<CommentText: string, LastStatusDateTime: string>>
export def "get-systemstatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/systemstatus"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Used to activate a token for a digitization that has been approved and provisioned, but requires additional cardholder authentication prior to activation. If the provisioning was not completed successfully, activation cannot be accomplished using Customer Service API. It is expected that a cardholder will complete the authentication process using an issuer's call center or using an issuer-supplied mobile application, and only then should the issuer use this API to activate the token.
#
# POST /token/activate
# Returns: record<TokenActivateResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>>
export def "post-token-activate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-activate-request: any # shape: {AccountPan?: string, AuditInfo: any, CommentText?: string, PaymentAppInstanceId?: string, ReasonCode: string, TokenUniqueReference?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/token/activate"
    body: {content_type: "application/json", kind: json, fields: [{name: TokenActivateRequest, var: token_activate_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_activate_request: $token_activate_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Used to retrieve the available Activation Methods for a token that is awaiting activation. Activation Methods are the means by which a cardholder may complete cardholder authentication with the issuer beyond the scope of MDES. It is possible that there are no Activation Methods for a token when an issuer did not provide any cardholder-specific information with the Tokenization Authorization Request (TAR) pre-digitization network message response.
#
# POST /token/activationmethods
# Returns: record<TokenActivationMethodsResponse: record<ActivationMethods: record<ActivationMethod: list>>>
export def "post-token-activationmethods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-activation-methods-request: any # shape: {AuditInfo?: any, TokenUniqueReference: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/token/activationmethods"
    body: {content_type: "application/json", kind: json, fields: [{name: TokenActivationMethodsRequest, var: token_activation_methods_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_activation_methods_request: $token_activation_methods_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Used to retrieve all comments associated with a token. Typically the response includes comments created earlier by Issuer Customer Service representatives detailing additional information about a particular inquiry or event. There may also be comments with warnings of potential fraud. These comments are created automatically by the MDES system when a Token requestor indicates a high risk of fraud during digitization.
#
# POST /token/comments
# Returns: record<TokenCommentsResponse: record<Comments: record<Comment: list>>>
export def "post-token-comments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-comments-request: any # shape: {AuditInfo?: any, TokenUniqueReference: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/token/comments"
    body: {content_type: "application/json", kind: json, fields: [{name: TokenCommentsRequest, var: token_comments_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_comments_request: $token_comments_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Used to delete a token so that it may not initiate any new transactions. All authorizations for a deleted token will be declined. A deleted token may not be returned to an active state.
#
# POST /token/delete
# Returns: record<TokenDeleteResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>>
export def "post-token-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-delete-request: any # shape: {AuditInfo: any, CommentText?: string, ReasonCode: string, TokenUniqueReference: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/token/delete"
    body: {content_type: "application/json", kind: json, fields: [{name: TokenDeleteRequest, var: token_delete_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_delete_request: $token_delete_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Used to trigger the process of generating and sending a new Activation Code (for a specific token) to the cardholder via the requested Activation Method. When successful, a new Activation Code Expiration Date Time period will begin, and a new Activation Code will be sent to the issuer using the Activation Code Notification (ACN) pre-digitization network message. It can only be used to do this for Activation Methods that involve the external distribution of an Activation Code to the cardholder. For example, via email or SMS. It cannot be used to send a new activation code via the "Mobile Application" activation method, for instance. A new Activation Code can be sent even if the previous code has not expired. A new Activation Code can also be sent even after the previous code has expired; however, it can only be done up to 30 days after the token was created (the number of days is subject to change at the discretion of Mastercard).
#
# POST /token/resendactivationcode
# Returns: record<TokenResendActivationCodeResponse: record<Token: record<TokenUniqueReference: string>>>
export def "post-token-resendactivationcode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-resend-activation-code-request: any # shape: {ActivationMethodId: string, AuditInfo: any, TokenUniqueReference: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/token/resendactivationcode"
    body: {content_type: "application/json", kind: json, fields: [{name: TokenResendActivationCodeRequest, var: token_resend_activation_code_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_resend_activation_code_request: $token_resend_activation_code_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Used to request that the Mobile PIN for a Mastercard Cloud-Based Payment token in a single issuer wallet is reset. The request is passed to the Credential Management System for processing. When the Mobile PIN is a token-level PIN (as opposed to a wallet-level PIN), the cardholder must choose a new PIN within 10 minutes of a Reset Mobile PIN action. Otherwise, the reset will need to be re-requested.
#
# POST /token/resetmobilepin
# Returns: record<TokenResetMobilePinResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>>
export def "post-token-resetmobilepin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-reset-mobile-pin-request: any # shape: {AuditInfo: any, CommentText?: string, ReasonCode: string, TokenUniqueReference: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/token/resetmobilepin"
    body: {content_type: "application/json", kind: json, fields: [{name: TokenResetMobilePinRequest, var: token_reset_mobile_pin_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_reset_mobile_pin_request: $token_reset_mobile_pin_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Used to retrieve the historical statuses and lifecycle events for a token, such as when it was initially activated, subsequently suspended or resumed, and finally deleted.
#
# POST /token/statushistory
# Returns: record<TokenStatusHistoryResponse: record<Statuses: record<Status: list>>>
export def "post-token-statushistory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-status-history-request: any # shape: {AuditInfo?: any, TokenUniqueReference: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/token/statushistory"
    body: {content_type: "application/json", kind: json, fields: [{name: TokenStatusHistoryRequest, var: token_status_history_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_status_history_request: $token_status_history_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Used to suspend an active token so that it may not initiate any new transactions. All authorizations for a SUSPENDED token will be declined. Tokens may be suspended by multiple parties (suspenders) concurrently. The token status is updated from ACTIVE to SUSPENDED when the first suspender triggers a suspend action. Additional suspenders can add their suspend action to the list of suspenders. Suspenders can unsuspend only their own suspend action. All suspenders need to perform an unsuspend action to move a token from SUSPENDED to ACTIVE. The token status will only change when the last suspender has unsuspended the token. For CoF tokens, the only two supported suspenders are issuer and token requestor. For Apple Pay tokens, there are some differences in behavior versus the general principles. An issuer may add themselves as a suspender to a token already suspended by a cardholder, as above. However, a cardholder cannot suspend a token already suspended by the issuer. As a special case for Apple Pay, an issuer may unsuspend (override) a token already suspended by a cardholder. However, a cardholder cannot unsuspend a token already suspended by the issuer.
#
# POST /token/suspend
# Returns: record<TokenSuspendResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>>
export def "post-token-suspend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-suspend-request: any # shape: {AuditInfo: any, CommentText?: string, ReasonCode: string, TokenUniqueReference: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/token/suspend"
    body: {content_type: "application/json", kind: json, fields: [{name: TokenSuspendRequest, var: token_suspend_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_suspend_request: $token_suspend_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Used to unsuspend or resume a suspended token and return it to the active state where it may initiate new transactions. Tokens may be suspended by multiple parties (suspenders) concurrently. The token status is updated from ACTIVE to SUSPENDED when the first suspender triggers a suspend action. Additional suspenders can add their suspend action to the list of suspenders. Suspenders can unsuspend only their own suspend action. All suspenders need to perform an unsuspend action to move a token from SUSPENDED to ACTIVE. The token status will only change when the last suspender has unsuspended the token. For CoF tokens, the only two supported suspenders are issuer and token requestor.For Apple Pay tokens, there are some differences in behavior versus the general principles. An issuer may add themselves as a suspender to a token already suspended by a cardholder, as above. However, a cardholder cannot suspend a token already suspended by the issuer. As a special case for Apple Pay, an issuer may unsuspend (override) a token already suspended by a cardholder. However, a cardholder cannot unsuspend a token already suspended by the issuer.
#
# POST /token/unsuspend
# Returns: record<TokenUnsuspendResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>>
export def "post-token-unsuspend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-unsuspend-request: any # shape: {AuditInfo: any, CommentText?: string, ReasonCode: string, TokenUniqueReference: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/token/unsuspend"
    body: {content_type: "application/json", kind: json, fields: [{name: TokenUnsuspendRequest, var: token_unsuspend_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_unsuspend_request: $token_unsuspend_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Used to update Account PAN Mapping Information or Issuer Product Configuration ID associated to a provisioned token. To update a specific token, the API should be requested using the Token Unique Reference. To update all tokens mapped to a specific Account PAN, the API should be requested using the Account PAN. In either case, updates will only be applied to tokens in ACTIVE or SUSPENDED state, not those in IN PROGRESS or DELETED state. When updating Account PAN Mapping Information, the Account PAN, Expiration Date and Sequence Number, may be updated individually or in any combination. Only information provided will be updated. The account mapping will only update an Account PAN for a new Account PAN when they are both in the same Account Range.
#
# POST /token/update
# Returns: record<TokenUpdateResponse: record<Tokens: record<Token: list>>>
export def "post-token-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-update-request: any # shape: {AccountPanSequenceNumber?: string, AuditInfo: any, CommentText?: string, CurrentAccountPan?: string, ExpirationDate?: string, IssuerProductConfigurationId?: string, NewAccountPan?: string, TokenUniqueReference?: string, UpdateWalletProviderIndicator?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/token/update"
    body: {content_type: "application/json", kind: json, fields: [{name: TokenUpdateRequest, var: token_update_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_update_request: $token_update_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Used to retrieve transactions performed by a token. It only returns transactions performed within the last 30 days, to help identify a particular token, or to identify a particular recent transaction. It is not intended to provide the full transaction history of a token or Account PAN._Notes:_ The Transaction History API response is not supported for static Card on File (CoF) tokens.If a set of tokens has been re-mapped to a new FPAN, all digital transactions will be made available before or after the FPAN has been updated. MDES does not return the value of the FPAN which was mapped to the particular token at the time of the transaction. However, MDES will return the history of all transactions performed on that particular token in the last 30 days, based on old and/or new FPAN.
#
# POST /transactions
# Returns: record<TransactionsResponse: record<Transactions: record<Transaction: list>>>
export def "post-transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --transactions-request: any # shape: {AuditInfo: any, TokenUniqueReference: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transactions"
    body: {content_type: "application/json", kind: json, fields: [{name: TransactionsRequest, var: transactions_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transactions_request: $transactions_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Used after an issuer has performed additional cardholder authentication to indicate an increased level of token assurance. It will only be applied to tokens that actually have a Token Assurance Level, and those that are in ACTIVE or SUSPENDED state.
#
# POST /updatetokenassurance
# Returns: record<UpdateTokenAssuranceResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>>
export def "post-updatetokenassurance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-token-assurance-request: any # shape: {AuditInfo: any, CommentText?: string, TokenUniqueReference: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/updatetokenassurance"
    body: {content_type: "application/json", kind: json, fields: [{name: UpdateTokenAssuranceRequest, var: update_token_assurance_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    update_token_assurance_request: $update_token_assurance_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
