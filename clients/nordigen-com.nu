# Auto-generated client for Nordigen Account Information Services API v2.0 (v2)
# Source: https://api.apis.guru/v2/specs/nordigen.com/2.0 (v2)/openapi.json
# Auth: --token flag or $env.NORDIGEN_ACCOUNT_INFORMATION_SERVICES_API_TOKEN

const CLIENT = {
  base_url: "https://ob.nordigen.com"
  token_env_var: "NORDIGEN_ACCOUNT_INFORMATION_SERVICES_API_TOKEN"
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

def base-url-completer [] { ["https://ob.nordigen.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def payment-product-completer [] { ["CBCT" "ISCT" "SCT" "T2P"] }
def address-country-completer [] { ["AT" "BE" "BG" "CY" "CZ" "DE" "DK" "EE" "ES" "FI" "FR" "GB" "GR" "HR" "HU" "IE" "IS" "IT" "LI" "LT" "LU" "LV" "MT" "NL" "NO" "PL" "PT" "RO" "SE" "SI" "SK"] }
def type-completer [] { ["IBAN" "SCAN"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    retrieve-account-metadata: "record<created: string, iban: string, id: string, institution_id: string, last_accessed: string, owner_name: string, status: string>"
    retrieve-all-eu-as-for-an-end-user-v2: "record<count: int, next: string, previous: string, results: table<accepted: string, access_scope: list, access_valid_for_days: int, created: string, id: string, institution_id: string, max_historical_days: int>>"
    create-eua-v2: "record<accepted: string, access_scope: list<list<any>>, access_valid_for_days: int, created: string, id: string, institution_id: string, max_historical_days: int>"
    retrieve-eua-by-id-v2: "record<accepted: string, access_scope: list<list<any>>, access_valid_for_days: int, created: string, id: string, institution_id: string, max_historical_days: int>"
    accept-eua: "record<accepted: string, access_scope: list<list<any>>, access_valid_for_days: int, created: string, id: string, institution_id: string, max_historical_days: int>"
    retrieve-all-supported-institutions-in-a-given-country: "table<bic: string, countries: list<string>, id: string, logo: string, name: string, transaction_total_days: string>"
    retrieve-institution: "record<bic: string, countries: list<string>, id: string, logo: string, name: string, transaction_total_days: string>"
    list-payments: "record<count: int, next: string, previous: string, results: table<creditor_account: string, custom_payment_id: string, debtor_account: record, description: string, instructed_amount: record, payment_id: string, payment_product: string, payment_status: string, payment_type: string, redirect: string>>"
    create-payment: "record<creditor_account: string, custom_payment_id: string, description: string, instructed_amount: record<amount: string, currency: string>, link: string, payment_id: string, payment_product: string, payment_status: string, payment_type: string, periodic_payment: record<day_of_execution: string, end_date: string, execution_rule: string, frequency: string, start_date: string>, redirect: string, requested_execution_date: string>"
    retrieve-all-payment-creditor-accounts: "table<account: string, address_country: string, currency: string, id: string, name: string, type: string>"
    payments-creditors-list: "record<count: int, next: string, previous: string, results: table<account: string, address_country: string, currency: string, id: string, name: string, type: string>>"
    payments-creditors-create: "record<account: string, address_country: string, address_street: string, agent: string, agent_name: string, currency: string, id: string, institution_id: string, name: string, post_code: string, type: string>"
    payments-creditors-retrieve: "record<account: string, address_country: string, currency: string, id: string, name: string, type: string>"
    list-minimum-required-fields-for-institution: "record"
    delete-periodic-payment: "record"
    retrieve-payment: "record<creditor_account: string, custom_payment_id: string, debtor_account: record<account: string, address_country: string, address_street: string, currency: string, name: string, post_code: string, type: string, type_number: string>, description: string, instructed_amount: record<amount: string, currency: string>, payment_id: string, payment_product: string, payment_status: string, payment_type: string, redirect: string>"
    retrieve-all-requisitions: "record<count: int, next: string, previous: string, results: table<account_selection: bool, accounts: list, agreement: string, created: string, id: string, institution_id: string, link: string, redirect: string, redirect_immediate: bool, reference: string, ssn: string, status: string, user_language: string>>"
    requisition-created: "record<account_selection: bool, accounts: list<any>, agreement: string, created: string, id: string, institution_id: string, link: string, redirect: string, redirect_immediate: bool, reference: string, ssn: string, status: string, user_language: string>"
    requisition-by-id: "record<account_selection: bool, accounts: list<string>, agreement: string, created: string, id: string, institution_id: string, link: string, redirect: string, redirect_immediate: bool, reference: string, ssn: string, status: string, user_language: string>"
    jwt-obtain: "record<access: string, access_expires: int, refresh: string, refresh_expires: int>"
    jwt-refresh: "record<access: string, access_expires: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["retrieve-account-transactions-v2" "retrieve-account-metadata" "accounts-balances-retrieve" "accounts-details-retrieve" "accounts-transactions-retrieve" "retrieve-all-eu-as-for-an-end-user-v2" "create-eua-v2" "delete-eua-by-id-v2" "retrieve-eua-by-id-v2" "accept-eua" "retrieve-all-supported-institutions-in-a-given-country" "retrieve-institution" "list-payments" "create-payment" "retrieve-all-payment-creditor-accounts" "payments-creditors-list" "payments-creditors-create" "payments-creditors-destroy" "payments-creditors-retrieve" "list-minimum-required-fields-for-institution" "delete-periodic-payment" "retrieve-payment" "retrieve-all-requisitions" "requisition-created" "delete-requisition-by-id-v2" "requisition-by-id" "jwt-obtain" "jwt-refresh" "commands"] | sort) } | get name | first)
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

# Access account premium transactions.
#
# GET /api/v2/accounts/premium/{id}/transactions/
# operationId: retrieve account transactions v2
export def "retrieve-account-transactions-v2" [
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
  --country: string # ISO 3166 two-character country code
  --date-from: string # format: date
  --date-to: string # format: date
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v2/accounts/premium/{id}/transactions/"
    path_params: [{name: id, var: id}]
    query: [{name: country, var: country}, {name: date_from, var: date_from}, {name: date_to, var: date_to}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, country: $country, date_from: $date_from, date_to: $date_to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Access account metadata. Information about the account record, such as the processing status and IBAN. Account status is recalculated based on the error count in the latest req.
#
# GET /api/v2/accounts/{id}/
# Returns: record<created: string, iban: string, id: string, institution_id: string, last_accessed: string, owner_name: string, status: string>
# operationId: retrieve account metadata
export def "retrieve-account-metadata" [
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
    path: "/api/v2/accounts/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Access account balances. Balances will be returned in Berlin Group PSD2 format.
#
# GET /api/v2/accounts/{id}/balances/
# operationId: accounts_balances_retrieve
export def "accounts-balances-retrieve" [
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
    method: get
    path: "/api/v2/accounts/{id}/balances/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Access account details. Account details will be returned in Berlin Group PSD2 format.
#
# GET /api/v2/accounts/{id}/details/
# operationId: accounts_details_retrieve
export def "accounts-details-retrieve" [
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
    method: get
    path: "/api/v2/accounts/{id}/details/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Access account transactions. Transactions will be returned in Berlin Group PSD2 format.
#
# GET /api/v2/accounts/{id}/transactions/
# operationId: accounts_transactions_retrieve
export def "accounts-transactions-retrieve" [
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
  --date-from: string # format: date
  --date-to: string # format: date
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v2/accounts/{id}/transactions/"
    path_params: [{name: id, var: id}]
    query: [{name: date_from, var: date_from}, {name: date_to, var: date_to}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id, date_from: $date_from, date_to: $date_to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all end user agreements belonging to the company
#
# GET /api/v2/agreements/enduser/
# Returns: record<count: int, next: string, previous: string, results: table<accepted: string, access_scope: list, access_valid_for_days: int, created: string, id: string, institution_id: string, max_historical_days: int>>
# operationId: retrieve all EUAs for an end user v2
export def "retrieve-all-eu-as-for-an-end-user-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page. (default: 100)
  --offset: int # The initial index from which to return the results. (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/agreements/enduser/"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an end user agreement
#
# POST /api/v2/agreements/enduser/
# Returns: record<accepted: string, access_scope: list<list<any>>, access_valid_for_days: int, created: string, id: string, institution_id: string, max_historical_days: int>
# operationId: create EUA v2
export def "create-eua-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-scope: list # Array containing one or several values of ['balances', 'details', 'transactions'] (default: [balances, details, transactions])
  --access-valid-for-days: int # Number of days from acceptance that the access can be used. (default: 90)
  institution_id: string # an Institution ID for this EUA
  --max-historical-days: int # Maximum number of days of transaction data to retrieve. (default: 90)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v2/agreements/enduser/"
    body: {content_type: "application/json", kind: json, fields: [{name: access_scope, var: access_scope}, {name: access_valid_for_days, var: access_valid_for_days}, {name: institution_id, var: institution_id}, {name: max_historical_days, var: max_historical_days}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    access_scope: $access_scope, access_valid_for_days: $access_valid_for_days, institution_id: $institution_id, max_historical_days: $max_historical_days
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an end user agreement
#
# DELETE /api/v2/agreements/enduser/{id}/
# operationId: delete EUA by id v2
export def "delete-eua-by-id-v2" [
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
    path: "/api/v2/agreements/enduser/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve end user agreement by ID
#
# GET /api/v2/agreements/enduser/{id}/
# Returns: record<accepted: string, access_scope: list<list<any>>, access_valid_for_days: int, created: string, id: string, institution_id: string, max_historical_days: int>
# operationId: retrieve EUA by id v2
export def "retrieve-eua-by-id-v2" [
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
    path: "/api/v2/agreements/enduser/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accept an end-user agreement via the API
#
# PUT /api/v2/agreements/enduser/{id}/accept/
# Returns: record<accepted: string, access_scope: list<list<any>>, access_valid_for_days: int, created: string, id: string, institution_id: string, max_historical_days: int>
# operationId: accept EUA
export def "accept-eua" [
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
  ip_address: string
  user_agent: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v2/agreements/enduser/{id}/accept/"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ip_address, var: ip_address}, {name: user_agent, var: user_agent}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ip_address: $ip_address, user_agent: $user_agent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all available institutions
#
# GET /api/v2/institutions/
# Returns: table<bic: string, countries: list<string>, id: string, logo: string, name: string, transaction_total_days: string>
# operationId: retrieve all supported Institutions in a given country
export def "retrieve-all-supported-institutions-in-a-given-country" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # ISO 3166 two-character country code
  --payments-enabled: string # Boolean value, indicating if payments are enabled
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/institutions/"
    query: [{name: country, var: country}, {name: payments_enabled, var: payments_enabled}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country, payments_enabled: $payments_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details about a specific Institution
#
# GET /api/v2/institutions/{id}/
# Returns: record<bic: string, countries: list<string>, id: string, logo: string, name: string, transaction_total_days: string>
# operationId: retrieve institution
export def "retrieve-institution" [
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
    path: "/api/v2/institutions/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all payments belonging to the company
#
# GET /api/v2/payments/
# Returns: record<count: int, next: string, previous: string, results: table<creditor_account: string, custom_payment_id: string, debtor_account: record, description: string, instructed_amount: record, payment_id: string, payment_product: string, payment_status: string, payment_type: string, redirect: string>>
# operationId: list payments
export def "list-payments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page. (default: 100)
  --offset: int # The initial index from which to return the results. (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/payments/"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create payment
#
# POST /api/v2/payments/
# Returns: record<creditor_account: string, custom_payment_id: string, description: string, instructed_amount: record<amount: string, currency: string>, link: string, payment_id: string, payment_product: string, payment_status: string, payment_type: string, periodic_payment: record<day_of_execution: string, end_date: string, execution_rule: string, frequency: string, start_date: string>, redirect: string, requested_execution_date: string>
# operationId: create payment
export def "create-payment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  creditor_account: string # Registered creditor account (format: uuid)
  --custom-payment-id: string # Payment Custom Payment ID
  --debtor-account: record # Debtor account — shape: {account?: string, address_country?: string, address_street?: string, currency?: string, name: string, post_code?: string, type?: "IBAN"|"SCAN", type_number?: string}
  --description: string # Payment description (default: GOCARDLESS)
  --institution-id: string # Institution ID for Payment (default: SWEDBANK_SANDBOX_SANDLV22)
  instructed_amount: record # Instructed amount — shape: {amount: string, currency: string}
  --payment-product: string@payment-product-completer # Payment product (default: ISCT)
  --periodic-payment: record # Periodic Payment Serializer. — shape: {day_of_execution?: string, end_date?: string, execution_rule?: "following"|"preceding", frequency?: "Daily"|"Weekly"|"EveryTwoWeeks"|"Monthly"|"EveryTwoMonths"|"Quarterly"|"SemiAnnual"|"Annual"|"MonthlyVariable", start_date: string}
  --redirect: string # Redirect URL to your application after payment is done (nullable, format: uri)
  --requested-execution-date: string # Payment Execution date (for periodic payments) (format: date)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v2/payments/"
    body: {content_type: "application/json", kind: json, fields: [{name: creditor_account, var: creditor_account}, {name: custom_payment_id, var: custom_payment_id}, {name: debtor_account, var: debtor_account}, {name: description, var: description}, {name: institution_id, var: institution_id}, {name: instructed_amount, var: instructed_amount}, {name: payment_product, var: payment_product}, {name: periodic_payment, var: periodic_payment}, {name: redirect, var: redirect}, {name: requested_execution_date, var: requested_execution_date}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    creditor_account: $creditor_account, custom_payment_id: $custom_payment_id, debtor_account: $debtor_account, description: $description, institution_id: $institution_id, instructed_amount: $instructed_amount, payment_product: $payment_product, periodic_payment: $periodic_payment, redirect: $redirect, requested_execution_date: $requested_execution_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all payment creditor accounts
#
# GET /api/v2/payments/account/
# Returns: table<account: string, address_country: string, currency: string, id: string, name: string, type: string>
# operationId: retrieve all payment creditor accounts
export def "retrieve-all-payment-creditor-accounts" [
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
    path: "/api/v2/payments/account/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# API endpoints related to creditor accounts.
#
# GET /api/v2/payments/creditors/
# Returns: record<count: int, next: string, previous: string, results: table<account: string, address_country: string, currency: string, id: string, name: string, type: string>>
# operationId: payments_creditors_list
export def "payments-creditors-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: string
  --address-country: string
  --agent: string
  --currency: string
  --limit: int # Number of results to return per page. (default: 100)
  --name: string
  --offset: int # The initial index from which to return the results. (default: 1)
  --type: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/payments/creditors/"
    query: [{name: account, var: account}, {name: address_country, var: address_country}, {name: agent, var: agent}, {name: currency, var: currency}, {name: limit, var: limit}, {name: name, var: name}, {name: offset, var: offset}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account: $account, address_country: $address_country, agent: $agent, currency: $currency, limit: $limit, name: $name, offset: $offset, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# API endpoints related to creditor accounts.
#
# POST /api/v2/payments/creditors/
# Returns: record<account: string, address_country: string, address_street: string, agent: string, agent_name: string, currency: string, id: string, institution_id: string, name: string, post_code: string, type: string>
# operationId: payments_creditors_create
export def "payments-creditors-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account: string # Creditor account type identifier
  --address-country: string@address-country-completer
  --address-street: string # Creditor account address street
  --agent: string # Creditor account BICFI Identifier
  --agent-name: string # Creditor account agent name
  currency: string # Creditor account currency
  --institution-id: string # an Institution ID for this CreditorAccount
  name: string # Creditor account name
  --post-code: string # Creditor account address post code
  --type: string@type-completer # Creditor account type (default: IBAN)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v2/payments/creditors/"
    body: {content_type: "application/json", kind: json, fields: [{name: account, var: account}, {name: address_country, var: address_country}, {name: address_street, var: address_street}, {name: agent, var: agent}, {name: agent_name, var: agent_name}, {name: currency, var: currency}, {name: institution_id, var: institution_id}, {name: name, var: name}, {name: post_code, var: post_code}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account: $account, address_country: $address_country, address_street: $address_street, agent: $agent, agent_name: $agent_name, currency: $currency, institution_id: $institution_id, name: $name, post_code: $post_code, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# API endpoints related to creditor accounts.
#
# DELETE /api/v2/payments/creditors/{id}/
# operationId: payments_creditors_destroy
export def "payments-creditors-destroy" [
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
    path: "/api/v2/payments/creditors/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# API endpoints related to creditor accounts.
#
# GET /api/v2/payments/creditors/{id}/
# Returns: record<account: string, address_country: string, currency: string, id: string, name: string, type: string>
# operationId: payments_creditors_retrieve
export def "payments-creditors-retrieve" [
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
    path: "/api/v2/payments/creditors/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List minimum required fields for institution
#
# GET /api/v2/payments/fields/{institution_id}/
# Returns: record
# operationId: list minimum required fields for institution
export def "list-minimum-required-fields-for-institution" [
  institution_id: string
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
    path: "/api/v2/payments/fields/{institution_id}/"
    path_params: [{name: institution_id, var: institution_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    institution_id: $institution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete periodic payment
#
# DELETE /api/v2/payments/{id}/
# Returns: record
# operationId: delete periodic payment
export def "delete-periodic-payment" [
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
    path: "/api/v2/payments/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve payment
#
# GET /api/v2/payments/{id}/
# Returns: record<creditor_account: string, custom_payment_id: string, debtor_account: record<account: string, address_country: string, address_street: string, currency: string, name: string, post_code: string, type: string, type_number: string>, description: string, instructed_amount: record<amount: string, currency: string>, payment_id: string, payment_product: string, payment_status: string, payment_type: string, redirect: string>
# operationId: retrieve payment
export def "retrieve-payment" [
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
    path: "/api/v2/payments/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all requisitions belonging to the company
#
# GET /api/v2/requisitions/
# Returns: record<count: int, next: string, previous: string, results: table<account_selection: bool, accounts: list, agreement: string, created: string, id: string, institution_id: string, link: string, redirect: string, redirect_immediate: bool, reference: string, ssn: string, status: string, user_language: string>>
# operationId: retrieve all requisitions
export def "retrieve-all-requisitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page. (default: 100)
  --offset: int # The initial index from which to return the results. (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/requisitions/"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new requisition
#
# POST /api/v2/requisitions/
# Returns: record<account_selection: bool, accounts: list<any>, agreement: string, created: string, id: string, institution_id: string, link: string, redirect: string, redirect_immediate: bool, reference: string, ssn: string, status: string, user_language: string>
# operationId: requisition created
export def "requisition-created" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-selection: oneof<nothing, bool> # option to enable account selection view for the end user (default: false)
  --agreement: string # EUA associated with this requisition (format: uuid)
  institution_id: string # an Institution ID for this Requisition
  --redirect: string # redirect URL to your application after end-user authorization with ASPSP (nullable, format: uri)
  --redirect-immediate: oneof<nothing, bool> # enable redirect back to the client after account list received (default: false)
  --reference: string # additional ID to identify the end user
  --ssn: string # optional SSN field to verify ownership of the account
  --user-language: string # A two-letter country code (ISO 639-1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v2/requisitions/"
    body: {content_type: "application/json", kind: json, fields: [{name: account_selection, var: account_selection}, {name: agreement, var: agreement}, {name: institution_id, var: institution_id}, {name: redirect, var: redirect}, {name: redirect_immediate, var: redirect_immediate}, {name: reference, var: reference}, {name: ssn, var: ssn}, {name: user_language, var: user_language}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account_selection: $account_selection, agreement: $agreement, institution_id: $institution_id, redirect: $redirect, redirect_immediate: $redirect_immediate, reference: $reference, ssn: $ssn, user_language: $user_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete requisition and its end user agreement
#
# DELETE /api/v2/requisitions/{id}/
# operationId: delete requisition by id v2
export def "delete-requisition-by-id-v2" [
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
    path: "/api/v2/requisitions/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a requisition by ID
#
# GET /api/v2/requisitions/{id}/
# Returns: record<account_selection: bool, accounts: list<string>, agreement: string, created: string, id: string, institution_id: string, link: string, redirect: string, redirect_immediate: bool, reference: string, ssn: string, status: string, user_language: string>
# operationId: requisition by id
export def "requisition-by-id" [
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
    path: "/api/v2/requisitions/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Obtain JWT pair
#
# POST /api/v2/token/new/
# Returns: record<access: string, access_expires: int, refresh: string, refresh_expires: int>
# operationId: JWT Obtain
export def "jwt-obtain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  secret_id: string # Secret id from /user-secrets/
  secret_key: string # Secret key from /user-secrets/
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v2/token/new/"
    body: {content_type: "application/json", kind: json, fields: [{name: secret_id, var: secret_id}, {name: secret_key, var: secret_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    secret_id: $secret_id, secret_key: $secret_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refresh access token
#
# POST /api/v2/token/refresh/
# Returns: record<access: string, access_expires: int>
# operationId: JWT Refresh
export def "jwt-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  refresh: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v2/token/refresh/"
    body: {content_type: "application/json", kind: json, fields: [{name: refresh, var: refresh}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    refresh: $refresh
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
