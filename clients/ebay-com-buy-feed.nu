# Auto-generated client for Item Feed Service v1_beta.34.0
# Source: https://api.apis.guru/v2/specs/ebay.com/buy-feed/v1_beta.34.0/openapi.json
# Auth: --token flag or $env.ITEM_FEED_SERVICE_TOKEN

const CLIENT = {
  base_url: "https://api.ebay.com/buy/feed/v1_beta"
  token_env_var: "ITEM_FEED_SERVICE_TOKEN"
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

def base-url-completer [] { ["https://api.ebay.com/buy/feed/v1_beta"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/tab-separated-values"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-item-feed: "record<items: table<acceptedPaymentMethods: string, additionalImageUrls: string, additionalShippingCostPerUnit: string, ageGroup: string, alerts: string, availability: string, availabilityThreshold: int, availabilityThresholdType: string, brand: string, buyingOptions: string, category: string, categoryId: string, color: string, condition: string, conditionId: string, defaultImageUrl: string, deliveryOptions: string, discountAmount: string, discountPercentage: string, ecoParticipationFeeCurrency: string, ecoParticipationFeeValue: string, energyEfficiencyClass: string, epid: string, estimatedAvailableQuantity: int, gender: string, gtin: string, hazmatAdditionalInformation: string, hazmatPictogramDescriptions: string, hazmatPictogramIds: string, hazmatPictogramImageUrls: string, hazmatSignalWord: string, hazmatSignalWordId: string, hazmatStatementDescriptions: string, hazmatStatementIds: string, imageAlteringProhibited: bool, imageUrl: string, inferredBrand: string, inferredEpid: string, inferredGtin: string, inferredLocalizedAspects: string, inferredMpn: string, itemAffiliateWebUrl: string, itemCreationDate: string, itemEndDate: string, itemId: string, itemLocationCountry: string, itemWebUrl: string, legacyItemId: string, lengthUnitOfMeasure: string, localizedAspects: string, lotSize: int, material: string, mpn: string, originalPriceCurrency: string, originalPriceValue: string, packageHeight: string, packageLength: string, packageWeight: string, packageWidth: string, pattern: string, priceCurrency: string, priceValue: string, primaryItemGroupId: string, primaryItemGroupType: string, priorityListingPayload: string, qualifiedPrograms: string, quantityUsedForEstimate: int, refundMethod: string, repairScore: string, returnMethod: string, returnPeriodUnit: string, returnPeriodValue: int, returnShippingCostPayer: string, returnsAccepted: bool, sellerAccountType: string, sellerFeedbackPercentage: string, sellerFeedbackScore: string, sellerItemRevision: string, sellerTrustLevel: string, sellerUsername: string, shipToExcludedRegions: string, shipToIncludedRegions: string, shippingCarrierCode: string, shippingCost: string, shippingCostType: string, shippingServiceCode: string, shippingType: string, size: string, takeBackPolicyDescription: string, takeBackPolicyLabel: string, title: string, totalUnits: string, tyreLabelImageUrl: string, unitPrice: string, unitPricingMeasure: string, weightUnitOfMeasure: string>>"
    get-item-group-feed: "record<itemGroups: table<additionalImageUrls: string, imageAlteringProhibited: bool, imageUrl: string, itemGroupId: string, itemGroupType: string, title: string, variesByLocalizedAspects: string>>"
    get-item-priority-feed: "record<itemDelta: table<changeMetadata: string, itemId: string, priorityListingPayload: string>>"
    get-item-snapshot-feed: "record<items: table<acceptedPaymentMethods: string, additionalImageUrls: string, additionalShippingCostPerUnit: string, ageGroup: string, alerts: string, authenticityGuaranteeFeeCurrency: string, authenticityGuaranteeFeeValue: string, authenticityGuaranteeSelection: string, authenticityGuaranteeServiceId: string, availability: string, availabilityThreshold: int, availabilityThresholdType: string, brand: string, buyingOptions: string, category: string, categoryId: string, changeMetadata: string, color: string, condition: string, conditionId: string, couponDiscountCurrency: string, couponDiscountType: string, couponDiscountValue: string, couponExpirationDate: string, couponMessage: string, couponRedemptionCode: string, couponTermsWebUrl: string, defaultImageUrl: string, deliveryOptions: string, description: string, discountAmount: string, discountPercentage: string, ecoParticipationFeeCurrency: string, ecoParticipationFeeValue: string, energyEfficiencyClass: string, epid: string, estimatedAvailableQuantity: int, gender: string, gtin: string, hazmatAdditionalInformation: string, hazmatPictogramDescriptions: string, hazmatPictogramIds: string, hazmatPictogramImageUrls: string, hazmatSignalWord: string, hazmatSignalWordId: string, hazmatStatementDescriptions: string, hazmatStatementIds: string, imageAlteringProhibited: bool, imageUrl: string, inferredEpid: string, itemAffiliateWebUrl: string, itemCreationDate: string, itemEndDate: string, itemId: string, itemLocationCountry: string, itemSnapshotDate: string, itemWebUrl: string, legacyItemId: string, localizedAspects: string, lotSize: int, material: string, mpn: string, originalPriceCurrency: string, originalPriceValue: string, pattern: string, priceCurrency: string, priceValue: string, primaryItemGroupId: string, primaryItemGroupType: string, qualifiedPrograms: string, quantityUsedForEstimate: int, refundMethod: string, repairScore: string, returnMethod: string, returnPeriodUnit: string, returnPeriodValue: int, returnShippingCostPayer: string, returnsAccepted: bool, sellerAccountType: string, sellerFeedbackPercentage: string, sellerFeedbackScore: string, sellerItemRevision: string, sellerTrustLevel: string, sellerUsername: string, shipToExcludedRegions: string, shipToIncludedRegions: string, shippingCarrierCode: string, shippingCost: string, shippingCostType: string, shippingServiceCode: string, shippingType: string, size: string, takeBackPolicyDescription: string, takeBackPolicyLabel: string, title: string, totalUnits: string, tyreLabelImageUrl: string, unitPrice: string, unitPricingMeasure: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-item-feed" "get-item-group-feed" "get-item-priority-feed" "get-item-snapshot-feed" "commands"] | sort) } | get name | first)
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

# This method lets you download a TSV_GZIP (tab separated value gzip) Item feed file. The feed file contains all the items from all the child categories of the specified category. The first line of the file is the header, which labels the columns and indicates the order of the values on each line. Each header is described in the Response fields (/api-docs/buy/feed/resources/item/methods/getItemFeed#h3-response-fields) section. There are two types of item feed files generated: A daily Item feed file containing all the newly listed items for a specific category, date, and marketplace (feed_scope = NEWLY_LISTED) A weekly Item Bootstrap feed file containing all the items in a specific category and marketplace (feed_scope = ALL_ACTIVE) Note: Filters are applied to the feed files. For details, see Feed File Filters (/api-docs/buy/static/api-feed_beta.html#Feed2). When curating the items returned, be sure to code as if these filters are not applied as they can be changed or removed in the future.Downloading feed files Item feed files are binary gzip files. If the file is larger than 100 MB, the download must be streamed in chunks. You specify the size of the chunks in bytes using the Range (#range-header) request header. The Content-range (#content-range) response header indicates where in the full resource this partial chunk of data belongs and the total number of bytes in the file. For more information about using these headers, see Retrieving a gzip feed file (/api-docs/buy/static/api-feed_beta.html#retrv-gzip). In addition to the API, there is an open source Feed SDK (https://github.com/eBay/FeedSDK) written in Java that downloads, combines files into a single file when needed, and unzips the entire feed file. It also lets you specify field filters to curate the items in the file. Note: A successful call will always return a TSV.GZIP file; however, unsuccessful calls generate errors that are returned in JSON format. For documentation purposes, the successful call response is shown below as JSON fields so that the value returned in each column can be explained. The order of the response fields shows the order of the columns in the feed file. Restrictions For a list of supported sites and other restrictions, see API Restrictions (/api-docs/buy/feed/overview.html#API).
#
# GET /item
# Returns: record<items: table<acceptedPaymentMethods: string, additionalImageUrls: string, additionalShippingCostPerUnit: string, ageGroup: string, alerts: string, availability: string, availabilityThreshold: int, availabilityThresholdType: string, brand: string, buyingOptions: string, category: string, categoryId: string, color: string, condition: string, conditionId: string, defaultImageUrl: string, deliveryOptions: string, discountAmount: string, discountPercentage: string, ecoParticipationFeeCurrency: string, ecoParticipationFeeValue: string, energyEfficiencyClass: string, epid: string, estimatedAvailableQuantity: int, gender: string, gtin: string, hazmatAdditionalInformation: string, hazmatPictogramDescriptions: string, hazmatPictogramIds: string, hazmatPictogramImageUrls: string, hazmatSignalWord: string, hazmatSignalWordId: string, hazmatStatementDescriptions: string, hazmatStatementIds: string, imageAlteringProhibited: bool, imageUrl: string, inferredBrand: string, inferredEpid: string, inferredGtin: string, inferredLocalizedAspects: string, inferredMpn: string, itemAffiliateWebUrl: string, itemCreationDate: string, itemEndDate: string, itemId: string, itemLocationCountry: string, itemWebUrl: string, legacyItemId: string, lengthUnitOfMeasure: string, localizedAspects: string, lotSize: int, material: string, mpn: string, originalPriceCurrency: string, originalPriceValue: string, packageHeight: string, packageLength: string, packageWeight: string, packageWidth: string, pattern: string, priceCurrency: string, priceValue: string, primaryItemGroupId: string, primaryItemGroupType: string, priorityListingPayload: string, qualifiedPrograms: string, quantityUsedForEstimate: int, refundMethod: string, repairScore: string, returnMethod: string, returnPeriodUnit: string, returnPeriodValue: int, returnShippingCostPayer: string, returnsAccepted: bool, sellerAccountType: string, sellerFeedbackPercentage: string, sellerFeedbackScore: string, sellerItemRevision: string, sellerTrustLevel: string, sellerUsername: string, shipToExcludedRegions: string, shipToIncludedRegions: string, shippingCarrierCode: string, shippingCost: string, shippingCostType: string, shippingServiceCode: string, shippingType: string, size: string, takeBackPolicyDescription: string, takeBackPolicyLabel: string, title: string, totalUnits: string, tyreLabelImageUrl: string, unitPrice: string, unitPricingMeasure: string, weightUnitOfMeasure: string>>
# operationId: getItemFeed
export def "get-item-feed" [
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
  --feed-scope: string # Specifies the type of feed file to return. Valid Values: NEWLY_LISTED - Returns the daily Item feed file containing all Good 'Til Cancelled items that were listed on the day specified by the date parameter in the category specified by the category_id parameter./item?feed_scope=NEWLY_LISTED&category_id=15032&date=20170925ALL_ACTIVE - Returns the weekly Item Bootstrap feed file containing all the Good 'Til Cancelled items in the category specified by the category_id parameter.Note: Bootstrap files are generated every Tuesday and the file is available on Wednesday. However, the exact time the file is available can vary so we recommend you download the Bootstrap file on Thursday. The items in the file are the items that were in the specified category on Sunday. /item?feed_scope=ALL_ACTIVE&category_id=15032 (required)
  --category-id: string # An eBay top-level category ID of the items to be returned in the feed file. The list of eBay category IDs changes over time and category IDs are not the same across all the eBay marketplaces. To get a list of the top-level categories for a marketplace, you can use the Taxonomy API getCategoryTree (/api-docs/commerce/taxonomy/resources/category_tree/methods/getCategoryTree) method. This method retrieves the complete category tree for the marketplace. The top-level categories are identified by the categoryTreeNodeLevel field. For example: "categoryTreeNodeLevel": 1 For details see Get Categories for Buy APIs (/api-docs/buy/buy-categories.html). Restriction: Must be a top-level (L1) category other than Real Estate. Items listed under Real Estate L1 categories are excluded from all feeds in all marketplaces. (required)
  --date: string # The date of the daily Item feed file (feed_scope=NEWLY_LISTED) you want. The date is required only for the daily Item feed file. If you specify a date for the Item Bootstrap file (feed_scope=ALL_ACTIVE), the date is ignored and the latest file is returned. The date the Item Bootstrap feed file was generated is returned in the Last-Modified response header. The Item feed files are generated every day and there are 14 daily files available. Note: The daily Item feed files are available each day after 9AM MST (US Mountain Standard Time), which is -7 hours UTC time. There is a 48 hour latency when generating the Item feed files. This means you can download the file for July 10th on July 12 after 9AM MST. Note: For categories with a large number of items, the latency can be up to 72 hours. Format: yyyyMMdd Requirements: Required when feed_scope=NEWLY_LISTED Must be within 3-14 days in the past
  --hdr-accept: string # The formats that the client accepts for the response.A successful call will always return a TSV.GZIP file; however, unsuccessful calls generate errors that are returned in JSON format.Default: application/json,text/tab-separated-values (required) (spec name: Accept)
  --x-ebay-c-marketplace-id: string # The ID of the eBay marketplace where the item is hosted. Note: This value is case sensitive.For example: X-EBAY-C-MARKETPLACE-ID = EBAY_US For a list of supported sites see, API Restrictions (/api-docs/buy/feed/overview.html#API). (required)
  --range: string # This header specifies the range in bytes of the chunks of the gzip file being returned. Format: bytes=startpos-endpos For example, the following retrieves the first 10 MBs of the feed file. Range bytes=0-10485760 For more information about using this header, see Retrieving a gzip feed file (/api-docs/buy/static/api-feed_beta.html#retrv-gzip). Maximum: 100 MB (10MB in the Sandbox) (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/item"
    query: [{name: feed_scope, var: feed_scope, required: true}, {name: category_id, var: category_id, required: true}, {name: date, var: date}]
    header: [{name: Accept, var: hdr_accept, required: true}, {name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id, required: true}, {name: Range, var: range, required: true}]
    accept: ["application/json", "text/tab-separated-values"]
    ok: [200, 204, 206]
    auth: bearer
  } {
    feed_scope: $feed_scope, category_id: $category_id, date: $date, hdr_accept: $hdr_accept, x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# This method lets you download a TSV_GZIP (tab separated value gzip) Item Group feed file. An item group is an item that has various aspect differences, such as color, size, storage capacity, etc. There are two types of item group feed files generated: A daily Item Group feed file containing the item group variation information associated with items returned in the Item (/api-docs/buy/feed/resources/item/methods/getItemFeed) feed file for a specific day, category, and marketplace. (feed_scope = NEWLY_LISTED) A weekly Item Group Bootstrap feed file containing all the item group variation information associated with items returned in the Item Bootstrap (/api-docs/buy/feed/resources/item/methods/getItemFeed) feed file for all the items in a specific category. (feed_scope = ALL_ACTIVE) Note: Filters are applied to the feed files. For details, see Feed File Filters (/api-docs/buy/static/api-feed.html#feed-filters). When curating the items returned, be sure to code as if these filters are not applied as they can be changed or removed in the future. The contents of these feed files are based on the contents of the corresponding daily Item or Item Bootstrap feed file. When a new Item or Item Bootstrap feed file is generated, the service reads the file and if an item in the file has a primaryItemGroupId value, which indicates the item is part of an item group, it uses that value to return the item group (parent item) information for that item in the corresponding Item Group or Item Group Bootstrap feed file. This information includes the name/value pair of the aspects of the items in this group returned in the variesByLocalizedAspects column. For example, if the item was a shirt some of the variation names could be Size, Color, etc. Also the images for the various aspects are returned in the additionalImageUrls column. The first line in any feed file is the header, which labels the columns and indicates the order of the values on each line. Each header is described in the Response fields (/api-docs/buy/feed/resources/item_group/methods/getItemGroupFeed#h3-response-fields) section. Combining the Item Group and Item feed files The Item Group or Item Group Bootstrap feed file contains details about the item group (parent item), including the item group ID itemGroupId. You match the value of itemGroupId from the Item Group feed file with the value of primaryItemGroupId from the corresponding daily Item or Item Bootstrap feed file.Downloading feed files Item Group feed files are binary gzip files. If the file is larger than 100 MB, the download must be streamed in chunks. You specify the size of the chunks in bytes using the Range (#range-header) request header. The content-range (#content-range) response header indicates where in the full resource this partial chunk of data belongs and the total number of bytes in the file. For more information about using these headers, see Retrieving a gzip feed file (/api-docs/{swift-folder}/buy/static/api-feed_beta.html#retrv-gzip). Note: A successful call will always return a TSV.GZIP file; however, unsuccessful calls generate errors that are returned in JSON format. For documentation purposes, the successful call response is shown below as JSON fields so that the value returned in each column can be explained. The order of the response fields shows the order of the columns in the feed file. Restrictions For a list of supported sites and other restrictions, see API Restrictions (/api-docs/{swift-folder}/buy/feed/overview.html#API).
#
# GET /item_group
# Returns: record<itemGroups: table<additionalImageUrls: string, imageAlteringProhibited: bool, imageUrl: string, itemGroupId: string, itemGroupType: string, title: string, variesByLocalizedAspects: string>>
# operationId: getItemGroupFeed
export def "get-item-group-feed" [
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
  --feed-scope: string # Specifies the type of file to return. Valid Values: NEWLY_LISTED - Returns the Item Group feed file containing the item group variation information for items in the daily Item (/api-docs/buy/feed/resources/item/methods/getItemFeed) feed file that were associated with an item group. The items in this type of Item feed file are items that were listed on the day specified by the date parameter in the category specified by the category_id parameter. /item_group?feed_scope=NEWLY_LISTED&category_id=15032&date=20170925 ALL_ACTIVE - Returns the weekly Item Group Bootstrap file containing the item group variation information for items in the weekly Item Bootstrap (/api-docs/buy/feed/resources/item/methods/getItemFeed) feed file that were associated with an item group. The items are Good 'Til Cancelled items in the category specified by the category_id parameter. Note: Bootstrap files are generated every Tuesday and the file is available on Wednesday. However, the exact time the file is available can vary so we recommend you download the Bootstrap file on Thursday. The item groups in the file are for the items that were in the specified category on Sunday./item_group?feed_scope=ALL_ACTIVE&category_id=15032 (required)
  --category-id: string # An eBay top-level category ID of the items to be returned in the feed file. The list of eBay category IDs changes over time and category IDs are not the same across all the eBay marketplaces. To get a list of the top-level categories for a marketplaces, you can use the Taxonomy API getCategoryTree (/api-docs/commerce/taxonomy/resources/category_tree/methods/getCategoryTree) method. This method retrieves the complete category tree for the marketplace. The top-level categories are identified by the categoryTreeNodeLevel field. For example: "categoryTreeNodeLevel": 1 For details see Get Categories for Buy APIs (/api-docs/buy/buy-categories.html). Restriction: Must be a top-level category other than Real Estate. Items listed under Real Estate L1 categories are excluded from all feeds in all marketplaces. (required)
  --date: string # The date of the daily Item Group feed file (feed_scope=NEWLY_LISTED) you want. The date is required only for the daily Item Group feed file. If you specify a date for the Item Group Bootstrap file (feed_scope=ALL_ACTIVE), the date is ignored and the latest file is returned. The date the Item Group Bootstrap feed file was generated is returned in the Last-Modified response header. The Item Group feed files are generated every day and there are 14 daily files available. There is a 48 hour latency when generating the files. This means on July 10, the latest feed file you can download is July 8. Note: The generated files are stored using MST (US Mountain Standard Time), which is -7 hours UTC time. Format: yyyyMMdd Requirements: Required only when feed_scope=NEWLY_LISTED Must be within 3-14 days in the past
  --hdr-accept: string # The formats that the client accepts for the response.A successful call will always return a TSV.GZIP file; however, unsuccessful calls generate error codes that are returned in JSON format.Default: application/json,text/tab-separated-values (required) (spec name: Accept)
  --x-ebay-c-marketplace-id: string # The ID of the eBay marketplace where the item is hosted. Note: This value is case sensitive.For example: X-EBAY-C-MARKETPLACE-ID = EBAY_US For a list of supported sites see, API Restrictions (/api-docs/buy/feed/overview.html#API). (required)
  --range: string # This header specifies the range in bytes of the chunks of the gzip file being returned. Format: bytes=startpos-endpos For example, the following retrieves the first 10 MBs of the feed file. Range bytes=0-10485760 For more information about using this header, see Retrieving a gzip feed file (/api-docs/buy/static/api-feed_beta.html#retrv-gzip). Maximum: 100 MB (10MB in the Sandbox)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/item_group"
    query: [{name: feed_scope, var: feed_scope, required: true}, {name: category_id, var: category_id, required: true}, {name: date, var: date}]
    header: [{name: Accept, var: hdr_accept, required: true}, {name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id, required: true}, {name: Range, var: range}]
    accept: ["application/json", "text/tab-separated-values"]
    ok: [200, 204, 206]
    auth: bearer
  } {
    feed_scope: $feed_scope, category_id: $category_id, date: $date, hdr_accept: $hdr_accept, x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Using this method, you can download a TSV_GZIP (tab separated value gzip) Item Priority feed file, which allows you to track changes (deltas) in the status of your priority items, such as when an item is added or removed from a campaign. The delta feed tracks the changes to the status of items within a category you specify in the input URI. You can also specify a specific date for the feed you want returned. Important: You must consume the daily feeds (Item, Item Group) before consuming the Item Priority feed. This ensures that your inventory is up to date.Downloading feed files Note: Filters are applied to the feed files. For details, see Feed File Filters (/api-docs/buy/static/api-feed.html#feed-filters). When curating the items returned, be sure to code as if these filters are not applied as they can be changed or removed in the future.Priority Item feed files are binary gzip files. If the file is larger than 100 MB, the download must be streamed in chunks. You specify the size of the chunks in bytes using the Range (#range-header) request header. The Content-range (#content-range) response header indicates where in the full resource this partial chunk of data belongs and the total number of bytes in the file. For more information about using these headers, see Retrieving a gzip feed file (/api-docs/buy/static/api-feed_beta.html#retrv-gzip). In addition to the API, there is an open source Feed SDK (https://github.com/eBay/FeedSDK) written in Java that downloads, combines files into a single file when needed, and unzips the entire feed file. It also lets you specify field filters to curate the items in the file. Note: A successful call will always return a TSV.GZIP file; however, unsuccessful calls generate errors that are returned in JSON format. For documentation purposes, the successful call response is shown below as JSON fields so that the value returned in each column can be explained. The order of the response fields shows the order of the columns in the feed file. Restrictions For a list of supported sites and other restrictions, see API Restrictions (/api-docs/buy/feed/overview.html#API).
#
# GET /item_priority
# Returns: record<itemDelta: table<changeMetadata: string, itemId: string, priorityListingPayload: string>>
# operationId: getItemPriorityFeed
export def "get-item-priority-feed" [
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
  --category-id: string # An eBay top-level category ID of the items to be returned in the feed file. The list of eBay category IDs changes over time and category IDs are not the same across all the eBay marketplaces. To get a list of the top-level categories for a marketplaces, you can use the Taxonomy API getCategoryTree (/api-docs/commerce/taxonomy/resources/category_tree/methods/getCategoryTree) method. This method retrieves the complete category tree for the marketplace. The top-level categories are identified by the categoryTreeNodeLevel field.For example: "categoryTreeNodeLevel": 1 For details see Get the eBay categories of a marketplace (/api-docs/buy/api-feed.html#Getcat).Restriction: Must be a top-level category other than Real Estate. Items listed under Real Estate L1 categories are excluded from all feeds in all marketplaces. (required)
  --date: string # The date of the feed you want returned. This can be up to 14 days in the past but cannot be set to a date in the future. Format: yyyyMMdd Note: The daily Item feed files are available each day after 9AM MST (US Mountain Standard Time), which is -7 hours UTC time. There is a 48 hour latency when generating the Item feed files. This means you can download the file for July 10th on July 12 after 9AM MST. Note: For categories with a large number of items, the latency can be up to 72 hours. (required)
  --hdr-accept: string # The formats that the client accepts for the response.A successful call will always return a TSV.GZIP file; however, unsuccessful calls generate error codes that are returned in JSON format.Default: application/json,text/tab-separated-values (required) (spec name: Accept)
  --x-ebay-c-marketplace-id: string # The ID of the eBay marketplace where the item is hosted. Note: This value is case sensitive.For example: X-EBAY-C-MARKETPLACE-ID = EBAY_US For a list of supported sites see, Buy API Support by Marketplace (/api-docs/buy/static/ref-marketplace-supported.html). (required)
  --range: string # Header specifying content range to be retrieved. Only supported range is bytes. Example : bytes = 0-102400. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/item_priority"
    query: [{name: category_id, var: category_id, required: true}, {name: date, var: date, required: true}]
    header: [{name: Accept, var: hdr_accept, required: true}, {name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id, required: true}, {name: Range, var: range, required: true}]
    accept: ["application/json", "text/tab-separated-values"]
    ok: [200, 204, 206]
    auth: bearer
  } {
    category_id: $category_id, date: $date, hdr_accept: $hdr_accept, x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Hourly Snapshot feed file is generated each hour every day for most categories. This method lets you download an Hourly Snapshot TSV_GZIP (tab-separated value gzip) feed file containing the details of all the items that have changed (/api-docs/buy/static/api-feed.html#changed-items) within the specified day and hour for a specific category. This means to generate the 8AM file of items that have changed from 8AM and 8:59AM, the service starts at 9AM. You can retrieve the 8AM snapshot file at 10AM. Snapshot feeds now include new listings. You can check itemCreationDate (/api-docs/buy/feed/resources/item_snapshot/methods/getItemSnapshotFeed#response.items.itemCreationDate) to identify listings that were newly created within the specified hour. Note: Filters are applied to the feed files. For details, see Feed File Filters (/api-docs/buy/static/api-feed.html#feed-filters). When curating the items returned, be sure to code as if these filters are not applied as they can be changed or removed in the future. You can use the response from this method to update the item details of items stored in your database. By looking at the value of itemSnapshotDate (/api-docs/buy/feed/resources/item_snapshot/methods/getItemSnapshotFeed#response.items.itemSnapshotDate) for a given item, you will be able to tell which information is the latest. Important: When the value of the availability column is UNAVAILABLE, only the itemId and availability columns are populated. Downloading feed files Hourly snapshot feed files are binary gzip files. If the file is larger than 100 MB, the download must be streamed in chunks. You specify the size of the chunks in bytes using the Range (#range-header) request header. The Content-range (#content-range) response header indicates where in the full resource this partial chunk of data belongs and the total number of bytes in the file. For more information about using these headers, see Retrieving a gzip feed file (/api-docs/buy/static/api-feed_beta.html#retrv-gzip). Note: A successful call will always return a TSV.GZIP file; however, unsuccessful calls generate errors that are returned in JSON format. For documentation purposes, the successful call response is shown below as JSON fields so that the value returned in each column can be explained. The order of the response fields shows the order of the columns in the feed file.Restrictions For a list of supported sites and other restrictions, see API Restrictions (/api-docs/buy/feed/overview.html#API).
#
# GET /item_snapshot
# Returns: record<items: table<acceptedPaymentMethods: string, additionalImageUrls: string, additionalShippingCostPerUnit: string, ageGroup: string, alerts: string, authenticityGuaranteeFeeCurrency: string, authenticityGuaranteeFeeValue: string, authenticityGuaranteeSelection: string, authenticityGuaranteeServiceId: string, availability: string, availabilityThreshold: int, availabilityThresholdType: string, brand: string, buyingOptions: string, category: string, categoryId: string, changeMetadata: string, color: string, condition: string, conditionId: string, couponDiscountCurrency: string, couponDiscountType: string, couponDiscountValue: string, couponExpirationDate: string, couponMessage: string, couponRedemptionCode: string, couponTermsWebUrl: string, defaultImageUrl: string, deliveryOptions: string, description: string, discountAmount: string, discountPercentage: string, ecoParticipationFeeCurrency: string, ecoParticipationFeeValue: string, energyEfficiencyClass: string, epid: string, estimatedAvailableQuantity: int, gender: string, gtin: string, hazmatAdditionalInformation: string, hazmatPictogramDescriptions: string, hazmatPictogramIds: string, hazmatPictogramImageUrls: string, hazmatSignalWord: string, hazmatSignalWordId: string, hazmatStatementDescriptions: string, hazmatStatementIds: string, imageAlteringProhibited: bool, imageUrl: string, inferredEpid: string, itemAffiliateWebUrl: string, itemCreationDate: string, itemEndDate: string, itemId: string, itemLocationCountry: string, itemSnapshotDate: string, itemWebUrl: string, legacyItemId: string, localizedAspects: string, lotSize: int, material: string, mpn: string, originalPriceCurrency: string, originalPriceValue: string, pattern: string, priceCurrency: string, priceValue: string, primaryItemGroupId: string, primaryItemGroupType: string, qualifiedPrograms: string, quantityUsedForEstimate: int, refundMethod: string, repairScore: string, returnMethod: string, returnPeriodUnit: string, returnPeriodValue: int, returnShippingCostPayer: string, returnsAccepted: bool, sellerAccountType: string, sellerFeedbackPercentage: string, sellerFeedbackScore: string, sellerItemRevision: string, sellerTrustLevel: string, sellerUsername: string, shipToExcludedRegions: string, shipToIncludedRegions: string, shippingCarrierCode: string, shippingCost: string, shippingCostType: string, shippingServiceCode: string, shippingType: string, size: string, takeBackPolicyDescription: string, takeBackPolicyLabel: string, title: string, totalUnits: string, tyreLabelImageUrl: string, unitPrice: string, unitPricingMeasure: string>>
# operationId: getItemSnapshotFeed
export def "get-item-snapshot-feed" [
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
  --category-id: string # An eBay top-level category ID of the items to be returned in the feed file. The list of eBay category IDs changes over time and category IDs are not the same across all the eBay marketplaces. To get a list of the top-level categories for a marketplace, you can use the Taxonomy API getCategoryTree (/api-docs/commerce/taxonomy/resources/category_tree/methods/getCategoryTree) method. This method retrieves the complete category tree for the marketplace. The top-level categories are identified by the categoryTreeNodeLevel field.For example: "categoryTreeNodeLevel": 1 For details see Get Categories for Buy APIs (/api-docs/buy/buy-categories.html). Restriction: Must be a top-level category other than Real Estate. Items listed under Real Estate L1 categories are excluded from all feeds in all marketplaces. (required)
  --snapshot-date: string # The date and hour of the snapshot feed file you want. Each file contains the items that changed within the hour in the specified category. So, the 9AM file contains the items that changed between 9AM and 9:59AM on the day specified. It takes 2 hours to generate a snapshot file, which means to get the file for 9AM the earliest you could submit the call is at 11AM.There are 7 days of Hourly Snapshot feed files available.Note: The Feed API uses GMT, so you must convert your local time to GMT. For example, if you lived in California and wanted the September 15th 7pm file, you would submit the following call: item_snapshot?category_id=625&snapshot_date=2017-09-16T02:00:00.000Z Format: UTC yyyy-MM-ddThh:00:00.000Z Files are generated on the hour, so minutes and seconds are always zeros. (required)
  --hdr-accept: string # The formats that the client accepts for the response.A successful call will always return a TSV.GZIP file; however, unsuccessful calls generate error codes that are returned in JSON format.Default: application/json,text/tab-separated-values (required) (spec name: Accept)
  --x-ebay-c-marketplace-id: string # The ID of the eBay marketplace where the item is hosted. Note: This value is case sensitive.For example: X-EBAY-C-MARKETPLACE-ID = EBAY_US For a list of supported sites see, API Restrictions (/api-docs/buy/feed/overview.html#API). (required)
  --range: string # This header specifies the range in bytes of the chunks of the gzip file being returned. Format: bytes=startpos-endpos For example, the following retrieves the first 10 MBs of the feed file. Range bytes=0-10485760 For more information about using this header, see Retrieving a gzip feed file (/api-docs/buy/static/api-feed_beta.html#retrv-gzip). Maximum: 100 MB (10MB in the Sandbox) (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/item_snapshot"
    query: [{name: category_id, var: category_id, required: true}, {name: snapshot_date, var: snapshot_date, required: true}]
    header: [{name: Accept, var: hdr_accept, required: true}, {name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id, required: true}, {name: Range, var: range, required: true}]
    accept: ["application/json", "text/tab-separated-values"]
    ok: [200, 204, 206]
    auth: bearer
  } {
    category_id: $category_id, snapshot_date: $snapshot_date, hdr_accept: $hdr_accept, x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
