# Auto-generated client for BeezUP Merchant API  v2.0
# Source: https://api.apis.guru/v2/specs/beezup.com/2.0/openapi.json
# Auth: --token flag or $env.BEEZUP_MERCHANT_API_TOKEN

const CLIENT = {
  base_url: "https://api.beezup.com"
  token_env_var: "BEEZUP_MERCHANT_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: ocp-apim-subscription-key, in: header, header_name: Ocp-Apim-Subscription-Key, prefix: ""}
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

def base-url-completer [] { ["https://api.beezup.com"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key"] }

# Completers for enum parameters
def date-search-type-completer [] { ["MarketPlaceModification" "Modification" "Purchase"] }
def action-name-completer [] { ["disable" "reenable"] }
def period-type-completer [] { ["Custom" "Last30Days" "Last3Months" "Last60Days" "Last7Days" "Last90Days" "LastMonth" "LastWeek" "ThisMonth" "Yesterday"] }
def order-by-completer [] { ["ClickCount" "Cost" "DisabledProductCount" "EnabledProductCount" "Margin" "OrderCount" "PerformanceIndicator" "ProductCount" "ROI" "SoldProductCount" "TotalSales"] }
def order-by-direction-completer [] { ["Ascending" "Descending"] }
def product-state-completer [] { ["All" "Disabled" "Enabled"] }
def report-type-completer [] { ["ByCategory" "ByChannel" "ByDay" "ByProduct"] }
def optimisation-action-name-completer [] { ["disable" "reenable"] }
def format-completer [] { ["csv" "xlsx"] }
def cost-type-completer [] { ["CPA_ByCategory" "CPA_Global" "CPC_ByCategory" "CPC_Global" "Fixed_Global"] }
def profile-picture-selected-completer [] { ["gravatar" "initials" "uploaded"] }
def feed-type-completer [] { ["Images" "Inventory" "Offers" "Pricing" "Products" "Relationships" "Unpublish"] }
def publication-strategy-kind-completer [] { ["Delta" "Full"] }
def format-completer-1 [] { ["csv"] }
def accept-completer [] { ["application/json" "application/pdf"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    change-order-list-v3: "record<operations: table<errors: list, order: record, status: int, success: bool>>"
    change-order-list-v2: "record<operations: table<errors: list, order: record, status: int, success: bool>>"
    clear-merchant-order-info-list-v3: "record<operations: table<errors: list, order: record, status: int, success: bool>>"
    set-merchant-order-info-list-v3: "record<operations: table<errors: list, order: record, status: int, success: bool>>"
    get-order-list-full-v3: "record<links: record<clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, orders: table<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool, orderItems: list, order_Buyer_AddressCity: string, order_Buyer_AddressCountryIsoCodeAlpha2: string, order_Buyer_AddressCountryName: string, order_Buyer_AddressLine1: string, order_Buyer_AddressLine2: string, order_Buyer_AddressLine3: string, order_Buyer_AddressPostalCode: string, order_Buyer_AddressStateOrRegion: string, order_Buyer_Civility: string, order_Buyer_CompanyName: string, order_Buyer_Email: string, order_Buyer_FirstName: string, order_Buyer_Identifier: string, order_Buyer_LastName: string, order_Buyer_MobilePhone: string, order_Buyer_Phone: string, order_Comment: string, order_FulfilledBy: string, order_IsBusiness: bool, order_IsPrime: bool, order_MarketPlaceChannel: string, order_OrderItemsSourceUri: string, order_OrderSourceUri: string, order_PayingUtcDate: string, order_PaymentMethod: string, order_Shipping_AddressCity: string, order_Shipping_AddressCountryIsoCodeAlpha2: string, order_Shipping_AddressCountryName: string, order_Shipping_AddressLine1: string, order_Shipping_AddressLine2: string, order_Shipping_AddressLine3: string, order_Shipping_AddressName: string, order_Shipping_AddressPostalCode: string, order_Shipping_AddressStateOrRegion: string, order_Shipping_Civility: string, order_Shipping_CompanyName: string, order_Shipping_EarliestShipUtcDate: string, order_Shipping_Email: string, order_Shipping_FirstName: string, order_Shipping_LastName: string, order_Shipping_LatestShipUtcDate: string, order_Shipping_Method: string, order_Shipping_MobilePhone: string, order_Shipping_Phone: string, order_Shipping_Price: float, order_Shipping_ShippingTax: float, order_TotalCommission: float, order_TotalTax: float, transitionLinks: list>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>"
    get-order-list-light-v3: "record<links: record<clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, orders: table<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>"
    get-order-management-ready-marketplace-business-code: "table<codeIdentifier: string, intIdentifier: int, position: int, translationText: string>"
    get-marketplace-accounts-synchronization-v3: "record<accountSynchronizations: table<accountId: int, completedHarvestSynchroUtcDate: string, marketplaceBusinessCode: string, marketplaceTechnicalCode: string>>"
    get-order-v3: "record<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, clearMerchantInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, history: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool, orderItems: table<beezUPOrderItemId: string, orderItem_BeezUPStoreId: string, orderItem_Condition: string, orderItem_ImageUrl: string, orderItem_ItemPrice: float, orderItem_ItemTax: float, orderItem_MarketPlaceProductId: string, orderItem_MarketplaceImageUri: string, orderItem_MarketplaceProductUri: string, orderItem_MerchantImportedProductId: string, orderItem_MerchantImportedProductIdColumnName: string, orderItem_MerchantImportedProductUrl: string, orderItem_MerchantProductId: string, orderItem_MerchantProductIdColumnName: string, orderItem_OrderItemType: string, orderItem_Quantity: float, orderItem_Shipping_Price: float, orderItem_Title: string, orderItem_TotalPrice: float, orderItem_gtin: string>, order_Buyer_AddressCity: string, order_Buyer_AddressCountryIsoCodeAlpha2: string, order_Buyer_AddressCountryName: string, order_Buyer_AddressLine1: string, order_Buyer_AddressLine2: string, order_Buyer_AddressLine3: string, order_Buyer_AddressPostalCode: string, order_Buyer_AddressStateOrRegion: string, order_Buyer_Civility: string, order_Buyer_CompanyName: string, order_Buyer_Email: string, order_Buyer_FirstName: string, order_Buyer_Identifier: string, order_Buyer_LastName: string, order_Buyer_MobilePhone: string, order_Buyer_Phone: string, order_Comment: string, order_FulfilledBy: string, order_IsBusiness: bool, order_IsPrime: bool, order_MarketPlaceChannel: string, order_OrderItemsSourceUri: string, order_OrderSourceUri: string, order_PayingUtcDate: string, order_PaymentMethod: string, order_Shipping_AddressCity: string, order_Shipping_AddressCountryIsoCodeAlpha2: string, order_Shipping_AddressCountryName: string, order_Shipping_AddressLine1: string, order_Shipping_AddressLine2: string, order_Shipping_AddressLine3: string, order_Shipping_AddressName: string, order_Shipping_AddressPostalCode: string, order_Shipping_AddressStateOrRegion: string, order_Shipping_Civility: string, order_Shipping_CompanyName: string, order_Shipping_EarliestShipUtcDate: string, order_Shipping_Email: string, order_Shipping_FirstName: string, order_Shipping_LastName: string, order_Shipping_LatestShipUtcDate: string, order_Shipping_Method: string, order_Shipping_MobilePhone: string, order_Shipping_Phone: string, order_Shipping_Price: float, order_Shipping_ShippingTax: float, order_TotalCommission: float, order_TotalTax: float, transitionLinks: table<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool, rel: string>>"
    head-order-v3: "record"
    get-order-history-v3: "record<changeOrderReportings: table<changeOrderType: string, creationUtcDate: string, details: record, errorMessage: string, executionUUID: string, ipAddress: string, lastUpdateUtcDate: string, processingStatus: string, sourceType: string, sourceUserId: string, sourceUserName: string, testMode: bool>, harvestOrderReportings: table<beezUPForcedStatus: string, beezUPStatus: string, creationUtcDate: string, errorMessage: string, executionUUID: string, lastUpdateUtcDate: string, marketplaceStatus: string, processingStatus: string, warningMessage: string>, lastModificationUtcDate: string>"
    get-order-change-reporting-v3: "record<changeOrderType: string, creationUtcDate: string, details: record, errorMessage: string, executionUUID: string, ipAddress: string, lastUpdateUtcDate: string, processingStatus: string, sourceType: string, sourceUserId: string, sourceUserName: string, testMode: bool>"
    get-channels-index: "record<channels: record, links: record<channelCountryLov: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, channelTypeLov: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, sectorLov: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    get-channels: "record<channels: table<homeUrl: string, logoUrl: string, name: string, sectors: list, types: list>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    get-public-lov-index: "record<links: record<lists: record, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    get-public-list-of-values: "record<items: table<codeIdentifier: string, intIdentifier: int, position: int, translationText: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    login: "record<credentials: table<primaryToken: string, productName: string, secondaryToken: string>>"
    analytics-index: "record<links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, trackingStatus: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<analyticsNumericalProductColumnFilterOperatorNameLov: record<href: string, method: string>, analyticsProductColumnFilterOperatorNameLov: record<href: string, method: string>, analyticsStringProductColumnFilterOperatorNameLov: record<href: string, method: string>, performanceIndicatorFilterOperatorNameLov: record<href: string, method: string>, performanceIndicatorFormulaOperatorNameLov: record<href: string, method: string>, performanceIndicatorFormulaParameterTypeLov: record<href: string, method: string>, performanceIndicatorTypeForReportsByCategoryLov: record<href: string, method: string>, performanceIndicatorTypeForReportsByChannelLov: record<href: string, method: string>, performanceIndicatorTypeForReportsByProductLov: record<href: string, method: string>, performanceIndicatorTypeLov: record<href: string, method: string>, storeOptimisationRuleExecutionStatusLov: record<href: string, method: string>>, stores: table<links: record>>"
    get-store-report-by-day-per-store: "record"
    get-tracking-status: "record<clickSynchronizationUtcDate: string, marketplaceOrderSynchonizationUtcDate: string, orderSynchonizationUtcDate: string>"
    analytics-store-index: "record<links: record<optimise: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, optimiseAll: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, optimiseByCategory: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, optimiseByChannel: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, optimiseByProduct: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportByCategory: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportByChannel: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportByDay: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportByProduct: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportFilters: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, rules: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, trackedClicks: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, trackedExternalOrders: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, trackedOrders: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, trackingStatus: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    copy-optimisation: "record<catalogProductCount: int, channel: record<channelId: string, channelImageUrl: string, channelName: string>, enabledProductCount: int>"
    get-store-report-by-category: "record<categories: table<allProductCount: int, catalogCategoryId: string, catalogCategoryPath: list, catalogProductCount: int, clickCount: int, cost: float, enabledProductCount: int, links: record, margin: float, orderCount: int, performanceIndicator: float, roi: float, soldProductCount: int, totalSales: float>, currencyCode: string, links: record<disableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>"
    get-store-report-by-channel: "record<channels: table<catalogProductCount: int, channel: record, clickCount: int, cost: float, enabledProductCount: int, links: record, margin: float, orderCount: int, performanceIndicator: float, roi: float, soldProductCount: int, totalSales: float>, currencyCode: string, links: record<disableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>"
    get-store-report-by-day: "record<currencyCode: string, days: table<allChannels: record, byChannels: list, day: string>, globalPerformanceIndicators: record<allChannels: record<performanceIndicator: float>, byChannels: list<record>>>"
    get-store-report-by-product: "record<currencyCode: string, links: record<disableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>, products: table<channelCount: int, clickCount: int, cost: float, enabledOnChannelCount: int, links: record, margin: float, orderCount: int, performanceIndicator: float, product: record, roi: float, soldProductCount: int, totalSales: float>>"
    get-report-filters: "record<links: record<save: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, reportFilters: table<links: record, reportFilterId: string, reportFilterName: string, reportType: string>>"
    get-report-filter: "record<links: record<delete: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, save: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, parameters: record<advancedFilters: record<globalMarginPercent: int, linkClickToOrderMaxDay: int, linkClickToOrderType: string, marginType: string, onlyDirectSales: bool, onlyPaymentValidatedOrders: bool, performanceIndicatorFormula: record>, beginPeriodUtcDate: string, categoryFilter: record<categoryPath: list>, channelId: string, endPeriodUtcDate: string, performanceIndicatorFilters: list<record>, periodType: string, analyticsProductColumnFilters: record<additionalAnalyticsProductColumnFilters: record, sku: string, title: string>, productColumnsToDisplay: list<string>, productState: string, reportType: string>, reportFilterId: string, reportFilterName: string>"
    get-rules: "record<links: record<create: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, history: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, run: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, rules: table<actionName: string, enabled: bool, lastExecutionStatus: string, lastExecutionUtcDate: string, links: record, position: int, reportFilterId: string, ruleId: string, ruleName: string, validityEndUtcDate: string, validityStartUtcDate: string>>"
    get-rules-executions: "record<executions: table<activeAffectedProductCount: int, affectedChannelCount: int, affectedProductCount: int, completedUtcDate: string, errorType: string, executionSource: string, links: record, optimisationActionName: string, reportUrl: string, ruleId: string, ruleName: string, startedUtcDate: string, status: string, userId: string>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>"
    get-rule: "record<actionName: string, enabled: bool, lastExecutionStatus: string, lastExecutionUtcDate: string, links: record<delete: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, movedown: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, moveup: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportFilter: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, run: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, update: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, position: int, reportFilterId: string, ruleId: string, ruleName: string, validityEndUtcDate: string, validityStartUtcDate: string>"
    get-store-tracked-clicks: "record<clicks: table<channel: record, ipAddress: string, product: record, utcDate: string>>"
    get-store-tracked-external-orders: "record<externalOrders: table<currencyCode: string, merchantOrderId: string, paymentValidated: bool, products: list, totalAmount: float, utcDate: string, visitorId: string>>"
    get-store-tracked-orders: "record<orders: table<channel: record, currencyCode: string, merchantOrderId: string, paymentValidated: bool, products: list, totalAmount: float, utcDate: string>>"
    get-store-tracking-status: "record<clickSynchronizationUtcDate: string, marketplaceOrderSynchonizationUtcDate: string, orderSynchonizationUtcDate: string>"
    catalog-index: "record<links: record<beezUPColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<beezUPColumnDataTypeLov: record<href: string, method: string>, beezUPColumnDisplayGroupLov: record<href: string, method: string>, beezUPColumnImportanceLov: record<href: string, method: string>, beezUPColumnLov: record<href: string, method: string>, compareOptionLov: record<href: string, method: string>, duplicateProductValueStrategyLov: record<href: string, method: string>>, storeLinks: record<links: record>>"
    catalog-get-beez-up-columns: "table<beezUPColumnName: string, canBeTruncated: bool, columnDataType: string, columnImportance: string, description: string, displayGroupName: string, unique: bool>"
    importation-get-reportings-all-stores: "record"
    catalog-store-index: "record<links: record<autoImportInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, catalogColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, categories: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, computeExpression: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, customColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, importations: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, inputConfiguration: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, products: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, randomProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, startImportation: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, status: string>"
    auto-get-auto-import-configuration: "record<duplicateProductConfiguration: record<compareOptions: string, strategy: string>, input: record<files: list<record>, transformFileUrl: string>, inputConfiguredByUserId: string, pauseStatusChangedByUserId: string, pauseStatusChangedUtcDate: string, paused: bool, scheduledByUserId: string, schedulingLocalTimeZoneName: string, schedulingType: string, schedulingValue: list<string>>"
    auto-start-auto-import: "record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>"
    catalog-get-catalog-columns: "record<catalogColumns: table<catalogColumnName: string, configuration: record, duplicateProductValueConfiguration: record, id: string, ignored: bool, links: record, userColumName: string>>"
    catalog-get-categories: "record<categories: table<categoryId: string, categoryPath: list, selfProductCount: int, totalProductCount: int>>"
    catalog-get-custom-columns: "record<customColumns: table<catalogColumnDependencies: list, configuration: record, id: string, links: record, userColumName: string>, links: record<add: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    catalog-compute-expression: "string"
    catalog-get-custom-column-expression: "string"
    importation-get-reportings: "record<importations: table<autoImported: bool, beginUtcDate: string, endUtcDate: string, errors: list, executionId: string, inputConfigurationUrl: string, lastUpdateUtcDate: string, links: record, stepName: string, steps: record, success: bool, totalProductCount: int, totalProductErrorCount: int, totalProductSuccessCount: int, userId: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, start: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    importation-start-manual-update: "record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>"
    importation-get-importation-monitoring: "record<beginUtcDate: string, errors: table<arguments: list, code: string, cultureName: string, docUrl: string, message: string>, executionId: string, lastUpdateUtcDate: string, links: record<activateAutoImport: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, cancel: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, catalogColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, commit: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, commitColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, configureRemainingCatalogColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, customColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, productSamples: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, technicalProgression: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, steps: record, success: bool, userId: string>"
    importation-get-detected-catalog-columns: "record<detectedCatalogColumns: table<catalogColumnName: string, configuration: record, duplicateProductValueConfiguration: record, id: string, ignored: bool, links: record, userColumName: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    importation-get-custom-columns: "record<customColumns: table<configuration: record, id: string, links: record, userColumName: string>, links: record<add: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    importation-get-custom-column-expression: "string"
    importation-get-product-sample: "record<productValues: record>"
    importation-get-product-sample-custom-column-value: "string"
    importation-get-products-report: "record<paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>, productErrors: table<ean: string, errors: list, lineNumber: int, mpn: string, sku: string, title: string>>"
    importation-get-report: "record<categories: record<createdCount: int, deletedCount: int, unchangedCount: int, updatedCount: int>, columns: record<createdCount: int, deletedCount: int, unchangedCount: int, updatedCount: int>, errors: table<beezUPColumnName: string, errorCode: string, productCount: int, userColumName: string>, executionId: string, importationInfo: record<beginUtcDate: string, endUtcDate: string, inputConfiguration: record<fetch: record, fileNumber: int, read: record>, userId: string>, productMetrics: record<activeCount: int, detectedCount: int, duplicatedCount: int, failedCount: int>, products: record<createdCount: int, deletedCount: int, unchangedCount: int, updatedCount: int>>"
    importation-technical-progression: "record<stepsProgression: record>"
    importation-get-manual-update-last-input-config: "record<input: record<files: list<record>, transformFileUrl: string>>"
    catalog-get-product-by-sku: "record<categoryId: string, exists: bool, productId: string, values: record>"
    catalog-get-products: "record<paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>, products: table<categoryId: string, exists: bool, productId: string, values: record>>"
    catalog-get-random-products: "record<products: table<categoryId: string, exists: bool, productId: string, values: record>>"
    catalog-get-product-by-product-id: "record<categoryId: string, exists: bool, productId: string, values: record>"
    get-channel-catalogs: "record<channelCatalogs: record, links: record<add: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, beezUPColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, filterOperators: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<channelCatalogExclusionFilterOperatorLov: record<href: string, method: string>, channelCatalogExportCacheStatusLov: record<href: string, method: string>>>"
    add-channel-catalog: "record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>"
    get-channel-catalog-filter-operators: "table<expectedChannelColumnDataType: string, expectedValueDataType: string, name: string, valueRequired: bool>"
    get-channel-catalog-product-by-channel-catalog: "record<channelCatalogs: record>"
    get-channel-catalog: "record<channelId: string, channelImageUrl: string, channelName: string, categoryMappingSettings: record<categoryMappingDisabledByMerchant: bool>, channelCatalogId: string, channelCategorySettings: record<mappingLeafRequired: bool, mappingRequired: bool>, channelCostSettings: record<costType: string, globalCostValue: float>, columnMappings: table<catalogColumnId: string, channelCategoryPath: list, channelColumnId: string, catalogBeezUPColumnName: string, catalogColumnName: string, channelBeezUPColumnName: string, channelColumnName: string>, costSettings: record<costType: string, globalCostValue: float>, enabled: bool, exclusionFilters: table<channelColumnId: string, enabled: bool, groupId: string, name: string, operatorName: string, position: int, positionInGroup: int, value: string>, exportUrl: string, generalSettings: record<acceptToPublishInfo: bool, activeBeezUPTracking: bool, doNotExportOutOfStockProducts: bool>, isMarketplace: bool, links: record<categoryMappings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, channelInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, configureColumnMappings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, configureCostSettings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, configureGeneralSettings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, delete: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disableCategoryMappings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, exclusionFilters: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, exportationCacheInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, marketplaceSettings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, products: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reenableCategoryMappings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, state: record<apiSettingsStatus: string, categoryMappingState: record<status: string, uncategorizedProductCount: int, withoutCategoryCostProductCount: int>, columnMappingStatus: string, exportedProductCount: int>, storeId: string, types: list<string>>"
    get-channel-catalog-categories: "record<channelCatalogCategoryConfigurations: table<catalogCategoryPath: list, channelCategoryPath: list, costValue: float, links: record>, costStatus: string, links: record<disable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reenable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, mappingStatus: string>"
    get-channel-catalog-exclusion-filters: "record<exclusionFilters: table<channelColumnId: string, enabled: bool, groupId: string, name: string, operatorName: string, position: int, positionInGroup: int, value: string>, links: record<configure: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    get-channel-catalog-exportation-cache-info: "record<cacheInfo: record<cacheStatus: string, expirationUtcDate: string, feedUrl: string, lastContentChangeUtcDate: string, lastUpdateUtcDate: string>, links: record<clear: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    get-channel-catalog-exportation-history: "record<exportations: table<cacheStatus: string, clientIpAddress: string, clientUserAgent: string, exportationDuration: string, exportationUtcDate: string, exportedProductCount: int>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>"
    get-channel-catalog-product-info-list: "record<links: record<export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>, productInfos: table<productExists: bool, productId: string, productImageUrl: string, productSku: string, productTitle: string, disabled: bool, excluded: bool, excludedBy: list, links: record, overrides: record, uncategorized: bool>>"
    get-channel-catalog-products-counters: "record<disabledProductCountExcludingUncategorized: int, disabledProductCountIncludingUncategorized: int, excludedProductCountExcludingUncategorizedAndDisabled: int, excludedProductCountIncludingUncategorizedAndDisabled: int, existingProductCount: int, uncategorizedProductCount: int>"
    export-channel-catalog-product-info-list: "record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>"
    get-channel-catalog-product-info: "record<productExists: bool, productId: string, productImageUrl: string, productSku: string, productTitle: string, disabled: bool, excluded: bool, excludedBy: list<string>, links: record<disable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, override: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reenable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, overrides: record, uncategorized: bool>"
    get-available-channels: "table<channelId: string, channelLogoUrl: string, channelName: string, links: record<self: record>, types: list<string>>"
    get-channel-info: "record<beezUPOffer: string, channelDescription: string, channelId: string, channelLogoUrl: string, channelName: string, details: record<businessModel: string, category: string, channelType: string, costs: string, homeUrl: string, subscriptionLink: string, trackingType: string>, keyNumbers: record<categories: string, products: string, stores: string, viewsPerMonth: string>, salesContact: record<email: string, name: string, phoneNumber: string>, technicalContact: record<email: string, name: string, phoneNumber: string>>"
    get-channel-categories: "record<firstLevelCategories: table<channelCategoryChannelCode: string, channelCategoryColumnOverrides: record, channelCategoryDefaultCost: float, channelCategoryId: string, channelCategoryLevel: int, channelCategoryName: string, subCategories: list>>"
    get-channel-columns: "table<channelColumnDescription: string, channelColumnId: string, channelColumnName: string, configuration: record<beezUPColumnName: string, columnDataType: string, columnImportance: string>, position: int, restrictedValues: record, showInMapping: bool>"
    get-customer-index: "record<links: record<accountInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, billingPeriods: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, contracts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, friendInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, getOffer: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, invoices: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, logout: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, standardOffers: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, stores: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<activeOfferLov: record<href: string, method: string>, beezUPTimeZoneLov: record<href: string, method: string>, contractTerminationReasonLov: record<href: string, method: string>, countryLov: record<href: string, method: string>, customerStatusLov: record<href: string, method: string>, invoicePaymentStatusLov: record<href: string, method: string>, offerLov: record<href: string, method: string>, storeCountryLov: record<href: string, method: string>, storeSectorLov: record<href: string, method: string>>>"
    get-user-account-info: "record<commercialOwnerEmail: string, companyInfo: record<accountingEmails: list<string>, address: string, city: string, company: string, countryIsoCodeAlpha3: string, postalCode: string, vatNumber: string>, email: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<activateUserAccount: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, changeEmail: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, changePassword: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, getCreditCardInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, getProfilePictureInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, saveCompanyInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, saveCreditCardInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, savePersonalInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, saveProfilePictureInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, personalInfo: record<beezUPTimeZoneId: int, firstName: string, lastName: string, phoneNumber: string, whatIDo: string>, profilePictureUrl: string, status: string, userId: string>"
    get-credit-card-info: "record<creditCardInfo: record<cardNumber: string, cardType: string, expirationMonth: int, expirationYear: int>, currentPaymentMethod: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<saveCreditCardInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    get-profile-picture-info: "record<links: record<save: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, profilePictureInfo: record<profilePictureSelected: string, profilePictureUrl: string, gravatarProfilePictureUrl: string, initialsProfilePictureUrl: string>>"
    get-billing-periods: "record<billingPeriods: table<billingPeriodInMonth: int, discountPercentage: float>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    get-contracts: "record<current: record<additionalClickPrice: float, billingPeriodInMonth: int, billingPeriodPercentDiscount: float, clickIncluded: int, commitmentCalculatedFinishUtcDate: string, commitmentPeriodInMonth: int, contractId: string, currencyCode: string, discountDurationInMonth: int, discountEndUtcDate: string, fixedAndVariableClickInfo: record<clickIncludedAndAdditionalClickPrices: list>, fixedPrice: float, ipUserCreation: string, ipUserModification: string, isCommitmentRenewalAutomatically: bool, isModifiableContract: bool, offerId: int, offerName: string, percentDiscount: float, startUtcDate: string, storeCount: int, trialPeriodInMonth: int, variableModelInfo: record<clickIncludedAndVariablePrices: list, overflowClickCount: int, overflowClickPrice: float>, links: record<disable: record, reenable: record>>, links: record<create: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, next: record<additionalClickPrice: float, billingPeriodInMonth: int, billingPeriodPercentDiscount: float, clickIncluded: int, commitmentCalculatedFinishUtcDate: string, commitmentPeriodInMonth: int, contractId: string, currencyCode: string, discountDurationInMonth: int, discountEndUtcDate: string, fixedAndVariableClickInfo: record<clickIncludedAndAdditionalClickPrices: list>, fixedPrice: float, ipUserCreation: string, ipUserModification: string, isCommitmentRenewalAutomatically: bool, isModifiableContract: bool, offerId: int, offerName: string, percentDiscount: float, startUtcDate: string, storeCount: int, trialPeriodInMonth: int, variableModelInfo: record<clickIncludedAndVariablePrices: list, overflowClickCount: int, overflowClickPrice: float>, links: record<delete: record>>>"
    create-contract: "record<info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<contracts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    get-friend-info: "record<company: string, countryIsoCodeAlpha3: string, email: string, firstName: string, lastName: string, profilePictureUrl: string, userId: string, whatIDo: string>"
    get-invoices: "record<invoices: table<amount: float, amountToBePaid: float, contractId: string, currencyCode: string, dueDate: string, invoiceDate: string, invoiceNumber: string, invoiceUrl: string, paymentStatus: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    get-standard-offers: "record<functionalities: table<code: string, order: int>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, offers: table<additionalClickPrice: float, currencyCode: string, fixedPrice: float, functionalities: list, includedClick: int, isMostPopular: bool, isOldOffer: bool, links: record, name: string, offerId: int, position: int>>"
    get-offer: "record<content: record<contractBillingPeriodInfo: record<amountBillingPeriodDiscount: float, billingPeriodInMonth: int, billingPeriodPercentDiscount: float>, contractBonusInfo: record<bonuses: list>, contractClickInfo: record<additionalClickPrice: float, clickIncluded: int, initialOfferClickIncluded: int>, contractCommitmentInfo: record<commercialCreatorUserId: string, commercialUserId: string, commitmentCalculatedFinishDate: string, commitmentPeriodInMonth: int, contractType: int, couponOfferCode: string, currentContractId: string, currentContractTerminationDate: string, currentCustomerPaymentMethod: string, fixedAndVariableClickInfo: record, isCustomerWantsToTerminateHisContract: bool, isModelMustBeTransmittedInNewContract: bool, minBillingPeriodInMonths: int, model: string, newContractStartDate: string, offerId: int, offerName: string, paymentDelayInDays: int, paymentMethodAuthorized: string, requestedPaymentMethod: string, trialPeriodFinishDate: string, trialPeriodInMonth: int, variableModelInfo: record>, contractDiscountInfo: record<amountCodePromoDiscount: float, amountCodePromoDiscountPerMonth: float, couponDiscountCode: string, couponDiscountId: int, customerHasActualDiscount: bool, discountDurationInMonth: int, isCouponDiscountLinkedToCouponOffer: bool, percentDiscount: float, promotionalCodeValidity: string>, contractMoneyInfo: record<amountExcludingTaxesAndExcludingCodePromoDiscountIncludingBillingPeriodDiscount: float, amountExcludingTaxesAndExcludingDiscounts: float, amountExcludingTaxesIncludingDiscounts: float, amountExcludingTaxesIncludingDiscountsPerMonth: float, amountIncludingTaxesExcludingDiscountIncludingBillingPeriodDiscount: float, amountIncludingTaxesIncludingDiscounts: float, amountTaxesExcludingDiscountIncludingBillingPeriodDiscount: float, amountTaxesIncludingDiscounts: float, currencyCode: string, initialOfferFixedPrice: float, vatPercent: float>, contractStoreInfo: record<additionalStorePrice: float, maxStoreCount: int, minStoreCount: int, ownedStoreCount: int, storeCount: int, storeIncluded: int>, contractTerminationReason: string, contractTerminationReasonType: int, notifyVatExemption: bool, previousFixPeriodInvoiceProrataInfo: record<amountAfterTax: float, amountToBePaid: float, computedProrataToBeDeducted: float, contractId: string, fixedPeriodEndDate: string, fixedPeriodStartDate: string, invoiceNumber: string>>, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<createContract: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    get-stores: "record<links: record<createStore: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, stores: table<countryIsoCodeAlpha3: string, creationUtcDate: string, currencyCode: string, goVersion: int, isTest: bool, links: record, name: string, offerId: int, offerName: string, ownerUserId: string, sectors: list, shareCount: int, status: string, storeId: string, url: string, userRole: string>>"
    create-store: "record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>"
    get-store: "record<countryIsoCodeAlpha3: string, creationUtcDate: string, currencyCode: string, goVersion: int, isTest: bool, links: record<deleteStore: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, share: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, shares: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, updateStore: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, name: string, offerId: int, offerName: string, ownerUserId: string, sectors: list<string>, shareCount: int, status: string, storeId: string, url: string, userRole: string>"
    get-store-alerts: "record<alerts: table<alertId: int, alertName: string, enabled: bool, links: record, properties: list>>"
    get-rights: "table<functionalityCode: string, maxValueInterger: int, unlimited: bool>"
    get-store-shares: "record<links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, share: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, shares: table<links: record, userId: string, userRole: string>>"
    zendesk-token: "record<token: string>"
    get-legacy-tracking-channel-catalogs: "record<channelCatalogs: record, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    get-legacy-tracking-channel-catalog: "record<links: record<migrate: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    get-user-lov-index: "record<links: record<lists: record, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    get-user-list-of-values: "record<items: table<codeIdentifier: string, intIdentifier: int, position: int, translationText: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    get-marketplace-channel-catalogs: "record<links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, marketplaceChannelCatalogs: table<apiSettingsStatus: string, beezUPChannelCatalogId: string, beezUPChannelId: string, beezUPMarketplaceName: any, beezUPStoreId: string, beezUPStoreName: string, enabled: bool, links: record, lovLinks: record, marketplaceAccountId: int, marketplaceBusinessCode: string, marketplaceIsoCountryCodeAlpha2: string, marketplaceMarketPlaceId: string, marketplaceMerchantIdentifiers: record, marketplaceTechnicalCode: string>>"
    get-publications: "record<links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, publications: table<feeds: list, publicationType: string>>"
    get-channel-catalog-marketplace-properties: "record<info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<externalConfigurationPage: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, settings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, propertyGroups: table<name: string, position: int, properties: list>>"
    get-channel-catalog-marketplace-settings: "record<links: record<save: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, settings: table<discriminatorType: string, name: string>>"
    get-order-index: "record<links: record<autoTransitions: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, exportations: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, lightOrders: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, orders: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<orderChangeBusinessOperationType: record<href: string, method: string>, orderProperty: record<href: string, method: string>, orderPropertyPosted: record<href: string, method: string>, orderState: record<href: string, method: string>>>"
    get-automatic-transitions: "record<automaticTransitionInfos: table<accountId: int, enabled: bool, marketplaceTechnicalCode: string, orderStatusTransitionId: int, beezUPOrderStatus: string, businessOperationType: string, links: record, marketplaceBusinessCode: string>, links: record<configure: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>"
    change-order-list: "record<operations: table<errors: list, order: record, status: int, success: bool>>"
    clear-merchant-order-info-list: "record<operations: table<errors: list, order: record, status: int, success: bool>>"
    set-merchant-order-info-list: "record<operations: table<errors: list, order: record, status: int, success: bool>>"
    get-order-exportations: "record<exportations: table<abortionUtcDate: string, beginUtcDate: string, blobNameUri: string, endUtcDate: string, enqueuedUtcDate: string, errorMessage: string, executionUUID: string, expirationUtcDate: string, failureUtcDate: string, ipAddress: string, jsonCriteria: string, lastUpdateUtcDate: string, orderCount: int, processingStatus: string, remainingOrderCount: int, resumedUtcDate: string, sourceType: string, sourceUserId: string, sourceUserName: string, suspendedUtcDate: string, timeoutDuration: string, warningMessage: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>"
    generate-batch-order-invoice: "table<accountId: int, beezUPOrderUUID: string, invoiceLocation: string, invoiceSequenceNumber: int, marketplaceTechnicalCode: string>"
    get-order-invoice-pdf: "binary"
    get-order-invoice-design-settings: "record<footerContentHtml: string, headerContentHtml: string>"
    get-order-invoice-design-settings-preview: "record<invoiceHtmlContent: string>"
    get-order-invoice-general-settings: "record<cultureName: string, invoicePrefix: string, invoiceStartingSequenceNumber: int, productVATPercent: float, shippingVATPercent: float, lastInvoiceSequenceNumber: int>"
    get-order-invoice-preview: "record<invoiceHtmlContent: string>"
    get-order-list-full: "record<links: record<clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, orders: table<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool, orderItems: list, order_Buyer_AddressCity: string, order_Buyer_AddressCountryIsoCodeAlpha2: string, order_Buyer_AddressCountryName: string, order_Buyer_AddressLine1: string, order_Buyer_AddressLine2: string, order_Buyer_AddressLine3: string, order_Buyer_AddressPostalCode: string, order_Buyer_AddressStateOrRegion: string, order_Buyer_Civility: string, order_Buyer_CompanyName: string, order_Buyer_Email: string, order_Buyer_FirstName: string, order_Buyer_Identifier: string, order_Buyer_LastName: string, order_Buyer_MobilePhone: string, order_Buyer_Phone: string, order_Comment: string, order_FulfilledBy: string, order_IsBusiness: bool, order_IsPrime: bool, order_MarketPlaceChannel: string, order_OrderItemsSourceUri: string, order_OrderSourceUri: string, order_PayingUtcDate: string, order_PaymentMethod: string, order_Shipping_AddressCity: string, order_Shipping_AddressCountryIsoCodeAlpha2: string, order_Shipping_AddressCountryName: string, order_Shipping_AddressLine1: string, order_Shipping_AddressLine2: string, order_Shipping_AddressLine3: string, order_Shipping_AddressName: string, order_Shipping_AddressPostalCode: string, order_Shipping_AddressStateOrRegion: string, order_Shipping_Civility: string, order_Shipping_CompanyName: string, order_Shipping_EarliestShipUtcDate: string, order_Shipping_Email: string, order_Shipping_FirstName: string, order_Shipping_LastName: string, order_Shipping_LatestShipUtcDate: string, order_Shipping_Method: string, order_Shipping_MobilePhone: string, order_Shipping_Phone: string, order_Shipping_Price: float, order_Shipping_ShippingTax: float, order_TotalCommission: float, order_TotalTax: float, transitionLinks: list>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>"
    get-order-list-light: "record<links: record<clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, orders: table<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>"
    get-marketplace-accounts-synchronization: "record<accountSynchronizations: table<accountId: int, completedHarvestSynchroUtcDate: string, marketplaceBusinessCode: string, marketplaceTechnicalCode: string>>"
    get-subscription-list: "table<consumerHealthStatus: string, consumerLastRequestSentUri: string, consumerUnvailableSinceUtcDate: string, id: string, lastErrorMessage: record<errors: list>, lastOrderPushedModificationUtcDate: string, lastRetryUtcDate: string, lastSuccessfulOrderPushedUtcDate: string, maxRetryCount: int, merchantApplicationName: string, merchantApplicationVersion: string, merchantEmailAlert: string, name: string, nextScheduledRetryUtcDate: string, recoverBeginPeriodOrderLastModificationUtcDate: string, recoverEndPeriodOrderLastModificationUtcDate: string, retryCount: int, status: string, targetUrl: string, links: record<activate: record, deactivate: record, delete: record, reporting: record, retry: record>>"
    get-subscription: "record<consumerHealthStatus: string, consumerLastRequestSentUri: string, consumerUnvailableSinceUtcDate: string, id: string, lastErrorMessage: record<errors: list<record>>, lastOrderPushedModificationUtcDate: string, lastRetryUtcDate: string, lastSuccessfulOrderPushedUtcDate: string, maxRetryCount: int, merchantApplicationName: string, merchantApplicationVersion: string, merchantEmailAlert: string, name: string, nextScheduledRetryUtcDate: string, recoverBeginPeriodOrderLastModificationUtcDate: string, recoverEndPeriodOrderLastModificationUtcDate: string, retryCount: int, status: string, targetUrl: string, links: record<activate: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, rel: string, urlTemplated: bool>, deactivate: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, rel: string, urlTemplated: bool>, delete: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, rel: string, urlTemplated: bool>, reporting: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, rel: string, urlTemplated: bool>, retry: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, rel: string, urlTemplated: bool>>>"
    get-subscription-push-reporting: "table<duration: string, errorMessage: record<errors: list>, eventId: string, httpStatus: int, lastOrderModificationUtcDate: string, maxRetryCount: int, nextScheduledRetryUtcDate: string, orderCount: int, requestUri: string, responseUri: string, retryCount: int, subscriptionId: string, succeed: bool>"
    get-order: "record<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, clearMerchantInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, history: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool, orderItems: table<beezUPOrderItemId: string, orderItem_BeezUPStoreId: string, orderItem_Condition: string, orderItem_ImageUrl: string, orderItem_ItemPrice: float, orderItem_ItemTax: float, orderItem_MarketPlaceProductId: string, orderItem_MarketplaceImageUri: string, orderItem_MarketplaceProductUri: string, orderItem_MerchantImportedProductId: string, orderItem_MerchantImportedProductIdColumnName: string, orderItem_MerchantImportedProductUrl: string, orderItem_MerchantProductId: string, orderItem_MerchantProductIdColumnName: string, orderItem_OrderItemType: string, orderItem_Quantity: float, orderItem_Shipping_Price: float, orderItem_Title: string, orderItem_TotalPrice: float, orderItem_gtin: string>, order_Buyer_AddressCity: string, order_Buyer_AddressCountryIsoCodeAlpha2: string, order_Buyer_AddressCountryName: string, order_Buyer_AddressLine1: string, order_Buyer_AddressLine2: string, order_Buyer_AddressLine3: string, order_Buyer_AddressPostalCode: string, order_Buyer_AddressStateOrRegion: string, order_Buyer_Civility: string, order_Buyer_CompanyName: string, order_Buyer_Email: string, order_Buyer_FirstName: string, order_Buyer_Identifier: string, order_Buyer_LastName: string, order_Buyer_MobilePhone: string, order_Buyer_Phone: string, order_Comment: string, order_FulfilledBy: string, order_IsBusiness: bool, order_IsPrime: bool, order_MarketPlaceChannel: string, order_OrderItemsSourceUri: string, order_OrderSourceUri: string, order_PayingUtcDate: string, order_PaymentMethod: string, order_Shipping_AddressCity: string, order_Shipping_AddressCountryIsoCodeAlpha2: string, order_Shipping_AddressCountryName: string, order_Shipping_AddressLine1: string, order_Shipping_AddressLine2: string, order_Shipping_AddressLine3: string, order_Shipping_AddressName: string, order_Shipping_AddressPostalCode: string, order_Shipping_AddressStateOrRegion: string, order_Shipping_Civility: string, order_Shipping_CompanyName: string, order_Shipping_EarliestShipUtcDate: string, order_Shipping_Email: string, order_Shipping_FirstName: string, order_Shipping_LastName: string, order_Shipping_LatestShipUtcDate: string, order_Shipping_Method: string, order_Shipping_MobilePhone: string, order_Shipping_Phone: string, order_Shipping_Price: float, order_Shipping_ShippingTax: float, order_TotalCommission: float, order_TotalTax: float, transitionLinks: table<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool, rel: string>>"
    head-order: "record"
    get-order-history: "record<changeOrderReportings: table<changeOrderType: string, creationUtcDate: string, details: record, errorMessage: string, executionUUID: string, ipAddress: string, lastUpdateUtcDate: string, processingStatus: string, sourceType: string, sourceUserId: string, sourceUserName: string, testMode: bool>, harvestOrderReportings: table<beezUPForcedStatus: string, beezUPStatus: string, creationUtcDate: string, errorMessage: string, executionUUID: string, lastUpdateUtcDate: string, marketplaceStatus: string, processingStatus: string, warningMessage: string>, lastModificationUtcDate: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["change-order-list-v3" "change-order-list-v2" "clear-merchant-order-info-list-v3" "set-merchant-order-info-list-v3" "harvest-all-v3" "get-order-list-full-v3" "get-order-list-light-v3" "get-order-management-ready-marketplace-business-code" "get-marketplace-accounts-synchronization-v3" "harvest-account" "get-order-v3" "head-order-v3" "clear-merchant-order-info-v3" "harvest-order-v3" "get-order-history-v3" "get-order-change-reporting-v3" "set-merchant-order-info-v3" "change-order-v3" "get-channels-index" "get-channels" "get-public-lov-index" "get-public-list-of-values" "login" "lost-password" "register" "analytics-index" "get-store-report-by-day-per-store" "get-tracking-status" "analytics-store-index" "optimise-all" "optimise-by-category" "optimise-by-channel" "optimise-by-product" "copy-optimisation" "optimise" "get-store-report-by-category" "get-store-report-by-channel" "get-store-report-by-day" "get-store-report-by-product" "get-report-filters" "delete-report-filter" "get-report-filter" "save-report-filter" "get-rules" "create-rule" "get-rules-executions" "run-rules" "delete-rule" "get-rule" "update-rule" "disable-rule" "enable-rule" "move-down-rule" "move-up-rule" "run-rule" "get-store-tracked-clicks" "get-store-tracked-external-orders" "get-store-tracked-orders" "get-store-tracking-status" "catalog-index" "catalog-get-beez-up-columns" "importation-get-reportings-all-stores" "catalog-store-index" "auto-delete-auto-import" "auto-get-auto-import-configuration" "importation-activate-auto-import" "auto-pause-auto-import" "auto-resume-auto-import" "auto-configure-auto-import-interval" "auto-schedule-auto-import" "auto-start-auto-import" "catalog-get-catalog-columns" "catalog-change-catalog-column-user-name" "catalog-get-categories" "catalog-get-custom-columns" "catalog-compute-expression" "catalog-delete-custom-column" "catalog-save-custom-column" "catalog-get-custom-column-expression" "catalog-change-custom-column-expression" "catalog-change-custom-column-user-name" "importation-get-reportings" "importation-start-manual-update" "importation-get-importation-monitoring" "importation-cancel" "importation-get-detected-catalog-columns" "importation-configure-catalog-column" "importation-ignore-column" "importation-map-catalog-column" "importation-reattend-column" "importation-unmap-catalog-column" "importation-commit" "importation-commit-columns" "importation-configure-remaining-catalog-columns" "importation-get-custom-columns" "importation-delete-custom-column" "importation-save-custom-column" "importation-get-custom-column-expression" "importation-map-custom-column" "importation-unmap-custom-column" "importation-get-product-sample" "importation-get-product-sample-custom-column-value" "importation-get-products-report" "importation-get-report" "importation-technical-progression" "importation-get-manual-update-last-input-config" "catalog-get-product-by-sku" "catalog-get-products" "catalog-get-random-products" "catalog-get-product-by-product-id" "get-channel-catalogs" "add-channel-catalog" "get-channel-catalog-filter-operators" "get-channel-catalog-product-by-channel-catalog" "delete-channel-catalog" "get-channel-catalog" "get-channel-catalog-categories" "configure-channel-catalog-category" "disable-channel-catalog-category-mapping" "reenable-channel-catalog-category-mapping" "configure-channel-catalog-column-mappings" "disable-channel-catalog" "enable-channel-catalog" "get-channel-catalog-exclusion-filters" "configure-channel-catalog-exclusion-filters" "get-channel-catalog-exportation-cache-info" "clear-channel-catalog-exportation-cache" "get-channel-catalog-exportation-history" "get-channel-catalog-product-info-list" "get-channel-catalog-products-counters" "export-channel-catalog-product-info-list" "get-channel-catalog-product-info" "disable-channel-catalog-product" "override-channel-catalog-product-values" "get-channel-catalog-product-value-override-copy" "configure-channel-catalog-product-value-override-copy" "delete-channel-catalog-product-value-override" "reenable-channel-catalog-product" "configure-channel-catalog-cost-settings" "configure-channel-catalog-general-settings" "get-available-channels" "get-channel-info" "get-channel-categories" "get-channel-columns" "get-customer-index" "get-user-account-info" "activate-user-account" "change-email" "change-password" "save-company-info" "get-credit-card-info" "save-credit-card-info" "save-personal-info" "get-profile-picture-info" "save-profile-picture-info" "resend-email-activation" "get-billing-periods" "get-contracts" "create-contract" "terminate-current-contract" "reactivate-current-contract" "delete-next-contract" "get-friend-info" "get-invoices" "get-standard-offers" "get-offer" "logout" "get-stores" "create-store" "delete-store" "get-store" "update-store" "get-store-alerts" "save-store-alerts" "get-rights" "get-store-shares" "share-store" "delete-store-share" "zendesk-token" "get-legacy-tracking-channel-catalogs" "get-legacy-tracking-channel-catalog" "migrate-legacy-tracking-channel-catalog" "get-user-lov-index" "get-user-list-of-values" "get-marketplace-channel-catalogs" "get-publications" "publish-catalog-to-marketplace" "get-channel-catalog-marketplace-properties" "get-channel-catalog-marketplace-settings" "set-channel-catalog-marketplace-settings" "get-order-index" "get-automatic-transitions" "configure-automatic-transitions" "change-order-list" "clear-merchant-order-info-list" "set-merchant-order-info-list" "get-order-exportations" "export-orders" "harvest-all" "generate-batch-order-invoice" "get-order-invoice-pdf" "get-order-invoice-design-settings" "save-order-invoice-design-settings" "get-order-invoice-design-settings-preview" "get-order-invoice-general-settings" "save-order-invoice-general-settings" "generate-order-invoice" "get-order-invoice-preview" "get-order-list-full" "get-order-list-light" "get-marketplace-accounts-synchronization" "get-subscription-list" "delete-subscription" "get-subscription" "create-subscription" "activate-subscription" "deactivate-subscription" "get-subscription-push-reporting" "retry-push-orders" "get-order" "head-order" "clear-merchant-order-info" "harvest-order" "get-order-history" "set-merchant-order-info" "change-order" "commands"] | sort) } | get name | first)
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

# Send a batch of operations to change your marketplace Order information: accept, ship, etc. (max 100 items per call)
#
# POST /orders/v3/batches/changeOrders
# Returns: record<operations: table<errors: list, order: record, status: int, success: bool>>
# operationId: ChangeOrderListV3
export def "change-order-list-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-name: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login. (required)
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  change_orders: list # The change order operations — item shape: {changeOrderRequest?: record, order: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orders/v3/batches/changeOrders"
    query: [{name: userName, var: user_name, required: true}, {name: testMode, var: test_mode}]
    body: {content_type: "application/json", kind: json, fields: [{name: changeOrders, var: change_orders}]}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    user_name: $user_name, test_mode: $test_mode, change_orders: $change_orders
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a batch of operations to change your marketplace Order information: accept, ship, etc. (max 100 items per call)
#
# POST /orders/v3/batches/changeOrders/{changeOrderType}
# Returns: record<operations: table<errors: list, order: record, status: int, success: bool>>
# operationId: ChangeOrderListV2
export def "change-order-list-v2" [
  change_order_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-name: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login. (required)
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  change_orders: list # The change order operations — item shape: {changeOrderRequest?: record, order: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orders/v3/batches/changeOrders/{changeOrderType}"
    path_params: [{name: changeOrderType, var: change_order_type}]
    query: [{name: userName, var: user_name, required: true}, {name: testMode, var: test_mode}]
    body: {content_type: "application/json", kind: json, fields: [{name: changeOrders, var: change_orders}]}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    change_order_type: $change_order_type, user_name: $user_name, test_mode: $test_mode, change_orders: $change_orders
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a batch of operations to clear an Order's merchant information (max 100 items per call)
#
# POST /orders/v3/batches/clearMerchantOrderInfos
# Returns: record<operations: table<errors: list, order: record, status: int, success: bool>>
# operationId: ClearMerchantOrderInfoListV3
export def "clear-merchant-order-info-list-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  orders: list # e.g. [{accountId: 1234, beezUPOrderId: 0, marketplaceTechnicalCode: Amazon}, {accountId: 5678, beezUPOrderId: 0, marketplaceTechnicalCode: Amazon}, {accountId: 9876, beezUPOrderId: 0, marketplaceTechnicalCode: Ebay}] — item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orders/v3/batches/clearMerchantOrderInfos"
    query: [{name: testMode, var: test_mode}]
    body: {content_type: "application/json", kind: json, fields: [{name: orders, var: orders}]}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    test_mode: $test_mode, orders: $orders
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a batch of operations to set an Order's merchant information (max 100 items per call)
#
# POST /orders/v3/batches/setMerchantOrderInfos
# Returns: record<operations: table<errors: list, order: record, status: int, success: bool>>
# operationId: SetMerchantOrderInfoListV3
export def "set-merchant-order-info-list-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  order_merchant_e_commerce_software_name: string # The e-commerce software name of the merchant (e.g. Prestashop)
  order_merchant_e_commerce_software_version: string # The e-commece software version of the merchant (e.g. 123.0.1)
  orders: list # e.g. [{accountId: 1234, beezUPOrderId: 8D47FF1427A26B064ca98e95f644361ada5a5be0bbb3b53, marketplaceTechnicalCode: Amazon, order_MerchantOrderId: BX1234}, {accountId: 5678, beezUPOrderId: 8D47FF149F213D055f26e3c413e4c9ba5c5cfda460547a4, marketplaceTechnicalCode: Amazon, order_MerchantOrderId: BX5678}, {accountId: 9876, beezUPOrderId: 8D47FF150217B60bdec05ab61c445d1a59e3da050b52823, marketplaceTechnicalCode: Ebay, order_MerchantOrderId: BX9876}] — item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string, order_MerchantOrderId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orders/v3/batches/setMerchantOrderInfos"
    query: [{name: testMode, var: test_mode}]
    body: {content_type: "application/json", kind: json, fields: [{name: order_MerchantECommerceSoftwareName, var: order_merchant_e_commerce_software_name}, {name: order_MerchantECommerceSoftwareVersion, var: order_merchant_e_commerce_software_version}, {name: orders, var: orders}]}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    test_mode: $test_mode, order_merchant_e_commerce_software_name: $order_merchant_e_commerce_software_name, order_merchant_e_commerce_software_version: $order_merchant_e_commerce_software_version, orders: $orders
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send harvest request to all your marketplaces
#
# POST /orders/v3/harvest
# operationId: HarvestAllV3
export def "harvest-all-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # The StoreId to filter by (format: StoreId, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> any {
  http-request {
    method: post
    path: "/orders/v3/harvest"
    query: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a paginated list of all Orders with all Order and Order Item(s) properties
#
# POST /orders/v3/list/full
# Returns: record<links: record<clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, orders: table<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool, orderItems: list, order_Buyer_AddressCity: string, order_Buyer_AddressCountryIsoCodeAlpha2: string, order_Buyer_AddressCountryName: string, order_Buyer_AddressLine1: string, order_Buyer_AddressLine2: string, order_Buyer_AddressLine3: string, order_Buyer_AddressPostalCode: string, order_Buyer_AddressStateOrRegion: string, order_Buyer_Civility: string, order_Buyer_CompanyName: string, order_Buyer_Email: string, order_Buyer_FirstName: string, order_Buyer_Identifier: string, order_Buyer_LastName: string, order_Buyer_MobilePhone: string, order_Buyer_Phone: string, order_Comment: string, order_FulfilledBy: string, order_IsBusiness: bool, order_IsPrime: bool, order_MarketPlaceChannel: string, order_OrderItemsSourceUri: string, order_OrderSourceUri: string, order_PayingUtcDate: string, order_PaymentMethod: string, order_Shipping_AddressCity: string, order_Shipping_AddressCountryIsoCodeAlpha2: string, order_Shipping_AddressCountryName: string, order_Shipping_AddressLine1: string, order_Shipping_AddressLine2: string, order_Shipping_AddressLine3: string, order_Shipping_AddressName: string, order_Shipping_AddressPostalCode: string, order_Shipping_AddressStateOrRegion: string, order_Shipping_Civility: string, order_Shipping_CompanyName: string, order_Shipping_EarliestShipUtcDate: string, order_Shipping_Email: string, order_Shipping_FirstName: string, order_Shipping_LastName: string, order_Shipping_LatestShipUtcDate: string, order_Shipping_Method: string, order_Shipping_MobilePhone: string, order_Shipping_Phone: string, order_Shipping_Price: float, order_Shipping_ShippingTax: float, order_TotalCommission: float, order_TotalTax: float, transitionLinks: list>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>
# operationId: GetOrderListFullV3
export def "get-order-list-full-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: string # Allows the client to indicate wether it accepts a compressed encoding to reduce traffic size (required)
  --account-ids: list<int> # Account Id list (e.g. [12345])
  --beez-up-order-statuses: list<string> # e.g. [InProgress]
  begin_period_utc_date: string # The begin period you want to make the search. \ The period MUST not be greater than 62 days. The begin period MUST be lower than the end period. (format: date-time, e.g. 2017-03-01T13:10:01Z)
  --date-search-type: string@date-search-type-completer # Indicates on which date you want to make the filter (default: Modification)
  end_period_utc_date: string # The end period of you search. \ The period MUST not be greater than 62 days. \ The end period MUST be greater than the begin period. The end period MUST be lower to the current date. (format: date-time, e.g. 2017-04-01T13:10:01Z)
  --invoice-availability-type: string # Indicates on which invoice availability to filter (e.g. All)
  --marketplace-business-codes: list<string> # e.g. [PRICEMINISTER]
  --marketplace-order-ids: list<string> # e.g. [AmazonOrderId1234]
  --marketplace-technical-codes: list<string> # e.g. [PriceMinister]
  --order-merchant-info-synchronization-status: string # Indicates on which order merchant info synchronization status to filter (e.g. All)
  --order-buyer-name: string # Buyer full name (e.g. Monroe)
  --order-merchant-order-ids: list<string> # Merchant order id list (e.g. [MyOrderId1234])
  --store-ids: list<string> # Store Id list
  page_number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  page_size: int # Indicate the order count per page (format: int32, default: 100, e.g. 100)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orders/v3/list/full"
    header: [{name: Accept-Encoding, var: accept_encoding, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountIds, var: account_ids}, {name: beezUPOrderStatuses, var: beez_up_order_statuses}, {name: beginPeriodUtcDate, var: begin_period_utc_date}, {name: dateSearchType, var: date_search_type}, {name: endPeriodUtcDate, var: end_period_utc_date}, {name: invoiceAvailabilityType, var: invoice_availability_type}, {name: marketplaceBusinessCodes, var: marketplace_business_codes}, {name: marketplaceOrderIds, var: marketplace_order_ids}, {name: marketplaceTechnicalCodes, var: marketplace_technical_codes}, {name: orderMerchantInfoSynchronizationStatus, var: order_merchant_info_synchronization_status}, {name: order_Buyer_Name, var: order_buyer_name}, {name: order_MerchantOrderIds, var: order_merchant_order_ids}, {name: storeIds, var: store_ids}, {name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    accept_encoding: $accept_encoding, account_ids: $account_ids, beez_up_order_statuses: $beez_up_order_statuses, begin_period_utc_date: $begin_period_utc_date, date_search_type: $date_search_type, end_period_utc_date: $end_period_utc_date, invoice_availability_type: $invoice_availability_type, marketplace_business_codes: $marketplace_business_codes, marketplace_order_ids: $marketplace_order_ids, marketplace_technical_codes: $marketplace_technical_codes, order_merchant_info_synchronization_status: $order_merchant_info_synchronization_status, order_buyer_name: $order_buyer_name, order_merchant_order_ids: $order_merchant_order_ids, store_ids: $store_ids, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a paginated list of all Orders without details
#
# POST /orders/v3/list/light
# Returns: record<links: record<clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, orders: table<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>
# operationId: GetOrderListLightV3
export def "get-order-list-light-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-ids: list<int> # Account Id list (e.g. [12345])
  --beez-up-order-statuses: list<string> # e.g. [InProgress]
  begin_period_utc_date: string # The begin period you want to make the search. \ The period MUST not be greater than 62 days. The begin period MUST be lower than the end period. (format: date-time, e.g. 2017-03-01T13:10:01Z)
  --date-search-type: string@date-search-type-completer # Indicates on which date you want to make the filter (default: Modification)
  end_period_utc_date: string # The end period of you search. \ The period MUST not be greater than 62 days. \ The end period MUST be greater than the begin period. The end period MUST be lower to the current date. (format: date-time, e.g. 2017-04-01T13:10:01Z)
  --invoice-availability-type: string # Indicates on which invoice availability to filter (e.g. All)
  --marketplace-business-codes: list<string> # e.g. [PRICEMINISTER]
  --marketplace-order-ids: list<string> # e.g. [AmazonOrderId1234]
  --marketplace-technical-codes: list<string> # e.g. [PriceMinister]
  --order-merchant-info-synchronization-status: string # Indicates on which order merchant info synchronization status to filter (e.g. All)
  --order-buyer-name: string # Buyer full name (e.g. Monroe)
  --order-merchant-order-ids: list<string> # Merchant order id list (e.g. [MyOrderId1234])
  --store-ids: list<string> # Store Id list
  page_number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  page_size: int # Indicate the order count per page (format: int32, default: 100, e.g. 100)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orders/v3/list/light"
    body: {content_type: "application/json", kind: json, fields: [{name: accountIds, var: account_ids}, {name: beezUPOrderStatuses, var: beez_up_order_statuses}, {name: beginPeriodUtcDate, var: begin_period_utc_date}, {name: dateSearchType, var: date_search_type}, {name: endPeriodUtcDate, var: end_period_utc_date}, {name: invoiceAvailabilityType, var: invoice_availability_type}, {name: marketplaceBusinessCodes, var: marketplace_business_codes}, {name: marketplaceOrderIds, var: marketplace_order_ids}, {name: marketplaceTechnicalCodes, var: marketplace_technical_codes}, {name: orderMerchantInfoSynchronizationStatus, var: order_merchant_info_synchronization_status}, {name: order_Buyer_Name, var: order_buyer_name}, {name: order_MerchantOrderIds, var: order_merchant_order_ids}, {name: storeIds, var: store_ids}, {name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    account_ids: $account_ids, beez_up_order_statuses: $beez_up_order_statuses, begin_period_utc_date: $begin_period_utc_date, date_search_type: $date_search_type, end_period_utc_date: $end_period_utc_date, invoice_availability_type: $invoice_availability_type, marketplace_business_codes: $marketplace_business_codes, marketplace_order_ids: $marketplace_order_ids, marketplace_technical_codes: $marketplace_technical_codes, order_merchant_info_synchronization_status: $order_merchant_info_synchronization_status, order_buyer_name: $order_buyer_name, order_merchant_order_ids: $order_merchant_order_ids, store_ids: $store_ids, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of MarketplaceBusinessCode ready for Order Management
#
# GET /orders/v3/lov/orderManagementReadyMarketplaceBusinessCode
# Returns: table<codeIdentifier: string, intIdentifier: int, position: int, translationText: string>
# operationId: GetOrderManagementReadyMarketplaceBusinessCode
export def "get-order-management-ready-marketplace-business-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-ids: list<string> # StoredIds to filter
  --accept-language: list<string> # Indicates that the client accepts the following languages.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/orders/v3/lov/orderManagementReadyMarketplaceBusinessCode"
    query: [{name: storeIds, var: store_ids, style: csv}]
    header: [{name: Accept-Language, var: accept_language, array: true}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    store_ids: $store_ids, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get current synchronization status between your marketplaces and BeezUP accounts
#
# GET /orders/v3/status
# Returns: record<accountSynchronizations: table<accountId: int, completedHarvestSynchroUtcDate: string, marketplaceBusinessCode: string, marketplaceTechnicalCode: string>>
# operationId: GetMarketplaceAccountsSynchronizationV3
export def "get-marketplace-accounts-synchronization-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-ids: list<string> # StoredIds to filter
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders/v3/status"
    query: [{name: storeIds, var: store_ids, style: csv}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    store_ids: $store_ids, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send harvest request for an Account
#
# POST /orders/v3/{marketplaceTechnicalCode}/{accountId}/harvest
# operationId: HarvestAccount
export def "harvest-account" [
  marketplace_technical_code: string
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
  --marketplace-order-id: string
  --beez-up-order-id: string
]: nothing -> any {
  http-request {
    method: post
    path: "/orders/v3/{marketplaceTechnicalCode}/{accountId}/harvest"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}]
    query: [{name: marketplaceOrderId, var: marketplace_order_id}, {name: beezUPOrderId, var: beez_up_order_id}]
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, marketplace_order_id: $marketplace_order_id, beez_up_order_id: $beez_up_order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get full Order and Order Item(s) properties
#
# GET /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}
# Returns: record<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, clearMerchantInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, history: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool, orderItems: table<beezUPOrderItemId: string, orderItem_BeezUPStoreId: string, orderItem_Condition: string, orderItem_ImageUrl: string, orderItem_ItemPrice: float, orderItem_ItemTax: float, orderItem_MarketPlaceProductId: string, orderItem_MarketplaceImageUri: string, orderItem_MarketplaceProductUri: string, orderItem_MerchantImportedProductId: string, orderItem_MerchantImportedProductIdColumnName: string, orderItem_MerchantImportedProductUrl: string, orderItem_MerchantProductId: string, orderItem_MerchantProductIdColumnName: string, orderItem_OrderItemType: string, orderItem_Quantity: float, orderItem_Shipping_Price: float, orderItem_Title: string, orderItem_TotalPrice: float, orderItem_gtin: string>, order_Buyer_AddressCity: string, order_Buyer_AddressCountryIsoCodeAlpha2: string, order_Buyer_AddressCountryName: string, order_Buyer_AddressLine1: string, order_Buyer_AddressLine2: string, order_Buyer_AddressLine3: string, order_Buyer_AddressPostalCode: string, order_Buyer_AddressStateOrRegion: string, order_Buyer_Civility: string, order_Buyer_CompanyName: string, order_Buyer_Email: string, order_Buyer_FirstName: string, order_Buyer_Identifier: string, order_Buyer_LastName: string, order_Buyer_MobilePhone: string, order_Buyer_Phone: string, order_Comment: string, order_FulfilledBy: string, order_IsBusiness: bool, order_IsPrime: bool, order_MarketPlaceChannel: string, order_OrderItemsSourceUri: string, order_OrderSourceUri: string, order_PayingUtcDate: string, order_PaymentMethod: string, order_Shipping_AddressCity: string, order_Shipping_AddressCountryIsoCodeAlpha2: string, order_Shipping_AddressCountryName: string, order_Shipping_AddressLine1: string, order_Shipping_AddressLine2: string, order_Shipping_AddressLine3: string, order_Shipping_AddressName: string, order_Shipping_AddressPostalCode: string, order_Shipping_AddressStateOrRegion: string, order_Shipping_Civility: string, order_Shipping_CompanyName: string, order_Shipping_EarliestShipUtcDate: string, order_Shipping_Email: string, order_Shipping_FirstName: string, order_Shipping_LastName: string, order_Shipping_LatestShipUtcDate: string, order_Shipping_Method: string, order_Shipping_MobilePhone: string, order_Shipping_Phone: string, order_Shipping_Price: float, order_Shipping_ShippingTax: float, order_TotalCommission: float, order_TotalTax: float, transitionLinks: table<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool, rel: string>>
# operationId: GetOrderV3
export def "get-order-v3" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}, {name: beezUPOrderId, var: beez_up_order_id}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, beez_up_order_id: $beez_up_order_id, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the meta information about the order (ETag, Last-Modified)
#
# HEAD /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}
# Returns: record
# operationId: HeadOrderV3
export def "head-order-v3" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}, {name: beezUPOrderId, var: beez_up_order_id}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, beez_up_order_id: $beez_up_order_id, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear an Order's merchant information
#
# POST /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/clearMerchantOrderInfo
# operationId: ClearMerchantOrderInfoV3
export def "clear-merchant-order-info-v3" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
]: nothing -> any {
  http-request {
    method: post
    path: "/orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/clearMerchantOrderInfo"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}, {name: beezUPOrderId, var: beez_up_order_id}]
    query: [{name: testMode, var: test_mode}]
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, beez_up_order_id: $beez_up_order_id, test_mode: $test_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send harvest request for a single Order
#
# POST /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/harvest
# operationId: HarvestOrderV3
export def "harvest-order-v3" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
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
    path: "/orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/harvest"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}, {name: beezUPOrderId, var: beez_up_order_id}]
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, beez_up_order_id: $beez_up_order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Order's harvest and change history
#
# GET /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/history
# Returns: record<changeOrderReportings: table<changeOrderType: string, creationUtcDate: string, details: record, errorMessage: string, executionUUID: string, ipAddress: string, lastUpdateUtcDate: string, processingStatus: string, sourceType: string, sourceUserId: string, sourceUserName: string, testMode: bool>, harvestOrderReportings: table<beezUPForcedStatus: string, beezUPStatus: string, creationUtcDate: string, errorMessage: string, executionUUID: string, lastUpdateUtcDate: string, marketplaceStatus: string, processingStatus: string, warningMessage: string>, lastModificationUtcDate: string>
# operationId: GetOrderHistoryV3
export def "get-order-history-v3" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
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
    path: "/orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/history"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}, {name: beezUPOrderId, var: beez_up_order_id}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, beez_up_order_id: $beez_up_order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the order change reporting
#
# GET /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/history/{orderChangeExecutionUUID}
# Returns: record<changeOrderType: string, creationUtcDate: string, details: record, errorMessage: string, executionUUID: string, ipAddress: string, lastUpdateUtcDate: string, processingStatus: string, sourceType: string, sourceUserId: string, sourceUserName: string, testMode: bool>
# operationId: GetOrderChangeReportingV3
export def "get-order-change-reporting-v3" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  order_change_execution_uuid: string
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
    path: "/orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/history/{orderChangeExecutionUUID}"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}, {name: beezUPOrderId, var: beez_up_order_id}, {name: orderChangeExecutionUUID, var: order_change_execution_uuid}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, beez_up_order_id: $beez_up_order_id, order_change_execution_uuid: $order_change_execution_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set an Order's merchant information
#
# POST /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/setMerchantOrderInfo
# operationId: SetMerchantOrderInfoV3
export def "set-merchant-order-info-v3" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  order_merchant_e_commerce_software_name: string # The e-commerce software name of the merchant (e.g. Prestashop)
  order_merchant_e_commerce_software_version: string # The e-commece software version of the merchant (e.g. 123.0.1)
  order_merchant_order_id: string # The order merchant identifier (e.g. MyOrderMerchantId)
]: any -> any {
  $in | http-request {
    method: post
    path: "/orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/setMerchantOrderInfo"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}, {name: beezUPOrderId, var: beez_up_order_id}]
    query: [{name: testMode, var: test_mode}]
    body: {content_type: "application/json", kind: json, fields: [{name: order_MerchantECommerceSoftwareName, var: order_merchant_e_commerce_software_name}, {name: order_MerchantECommerceSoftwareVersion, var: order_merchant_e_commerce_software_version}, {name: order_MerchantOrderId, var: order_merchant_order_id}]}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, beez_up_order_id: $beez_up_order_id, test_mode: $test_mode, order_merchant_e_commerce_software_name: $order_merchant_e_commerce_software_name, order_merchant_e_commerce_software_version: $order_merchant_e_commerce_software_version, order_merchant_order_id: $order_merchant_order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change your marketplace Order Information (accept, ship, etc.)
#
# POST /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/{changeOrderType}
# operationId: ChangeOrderV3
export def "change-order-v3" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  change_order_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-name: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login. (required)
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/{changeOrderType}"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}, {name: beezUPOrderId, var: beez_up_order_id}, {name: changeOrderType, var: change_order_type}]
    query: [{name: userName, var: user_name, required: true}, {name: testMode, var: test_mode}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, beez_up_order_id: $beez_up_order_id, change_order_type: $change_order_type, user_name: $user_name, test_mode: $test_mode, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get public channel index
#
# GET /v2/public/channels/
# Returns: record<channels: record, links: record<channelCountryLov: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, channelTypeLov: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, sectorLov: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: GetChannelsIndex
export def "get-channels-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/public/channels/"
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The channel list for one country
#
# GET /v2/public/channels/{countryIsoCode}
# Returns: record<channels: table<homeUrl: string, logoUrl: string, name: string, sectors: list, types: list>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: GetChannels
export def "get-channels" [
  country_iso_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: list<string> # Allows the client to indicate whether it accepts a compressed encoding to reduce traffic size. (required)
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/public/channels/{countryIsoCode}"
    path_params: [{name: countryIsoCode, var: country_iso_code}]
    header: [{name: Accept-Encoding, var: accept_encoding, array: true, required: true}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    country_iso_code: $country_iso_code, accept_encoding: $accept_encoding, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all list names
#
# GET /v2/public/lov/
# Returns: record<links: record<lists: record, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: GetPublicLovIndex
export def "get-public-lov-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/public/lov/"
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of values related to this list name
#
# GET /v2/public/lov/{listName}
# Returns: record<items: table<codeIdentifier: string, intIdentifier: int, position: int, translationText: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: GetPublicListOfValues
export def "get-public-list-of-values" [
  list_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: list<string> # Indicates that the client accepts the following languages.
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/public/lov/{listName}"
    path_params: [{name: listName, var: list_name}]
    header: [{name: Accept-Language, var: accept_language, array: true}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    list_name: $list_name, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Login
#
# POST /v2/public/security/login
# Returns: record<credentials: table<primaryToken: string, productName: string, secondaryToken: string>>
# operationId: Login
export def "login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  login: string # The email (format: email, e.g. paulsimon@mysupercompany.com)
  password: string # Your password (format: password, e.g. I@mW0nder$Full)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/public/security/login"
    body: {content_type: "application/json", kind: json, fields: [{name: login, var: login}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    login: $login, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lost password
#
# POST /v2/public/security/lostpassword
# operationId: LostPassword
export def "lost-password" [
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
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/public/security/lostpassword"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User Registration
#
# POST /v2/public/security/register
# operationId: Register
export def "register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --commercial-owner-user-id: string # The user id of your commercial in BeezUP. (format: uuid, e.g. 47ea14ab-195d-4f9a-a24e-32c329ee40f6)
  --culture-name: string # Can be null. Default: en-GB. The culture name you want to use. FYI. \ The email activation will use this culture. (e.g. en-GB)
  email: string # Your email. We refuse disposable email. (e.g. myemail@mycompany.com)
  password: string # The password you want to use for your new account. \ The password length must be greater or equals to 6 and lower or equals to 128. \ The password must contains at least one number and one special character (e.g. I@mW0nder$Full)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/public/security/register"
    body: {content_type: "application/json", kind: json, fields: [{name: commercialOwnerUserId, var: commercial_owner_user_id}, {name: cultureName, var: culture_name}, {name: email, var: email}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    commercial_owner_user_id: $commercial_owner_user_id, culture_name: $culture_name, email: $email, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Analytics API operation index
#
# GET /v2/user/analytics/
# Returns: record<links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, trackingStatus: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<analyticsNumericalProductColumnFilterOperatorNameLov: record<href: string, method: string>, analyticsProductColumnFilterOperatorNameLov: record<href: string, method: string>, analyticsStringProductColumnFilterOperatorNameLov: record<href: string, method: string>, performanceIndicatorFilterOperatorNameLov: record<href: string, method: string>, performanceIndicatorFormulaOperatorNameLov: record<href: string, method: string>, performanceIndicatorFormulaParameterTypeLov: record<href: string, method: string>, performanceIndicatorTypeForReportsByCategoryLov: record<href: string, method: string>, performanceIndicatorTypeForReportsByChannelLov: record<href: string, method: string>, performanceIndicatorTypeForReportsByProductLov: record<href: string, method: string>, performanceIndicatorTypeLov: record<href: string, method: string>, storeOptimisationRuleExecutionStatusLov: record<href: string, method: string>>, stores: table<links: record>>
# operationId: AnalyticsIndex
export def "analytics-index" [
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
    path: "/v2/user/analytics/"
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the report by day for a StoreId
#
# POST /v2/user/analytics/reports/byday
# Returns: record
# operationId: GetStoreReportByDayPerStore
export def "get-store-report-by-day-per-store" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --advanced-filters: record # shape: {globalMarginPercent?: int, linkClickToOrderMaxDay?: int, linkClickToOrderType: "OnPurchaseDate"|"OnClickDate", marginType: "Tracker"|"Global", onlyDirectSales: bool, onlyPaymentValidatedOrders: bool, performanceIndicatorFormula: record}
  begin_period_utc_date: string # The begin date of the period for the report (format: date, e.g. 2006-11-20T00:00:00Z)
  --catalog-category-id: string # The catalog category identifier (format: guid, e.g. 81a058a6-0451-4b79-84ef-94c58d0ed4ac)
  --channel-ids: list<string> # Indicate the channel identifier list (e.g. [2dc136a7-0d3d-4cc9-a825-a28a42c53e28])
  end_period_utc_date: string # The end date of the period for the report (format: date, e.g. 2006-12-20T00:00:00Z)
  --product-id: string # The product identifier (format: guid, e.g. 578419df-1bbf-41a6-96fa-862e42182b67)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/analytics/reports/byday"
    body: {content_type: "application/json", kind: json, fields: [{name: advancedFilters, var: advanced_filters}, {name: beginPeriodUtcDate, var: begin_period_utc_date}, {name: catalogCategoryId, var: catalog_category_id}, {name: channelIds, var: channel_ids}, {name: endPeriodUtcDate, var: end_period_utc_date}, {name: productId, var: product_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    advanced_filters: $advanced_filters, begin_period_utc_date: $begin_period_utc_date, catalog_category_id: $catalog_category_id, channel_ids: $channel_ids, end_period_utc_date: $end_period_utc_date, product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the global synchronization status of clicks and orders
#
# GET /v2/user/analytics/tracking/status
# Returns: record<clickSynchronizationUtcDate: string, marketplaceOrderSynchonizationUtcDate: string, orderSynchonizationUtcDate: string>
# operationId: GetTrackingStatus
export def "get-tracking-status" [
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
    path: "/v2/user/analytics/tracking/status"
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Analytics API operation index for one store
#
# GET /v2/user/analytics/{storeId}
# Returns: record<links: record<optimise: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, optimiseAll: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, optimiseByCategory: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, optimiseByChannel: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, optimiseByProduct: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportByCategory: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportByChannel: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportByDay: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportByProduct: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportFilters: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, rules: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, trackedClicks: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, trackedExternalOrders: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, trackedOrders: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, trackingStatus: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: AnalyticsStoreIndex
export def "analytics-store-index" [
  store_id: string
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
    path: "/v2/user/analytics/{storeId}"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Optimise all products
#
# POST /v2/user/analytics/{storeId}/optimisations/all/{actionName}
# operationId: OptimiseAll
export def "optimise-all" [
  store_id: string
  action_name: string@action-name-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  advanced_filters: record # shape: {globalMarginPercent?: int, linkClickToOrderMaxDay?: int, linkClickToOrderType: "OnPurchaseDate"|"OnClickDate", marginType: "Tracker"|"Global", onlyDirectSales: bool, onlyPaymentValidatedOrders: bool, performanceIndicatorFormula: record}
  begin_period_utc_date: string # The begin date period you want to get the report. It's required only in case of custom period type ! (format: date-time, e.g. 2006-11-20T00:00:00Z)
  --category-filter: record # shape: {categoryPath?: list<string>}
  --channel-id: string # The channel identifier (format: guid, e.g. 2dc136a7-0d3d-4cc9-a825-a28a42c53e28)
  end_period_utc_date: string # The end date period you want to get the report. It's required only in case of custom period type ! (format: date-time, e.g. 2006-12-20T00:00:00Z)
  --performance-indicator-filters: list # e.g. [{indicator: Cost, operatorName: Equals, value: 10}] — item shape: {operatorName: string, performanceIndicator: "ClickCount"|"Cost"|"OrderCount"|"ProductCount"|"SoldProductCount"|"DisabledProductCount"|"EnabledProductCount"|"TotalSales"|"Margin"|"ROI"|"PerformanceIndicator", value: float}
  period_type: string@period-type-completer # Indicates the period type we want use for the report filter
  --order-by: string@order-by-completer # Indicate on which indicator or value you want to make your formula (e.g. Cost)
  --order-by-direction: string@order-by-direction-completer # Indicate which direction to order results by (e.g. Ascending)
  --analytics-product-column-filters: record # shape: {additionalAnalyticsProductColumnFilters?: record, sku?: string, title?: string}
  --product-columns-to-display: list<string> # e.g. [4b460e31-3d1f-4117-922d-b159a64ec1d2]
  --product-state: string@product-state-completer # You can filter on the product state. (default: All, e.g. All)
  report_type: string@report-type-completer # The report type (e.g. ByProduct)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/analytics/{storeId}/optimisations/all/{actionName}"
    path_params: [{name: storeId, var: store_id}, {name: actionName, var: action_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: advancedFilters, var: advanced_filters}, {name: beginPeriodUtcDate, var: begin_period_utc_date}, {name: categoryFilter, var: category_filter}, {name: channelId, var: channel_id}, {name: endPeriodUtcDate, var: end_period_utc_date}, {name: performanceIndicatorFilters, var: performance_indicator_filters}, {name: periodType, var: period_type}, {name: orderBy, var: order_by}, {name: orderByDirection, var: order_by_direction}, {name: analyticsProductColumnFilters, var: analytics_product_column_filters}, {name: productColumnsToDisplay, var: product_columns_to_display}, {name: productState, var: product_state}, {name: reportType, var: report_type}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, action_name: $action_name, advanced_filters: $advanced_filters, begin_period_utc_date: $begin_period_utc_date, category_filter: $category_filter, channel_id: $channel_id, end_period_utc_date: $end_period_utc_date, performance_indicator_filters: $performance_indicator_filters, period_type: $period_type, order_by: $order_by, order_by_direction: $order_by_direction, analytics_product_column_filters: $analytics_product_column_filters, product_columns_to_display: $product_columns_to_display, product_state: $product_state, report_type: $report_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Optimise products by category
#
# POST /v2/user/analytics/{storeId}/optimisations/bycategory/{catalogCategoryId}/{actionName}
# operationId: OptimiseByCategory
export def "optimise-by-category" [
  store_id: string
  catalog_category_id: string
  action_name: string@action-name-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/analytics/{storeId}/optimisations/bycategory/{catalogCategoryId}/{actionName}"
    path_params: [{name: storeId, var: store_id}, {name: catalogCategoryId, var: catalog_category_id}, {name: actionName, var: action_name}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, catalog_category_id: $catalog_category_id, action_name: $action_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Optimise products by channel
#
# POST /v2/user/analytics/{storeId}/optimisations/bychannel/{channelId}/{actionName}
# operationId: OptimiseByChannel
export def "optimise-by-channel" [
  store_id: string
  channel_id: string
  action_name: string@action-name-completer
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
    path: "/v2/user/analytics/{storeId}/optimisations/bychannel/{channelId}/{actionName}"
    path_params: [{name: storeId, var: store_id}, {name: channelId, var: channel_id}, {name: actionName, var: action_name}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, channel_id: $channel_id, action_name: $action_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Optimise product
#
# POST /v2/user/analytics/{storeId}/optimisations/byproduct/{productId}/{actionName}
# operationId: OptimiseByProduct
export def "optimise-by-product" [
  store_id: string
  product_id: string
  action_name: string@action-name-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/analytics/{storeId}/optimisations/byproduct/{productId}/{actionName}"
    path_params: [{name: storeId, var: store_id}, {name: productId, var: product_id}, {name: actionName, var: action_name}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, product_id: $product_id, action_name: $action_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copy product optimisations between 2 channels
#
# POST /v2/user/analytics/{storeId}/optimisations/copy
# Returns: record<catalogProductCount: int, channel: record<channelId: string, channelImageUrl: string, channelName: string>, enabledProductCount: int>
# operationId: CopyOptimisation
export def "copy-optimisation" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_id_source: string # The channel identifier (format: guid, e.g. 2dc136a7-0d3d-4cc9-a825-a28a42c53e28)
  channel_id_target: string # The channel identifier (format: guid, e.g. 2dc136a7-0d3d-4cc9-a825-a28a42c53e28)
  --keep-existing-optimisation: oneof<nothing, bool> # If true the existing optimisation will be kept (e.g. false)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/analytics/{storeId}/optimisations/copy"
    path_params: [{name: storeId, var: store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: channelIdSource, var: channel_id_source}, {name: channelIdTarget, var: channel_id_target}, {name: keepExistingOptimisation, var: keep_existing_optimisation, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, channel_id_source: $channel_id_source, channel_id_target: $channel_id_target, keep_existing_optimisation: $keep_existing_optimisation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Optimise products by page
#
# POST /v2/user/analytics/{storeId}/optimisations/{actionName}
# operationId: Optimise
export def "optimise" [
  store_id: string
  action_name: string@action-name-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  advanced_filters: record # shape: {globalMarginPercent?: int, linkClickToOrderMaxDay?: int, linkClickToOrderType: "OnPurchaseDate"|"OnClickDate", marginType: "Tracker"|"Global", onlyDirectSales: bool, onlyPaymentValidatedOrders: bool, performanceIndicatorFormula: record}
  begin_period_utc_date: string # The begin date period you want to get the report. It's required only in case of custom period type ! (format: date-time, e.g. 2006-11-20T00:00:00Z)
  --category-filter: record # shape: {categoryPath?: list<string>}
  --channel-id: string # The channel identifier (format: guid, e.g. 2dc136a7-0d3d-4cc9-a825-a28a42c53e28)
  end_period_utc_date: string # The end date period you want to get the report. It's required only in case of custom period type ! (format: date-time, e.g. 2006-12-20T00:00:00Z)
  --performance-indicator-filters: list # e.g. [{indicator: Cost, operatorName: Equals, value: 10}] — item shape: {operatorName: string, performanceIndicator: "ClickCount"|"Cost"|"OrderCount"|"ProductCount"|"SoldProductCount"|"DisabledProductCount"|"EnabledProductCount"|"TotalSales"|"Margin"|"ROI"|"PerformanceIndicator", value: float}
  period_type: string@period-type-completer # Indicates the period type we want use for the report filter
  --order-by: string@order-by-completer # Indicate on which indicator or value you want to make your formula (e.g. Cost)
  --order-by-direction: string@order-by-direction-completer # Indicate which direction to order results by (e.g. Ascending)
  --analytics-product-column-filters: record # shape: {additionalAnalyticsProductColumnFilters?: record, sku?: string, title?: string}
  --product-columns-to-display: list<string> # e.g. [4b460e31-3d1f-4117-922d-b159a64ec1d2]
  --product-state: string@product-state-completer # You can filter on the product state. (default: All, e.g. All)
  report_type: string@report-type-completer # The report type (e.g. ByProduct)
  --page-number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  --page-size: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/analytics/{storeId}/optimisations/{actionName}"
    path_params: [{name: storeId, var: store_id}, {name: actionName, var: action_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: advancedFilters, var: advanced_filters}, {name: beginPeriodUtcDate, var: begin_period_utc_date}, {name: categoryFilter, var: category_filter}, {name: channelId, var: channel_id}, {name: endPeriodUtcDate, var: end_period_utc_date}, {name: performanceIndicatorFilters, var: performance_indicator_filters}, {name: periodType, var: period_type}, {name: orderBy, var: order_by}, {name: orderByDirection, var: order_by_direction}, {name: analyticsProductColumnFilters, var: analytics_product_column_filters}, {name: productColumnsToDisplay, var: product_columns_to_display}, {name: productState, var: product_state}, {name: reportType, var: report_type}, {name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, action_name: $action_name, advanced_filters: $advanced_filters, begin_period_utc_date: $begin_period_utc_date, category_filter: $category_filter, channel_id: $channel_id, end_period_utc_date: $end_period_utc_date, performance_indicator_filters: $performance_indicator_filters, period_type: $period_type, order_by: $order_by, order_by_direction: $order_by_direction, analytics_product_column_filters: $analytics_product_column_filters, product_columns_to_display: $product_columns_to_display, product_state: $product_state, report_type: $report_type, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the report by category
#
# POST /v2/user/analytics/{storeId}/reports/bycategory
# Returns: record<categories: table<allProductCount: int, catalogCategoryId: string, catalogCategoryPath: list, catalogProductCount: int, clickCount: int, cost: float, enabledProductCount: int, links: record, margin: float, orderCount: int, performanceIndicator: float, roi: float, soldProductCount: int, totalSales: float>, currencyCode: string, links: record<disableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>
# operationId: GetStoreReportByCategory
export def "get-store-report-by-category" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  advanced_filters: record # shape: {globalMarginPercent?: int, linkClickToOrderMaxDay?: int, linkClickToOrderType: "OnPurchaseDate"|"OnClickDate", marginType: "Tracker"|"Global", onlyDirectSales: bool, onlyPaymentValidatedOrders: bool, performanceIndicatorFormula: record}
  --begin-period-utc-date: string # The begin date period you want to get the report. It's required only in case of custom period type ! (format: date-time, e.g. 2006-11-20T00:00:00Z)
  --category-filter: record # shape: {categoryPath?: list<string>}
  --channel-id: string # The channel identifier (format: guid, e.g. 2dc136a7-0d3d-4cc9-a825-a28a42c53e28)
  --end-period-utc-date: string # The end date period you want to get the report. It's required only in case of custom period type ! (format: date-time, e.g. 2006-12-20T00:00:00Z)
  --performance-indicator-filters: list # e.g. [{indicator: Cost, operatorName: Equals, value: 10}] — item shape: {operatorName: string, performanceIndicator: "ClickCount"|"Cost"|"OrderCount"|"ProductCount"|"SoldProductCount"|"DisabledProductCount"|"EnabledProductCount"|"TotalSales"|"Margin"|"ROI"|"PerformanceIndicator", value: float}
  period_type: string@period-type-completer # Indicates the period type we want use for the report filter
  --order-by: string@order-by-completer # Indicate on which indicator or value you want to make your formula (e.g. Cost)
  --order-by-direction: string@order-by-direction-completer # Indicate which direction to order results by (e.g. Ascending)
  --page-number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  --page-size: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/analytics/{storeId}/reports/bycategory"
    path_params: [{name: storeId, var: store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: advancedFilters, var: advanced_filters}, {name: beginPeriodUtcDate, var: begin_period_utc_date}, {name: categoryFilter, var: category_filter}, {name: channelId, var: channel_id}, {name: endPeriodUtcDate, var: end_period_utc_date}, {name: performanceIndicatorFilters, var: performance_indicator_filters}, {name: periodType, var: period_type}, {name: orderBy, var: order_by}, {name: orderByDirection, var: order_by_direction}, {name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, advanced_filters: $advanced_filters, begin_period_utc_date: $begin_period_utc_date, category_filter: $category_filter, channel_id: $channel_id, end_period_utc_date: $end_period_utc_date, performance_indicator_filters: $performance_indicator_filters, period_type: $period_type, order_by: $order_by, order_by_direction: $order_by_direction, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the report by channel
#
# POST /v2/user/analytics/{storeId}/reports/bychannel
# Returns: record<channels: table<catalogProductCount: int, channel: record, clickCount: int, cost: float, enabledProductCount: int, links: record, margin: float, orderCount: int, performanceIndicator: float, roi: float, soldProductCount: int, totalSales: float>, currencyCode: string, links: record<disableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>
# operationId: GetStoreReportByChannel
export def "get-store-report-by-channel" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  advanced_filters: record # shape: {globalMarginPercent?: int, linkClickToOrderMaxDay?: int, linkClickToOrderType: "OnPurchaseDate"|"OnClickDate", marginType: "Tracker"|"Global", onlyDirectSales: bool, onlyPaymentValidatedOrders: bool, performanceIndicatorFormula: record}
  --begin-period-utc-date: string # The begin date period you want to get the report. It's required only in case of custom period type ! (format: date-time, e.g. 2006-11-20T00:00:00Z)
  --category-filter: record # shape: {categoryPath?: list<string>}
  --channel-id: string # The channel identifier (format: guid, e.g. 2dc136a7-0d3d-4cc9-a825-a28a42c53e28)
  --end-period-utc-date: string # The end date period you want to get the report. It's required only in case of custom period type ! (format: date-time, e.g. 2006-12-20T00:00:00Z)
  --performance-indicator-filters: list # e.g. [{indicator: Cost, operatorName: Equals, value: 10}] — item shape: {operatorName: string, performanceIndicator: "ClickCount"|"Cost"|"OrderCount"|"ProductCount"|"SoldProductCount"|"DisabledProductCount"|"EnabledProductCount"|"TotalSales"|"Margin"|"ROI"|"PerformanceIndicator", value: float}
  period_type: string@period-type-completer # Indicates the period type we want use for the report filter
  --order-by: string@order-by-completer # Indicate on which indicator or value you want to make your formula (e.g. Cost)
  --order-by-direction: string@order-by-direction-completer # Indicate which direction to order results by (e.g. Ascending)
  --page-number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  --page-size: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/analytics/{storeId}/reports/bychannel"
    path_params: [{name: storeId, var: store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: advancedFilters, var: advanced_filters}, {name: beginPeriodUtcDate, var: begin_period_utc_date}, {name: categoryFilter, var: category_filter}, {name: channelId, var: channel_id}, {name: endPeriodUtcDate, var: end_period_utc_date}, {name: performanceIndicatorFilters, var: performance_indicator_filters}, {name: periodType, var: period_type}, {name: orderBy, var: order_by}, {name: orderByDirection, var: order_by_direction}, {name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, advanced_filters: $advanced_filters, begin_period_utc_date: $begin_period_utc_date, category_filter: $category_filter, channel_id: $channel_id, end_period_utc_date: $end_period_utc_date, performance_indicator_filters: $performance_indicator_filters, period_type: $period_type, order_by: $order_by, order_by_direction: $order_by_direction, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the report by day for a StoreId
#
# POST /v2/user/analytics/{storeId}/reports/byday
# Returns: record<currencyCode: string, days: table<allChannels: record, byChannels: list, day: string>, globalPerformanceIndicators: record<allChannels: record<performanceIndicator: float>, byChannels: list<record>>>
# operationId: GetStoreReportByDay
export def "get-store-report-by-day" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --advanced-filters: record # shape: {globalMarginPercent?: int, linkClickToOrderMaxDay?: int, linkClickToOrderType: "OnPurchaseDate"|"OnClickDate", marginType: "Tracker"|"Global", onlyDirectSales: bool, onlyPaymentValidatedOrders: bool, performanceIndicatorFormula: record}
  begin_period_utc_date: string # The begin date of the period for the report (format: date, e.g. 2006-11-20T00:00:00Z)
  --catalog-category-id: string # The catalog category identifier (format: guid, e.g. 81a058a6-0451-4b79-84ef-94c58d0ed4ac)
  --channel-ids: list<string> # Indicate the channel identifier list (e.g. [2dc136a7-0d3d-4cc9-a825-a28a42c53e28])
  end_period_utc_date: string # The end date of the period for the report (format: date, e.g. 2006-12-20T00:00:00Z)
  --product-id: string # The product identifier (format: guid, e.g. 578419df-1bbf-41a6-96fa-862e42182b67)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/analytics/{storeId}/reports/byday"
    path_params: [{name: storeId, var: store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: advancedFilters, var: advanced_filters}, {name: beginPeriodUtcDate, var: begin_period_utc_date}, {name: catalogCategoryId, var: catalog_category_id}, {name: channelIds, var: channel_ids}, {name: endPeriodUtcDate, var: end_period_utc_date}, {name: productId, var: product_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, advanced_filters: $advanced_filters, begin_period_utc_date: $begin_period_utc_date, catalog_category_id: $catalog_category_id, channel_ids: $channel_ids, end_period_utc_date: $end_period_utc_date, product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the report by product
#
# POST /v2/user/analytics/{storeId}/reports/byproduct
# Returns: record<currencyCode: string, links: record<disableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>, products: table<channelCount: int, clickCount: int, cost: float, enabledOnChannelCount: int, links: record, margin: float, orderCount: int, performanceIndicator: float, product: record, roi: float, soldProductCount: int, totalSales: float>>
# operationId: GetStoreReportByProduct
export def "get-store-report-by-product" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  advanced_filters: record # shape: {globalMarginPercent?: int, linkClickToOrderMaxDay?: int, linkClickToOrderType: "OnPurchaseDate"|"OnClickDate", marginType: "Tracker"|"Global", onlyDirectSales: bool, onlyPaymentValidatedOrders: bool, performanceIndicatorFormula: record}
  begin_period_utc_date: string # The begin date period you want to get the report. It's required only in case of custom period type ! (format: date-time, e.g. 2006-11-20T00:00:00Z)
  --category-filter: record # shape: {categoryPath?: list<string>}
  --channel-id: string # The channel identifier (format: guid, e.g. 2dc136a7-0d3d-4cc9-a825-a28a42c53e28)
  end_period_utc_date: string # The end date period you want to get the report. It's required only in case of custom period type ! (format: date-time, e.g. 2006-12-20T00:00:00Z)
  --performance-indicator-filters: list # e.g. [{indicator: Cost, operatorName: Equals, value: 10}] — item shape: {operatorName: string, performanceIndicator: "ClickCount"|"Cost"|"OrderCount"|"ProductCount"|"SoldProductCount"|"DisabledProductCount"|"EnabledProductCount"|"TotalSales"|"Margin"|"ROI"|"PerformanceIndicator", value: float}
  period_type: string@period-type-completer # Indicates the period type we want use for the report filter
  --order-by: string@order-by-completer # Indicate on which indicator or value you want to make your formula (e.g. Cost)
  --order-by-direction: string@order-by-direction-completer # Indicate which direction to order results by (e.g. Ascending)
  --page-number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  --page-size: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
  --analytics-product-column-filters: record # shape: {additionalAnalyticsProductColumnFilters?: record, sku?: string, title?: string}
  --product-columns-to-display: list<string> # e.g. [4b460e31-3d1f-4117-922d-b159a64ec1d2]
  product_state: string@product-state-completer # You can filter on the product state. (default: All, e.g. All)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/analytics/{storeId}/reports/byproduct"
    path_params: [{name: storeId, var: store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: advancedFilters, var: advanced_filters}, {name: beginPeriodUtcDate, var: begin_period_utc_date}, {name: categoryFilter, var: category_filter}, {name: channelId, var: channel_id}, {name: endPeriodUtcDate, var: end_period_utc_date}, {name: performanceIndicatorFilters, var: performance_indicator_filters}, {name: periodType, var: period_type}, {name: orderBy, var: order_by}, {name: orderByDirection, var: order_by_direction}, {name: pageNumber, var: page_number}, {name: pageSize, var: page_size}, {name: analyticsProductColumnFilters, var: analytics_product_column_filters}, {name: productColumnsToDisplay, var: product_columns_to_display}, {name: productState, var: product_state}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, advanced_filters: $advanced_filters, begin_period_utc_date: $begin_period_utc_date, category_filter: $category_filter, channel_id: $channel_id, end_period_utc_date: $end_period_utc_date, performance_indicator_filters: $performance_indicator_filters, period_type: $period_type, order_by: $order_by, order_by_direction: $order_by_direction, page_number: $page_number, page_size: $page_size, analytics_product_column_filters: $analytics_product_column_filters, product_columns_to_display: $product_columns_to_display, product_state: $product_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get report filter list for the given store
#
# GET /v2/user/analytics/{storeId}/reports/filters
# Returns: record<links: record<save: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, reportFilters: table<links: record, reportFilterId: string, reportFilterName: string, reportType: string>>
# operationId: GetReportFilters
export def "get-report-filters" [
  store_id: string
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
    path: "/v2/user/analytics/{storeId}/reports/filters"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the report filter
#
# DELETE /v2/user/analytics/{storeId}/reports/filters/{reportFilterId}
# operationId: DeleteReportFilter
export def "delete-report-filter" [
  store_id: string
  report_filter_id: string
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
    path: "/v2/user/analytics/{storeId}/reports/filters/{reportFilterId}"
    path_params: [{name: storeId, var: store_id}, {name: reportFilterId, var: report_filter_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, report_filter_id: $report_filter_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the report filter description
#
# GET /v2/user/analytics/{storeId}/reports/filters/{reportFilterId}
# Returns: record<links: record<delete: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, save: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, parameters: record<advancedFilters: record<globalMarginPercent: int, linkClickToOrderMaxDay: int, linkClickToOrderType: string, marginType: string, onlyDirectSales: bool, onlyPaymentValidatedOrders: bool, performanceIndicatorFormula: record>, beginPeriodUtcDate: string, categoryFilter: record<categoryPath: list>, channelId: string, endPeriodUtcDate: string, performanceIndicatorFilters: list<record>, periodType: string, analyticsProductColumnFilters: record<additionalAnalyticsProductColumnFilters: record, sku: string, title: string>, productColumnsToDisplay: list<string>, productState: string, reportType: string>, reportFilterId: string, reportFilterName: string>
# operationId: GetReportFilter
export def "get-report-filter" [
  store_id: string
  report_filter_id: string
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
    path: "/v2/user/analytics/{storeId}/reports/filters/{reportFilterId}"
    path_params: [{name: storeId, var: store_id}, {name: reportFilterId, var: report_filter_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, report_filter_id: $report_filter_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save the report filter
#
# PUT /v2/user/analytics/{storeId}/reports/filters/{reportFilterId}
# operationId: SaveReportFilter
export def "save-report-filter" [
  store_id: string
  report_filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  parameters: record # Contains common filter parameters — shape: {advancedFilters: record, beginPeriodUtcDate: string, categoryFilter?: record, channelId?: string, endPeriodUtcDate: string, performanceIndicatorFilters?: list, periodType: "Custom"|"Yesterday"|"Last7Days"|"LastWeek"|"ThisMonth"|"Last30Days"|"LastMonth"|"Last60Days"|"Last90Days"|"Last3Months", analyticsProductColumnFilters?: record, productColumnsToDisplay?: list<string>, productState?: "All"|"Enabled"|"Disabled", reportType: "ByChannel"|"ByCategory"|"ByProduct"|"ByDay"}
  report_filter_name: string # Report filter name (e.g. My report filter)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/user/analytics/{storeId}/reports/filters/{reportFilterId}"
    path_params: [{name: storeId, var: store_id}, {name: reportFilterId, var: report_filter_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: parameters, var: parameters}, {name: reportFilterName, var: report_filter_name}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, report_filter_id: $report_filter_id, parameters: $parameters, report_filter_name: $report_filter_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of rules for a given store
#
# GET /v2/user/analytics/{storeId}/rules
# Returns: record<links: record<create: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, history: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, run: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, rules: table<actionName: string, enabled: bool, lastExecutionStatus: string, lastExecutionUtcDate: string, links: record, position: int, reportFilterId: string, ruleId: string, ruleName: string, validityEndUtcDate: string, validityStartUtcDate: string>>
# operationId: GetRules
export def "get-rules" [
  store_id: string
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
    path: "/v2/user/analytics/{storeId}/rules"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rule creation
#
# POST /v2/user/analytics/{storeId}/rules
# operationId: CreateRule
export def "create-rule" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-utc-date: string # The end validity utc date of the rule (format: date-time, e.g. 2017-09-30T10:42:40.001Z)
  optimisation_action_name: string@optimisation-action-name-completer # The optimisation action (e.g. reenable)
  report_filter_id: string # The report filter to use for the rule (format: guid, e.g. fb19c53c-2f63-4262-9d94-2d7faa500acd)
  rule_name: string # The name of the rule (e.g. My rule)
  --start-utc-date: string # The start validity utc date of the rule (format: date-time, e.g. 2016-08-29T09:12:33.001Z)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/analytics/{storeId}/rules"
    path_params: [{name: storeId, var: store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: endUtcDate, var: end_utc_date}, {name: optimisationActionName, var: optimisation_action_name}, {name: reportFilterId, var: report_filter_id}, {name: ruleName, var: rule_name}, {name: startUtcDate, var: start_utc_date}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, end_utc_date: $end_utc_date, optimisation_action_name: $optimisation_action_name, report_filter_id: $report_filter_id, rule_name: $rule_name, start_utc_date: $start_utc_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the rules execution history
#
# GET /v2/user/analytics/{storeId}/rules/executions
# Returns: record<executions: table<activeAffectedProductCount: int, affectedChannelCount: int, affectedProductCount: int, completedUtcDate: string, errorType: string, executionSource: string, links: record, optimisationActionName: string, reportUrl: string, ruleId: string, ruleName: string, startedUtcDate: string, status: string, userId: string>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>
# operationId: GetRulesExecutions
export def "get-rules-executions" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page to retrieve (required, default: 1)
  --page-size: int # The count of rule history to retrieve (required, default: 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/analytics/{storeId}/rules/executions"
    path_params: [{name: storeId, var: store_id}]
    query: [{name: pageNumber, var: page_number, required: true, default: "1"}, {name: pageSize, var: page_size, required: true, default: "10"}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run all rules for this store
#
# POST /v2/user/analytics/{storeId}/rules/run
# operationId: RunRules
export def "run-rules" [
  store_id: string
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
    path: "/v2/user/analytics/{storeId}/rules/run"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Rule
#
# DELETE /v2/user/analytics/{storeId}/rules/{ruleId}
# operationId: DeleteRule
export def "delete-rule" [
  store_id: string
  rule_id: string
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
    path: "/v2/user/analytics/{storeId}/rules/{ruleId}"
    path_params: [{name: storeId, var: store_id}, {name: ruleId, var: rule_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the rule
#
# GET /v2/user/analytics/{storeId}/rules/{ruleId}
# Returns: record<actionName: string, enabled: bool, lastExecutionStatus: string, lastExecutionUtcDate: string, links: record<delete: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, movedown: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, moveup: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportFilter: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, run: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, update: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, position: int, reportFilterId: string, ruleId: string, ruleName: string, validityEndUtcDate: string, validityStartUtcDate: string>
# operationId: GetRule
export def "get-rule" [
  store_id: string
  rule_id: string
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
    path: "/v2/user/analytics/{storeId}/rules/{ruleId}"
    path_params: [{name: storeId, var: store_id}, {name: ruleId, var: rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Rule
#
# PATCH /v2/user/analytics/{storeId}/rules/{ruleId}
# operationId: UpdateRule
export def "update-rule" [
  store_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-utc-date: string # Not required. The end validity utc date of the rule (format: date-time, e.g. 2016-08-29T09:12:33.001Z)
  rule_name: string # The name of the rule (e.g. My Rule Renamed)
  --start-utc-date: string # Not required. The start validity utc date of the rule. (format: date-time, e.g. 2016-08-29T09:12:33.001Z)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v2/user/analytics/{storeId}/rules/{ruleId}"
    path_params: [{name: storeId, var: store_id}, {name: ruleId, var: rule_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: endUtcDate, var: end_utc_date}, {name: ruleName, var: rule_name}, {name: startUtcDate, var: start_utc_date}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, rule_id: $rule_id, end_utc_date: $end_utc_date, rule_name: $rule_name, start_utc_date: $start_utc_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable rule
#
# POST /v2/user/analytics/{storeId}/rules/{ruleId}/disable
# operationId: DisableRule
export def "disable-rule" [
  store_id: string
  rule_id: string
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
    path: "/v2/user/analytics/{storeId}/rules/{ruleId}/disable"
    path_params: [{name: storeId, var: store_id}, {name: ruleId, var: rule_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable rule
#
# POST /v2/user/analytics/{storeId}/rules/{ruleId}/enable
# operationId: EnableRule
export def "enable-rule" [
  store_id: string
  rule_id: string
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
    path: "/v2/user/analytics/{storeId}/rules/{ruleId}/enable"
    path_params: [{name: storeId, var: store_id}, {name: ruleId, var: rule_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Move the rule down
#
# POST /v2/user/analytics/{storeId}/rules/{ruleId}/movedown
# operationId: MoveDownRule
export def "move-down-rule" [
  store_id: string
  rule_id: string
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
    path: "/v2/user/analytics/{storeId}/rules/{ruleId}/movedown"
    path_params: [{name: storeId, var: store_id}, {name: ruleId, var: rule_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Move the rule up
#
# POST /v2/user/analytics/{storeId}/rules/{ruleId}/moveup
# operationId: MoveUpRule
export def "move-up-rule" [
  store_id: string
  rule_id: string
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
    path: "/v2/user/analytics/{storeId}/rules/{ruleId}/moveup"
    path_params: [{name: storeId, var: store_id}, {name: ruleId, var: rule_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run rule
#
# POST /v2/user/analytics/{storeId}/rules/{ruleId}/run
# operationId: RunRule
export def "run-rule" [
  store_id: string
  rule_id: string
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
    path: "/v2/user/analytics/{storeId}/rules/{ruleId}/run"
    path_params: [{name: storeId, var: store_id}, {name: ruleId, var: rule_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the latest tracked clicks
#
# GET /v2/user/analytics/{storeId}/tracking/clicks
# Returns: record<clicks: table<channel: record, ipAddress: string, product: record, utcDate: string>>
# operationId: GetStoreTrackedClicks
export def "get-store-tracked-clicks" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # The amount of clicks to retrieve (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/analytics/{storeId}/tracking/clicks"
    path_params: [{name: storeId, var: store_id}]
    query: [{name: count, var: count}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the latest tracked external orders
#
# GET /v2/user/analytics/{storeId}/tracking/externalorders
# Returns: record<externalOrders: table<currencyCode: string, merchantOrderId: string, paymentValidated: bool, products: list, totalAmount: float, utcDate: string, visitorId: string>>
# operationId: GetStoreTrackedExternalOrders
export def "get-store-tracked-external-orders" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # The amount of external orders to retrieve (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/analytics/{storeId}/tracking/externalorders"
    path_params: [{name: storeId, var: store_id}]
    query: [{name: count, var: count}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the latest tracked orders
#
# GET /v2/user/analytics/{storeId}/tracking/orders
# Returns: record<orders: table<channel: record, currencyCode: string, merchantOrderId: string, paymentValidated: bool, products: list, totalAmount: float, utcDate: string>>
# operationId: GetStoreTrackedOrders
export def "get-store-tracked-orders" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # The amount of orders to retrieve (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/analytics/{storeId}/tracking/orders"
    path_params: [{name: storeId, var: store_id}]
    query: [{name: count, var: count}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the synchronization status of clicks and orders of a store
#
# GET /v2/user/analytics/{storeId}/tracking/status
# Returns: record<clickSynchronizationUtcDate: string, marketplaceOrderSynchonizationUtcDate: string, orderSynchonizationUtcDate: string>
# operationId: GetStoreTrackingStatus
export def "get-store-tracking-status" [
  store_id: string
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
    path: "/v2/user/analytics/{storeId}/tracking/status"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the index of the catalog API
#
# GET /v2/user/catalogs/
# Returns: record<links: record<beezUPColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<beezUPColumnDataTypeLov: record<href: string, method: string>, beezUPColumnDisplayGroupLov: record<href: string, method: string>, beezUPColumnImportanceLov: record<href: string, method: string>, beezUPColumnLov: record<href: string, method: string>, compareOptionLov: record<href: string, method: string>, duplicateProductValueStrategyLov: record<href: string, method: string>>, storeLinks: record<links: record>>
# operationId: CatalogIndex
export def "catalog-index" [
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
    path: "/v2/user/catalogs/"
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the BeezUP columns
#
# GET /v2/user/catalogs/beezupColumns
# Returns: table<beezUPColumnName: string, canBeTruncated: bool, columnDataType: string, columnImportance: string, description: string, displayGroupName: string, unique: bool>
# operationId: Catalog_GetBeezUPColumns
export def "catalog-get-beez-up-columns" [
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
    path: "/v2/user/catalogs/beezupColumns"
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the latest catalog importation reporting for all your stores
#
# GET /v2/user/catalogs/importations
# Returns: record
# operationId: Importation_GetReportingsAllStores
export def "importation-get-reportings-all-stores" [
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
    path: "/v2/user/catalogs/importations"
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the index of the catalog API for this store
#
# GET /v2/user/catalogs/{storeId}
# Returns: record<links: record<autoImportInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, catalogColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, categories: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, computeExpression: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, customColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, importations: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, inputConfiguration: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, products: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, randomProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, startImportation: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, status: string>
# operationId: CatalogStoreIndex
export def "catalog-store-index" [
  store_id: string
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
    path: "/v2/user/catalogs/{storeId}"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Auto Import
#
# DELETE /v2/user/catalogs/{storeId}/autoImport
# operationId: Auto_DeleteAutoImport
export def "auto-delete-auto-import" [
  store_id: string
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
    path: "/v2/user/catalogs/{storeId}/autoImport"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the auto import configuration
#
# GET /v2/user/catalogs/{storeId}/autoImport
# Returns: record<duplicateProductConfiguration: record<compareOptions: string, strategy: string>, input: record<files: list<record>, transformFileUrl: string>, inputConfiguredByUserId: string, pauseStatusChangedByUserId: string, pauseStatusChangedUtcDate: string, paused: bool, scheduledByUserId: string, schedulingLocalTimeZoneName: string, schedulingType: string, schedulingValue: list<string>>
# operationId: Auto_GetAutoImportConfiguration
export def "auto-get-auto-import-configuration" [
  store_id: string
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
    path: "/v2/user/catalogs/{storeId}/autoImport"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate the auto importation of the last successful manual catalog importation.
#
# POST /v2/user/catalogs/{storeId}/autoImport/activate
# operationId: Importation_ActivateAutoImport
export def "importation-activate-auto-import" [
  store_id: string
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
    path: "/v2/user/catalogs/{storeId}/autoImport/activate"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pause Auto Import
#
# POST /v2/user/catalogs/{storeId}/autoImport/pause
# operationId: Auto_PauseAutoImport
export def "auto-pause-auto-import" [
  store_id: string
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
    path: "/v2/user/catalogs/{storeId}/autoImport/pause"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resume Auto Import
#
# POST /v2/user/catalogs/{storeId}/autoImport/resume
# operationId: Auto_ResumeAutoImport
export def "auto-resume-auto-import" [
  store_id: string
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
    path: "/v2/user/catalogs/{storeId}/autoImport/resume"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure Auto Import Interval
#
# POST /v2/user/catalogs/{storeId}/autoImport/scheduling/interval
# operationId: Auto_ConfigureAutoImportInterval
export def "auto-configure-auto-import-interval" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  interval: string # Indicate the interval in time span. (i.e. "04:00:00" for every 4 hours) (e.g. 04:00:00)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/catalogs/{storeId}/autoImport/scheduling/interval"
    path_params: [{name: storeId, var: store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: interval, var: interval}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, interval: $interval
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure Auto Import Schedules
#
# POST /v2/user/catalogs/{storeId}/autoImport/scheduling/schedules
# operationId: Auto_ScheduleAutoImport
export def "auto-schedule-auto-import" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --local-time-zone-name: string # If null the local time zone name will be "Romance Standard Time" (default: Romance Standard Time, e.g. Romance Standard Time)
  schedules: list<string> # Indicate the time span you want to import your catalog. (i.e. "21:00:00" to import your catalog at 9PM) (e.g. [21:00:00, 23:00:00, 08:30:00])
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/catalogs/{storeId}/autoImport/scheduling/schedules"
    path_params: [{name: storeId, var: store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: localTimeZoneName, var: local_time_zone_name}, {name: schedules, var: schedules}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, local_time_zone_name: $local_time_zone_name, schedules: $schedules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start Auto Import Manually
#
# POST /v2/user/catalogs/{storeId}/autoImport/start
# Returns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>
# operationId: Auto_StartAutoImport
export def "auto-start-auto-import" [
  store_id: string
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
    path: "/v2/user/catalogs/{storeId}/autoImport/start"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get catalog column list
#
# GET /v2/user/catalogs/{storeId}/catalogColumns
# Returns: record<catalogColumns: table<catalogColumnName: string, configuration: record, duplicateProductValueConfiguration: record, id: string, ignored: bool, links: record, userColumName: string>>
# operationId: Catalog_GetCatalogColumns
export def "catalog-get-catalog-columns" [
  store_id: string
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
    path: "/v2/user/catalogs/{storeId}/catalogColumns"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change Catalog Column User Name
#
# POST /v2/user/catalogs/{storeId}/catalogColumns/{columnId}/rename
# operationId: Catalog_ChangeCatalogColumnUserName
export def "catalog-change-catalog-column-user-name" [
  store_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_colum_name: string # Column named by the user (e.g. My SKU)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/catalogs/{storeId}/catalogColumns/{columnId}/rename"
    path_params: [{name: storeId, var: store_id}, {name: columnId, var: column_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: userColumName, var: user_colum_name}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, column_id: $column_id, user_colum_name: $user_colum_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get category list
#
# GET /v2/user/catalogs/{storeId}/categories
# Returns: record<categories: table<categoryId: string, categoryPath: list, selfProductCount: int, totalProductCount: int>>
# operationId: Catalog_GetCategories
export def "catalog-get-categories" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: list<string> # Indicates that the client accepts that the response will be compressed to reduce traffic size. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/catalogs/{storeId}/categories"
    path_params: [{name: storeId, var: store_id}]
    header: [{name: Accept-Encoding, var: accept_encoding, array: true, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, accept_encoding: $accept_encoding
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get custom column list
#
# GET /v2/user/catalogs/{storeId}/customColumns
# Returns: record<customColumns: table<catalogColumnDependencies: list, configuration: record, id: string, links: record, userColumName: string>, links: record<add: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: Catalog_GetCustomColumns
export def "catalog-get-custom-columns" [
  store_id: string
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
    path: "/v2/user/catalogs/{storeId}/customColumns"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compute the expression for this catalog.
#
# POST /v2/user/catalogs/{storeId}/customColumns/computeExpression
# Returns: string
# operationId: Catalog_ComputeExpression
export def "catalog-compute-expression" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  encrypted_expression: string # The encrypted excel expression of the column (e.g. uziushdczaniodnndonisodndsiondsoidsndoin)
  product_values: record # The key is the column identifier (e.g. {012929c0-e78b-462a-a96e-25c061575385: http://media.conforama.fr/Medias/500000/80000/5000/500/10/G_585511_A.jpg, 46602e10-bc45-4944-a440-63d5f7ece1f8: 42, 68082b11-4ffd-4bec-964a-465a471c7d37: SKU1234, b6d74510-41ce-42ec-947a-0bdf62e9beee: Refrigerateur, ba270fa0-8482-46be-905a-cae4ca746b92: http://www.conforama.fr/gros-electromenager/encastrable/refrigerateur-encastrable/refrigerateur-combine-161-litres-far-r5115s/p/585511})
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/catalogs/{storeId}/customColumns/computeExpression"
    path_params: [{name: storeId, var: store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: encryptedExpression, var: encrypted_expression}, {name: productValues, var: product_values}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, encrypted_expression: $encrypted_expression, product_values: $product_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete custom column
#
# DELETE /v2/user/catalogs/{storeId}/customColumns/{columnId}
# operationId: Catalog_DeleteCustomColumn
export def "catalog-delete-custom-column" [
  store_id: string
  column_id: string
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
    path: "/v2/user/catalogs/{storeId}/customColumns/{columnId}"
    path_params: [{name: storeId, var: store_id}, {name: columnId, var: column_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, column_id: $column_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace a custom column
#
# PUT /v2/user/catalogs/{storeId}/customColumns/{columnId}
# operationId: Catalog_SaveCustomColumn
export def "catalog-save-custom-column" [
  store_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  display_group_name: string # Indicate the display group name where the column must be putted (e.g. Category)
  encrypted_blockly_expression: string # The encrypted XML Blockly representation of the expression (e.g. apokpoa,opz,sixsoisiosnoisn)
  encrypted_expression: string # The encrypted excel expression of the column (e.g. uziushdczaniodnndonisodndsiondsoidsndoin)
  user_column_name: string # Column named by the user (e.g. My SKU)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/user/catalogs/{storeId}/customColumns/{columnId}"
    path_params: [{name: storeId, var: store_id}, {name: columnId, var: column_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayGroupName, var: display_group_name}, {name: encryptedBlocklyExpression, var: encrypted_blockly_expression}, {name: encryptedExpression, var: encrypted_expression}, {name: userColumnName, var: user_column_name}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, column_id: $column_id, display_group_name: $display_group_name, encrypted_blockly_expression: $encrypted_blockly_expression, encrypted_expression: $encrypted_expression, user_column_name: $user_column_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the encrypted custom column expression
#
# GET /v2/user/catalogs/{storeId}/customColumns/{columnId}/expression
# Returns: string
# operationId: Catalog_GetCustomColumnExpression
export def "catalog-get-custom-column-expression" [
  store_id: string
  column_id: string
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
    path: "/v2/user/catalogs/{storeId}/customColumns/{columnId}/expression"
    path_params: [{name: storeId, var: store_id}, {name: columnId, var: column_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, column_id: $column_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change custom column expression
#
# PUT /v2/user/catalogs/{storeId}/customColumns/{columnId}/expression
# operationId: Catalog_ChangeCustomColumnExpression
export def "catalog-change-custom-column-expression" [
  store_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  encrypted_blockly_expression: string # The encrypted XML Blockly representation of the expression (e.g. apokpoa,opz,sixsoisiosnoisn)
  encrypted_expression: string # The encrypted excel expression of the column (e.g. uziushdczaniodnndonisodndsiondsoidsndoin)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/user/catalogs/{storeId}/customColumns/{columnId}/expression"
    path_params: [{name: storeId, var: store_id}, {name: columnId, var: column_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: encryptedBlocklyExpression, var: encrypted_blockly_expression}, {name: encryptedExpression, var: encrypted_expression}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, column_id: $column_id, encrypted_blockly_expression: $encrypted_blockly_expression, encrypted_expression: $encrypted_expression
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change Custom Column User Name
#
# POST /v2/user/catalogs/{storeId}/customColumns/{columnId}/rename
# operationId: Catalog_ChangeCustomColumnUserName
export def "catalog-change-custom-column-user-name" [
  store_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_colum_name: string # Column named by the user (e.g. My SKU)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/catalogs/{storeId}/customColumns/{columnId}/rename"
    path_params: [{name: storeId, var: store_id}, {name: columnId, var: column_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: userColumName, var: user_colum_name}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, column_id: $column_id, user_colum_name: $user_colum_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the latest catalog importation reporting
#
# GET /v2/user/catalogs/{storeId}/importations
# Returns: record<importations: table<autoImported: bool, beginUtcDate: string, endUtcDate: string, errors: list, executionId: string, inputConfigurationUrl: string, lastUpdateUtcDate: string, links: record, stepName: string, steps: record, success: bool, totalProductCount: int, totalProductErrorCount: int, totalProductSuccessCount: int, userId: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, start: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: Importation_GetReportings
export def "importation-get-reportings" [
  store_id: string
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
    path: "/v2/user/catalogs/{storeId}/importations"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start Manual Import
#
# POST /v2/user/catalogs/{storeId}/importations/start
# Returns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>
# operationId: Importation_StartManualUpdate
export def "importation-start-manual-update" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --duplicate-product-sku-configuration: record # Describe how you want to manage the duplication of the product value — shape: {compareOptions: "None"|"IgnoreCase"|"IgnoreNonSpace"|"IgnoreSymbols"|"OrdinalIgnoreCase"|"StringSort"|"Ordinal", strategy: "None"|"SkipAllDuplicateProducts"|"KeepFirstDuplicateProductOnly"|"FailImportationIfAnyDuplicateProduct"}
  input: record # Describe the input configuration — shape: {files: list, transformFileUrl?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/catalogs/{storeId}/importations/start"
    path_params: [{name: storeId, var: store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: duplicateProductSkuConfiguration, var: duplicate_product_sku_configuration}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, duplicate_product_sku_configuration: $duplicate_product_sku_configuration, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the importation status
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}
# Returns: record<beginUtcDate: string, errors: table<arguments: list, code: string, cultureName: string, docUrl: string, message: string>, executionId: string, lastUpdateUtcDate: string, links: record<activateAutoImport: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, cancel: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, catalogColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, commit: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, commitColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, configureRemainingCatalogColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, customColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, productSamples: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, technicalProgression: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, steps: record, success: bool, userId: string>
# operationId: Importation_GetImportationMonitoring
export def "importation-get-importation-monitoring" [
  store_id: string
  execution_id: string
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
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel importation
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/cancel
# operationId: Importation_Cancel
export def "importation-cancel" [
  store_id: string
  execution_id: string
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
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/cancel"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detected catalog columns during this importation.
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns
# Returns: record<detectedCatalogColumns: table<catalogColumnName: string, configuration: record, duplicateProductValueConfiguration: record, id: string, ignored: bool, links: record, userColumName: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: Importation_GetDetectedCatalogColumns
export def "importation-get-detected-catalog-columns" [
  store_id: string
  execution_id: string
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
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure catalog column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}
# operationId: Importation_ConfigureCatalogColumn
export def "importation-configure-catalog-column" [
  store_id: string
  execution_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  catalog_column: record # The catalog column configuration (e.g. {catalogColumnName: SKU, configuration: {beezUPColumnName: CategoryFirstLevel, canBeTruncated: false, columnCultureName: fr-FR, columnDataType: String, columnFormat: MM/dd/yyyy, columnImportance: Required, displayGroupName: Category}, duplicateProductValueConfiguration: {compareOptions: IgnoreCase, strategy: KeepFirstDuplicateProductOnly}, id: 8a76f06a-fefc-4c0d-bcfe-b210f1482977, ignored: true, userColumName: My SKU}) — shape: {catalogColumnName: string, configuration: record, duplicateProductValueConfiguration?: record, id: string, ignored?: bool, links: record, userColumName: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}, {name: columnId, var: column_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: catalogColumn, var: catalog_column}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id, column_id: $column_id, catalog_column: $catalog_column
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ignore Column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}/ignore
# operationId: Importation_IgnoreColumn
export def "importation-ignore-column" [
  store_id: string
  execution_id: string
  column_id: string
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
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}/ignore"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}, {name: columnId, var: column_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id, column_id: $column_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Map catalog column to a BeezUP column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}/map
# operationId: Importation_MapCatalogColumn
export def "importation-map-catalog-column" [
  store_id: string
  execution_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  beez_up_column_name: string # The BeezUP column name (e.g. CategoryFirstLevel)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}/map"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}, {name: columnId, var: column_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: beezUPColumnName, var: beez_up_column_name}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id, column_id: $column_id, beez_up_column_name: $beez_up_column_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reattend Column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}/reattend
# operationId: Importation_ReattendColumn
export def "importation-reattend-column" [
  store_id: string
  execution_id: string
  column_id: string
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
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}/reattend"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}, {name: columnId, var: column_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id, column_id: $column_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unmap catalog column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}/unmap
# operationId: Importation_UnmapCatalogColumn
export def "importation-unmap-catalog-column" [
  store_id: string
  execution_id: string
  column_id: string
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
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}/unmap"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}, {name: columnId, var: column_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id, column_id: $column_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Commit Importation
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/commit
# operationId: Importation_Commit
export def "importation-commit" [
  store_id: string
  execution_id: string
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
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/commit"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Commit columns
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/commitColumns
# operationId: Importation_CommitColumns
export def "importation-commit-columns" [
  store_id: string
  execution_id: string
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
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/commitColumns"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure remaining catalog columns
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/configureRemainingCatalogColumns
# operationId: Importation_ConfigureRemainingCatalogColumns
export def "importation-configure-remaining-catalog-columns" [
  store_id: string
  execution_id: string
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
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/configureRemainingCatalogColumns"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get custom columns currently place in this importation
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns
# Returns: record<customColumns: table<configuration: record, id: string, links: record, userColumName: string>, links: record<add: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: Importation_GetCustomColumns
export def "importation-get-custom-columns" [
  store_id: string
  execution_id: string
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
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/customColumns"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Custom Column
#
# DELETE /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}
# operationId: Importation_DeleteCustomColumn
export def "importation-delete-custom-column" [
  store_id: string
  execution_id: string
  column_id: string
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
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}, {name: columnId, var: column_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id, column_id: $column_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace a custom column
#
# PUT /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}
# operationId: Importation_SaveCustomColumn
export def "importation-save-custom-column" [
  store_id: string
  execution_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  encrypted_blockly_expression: string # The encrypted XML Blockly representation of the expression (e.g. apokpoa,opz,sixsoisiosnoisn)
  encrypted_expression: string # The encrypted excel expression of the column (e.g. uziushdczaniodnndonisodndsiondsoidsndoin)
  user_colum_name: string # Column named by the user (e.g. My SKU)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}, {name: columnId, var: column_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: encryptedBlocklyExpression, var: encrypted_blockly_expression}, {name: encryptedExpression, var: encrypted_expression}, {name: userColumName, var: user_colum_name}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id, column_id: $column_id, encrypted_blockly_expression: $encrypted_blockly_expression, encrypted_expression: $encrypted_expression, user_colum_name: $user_colum_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the encrypted custom column expression in this importation
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}/expression
# Returns: string
# operationId: Importation_GetCustomColumnExpression
export def "importation-get-custom-column-expression" [
  store_id: string
  execution_id: string
  column_id: string
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
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}/expression"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}, {name: columnId, var: column_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id, column_id: $column_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Map custom column to a BeezUP column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}/map
# operationId: Importation_MapCustomColumn
export def "importation-map-custom-column" [
  store_id: string
  execution_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  beez_up_column_name: string # The BeezUP column name (e.g. CategoryFirstLevel)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}/map"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}, {name: columnId, var: column_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: beezUPColumnName, var: beez_up_column_name}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id, column_id: $column_id, beez_up_column_name: $beez_up_column_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unmap custom column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}/unmap
# operationId: Importation_UnmapCustomColumn
export def "importation-unmap-custom-column" [
  store_id: string
  execution_id: string
  column_id: string
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
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}/unmap"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}, {name: columnId, var: column_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id, column_id: $column_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the product sample related to this importation with all columns (catalog and custom)
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/productSamples/{productSampleIndex}
# Returns: record<productValues: record>
# operationId: Importation_GetProductSample
export def "importation-get-product-sample" [
  store_id: string
  execution_id: string
  product_sample_index: int
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
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/productSamples/{productSampleIndex}"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}, {name: productSampleIndex, var: product_sample_index}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id, product_sample_index: $product_sample_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get product sample custom column value related to this importation.
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/productSamples/{productSampleIndex}/customColumns/{columnId}
# Returns: string
# operationId: Importation_GetProductSampleCustomColumnValue
export def "importation-get-product-sample-custom-column-value" [
  store_id: string
  execution_id: string
  product_sample_index: int
  column_id: string
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
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/productSamples/{productSampleIndex}/customColumns/{columnId}"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}, {name: productSampleIndex, var: product_sample_index}, {name: columnId, var: column_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id, product_sample_index: $product_sample_index, column_id: $column_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Importation Get Products Report
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/products/list
# Returns: record<paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>, productErrors: table<ean: string, errors: list, lineNumber: int, mpn: string, sku: string, title: string>>
# operationId: Importation_GetProductsReport
export def "importation-get-products-report" [
  store_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ean: string # Filter by EAN (equals)
  --error-codes: list # Get Importation Products Report Request Error Codes — item shape: {errorCode?: string, userColumnName?: string}
  --mpn: string # Filter by MPN (equals)
  page_number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  page_size: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
  --sku: string # Filter by Sku (equals)
  --title: string # Filter by Title (StartsWith)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/products/list"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ean, var: ean}, {name: errorCodes, var: error_codes}, {name: mpn, var: mpn}, {name: pageNumber, var: page_number}, {name: pageSize, var: page_size}, {name: sku, var: sku}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id, ean: $ean, error_codes: $error_codes, mpn: $mpn, page_number: $page_number, page_size: $page_size, sku: $sku, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Importation Get Report
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/report
# Returns: record<categories: record<createdCount: int, deletedCount: int, unchangedCount: int, updatedCount: int>, columns: record<createdCount: int, deletedCount: int, unchangedCount: int, updatedCount: int>, errors: table<beezUPColumnName: string, errorCode: string, productCount: int, userColumName: string>, executionId: string, importationInfo: record<beginUtcDate: string, endUtcDate: string, inputConfiguration: record<fetch: record, fileNumber: int, read: record>, userId: string>, productMetrics: record<activeCount: int, detectedCount: int, duplicatedCount: int, failedCount: int>, products: record<createdCount: int, deletedCount: int, unchangedCount: int, updatedCount: int>>
# operationId: Importation_GetReport
export def "importation-get-report" [
  store_id: string
  execution_id: string
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
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/report"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get technical progression
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/technicalProgression
# Returns: record<stepsProgression: record>
# operationId: Importation_TechnicalProgression
export def "importation-technical-progression" [
  store_id: string
  execution_id: string
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
    path: "/v2/user/catalogs/{storeId}/importations/{executionId}/technicalProgression"
    path_params: [{name: storeId, var: store_id}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the last input configuration
#
# GET /v2/user/catalogs/{storeId}/inputConfiguration
# Returns: record<input: record<files: list<record>, transformFileUrl: string>>
# operationId: Importation_GetManualUpdateLastInputConfig
export def "importation-get-manual-update-last-input-config" [
  store_id: string
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
    path: "/v2/user/catalogs/{storeId}/inputConfiguration"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get product by Sku
#
# GET /v2/user/catalogs/{storeId}/products
# Returns: record<categoryId: string, exists: bool, productId: string, values: record>
# operationId: Catalog_GetProductBySku
export def "catalog-get-product-by-sku" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sku: string # The product sku you want to get (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/catalogs/{storeId}/products"
    path_params: [{name: storeId, var: store_id}]
    query: [{name: sku, var: sku, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, sku: $sku
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get product list
#
# POST /v2/user/catalogs/{storeId}/products/list
# Returns: record<paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>, products: table<categoryId: string, exists: bool, productId: string, values: record>>
# operationId: Catalog_GetProducts
export def "catalog-get-products" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-path: list<string> # The catalog category path (e.g. [Vêtements, Femmes, Chaussures])
  --column-id-list: list<string>
  --ean: string # Search for product by ean (e.g. MySku123)
  --exists: oneof<nothing, bool> # Search for existing products or not. If null you will received both. (e.g. true)
  --mpn: string # Search for product by mpn (e.g. MySku123)
  --order-by-catalog-column-id: string # The catalog column identifier (catalog or custom column) (format: guid, e.g. bea7c21e-948b-4ac3-9ffd-4396e62c4163)
  page_number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  page_size: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
  --product-id-list: list<string> # Filter with a list of product identifier
  --sku: string # Search for product by sku (e.g. MySku123)
  --title: string # Search for products containing this title (e.g. Frigo)
  --without-sub-categories: oneof<nothing, bool> # Do not retrieve sub categories. By default, this value is set to false (e.g. false)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/catalogs/{storeId}/products/list"
    path_params: [{name: storeId, var: store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: categoryPath, var: category_path}, {name: columnIdList, var: column_id_list}, {name: ean, var: ean}, {name: exists, var: exists}, {name: mpn, var: mpn}, {name: orderByCatalogColumnId, var: order_by_catalog_column_id}, {name: pageNumber, var: page_number}, {name: pageSize, var: page_size}, {name: productIdList, var: product_id_list}, {name: sku, var: sku}, {name: title, var: title}, {name: withoutSubCategories, var: without_sub_categories}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, category_path: $category_path, column_id_list: $column_id_list, ean: $ean, exists: $exists, mpn: $mpn, order_by_catalog_column_id: $order_by_catalog_column_id, page_number: $page_number, page_size: $page_size, product_id_list: $product_id_list, sku: $sku, title: $title, without_sub_categories: $without_sub_categories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get random product list
#
# GET /v2/user/catalogs/{storeId}/products/random
# Returns: record<products: table<categoryId: string, exists: bool, productId: string, values: record>>
# operationId: Catalog_GetRandomProducts
export def "catalog-get-random-products" [
  store_id: string
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
    path: "/v2/user/catalogs/{storeId}/products/random"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get product by ProductId
#
# GET /v2/user/catalogs/{storeId}/products/{productId}
# Returns: record<categoryId: string, exists: bool, productId: string, values: record>
# operationId: Catalog_GetProductByProductId
export def "catalog-get-product-by-product-id" [
  store_id: string
  product_id: string
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
    path: "/v2/user/catalogs/{storeId}/products/{productId}"
    path_params: [{name: storeId, var: store_id}, {name: productId, var: product_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all your current channel catalogs
#
# GET /v2/user/channelCatalogs/
# Returns: record<channelCatalogs: record, links: record<add: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, beezUPColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, filterOperators: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<channelCatalogExclusionFilterOperatorLov: record<href: string, method: string>, channelCatalogExportCacheStatusLov: record<href: string, method: string>>>
# operationId: GetChannelCatalogs
export def "get-channel-catalogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # The store identifier (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/channelCatalogs/"
    query: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new channel catalog
#
# POST /v2/user/channelCatalogs/
# Returns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>
# operationId: AddChannelCatalog
export def "add-channel-catalog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_id: string # The channel identifier (format: guid, e.g. 2dc136a7-0d3d-4cc9-a825-a28a42c53e28)
  store_id: string # The store identifier (format: guid, e.g. 64f43358-63a1-47f7-97ec-0301fc39956b)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/channelCatalogs/"
    body: {content_type: "application/json", kind: json, fields: [{name: channelId, var: channel_id}, {name: storeId, var: store_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    channel_id: $channel_id, store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get channel catalog filter operators
#
# GET /v2/user/channelCatalogs/filterOperators
# Returns: table<expectedChannelColumnDataType: string, expectedValueDataType: string, name: string, valueRequired: bool>
# operationId: GetChannelCatalogFilterOperators
export def "get-channel-catalog-filter-operators" [
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
    path: "/v2/user/channelCatalogs/filterOperators"
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get channel catalog products related to these channel catalogs
#
# POST /v2/user/channelCatalogs/products
# Returns: record<channelCatalogs: record>
# operationId: GetChannelCatalogProductByChannelCatalog
export def "get-channel-catalog-product-by-channel-catalog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_catalog_ids: list<string> # The list of channel catalog identifier
  product_id: string # The product identifier (format: guid, e.g. 578419df-1bbf-41a6-96fa-862e42182b67)
  store_id: string # The store identifier (format: guid, e.g. 64f43358-63a1-47f7-97ec-0301fc39956b)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/channelCatalogs/products"
    body: {content_type: "application/json", kind: json, fields: [{name: channelCatalogIds, var: channel_catalog_ids}, {name: productId, var: product_id}, {name: storeId, var: store_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_ids: $channel_catalog_ids, product_id: $product_id, store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the channel catalog
#
# DELETE /v2/user/channelCatalogs/{channelCatalogId}
# operationId: DeleteChannelCatalog
export def "delete-channel-catalog" [
  channel_catalog_id: string
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
    path: "/v2/user/channelCatalogs/{channelCatalogId}"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the channel catalog information
#
# GET /v2/user/channelCatalogs/{channelCatalogId}
# Returns: record<channelId: string, channelImageUrl: string, channelName: string, categoryMappingSettings: record<categoryMappingDisabledByMerchant: bool>, channelCatalogId: string, channelCategorySettings: record<mappingLeafRequired: bool, mappingRequired: bool>, channelCostSettings: record<costType: string, globalCostValue: float>, columnMappings: table<catalogColumnId: string, channelCategoryPath: list, channelColumnId: string, catalogBeezUPColumnName: string, catalogColumnName: string, channelBeezUPColumnName: string, channelColumnName: string>, costSettings: record<costType: string, globalCostValue: float>, enabled: bool, exclusionFilters: table<channelColumnId: string, enabled: bool, groupId: string, name: string, operatorName: string, position: int, positionInGroup: int, value: string>, exportUrl: string, generalSettings: record<acceptToPublishInfo: bool, activeBeezUPTracking: bool, doNotExportOutOfStockProducts: bool>, isMarketplace: bool, links: record<categoryMappings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, channelInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, configureColumnMappings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, configureCostSettings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, configureGeneralSettings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, delete: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disableCategoryMappings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, exclusionFilters: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, exportationCacheInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, marketplaceSettings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, products: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reenableCategoryMappings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, state: record<apiSettingsStatus: string, categoryMappingState: record<status: string, uncategorizedProductCount: int, withoutCategoryCostProductCount: int>, columnMappingStatus: string, exportedProductCount: int>, storeId: string, types: list<string>>
# operationId: GetChannelCatalog
export def "get-channel-catalog" [
  channel_catalog_id: string
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
    path: "/v2/user/channelCatalogs/{channelCatalogId}"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get channel catalog categories
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/categories
# Returns: record<channelCatalogCategoryConfigurations: table<catalogCategoryPath: list, channelCategoryPath: list, costValue: float, links: record>, costStatus: string, links: record<disable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reenable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, mappingStatus: string>
# operationId: GetChannelCatalogCategories
export def "get-channel-catalog-categories" [
  channel_catalog_id: string
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
    path: "/v2/user/channelCatalogs/{channelCatalogId}/categories"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure channel catalog category
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/categories/configure
# operationId: ConfigureChannelCatalogCategory
export def "configure-channel-catalog-category" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_catalog_categories: list # item shape: {autoMapNewSubCategories: bool, catalogCategoryPath: list<string>, channelCategoryPath?: list<string>, costValue?: float}
  --override-sub-category-mappings: oneof<nothing, bool> # Great feature! In case of mapping to parent channel category, you can ask to override the mapping of all sub channel category to this catalog category path (e.g. true)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/channelCatalogs/{channelCatalogId}/categories/configure"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: channelCatalogCategories, var: channel_catalog_categories}, {name: overrideSubCategoryMappings, var: override_sub_category_mappings, required: true}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id, channel_catalog_categories: $channel_catalog_categories, override_sub_category_mappings: $override_sub_category_mappings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a channel catalog category mapping
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/categories/disableMapping
# operationId: DisableChannelCatalogCategoryMapping
export def "disable-channel-catalog-category-mapping" [
  channel_catalog_id: string
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
    path: "/v2/user/channelCatalogs/{channelCatalogId}/categories/disableMapping"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reenable a channel catalog category mapping
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/categories/reenableMapping
# operationId: ReenableChannelCatalogCategoryMapping
export def "reenable-channel-catalog-category-mapping" [
  channel_catalog_id: string
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
    path: "/v2/user/channelCatalogs/{channelCatalogId}/categories/reenableMapping"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure channel catalog column mappings
#
# PUT /v2/user/channelCatalogs/{channelCatalogId}/columnMappings
# operationId: ConfigureChannelCatalogColumnMappings
export def "configure-channel-catalog-column-mappings" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/user/channelCatalogs/{channelCatalogId}/columnMappings"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a channel catalog
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/disable
# operationId: DisableChannelCatalog
export def "disable-channel-catalog" [
  channel_catalog_id: string
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
    path: "/v2/user/channelCatalogs/{channelCatalogId}/disable"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a channel catalog
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/enable
# operationId: EnableChannelCatalog
export def "enable-channel-catalog" [
  channel_catalog_id: string
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
    path: "/v2/user/channelCatalogs/{channelCatalogId}/enable"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get channel catalog exclusion filters
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/exclusionFilters
# Returns: record<exclusionFilters: table<channelColumnId: string, enabled: bool, groupId: string, name: string, operatorName: string, position: int, positionInGroup: int, value: string>, links: record<configure: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: GetChannelCatalogExclusionFilters
export def "get-channel-catalog-exclusion-filters" [
  channel_catalog_id: string
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
    path: "/v2/user/channelCatalogs/{channelCatalogId}/exclusionFilters"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure channel catalog exclusion filters
#
# PUT /v2/user/channelCatalogs/{channelCatalogId}/exclusionFilters
# operationId: ConfigureChannelCatalogExclusionFilters
export def "configure-channel-catalog-exclusion-filters" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/user/channelCatalogs/{channelCatalogId}/exclusionFilters"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the exportation cache information
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/exportations/cache
# Returns: record<cacheInfo: record<cacheStatus: string, expirationUtcDate: string, feedUrl: string, lastContentChangeUtcDate: string, lastUpdateUtcDate: string>, links: record<clear: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: GetChannelCatalogExportationCacheInfo
export def "get-channel-catalog-exportation-cache-info" [
  channel_catalog_id: string
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
    path: "/v2/user/channelCatalogs/{channelCatalogId}/exportations/cache"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear the exportation cache
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/exportations/cache/clear
# operationId: ClearChannelCatalogExportationCache
export def "clear-channel-catalog-exportation-cache" [
  channel_catalog_id: string
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
    path: "/v2/user/channelCatalogs/{channelCatalogId}/exportations/cache/clear"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the exportation history
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/exportations/history
# Returns: record<exportations: table<cacheStatus: string, clientIpAddress: string, clientUserAgent: string, exportationDuration: string, exportationUtcDate: string, exportedProductCount: int>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>
# operationId: GetChannelCatalogExportationHistory
export def "get-channel-catalog-exportation-history" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number you want to get (required, format: int32, e.g. 1)
  --page-size: int # The entry count you want to get (required, format: int32, e.g. 25)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/channelCatalogs/{channelCatalogId}/exportations/history"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    query: [{name: pageNumber, var: page_number, required: true}, {name: pageSize, var: page_size, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get channel catalog product information list
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/products
# Returns: record<links: record<export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>, productInfos: table<productExists: bool, productId: string, productImageUrl: string, productSku: string, productTitle: string, disabled: bool, excluded: bool, excludedBy: list, links: record, overrides: record, uncategorized: bool>>
# operationId: GetChannelCatalogProductInfoList
export def "get-channel-catalog-product-info-list" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalog-category-filter: record # shape: {categoryPath?: list<string>}
  --channel-category-filter: record # shape: {categoryPath?: list<string>}
  criteria: record # shape: {disabled?: bool, excluded?: bool, exist?: bool, logic: "funnel"|"cumulative", uncategorized?: bool}
  --overridden: oneof<nothing, bool> # Search overridden products. If null the filter will not be taken in account. (e.g. true)
  page_number: int # format: int32, e.g. 1
  page_size: int # format: int32, e.g. 100
  --product-filters: record # shape: {additionalProductFilters?: record, catalogEans?: list<string>, catalogMpns?: list<string>, catalogSkus?: list<string>, channelEans?: list<string>, channelMpns?: list<string>, channelSkus?: list<string>, title?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/channelCatalogs/{channelCatalogId}/products"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: catalogCategoryFilter, var: catalog_category_filter}, {name: channelCategoryFilter, var: channel_category_filter}, {name: criteria, var: criteria}, {name: overridden, var: overridden}, {name: pageNumber, var: page_number}, {name: pageSize, var: page_size}, {name: productFilters, var: product_filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id, catalog_category_filter: $catalog_category_filter, channel_category_filter: $channel_category_filter, criteria: $criteria, overridden: $overridden, page_number: $page_number, page_size: $page_size, product_filters: $product_filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get channel catalog products' counters
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/products/counters
# Returns: record<disabledProductCountExcludingUncategorized: int, disabledProductCountIncludingUncategorized: int, excludedProductCountExcludingUncategorizedAndDisabled: int, excludedProductCountIncludingUncategorizedAndDisabled: int, existingProductCount: int, uncategorizedProductCount: int>
# operationId: GetChannelCatalogProductsCounters
export def "get-channel-catalog-products-counters" [
  channel_catalog_id: string
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
    path: "/v2/user/channelCatalogs/{channelCatalogId}/products/counters"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export channel catalog product information list
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/products/export
# Returns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>
# operationId: ExportChannelCatalogProductInfoList
export def "export-channel-catalog-product-info-list" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # The file type of the exportation (required)
  --catalog-category-filter: record # shape: {categoryPath?: list<string>}
  --channel-category-filter: record # shape: {categoryPath?: list<string>}
  criteria: record # shape: {disabled?: bool, excluded?: bool, exist?: bool, logic: "funnel"|"cumulative", uncategorized?: bool}
  --overridden: oneof<nothing, bool> # Search overridden products. If null the filter will not be taken in account. (e.g. true)
  page_number: int # format: int32, e.g. 1
  page_size: int # format: int32, e.g. 100
  --product-filters: record # shape: {additionalProductFilters?: record, catalogEans?: list<string>, catalogMpns?: list<string>, catalogSkus?: list<string>, channelEans?: list<string>, channelMpns?: list<string>, channelSkus?: list<string>, title?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/channelCatalogs/{channelCatalogId}/products/export"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    query: [{name: format, var: format, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: catalogCategoryFilter, var: catalog_category_filter}, {name: channelCategoryFilter, var: channel_category_filter}, {name: criteria, var: criteria}, {name: overridden, var: overridden}, {name: pageNumber, var: page_number}, {name: pageSize, var: page_size}, {name: productFilters, var: product_filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id, format: $format, catalog_category_filter: $catalog_category_filter, channel_category_filter: $channel_category_filter, criteria: $criteria, overridden: $overridden, page_number: $page_number, page_size: $page_size, product_filters: $product_filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get channel catalog product information
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}
# Returns: record<productExists: bool, productId: string, productImageUrl: string, productSku: string, productTitle: string, disabled: bool, excluded: bool, excludedBy: list<string>, links: record<disable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, override: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reenable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, overrides: record, uncategorized: bool>
# operationId: GetChannelCatalogProductInfo
export def "get-channel-catalog-product-info" [
  channel_catalog_id: string
  product_id: string
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
    path: "/v2/user/channelCatalogs/{channelCatalogId}/products/{productId}"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}, {name: productId, var: product_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id, product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable channel catalog product
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/disable
# operationId: DisableChannelCatalogProduct
export def "disable-channel-catalog-product" [
  channel_catalog_id: string
  product_id: string
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
    path: "/v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/disable"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}, {name: productId, var: product_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id, product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Override channel catalog product values
#
# PUT /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/overrides
# operationId: OverrideChannelCatalogProductValues
export def "override-channel-catalog-product-values" [
  channel_catalog_id: string
  product_id: string
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
    method: put
    path: "/v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/overrides"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}, {name: productId, var: product_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id, product_id: $product_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get channel catalog product value override compatibilities status
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/overrides/copy
# operationId: GetChannelCatalogProductValueOverrideCopy
export def "get-channel-catalog-product-value-override-copy" [
  channel_catalog_id: string
  product_id: string
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
    path: "/v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/overrides/copy"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}, {name: productId, var: product_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id, product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copy channel catalog product value override
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/overrides/copy
# operationId: ConfigureChannelCatalogProductValueOverrideCopy
export def "configure-channel-catalog-product-value-override-copy" [
  channel_catalog_id: string
  product_id: string
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
    path: "/v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/overrides/copy"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}, {name: productId, var: product_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id, product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific channel catalog product value override
#
# DELETE /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/overrides/{channelColumnId}
# operationId: DeleteChannelCatalogProductValueOverride
export def "delete-channel-catalog-product-value-override" [
  channel_catalog_id: string
  product_id: string
  channel_column_id: string
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
    path: "/v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/overrides/{channelColumnId}"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}, {name: productId, var: product_id}, {name: channelColumnId, var: channel_column_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id, product_id: $product_id, channel_column_id: $channel_column_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reenable channel catalog product
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/reenable
# operationId: ReenableChannelCatalogProduct
export def "reenable-channel-catalog-product" [
  channel_catalog_id: string
  product_id: string
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
    path: "/v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/reenable"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}, {name: productId, var: product_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id, product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure channel catalog cost settings
#
# PUT /v2/user/channelCatalogs/{channelCatalogId}/settings/cost
# operationId: ConfigureChannelCatalogCostSettings
export def "configure-channel-catalog-cost-settings" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  cost_type: string@cost-type-completer # CPC means cost per click. CPA means cost per action. You can have CPC/CPA with a global cost value. You can have CPC/CPA by category the cost value MUST be null You can have global fixed price. (e.g. Fixed_Global)
  --global-cost-value: float # In case of global cost type, you have to indicate the cost value. (format: decimal, e.g. 10.21)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/user/channelCatalogs/{channelCatalogId}/settings/cost"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: costType, var: cost_type}, {name: globalCostValue, var: global_cost_value}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id, cost_type: $cost_type, global_cost_value: $global_cost_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure channel catalog general settings
#
# PUT /v2/user/channelCatalogs/{channelCatalogId}/settings/general
# operationId: ConfigureChannelCatalogGeneralSettings
export def "configure-channel-catalog-general-settings" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-to-publish-info: oneof<nothing, bool> # If true then you authorize disclosure of my statistics generated from clicks and sales (e.g. true)
  --active-beez-up-tracking: oneof<nothing, bool> # Activate BeezUP tracking for my statistics (checked by default) (default: true, e.g. true)
  --do-not-export-out-of-stock-products: oneof<nothing, bool> # Do not export "out of stock" products. Note: this option is not taken into account by the counter. (e.g. true)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/user/channelCatalogs/{channelCatalogId}/settings/general"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: acceptToPublishInfo, var: accept_to_publish_info, required: true}, {name: activeBeezUPTracking, var: active_beez_up_tracking, required: true}, {name: doNotExportOutOfStockProducts, var: do_not_export_out_of_stock_products, required: true}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id, accept_to_publish_info: $accept_to_publish_info, active_beez_up_tracking: $active_beez_up_tracking, do_not_export_out_of_stock_products: $do_not_export_out_of_stock_products
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all available channel for this store
#
# GET /v2/user/channels/
# Returns: table<channelId: string, channelLogoUrl: string, channelName: string, links: record<self: record>, types: list<string>>
# operationId: GetAvailableChannels
export def "get-available-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # The store identifier (required, format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/channels/"
    query: [{name: storeId, var: store_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get channel information
#
# GET /v2/user/channels/{channelId}
# Returns: record<beezUPOffer: string, channelDescription: string, channelId: string, channelLogoUrl: string, channelName: string, details: record<businessModel: string, category: string, channelType: string, costs: string, homeUrl: string, subscriptionLink: string, trackingType: string>, keyNumbers: record<categories: string, products: string, stores: string, viewsPerMonth: string>, salesContact: record<email: string, name: string, phoneNumber: string>, technicalContact: record<email: string, name: string, phoneNumber: string>>
# operationId: GetChannelInfo
export def "get-channel-info" [
  channel_id: string
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
    path: "/v2/user/channels/{channelId}"
    path_params: [{name: channelId, var: channel_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get channel categories
#
# GET /v2/user/channels/{channelId}/categories
# Returns: record<firstLevelCategories: table<channelCategoryChannelCode: string, channelCategoryColumnOverrides: record, channelCategoryDefaultCost: float, channelCategoryId: string, channelCategoryLevel: int, channelCategoryName: string, subCategories: list>>
# operationId: GetChannelCategories
export def "get-channel-categories" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: list<string> # Indicates that the client accepts that the response will be compressed to reduce traffic size. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/channels/{channelId}/categories"
    path_params: [{name: channelId, var: channel_id}]
    header: [{name: Accept-Encoding, var: accept_encoding, array: true, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    channel_id: $channel_id, accept_encoding: $accept_encoding
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get channel columns
#
# POST /v2/user/channels/{channelId}/columns
# Returns: table<channelColumnDescription: string, channelColumnId: string, channelColumnName: string, configuration: record<beezUPColumnName: string, columnDataType: string, columnImportance: string>, position: int, restrictedValues: record, showInMapping: bool>
# operationId: GetChannelColumns
export def "get-channel-columns" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: list<string> # Indicates that the client accepts that the response will be compressed to reduce traffic size. (required)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/channels/{channelId}/columns"
    path_params: [{name: channelId, var: channel_id}]
    header: [{name: Accept-Encoding, var: accept_encoding, array: true, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    channel_id: $channel_id, accept_encoding: $accept_encoding, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The index of all operations and LOV
#
# GET /v2/user/customer/
# Returns: record<links: record<accountInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, billingPeriods: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, contracts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, friendInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, getOffer: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, invoices: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, logout: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, standardOffers: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, stores: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<activeOfferLov: record<href: string, method: string>, beezUPTimeZoneLov: record<href: string, method: string>, contractTerminationReasonLov: record<href: string, method: string>, countryLov: record<href: string, method: string>, customerStatusLov: record<href: string, method: string>, invoicePaymentStatusLov: record<href: string, method: string>, offerLov: record<href: string, method: string>, storeCountryLov: record<href: string, method: string>, storeSectorLov: record<href: string, method: string>>>
# operationId: GetCustomerIndex
export def "get-customer-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/customer/"
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user account information
#
# GET /v2/user/customer/account
# Returns: record<commercialOwnerEmail: string, companyInfo: record<accountingEmails: list<string>, address: string, city: string, company: string, countryIsoCodeAlpha3: string, postalCode: string, vatNumber: string>, email: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<activateUserAccount: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, changeEmail: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, changePassword: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, getCreditCardInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, getProfilePictureInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, saveCompanyInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, saveCreditCardInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, savePersonalInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, saveProfilePictureInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, personalInfo: record<beezUPTimeZoneId: int, firstName: string, lastName: string, phoneNumber: string, whatIDo: string>, profilePictureUrl: string, status: string, userId: string>
# operationId: GetUserAccountInfo
export def "get-user-account-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/customer/account"
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate the user account
#
# POST /v2/user/customer/account/activate
# operationId: ActivateUserAccount
export def "activate-user-account" [
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
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/customer/account/activate"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change user email
#
# POST /v2/user/customer/account/changeEmail
# operationId: ChangeEmail
export def "change-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  new_email: string # The email (format: email, e.g. paulsimon@mysupercompany.com)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/customer/account/changeEmail"
    body: {content_type: "application/json", kind: json, fields: [{name: newEmail, var: new_email}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    new_email: $new_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change user password
#
# POST /v2/user/customer/account/changePassword
# operationId: ChangePassword
export def "change-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  new_password: string # Your new password. Which must respect the same constraints as the user registeration (format: password)
  old_password: string # Your current password (format: password)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/customer/account/changePassword"
    body: {content_type: "application/json", kind: json, fields: [{name: newPassword, var: new_password}, {name: oldPassword, var: old_password}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    new_password: $new_password, old_password: $old_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change company information
#
# PUT /v2/user/customer/account/companyInfo
# operationId: SaveCompanyInfo
export def "save-company-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accounting-emails: list<string> # Your company accounting emails (e.g. [myaccountemail@mysupercompany.com])
  address: string # Your address (e.g. 21 jump street)
  city: string # Your address city (e.g. New-York)
  company: string # Your company name (e.g. My super company)
  country_iso_code_alpha3: string # The country iso code alpha 3 (ISO 3166-1_alpha-3) (https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3) (e.g. FRA)
  postal_code: string # Your address postal code (e.g. 13014)
  --vat-number: string # Your company VATNumber. Used for french company. This number is checked with official web service before being saved. (e.g. 1234567890)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/user/customer/account/companyInfo"
    body: {content_type: "application/json", kind: json, fields: [{name: accountingEmails, var: accounting_emails}, {name: address, var: address}, {name: city, var: city}, {name: company, var: company}, {name: countryIsoCodeAlpha3, var: country_iso_code_alpha3}, {name: postalCode, var: postal_code}, {name: vatNumber, var: vat_number}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    accounting_emails: $accounting_emails, address: $address, city: $city, company: $company, country_iso_code_alpha3: $country_iso_code_alpha3, postal_code: $postal_code, vat_number: $vat_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get credit card information
#
# GET /v2/user/customer/account/creditCardInfo
# Returns: record<creditCardInfo: record<cardNumber: string, cardType: string, expirationMonth: int, expirationYear: int>, currentPaymentMethod: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<saveCreditCardInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: GetCreditCardInfo
export def "get-credit-card-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/customer/account/creditCardInfo"
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save user credit card info
#
# PUT /v2/user/customer/account/creditCardInfo
# operationId: SaveCreditCardInfo
export def "save-credit-card-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  card_number: string # Card number (e.g. 1234567890091234)
  card_verification_code: string # Card Verification Code (e.g. 123)
  expiration_month: int # Expiration Month (format: int32, e.g. 12)
  expiration_year: int # Expiration Year (format: int32, e.g. 2017)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/user/customer/account/creditCardInfo"
    body: {content_type: "application/json", kind: json, fields: [{name: cardNumber, var: card_number}, {name: cardVerificationCode, var: card_verification_code}, {name: expirationMonth, var: expiration_month}, {name: expirationYear, var: expiration_year}]}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    card_number: $card_number, card_verification_code: $card_verification_code, expiration_month: $expiration_month, expiration_year: $expiration_year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save user personal information
#
# PUT /v2/user/customer/account/personalInfo
# operationId: SavePersonalInfo
export def "save-personal-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  beez_up_time_zone_id: int # The time zone identifier based on the list of values /v2/user/lov/BeezUPTimeZone (format: int32, e.g. 79)
  first_name: string # Your first name (e.g. Paul)
  last_name: string # Your last name (e.g. Simon)
  phone_number: string # Your phone number (e.g. 5551234)
  --what-i-do: string # Your role in your company (e.g. I'm the Manager on this company)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/user/customer/account/personalInfo"
    body: {content_type: "application/json", kind: json, fields: [{name: beezUPTimeZoneId, var: beez_up_time_zone_id}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: phoneNumber, var: phone_number}, {name: whatIDo, var: what_i_do}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    beez_up_time_zone_id: $beez_up_time_zone_id, first_name: $first_name, last_name: $last_name, phone_number: $phone_number, what_i_do: $what_i_do
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get profile picture information
#
# GET /v2/user/customer/account/profilePictureInfo
# Returns: record<links: record<save: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, profilePictureInfo: record<profilePictureSelected: string, profilePictureUrl: string, gravatarProfilePictureUrl: string, initialsProfilePictureUrl: string>>
# operationId: GetProfilePictureInfo
export def "get-profile-picture-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/customer/account/profilePictureInfo"
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change user picture information
#
# PUT /v2/user/customer/account/profilePictureInfo
# operationId: SaveProfilePictureInfo
export def "save-profile-picture-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  profile_picture_selected: string@profile-picture-selected-completer # Your profile picture choice about usage of gravatar picture, initials picture or uploaded picture. (e.g. initials)
  --profile-picture-url: string # Indicate the url of your picture profil (e.g. https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Marlon_Brando_%28cropped%29.jpg/220px-Marlon_Brando_%28cropped%29.jpg)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/user/customer/account/profilePictureInfo"
    body: {content_type: "application/json", kind: json, fields: [{name: profilePictureSelected, var: profile_picture_selected}, {name: profilePictureUrl, var: profile_picture_url}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    profile_picture_selected: $profile_picture_selected, profile_picture_url: $profile_picture_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend email activation
#
# POST /v2/user/customer/account/resendEmailActivation
# operationId: ResendEmailActivation
export def "resend-email-activation" [
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
    path: "/v2/user/customer/account/resendEmailActivation"
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get billing periods conditions
#
# GET /v2/user/customer/billingPeriods
# Returns: record<billingPeriods: table<billingPeriodInMonth: int, discountPercentage: float>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: GetBillingPeriods
export def "get-billing-periods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/customer/billingPeriods"
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get contract list
#
# GET /v2/user/customer/contracts
# Returns: record<current: record<additionalClickPrice: float, billingPeriodInMonth: int, billingPeriodPercentDiscount: float, clickIncluded: int, commitmentCalculatedFinishUtcDate: string, commitmentPeriodInMonth: int, contractId: string, currencyCode: string, discountDurationInMonth: int, discountEndUtcDate: string, fixedAndVariableClickInfo: record<clickIncludedAndAdditionalClickPrices: list>, fixedPrice: float, ipUserCreation: string, ipUserModification: string, isCommitmentRenewalAutomatically: bool, isModifiableContract: bool, offerId: int, offerName: string, percentDiscount: float, startUtcDate: string, storeCount: int, trialPeriodInMonth: int, variableModelInfo: record<clickIncludedAndVariablePrices: list, overflowClickCount: int, overflowClickPrice: float>, links: record<disable: record, reenable: record>>, links: record<create: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, next: record<additionalClickPrice: float, billingPeriodInMonth: int, billingPeriodPercentDiscount: float, clickIncluded: int, commitmentCalculatedFinishUtcDate: string, commitmentPeriodInMonth: int, contractId: string, currencyCode: string, discountDurationInMonth: int, discountEndUtcDate: string, fixedAndVariableClickInfo: record<clickIncludedAndAdditionalClickPrices: list>, fixedPrice: float, ipUserCreation: string, ipUserModification: string, isCommitmentRenewalAutomatically: bool, isModifiableContract: bool, offerId: int, offerName: string, percentDiscount: float, startUtcDate: string, storeCount: int, trialPeriodInMonth: int, variableModelInfo: record<clickIncludedAndVariablePrices: list, overflowClickCount: int, overflowClickPrice: float>, links: record<delete: record>>>
# operationId: GetContracts
export def "get-contracts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/customer/contracts"
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new contract
#
# POST /v2/user/customer/contracts
# Returns: record<info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<contracts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: CreateContract
export def "create-contract" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  billing_period_in_month: int # Can be null. The billing period in month based on /billingPeriods (format: int32, e.g. 12)
  --coupon-discount-code: string # The coupon discount code (e.g. I-LOVE-BEEZUP)
  --coupon-offer-code: string # Your special coupon offer identifier (format: guid, e.g. 04efc310-bc25-4710-a83a-faf200284fe5)
  offer_id: int # The offer id based on /offers. Not a free offer of course. (format: int32, e.g. 1)
  store_count: int # The store count you want to have in your contract. (format: int32, e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/customer/contracts"
    body: {content_type: "application/json", kind: json, fields: [{name: billingPeriodInMonth, var: billing_period_in_month}, {name: couponDiscountCode, var: coupon_discount_code}, {name: couponOfferCode, var: coupon_offer_code}, {name: offerId, var: offer_id}, {name: storeCount, var: store_count}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    billing_period_in_month: $billing_period_in_month, coupon_discount_code: $coupon_discount_code, coupon_offer_code: $coupon_offer_code, offer_id: $offer_id, store_count: $store_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Schedule termination of your current contract at the end of the commitment.
#
# POST /v2/user/customer/contracts/current/disableAutoRenewal
# operationId: TerminateCurrentContract
export def "terminate-current-contract" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contract-termination-reason: string # The termination reason, if your current contract is scheduled to be terminated. (e.g. I'm crazy, I want to leave your splendid service...)
  contract_termination_reason_type: int # The contract termination reason type identifier, if your current contract is scheduled to be terminated. The value is based on the list of values /user/lov/ContractTerminationReason (format: int32, e.g. 1)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/customer/contracts/current/disableAutoRenewal"
    body: {content_type: "application/json", kind: json, fields: [{name: contractTerminationReason, var: contract_termination_reason}, {name: contractTerminationReasonType, var: contract_termination_reason_type}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    contract_termination_reason: $contract_termination_reason, contract_termination_reason_type: $contract_termination_reason_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reactivate your terminated contract.
#
# POST /v2/user/customer/contracts/current/reenableAutoRenewal
# operationId: ReactivateCurrentContract
export def "reactivate-current-contract" [
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
    path: "/v2/user/customer/contracts/current/reenableAutoRenewal"
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete your next contract
#
# DELETE /v2/user/customer/contracts/next
# operationId: DeleteNextContract
export def "delete-next-contract" [
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
    path: "/v2/user/customer/contracts/next"
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get friend information
#
# GET /v2/user/customer/friends/{userId}
# Returns: record<company: string, countryIsoCodeAlpha3: string, email: string, firstName: string, lastName: string, profilePictureUrl: string, userId: string, whatIDo: string>
# operationId: GetFriendInfo
export def "get-friend-info" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/customer/friends/{userId}"
    path_params: [{name: userId, var: user_id}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    user_id: $user_id, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all your invoices
#
# GET /v2/user/customer/invoices
# Returns: record<invoices: table<amount: float, amountToBePaid: float, contractId: string, currencyCode: string, dueDate: string, invoiceDate: string, invoiceNumber: string, invoiceUrl: string, paymentStatus: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: GetInvoices
export def "get-invoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/customer/invoices"
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all standard offers
#
# GET /v2/user/customer/offers
# Returns: record<functionalities: table<code: string, order: int>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, offers: table<additionalClickPrice: float, currencyCode: string, fixedPrice: float, functionalities: list, includedClick: int, isMostPopular: bool, isOldOffer: bool, links: record, name: string, offerId: int, position: int>>
# operationId: GetStandardOffers
export def "get-standard-offers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/customer/offers"
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get offer pricing
#
# POST /v2/user/customer/offers
# Returns: record<content: record<contractBillingPeriodInfo: record<amountBillingPeriodDiscount: float, billingPeriodInMonth: int, billingPeriodPercentDiscount: float>, contractBonusInfo: record<bonuses: list>, contractClickInfo: record<additionalClickPrice: float, clickIncluded: int, initialOfferClickIncluded: int>, contractCommitmentInfo: record<commercialCreatorUserId: string, commercialUserId: string, commitmentCalculatedFinishDate: string, commitmentPeriodInMonth: int, contractType: int, couponOfferCode: string, currentContractId: string, currentContractTerminationDate: string, currentCustomerPaymentMethod: string, fixedAndVariableClickInfo: record, isCustomerWantsToTerminateHisContract: bool, isModelMustBeTransmittedInNewContract: bool, minBillingPeriodInMonths: int, model: string, newContractStartDate: string, offerId: int, offerName: string, paymentDelayInDays: int, paymentMethodAuthorized: string, requestedPaymentMethod: string, trialPeriodFinishDate: string, trialPeriodInMonth: int, variableModelInfo: record>, contractDiscountInfo: record<amountCodePromoDiscount: float, amountCodePromoDiscountPerMonth: float, couponDiscountCode: string, couponDiscountId: int, customerHasActualDiscount: bool, discountDurationInMonth: int, isCouponDiscountLinkedToCouponOffer: bool, percentDiscount: float, promotionalCodeValidity: string>, contractMoneyInfo: record<amountExcludingTaxesAndExcludingCodePromoDiscountIncludingBillingPeriodDiscount: float, amountExcludingTaxesAndExcludingDiscounts: float, amountExcludingTaxesIncludingDiscounts: float, amountExcludingTaxesIncludingDiscountsPerMonth: float, amountIncludingTaxesExcludingDiscountIncludingBillingPeriodDiscount: float, amountIncludingTaxesIncludingDiscounts: float, amountTaxesExcludingDiscountIncludingBillingPeriodDiscount: float, amountTaxesIncludingDiscounts: float, currencyCode: string, initialOfferFixedPrice: float, vatPercent: float>, contractStoreInfo: record<additionalStorePrice: float, maxStoreCount: int, minStoreCount: int, ownedStoreCount: int, storeCount: int, storeIncluded: int>, contractTerminationReason: string, contractTerminationReasonType: int, notifyVatExemption: bool, previousFixPeriodInvoiceProrataInfo: record<amountAfterTax: float, amountToBePaid: float, computedProrataToBeDeducted: float, contractId: string, fixedPeriodEndDate: string, fixedPeriodStartDate: string, invoiceNumber: string>>, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<createContract: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: GetOffer
export def "get-offer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  billing_period_in_month: int # Can be null. The billing period in month based on /billingPeriods (format: int32, e.g. 12)
  --coupon-discount-code: string # The coupon discount code (e.g. I-LOVE-BEEZUP)
  --coupon-offer-code: string # Your special coupon offer identifier (format: guid, e.g. 04efc310-bc25-4710-a83a-faf200284fe5)
  offer_id: int # The offer id based on /offers. Not a free offer of course. (format: int32, e.g. 1)
  store_count: int # The store count you want to have in your contract. (format: int32, e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/customer/offers"
    body: {content_type: "application/json", kind: json, fields: [{name: billingPeriodInMonth, var: billing_period_in_month}, {name: couponDiscountCode, var: coupon_discount_code}, {name: couponOfferCode, var: coupon_offer_code}, {name: offerId, var: offer_id}, {name: storeCount, var: store_count}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    billing_period_in_month: $billing_period_in_month, coupon_discount_code: $coupon_discount_code, coupon_offer_code: $coupon_offer_code, offer_id: $offer_id, store_count: $store_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Log out the current user from go2
#
# POST /v2/user/customer/security/logout
# operationId: Logout
export def "logout" [
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
    path: "/v2/user/customer/security/logout"
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get store list
#
# GET /v2/user/customer/stores
# Returns: record<links: record<createStore: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, stores: table<countryIsoCodeAlpha3: string, creationUtcDate: string, currencyCode: string, goVersion: int, isTest: bool, links: record, name: string, offerId: int, offerName: string, ownerUserId: string, sectors: list, shareCount: int, status: string, storeId: string, url: string, userRole: string>>
# operationId: GetStores
export def "get-stores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/customer/stores"
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new store
#
# POST /v2/user/customer/stores
# Returns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>
# operationId: CreateStore
export def "create-store" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  country_iso_code_alpha3: string # The country iso code alpha 3 based on the list of values /user/lov/StoreCountry (e.g. DEU)
  --id: string # The store identifier (format: guid, e.g. 64f43358-63a1-47f7-97ec-0301fc39956b)
  name: string # The store name. Must be unique. (e.g. My Store)
  sectors: list<string> # The store's sectors based on the list of values /user/lov/ParamSector (e.g. [ANIMALERIE, AUTOMOTO])
  url: string # The url of your store (e.g. http://www.mystore.com)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/customer/stores"
    body: {content_type: "application/json", kind: json, fields: [{name: countryIsoCodeAlpha3, var: country_iso_code_alpha3}, {name: id, var: id}, {name: name, var: name}, {name: sectors, var: sectors}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    country_iso_code_alpha3: $country_iso_code_alpha3, id: $id, name: $name, sectors: $sectors, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a store
#
# DELETE /v2/user/customer/stores/{storeId}
# operationId: DeleteStore
export def "delete-store" [
  store_id: string
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
    path: "/v2/user/customer/stores/{storeId}"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get store's information
#
# GET /v2/user/customer/stores/{storeId}
# Returns: record<countryIsoCodeAlpha3: string, creationUtcDate: string, currencyCode: string, goVersion: int, isTest: bool, links: record<deleteStore: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, share: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, shares: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, updateStore: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, name: string, offerId: int, offerName: string, ownerUserId: string, sectors: list<string>, shareCount: int, status: string, storeId: string, url: string, userRole: string>
# operationId: GetStore
export def "get-store" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/customer/stores/{storeId}"
    path_params: [{name: storeId, var: store_id}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update some store's information.
#
# PATCH /v2/user/customer/stores/{storeId}
# operationId: UpdateStore
export def "update-store" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The store name. Must be unique. (e.g. My Store)
  sectors: list<string> # The store's sectors based on the list of values /user/lov/ParamSector (e.g. [ANIMALERIE, AUTOMOTO])
  url: string # The url of your store (e.g. http://www.mystore.com)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v2/user/customer/stores/{storeId}"
    path_params: [{name: storeId, var: store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: sectors, var: sectors}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, name: $name, sectors: $sectors, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get store's alerts
#
# GET /v2/user/customer/stores/{storeId}/alerts
# Returns: record<alerts: table<alertId: int, alertName: string, enabled: bool, links: record, properties: list>>
# operationId: GetStoreAlerts
export def "get-store-alerts" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/customer/stores/{storeId}/alerts"
    path_params: [{name: storeId, var: store_id}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save store alerts
#
# POST /v2/user/customer/stores/{storeId}/alerts
# operationId: SaveStoreAlerts
export def "save-store-alerts" [
  store_id: string
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
    path: "/v2/user/customer/stores/{storeId}/alerts"
    path_params: [{name: storeId, var: store_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get store's rights
#
# GET /v2/user/customer/stores/{storeId}/rights
# Returns: table<functionalityCode: string, maxValueInterger: int, unlimited: bool>
# operationId: GetRights
export def "get-rights" [
  store_id: string
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
    path: "/v2/user/customer/stores/{storeId}/rights"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get shares related to this store
#
# GET /v2/user/customer/stores/{storeId}/shares
# Returns: record<links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, share: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, shares: table<links: record, userId: string, userRole: string>>
# operationId: GetStoreShares
export def "get-store-shares" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/customer/stores/{storeId}/shares"
    path_params: [{name: storeId, var: store_id}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Share a store to another user
#
# POST /v2/user/customer/stores/{storeId}/shares
# operationId: ShareStore
export def "share-store" [
  store_id: string
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
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/customer/stores/{storeId}/shares"
    path_params: [{name: storeId, var: store_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a share of a store to another user
#
# DELETE /v2/user/customer/stores/{storeId}/shares/{userId}
# operationId: DeleteStoreShare
export def "delete-store-share" [
  store_id: string
  user_id: string
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
    path: "/v2/user/customer/stores/{storeId}/shares/{userId}"
    path_params: [{name: storeId, var: store_id}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Zendesk token
#
# GET /v2/user/customer/zendeskToken
# Returns: record<token: string>
# operationId: ZendeskToken
export def "zendesk-token" [
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
    path: "/v2/user/customer/zendeskToken"
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all your current channel catalogs configured to use legacy tracking format
#
# GET /v2/user/legacyTracking/channelCatalogs/
# Returns: record<channelCatalogs: record, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: GetLegacyTrackingChannelCatalogs
export def "get-legacy-tracking-channel-catalogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # The store identifier (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/legacyTracking/channelCatalogs/"
    query: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the channel catalog configured to use legacy tracking format information
#
# GET /v2/user/legacyTracking/channelCatalogs/{channelCatalogId}
# Returns: record<links: record<migrate: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: GetLegacyTrackingChannelCatalog
export def "get-legacy-tracking-channel-catalog" [
  channel_catalog_id: string
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
    path: "/v2/user/legacyTracking/channelCatalogs/{channelCatalogId}"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Migrate a channel catalog to current tracking format
#
# POST /v2/user/legacyTracking/channelCatalogs/{channelCatalogId}/migrate
# operationId: MigrateLegacyTrackingChannelCatalog
export def "migrate-legacy-tracking-channel-catalog" [
  channel_catalog_id: string
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
    path: "/v2/user/legacyTracking/channelCatalogs/{channelCatalogId}/migrate"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all list names
#
# GET /v2/user/lov/
# Returns: record<links: record<lists: record, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: GetUserLovIndex
export def "get-user-lov-index" [
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
    path: "/v2/user/lov/"
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of values related to this list name
#
# GET /v2/user/lov/{listName}
# Returns: record<items: table<codeIdentifier: string, intIdentifier: int, position: int, translationText: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: GetUserListOfValues
export def "get-user-list-of-values" [
  list_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: list<string> # Indicates that the client accepts the following languages.
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/lov/{listName}"
    path_params: [{name: listName, var: list_name}]
    header: [{name: Accept-Language, var: accept_language, array: true}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    list_name: $list_name, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get your marketplace channel catalog list
#
# GET /v2/user/marketplaces/channelcatalogs/
# Returns: record<links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, marketplaceChannelCatalogs: table<apiSettingsStatus: string, beezUPChannelCatalogId: string, beezUPChannelId: string, beezUPMarketplaceName: any, beezUPStoreId: string, beezUPStoreName: string, enabled: bool, links: record, lovLinks: record, marketplaceAccountId: int, marketplaceBusinessCode: string, marketplaceIsoCountryCodeAlpha2: string, marketplaceMarketPlaceId: string, marketplaceMerchantIdentifiers: record, marketplaceTechnicalCode: string>>
# operationId: GetMarketplaceChannelCatalogs
export def "get-marketplace-channel-catalogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # The StoreId to filter by (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/marketplaces/channelcatalogs/"
    query: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the publication history for an account, sorted by descending start date
#
# GET /v2/user/marketplaces/channelcatalogs/publications/{marketplaceTechnicalCode}/{accountId}/history
# Returns: record<links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, publications: table<feeds: list, publicationType: string>>
# operationId: GetPublications
export def "get-publications" [
  marketplace_technical_code: string
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
  --channel-catalog-id: string # Channel Catalog Id by which to filter (optional) (format: guid)
  --count: int # Amount of entries to fetch (optional, default set to 10) (format: int32, default: 10)
  --publication-types: list<string> # Publication types by which to filter (optional) (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/marketplaces/channelcatalogs/publications/{marketplaceTechnicalCode}/{accountId}/history"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}]
    query: [{name: channelCatalogId, var: channel_catalog_id}, {name: count, var: count}, {name: publicationTypes, var: publication_types, style: csv, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, channel_catalog_id: $channel_catalog_id, count: $count, publication_types: $publication_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [PREVIEW] Launch a publication of the catalog to the marketplace
#
# POST /v2/user/marketplaces/channelcatalogs/publications/{marketplaceTechnicalCode}/{accountId}/publish
# operationId: PublishCatalogToMarketplace
export def "publish-catalog-to-marketplace" [
  marketplace_technical_code: string
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
  feed_type: string@feed-type-completer # The Feed Type (e.g. Offers)
  publication_strategy_kind: string@publication-strategy-kind-completer # Define the publication strategy kind, for that you have 2 choices * Delta - This is the recommanded publication strategy kind, this strategy will push to the marketplace only the difference between your catalog and the previous published feeds done by BeezUP. * Full - If you want to force the publication of all your catalog feeds to the marketplace. !WARNING! Depending to the marketplace this operation will purge the existing offers on the marketplace that are not in the catalog or unknown from the publication feed referential. (default: Delta)
  --with-unpublish: oneof<nothing, bool> # In full publication strategy kind, for some marktetplace, you can ask to unpublish or not your existing feeds on the markeptlace absent from your exported catalog.
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/channelcatalogs/publications/{marketplaceTechnicalCode}/{accountId}/publish"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: feedType, var: feed_type}, {name: publicationStrategyKind, var: publication_strategy_kind}, {name: withUnpublish, var: with_unpublish, required: true}]}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, feed_type: $feed_type, publication_strategy_kind: $publication_strategy_kind, with_unpublish: $with_unpublish
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the marketplace properties for a channel catalog
#
# GET /v2/user/marketplaces/channelcatalogs/{channelCatalogId}/properties
# Returns: record<info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<externalConfigurationPage: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, settings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, propertyGroups: table<name: string, position: int, properties: list>>
# operationId: GetChannelCatalogMarketplaceProperties
export def "get-channel-catalog-marketplace-properties" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --redirection-page-url: string # required, format: uri
  --accept-language: list<string> # Indicates that the client accepts the following languages.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/marketplaces/channelcatalogs/{channelCatalogId}/properties"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    query: [{name: redirectionPageUrl, var: redirection_page_url, required: true}]
    header: [{name: Accept-Language, var: accept_language, array: true}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id, redirection_page_url: $redirection_page_url, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the marketplace settings for a channel catalog
#
# GET /v2/user/marketplaces/channelcatalogs/{channelCatalogId}/settings
# Returns: record<links: record<save: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, settings: table<discriminatorType: string, name: string>>
# operationId: GetChannelCatalogMarketplaceSettings
export def "get-channel-catalog-marketplace-settings" [
  channel_catalog_id: string
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
    path: "/v2/user/marketplaces/channelcatalogs/{channelCatalogId}/settings"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save new marketplace settings for a channel catalog
#
# POST /v2/user/marketplaces/channelcatalogs/{channelCatalogId}/settings
# operationId: SetChannelCatalogMarketplaceSettings
export def "set-channel-catalog-marketplace-settings" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  settings: list # e.g. [{name: Country, values: [FR]}, {name: Currency, values: [EUR]}, {name: ListingDuration, values: [GTC]}, {name: PaymentMethods, values: [CCAccepted]}, {name: PayPalEmailAddress, values: [pascal@ixeoline.com]}, {name: PostalCode, values: [69630]}, {name: RefundOption, values: [MoneyBackOrExchange]}, {name: ReturnsAcceptedOption, values: [ReturnsAccepted]}, {name: ReturnsWithinOption, values: [Days_10]}, {name: ShippingCostPaidByOption, values: [Buyer]}, {name: ShippingService, values: [FR_ColiposteColissimo]}] — item shape: {discriminatorType: "channelCatalogMarketplaceStringSetting"|"channelCatalogMarketplaceIntegerSetting"|"channelCatalogMarketplaceBooleanSetting"|"channelCatalogMarketplaceNumberSetting", name: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/channelcatalogs/{channelCatalogId}/settings"
    path_params: [{name: channelCatalogId, var: channel_catalog_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: settings, var: settings}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    channel_catalog_id: $channel_catalog_id, settings: $settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [DEPRECATED] Get all actions you can do on the order API
#
# GET /v2/user/marketplaces/orders/
# DEPRECATED
# Returns: record<links: record<autoTransitions: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, exportations: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, lightOrders: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, orders: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<orderChangeBusinessOperationType: record<href: string, method: string>, orderProperty: record<href: string, method: string>, orderPropertyPosted: record<href: string, method: string>, orderState: record<href: string, method: string>>>
# operationId: GetOrderIndex
@deprecated
export def "get-order-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/marketplaces/orders/"
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of configured automatic Order status transitions
#
# GET /v2/user/marketplaces/orders/automaticTransitions
# Returns: record<automaticTransitionInfos: table<accountId: int, enabled: bool, marketplaceTechnicalCode: string, orderStatusTransitionId: int, beezUPOrderStatus: string, businessOperationType: string, links: record, marketplaceBusinessCode: string>, links: record<configure: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>>
# operationId: GetAutomaticTransitions
export def "get-automatic-transitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # The StoreId to filter by (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/marketplaces/orders/automaticTransitions"
    query: [{name: storeId, var: store_id}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure new or existing automatic Order status transition
#
# POST /v2/user/marketplaces/orders/automaticTransitions
# operationId: ConfigureAutomaticTransitions
export def "configure-automatic-transitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  automatic_transitions: list # item shape: {accountId: int, enabled: bool, marketplaceTechnicalCode: string, orderStatusTransitionId: int}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/orders/automaticTransitions"
    body: {content_type: "application/json", kind: json, fields: [{name: automaticTransitions, var: automatic_transitions}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    automatic_transitions: $automatic_transitions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [DEPRECATED] Send a batch of operations to change your marketplace Order information: accept, ship, etc. (max 100 items per call)
#
# POST /v2/user/marketplaces/orders/batches/changeOrders/{changeOrderType}
# DEPRECATED
# Returns: record<operations: table<errors: list, order: record, status: int, success: bool>>
# operationId: ChangeOrderList
@deprecated
export def "change-order-list" [
  change_order_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-name: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login. (required)
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  change_orders: list # The change order operations — item shape: {changeOrderRequest?: record, order: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/orders/batches/changeOrders/{changeOrderType}"
    path_params: [{name: changeOrderType, var: change_order_type}]
    query: [{name: userName, var: user_name, required: true}, {name: testMode, var: test_mode}]
    body: {content_type: "application/json", kind: json, fields: [{name: changeOrders, var: change_orders}]}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    change_order_type: $change_order_type, user_name: $user_name, test_mode: $test_mode, change_orders: $change_orders
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [DEPRECATED] Send a batch of operations to clear an Order's merchant information (max 100 items per call)
#
# POST /v2/user/marketplaces/orders/batches/clearMerchantOrderInfos
# DEPRECATED
# Returns: record<operations: table<errors: list, order: record, status: int, success: bool>>
# operationId: ClearMerchantOrderInfoList
@deprecated
export def "clear-merchant-order-info-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  orders: list # e.g. [{accountId: 1234, beezUPOrderId: 0, marketplaceTechnicalCode: Amazon}, {accountId: 5678, beezUPOrderId: 0, marketplaceTechnicalCode: Amazon}, {accountId: 9876, beezUPOrderId: 0, marketplaceTechnicalCode: Ebay}] — item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/orders/batches/clearMerchantOrderInfos"
    body: {content_type: "application/json", kind: json, fields: [{name: orders, var: orders}]}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    orders: $orders
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [DEPRECATED] Send a batch of operations to set an Order's merchant information (max 100 items per call)
#
# POST /v2/user/marketplaces/orders/batches/setMerchantOrderInfos
# DEPRECATED
# Returns: record<operations: table<errors: list, order: record, status: int, success: bool>>
# operationId: SetMerchantOrderInfoList
@deprecated
export def "set-merchant-order-info-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  order_merchant_e_commerce_software_name: string # The e-commerce software name of the merchant (e.g. Prestashop)
  order_merchant_e_commerce_software_version: string # The e-commece software version of the merchant (e.g. 123.0.1)
  orders: list # e.g. [{accountId: 1234, beezUPOrderId: 8D47FF1427A26B064ca98e95f644361ada5a5be0bbb3b53, marketplaceTechnicalCode: Amazon, order_MerchantOrderId: BX1234}, {accountId: 5678, beezUPOrderId: 8D47FF149F213D055f26e3c413e4c9ba5c5cfda460547a4, marketplaceTechnicalCode: Amazon, order_MerchantOrderId: BX5678}, {accountId: 9876, beezUPOrderId: 8D47FF150217B60bdec05ab61c445d1a59e3da050b52823, marketplaceTechnicalCode: Ebay, order_MerchantOrderId: BX9876}] — item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string, order_MerchantOrderId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/orders/batches/setMerchantOrderInfos"
    body: {content_type: "application/json", kind: json, fields: [{name: order_MerchantECommerceSoftwareName, var: order_merchant_e_commerce_software_name}, {name: order_MerchantECommerceSoftwareVersion, var: order_merchant_e_commerce_software_version}, {name: orders, var: orders}]}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    order_merchant_e_commerce_software_name: $order_merchant_e_commerce_software_name, order_merchant_e_commerce_software_version: $order_merchant_e_commerce_software_version, orders: $orders
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a paginated list of Order report exportations
#
# GET /v2/user/marketplaces/orders/exportations
# Returns: record<exportations: table<abortionUtcDate: string, beginUtcDate: string, blobNameUri: string, endUtcDate: string, enqueuedUtcDate: string, errorMessage: string, executionUUID: string, expirationUtcDate: string, failureUtcDate: string, ipAddress: string, jsonCriteria: string, lastUpdateUtcDate: string, orderCount: int, processingStatus: string, remainingOrderCount: int, resumedUtcDate: string, sourceType: string, sourceUserId: string, sourceUserName: string, suspendedUtcDate: string, timeoutDuration: string, warningMessage: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>
# operationId: GetOrderExportations
export def "get-order-exportations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number you want to get (required, format: int32, e.g. 1)
  --page-size: int # The entry count you want to get (required, format: int32, e.g. 25)
  --store-id: string # The store identifier to regroup the order exportations (required, format: guid)
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/marketplaces/orders/exportations"
    query: [{name: pageNumber, var: page_number, required: true}, {name: pageSize, var: page_size, required: true}, {name: storeId, var: store_id, required: true}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    page_number: $page_number, page_size: $page_size, store_id: $store_id, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request a new Order report exportation to be generated
#
# POST /v2/user/marketplaces/orders/exportations
# operationId: ExportOrders
export def "export-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer-1 # The type of the file to export (default: csv, e.g. csv)
  order_list_request_without_pagination: record # shape: {accountIds?: list<int>, beezUPOrderStatuses?: list<string>, beginPeriodUtcDate: string, dateSearchType?: "Modification"|"Purchase"|"MarketPlaceModification", endPeriodUtcDate: string, invoiceAvailabilityType?: string, marketplaceBusinessCodes?: list<string>, marketplaceOrderIds?: list<string>, marketplaceTechnicalCodes?: list<string>, orderMerchantInfoSynchronizationStatus?: string, order_Buyer_Name?: string, order_MerchantOrderIds?: list<string>, storeIds?: list<string>}
  store_id: string # The store identifier (format: guid, e.g. 64f43358-63a1-47f7-97ec-0301fc39956b)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/orders/exportations"
    body: {content_type: "application/json", kind: json, fields: [{name: format, var: format}, {name: orderListRequestWithoutPagination, var: order_list_request_without_pagination}, {name: storeId, var: store_id}]}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    format: $format, order_list_request_without_pagination: $order_list_request_without_pagination, store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [DEPRECATED] Send harvest request to all your marketplaces
#
# POST /v2/user/marketplaces/orders/harvest
# DEPRECATED
# operationId: HarvestAll
@deprecated
export def "harvest-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # The StoreId to filter by (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> any {
  http-request {
    method: post
    path: "/v2/user/marketplaces/orders/harvest"
    query: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate an Order Invoice batch
#
# POST /v2/user/marketplaces/orders/invoices/generate
# Returns: table<accountId: int, beezUPOrderUUID: string, invoiceLocation: string, invoiceSequenceNumber: int, marketplaceTechnicalCode: string>
# operationId: GenerateBatchOrderInvoice
export def "generate-batch-order-invoice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-name: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login. (required)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/orders/invoices/generate"
    query: [{name: userName, var: user_name, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    user_name: $user_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the PDF version of the invoice
#
# POST /v2/user/marketplaces/orders/invoices/getPdfInvoice
# Returns: binary
# operationId: GetOrderInvoicePdf
export def "get-order-invoice-pdf" [
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
  order_invoice_uri: string # order invoice url (e.g. http://www.mydomain.com)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/orders/invoices/getPdfInvoice"
    body: {content_type: "application/json", kind: json, fields: [{name: orderInvoiceUri, var: order_invoice_uri}]}
    accept: ["application/pdf", "application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    order_invoice_uri: $order_invoice_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Order Invoice design settings
#
# GET /v2/user/marketplaces/orders/invoices/settings/design
# Returns: record<footerContentHtml: string, headerContentHtml: string>
# operationId: GetOrderInvoiceDesignSettings
export def "get-order-invoice-design-settings" [
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
    path: "/v2/user/marketplaces/orders/invoices/settings/design"
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save Order Invoice design settings
#
# PUT /v2/user/marketplaces/orders/invoices/settings/design
# operationId: SaveOrderInvoiceDesignSettings
export def "save-order-invoice-design-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --footer-content-html: string # Footer Content HTML
  --header-content-html: string # Header Content HTML
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/user/marketplaces/orders/invoices/settings/design"
    body: {content_type: "application/json", kind: json, fields: [{name: footerContentHtml, var: footer_content_html}, {name: headerContentHtml, var: header_content_html}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    footer_content_html: $footer_content_html, header_content_html: $header_content_html
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a preview an Order Invoice using custom design settings
#
# POST /v2/user/marketplaces/orders/invoices/settings/design/preview
# Returns: record<invoiceHtmlContent: string>
# operationId: GetOrderInvoiceDesignSettingsPreview
export def "get-order-invoice-design-settings-preview" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: string # Allows the client to indicate wether it accepts a compressed encoding to reduce traffic size (required)
  --footer-content-html: string # Footer Content HTML
  --header-content-html: string # Header Content HTML
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/orders/invoices/settings/design/preview"
    header: [{name: Accept-Encoding, var: accept_encoding, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: footerContentHtml, var: footer_content_html}, {name: headerContentHtml, var: header_content_html}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    accept_encoding: $accept_encoding, footer_content_html: $footer_content_html, header_content_html: $header_content_html
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Order Invoice general settings
#
# GET /v2/user/marketplaces/orders/invoices/settings/general
# Returns: record<cultureName: string, invoicePrefix: string, invoiceStartingSequenceNumber: int, productVATPercent: float, shippingVATPercent: float, lastInvoiceSequenceNumber: int>
# operationId: GetOrderInvoiceGeneralSettings
export def "get-order-invoice-general-settings" [
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
    path: "/v2/user/marketplaces/orders/invoices/settings/general"
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save Order Invoice general settings
#
# PUT /v2/user/marketplaces/orders/invoices/settings/general
# operationId: SaveOrderInvoiceGeneralSettings
export def "save-order-invoice-general-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  culture_name: string # If the error is translated, the culture name will be indicated (e.g. en)
  invoice_prefix: string # Invoice Prefix. Can contain 1 to 50 characters, with alphanumeric characters in lowercase uppercase and #, _, - (e.g. TOTO)
  invoice_starting_sequence_number: int # Invoice Sequence Number (e.g. 879)
  product_vat_percent: float # Product VAT in percent (e.g. 4.0)
  shipping_vat_percent: float # Shipping cost VAT in percent (e.g. 8.0)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/user/marketplaces/orders/invoices/settings/general"
    body: {content_type: "application/json", kind: json, fields: [{name: cultureName, var: culture_name}, {name: invoicePrefix, var: invoice_prefix}, {name: invoiceStartingSequenceNumber, var: invoice_starting_sequence_number}, {name: productVATPercent, var: product_vat_percent}, {name: shippingVATPercent, var: shipping_vat_percent}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    culture_name: $culture_name, invoice_prefix: $invoice_prefix, invoice_starting_sequence_number: $invoice_starting_sequence_number, product_vat_percent: $product_vat_percent, shipping_vat_percent: $shipping_vat_percent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate an Order Invoice
#
# POST /v2/user/marketplaces/orders/invoices/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderUUID}/generate
# operationId: GenerateOrderInvoice
export def "generate-order-invoice" [
  marketplace_technical_code: string
  account_id: string
  beez_up_order_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-name: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login. (required)
  --invoice-sequence-number: int # Invoice Sequence Number (e.g. 879)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/orders/invoices/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderUUID}/generate"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}, {name: beezUPOrderUUID, var: beez_up_order_uuid}]
    query: [{name: userName, var: user_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: invoiceSequenceNumber, var: invoice_sequence_number}]}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, beez_up_order_uuid: $beez_up_order_uuid, user_name: $user_name, invoice_sequence_number: $invoice_sequence_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a preview an Order Invoice
#
# POST /v2/user/marketplaces/orders/invoices/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderUUID}/preview
# Returns: record<invoiceHtmlContent: string>
# operationId: GetOrderInvoicePreview
export def "get-order-invoice-preview" [
  marketplace_technical_code: string
  account_id: string
  beez_up_order_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: string # Allows the client to indicate wether it accepts a compressed encoding to reduce traffic size (required)
  --invoice-sequence-number: int # Invoice Sequence Number (e.g. 879)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/orders/invoices/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderUUID}/preview"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}, {name: beezUPOrderUUID, var: beez_up_order_uuid}]
    header: [{name: Accept-Encoding, var: accept_encoding, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: invoiceSequenceNumber, var: invoice_sequence_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, beez_up_order_uuid: $beez_up_order_uuid, accept_encoding: $accept_encoding, invoice_sequence_number: $invoice_sequence_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [DEPRECATED] Get a paginated list of all Orders with all Order and Order Item(s) properties
#
# POST /v2/user/marketplaces/orders/list/full
# DEPRECATED
# Returns: record<links: record<clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, orders: table<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool, orderItems: list, order_Buyer_AddressCity: string, order_Buyer_AddressCountryIsoCodeAlpha2: string, order_Buyer_AddressCountryName: string, order_Buyer_AddressLine1: string, order_Buyer_AddressLine2: string, order_Buyer_AddressLine3: string, order_Buyer_AddressPostalCode: string, order_Buyer_AddressStateOrRegion: string, order_Buyer_Civility: string, order_Buyer_CompanyName: string, order_Buyer_Email: string, order_Buyer_FirstName: string, order_Buyer_Identifier: string, order_Buyer_LastName: string, order_Buyer_MobilePhone: string, order_Buyer_Phone: string, order_Comment: string, order_FulfilledBy: string, order_IsBusiness: bool, order_IsPrime: bool, order_MarketPlaceChannel: string, order_OrderItemsSourceUri: string, order_OrderSourceUri: string, order_PayingUtcDate: string, order_PaymentMethod: string, order_Shipping_AddressCity: string, order_Shipping_AddressCountryIsoCodeAlpha2: string, order_Shipping_AddressCountryName: string, order_Shipping_AddressLine1: string, order_Shipping_AddressLine2: string, order_Shipping_AddressLine3: string, order_Shipping_AddressName: string, order_Shipping_AddressPostalCode: string, order_Shipping_AddressStateOrRegion: string, order_Shipping_Civility: string, order_Shipping_CompanyName: string, order_Shipping_EarliestShipUtcDate: string, order_Shipping_Email: string, order_Shipping_FirstName: string, order_Shipping_LastName: string, order_Shipping_LatestShipUtcDate: string, order_Shipping_Method: string, order_Shipping_MobilePhone: string, order_Shipping_Phone: string, order_Shipping_Price: float, order_Shipping_ShippingTax: float, order_TotalCommission: float, order_TotalTax: float, transitionLinks: list>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>
# operationId: GetOrderListFull
@deprecated
export def "get-order-list-full" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: list<string> # Allows the client to indicate wether it accepts a compressed encoding to reduce traffic size (required)
  --account-ids: list<int> # Account Id list (e.g. [12345])
  --beez-up-order-statuses: list<string> # e.g. [InProgress]
  begin_period_utc_date: string # The begin period you want to make the search. \ The period MUST not be greater than 62 days. The begin period MUST be lower than the end period. (format: date-time, e.g. 2017-03-01T13:10:01Z)
  --date-search-type: string@date-search-type-completer # Indicates on which date you want to make the filter (default: Modification)
  end_period_utc_date: string # The end period of you search. \ The period MUST not be greater than 62 days. \ The end period MUST be greater than the begin period. The end period MUST be lower to the current date. (format: date-time, e.g. 2017-04-01T13:10:01Z)
  --invoice-availability-type: string # Indicates on which invoice availability to filter (e.g. All)
  --marketplace-business-codes: list<string> # e.g. [PRICEMINISTER]
  --marketplace-order-ids: list<string> # e.g. [AmazonOrderId1234]
  --marketplace-technical-codes: list<string> # e.g. [PriceMinister]
  --order-merchant-info-synchronization-status: string # Indicates on which order merchant info synchronization status to filter (e.g. All)
  --order-buyer-name: string # Buyer full name (e.g. Monroe)
  --order-merchant-order-ids: list<string> # Merchant order id list (e.g. [MyOrderId1234])
  --store-ids: list<string> # Store Id list
  page_number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  page_size: int # Indicate the order count per page (format: int32, default: 100, e.g. 100)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/orders/list/full"
    header: [{name: Accept-Encoding, var: accept_encoding, array: true, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountIds, var: account_ids}, {name: beezUPOrderStatuses, var: beez_up_order_statuses}, {name: beginPeriodUtcDate, var: begin_period_utc_date}, {name: dateSearchType, var: date_search_type}, {name: endPeriodUtcDate, var: end_period_utc_date}, {name: invoiceAvailabilityType, var: invoice_availability_type}, {name: marketplaceBusinessCodes, var: marketplace_business_codes}, {name: marketplaceOrderIds, var: marketplace_order_ids}, {name: marketplaceTechnicalCodes, var: marketplace_technical_codes}, {name: orderMerchantInfoSynchronizationStatus, var: order_merchant_info_synchronization_status}, {name: order_Buyer_Name, var: order_buyer_name}, {name: order_MerchantOrderIds, var: order_merchant_order_ids}, {name: storeIds, var: store_ids}, {name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    accept_encoding: $accept_encoding, account_ids: $account_ids, beez_up_order_statuses: $beez_up_order_statuses, begin_period_utc_date: $begin_period_utc_date, date_search_type: $date_search_type, end_period_utc_date: $end_period_utc_date, invoice_availability_type: $invoice_availability_type, marketplace_business_codes: $marketplace_business_codes, marketplace_order_ids: $marketplace_order_ids, marketplace_technical_codes: $marketplace_technical_codes, order_merchant_info_synchronization_status: $order_merchant_info_synchronization_status, order_buyer_name: $order_buyer_name, order_merchant_order_ids: $order_merchant_order_ids, store_ids: $store_ids, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [DEPRECATED] Get a paginated list of all Orders without details
#
# POST /v2/user/marketplaces/orders/list/light
# DEPRECATED
# Returns: record<links: record<clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, orders: table<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>>
# operationId: GetOrderListLight
@deprecated
export def "get-order-list-light" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-ids: list<int> # Account Id list (e.g. [12345])
  --beez-up-order-statuses: list<string> # e.g. [InProgress]
  begin_period_utc_date: string # The begin period you want to make the search. \ The period MUST not be greater than 62 days. The begin period MUST be lower than the end period. (format: date-time, e.g. 2017-03-01T13:10:01Z)
  --date-search-type: string@date-search-type-completer # Indicates on which date you want to make the filter (default: Modification)
  end_period_utc_date: string # The end period of you search. \ The period MUST not be greater than 62 days. \ The end period MUST be greater than the begin period. The end period MUST be lower to the current date. (format: date-time, e.g. 2017-04-01T13:10:01Z)
  --invoice-availability-type: string # Indicates on which invoice availability to filter (e.g. All)
  --marketplace-business-codes: list<string> # e.g. [PRICEMINISTER]
  --marketplace-order-ids: list<string> # e.g. [AmazonOrderId1234]
  --marketplace-technical-codes: list<string> # e.g. [PriceMinister]
  --order-merchant-info-synchronization-status: string # Indicates on which order merchant info synchronization status to filter (e.g. All)
  --order-buyer-name: string # Buyer full name (e.g. Monroe)
  --order-merchant-order-ids: list<string> # Merchant order id list (e.g. [MyOrderId1234])
  --store-ids: list<string> # Store Id list
  page_number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  page_size: int # Indicate the order count per page (format: int32, default: 100, e.g. 100)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/orders/list/light"
    body: {content_type: "application/json", kind: json, fields: [{name: accountIds, var: account_ids}, {name: beezUPOrderStatuses, var: beez_up_order_statuses}, {name: beginPeriodUtcDate, var: begin_period_utc_date}, {name: dateSearchType, var: date_search_type}, {name: endPeriodUtcDate, var: end_period_utc_date}, {name: invoiceAvailabilityType, var: invoice_availability_type}, {name: marketplaceBusinessCodes, var: marketplace_business_codes}, {name: marketplaceOrderIds, var: marketplace_order_ids}, {name: marketplaceTechnicalCodes, var: marketplace_technical_codes}, {name: orderMerchantInfoSynchronizationStatus, var: order_merchant_info_synchronization_status}, {name: order_Buyer_Name, var: order_buyer_name}, {name: order_MerchantOrderIds, var: order_merchant_order_ids}, {name: storeIds, var: store_ids}, {name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    account_ids: $account_ids, beez_up_order_statuses: $beez_up_order_statuses, begin_period_utc_date: $begin_period_utc_date, date_search_type: $date_search_type, end_period_utc_date: $end_period_utc_date, invoice_availability_type: $invoice_availability_type, marketplace_business_codes: $marketplace_business_codes, marketplace_order_ids: $marketplace_order_ids, marketplace_technical_codes: $marketplace_technical_codes, order_merchant_info_synchronization_status: $order_merchant_info_synchronization_status, order_buyer_name: $order_buyer_name, order_merchant_order_ids: $order_merchant_order_ids, store_ids: $store_ids, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [DEPRECATED] Get current synchronization status between your marketplaces and BeezUP accounts
#
# GET /v2/user/marketplaces/orders/status
# DEPRECATED
# Returns: record<accountSynchronizations: table<accountId: int, completedHarvestSynchroUtcDate: string, marketplaceBusinessCode: string, marketplaceTechnicalCode: string>>
# operationId: GetMarketplaceAccountsSynchronization
@deprecated
export def "get-marketplace-accounts-synchronization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # The StoreId to filter by (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/marketplaces/orders/status"
    query: [{name: storeId, var: store_id}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    store_id: $store_id, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the subscription list
#
# GET /v2/user/marketplaces/orders/subscriptions/
# Returns: table<consumerHealthStatus: string, consumerLastRequestSentUri: string, consumerUnvailableSinceUtcDate: string, id: string, lastErrorMessage: record<errors: list>, lastOrderPushedModificationUtcDate: string, lastRetryUtcDate: string, lastSuccessfulOrderPushedUtcDate: string, maxRetryCount: int, merchantApplicationName: string, merchantApplicationVersion: string, merchantEmailAlert: string, name: string, nextScheduledRetryUtcDate: string, recoverBeginPeriodOrderLastModificationUtcDate: string, recoverEndPeriodOrderLastModificationUtcDate: string, retryCount: int, status: string, targetUrl: string, links: record<activate: record, deactivate: record, delete: record, reporting: record, retry: record>>
# operationId: GetSubscriptionList
export def "get-subscription-list" [
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
    path: "/v2/user/marketplaces/orders/subscriptions/"
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a subscription to the orders
#
# DELETE /v2/user/marketplaces/orders/subscriptions/{id}
# operationId: DeleteSubscription
export def "delete-subscription" [
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
    path: "/v2/user/marketplaces/orders/subscriptions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a subscription to the orders
#
# GET /v2/user/marketplaces/orders/subscriptions/{id}
# Returns: record<consumerHealthStatus: string, consumerLastRequestSentUri: string, consumerUnvailableSinceUtcDate: string, id: string, lastErrorMessage: record<errors: list<record>>, lastOrderPushedModificationUtcDate: string, lastRetryUtcDate: string, lastSuccessfulOrderPushedUtcDate: string, maxRetryCount: int, merchantApplicationName: string, merchantApplicationVersion: string, merchantEmailAlert: string, name: string, nextScheduledRetryUtcDate: string, recoverBeginPeriodOrderLastModificationUtcDate: string, recoverEndPeriodOrderLastModificationUtcDate: string, retryCount: int, status: string, targetUrl: string, links: record<activate: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, rel: string, urlTemplated: bool>, deactivate: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, rel: string, urlTemplated: bool>, delete: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, rel: string, urlTemplated: bool>, reporting: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, rel: string, urlTemplated: bool>, retry: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, rel: string, urlTemplated: bool>>>
# operationId: GetSubscription
export def "get-subscription" [
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
    path: "/v2/user/marketplaces/orders/subscriptions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a subscription to the orders
#
# POST /v2/user/marketplaces/orders/subscriptions/{id}
# operationId: CreateSubscription
export def "create-subscription" [
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
  merchant_application_name: string # The name of your application (e.g. MyApp)
  merchant_application_version: string # The version of your application (default: 1.0, e.g. 1.0)
  --merchant-email-alert: string # The email (format: email, e.g. paulsimon@mysupercompany.com)
  name: string # The subscription name you want to use (e.g. MySubscriptionName)
  target_url: string # The URL https://en.wikipedia.org/wiki/URL (https://en.wikipedia.org/wiki/URL) (e.g. http://www.mydomain.com)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/orders/subscriptions/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: merchantApplicationName, var: merchant_application_name}, {name: merchantApplicationVersion, var: merchant_application_version}, {name: merchantEmailAlert, var: merchant_email_alert}, {name: name, var: name}, {name: targetUrl, var: target_url}]}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    id: $id, merchant_application_name: $merchant_application_name, merchant_application_version: $merchant_application_version, merchant_email_alert: $merchant_email_alert, name: $name, target_url: $target_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate a subscription to the orders
#
# POST /v2/user/marketplaces/orders/subscriptions/{id}/activate
# operationId: ActivateSubscription
export def "activate-subscription" [
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
  --recover-begin-period-order-last-modification-utc-date: string # If set, the date must be in the past the subscription will recover existing orders using the begin period order last modification date. If not set then you will receive new/updated orders in real-time. (format: date-time)
  --recover-end-period-order-last-modification-utc-date: string # If end period set, first the date must be in the past, the subscription will recover existing orders using the begin and the end period order last modification date. If end period is not set and the begin period is set, then you will recover existing orders from the past using the begin period last modification date and after than you will continue to receive new/updated orders in real-time. If begin/end period are not set then you will receive new/updated orders in real-time. REMARK: The begin period is required if the end period is fulfilled. REMARK: If the end period is order last modification date is indicated then once we have push all orders to your target url the subscription will be desactivated. (format: date-time)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/orders/subscriptions/{id}/activate"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: recoverBeginPeriodOrderLastModificationUtcDate, var: recover_begin_period_order_last_modification_utc_date}, {name: recoverEndPeriodOrderLastModificationUtcDate, var: recover_end_period_order_last_modification_utc_date}]}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    id: $id, recover_begin_period_order_last_modification_utc_date: $recover_begin_period_order_last_modification_utc_date, recover_end_period_order_last_modification_utc_date: $recover_end_period_order_last_modification_utc_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate a subscription to the orders
#
# POST /v2/user/marketplaces/orders/subscriptions/{id}/deactivate
# operationId: DeactivateSubscription
export def "deactivate-subscription" [
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
    path: "/v2/user/marketplaces/orders/subscriptions/{id}/deactivate"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the push reporting related to this subscription
#
# GET /v2/user/marketplaces/orders/subscriptions/{id}/reporting
# Returns: table<duration: string, errorMessage: record<errors: list>, eventId: string, httpStatus: int, lastOrderModificationUtcDate: string, maxRetryCount: int, nextScheduledRetryUtcDate: string, orderCount: int, requestUri: string, responseUri: string, retryCount: int, subscriptionId: string, succeed: bool>
# operationId: GetSubscriptionPushReporting
export def "get-subscription-push-reporting" [
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
  --page-number: int # format: PageNumber
  --page-size: int # format: PageSize
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/marketplaces/orders/subscriptions/{id}/reporting"
    path_params: [{name: id, var: id}]
    query: [{name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    id: $id, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Force retry push orders immediatly
#
# POST /v2/user/marketplaces/orders/subscriptions/{id}/retry
# operationId: RetryPushOrders
export def "retry-push-orders" [
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
    path: "/v2/user/marketplaces/orders/subscriptions/{id}/retry"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [DEPRECATED] DEPRECATED - Get full Order and Order Item(s) properties
#
# GET /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}
# DEPRECATED
# Returns: record<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, clearMerchantInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, history: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool, orderItems: table<beezUPOrderItemId: string, orderItem_BeezUPStoreId: string, orderItem_Condition: string, orderItem_ImageUrl: string, orderItem_ItemPrice: float, orderItem_ItemTax: float, orderItem_MarketPlaceProductId: string, orderItem_MarketplaceImageUri: string, orderItem_MarketplaceProductUri: string, orderItem_MerchantImportedProductId: string, orderItem_MerchantImportedProductIdColumnName: string, orderItem_MerchantImportedProductUrl: string, orderItem_MerchantProductId: string, orderItem_MerchantProductIdColumnName: string, orderItem_OrderItemType: string, orderItem_Quantity: float, orderItem_Shipping_Price: float, orderItem_Title: string, orderItem_TotalPrice: float, orderItem_gtin: string>, order_Buyer_AddressCity: string, order_Buyer_AddressCountryIsoCodeAlpha2: string, order_Buyer_AddressCountryName: string, order_Buyer_AddressLine1: string, order_Buyer_AddressLine2: string, order_Buyer_AddressLine3: string, order_Buyer_AddressPostalCode: string, order_Buyer_AddressStateOrRegion: string, order_Buyer_Civility: string, order_Buyer_CompanyName: string, order_Buyer_Email: string, order_Buyer_FirstName: string, order_Buyer_Identifier: string, order_Buyer_LastName: string, order_Buyer_MobilePhone: string, order_Buyer_Phone: string, order_Comment: string, order_FulfilledBy: string, order_IsBusiness: bool, order_IsPrime: bool, order_MarketPlaceChannel: string, order_OrderItemsSourceUri: string, order_OrderSourceUri: string, order_PayingUtcDate: string, order_PaymentMethod: string, order_Shipping_AddressCity: string, order_Shipping_AddressCountryIsoCodeAlpha2: string, order_Shipping_AddressCountryName: string, order_Shipping_AddressLine1: string, order_Shipping_AddressLine2: string, order_Shipping_AddressLine3: string, order_Shipping_AddressName: string, order_Shipping_AddressPostalCode: string, order_Shipping_AddressStateOrRegion: string, order_Shipping_Civility: string, order_Shipping_CompanyName: string, order_Shipping_EarliestShipUtcDate: string, order_Shipping_Email: string, order_Shipping_FirstName: string, order_Shipping_LastName: string, order_Shipping_LatestShipUtcDate: string, order_Shipping_Method: string, order_Shipping_MobilePhone: string, order_Shipping_Phone: string, order_Shipping_Price: float, order_Shipping_ShippingTax: float, order_TotalCommission: float, order_TotalTax: float, transitionLinks: table<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool, rel: string>>
# operationId: GetOrder
@deprecated
export def "get-order" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}, {name: beezUPOrderId, var: beez_up_order_id}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, beez_up_order_id: $beez_up_order_id, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [DEPRECATED] DEPRECATED - Get the meta information about the order (ETag, Last-Modified)
#
# HEAD /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}
# DEPRECATED
# Returns: record
# operationId: HeadOrder
@deprecated
export def "head-order" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}, {name: beezUPOrderId, var: beez_up_order_id}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, beez_up_order_id: $beez_up_order_id, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [DEPRECATED] Clear an Order's merchant information
#
# POST /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/clearMerchantOrderInfo
# DEPRECATED
# operationId: ClearMerchantOrderInfo
@deprecated
export def "clear-merchant-order-info" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
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
    path: "/v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/clearMerchantOrderInfo"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}, {name: beezUPOrderId, var: beez_up_order_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, beez_up_order_id: $beez_up_order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [DEPRECATED] Send harvest request for a single Order
#
# POST /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/harvest
# DEPRECATED
# operationId: HarvestOrder
@deprecated
export def "harvest-order" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
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
    path: "/v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/harvest"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}, {name: beezUPOrderId, var: beez_up_order_id}]
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, beez_up_order_id: $beez_up_order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [DEPRECATED] Get an Order's harvest and change history
#
# GET /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/history
# DEPRECATED
# Returns: record<changeOrderReportings: table<changeOrderType: string, creationUtcDate: string, details: record, errorMessage: string, executionUUID: string, ipAddress: string, lastUpdateUtcDate: string, processingStatus: string, sourceType: string, sourceUserId: string, sourceUserName: string, testMode: bool>, harvestOrderReportings: table<beezUPForcedStatus: string, beezUPStatus: string, creationUtcDate: string, errorMessage: string, executionUUID: string, lastUpdateUtcDate: string, marketplaceStatus: string, processingStatus: string, warningMessage: string>, lastModificationUtcDate: string>
# operationId: GetOrderHistory
@deprecated
export def "get-order-history" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/history"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}, {name: beezUPOrderId, var: beez_up_order_id}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, beez_up_order_id: $beez_up_order_id, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [DEPRECATED] Set an Order's merchant information
#
# POST /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/setMerchantOrderInfo
# DEPRECATED
# operationId: SetMerchantOrderInfo
@deprecated
export def "set-merchant-order-info" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  order_merchant_e_commerce_software_name: string # The e-commerce software name of the merchant (e.g. Prestashop)
  order_merchant_e_commerce_software_version: string # The e-commece software version of the merchant (e.g. 123.0.1)
  order_merchant_order_id: string # The order merchant identifier (e.g. MyOrderMerchantId)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/setMerchantOrderInfo"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}, {name: beezUPOrderId, var: beez_up_order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: order_MerchantECommerceSoftwareName, var: order_merchant_e_commerce_software_name}, {name: order_MerchantECommerceSoftwareVersion, var: order_merchant_e_commerce_software_version}, {name: order_MerchantOrderId, var: order_merchant_order_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, beez_up_order_id: $beez_up_order_id, order_merchant_e_commerce_software_name: $order_merchant_e_commerce_software_name, order_merchant_e_commerce_software_version: $order_merchant_e_commerce_software_version, order_merchant_order_id: $order_merchant_order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [DEPRECATED] Change your marketplace Order Information (accept, ship, etc.)
#
# POST /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/{changeOrderType}
# DEPRECATED
# operationId: ChangeOrder
@deprecated
export def "change-order" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  change_order_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-name: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login. (required)
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  --if-match: string # ETag value to identify the last known version of requested resource.\ To ensure that you are making a change on the lastest version of the resource.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3 (required)
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/{changeOrderType}"
    path_params: [{name: marketplaceTechnicalCode, var: marketplace_technical_code}, {name: accountId, var: account_id}, {name: beezUPOrderId, var: beez_up_order_id}, {name: changeOrderType, var: change_order_type}]
    query: [{name: userName, var: user_name, required: true}, {name: testMode, var: test_mode}]
    header: [{name: If-Match, var: if_match, required: true}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    marketplace_technical_code: $marketplace_technical_code, account_id: $account_id, beez_up_order_id: $beez_up_order_id, change_order_type: $change_order_type, user_name: $user_name, test_mode: $test_mode, if_match: $if_match, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
