# Auto-generated client for IBKR 3rd Party Web API v1.0.0
# Source: https://api.apis.guru/v2/specs/interactivebrokers.com/1.0.0/openapi.json
# Auth: --token flag or $env.IBKR_3RD_PARTY_WEB_API_TOKEN

const CLIENT = {
  base_url: "https://www.interactivebrokers.com/tradingapi/v1"
  token_env_var: "IBKR_3RD_PARTY_WEB_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: portal, in: header, header_name: portal, prefix: ""}
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

def base-url-completer [] { ["https://www.interactivebrokers.com/tradingapi/v1"] }
def auth-scheme-completer [] { ["portal"] }

# Completers for enum parameters
def order-type-completer [] { ["1" "2" "3" "4"] }
def side-completer [] { ["1" "2"] }
def time-in-force-completer [] { ["0" "1" "2" "3" "7"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-accounts: "record<accounts: list<string>>"
    post-accounts-account-order-impact: "record<Commission: float, CommissionsCurrency: string, EquityWithLoan: float, InitMargin: float, InitMarginBefore: float, MaintMargin: float, MaintMarginBefore: float, MarginCurrency: string, MaxCommissions: float, MinCommissions: float>"
    get-accounts-account-orders: "table<ContractId: float, CustomerOrderId: float, FilledQuantity: float, ListingExchange: string, OrderType: float, OutsideRTH: string, Price: float, RemainingQuantity: float, Side: string, Status: string, Ticker: string, TimeInForce: float, TransactionTime: string, Warning: string>"
    post-accounts-account-orders: "table<ContractId: float, CustomerOrderId: float, FilledQuantity: float, ListingExchange: string, OrderType: float, OutsideRTH: string, Price: float, RemainingQuantity: float, Side: string, Status: string, Ticker: string, TimeInForce: float, TransactionTime: string, Warning: string>"
    delete-accounts-account-orders-customer-order-id: "table<CustomerOrderId: string, OrderQty: float, OrderType: float, Price: string, Side: float, Status: string, Symbol: float, Warning: string>"
    get-accounts-account-orders-customer-order-id: "table<ContractId: float, CustomerOrderId: float, FilledQuantity: float, ListingExchange: string, OrderType: float, OutsideRTH: string, Price: float, RemainingQuantity: float, Side: string, Status: string, Ticker: string, TimeInForce: float, TransactionTime: string, Warning: string>"
    put-accounts-account-orders-customer-order-id: "table<CustomerOrderId: string, OrderQty: float, OrderType: float, Price: string, Side: float, Status: string, Symbol: float, Warning: string>"
    get-accounts-account-positions: "table<AverageCost: float, ContractId: float, Position: float>"
    get-accounts-account-summary: "record<Info: record<AccountCode: string, AccountReady: string, AccountType: string, Cushion: string, DayTradesRemaining: string, DayTradesRemainingT: string, \"DayTradesRemainingT+2\": string, \"DayTradesRemainingT+3\": string, \"DayTradesRemainingT+4\": string, HighestSeverity: string, Leverage-S: string, LookAheadNextChange: string, SegmentTitle-C: string, SegmentTitle-S: string, TradingType-S: string, WhatIfPMEnabled: string>, Ledger: table<CashBalance: float, CashBalanceFXSegment: float, CashCumQty: float, ExchangeRate: float, FutureOptionMarketValue: float, FuturePNL: float, NetDividend: float, NetInterest: float, NetLiquidation: float, OptionMarketValue: float, RealizedPNL: float, StockMarketValue: float, TotalCashBalance: float, UnrealizedPNL: float>, Summary: record<AccruedCash: float, AccruedCash-C: float, AccruedCash-S: float, AccruedDividend: float, AccruedDividend-C: float, AccruedDividend-S: float, AvailableFunds: float, AvailableFunds-C: float, AvailableFunds-S: float, Billable: float, Billable-C: float, Billable-S: float, BuyingPower: float, EquityWithLoanValue: float, EquityWithLoanValue-C: float, EquityWithLoanValue-S: float, ExcessLiquidity: float, ExcessLiquidity-C: float, ExcessLiquidity-S: float, FullAvailableFunds: float, FullAvailableFunds-C: float, FullAvailableFunds-S: float, FullExcessLiquidity: float, FullExcessLiquidity-C: float, FullExcessLiquidity-S: float, FullInitMarginReq: float, FullInitMarginReq-C: float, FullInitMarginReq-S: float, FullMaintMarginReq: float, FullMaintMarginReq-C: float, FullMaintMarginReq-S: float, GrossPositionValue: float, GrossPositionValue-C: float, GrossPositionValue-S: float, IndianStockHaircut: float, IndianStockHaircut-C: float, IndianStockHaircut-S: float, InitMarginReq: float, InitMarginReq-C: float, InitMarginReq-S: float, InsuredDeposit: float, InsuredDeposit-C: float, InsuredDeposit-S: float, LookAheadAvailableFunds: float, LookAheadAvailableFunds-C: float, LookAheadAvailableFunds-S: float, LookAheadExcessLiquidity: float, LookAheadExcessLiquidity-C: float, LookAheadExcessLiquidity-S: float, LookAheadInitMarginReq: float, LookAheadInitMarginReq-C: float, LookAheadInitMarginReq-S: float, LookAheadMaintMarginReq: float, LookAheadMaintMarginReq-C: float, LookAheadMaintMarginReq-S: float, MaintMarginReq: float, MaintMarginReq-C: float, MaintMarginReq-S: float, NetLiquidation: float, NetLiquidation-C: float, NetLiquidation-S: float, NetLiquidationUncertainty: float, PASharesValue: float, PASharesValue-C: float, PASharesValue-S: float, PostExpirationExcess: float, PostExpirationExcess-C: float, PostExpirationExcess-S: float, PostExpirationMargin: float, PostExpirationMargin-C: float, PostExpirationMargin-S: float, RegTEquity: float, RegTEquity-S: float, RegTMargin: float, RegTMargin-S: float, SMA: float, SMA-S: float, TotalCashValue: float, TotalCashValue-C: float, TotalCashValue-S: float>>"
    get-accounts-account-trades: "table<AvgPrice: float, Commission: float, CommissionCurrency: string, ContractId: float, Currency: string, CustomerOrderId: float, ExecId: string, ExecutionTime: string, FilledQuantity: float, LastMarket: string, ListingExchange: string, OrderId: string, OrderType: float, Quantity: float, RemainingQuantity: float, Side: string, Ticker: string, TradePrice: float, TradeSize: float>"
    get-marketdata-exchange-components: "table<Complete: bool, ConId: float, mapping: list<record>>"
    get-marketdata-snapshot: "table<Bid: record<market: float, price: float, size: float>, Closing: record<price: float>, Complete: bool, Conid: string, Offer: record<market: float, price: float, size: float>, Temporality: float, Trade: record<market: float, price: float, size: float, time: float>>"
    post-oauth-access-token: "record<oauth_token: string, oauth_token_secret: string>"
    post-oauth-live-session-token: "record<diffie_hellman_response: string, live_session_token_signature: string>"
    post-oauth-request-token: "record<oauth_token: string>"
    get-secdef: "table<CompanyName: string, ContractId: float, Currency: string, Exchange: string, SecurityType: string, Ticker: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-accounts" "post-accounts-account-order-impact" "get-accounts-account-orders" "post-accounts-account-orders" "delete-accounts-account-orders-customer-order-id" "get-accounts-account-orders-customer-order-id" "put-accounts-account-orders-customer-order-id" "get-accounts-account-positions" "get-accounts-account-summary" "get-accounts-account-trades" "get-marketdata-exchange-components" "get-marketdata-snapshot" "post-oauth-access-token" "post-oauth-live-session-token" "post-oauth-request-token" "get-secdef" "commands"] | sort) } | get name | first)
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

# Brokerage Accounts
#
# GET /accounts
# Returns: record<accounts: list<string>>
export def "get-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: string # Account Number (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts"
    query: [{name: account, var: account, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: portal
  } {
    account: $account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return margin impact info
#
# POST /accounts/{account}/order_impact
# Returns: record<Commission: float, CommissionsCurrency: string, EquityWithLoan: float, InitMargin: float, InitMarginBefore: float, MaintMargin: float, MaintMarginBefore: float, MarginCurrency: string, MaxCommissions: float, MinCommissions: float>
export def "post-accounts-account-order-impact" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aux-price: float # Required price to support Stop and Stop Limit orders
  --contract-id: float # The internal IB identifier for the trading product specified as an integer (can be obtained in response to /secdef request)
  --currency: string # The currency in which the FX pair trades (only for InstrumentType=CASH)
  --customer-order-id: string # The order ID assigned by the customer.
  --instrument-type: string # The instrument type of the contract
  --listing-exchange: string # The exchange on which the trading product is listed (only for InstrumentType=STK)
  --order-type: float@order-type-completer # Market = '1' Limit = '2' Stop = '3' StopLimit = '4'
  --price: float # The order price
  --quantity: float # The number of units in the order; contracts or shares
  --side: float@side-completer # Buy = '1', Sell = '2'
  --ticker: string # The symbol that identifies the trading product
  --time-in-force: float@time-in-force-completer # Defines order's active lifetime. Day = '0' GTC (Good till Cancel) = '1' IOC (Immediate or Cancel) = '3' Open = '2' Close = '7'
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{account}/order_impact"
    path_params: [{name: account, var: account}]
    body: {content_type: "application/json", kind: json, fields: [{name: "Aux Price", var: aux_price}, {name: ContractId, var: contract_id}, {name: Currency, var: currency}, {name: CustomerOrderId, var: customer_order_id}, {name: InstrumentType, var: instrument_type}, {name: ListingExchange, var: listing_exchange}, {name: "Order Type", var: order_type}, {name: Price, var: price}, {name: Quantity, var: quantity}, {name: Side, var: side}, {name: Ticker, var: ticker}, {name: "Time in Force", var: time_in_force}]}
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: portal
  } {
    account: $account, aux_price: $aux_price, contract_id: $contract_id, currency: $currency, customer_order_id: $customer_order_id, instrument_type: $instrument_type, listing_exchange: $listing_exchange, order_type: $order_type, price: $price, quantity: $quantity, side: $side, ticker: $ticker, time_in_force: $time_in_force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Open Orders
#
# GET /accounts/{account}/orders
# Returns: table<ContractId: float, CustomerOrderId: float, FilledQuantity: float, ListingExchange: string, OrderType: float, OutsideRTH: string, Price: float, RemainingQuantity: float, Side: string, Status: string, Ticker: string, TimeInForce: float, TransactionTime: string, Warning: string>
export def "get-accounts-account-orders" [
  account: string
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
    path: "/accounts/{account}/orders"
    path_params: [{name: account, var: account}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: portal
  } {
    account: $account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Place Order
#
# POST /accounts/{account}/orders
# Returns: table<ContractId: float, CustomerOrderId: float, FilledQuantity: float, ListingExchange: string, OrderType: float, OutsideRTH: string, Price: float, RemainingQuantity: float, Side: string, Status: string, Ticker: string, TimeInForce: float, TransactionTime: string, Warning: string>
export def "post-accounts-account-orders" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aux-price: float # Required Price to support Stop and Stop Limit orders
  --contract-id: float # The internal IB identifier for the trading product specified as an integer (can be obtained in response to /secdef request)
  --currency: string # The currency in which the FX pair trades (only for InstrumentType=CASH)
  --customer-order-id: string # The order ID assigned by the customer.
  --german-hft-algo: oneof<nothing, bool> # By setting this bool to false the customer attests that the order is not subject to German HFT Act, was not generated using any automated algorithm, and no algorithm determined or changed financial instrument, side, quantity, order type, limit or other price, trading venue or timing of this order. Currently we cannot accept orders where this flag is set to true. Such orders will be rejected.
  --instrument-type: string # The instrument type of the contract
  --listing-exchange: string # The exchange on which the trading product is listed (only for InstrumentType=STK)
  --mifid2-algo: string # This field permits specification of the user's preregistered (via account management) MiFID II short code for algos that are responsible for investment decisions
  --mifid2-decision-maker: string # This field permits specification of the user's preregistered (via account management) MiFID II short code for decision makers.
  --mifid2-execution-algo: string # This field permits specification of the user's preregistered (via account management) MiFID II short code for algos that are responsible for handling/routing of the order.
  --mifid2-execution-trader: string # This field permits specification of the user's preregistered (via account management) MiFID II person responsible for handling/routing of the order
  --order-type: float@order-type-completer # Market = '1' Limit = '2' Stop = '3' StopLimit = '4'
  --order-restrictions: float # MultiValueString representing the restrictions associated with an order. If more than one restriction is applicable to an order, this field can contain multiple instructions separated by space. '1' Program Trade '2' Index Arbitrage '3' Non-Index Arbitrage
  --outside-rth: float # Indicates if order is active outside regular trading hours, where defined. 0 = no (default), 1 = yes
  --price: float # The order price
  --quantity: float # The number of units in the order; contracts or shares
  --side: float@side-completer # Buy = '1', Sell = '2'
  --ticker: string # The symbol that identifies the trading product
  --time-in-force: float@time-in-force-completer # Defines order's active lifetime. Day = '0' GTC (Good till Cancel) = '1' IOC (Immediate or Cancel) = '3' Open = '2' Close = '7'
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{account}/orders"
    path_params: [{name: account, var: account}]
    body: {content_type: "application/json", kind: json, fields: [{name: "Aux Price", var: aux_price}, {name: ContractId, var: contract_id}, {name: Currency, var: currency}, {name: CustomerOrderId, var: customer_order_id}, {name: GermanHftAlgo, var: german_hft_algo}, {name: InstrumentType, var: instrument_type}, {name: ListingExchange, var: listing_exchange}, {name: Mifid2Algo, var: mifid2_algo}, {name: Mifid2DecisionMaker, var: mifid2_decision_maker}, {name: Mifid2ExecutionAlgo, var: mifid2_execution_algo}, {name: Mifid2ExecutionTrader, var: mifid2_execution_trader}, {name: "Order Type", var: order_type}, {name: OrderRestrictions, var: order_restrictions}, {name: "Outside RTH", var: outside_rth}, {name: Price, var: price}, {name: Quantity, var: quantity}, {name: Side, var: side}, {name: Ticker, var: ticker}, {name: "Time in Force", var: time_in_force}]}
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: portal
  } {
    account: $account, aux_price: $aux_price, contract_id: $contract_id, currency: $currency, customer_order_id: $customer_order_id, german_hft_algo: $german_hft_algo, instrument_type: $instrument_type, listing_exchange: $listing_exchange, mifid2_algo: $mifid2_algo, mifid2_decision_maker: $mifid2_decision_maker, mifid2_execution_algo: $mifid2_execution_algo, mifid2_execution_trader: $mifid2_execution_trader, order_type: $order_type, order_restrictions: $order_restrictions, outside_rth: $outside_rth, price: $price, quantity: $quantity, side: $side, ticker: $ticker, time_in_force: $time_in_force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel Order
#
# DELETE /accounts/{account}/orders/{CustomerOrderId}
# Returns: table<CustomerOrderId: string, OrderQty: float, OrderType: float, Price: string, Side: float, Status: string, Symbol: float, Warning: string>
export def "delete-accounts-account-orders-customer-order-id" [
  account: string
  customer_order_id: string
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
    method: delete
    path: "/accounts/{account}/orders/{CustomerOrderId}"
    path_params: [{name: account, var: account}, {name: CustomerOrderId, var: customer_order_id}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: portal
  } {
    account: $account, customer_order_id: $customer_order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return specific order info
#
# GET /accounts/{account}/orders/{CustomerOrderId}
# Returns: table<ContractId: float, CustomerOrderId: float, FilledQuantity: float, ListingExchange: string, OrderType: float, OutsideRTH: string, Price: float, RemainingQuantity: float, Side: string, Status: string, Ticker: string, TimeInForce: float, TransactionTime: string, Warning: string>
export def "get-accounts-account-orders-customer-order-id" [
  account: string
  customer_order_id: string
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
    path: "/accounts/{account}/orders/{CustomerOrderId}"
    path_params: [{name: account, var: account}, {name: CustomerOrderId, var: customer_order_id}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: portal
  } {
    account: $account, customer_order_id: $customer_order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify Order
#
# PUT /accounts/{account}/orders/{CustomerOrderId}
# Returns: table<CustomerOrderId: string, OrderQty: float, OrderType: float, Price: string, Side: float, Status: string, Symbol: float, Warning: string>
export def "put-accounts-account-orders-customer-order-id" [
  account: string
  customer_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aux-price: float # Required Price to support Stop and Stop Limit orders
  --body-customer-order-id: string # The new order ID assigned by the customer for the modification. (spec name: CustomerOrderId)
  --german-hft-algo: oneof<nothing, bool> # By setting this bool to false the customer attests that the order is not subject to German HFT Act, was not generated using any automated algorithm, and no algorithm determined or changed financial instrument, side, quantity, order type, limit or other price, trading venue or timing of this order. Currently we cannot accept orders where this flag is set to true. Such orders will be rejected.
  --mifid2-algo: string # This field permits specification of the user's preregistered (via account management) MiFID II short code for algos that are responsible for investment decisions
  --mifid2-decision-maker: string # This field permits specification of the user's preregistered (via account management) MiFID II short code for decision makers.
  --mifid2-execution-algo: string # This field permits specification of the user's preregistered (via account management) MiFID II short code for algos that are responsible for handling/routing of the order.
  --mifid2-execution-trader: string # This field permits specification of the user's preregistered (via account management) MiFID II person responsible for handling/routing of the order
  --order-type: float@order-type-completer # Market = '1' Limit = '2' Stop = '3' StopLimit = '4'
  --orig-customer-order-id: string # The order ID assigned by the customer
  --outside-rth: float # Indicates if order is active outside regular trading hours, where defined. 0 = no (default), 1 = yes
  --price: float # The order price
  --quantity: float # The number of units in the order; contracts or shares
  --side: float@side-completer # Buy = '1', Sell = '2'
  --time-in-force: float@time-in-force-completer # Defines order's active lifetime. Day = '0' GTC (Good till Cancel) = '1' IOC (Immediate or Cancel) = '3' Open = '2' Close = '7'
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{account}/orders/{CustomerOrderId}"
    path_params: [{name: account, var: account}, {name: CustomerOrderId, var: customer_order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: "Aux Price", var: aux_price}, {name: CustomerOrderId, var: body_customer_order_id}, {name: GermanHftAlgo, var: german_hft_algo}, {name: Mifid2Algo, var: mifid2_algo}, {name: Mifid2DecisionMaker, var: mifid2_decision_maker}, {name: Mifid2ExecutionAlgo, var: mifid2_execution_algo}, {name: Mifid2ExecutionTrader, var: mifid2_execution_trader}, {name: "Order Type", var: order_type}, {name: OrigCustomerOrderId, var: orig_customer_order_id}, {name: "Outside RTH", var: outside_rth}, {name: Price, var: price}, {name: Quantity, var: quantity}, {name: Side, var: side}, {name: "Time in Force", var: time_in_force}]}
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: portal
  } {
    account: $account, customer_order_id: $customer_order_id, aux_price: $aux_price, body_customer_order_id: $body_customer_order_id, german_hft_algo: $german_hft_algo, mifid2_algo: $mifid2_algo, mifid2_decision_maker: $mifid2_decision_maker, mifid2_execution_algo: $mifid2_execution_algo, mifid2_execution_trader: $mifid2_execution_trader, order_type: $order_type, orig_customer_order_id: $orig_customer_order_id, outside_rth: $outside_rth, price: $price, quantity: $quantity, side: $side, time_in_force: $time_in_force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Account Positions
#
# GET /accounts/{account}/positions
# Returns: table<AverageCost: float, ContractId: float, Position: float>
export def "get-accounts-account-positions" [
  account: string
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
    path: "/accounts/{account}/positions"
    path_params: [{name: account, var: account}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: portal
  } {
    account: $account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Account Values Summary
#
# GET /accounts/{account}/summary
# Returns: record<Info: record<AccountCode: string, AccountReady: string, AccountType: string, Cushion: string, DayTradesRemaining: string, DayTradesRemainingT: string, "DayTradesRemainingT+2": string, "DayTradesRemainingT+3": string, "DayTradesRemainingT+4": string, HighestSeverity: string, Leverage-S: string, LookAheadNextChange: string, SegmentTitle-C: string, SegmentTitle-S: string, TradingType-S: string, WhatIfPMEnabled: string>, Ledger: table<CashBalance: float, CashBalanceFXSegment: float, CashCumQty: float, ExchangeRate: float, FutureOptionMarketValue: float, FuturePNL: float, NetDividend: float, NetInterest: float, NetLiquidation: float, OptionMarketValue: float, RealizedPNL: float, StockMarketValue: float, TotalCashBalance: float, UnrealizedPNL: float>, Summary: record<AccruedCash: float, AccruedCash-C: float, AccruedCash-S: float, AccruedDividend: float, AccruedDividend-C: float, AccruedDividend-S: float, AvailableFunds: float, AvailableFunds-C: float, AvailableFunds-S: float, Billable: float, Billable-C: float, Billable-S: float, BuyingPower: float, EquityWithLoanValue: float, EquityWithLoanValue-C: float, EquityWithLoanValue-S: float, ExcessLiquidity: float, ExcessLiquidity-C: float, ExcessLiquidity-S: float, FullAvailableFunds: float, FullAvailableFunds-C: float, FullAvailableFunds-S: float, FullExcessLiquidity: float, FullExcessLiquidity-C: float, FullExcessLiquidity-S: float, FullInitMarginReq: float, FullInitMarginReq-C: float, FullInitMarginReq-S: float, FullMaintMarginReq: float, FullMaintMarginReq-C: float, FullMaintMarginReq-S: float, GrossPositionValue: float, GrossPositionValue-C: float, GrossPositionValue-S: float, IndianStockHaircut: float, IndianStockHaircut-C: float, IndianStockHaircut-S: float, InitMarginReq: float, InitMarginReq-C: float, InitMarginReq-S: float, InsuredDeposit: float, InsuredDeposit-C: float, InsuredDeposit-S: float, LookAheadAvailableFunds: float, LookAheadAvailableFunds-C: float, LookAheadAvailableFunds-S: float, LookAheadExcessLiquidity: float, LookAheadExcessLiquidity-C: float, LookAheadExcessLiquidity-S: float, LookAheadInitMarginReq: float, LookAheadInitMarginReq-C: float, LookAheadInitMarginReq-S: float, LookAheadMaintMarginReq: float, LookAheadMaintMarginReq-C: float, LookAheadMaintMarginReq-S: float, MaintMarginReq: float, MaintMarginReq-C: float, MaintMarginReq-S: float, NetLiquidation: float, NetLiquidation-C: float, NetLiquidation-S: float, NetLiquidationUncertainty: float, PASharesValue: float, PASharesValue-C: float, PASharesValue-S: float, PostExpirationExcess: float, PostExpirationExcess-C: float, PostExpirationExcess-S: float, PostExpirationMargin: float, PostExpirationMargin-C: float, PostExpirationMargin-S: float, RegTEquity: float, RegTEquity-S: float, RegTMargin: float, RegTMargin-S: float, SMA: float, SMA-S: float, TotalCashValue: float, TotalCashValue-C: float, TotalCashValue-S: float>>
export def "get-accounts-account-summary" [
  account: string
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
    path: "/accounts/{account}/summary"
    path_params: [{name: account, var: account}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: portal
  } {
    account: $account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns trades in account
#
# GET /accounts/{account}/trades
# Returns: table<AvgPrice: float, Commission: float, CommissionCurrency: string, ContractId: float, Currency: string, CustomerOrderId: float, ExecId: string, ExecutionTime: string, FilledQuantity: float, LastMarket: string, ListingExchange: string, OrderId: string, OrderType: float, Quantity: float, RemainingQuantity: float, Side: string, Ticker: string, TradePrice: float, TradeSize: float>
export def "get-accounts-account-trades" [
  account: string
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
    path: "/accounts/{account}/trades"
    path_params: [{name: account, var: account}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: portal
  } {
    account: $account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exchange Components
#
# GET /marketdata/exchange_components
# Returns: table<Complete: bool, ConId: float, mapping: list<record>>
export def "get-marketdata-exchange-components" [
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
    path: "/marketdata/exchange_components"
    accept: ["application/json"]
    ok: [200]
    auth: portal
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Market Data Snapshot
#
# GET /marketdata/snapshot
# Returns: table<Bid: record<market: float, price: float, size: float>, Closing: record<price: float>, Complete: bool, Conid: string, Offer: record<market: float, price: float, size: float>, Temporality: float, Trade: record<market: float, price: float, size: float, time: float>>
export def "get-marketdata-snapshot" [
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
    path: "/marketdata/snapshot"
    accept: ["application/json"]
    ok: [200]
    auth: portal
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Obtain a access token
#
# POST /oauth/access_token
# Returns: record<oauth_token: string, oauth_token_secret: string>
export def "post-oauth-access-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --oauth-consumer-key: string # The 25-character hexadecimal string that was obtained from Interactive Brokers during the OAuth consumer registration process.
  --oauth-nonce: string # A random string uniquely generated for each request.
  --oauth-signature: string # The signature for the request generated using the method specified in the oauth_signature_method parameter. See section 9 of the OAuth v1.0a specification for more details on signing requests.
  --oauth-signature-method: string # The signature method used to sign the request. Currently only 'RSA-SHA256' is supported.
  --oauth-timestamp: string # Timestamp expressed in seconds since 1/1/1970 00:00:00 GMT. Must be a positive integer and greater than or equal to any timestamp used in previous requests.
  --oauth-token: string # The request token obtained from IB via /request_token.
  --oauth-verifier: string # The verification code received from IB after the user has granted authorization.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth/access_token"
    body: {content_type: "application/json", kind: json, fields: [{name: oauth_consumer_key, var: oauth_consumer_key}, {name: oauth_nonce, var: oauth_nonce}, {name: oauth_signature, var: oauth_signature}, {name: oauth_signature_method, var: oauth_signature_method}, {name: oauth_timestamp, var: oauth_timestamp}, {name: oauth_token, var: oauth_token}, {name: oauth_verifier, var: oauth_verifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: portal
  } {
    oauth_consumer_key: $oauth_consumer_key, oauth_nonce: $oauth_nonce, oauth_signature: $oauth_signature, oauth_signature_method: $oauth_signature_method, oauth_timestamp: $oauth_timestamp, oauth_token: $oauth_token, oauth_verifier: $oauth_verifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Obtain a live session token
#
# POST /oauth/live_session_token
# Returns: record<diffie_hellman_response: string, live_session_token_signature: string>
export def "post-oauth-live-session-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --diffie-hellman-challenge: string # Challenge value calculated using the Diffie-Hellman prime and generated provided during the registration process. See the "OAuth at Interactive Brokers" document for more details.
  --oauth-consumer-key: string # The 25-character hexadecimal string that was obtained from Interactive Brokers during the OAuth consumer registration process.
  --oauth-nonce: string # A random string uniquely generated for each request.
  --oauth-signature: string # The signature for the request generated using the method specified in the oauth_signature_method parameter. See section 9 of the OAuth v1.0a specification for more details on signing requests.
  --oauth-signature-method: string # The signature method used to sign the request. Currently only 'RSA-SHA256' is supported.
  --oauth-timestamp: string # Timestamp expressed in seconds since 1/1/1970 00:00:00 GMT. Must be a positive integer and greater than or equal to any timestamp used in previous requests.
  --oauth-token: string # The request token obtained from IB via /request_token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth/live_session_token"
    body: {content_type: "application/json", kind: json, fields: [{name: diffie_hellman_challenge, var: diffie_hellman_challenge}, {name: oauth_consumer_key, var: oauth_consumer_key}, {name: oauth_nonce, var: oauth_nonce}, {name: oauth_signature, var: oauth_signature}, {name: oauth_signature_method, var: oauth_signature_method}, {name: oauth_timestamp, var: oauth_timestamp}, {name: oauth_token, var: oauth_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: portal
  } {
    diffie_hellman_challenge: $diffie_hellman_challenge, oauth_consumer_key: $oauth_consumer_key, oauth_nonce: $oauth_nonce, oauth_signature: $oauth_signature, oauth_signature_method: $oauth_signature_method, oauth_timestamp: $oauth_timestamp, oauth_token: $oauth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Obtain a request token
#
# POST /oauth/request_token
# Returns: record<oauth_token: string>
export def "post-oauth-request-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --oauth-callback: string # An absolute URL to which IB will redirect the user. This URL is provided by the consumer during registration. This parameter must be set to 'oob'.
  --oauth-consumer-key: string # The 25-character hexadecimal string that was obtained from Interactive Brokers during the OAuth consumer registration process.
  --oauth-nonce: string # A random string uniquely generated for each request.
  --oauth-signature: string # The signature for the request generated using the method specified in the oauth_signature_method parameter. See section 9 of the OAuth v1.0a specification for more details on signing requests.
  --oauth-signature-method: string # The signature method used to sign the request. Currently only 'RSA-SHA256' is supported.
  --oauth-timestamp: string # Timestamp expressed in seconds since 1/1/1970 00:00:00 GMT. Must be a positive integer and greater than or equal to any timestamp used in previous requests.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth/request_token"
    body: {content_type: "application/json", kind: json, fields: [{name: oauth_callback, var: oauth_callback}, {name: oauth_consumer_key, var: oauth_consumer_key}, {name: oauth_nonce, var: oauth_nonce}, {name: oauth_signature, var: oauth_signature}, {name: oauth_signature_method, var: oauth_signature_method}, {name: oauth_timestamp, var: oauth_timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: portal
  } {
    oauth_callback: $oauth_callback, oauth_consumer_key: $oauth_consumer_key, oauth_nonce: $oauth_nonce, oauth_signature: $oauth_signature, oauth_signature_method: $oauth_signature_method, oauth_timestamp: $oauth_timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get security definition
#
# GET /secdef
# Returns: table<CompanyName: string, ContractId: float, Currency: string, Exchange: string, SecurityType: string, Ticker: string>
export def "get-secdef" [
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
    path: "/secdef"
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: portal
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
