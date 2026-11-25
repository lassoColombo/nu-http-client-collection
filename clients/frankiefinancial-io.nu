# Auto-generated client for Frankie Financial API v1.5.3
# Source: https://api.apis.guru/v2/specs/frankiefinancial.io/1.5.3/swagger.json
# Auth: --token flag or $env.FRANKIE_FINANCIAL_API_TOKEN

const CLIENT = {
  base_url: "https://api.demo.frankiefinancial.io/compliance/v1.2"
  token_env_var: "FRANKIE_FINANCIAL_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: api_key, in: header, header_name: api_key, prefix: ""}
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

def base-url-completer [] { ["https://api.demo.frankiefinancial.io/compliance/v1.2"] }
def auth-scheme-completer [] { ["api_key" "none"] }

# Completers for enum parameters
def result-level-completer [] { ["full" "summary"] }
def validation-completer [] { ["acn" "off" "on" "only"] }
def entity-type-completer [] { ["INDIVIDUAL" "ORGANISATION" "TRUST"] }
def gender-completer [] { ["F" "M" "O" "U"] }
def document-status-completer [] { ["DOC_CHECKED" "DOC_SCANNED" "INITIALISING" "SCAN_IN_PROGRESS"] }
def id-type-completer [] { ["ANNUAL_RETURN" "ATTESTATION" "BANK_ACCOUNT" "BANK_STATEMENT" "BIRTH_CERT" "CHARGES" "CHECK_RESULTS" "CITIZENSHIP" "CONCESSION" "DEATH_CERT" "DEVICE" "DRIVERS_LICENCE" "EMAIL_ADDRESS" "EXTERNAL_ADMIN" "HEALTH_CONCESSION" "IMMIGRATION" "INTENT_PROOF" "MARRIAGE_CERT" "MILITARY_ID" "MOBILE_PHONE" "MSISDN" "NAME_CHANGE" "NATIONAL_HEALTH_ID" "NATIONAL_ID" "OTHER" "PASSPORT" "PENSION" "PRE_ASIC" "REPORT" "SELF_IMAGE" "TAX_ID" "UTILITY_BILL" "VEHICLE_REGISTRATION" "VISA"] }
def result-level-completer-1 [] { ["full" "simple" "summary"] }
def check-class-completer [] { ["bcro" "fraudlist" "pro"] }
def status-completer [] { ["FALSE_POSITIVE" "STALE" "TRUE_POSITIVE" "TRUE_POSITIVE_ACCEPT" "TRUE_POSITIVE_REJECT" "UNKNOWN"] }
def set-completer [] { ["archived" "clear" "fail" "inactive" "wait"] }
def risk-completer [] { ["high" "low" "medium" "significant" "unacceptable"] }
def payload-completer [] { ["object" "string"] }
def function-result-completer [] { ["COMPLETED" "FAILED" "INCOMPLETE"] }
def notification-type-completer [] { ["ALERT" "EVENT" "FUNCTION" "RESULT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    international-business-profile: "record<CompanyProfile: record<Activity: record<ActivityDTO: list>, ActivityDeclaration: record<ActivityDeclarationDTO: list>, Addresses: record<Addresses: list>, AgentAddress: string, AgentName: string, Aliases: record<AddressLine: list>, AppointmentDateOfOfficial: string, Capital: record<CapitalDTO: list>, Code: string, CompanyNameInEnglish: string, Date: string, Email: string, FaxNumber: string, FiscalCode: string, FoundationDate: string, Functions: record<AddressLine: list>, Headquarters: string, KeyFigures: record<AddressLine: list>, LastAnnualAccountDate: string, LegalForm: string, LegalFormDeclaration: string, LegalFormDetails: record<Basis: string, Capital: string, Comments: string, Control: string, Incorp: string, Partner: string, Responsibility: string, Stocks: string>, LegalStatus: string, MailingAddress: string, Name: string, Official: bool, RegistrationAuthority: string, RegistrationAuthorityCode: string, RegistrationDate: string, RegistrationNumber: string, SigningDeclaration: string, SigningDeclarationDescription: string, SigningLanguage: string, Source: string, StateOfIncorporation: string, TelephoneNumber: string, VatNumber: string, VirtualId: string, WebsiteURL: string, directorAndShareDetails: record<PersonsOfSignificantControl: record, capitalReserves: record, directors: record, shareHolderSummary: record, shareHolders: record>, officers: record<USOfficerDTO: list>>, checkId: string, entityId: string, ibResponseCode: int, ibResponseDetails: string, ibRetrievalLocation: string, ibTransactionId: string, requestId: string>"
    international-business-search: "record<Companies: record<CompanyDTO: list<record>>, ibContinuationKey: string, ibResponseCode: int, ibResponseDetails: string, ibTransactionId: string, requestId: string>"
    business-ownership-query: "record<flags: table<flag: string, value: int>, organisationCheckId: string, organisationCheckResult: record<entityCategories: record, entityCheckErrors: record, entityCheckResults: record, entityId: string, groupId: string>, ownershipCheckDate: string, ownershipCheckId: string, ownershipQueryError: record<commit: string, errorCode: string, errorMsg: string, httpStatusCode: int, issues: list<record>, requestId: string>, ownershipQueryResult: record<associatedEntities: record, blockingEntityIds: list<string>, entityId: string, ownershipDetails: record>, reportError: record<commit: string, errorCode: string, errorMsg: string, httpStatusCode: int, issues: list<record>, requestId: string>, reportResult: record<documentId: string, location: string, scanDocId: string>, requestId: string, uboResponse: record<asic_search_timestamp: string, business_details: record<ABN: string, ACN: string, ARBN: string, anzsic_code: string, asic_company_type: string, business_names: list, date_registered_with_asic: string, entity_id: string, giin: string, place_of_business: record, public_company: bool, registered_name: string, registered_office: record, regulatory_information: record, state_registered_with_asic: string, stock_exchange_data: record, trading_names: list>, business_screening_result: record<aml_result: record, kyc_result: record>, error_message: string, issues_list: list<record>, non_individual_beneficial_owners: list<record>, officeholders: list<record>, supplied_data: record<abn: string, acn: string, company_type: string, customer_reference: string, name: string>, supplied_data_matches: record<matched_acn: bool, matched_company_type: bool, matched_name: bool>, ubo_report: string, ultimate_beneficial_owners: list<record>>>"
    run-business-reports: "record<checkId: string, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, reports: table<details: record, report: record>, requestId: string>"
    check-organisation: "record<checkId: string, entityId: string, function: string, linkURL: string, requestId: string>"
    create-document: "record<document: record<country: string, createdFromScan: bool, docScan: list<record>, documentId: string, documentStatus: string, extraData: list<record>, idExpiry: string, idIssued: string, idNumber: string, idSubType: string, idType: string, manuallyModified: bool, region: string>, requestId: string>"
    compare-document: "record<documentComparisonResults: record<compareDocumentId: string, processResult: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, toDocumentId: string>, requestId: string>"
    create-scan-document: "record<extractedDocument: record<country: string, createdFromScan: bool, docScan: list<record>, documentId: string, documentStatus: string, extraData: list<record>, idExpiry: string, idIssued: string, idNumber: string, idSubType: string, idType: string, manuallyModified: bool, region: string>, extractedEntity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, processResult: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, requestId: string>"
    create-process-industry-utility-document: "record<documentId: string, industryProcess: string, requestId: string, utilityCompareResult: record<error: record<comparisonDate: string, correlationId: string, errorCode: int, message: string, version: string>, result: record<comparisonDate: string, correlationId: string, currentBillData: record, defaultOffer: record, marketDisclosure: record, maximumSaving: float, plans: list, version: string>>>"
    verify-document: "record<documentVerificationResults: record<documentId: string, processResult: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>>, requestId: string>"
    search-document: "record<documentSearchResults: table<confidence: record, document: record>, requestId: string>"
    delete-document: "record<requestId: string, statusMsg: string>"
    query-document: "record<document: record<country: string, createdFromScan: bool, docScan: list<record>, documentId: string, documentStatus: string, extraData: list<record>, idExpiry: string, idIssued: string, idNumber: string, idSubType: string, idType: string, manuallyModified: bool, region: string>, requestId: string>"
    update-document: "record<document: record<country: string, createdFromScan: bool, docScan: list<record>, documentId: string, documentStatus: string, extraData: list<record>, idExpiry: string, idIssued: string, idNumber: string, idSubType: string, idType: string, manuallyModified: bool, region: string>, requestId: string>"
    query-document-checks: "record<checkResults: record<checkResult: list<record>, idDocument: record<country: string, createdFromScan: bool, docScan: list, documentId: string, documentStatus: string, extraData: list, idExpiry: string, idIssued: string, idNumber: string, idSubType: string, idType: string, manuallyModified: bool, region: string>>, requestId: string>"
    update-compare-document: "record<documentComparisonResults: record<compareDocumentId: string, processResult: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, toDocumentId: string>, requestId: string>"
    query-document-full: "record<document: record<country: string, createdFromScan: bool, docScan: list<record>, documentId: string, documentStatus: string, extraData: list<record>, idExpiry: string, idIssued: string, idNumber: string, idSubType: string, idType: string, manuallyModified: bool, region: string>, requestId: string>"
    update-scan-document: "record<extractedDocument: record<country: string, createdFromScan: bool, docScan: list<record>, documentId: string, documentStatus: string, extraData: list<record>, idExpiry: string, idIssued: string, idNumber: string, idSubType: string, idType: string, manuallyModified: bool, region: string>, extractedEntity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, processResult: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, requestId: string>"
    update-process-industry-utility-document: "record<documentId: string, industryProcess: string, requestId: string, utilityCompareResult: record<error: record<comparisonDate: string, correlationId: string, errorCode: int, message: string, version: string>, result: record<comparisonDate: string, correlationId: string, currentBillData: record, defaultOffer: record, marketDisclosure: record, maximumSaving: float, plans: list, version: string>>>"
    update-process-industry-utility-document-consent: "record<documentId: string, industryProcess: string, requestId: string, utilityConsentResult: record<error: record<correlationId: string, errorCode: int, message: string, version: string>, result: record<correlationId: string, eic: list, plan: record, version: string>>>"
    update-process-industry-utility-document-switch: "record<documentId: string, industryProcess: string, requestId: string, utilitySwitchResult: record<error: record<correlationId: string, errorCode: int, message: string, version: string>, result: record<correlationId: string, nextSteps: list, plan: record, reference: string, switchDate: string, version: string>>>"
    update-verify-document: "record<documentVerificationResults: record<documentId: string, processResult: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>>, requestId: string>"
    create-entity: "record<entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string>"
    create-entity-get-idv-token: "record<applicantId: string, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string, supportTwoDocs: bool, token: string>"
    create-check-entity-push-to-mobile: "record<checkId: string, entityId: string, function: string, linkURL: string, requestId: string>"
    create-check-entity: "record<blacklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkResultsListSummaries: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkRisk: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, checkSummary: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, deviceCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, duplicateCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, entityProfileResult: record<actionRecommended: string, addressResults: record, checkId: string, checkResults: list<record>, checkType: string, creditHeaderFailures: list<string>, documentResults: record, entityId: string, issueList: list<string>, kycResults: list<record>, latestCheckDate: string, manualIntervention: bool, policyName: string, profileName: string, resolverRecommended: string, riskLevel: string, riskPolicy: string>, entityResult: record<addressesCheck: list<record>, adverseMediaCheck: list<record>, amlResultSets: list<record>, dateOfBirthCheck: record<checkResult: list, dob: record>, entityId: string, genderCheck: record<checkResult: list, gender: string>, identityDocsCheck: list<record>, nameCheck: record<checkResult: list, name: record>, pepCheck: list<record>, sanctionsCheck: list<record>, watchlistCheck: list<record>>, fraudCheckResults: record<fraudBackgroundCheckResults: list<record>, fraudListResults: list<record>>, manualCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, requestId: string, sharedBlocklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>>"
    search-entity: "record<entitySearchResults: table<confidence: record, documentMatchTypes: list, documentNameMismatches: list, entity: record, entityMatchTypes: list>, requestId: string>"
    delete-entity: "record<requestId: string, statusMsg: string>"
    query-entity: "record<entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string>"
    update-entity: "record<entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string>"
    update-check-class-results: "record<blacklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkResultsListSummaries: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkRisk: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, checkSummary: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, deviceCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, duplicateCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, entityProfileResult: record<actionRecommended: string, addressResults: record, checkId: string, checkResults: list<record>, checkType: string, creditHeaderFailures: list<string>, documentResults: record, entityId: string, issueList: list<string>, kycResults: list<record>, latestCheckDate: string, manualIntervention: bool, policyName: string, profileName: string, resolverRecommended: string, riskLevel: string, riskPolicy: string>, entityResult: record<addressesCheck: list<record>, adverseMediaCheck: list<record>, amlResultSets: list<record>, dateOfBirthCheck: record<checkResult: list, dob: record>, entityId: string, genderCheck: record<checkResult: list, gender: string>, identityDocsCheck: list<record>, nameCheck: record<checkResult: list, name: record>, pepCheck: list<record>, sanctionsCheck: list<record>, watchlistCheck: list<record>>, fraudCheckResults: record<fraudBackgroundCheckResults: list<record>, fraudListResults: list<record>>, manualCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, requestId: string, sharedBlocklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>>"
    update-check-class-result: "record<blacklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkResultsListSummaries: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkRisk: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, checkSummary: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, deviceCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, duplicateCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, entityProfileResult: record<actionRecommended: string, addressResults: record, checkId: string, checkResults: list<record>, checkType: string, creditHeaderFailures: list<string>, documentResults: record, entityId: string, issueList: list<string>, kycResults: list<record>, latestCheckDate: string, manualIntervention: bool, policyName: string, profileName: string, resolverRecommended: string, riskLevel: string, riskPolicy: string>, entityResult: record<addressesCheck: list<record>, adverseMediaCheck: list<record>, amlResultSets: list<record>, dateOfBirthCheck: record<checkResult: list, dob: record>, entityId: string, genderCheck: record<checkResult: list, gender: string>, identityDocsCheck: list<record>, nameCheck: record<checkResult: list, name: record>, pepCheck: list<record>, sanctionsCheck: list<record>, watchlistCheck: list<record>>, fraudCheckResults: record<fraudBackgroundCheckResults: list<record>, fraudListResults: list<record>>, manualCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, requestId: string, sharedBlocklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>>"
    query-entity-checks: "record<blacklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkResultsListSummaries: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkRisk: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, checkSummary: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, deviceCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, duplicateCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, entityProfileResult: record<actionRecommended: string, addressResults: record, checkId: string, checkResults: list<record>, checkType: string, creditHeaderFailures: list<string>, documentResults: record, entityId: string, issueList: list<string>, kycResults: list<record>, latestCheckDate: string, manualIntervention: bool, policyName: string, profileName: string, resolverRecommended: string, riskLevel: string, riskPolicy: string>, entityResult: record<addressesCheck: list<record>, adverseMediaCheck: list<record>, amlResultSets: list<record>, dateOfBirthCheck: record<checkResult: list, dob: record>, entityId: string, genderCheck: record<checkResult: list, gender: string>, identityDocsCheck: list<record>, nameCheck: record<checkResult: list, name: record>, pepCheck: list<record>, sanctionsCheck: list<record>, watchlistCheck: list<record>>, fraudCheckResults: record<fraudBackgroundCheckResults: list<record>, fraudListResults: list<record>>, manualCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, requestId: string, sharedBlocklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>>"
    blacklist-entity: "record<entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string>"
    flag-duplicate-entity: "record<entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string>"
    entity-monitoring: "record<entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string>"
    watchlist-entity: "record<entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string>"
    query-entity-full: "record<entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string>"
    update-entity-get-idv-token: "record<applicantId: string, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string, supportTwoDocs: bool, token: string>"
    update-entity-init-idv-process: "record<applicantId: string, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string, supportTwoDocs: bool, token: string>"
    update-entity-state: "record<blacklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkResultsListSummaries: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkRisk: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, checkSummary: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, deviceCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, duplicateCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, entityProfileResult: record<actionRecommended: string, addressResults: record, checkId: string, checkResults: list<record>, checkType: string, creditHeaderFailures: list<string>, documentResults: record, entityId: string, issueList: list<string>, kycResults: list<record>, latestCheckDate: string, manualIntervention: bool, policyName: string, profileName: string, resolverRecommended: string, riskLevel: string, riskPolicy: string>, entityResult: record<addressesCheck: list<record>, adverseMediaCheck: list<record>, amlResultSets: list<record>, dateOfBirthCheck: record<checkResult: list, dob: record>, entityId: string, genderCheck: record<checkResult: list, gender: string>, identityDocsCheck: list<record>, nameCheck: record<checkResult: list, name: record>, pepCheck: list<record>, sanctionsCheck: list<record>, watchlistCheck: list<record>>, fraudCheckResults: record<fraudBackgroundCheckResults: list<record>, fraudListResults: list<record>>, manualCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, requestId: string, sharedBlocklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>>"
    update-check-entity-push-to-mobile: "record<checkId: string, entityId: string, function: string, linkURL: string, requestId: string>"
    update-check-entity: "record<blacklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkResultsListSummaries: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkRisk: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, checkSummary: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, deviceCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, duplicateCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, entityProfileResult: record<actionRecommended: string, addressResults: record, checkId: string, checkResults: list<record>, checkType: string, creditHeaderFailures: list<string>, documentResults: record, entityId: string, issueList: list<string>, kycResults: list<record>, latestCheckDate: string, manualIntervention: bool, policyName: string, profileName: string, resolverRecommended: string, riskLevel: string, riskPolicy: string>, entityResult: record<addressesCheck: list<record>, adverseMediaCheck: list<record>, amlResultSets: list<record>, dateOfBirthCheck: record<checkResult: list, dob: record>, entityId: string, genderCheck: record<checkResult: list, gender: string>, identityDocsCheck: list<record>, nameCheck: record<checkResult: list, name: record>, pepCheck: list<record>, sanctionsCheck: list<record>, watchlistCheck: list<record>>, fraudCheckResults: record<fraudBackgroundCheckResults: list<record>, fraudListResults: list<record>>, manualCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, requestId: string, sharedBlocklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>>"
    retrieve-result: "record<origHTTPstatus: int, payload: record>"
    status-check: "record<asknicely1: string, asknicely2: string, asknicely3: string, asknicely4: string, asknicely5: string, asknicely6: string, asknicely7: string, commit: string, puppy: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["international-business-profile" "international-business-search" "business-ownership-query" "run-business-reports" "check-organisation" "create-document" "compare-document" "create-scan-document" "create-process-industry-utility-document" "verify-document" "search-document" "delete-document" "query-document" "update-document" "query-document-checks" "update-compare-document" "query-document-full" "update-scan-document" "update-process-industry-utility-document" "update-process-industry-utility-document-consent" "update-process-industry-utility-document-switch" "update-verify-document" "create-entity" "create-entity-get-idv-token" "create-check-entity-push-to-mobile" "create-check-entity" "search-entity" "delete-entity" "query-entity" "update-entity" "update-check-class-results" "update-check-class-result" "query-entity-checks" "blacklist-entity" "flag-duplicate-entity" "entity-monitoring" "watchlist-entity" "query-entity-full" "update-entity-get-idv-token" "update-entity-init-idv-process" "update-entity-state" "update-check-entity-push-to-mobile" "update-check-entity" "retrieve-result" "status-check" "notify-result" "commands"] | sort) } | get name | first)
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

# Retrieve a business profile from any country (AUS included).
#
# POST /business/international/profile
# Returns: record<CompanyProfile: record<Activity: record<ActivityDTO: list>, ActivityDeclaration: record<ActivityDeclarationDTO: list>, Addresses: record<Addresses: list>, AgentAddress: string, AgentName: string, Aliases: record<AddressLine: list>, AppointmentDateOfOfficial: string, Capital: record<CapitalDTO: list>, Code: string, CompanyNameInEnglish: string, Date: string, Email: string, FaxNumber: string, FiscalCode: string, FoundationDate: string, Functions: record<AddressLine: list>, Headquarters: string, KeyFigures: record<AddressLine: list>, LastAnnualAccountDate: string, LegalForm: string, LegalFormDeclaration: string, LegalFormDetails: record<Basis: string, Capital: string, Comments: string, Control: string, Incorp: string, Partner: string, Responsibility: string, Stocks: string>, LegalStatus: string, MailingAddress: string, Name: string, Official: bool, RegistrationAuthority: string, RegistrationAuthorityCode: string, RegistrationDate: string, RegistrationNumber: string, SigningDeclaration: string, SigningDeclarationDescription: string, SigningLanguage: string, Source: string, StateOfIncorporation: string, TelephoneNumber: string, VatNumber: string, VirtualId: string, WebsiteURL: string, directorAndShareDetails: record<PersonsOfSignificantControl: record, capitalReserves: record, directors: record, shareHolderSummary: record, shareHolders: record>, officers: record<USOfficerDTO: list>>, checkId: string, entityId: string, ibResponseCode: int, ibResponseDetails: string, ibRetrievalLocation: string, ibTransactionId: string, requestId: string>
# operationId: InternationalBusinessProfile
export def "international-business-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --company-code: string # This is the company number returned in the search results (InternationalBusinessSearchResponse.Companies.CompanyDTO[n].Code)
  country: string # The ISO 3166-1 alpha2 country code of country registry you wish to search. This is consistent for all countries except for: - The United States which requires the state registry to query as well. - As an example, for a Delaware query, the country code would be "US-DE". - A Texas query would use "US-TX" - Canada, which also requires you to supply a territory code too. - A Yukon query would use CA-YU, Manitoba would use CA-MB - You can do an all jurisdiction search with CA-ALL - United Arab Emirates (UAE) - For Abu Dhabi, use "DI" - For Dubai, use "DU" See details here: https://apidocs.frankiefinancial.com/docs/country-codes-for-international-business-queries
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/business/international/profile"
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: company_code, var: company_code}, {name: country, var: country}]}
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, company_code: $company_code, country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for a business from any country (AUS included).
#
# POST /business/international/search
# Returns: record<Companies: record<CompanyDTO: list<record>>, ibContinuationKey: string, ibResponseCode: int, ibResponseDetails: string, ibTransactionId: string, requestId: string>
# operationId: InternationalBusinessSearch
export def "international-business-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  country: string # The ISO 3166-1 alpha2 country code of country registry you wish to search. This is consistent for all countries except for: - The United States which requires the state registry to query as well. - As an example, for a Delaware query, the country code would be "US-DE". - A Texas query would use "US-TX" - Canada, which also requires you to supply a territory code too. - A Yukon query would use CA-YU, Manitoba would use CA-MB - You can do an all jurisdiction search with CA-ALL - United Arab Emirates (UAE) - For Abu Dhabi, use "DI" - For Dubai, use "DU" See details here: https://apidocs.frankiefinancial.com/docs/country-codes-for-international-business-queries
  --organisation-name: string # Name or name fragment you wish to search for. Note: The less you supply, the more, but less relevant results will be returned. CRITICAL NOTE: This is *NOT* to be used as a progressive search function. You must supply at least one of organisation_name and/or organisation_number. If you supply both, a name search will be conducted first, then the number will be checked against the result set and any remaining results returned.
  --organisation-number: string # The business number you wish to search on. This should be a unique corporate identifier as per the country registry you're searching.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/business/international/search"
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: organisation_name, var: organisation_name}, {name: organisation_number, var: organisation_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, country: $country, organisation_name: $organisation_name, organisation_number: $organisation_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Business Entity and Query UBO (AUS Only)
#
# POST /business/ownership/query
# Returns: record<flags: table<flag: string, value: int>, organisationCheckId: string, organisationCheckResult: record<entityCategories: record, entityCheckErrors: record, entityCheckResults: record, entityId: string, groupId: string>, ownershipCheckDate: string, ownershipCheckId: string, ownershipQueryError: record<commit: string, errorCode: string, errorMsg: string, httpStatusCode: int, issues: list<record>, requestId: string>, ownershipQueryResult: record<associatedEntities: record, blockingEntityIds: list<string>, entityId: string, ownershipDetails: record>, reportError: record<commit: string, errorCode: string, errorMsg: string, httpStatusCode: int, issues: list<record>, requestId: string>, reportResult: record<documentId: string, location: string, scanDocId: string>, requestId: string, uboResponse: record<asic_search_timestamp: string, business_details: record<ABN: string, ACN: string, ARBN: string, anzsic_code: string, asic_company_type: string, business_names: list, date_registered_with_asic: string, entity_id: string, giin: string, place_of_business: record, public_company: bool, registered_name: string, registered_office: record, regulatory_information: record, state_registered_with_asic: string, stock_exchange_data: record, trading_names: list>, business_screening_result: record<aml_result: record, kyc_result: record>, error_message: string, issues_list: list<record>, non_individual_beneficial_owners: list<record>, officeholders: list<record>, supplied_data: record<abn: string, acn: string, company_type: string, customer_reference: string, name: string>, supplied_data_matches: record<matched_acn: bool, matched_company_type: bool, matched_name: bool>, ubo_report: string, ultimate_beneficial_owners: list<record>>>
# operationId: BusinessOwnershipQuery
export def "business-ownership-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --check-type: list<string> # When creating a new check, we need to define the checks we wish to run. If this parameter is not supplied then the check will be based on a configured check type for each entity category. The checkType is make up of a comma separated list of the types of check we wish to run. The order is important, and must be of the form: - Entity Check (if you're running this). Choose one from the available options - ID Check (If you want this) - PEP Checks (again if you want this, choose one of the options) Entity Checks - One of: - "one_plus": Checks name, address and DoB against a minimum of 1 data source. (also known as a 1+1) - "two_plus": Checks name, address and DoB against a minimum of 2 independent data sources (also known as a 2+2) ID Checks - One of: - "id": Checks all of the identity documents, but not necessarily the entity itself independently. Use this in conjunction with a one_plus or two_plus for more. Fraud Checks - One or more of: - "fraudlist": Checks to see if the identity appears on any known fraud lists. Should be run after KYC/ID checks have passed. - "fraudid": Checks external ID services to see if details appear in fraud detection services (e.g. EmailAge or FraudNet) PEP Checks - One of: - "pep": Will only run PEP/Sanctions checks (no identity verification) - "pep_media": Will run PEP/Sanctions checks, as well as watchlist and adverse media checks. (no identity verification) * NOTE: These checks will ONLY run if either the KYC/ID checks have been run prior, or it is the only check requested. Pre-defined combinations: - "full": equivalent to "two_plus,id,pep_media" or "pep_media" if the target is an organisation. - "default": Currently defined as "two_plus,id" or "pep" if the target is an organisation. Custom: - By arrangement with Frankie you can define your own KYC check type. This will allow you to set the minimum number of matches for: - name - date of birth - address - government id This allows for alternatives to the "standard" two_plus or one_plus (note, these can be overridden too). Profile: - "profile": By arrangement with Frankie you can have a "profile" check type that applies checks according to a profile that you assign to the entity from a predefined set of profiles. The profile to use will be taken from the entity.entityProfile field if set, or be run through a set of configurable rules to determine which one to use. Profiles act a little like the Pre-defined combinations above in that they can map to a defined list. But they offer a lot more besides, including rules for determining default settings, inbuild data aging and other configurable features. They also allow for a new result set top be returned that provides a more detailed and useful breakdown of the check/verification process. Entity Profiles are the future of checks with Frankie Financial.
  --entity-categories: list<string> # A comma separated list that specifies the categories of entities associated with the target organisation that will be checked. - organisation - Just the organisation itself. - ubos - All ultimate beneficial owners. - pseudo_ubos - Use an alterntive category when an organisation has no actual UBOs. The actual category to use is defined via configuration, default is no alterntive category. - direct_owners - All direct owners of the company, both organisations and individuals, may include UBOs for for simple ownership. - officers - All officers of the company - officers_directors - All directors of the company - officers_other - All non-director officers of the company - all - All direct and indirect owners, both organisations and individuals (including UBOs), and officers of all organisations.
  --result-level: string@result-level-completer # The result level allows you to specify the level of detail returned for the entity check. You can choose summary or full. (default: summary)
  --validation: string@validation-completer # Should a validation check be run before the ownership query. The default is specified via configuration. The validation checks to see if the provided organisation is suitable for an ownership query by looking for the ACN in public data sources. Options are: - "on": Validate only when ACN is not provided. This is the typical default. - "acn": Validate even if ACN is provided. - "only": Like "acn" but only do validation query, don't proceed with ownership query. This option cannot be set as the default via configuration. - "off": Never validate. The Ownership query will then fail if an ACN is not provided.
  --generate-report: string # The type of human readable report, if any, to generate based on the ownership query results.
  --include-historical: oneof<nothing, bool> # If set to true, historical ownership data will be requested.
  --only-profile: oneof<nothing, bool> # If set to true, a full UBO report will not be requested.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  organisation: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/business/ownership/query"
    query: [{name: checkType, var: check_type, style: csv}, {name: entityCategories, var: entity_categories, style: csv}, {name: resultLevel, var: result_level}, {name: validation, var: validation}, {name: generateReport, var: generate_report}, {name: includeHistorical, var: include_historical}, {name: onlyProfile, var: only_profile}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: organisation, var: organisation}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    check_type: $check_type, entity_categories: $entity_categories, result_level: $result_level, validation: $validation, generate_report: $generate_report, include_historical: $include_historical, only_profile: $only_profile, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, organisation: $organisation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run Report(s) against a new or existing organisation entity (AUS Only).
#
# POST /business/reports
# Returns: record<checkId: string, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, reports: table<details: record, report: record>, requestId: string>
# operationId: RunBusinessReports
export def "run-business-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-types: string # Define the report(s) you wish to run. You can request more than one as a comma separated list. Duplicates will be ignored. Note: These reports are different to the business details and UBO queries and are meant to provide deeper detail and background on a business or organisation. Current valid report types are: - creditScore - creditReport (required)
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --addresses: list # Collection of address objects. — item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
  --date-of-birth: record # shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
  --entity-id: string # When an entity is first created, it is assigned an ID. When updating an entity, make sure you set the entityId One exception to this is when an entity is created from a document object. It is expected that this object would be passed into a /check or /entity call to set it. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --entity-profile: string # If the entity is using the new profiles feature, then their profile name will be found here. Note: If setting a profile, you must ensure that the profile matches a known configuration. Please contact Frankie developer support if you're unsure as to what valid values are.
  --entity-type: string@entity-type-completer # Indicates the type of an entity. - "INDIVIDUAL": An individual. - "TRUST": A trust. - "ORGANISATION": An organisation.
  --extra-data: list # Set of key-value pairs that provide arbitrary additional type-specific data. You can use these fields to store external IDs, or other non-identity related items if you need to. If updating an existing entity, then existing values with the same name will be overwritten. New values will be added. See here for more information about possible values you can use: https://apidocs.frankiefinancial.com/docs/entity-extradata-key-value-pairs — item shape: {kvpKey?: string, ... (2 more fields)}
  --flags: list # Used to set additional information flags with regards to this entity and for ongoing processing. Flags might include having the entity (not) participate in regular pep/sanctions screening Others will follow over time. — item shape: {flag?: string, value?: int}
  --gender: string@gender-completer # Used to indicate of the entity in question is: - "M"ale - "F"emale - "U"nspecified - "O"ther (for want of a better option) (e.g. F)
  --identity-docs: list # Collection of identity documents (photos, scans, selfies, etc) — item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
  --name: record # shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
  --organisation-data: record # Organisation details for entities. Returned from an ASIC report. — shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/business/reports"
    query: [{name: reportTypes, var: report_types, required: true}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: dateOfBirth, var: date_of_birth}, {name: entityId, var: entity_id}, {name: entityProfile, var: entity_profile}, {name: entityType, var: entity_type}, {name: extraData, var: extra_data}, {name: flags, var: flags}, {name: gender, var: gender}, {name: identityDocs, var: identity_docs}, {name: name, var: name}, {name: organisationData, var: organisation_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    report_types: $report_types, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, addresses: $addresses, date_of_birth: $date_of_birth, entity_id: $entity_id, entity_profile: $entity_profile, entity_type: $entity_type, extra_data: $extra_data, flags: $flags, gender: $gender, identity_docs: $identity_docs, name: $name, organisation_data: $organisation_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run KYC/AML Checks on Organisation and/or Associated Individuals.
#
# POST /business/{entityId}/verify
# Returns: record<checkId: string, entityId: string, function: string, linkURL: string, requestId: string>
# operationId: CheckOrganisation
export def "check-organisation" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --check-type: list<string> # When creating a new check, we need to define the checks we wish to run. If this parameter is not supplied then the check will be based on a configured check type for each entity category. The checkType is make up of a comma separated list of the types of check we wish to run. The order is important, and must be of the form: - Entity Check (if you're running this). Choose one from the available options - ID Check (If you want this) - PEP Checks (again if you want this, choose one of the options) Entity Checks - One of: - "one_plus": Checks name, address and DoB against a minimum of 1 data source. (also known as a 1+1) - "two_plus": Checks name, address and DoB against a minimum of 2 independent data sources (also known as a 2+2) ID Checks - One of: - "id": Checks all of the identity documents, but not necessarily the entity itself independently. Use this in conjunction with a one_plus or two_plus for more. Fraud Checks - One or more of: - "fraudlist": Checks to see if the identity appears on any known fraud lists. Should be run after KYC/ID checks have passed. - "fraudid": Checks external ID services to see if details appear in fraud detection services (e.g. EmailAge or FraudNet) PEP Checks - One of: - "pep": Will only run PEP/Sanctions checks (no identity verification) - "pep_media": Will run PEP/Sanctions checks, as well as watchlist and adverse media checks. (no identity verification) * NOTE: These checks will ONLY run if either the KYC/ID checks have been run prior, or it is the only check requested. Pre-defined combinations: - "full": equivalent to "two_plus,id,pep_media" or "pep_media" if the target is an organisation. - "default": Currently defined as "two_plus,id" or "pep" if the target is an organisation. Custom: - By arrangement with Frankie you can define your own KYC check type. This will allow you to set the minimum number of matches for: - name - date of birth - address - government id This allows for alternatives to the "standard" two_plus or one_plus (note, these can be overridden too). Profile: - "profile": By arrangement with Frankie you can have a "profile" check type that applies checks according to a profile that you assign to the entity from a predefined set of profiles. The profile to use will be taken from the entity.entityProfile field if set, or be run through a set of configurable rules to determine which one to use. Profiles act a little like the Pre-defined combinations above in that they can map to a defined list. But they offer a lot more besides, including rules for determining default settings, inbuild data aging and other configurable features. They also allow for a new result set top be returned that provides a more detailed and useful breakdown of the check/verification process. Entity Profiles are the future of checks with Frankie Financial.
  --entity-categories: list<string> # A comma separated list that specifies the categories of entities associated with the target organisation that will be checked. - organisation - Just the organisation itself. - ubos - All ultimate beneficial owners. - pseudo_ubos - Use an alterntive category when an organisation has no actual UBOs. The actual category to use is defined via configuration, default is no alterntive category. - direct_owners - All direct owners of the company, both organisations and individuals, may include UBOs for for simple ownership. - officers - All officers of the company - officers_directors - All directors of the company - officers_other - All non-director officers of the company - all - All direct and indirect owners, both organisations and individuals (including UBOs), and officers of all organisations.
  --result-level: string@result-level-completer # The result level allows you to specify the level of detail returned for the entity check. You can choose summary or full. (default: summary)
  --generate-report: string # The type of human readable report, if any, to generate based on the ownership query results.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/business/{entityId}/verify"
    path_params: [{name: entityId, var: entity_id}]
    query: [{name: checkType, var: check_type, style: csv}, {name: entityCategories, var: entity_categories, style: csv}, {name: resultLevel, var: result_level}, {name: generateReport, var: generate_report}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    accept: ["application/json"]
    ok: [202]
    auth: api_key
  } {
    entity_id: $entity_id, check_type: $check_type, entity_categories: $entity_categories, result_level: $result_level, generate_report: $generate_report, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create New Document.
#
# POST /document
# Returns: record<document: record<country: string, createdFromScan: bool, docScan: list<record>, documentId: string, documentStatus: string, extraData: list<record>, idExpiry: string, idIssued: string, idNumber: string, idSubType: string, idType: string, manuallyModified: bool, region: string>, requestId: string>
# operationId: CreateDocument
export def "create-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed. See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more (e.g. AUS)
  --doc-scan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls. Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
  --document-id: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --document-status: string@document-status-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned. - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error. (e.g. DOC_SCANNED)
  --extra-data: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added. If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, ... (2 more fields)}
  --id-expiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --id-issued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --id-number: string # The ID number of the document (if known). (e.g. 123456789)
  --id-sub-type: string # The sub-type of identity document. Very document specific.
  id_type: string@id-type-completer # Valid ID types - "OTHER": Generic document type. Unspecified. - "DRIVERS_LICENCE": Driver's licence. - "PASSPORT": Passport - "VISA": Visa document (not Visa payment card) - "IMMIGRATION": Immigration card - "NATIONAL_ID": Any national ID card - "TAX_ID": Any national tax identifier - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS) - "CONCESSION": State issued concession card - "HEALTH_CONCESSION": State issued health specific concession card - "PENSION": State issued pension ID - "MILITARY_ID": Military ID - "BIRTH_CERT": Birth certificate - "CITIZENSHIP": Citizenship certificate - "MARRIAGE_CERT": Marriage certificate - "DEATH_CERT": Death certificate - "NAME_CHANGE": Name chage confirmation - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc - "BANK_STATEMENT": Bank/card statement - "BANK_ACCOUNT": Bank account - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter - "ATTESTATION": A document of attestation (e.g. Statutory Declaration) - "SELF_IMAGE": A "selfie" used for comparisions - "EMAIL_ADDRESS": An email address - "MSISDN": A mobile phone number - "DEVICE": A device ID - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation - "EXTERNAL_ADMIN": Details of appointed administrator. - "CHARGES": Details of any charges that have been laid against a company or director - "PRE_ASIC": Any documents that are Pre-ASIC - "ANNUAL_RETURN": Details of a company's annual return - "REPORT": Frankie generated report. Special document types - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie. (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence) You should always use the local abbreviation for this. E.g. - VIC for The Australian state of Victoria - MA for the US state of Massachusetts - etc (e.g. VIC)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/document"
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: docScan, var: doc_scan}, {name: documentId, var: document_id}, {name: documentStatus, var: document_status}, {name: extraData, var: extra_data}, {name: idExpiry, var: id_expiry}, {name: idIssued, var: id_issued}, {name: idNumber, var: id_number}, {name: idSubType, var: id_sub_type}, {name: idType, var: id_type}, {name: region, var: region}]}
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, country: $country, doc_scan: $doc_scan, document_id: $document_id, document_status: $document_status, extra_data: $extra_data, id_expiry: $id_expiry, id_issued: $id_issued, id_number: $id_number, id_sub_type: $id_sub_type, id_type: $id_type, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Document and Compare to Original.
#
# POST /document/new/compare
# Returns: record<documentComparisonResults: record<compareDocumentId: string, processResult: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, toDocumentId: string>, requestId: string>
# operationId: CompareDocument
export def "compare-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --compare-document: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
  --to-document: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/document/new/compare"
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    body: {content_type: "application/json", kind: json, fields: [{name: compareDocument, var: compare_document}, {name: toDocument, var: to_document}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background, compare_document: $compare_document, to_document: $to_document
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create and OCR Scan Document.
#
# POST /document/new/scan
# Returns: record<extractedDocument: record<country: string, createdFromScan: bool, docScan: list<record>, documentId: string, documentStatus: string, extraData: list<record>, idExpiry: string, idIssued: string, idNumber: string, idSubType: string, idType: string, manuallyModified: bool, region: string>, extractedEntity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, processResult: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, requestId: string>
# operationId: CreateScanDocument
export def "create-scan-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed. See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more (e.g. AUS)
  --doc-scan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls. Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
  --document-id: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --document-status: string@document-status-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned. - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error. (e.g. DOC_SCANNED)
  --extra-data: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added. If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, ... (2 more fields)}
  --id-expiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --id-issued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --id-number: string # The ID number of the document (if known). (e.g. 123456789)
  --id-sub-type: string # The sub-type of identity document. Very document specific.
  id_type: string@id-type-completer # Valid ID types - "OTHER": Generic document type. Unspecified. - "DRIVERS_LICENCE": Driver's licence. - "PASSPORT": Passport - "VISA": Visa document (not Visa payment card) - "IMMIGRATION": Immigration card - "NATIONAL_ID": Any national ID card - "TAX_ID": Any national tax identifier - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS) - "CONCESSION": State issued concession card - "HEALTH_CONCESSION": State issued health specific concession card - "PENSION": State issued pension ID - "MILITARY_ID": Military ID - "BIRTH_CERT": Birth certificate - "CITIZENSHIP": Citizenship certificate - "MARRIAGE_CERT": Marriage certificate - "DEATH_CERT": Death certificate - "NAME_CHANGE": Name chage confirmation - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc - "BANK_STATEMENT": Bank/card statement - "BANK_ACCOUNT": Bank account - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter - "ATTESTATION": A document of attestation (e.g. Statutory Declaration) - "SELF_IMAGE": A "selfie" used for comparisions - "EMAIL_ADDRESS": An email address - "MSISDN": A mobile phone number - "DEVICE": A device ID - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation - "EXTERNAL_ADMIN": Details of appointed administrator. - "CHARGES": Details of any charges that have been laid against a company or director - "PRE_ASIC": Any documents that are Pre-ASIC - "ANNUAL_RETURN": Details of a company's annual return - "REPORT": Frankie generated report. Special document types - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie. (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence) You should always use the local abbreviation for this. E.g. - VIC for The Australian state of Victoria - MA for the US state of Massachusetts - etc (e.g. VIC)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/document/new/scan"
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: docScan, var: doc_scan}, {name: documentId, var: document_id}, {name: documentStatus, var: document_status}, {name: extraData, var: extra_data}, {name: idExpiry, var: id_expiry}, {name: idIssued, var: id_issued}, {name: idNumber, var: id_number}, {name: idSubType, var: id_sub_type}, {name: idType, var: id_type}, {name: region, var: region}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background, country: $country, doc_scan: $doc_scan, document_id: $document_id, document_status: $document_status, extra_data: $extra_data, id_expiry: $id_expiry, id_issued: $id_issued, id_number: $id_number, id_sub_type: $id_sub_type, id_type: $id_type, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Document and Run Utility Price Comparison.
#
# POST /document/new/utility/process/compare
# Returns: record<documentId: string, industryProcess: string, requestId: string, utilityCompareResult: record<error: record<comparisonDate: string, correlationId: string, errorCode: int, message: string, version: string>, result: record<comparisonDate: string, correlationId: string, currentBillData: record, defaultOffer: record, marketDisclosure: record, maximumSaving: float, plans: list, version: string>>>
# operationId: CreateProcessIndustryUtilityDocument
export def "create-process-industry-utility-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --plan-limit: int # The maximum number of plans to return (default: 30)
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed. See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more (e.g. AUS)
  --doc-scan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls. Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
  --document-id: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --document-status: string@document-status-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned. - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error. (e.g. DOC_SCANNED)
  --extra-data: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added. If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, ... (2 more fields)}
  --id-expiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --id-issued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --id-number: string # The ID number of the document (if known). (e.g. 123456789)
  --id-sub-type: string # The sub-type of identity document. Very document specific.
  id_type: string@id-type-completer # Valid ID types - "OTHER": Generic document type. Unspecified. - "DRIVERS_LICENCE": Driver's licence. - "PASSPORT": Passport - "VISA": Visa document (not Visa payment card) - "IMMIGRATION": Immigration card - "NATIONAL_ID": Any national ID card - "TAX_ID": Any national tax identifier - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS) - "CONCESSION": State issued concession card - "HEALTH_CONCESSION": State issued health specific concession card - "PENSION": State issued pension ID - "MILITARY_ID": Military ID - "BIRTH_CERT": Birth certificate - "CITIZENSHIP": Citizenship certificate - "MARRIAGE_CERT": Marriage certificate - "DEATH_CERT": Death certificate - "NAME_CHANGE": Name chage confirmation - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc - "BANK_STATEMENT": Bank/card statement - "BANK_ACCOUNT": Bank account - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter - "ATTESTATION": A document of attestation (e.g. Statutory Declaration) - "SELF_IMAGE": A "selfie" used for comparisions - "EMAIL_ADDRESS": An email address - "MSISDN": A mobile phone number - "DEVICE": A device ID - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation - "EXTERNAL_ADMIN": Details of appointed administrator. - "CHARGES": Details of any charges that have been laid against a company or director - "PRE_ASIC": Any documents that are Pre-ASIC - "ANNUAL_RETURN": Details of a company's annual return - "REPORT": Frankie generated report. Special document types - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie. (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence) You should always use the local abbreviation for this. E.g. - VIC for The Australian state of Victoria - MA for the US state of Massachusetts - etc (e.g. VIC)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/document/new/utility/process/compare"
    query: [{name: planLimit, var: plan_limit}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: docScan, var: doc_scan}, {name: documentId, var: document_id}, {name: documentStatus, var: document_status}, {name: extraData, var: extra_data}, {name: idExpiry, var: id_expiry}, {name: idIssued, var: id_issued}, {name: idNumber, var: id_number}, {name: idSubType, var: id_sub_type}, {name: idType, var: id_type}, {name: region, var: region}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    plan_limit: $plan_limit, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background, country: $country, doc_scan: $doc_scan, document_id: $document_id, document_status: $document_status, extra_data: $extra_data, id_expiry: $id_expiry, id_issued: $id_issued, id_number: $id_number, id_sub_type: $id_sub_type, id_type: $id_type, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create and Verify Document.
#
# POST /document/new/verify
# Returns: record<documentVerificationResults: record<documentId: string, processResult: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>>, requestId: string>
# operationId: VerifyDocument
export def "verify-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --document: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
  --entity-data: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/document/new/verify"
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    body: {content_type: "application/json", kind: json, fields: [{name: document, var: document}, {name: entityData, var: entity_data}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background, document: $document, entity_data: $entity_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search For a Document !! EXPERIMENTAL !!
#
# POST /document/search
# Returns: record<documentSearchResults: table<confidence: record, document: record>, requestId: string>
# operationId: SearchDocument
export def "search-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed. See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more (e.g. AUS)
  --doc-scan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls. Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
  --document-id: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --document-status: string@document-status-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned. - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error. (e.g. DOC_SCANNED)
  --extra-data: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added. If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, ... (2 more fields)}
  --id-expiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --id-issued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --id-number: string # The ID number of the document (if known). (e.g. 123456789)
  --id-sub-type: string # The sub-type of identity document. Very document specific.
  id_type: string@id-type-completer # Valid ID types - "OTHER": Generic document type. Unspecified. - "DRIVERS_LICENCE": Driver's licence. - "PASSPORT": Passport - "VISA": Visa document (not Visa payment card) - "IMMIGRATION": Immigration card - "NATIONAL_ID": Any national ID card - "TAX_ID": Any national tax identifier - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS) - "CONCESSION": State issued concession card - "HEALTH_CONCESSION": State issued health specific concession card - "PENSION": State issued pension ID - "MILITARY_ID": Military ID - "BIRTH_CERT": Birth certificate - "CITIZENSHIP": Citizenship certificate - "MARRIAGE_CERT": Marriage certificate - "DEATH_CERT": Death certificate - "NAME_CHANGE": Name chage confirmation - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc - "BANK_STATEMENT": Bank/card statement - "BANK_ACCOUNT": Bank account - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter - "ATTESTATION": A document of attestation (e.g. Statutory Declaration) - "SELF_IMAGE": A "selfie" used for comparisions - "EMAIL_ADDRESS": An email address - "MSISDN": A mobile phone number - "DEVICE": A device ID - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation - "EXTERNAL_ADMIN": Details of appointed administrator. - "CHARGES": Details of any charges that have been laid against a company or director - "PRE_ASIC": Any documents that are Pre-ASIC - "ANNUAL_RETURN": Details of a company's annual return - "REPORT": Frankie generated report. Special document types - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie. (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence) You should always use the local abbreviation for this. E.g. - VIC for The Australian state of Victoria - MA for the US state of Massachusetts - etc (e.g. VIC)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/document/search"
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: docScan, var: doc_scan}, {name: documentId, var: document_id}, {name: documentStatus, var: document_status}, {name: extraData, var: extra_data}, {name: idExpiry, var: id_expiry}, {name: idIssued, var: id_issued}, {name: idNumber, var: id_number}, {name: idSubType, var: id_sub_type}, {name: idType, var: id_type}, {name: region, var: region}]}
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, country: $country, doc_scan: $doc_scan, document_id: $document_id, document_status: $document_status, extra_data: $extra_data, id_expiry: $id_expiry, id_issued: $id_issued, id_number: $id_number, id_sub_type: $id_sub_type, id_type: $id_type, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Document.
#
# DELETE /document/{documentId}
# Returns: record<requestId: string, statusMsg: string>
# operationId: DeleteDocument
export def "delete-document" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/document/{documentId}"
    path_params: [{name: documentId, var: document_id}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    document_id: $document_id, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Document Details
#
# GET /document/{documentId}
# Returns: record<document: record<country: string, createdFromScan: bool, docScan: list<record>, documentId: string, documentStatus: string, extraData: list<record>, idExpiry: string, idIssued: string, idNumber: string, idSubType: string, idType: string, manuallyModified: bool, region: string>, requestId: string>
# operationId: QueryDocument
export def "query-document" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/document/{documentId}"
    path_params: [{name: documentId, var: document_id}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    document_id: $document_id, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Existing Document.
#
# POST /document/{documentId}
# Returns: record<document: record<country: string, createdFromScan: bool, docScan: list<record>, documentId: string, documentStatus: string, extraData: list<record>, idExpiry: string, idIssued: string, idNumber: string, idSubType: string, idType: string, manuallyModified: bool, region: string>, requestId: string>
# operationId: UpdateDocument
export def "update-document" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --no-invalidate: oneof<nothing, bool> # Disable check result invalidation for this update request.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed. See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more (e.g. AUS)
  --doc-scan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls. Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
  --body-document-id: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051) (spec name: documentId)
  --document-status: string@document-status-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned. - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error. (e.g. DOC_SCANNED)
  --extra-data: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added. If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, ... (2 more fields)}
  --id-expiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --id-issued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --id-number: string # The ID number of the document (if known). (e.g. 123456789)
  --id-sub-type: string # The sub-type of identity document. Very document specific.
  id_type: string@id-type-completer # Valid ID types - "OTHER": Generic document type. Unspecified. - "DRIVERS_LICENCE": Driver's licence. - "PASSPORT": Passport - "VISA": Visa document (not Visa payment card) - "IMMIGRATION": Immigration card - "NATIONAL_ID": Any national ID card - "TAX_ID": Any national tax identifier - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS) - "CONCESSION": State issued concession card - "HEALTH_CONCESSION": State issued health specific concession card - "PENSION": State issued pension ID - "MILITARY_ID": Military ID - "BIRTH_CERT": Birth certificate - "CITIZENSHIP": Citizenship certificate - "MARRIAGE_CERT": Marriage certificate - "DEATH_CERT": Death certificate - "NAME_CHANGE": Name chage confirmation - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc - "BANK_STATEMENT": Bank/card statement - "BANK_ACCOUNT": Bank account - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter - "ATTESTATION": A document of attestation (e.g. Statutory Declaration) - "SELF_IMAGE": A "selfie" used for comparisions - "EMAIL_ADDRESS": An email address - "MSISDN": A mobile phone number - "DEVICE": A device ID - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation - "EXTERNAL_ADMIN": Details of appointed administrator. - "CHARGES": Details of any charges that have been laid against a company or director - "PRE_ASIC": Any documents that are Pre-ASIC - "ANNUAL_RETURN": Details of a company's annual return - "REPORT": Frankie generated report. Special document types - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie. (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence) You should always use the local abbreviation for this. E.g. - VIC for The Australian state of Victoria - MA for the US state of Massachusetts - etc (e.g. VIC)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/document/{documentId}"
    path_params: [{name: documentId, var: document_id}]
    query: [{name: noInvalidate, var: no_invalidate}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: docScan, var: doc_scan}, {name: documentId, var: body_document_id}, {name: documentStatus, var: document_status}, {name: extraData, var: extra_data}, {name: idExpiry, var: id_expiry}, {name: idIssued, var: id_issued}, {name: idNumber, var: id_number}, {name: idSubType, var: id_sub_type}, {name: idType, var: id_type}, {name: region, var: region}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    document_id: $document_id, no_invalidate: $no_invalidate, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background, country: $country, doc_scan: $doc_scan, body_document_id: $body_document_id, document_status: $document_status, extra_data: $extra_data, id_expiry: $id_expiry, id_issued: $id_issued, id_number: $id_number, id_sub_type: $id_sub_type, id_type: $id_type, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Document Verification Check Details.
#
# GET /document/{documentId}/checks
# Returns: record<checkResults: record<checkResult: list<record>, idDocument: record<country: string, createdFromScan: bool, docScan: list, documentId: string, documentStatus: string, extraData: list, idExpiry: string, idIssued: string, idNumber: string, idSubType: string, idType: string, manuallyModified: bool, region: string>>, requestId: string>
# operationId: QueryDocumentChecks
export def "query-document-checks" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/document/{documentId}/checks"
    path_params: [{name: documentId, var: document_id}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    document_id: $document_id, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Document and Compare to Original.
#
# POST /document/{documentId}/compare
# Returns: record<documentComparisonResults: record<compareDocumentId: string, processResult: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, toDocumentId: string>, requestId: string>
# operationId: UpdateCompareDocument
export def "update-compare-document" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --compare-document: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
  --to-document: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/document/{documentId}/compare"
    path_params: [{name: documentId, var: document_id}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    body: {content_type: "application/json", kind: json, fields: [{name: compareDocument, var: compare_document}, {name: toDocument, var: to_document}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    document_id: $document_id, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background, compare_document: $compare_document, to_document: $to_document
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Document and Scan Data
#
# GET /document/{documentId}/full
# Returns: record<document: record<country: string, createdFromScan: bool, docScan: list<record>, documentId: string, documentStatus: string, extraData: list<record>, idExpiry: string, idIssued: string, idNumber: string, idSubType: string, idType: string, manuallyModified: bool, region: string>, requestId: string>
# operationId: QueryDocumentFull
export def "query-document-full" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/document/{documentId}/full"
    path_params: [{name: documentId, var: document_id}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    document_id: $document_id, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update and OCR Scan Document
#
# POST /document/{documentId}/scan
# Returns: record<extractedDocument: record<country: string, createdFromScan: bool, docScan: list<record>, documentId: string, documentStatus: string, extraData: list<record>, idExpiry: string, idIssued: string, idNumber: string, idSubType: string, idType: string, manuallyModified: bool, region: string>, extractedEntity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, processResult: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, requestId: string>
# operationId: UpdateScanDocument
export def "update-scan-document" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed. See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more (e.g. AUS)
  --doc-scan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls. Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
  --body-document-id: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051) (spec name: documentId)
  --document-status: string@document-status-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned. - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error. (e.g. DOC_SCANNED)
  --extra-data: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added. If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, ... (2 more fields)}
  --id-expiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --id-issued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --id-number: string # The ID number of the document (if known). (e.g. 123456789)
  --id-sub-type: string # The sub-type of identity document. Very document specific.
  id_type: string@id-type-completer # Valid ID types - "OTHER": Generic document type. Unspecified. - "DRIVERS_LICENCE": Driver's licence. - "PASSPORT": Passport - "VISA": Visa document (not Visa payment card) - "IMMIGRATION": Immigration card - "NATIONAL_ID": Any national ID card - "TAX_ID": Any national tax identifier - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS) - "CONCESSION": State issued concession card - "HEALTH_CONCESSION": State issued health specific concession card - "PENSION": State issued pension ID - "MILITARY_ID": Military ID - "BIRTH_CERT": Birth certificate - "CITIZENSHIP": Citizenship certificate - "MARRIAGE_CERT": Marriage certificate - "DEATH_CERT": Death certificate - "NAME_CHANGE": Name chage confirmation - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc - "BANK_STATEMENT": Bank/card statement - "BANK_ACCOUNT": Bank account - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter - "ATTESTATION": A document of attestation (e.g. Statutory Declaration) - "SELF_IMAGE": A "selfie" used for comparisions - "EMAIL_ADDRESS": An email address - "MSISDN": A mobile phone number - "DEVICE": A device ID - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation - "EXTERNAL_ADMIN": Details of appointed administrator. - "CHARGES": Details of any charges that have been laid against a company or director - "PRE_ASIC": Any documents that are Pre-ASIC - "ANNUAL_RETURN": Details of a company's annual return - "REPORT": Frankie generated report. Special document types - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie. (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence) You should always use the local abbreviation for this. E.g. - VIC for The Australian state of Victoria - MA for the US state of Massachusetts - etc (e.g. VIC)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/document/{documentId}/scan"
    path_params: [{name: documentId, var: document_id}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: docScan, var: doc_scan}, {name: documentId, var: body_document_id}, {name: documentStatus, var: document_status}, {name: extraData, var: extra_data}, {name: idExpiry, var: id_expiry}, {name: idIssued, var: id_issued}, {name: idNumber, var: id_number}, {name: idSubType, var: id_sub_type}, {name: idType, var: id_type}, {name: region, var: region}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    document_id: $document_id, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background, country: $country, doc_scan: $doc_scan, body_document_id: $body_document_id, document_status: $document_status, extra_data: $extra_data, id_expiry: $id_expiry, id_issued: $id_issued, id_number: $id_number, id_sub_type: $id_sub_type, id_type: $id_type, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Document and Run Utility Price Comparison.
#
# POST /document/{documentId}/utility/process/compare
# Returns: record<documentId: string, industryProcess: string, requestId: string, utilityCompareResult: record<error: record<comparisonDate: string, correlationId: string, errorCode: int, message: string, version: string>, result: record<comparisonDate: string, correlationId: string, currentBillData: record, defaultOffer: record, marketDisclosure: record, maximumSaving: float, plans: list, version: string>>>
# operationId: UpdateProcessIndustryUtilityDocument
export def "update-process-industry-utility-document" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --plan-limit: int # The maximum number of plans to return (default: 30)
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed. See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more (e.g. AUS)
  --doc-scan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls. Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
  --body-document-id: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051) (spec name: documentId)
  --document-status: string@document-status-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned. - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error. (e.g. DOC_SCANNED)
  --extra-data: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added. If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, ... (2 more fields)}
  --id-expiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --id-issued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --id-number: string # The ID number of the document (if known). (e.g. 123456789)
  --id-sub-type: string # The sub-type of identity document. Very document specific.
  id_type: string@id-type-completer # Valid ID types - "OTHER": Generic document type. Unspecified. - "DRIVERS_LICENCE": Driver's licence. - "PASSPORT": Passport - "VISA": Visa document (not Visa payment card) - "IMMIGRATION": Immigration card - "NATIONAL_ID": Any national ID card - "TAX_ID": Any national tax identifier - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS) - "CONCESSION": State issued concession card - "HEALTH_CONCESSION": State issued health specific concession card - "PENSION": State issued pension ID - "MILITARY_ID": Military ID - "BIRTH_CERT": Birth certificate - "CITIZENSHIP": Citizenship certificate - "MARRIAGE_CERT": Marriage certificate - "DEATH_CERT": Death certificate - "NAME_CHANGE": Name chage confirmation - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc - "BANK_STATEMENT": Bank/card statement - "BANK_ACCOUNT": Bank account - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter - "ATTESTATION": A document of attestation (e.g. Statutory Declaration) - "SELF_IMAGE": A "selfie" used for comparisions - "EMAIL_ADDRESS": An email address - "MSISDN": A mobile phone number - "DEVICE": A device ID - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation - "EXTERNAL_ADMIN": Details of appointed administrator. - "CHARGES": Details of any charges that have been laid against a company or director - "PRE_ASIC": Any documents that are Pre-ASIC - "ANNUAL_RETURN": Details of a company's annual return - "REPORT": Frankie generated report. Special document types - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie. (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence) You should always use the local abbreviation for this. E.g. - VIC for The Australian state of Victoria - MA for the US state of Massachusetts - etc (e.g. VIC)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/document/{documentId}/utility/process/compare"
    path_params: [{name: documentId, var: document_id}]
    query: [{name: planLimit, var: plan_limit}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: docScan, var: doc_scan}, {name: documentId, var: body_document_id}, {name: documentStatus, var: document_status}, {name: extraData, var: extra_data}, {name: idExpiry, var: id_expiry}, {name: idIssued, var: id_issued}, {name: idNumber, var: id_number}, {name: idSubType, var: id_sub_type}, {name: idType, var: id_type}, {name: region, var: region}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    document_id: $document_id, plan_limit: $plan_limit, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background, country: $country, doc_scan: $doc_scan, body_document_id: $body_document_id, document_status: $document_status, extra_data: $extra_data, id_expiry: $id_expiry, id_issued: $id_issued, id_number: $id_number, id_sub_type: $id_sub_type, id_type: $id_type, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provide Explicit Consent to Switch Utility Plans.
#
# POST /document/{documentId}/utility/process/consent
# Returns: record<documentId: string, industryProcess: string, requestId: string, utilityConsentResult: record<error: record<correlationId: string, errorCode: int, message: string, version: string>, result: record<correlationId: string, eic: list, plan: record, version: string>>>
# operationId: UpdateProcessIndustryUtilityDocumentConsent
export def "update-process-industry-utility-document-consent" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  correlation_id: string # Correlation ID as passed to comparison request (format: uuid, e.g. d290f1ee-6c54-4b01-90e6-d701748f0851)
  --details: record # Information for the residents of the property being supplied — shape: {concessionCard?: record, vulnerabilities?: record}
  plan_id: string # Unique ID of plan, selected from comparison results (format: string, e.g. 123456)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/document/{documentId}/utility/process/consent"
    path_params: [{name: documentId, var: document_id}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    body: {content_type: "application/json", kind: json, fields: [{name: correlationId, var: correlation_id}, {name: details, var: details}, {name: planId, var: plan_id}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    document_id: $document_id, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background, correlation_id: $correlation_id, details: $details, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiate Switching of Utility Plan.
#
# POST /document/{documentId}/utility/process/switch
# Returns: record<documentId: string, industryProcess: string, requestId: string, utilitySwitchResult: record<error: record<correlationId: string, errorCode: int, message: string, version: string>, result: record<correlationId: string, nextSteps: list, plan: record, reference: string, switchDate: string, version: string>>>
# operationId: UpdateProcessIndustryUtilityDocumentSwitch
export def "update-process-industry-utility-document-switch" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --confirmation: list<string> # Array of strings containing all the keys of the elements that required confirmation in the EIC. The absence of any key for a mandatory confirmation will result in an error response.
  correlation_id: string # Correlation ID as passed to comparison request (format: uuid, e.g. d290f1ee-6c54-4b01-90e6-d701748f0851)
  details: record # Details required to switch retailers — shape: {customerDetails: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/document/{documentId}/utility/process/switch"
    path_params: [{name: documentId, var: document_id}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    body: {content_type: "application/json", kind: json, fields: [{name: confirmation, var: confirmation}, {name: correlationId, var: correlation_id}, {name: details, var: details}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    document_id: $document_id, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background, confirmation: $confirmation, correlation_id: $correlation_id, details: $details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update and Verify Document.
#
# POST /document/{documentId}/verify
# Returns: record<documentVerificationResults: record<documentId: string, processResult: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>>, requestId: string>
# operationId: UpdateVerifyDocument
export def "update-verify-document" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --document: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
  --entity-data: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/document/{documentId}/verify"
    path_params: [{name: documentId, var: document_id}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    body: {content_type: "application/json", kind: json, fields: [{name: document, var: document}, {name: entityData, var: entity_data}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    document_id: $document_id, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background, document: $document, entity_data: $entity_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create New Entity.
#
# POST /entity
# Returns: record<entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string>
# operationId: CreateEntity
export def "create-entity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --addresses: list # Collection of address objects. — item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
  --date-of-birth: record # shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
  --entity-id: string # When an entity is first created, it is assigned an ID. When updating an entity, make sure you set the entityId One exception to this is when an entity is created from a document object. It is expected that this object would be passed into a /check or /entity call to set it. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --entity-profile: string # If the entity is using the new profiles feature, then their profile name will be found here. Note: If setting a profile, you must ensure that the profile matches a known configuration. Please contact Frankie developer support if you're unsure as to what valid values are.
  --entity-type: string@entity-type-completer # Indicates the type of an entity. - "INDIVIDUAL": An individual. - "TRUST": A trust. - "ORGANISATION": An organisation.
  --extra-data: list # Set of key-value pairs that provide arbitrary additional type-specific data. You can use these fields to store external IDs, or other non-identity related items if you need to. If updating an existing entity, then existing values with the same name will be overwritten. New values will be added. See here for more information about possible values you can use: https://apidocs.frankiefinancial.com/docs/entity-extradata-key-value-pairs — item shape: {kvpKey?: string, ... (2 more fields)}
  --flags: list # Used to set additional information flags with regards to this entity and for ongoing processing. Flags might include having the entity (not) participate in regular pep/sanctions screening Others will follow over time. — item shape: {flag?: string, value?: int}
  --gender: string@gender-completer # Used to indicate of the entity in question is: - "M"ale - "F"emale - "U"nspecified - "O"ther (for want of a better option) (e.g. F)
  --identity-docs: list # Collection of identity documents (photos, scans, selfies, etc) — item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
  --name: record # shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
  --organisation-data: record # Organisation details for entities. Returned from an ASIC report. — shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/entity"
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: dateOfBirth, var: date_of_birth}, {name: entityId, var: entity_id}, {name: entityProfile, var: entity_profile}, {name: entityType, var: entity_type}, {name: extraData, var: extra_data}, {name: flags, var: flags}, {name: gender, var: gender}, {name: identityDocs, var: identity_docs}, {name: name, var: name}, {name: organisationData, var: organisation_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, addresses: $addresses, date_of_birth: $date_of_birth, entity_id: $entity_id, entity_profile: $entity_profile, entity_type: $entity_type, extra_data: $extra_data, flags: $flags, gender: $gender, identity_docs: $identity_docs, name: $name, organisation_data: $organisation_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Entity and Get IDV Token
#
# POST /entity/new/idvalidate/getToken
# Returns: record<applicantId: string, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string, supportTwoDocs: bool, token: string>
# operationId: CreateEntityGetIDVToken
export def "create-entity-get-idv-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --applicant-id: string # The applicantId previously supplied when creating a token for the first time for an entity. Only required if re-submitting for a fresh token on a previously created applicant.
  --application-id: string # If this is for a native application SDK, then we need the applicationId as reported by the SDK. This will then be tied to the token so it cannot be used in another application or handset. You must send either an applicationID or a referrer (see below)
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
  --referrer: string # If this is for a web SDK, then you need to supply the referrer domain so that the token can be validated by the IDV service You must send either a referrer or an applicationID (see above)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/entity/new/idvalidate/getToken"
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicantId, var: applicant_id}, {name: applicationId, var: application_id}, {name: entity, var: entity}, {name: referrer, var: referrer}]}
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, applicant_id: $applicant_id, application_id: $application_id, entity: $entity, referrer: $referrer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Entity and Push Self-Verification Link
#
# POST /entity/new/verify/pushToMobile
# Returns: record<checkId: string, entityId: string, function: string, linkURL: string, requestId: string>
# operationId: CreateCheckEntityPushToMobile
export def "create-check-entity-push-to-mobile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --nopush: oneof<nothing, bool> # If set to true, then no SMS/email will be pushed. It will be up to the API caller to manage the delivery of the link.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --device-check-details: list # item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/entity/new/verify/pushToMobile"
    query: [{name: nopush, var: nopush}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    body: {content_type: "application/json", kind: json, fields: [{name: deviceCheckDetails, var: device_check_details}, {name: entity, var: entity}]}
    accept: ["application/json"]
    ok: [202]
    auth: api_key
  } {
    nopush: $nopush, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background, device_check_details: $device_check_details, entity: $entity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create and Verify Entity
#
# POST /entity/new/verify/{checkType}/{resultLevel}
# Returns: record<blacklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkResultsListSummaries: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkRisk: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, checkSummary: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, deviceCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, duplicateCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, entityProfileResult: record<actionRecommended: string, addressResults: record, checkId: string, checkResults: list<record>, checkType: string, creditHeaderFailures: list<string>, documentResults: record, entityId: string, issueList: list<string>, kycResults: list<record>, latestCheckDate: string, manualIntervention: bool, policyName: string, profileName: string, resolverRecommended: string, riskLevel: string, riskPolicy: string>, entityResult: record<addressesCheck: list<record>, adverseMediaCheck: list<record>, amlResultSets: list<record>, dateOfBirthCheck: record<checkResult: list, dob: record>, entityId: string, genderCheck: record<checkResult: list, gender: string>, identityDocsCheck: list<record>, nameCheck: record<checkResult: list, name: record>, pepCheck: list<record>, sanctionsCheck: list<record>, watchlistCheck: list<record>>, fraudCheckResults: record<fraudBackgroundCheckResults: list<record>, fraudListResults: list<record>>, manualCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, requestId: string, sharedBlocklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>>
# operationId: CreateCheckEntity
export def "create-check-entity" [
  check_type: string
  result_level: string@result-level-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --device-check-details: list # item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/entity/new/verify/{checkType}/{resultLevel}"
    path_params: [{name: checkType, var: check_type}, {name: resultLevel, var: result_level}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    body: {content_type: "application/json", kind: json, fields: [{name: deviceCheckDetails, var: device_check_details}, {name: entity, var: entity}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    check_type: $check_type, result_level: $result_level, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background, device_check_details: $device_check_details, entity: $entity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for Entity
#
# POST /entity/search
# Returns: record<entitySearchResults: table<confidence: record, documentMatchTypes: list, documentNameMismatches: list, entity: record, entityMatchTypes: list>, requestId: string>
# operationId: SearchEntity
export def "search-entity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --addresses: list # Collection of address objects. — item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
  --date-of-birth: record # shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
  --entity-id: string # When an entity is first created, it is assigned an ID. When updating an entity, make sure you set the entityId One exception to this is when an entity is created from a document object. It is expected that this object would be passed into a /check or /entity call to set it. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --entity-profile: string # If the entity is using the new profiles feature, then their profile name will be found here. Note: If setting a profile, you must ensure that the profile matches a known configuration. Please contact Frankie developer support if you're unsure as to what valid values are.
  --entity-type: string@entity-type-completer # Indicates the type of an entity. - "INDIVIDUAL": An individual. - "TRUST": A trust. - "ORGANISATION": An organisation.
  --extra-data: list # Set of key-value pairs that provide arbitrary additional type-specific data. You can use these fields to store external IDs, or other non-identity related items if you need to. If updating an existing entity, then existing values with the same name will be overwritten. New values will be added. See here for more information about possible values you can use: https://apidocs.frankiefinancial.com/docs/entity-extradata-key-value-pairs — item shape: {kvpKey?: string, ... (2 more fields)}
  --flags: list # Used to set additional information flags with regards to this entity and for ongoing processing. Flags might include having the entity (not) participate in regular pep/sanctions screening Others will follow over time. — item shape: {flag?: string, value?: int}
  --gender: string@gender-completer # Used to indicate of the entity in question is: - "M"ale - "F"emale - "U"nspecified - "O"ther (for want of a better option) (e.g. F)
  --identity-docs: list # Collection of identity documents (photos, scans, selfies, etc) — item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
  --name: record # shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
  --organisation-data: record # Organisation details for entities. Returned from an ASIC report. — shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/entity/search"
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: dateOfBirth, var: date_of_birth}, {name: entityId, var: entity_id}, {name: entityProfile, var: entity_profile}, {name: entityType, var: entity_type}, {name: extraData, var: extra_data}, {name: flags, var: flags}, {name: gender, var: gender}, {name: identityDocs, var: identity_docs}, {name: name, var: name}, {name: organisationData, var: organisation_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, addresses: $addresses, date_of_birth: $date_of_birth, entity_id: $entity_id, entity_profile: $entity_profile, entity_type: $entity_type, extra_data: $extra_data, flags: $flags, gender: $gender, identity_docs: $identity_docs, name: $name, organisation_data: $organisation_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Entity
#
# DELETE /entity/{entityId}
# Returns: record<requestId: string, statusMsg: string>
# operationId: DeleteEntity
export def "delete-entity" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/entity/{entityId}"
    path_params: [{name: entityId, var: entity_id}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    entity_id: $entity_id, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Entity Details
#
# GET /entity/{entityId}
# Returns: record<entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string>
# operationId: QueryEntity
export def "query-entity" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entity/{entityId}"
    path_params: [{name: entityId, var: entity_id}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    entity_id: $entity_id, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Existing Entity.
#
# POST /entity/{entityId}
# Returns: record<entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string>
# operationId: UpdateEntity
export def "update-entity" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --no-invalidate: oneof<nothing, bool> # Disable check result invalidation for this update request.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --addresses: list # Collection of address objects. — item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
  --date-of-birth: record # shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
  --body-entity-id: string # When an entity is first created, it is assigned an ID. When updating an entity, make sure you set the entityId One exception to this is when an entity is created from a document object. It is expected that this object would be passed into a /check or /entity call to set it. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051) (spec name: entityId)
  --entity-profile: string # If the entity is using the new profiles feature, then their profile name will be found here. Note: If setting a profile, you must ensure that the profile matches a known configuration. Please contact Frankie developer support if you're unsure as to what valid values are.
  --entity-type: string@entity-type-completer # Indicates the type of an entity. - "INDIVIDUAL": An individual. - "TRUST": A trust. - "ORGANISATION": An organisation.
  --extra-data: list # Set of key-value pairs that provide arbitrary additional type-specific data. You can use these fields to store external IDs, or other non-identity related items if you need to. If updating an existing entity, then existing values with the same name will be overwritten. New values will be added. See here for more information about possible values you can use: https://apidocs.frankiefinancial.com/docs/entity-extradata-key-value-pairs — item shape: {kvpKey?: string, ... (2 more fields)}
  --flags: list # Used to set additional information flags with regards to this entity and for ongoing processing. Flags might include having the entity (not) participate in regular pep/sanctions screening Others will follow over time. — item shape: {flag?: string, value?: int}
  --gender: string@gender-completer # Used to indicate of the entity in question is: - "M"ale - "F"emale - "U"nspecified - "O"ther (for want of a better option) (e.g. F)
  --identity-docs: list # Collection of identity documents (photos, scans, selfies, etc) — item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
  --name: record # shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
  --organisation-data: record # Organisation details for entities. Returned from an ASIC report. — shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/entity/{entityId}"
    path_params: [{name: entityId, var: entity_id}]
    query: [{name: noInvalidate, var: no_invalidate}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: dateOfBirth, var: date_of_birth}, {name: entityId, var: body_entity_id}, {name: entityProfile, var: entity_profile}, {name: entityType, var: entity_type}, {name: extraData, var: extra_data}, {name: flags, var: flags}, {name: gender, var: gender}, {name: identityDocs, var: identity_docs}, {name: name, var: name}, {name: organisationData, var: organisation_data}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    entity_id: $entity_id, no_invalidate: $no_invalidate, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background, addresses: $addresses, date_of_birth: $date_of_birth, body_entity_id: $body_entity_id, entity_profile: $entity_profile, entity_type: $entity_type, extra_data: $extra_data, flags: $flags, gender: $gender, identity_docs: $identity_docs, name: $name, organisation_data: $organisation_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Check Result States (Batch)
#
# POST /entity/{entityId}/check/{checkId}/{checkClass}
# Returns: record<blacklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkResultsListSummaries: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkRisk: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, checkSummary: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, deviceCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, duplicateCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, entityProfileResult: record<actionRecommended: string, addressResults: record, checkId: string, checkResults: list<record>, checkType: string, creditHeaderFailures: list<string>, documentResults: record, entityId: string, issueList: list<string>, kycResults: list<record>, latestCheckDate: string, manualIntervention: bool, policyName: string, profileName: string, resolverRecommended: string, riskLevel: string, riskPolicy: string>, entityResult: record<addressesCheck: list<record>, adverseMediaCheck: list<record>, amlResultSets: list<record>, dateOfBirthCheck: record<checkResult: list, dob: record>, entityId: string, genderCheck: record<checkResult: list, gender: string>, identityDocsCheck: list<record>, nameCheck: record<checkResult: list, name: record>, pepCheck: list<record>, sanctionsCheck: list<record>, watchlistCheck: list<record>>, fraudCheckResults: record<fraudBackgroundCheckResults: list<record>, fraudListResults: list<record>>, manualCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, requestId: string, sharedBlocklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>>
# operationId: UpdateCheckClassResults
export def "update-check-class-results" [
  entity_id: string
  check_id: string
  check_class: string@check-class-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --check-class-ids: list<string>
  comment: string
  --status: string@status-completer # Indicates the status of a check result as set by a user. - "UNKNOWN": The user has not decided so the actual check result applies as normal. - "TRUE_POSITIVE": The check result has been acknowledged as correct but the final effect (accept/reject) has not been decided. - "TRUE_POSITIVE_ACCEPT": The check result is correct but will be ignored. This is also known as 'whitelisting' - "TRUE_POSITIVE_REJECT": The check result is correct and will be used. - "FALSE_POSITIVE": The check result is not applicable and will be ignored. - "STALE": The check result will become invisible, will not be considered and will not count towards due diligence requirements.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/entity/{entityId}/check/{checkId}/{checkClass}"
    path_params: [{name: entityId, var: entity_id}, {name: checkId, var: check_id}, {name: checkClass, var: check_class}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: checkClassIds, var: check_class_ids}, {name: comment, var: comment}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    entity_id: $entity_id, check_id: $check_id, check_class: $check_class, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, check_class_ids: $check_class_ids, comment: $comment, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Check Result State
#
# POST /entity/{entityId}/check/{checkId}/{checkClass}/{checkClassId}
# Returns: record<blacklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkResultsListSummaries: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkRisk: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, checkSummary: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, deviceCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, duplicateCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, entityProfileResult: record<actionRecommended: string, addressResults: record, checkId: string, checkResults: list<record>, checkType: string, creditHeaderFailures: list<string>, documentResults: record, entityId: string, issueList: list<string>, kycResults: list<record>, latestCheckDate: string, manualIntervention: bool, policyName: string, profileName: string, resolverRecommended: string, riskLevel: string, riskPolicy: string>, entityResult: record<addressesCheck: list<record>, adverseMediaCheck: list<record>, amlResultSets: list<record>, dateOfBirthCheck: record<checkResult: list, dob: record>, entityId: string, genderCheck: record<checkResult: list, gender: string>, identityDocsCheck: list<record>, nameCheck: record<checkResult: list, name: record>, pepCheck: list<record>, sanctionsCheck: list<record>, watchlistCheck: list<record>>, fraudCheckResults: record<fraudBackgroundCheckResults: list<record>, fraudListResults: list<record>>, manualCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, requestId: string, sharedBlocklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>>
# operationId: UpdateCheckClassResult
export def "update-check-class-result" [
  entity_id: string
  check_id: string
  check_class: string@check-class-completer
  check_class_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Set the new status of the Check Class (PRO/BCRO). Valid values are: - "unknown" - "true_positive" - "true_positive_accept" - "true_positive_reject" - "false_positive" - "stale" (required)
  --undo: oneof<nothing, bool> # Undo a prior operation.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/entity/{entityId}/check/{checkId}/{checkClass}/{checkClassId}"
    path_params: [{name: entityId, var: entity_id}, {name: checkId, var: check_id}, {name: checkClass, var: check_class}, {name: checkClassId, var: check_class_id}]
    query: [{name: status, var: status, required: true}, {name: undo, var: undo}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    entity_id: $entity_id, check_id: $check_id, check_class: $check_class, check_class_id: $check_class_id, status: $status, undo: $undo, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Entity Verication Check Details
#
# GET /entity/{entityId}/checks
# Returns: record<blacklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkResultsListSummaries: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkRisk: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, checkSummary: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, deviceCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, duplicateCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, entityProfileResult: record<actionRecommended: string, addressResults: record, checkId: string, checkResults: list<record>, checkType: string, creditHeaderFailures: list<string>, documentResults: record, entityId: string, issueList: list<string>, kycResults: list<record>, latestCheckDate: string, manualIntervention: bool, policyName: string, profileName: string, resolverRecommended: string, riskLevel: string, riskPolicy: string>, entityResult: record<addressesCheck: list<record>, adverseMediaCheck: list<record>, amlResultSets: list<record>, dateOfBirthCheck: record<checkResult: list, dob: record>, entityId: string, genderCheck: record<checkResult: list, gender: string>, identityDocsCheck: list<record>, nameCheck: record<checkResult: list, name: record>, pepCheck: list<record>, sanctionsCheck: list<record>, watchlistCheck: list<record>>, fraudCheckResults: record<fraudBackgroundCheckResults: list<record>, fraudListResults: list<record>>, manualCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, requestId: string, sharedBlocklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>>
# operationId: QueryEntityChecks
export def "query-entity-checks" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alldata: oneof<nothing, bool> # Requests that literally all data should be included in the response to a "get checks" request. This is as opposed to a filtered view where expired results are by default not included for entities that have an assigned profile.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entity/{entityId}/checks"
    path_params: [{name: entityId, var: entity_id}]
    query: [{name: alldata, var: alldata}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    entity_id: $entity_id, alldata: $alldata, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set Entity Blacklist State.
#
# POST /entity/{entityId}/flag/blacklist
# Returns: record<entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string>
# operationId: BlacklistEntity
export def "blacklist-entity" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --set: oneof<nothing, bool> # Set the value of an entity flag. (required)
  --reason: string # Set the reason for blacklisting. Valid values are: - "NO_REASON_SUPPLIED" - "FABRICATED_IDENTITY" - "IDENTITY_TAKEOVER" - "FALSIFIED_ID_DOCUMENTS" - "STOLEN_ID_DOCUMENTS" - "MERCHANT_FRAUD" - "NEVER_PAY_BUST_OUT" - "CONFLICTING_DATA_PROVIDED" - "MONEY_MULE" - "FALSE_FRAUD_CLAIM" - "FRAUDULENT_3RD_PARTY" - "COMPANY_TAKEOVER" - "FICTITIOUS_EMPLOYER" - "COLLUSIVE_EMPLOYER" - "OVER_VALUATION_OF_ASSETS" - "FALSIFIED_EMPLOYMENT_DETAILS" - "MANIPULATED_IDENTITY" - "SYNDICATED_FRAUD" - "INTERNAL_FRAUD" - "BANK_FRAUD" - "UNDISCLOSED_DATA" - "FALSE_HARDSHIP" - "SMR_REPORT_LODGED" - "2X_SMR_REPORTS_LODGED"
  --blocked-by: string # Specify who is setting the entity as blacklisted.
  --attribute: string # Specify the blacklisted attribute. Valid values are: - "ENTIRE_PROFILE" - "FULL_NAME" - "EMAIL_ADDRESS" - "PHONE_NUMBER" - "ID_DOCUMENT" - "MAILING_ADDRESS" - "RESIDENTIAL_ADDRESS"
  --original-id: string # Specify the Id of the matching blacklisted entity or single data-point.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/entity/{entityId}/flag/blacklist"
    path_params: [{name: entityId, var: entity_id}]
    query: [{name: set, var: set, required: true}, {name: reason, var: reason}, {name: blockedBy, var: blocked_by}, {name: attribute, var: attribute}, {name: originalId, var: original_id}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    entity_id: $entity_id, set: $set, reason: $reason, blocked_by: $blocked_by, attribute: $attribute, original_id: $original_id, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resolve Duplicate States.
#
# POST /entity/{entityId}/flag/duplicate/{otherId}
# Returns: record<entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string>
# operationId: FlagDuplicateEntity
export def "flag-duplicate-entity" [
  entity_id: string
  other_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --set: oneof<nothing, bool> # Set the value of an entity flag. (required)
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/entity/{entityId}/flag/duplicate/{otherId}"
    path_params: [{name: entityId, var: entity_id}, {name: otherId, var: other_id}]
    query: [{name: set, var: set, required: true}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    entity_id: $entity_id, other_id: $other_id, set: $set, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set Entity Ongoing AML Monitoring Status.
#
# POST /entity/{entityId}/flag/monitor
# Returns: record<entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string>
# operationId: EntityMonitoring
export def "entity-monitoring" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --set: oneof<nothing, bool> # Set the value of an entity flag. (required)
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/entity/{entityId}/flag/monitor"
    path_params: [{name: entityId, var: entity_id}]
    query: [{name: set, var: set, required: true}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    entity_id: $entity_id, set: $set, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set Entity Watchlist State.
#
# POST /entity/{entityId}/flag/watchlist
# Returns: record<entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string>
# operationId: WatchlistEntity
export def "watchlist-entity" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --set: oneof<nothing, bool> # Set the value of an entity flag. (required)
  --reason: string # Set the reason for watchlisting. Valid values are: - "WAS_BLACKLISTED"
  --comment: string # A comment describing the reason for a request.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/entity/{entityId}/flag/watchlist"
    path_params: [{name: entityId, var: entity_id}]
    query: [{name: set, var: set, required: true}, {name: reason, var: reason}, {name: comment, var: comment}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    entity_id: $entity_id, set: $set, reason: $reason, comment: $comment, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Entity Details and Document Scan Data
#
# GET /entity/{entityId}/full
# Returns: record<entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string>
# operationId: QueryEntityFull
export def "query-entity-full" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entity/{entityId}/full"
    path_params: [{name: entityId, var: entity_id}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    entity_id: $entity_id, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Entity and Get IDV Token
#
# POST /entity/{entityId}/idvalidate/getToken
# Returns: record<applicantId: string, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string, supportTwoDocs: bool, token: string>
# operationId: UpdateEntityGetIDVToken
export def "update-entity-get-idv-token" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --applicant-id: string # The applicantId previously supplied when creating a token for the first time for an entity. Only required if re-submitting for a fresh token on a previously created applicant.
  --application-id: string # If this is for a native application SDK, then we need the applicationId as reported by the SDK. This will then be tied to the token so it cannot be used in another application or handset. You must send either an applicationID or a referrer (see below)
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
  --referrer: string # If this is for a web SDK, then you need to supply the referrer domain so that the token can be validated by the IDV service You must send either a referrer or an applicationID (see above)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/entity/{entityId}/idvalidate/getToken"
    path_params: [{name: entityId, var: entity_id}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicantId, var: applicant_id}, {name: applicationId, var: application_id}, {name: entity, var: entity}, {name: referrer, var: referrer}]}
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    entity_id: $entity_id, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, applicant_id: $applicant_id, application_id: $application_id, entity: $entity, referrer: $referrer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Entity and Initiate IDV Process
#
# POST /entity/{entityId}/idvalidate/initProcess
# Returns: record<applicantId: string, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, requestId: string, supportTwoDocs: bool, token: string>
# operationId: UpdateEntityInitIDVProcess
export def "update-entity-init-idv-process" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --device-check-details: list # item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/entity/{entityId}/idvalidate/initProcess"
    path_params: [{name: entityId, var: entity_id}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: deviceCheckDetails, var: device_check_details}, {name: entity, var: entity}]}
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    entity_id: $entity_id, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, device_check_details: $device_check_details, entity: $entity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Entity States
#
# POST /entity/{entityId}/status
# Returns: record<blacklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkResultsListSummaries: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkRisk: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, checkSummary: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, deviceCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, duplicateCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, entityProfileResult: record<actionRecommended: string, addressResults: record, checkId: string, checkResults: list<record>, checkType: string, creditHeaderFailures: list<string>, documentResults: record, entityId: string, issueList: list<string>, kycResults: list<record>, latestCheckDate: string, manualIntervention: bool, policyName: string, profileName: string, resolverRecommended: string, riskLevel: string, riskPolicy: string>, entityResult: record<addressesCheck: list<record>, adverseMediaCheck: list<record>, amlResultSets: list<record>, dateOfBirthCheck: record<checkResult: list, dob: record>, entityId: string, genderCheck: record<checkResult: list, gender: string>, identityDocsCheck: list<record>, nameCheck: record<checkResult: list, name: record>, pepCheck: list<record>, sanctionsCheck: list<record>, watchlistCheck: list<record>>, fraudCheckResults: record<fraudBackgroundCheckResults: list<record>, fraudListResults: list<record>>, manualCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, requestId: string, sharedBlocklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>>
# operationId: UpdateEntityState
export def "update-entity-state" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --set: string@set-completer # The status of an entity. Valid values are: - "wait": Waiting for new details from entity. - "fail": Manually fail the onboarding process. - "archived": Hide entity from on onboarding. - "clear": Remove any of the above manual states as well as any manual risk. - "inactive": Hide entity and prevent any further operations on it. Cannot be cleared.
  --risk: string@risk-completer # The risk override setting for an entity. This value will be used until a verify result updates a real risk factor. Valid values are: - "low" - "medium" - "high" - "unacceptable" - "significant"
  --comment: string # A comment describing the reason for a request.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/entity/{entityId}/status"
    path_params: [{name: entityId, var: entity_id}]
    query: [{name: set, var: set}, {name: risk, var: risk}, {name: comment, var: comment}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    entity_id: $entity_id, set: $set, risk: $risk, comment: $comment, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Entity and Push Self-Verification Link
#
# POST /entity/{entityId}/verify/pushToMobile
# Returns: record<checkId: string, entityId: string, function: string, linkURL: string, requestId: string>
# operationId: UpdateCheckEntityPushToMobile
export def "update-check-entity-push-to-mobile" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --nopush: oneof<nothing, bool> # If set to true, then no SMS/email will be pushed. It will be up to the API caller to manage the delivery of the link.
  --phase: int # Set the Push To Mobile phase. Currently supported values: - 2
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --device-check-details: list # item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/entity/{entityId}/verify/pushToMobile"
    path_params: [{name: entityId, var: entity_id}]
    query: [{name: nopush, var: nopush}, {name: phase, var: phase}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    body: {content_type: "application/json", kind: json, fields: [{name: deviceCheckDetails, var: device_check_details}, {name: entity, var: entity}]}
    accept: ["application/json"]
    ok: [202]
    auth: api_key
  } {
    entity_id: $entity_id, nopush: $nopush, phase: $phase, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background, device_check_details: $device_check_details, entity: $entity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Entity and Verify Details
#
# POST /entity/{entityId}/verify/{checkType}/{resultLevel}
# Returns: record<blacklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkResultsListSummaries: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, checkRisk: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, checkSummary: record<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list<record>, resultState: string, riskLevel: int>, deviceCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, duplicateCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, entity: record<addresses: list<record>, dateOfBirth: record<country: string, dateOfBirth: string, locality: string, yearOfBirth: string>, entityId: string, entityProfile: string, entityType: string, extraData: list<record>, flags: list<record>, gender: string, identityDocs: list<record>, name: record<displayName: string, familyName: string, givenName: string, honourific: string, middleName: string>, organisationData: record<adverseCreditDataPresent: bool, class: record, disclosingEntityIndicator: bool, includesNonBeneficiallyHeld: bool, kycCustomerType: string, lastCheckDate: string, ownershipResolved: bool, registeredName: string, registration: record, shareStructure: list, startDate: string, status: record, subclass: record, type: record>>, entityProfileResult: record<actionRecommended: string, addressResults: record, checkId: string, checkResults: list<record>, checkType: string, creditHeaderFailures: list<string>, documentResults: record, entityId: string, issueList: list<string>, kycResults: list<record>, latestCheckDate: string, manualIntervention: bool, policyName: string, profileName: string, resolverRecommended: string, riskLevel: string, riskPolicy: string>, entityResult: record<addressesCheck: list<record>, adverseMediaCheck: list<record>, amlResultSets: list<record>, dateOfBirthCheck: record<checkResult: list, dob: record>, entityId: string, genderCheck: record<checkResult: list, gender: string>, identityDocsCheck: list<record>, nameCheck: record<checkResult: list, name: record>, pepCheck: list<record>, sanctionsCheck: list<record>, watchlistCheck: list<record>>, fraudCheckResults: record<fraudBackgroundCheckResults: list<record>, fraudListResults: list<record>>, manualCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>, requestId: string, sharedBlocklistCheckResults: table<checkDate: string, checkId: string, checkPerformedBy: string, checkSource: string, checkType: string, confidenceLevel: int, providerCheckID: string, resultNotes: list, resultState: string, riskLevel: int>>
# operationId: UpdateCheckEntity
export def "update-check-entity" [
  entity_id: string
  check_type: string
  result_level: string@result-level-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # Force the verification to run, overriding any data aging or past check
  --no-invalidate: oneof<nothing, bool> # Disable check result invalidation for this update request.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --device-check-details: list # item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/entity/{entityId}/verify/{checkType}/{resultLevel}"
    path_params: [{name: entityId, var: entity_id}, {name: checkType, var: check_type}, {name: resultLevel, var: result_level}]
    query: [{name: force, var: force}, {name: noInvalidate, var: no_invalidate}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}, {name: X-Frankie-Background, var: x_frankie_background}]
    body: {content_type: "application/json", kind: json, fields: [{name: deviceCheckDetails, var: device_check_details}, {name: entity, var: entity}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: api_key
  } {
    entity_id: $entity_id, check_type: $check_type, result_level: $result_level, force: $force, no_invalidate: $no_invalidate, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id, x_frankie_background: $x_frankie_background, device_check_details: $device_check_details, entity: $entity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# (Re)retrieve Response Result.
#
# GET /retrieve/response/{requestId}
# Returns: record<origHTTPstatus: int, payload: record>
# operationId: RetrieveResult
export def "retrieve-result" [
  request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string@payload-completer # Specifies the type of the payload field in the retrieved response. Default is 'string'.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time. (required, format: uuid)
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/retrieve/response/{requestId}"
    path_params: [{name: requestId, var: request_id}]
    query: [{name: payload, var: payload}]
    header: [{name: X-Frankie-CustomerID, var: x_frankie_customer_id, required: true}, {name: X-Frankie-CustomerChildID, var: x_frankie_customer_child_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api_key
  } {
    request_id: $request_id, payload: $payload, x_frankie_customer_id: $x_frankie_customer_id, x_frankie_customer_child_id: $x_frankie_customer_child_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Service Status
#
# GET /ruok
# Returns: record<asknicely1: string, asknicely2: string, asknicely3: string, asknicely4: string, asknicely5: string, asknicely6: string, asknicely7: string, commit: string, puppy: bool>
# operationId: StatusCheck
export def "status-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --asking-nicely: oneof<nothing, bool> # If set to true, the request is being made politely.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ruok"
    query: [{name: askingNicely, var: asking_nicely}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    asking_nicely: $asking_nicely
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Push Notification Payload
#
# POST /your/configured/path/{requestId}
# operationId: notifyResult
export def "notify-result" [
  request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --check-id: string # If you're calling a processing function of some kind, a check number will be issued. This field will only be present if the function you're calling would normally return a checkId (such as scan, verify, and compare). (format: uuid)
  --document-id: string # Only supplied if the original request was tied to a document. This will be the same ID that was sent in the original acceptance. (format: uuid)
  --entity-customer-reference: string # If the entity in entityId above has had an external service ID attached to it in the entity extraData with kvpKey = customer_reference, then this is that kvpValue (e.g. AU0123456)
  --entity-id: string # Only supplied if the original request was tied to an entity. This will be the same ID that was sent in the original acceptance. (format: uuid)
  --function: string # Short description of the original function called, or function that was triggered. (e.g. entity.create)
  --function-result: string@function-result-completer # High level indication of the final disposition of a backgrounded function - "COMPLETED": the request completed (not that the final result is a success, just that we completed) - "FAILED": the request failed. - "INCOMPLETE": could not complete the request. (e.g. COMPLETED)
  --link-reference: string # URI for resource containing more details about the reason for the notification. (format: uri, e.g. https://portal.frankiefinancial.io/entity/3fa85f64-5717-4562-b3fc-2c963f66afa6)
  --message: string # A brief, human readable message describing the reason for the notification. (e.g. Entity successfully created)
  --notification-type: string@notification-type-completer # Indicates the type of notification being pushed. - "FUNCTION": A request that you previously backgrounded has completed and this is the notification that is it complete (success is another matter) - "RESULT": Like the FUNCTION notification, this tells you that a previously backgrounded request has completed, and that there is a set of results in the payload pointer. - "EVENT": There has been a stateful change in a document, entity or some other piece of data that we are holding/monitoring for you. This is an indication that you may wish to take some action. - "ALERT": Like the EVENT, except that the severity of the notification indicates that action is almost certainly required.
  --body-request-id: string # Unique identifier for every request. Can be used for tracking down answers with technical support. Uses the ULID format (a time-based, sortable UUID) Note: this will be different for every request. (format: ulid, e.g. 01BFJA617JMJXEW6G7TDDXNSHX) (spec name: requestId)
  --username: string # The portal username that initiated the operation that led to this notification. If applicable and available.
]: any -> any {
  $in | http-request {
    method: post
    path: "/your/configured/path/{requestId}"
    path_params: [{name: requestId, var: request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: checkId, var: check_id}, {name: documentId, var: document_id}, {name: entityCustomerReference, var: entity_customer_reference}, {name: entityId, var: entity_id}, {name: function, var: function}, {name: functionResult, var: function_result}, {name: linkReference, var: link_reference}, {name: message, var: message}, {name: notificationType, var: notification_type}, {name: requestId, var: body_request_id}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    request_id: $request_id, check_id: $check_id, document_id: $document_id, entity_customer_reference: $entity_customer_reference, entity_id: $entity_id, function: $function, function_result: $function_result, link_reference: $link_reference, message: $message, notification_type: $notification_type, body_request_id: $body_request_id, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
