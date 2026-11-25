# Auto-generated client for API v2020-08-10_6-22
# Source: https://api.apis.guru/v2/specs/tl-api.azurewebsites.net/2020-08-10_6-22/openapi.json
# Auth: --token flag or $env.API_TOKEN

const CLIENT = {
  base_url: "https://tl-api.azurewebsites.net"
  token_env_var: "API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: ocp-apim-subscription-key, in: header, header_name: Ocp-Apim-Subscription-Key, prefix: ""}
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

def base-url-completer [] { ["https://tl-api.azurewebsites.net" "https://triviallife.azure-api.net/v1"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    article-delete: "record<isError: bool, message: string, responseException: any, result: int>"
    article-post: "record<isError: bool, message: string, responseException: any, result: any>"
    article-put: "record<isError: bool, message: string, responseException: any, result: any>"
    article-update-article-gym-details: "record<isError: bool, message: string, responseException: any, result: any>"
    article-get-addons: "record<isError: bool, message: string, responseException: any, result: table<activeStatus: bool, applyForAllGyms: bool, articleId: int, createdDate: string, createdUser: string, description: string, measureUnit: string, modifiedDate: string, modifiedUser: string, name: string, number: int, price: float, sellingPrice: float, tags: string, totalCount: int, type: string>>"
    article-gym-article-details: "record<articleId: int, availableQty: float, createdUser: string, employeeDiscount: float, employeePrice: float, gymId: int, gymIdList: string, gymName: string, id: int, isDefault: bool, isInventoryItem: bool, isObsolete: bool, modifiedUser: string, reorderLevel: float, revenueAccountId: int, sellingPrice: float>"
    article-add-measure-unit: "record<isError: bool, message: string, responseException: any, result: any>"
    article-get-measure-units: "record<isError: bool, message: string, responseException: any, result: any>"
    article-get-revenue-accounts: "record<isError: bool, message: string, responseException: any, result: any>"
    article-search: "record<isError: bool, message: string, responseException: any, result: table<activeStatus: bool, applyForAllGyms: bool, articleId: int, createdDate: string, createdUser: string, description: string, measureUnit: string, modifiedDate: string, modifiedUser: string, name: string, number: int, price: float, sellingPrice: float, tags: string, totalCount: int, type: string>>"
    article-update-status: "record<isError: bool, message: string, responseException: any, result: int>"
    article-get: "record<isError: bool, message: string, responseException: any, result: any>"
    auth-login: "binary"
    gym-get: "record<isError: bool, message: string, responseException: any, result: any>"
    membership-get: "table<name: string>"
    membership-post: "bool"
    package-delete: "record<isError: bool, message: string, responseException: any, result: bool>"
    package-get: "record<isError: bool, message: string, responseException: any, result: any>"
    package-post: "record<isError: bool, message: string, responseException: any, result: any>"
    package-put: "record<isError: bool, message: string, responseException: any, result: any>"
    package-search: "table<isError: bool, message: string, responseException: any, result: any>"
    package-update-status: "record<isError: bool, message: string, responseException: any, result: bool>"
    status-get: "record<messageId: string, referenceId: int, source: any, statusId: int, statusText: string>"
    test-get: "record<id: int>"
    user-get: "record<accountNumber: string, externalEntityNumber: string, guardian: int, gymNumber: string, introduceBy: int, name: string, number: string, typeId: int, userId: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["article-delete" "article-post" "article-put" "article-update-article-gym-details" "article-get-addons" "article-gym-article-details" "article-add-measure-unit" "article-get-measure-units" "article-get-revenue-accounts" "article-search" "article-update-status" "article-get" "auth-login" "gym-get" "membership-get" "membership-post" "package-delete" "package-get" "package-post" "package-put" "package-search" "package-update-status" "status-get" "test-get" "user-get" "user-register-user" "user-update-user" "commands"] | sort) } | get name | first)
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

# Delete article from the system
#
# DELETE /api/Article
# Returns: record<isError: bool, message: string, responseException: any, result: int>
# operationId: Article_Delete
export def "article-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --article-id: int # indentity number(primary key) for article object (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/Article"
    query: [{name: ArticleId, var: article_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new article
#
# POST /api/Article
# Returns: record<isError: bool, message: string, responseException: any, result: any>
# operationId: Article_Post
export def "article-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active-status: oneof<nothing, bool> # Active Status
  --apply-for-all-gyms: oneof<nothing, bool>
  --article-id: int # format: int32
  available_gyms: list # item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
  --available-qty: float # Default AvailableQty (format: decimal)
  --barcode: string # nullable
  --created-date: string # format: date-time
  --created-user: string # nullable
  --cron-expression: string # Access Schedule CRON Expression (nullable)
  --description: string # nullable
  --discount: float # format: decimal
  --employee-discount: float # Default EmployeeDiscount (format: decimal)
  --employee-price: float # Default EmployeePrice (format: decimal)
  --gym-articles: list # Gym Customizations (nullable) — item shape: {articleId?: int, availableQty?: float, createdUser?: string, employeeDiscount?: float, employeePrice?: float, gymId?: int, gymIdList?: string, gymName?: string, id?: int, isDefault?: bool, isInventoryItem?: bool, isObsolete?: bool, modifiedUser?: string, reorderLevel?: float, revenueAccountId?: int, sellingPrice?: float}
  --is-add-on: oneof<nothing, bool>
  --is-inventory-item: oneof<nothing, bool> # Default IsInventoryItem of the Article
  --is-obsolete: oneof<nothing, bool> # Default IsObsolete of the Article
  measure_unit: string
  --modified-date: string # format: date-time
  --modified-user: string # nullable
  name: string
  --number: int # format: int32
  price: float # format: decimal
  --reorder-level: float # Deafault ReorderLevel (format: decimal)
  --revenue-account-id: int # Default Revenue account (format: int32)
  --selling-price: float # Default SellingPrice (format: decimal)
  --tags: string # nullable
  type: string
  --vat: float # format: decimal
  --vat-applicable: oneof<nothing, bool> # VAT Applicable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Article"
    body: {content_type: "application/json", kind: json, fields: [{name: activeStatus, var: active_status}, {name: applyForAllGyms, var: apply_for_all_gyms}, {name: articleId, var: article_id}, {name: availableGyms, var: available_gyms}, {name: availableQty, var: available_qty}, {name: barcode, var: barcode}, {name: createdDate, var: created_date}, {name: createdUser, var: created_user}, {name: cronExpression, var: cron_expression}, {name: description, var: description}, {name: discount, var: discount}, {name: employeeDiscount, var: employee_discount}, {name: employeePrice, var: employee_price}, {name: gymArticles, var: gym_articles}, {name: isAddOn, var: is_add_on}, {name: isInventoryItem, var: is_inventory_item}, {name: isObsolete, var: is_obsolete}, {name: measureUnit, var: measure_unit}, {name: modifiedDate, var: modified_date}, {name: modifiedUser, var: modified_user}, {name: name, var: name}, {name: number, var: number}, {name: price, var: price}, {name: reorderLevel, var: reorder_level}, {name: revenueAccountId, var: revenue_account_id}, {name: sellingPrice, var: selling_price}, {name: tags, var: tags}, {name: type, var: type}, {name: vat, var: vat}, {name: vatApplicable, var: vat_applicable}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    active_status: $active_status, apply_for_all_gyms: $apply_for_all_gyms, article_id: $article_id, available_gyms: $available_gyms, available_qty: $available_qty, barcode: $barcode, created_date: $created_date, created_user: $created_user, cron_expression: $cron_expression, description: $description, discount: $discount, employee_discount: $employee_discount, employee_price: $employee_price, gym_articles: $gym_articles, is_add_on: $is_add_on, is_inventory_item: $is_inventory_item, is_obsolete: $is_obsolete, measure_unit: $measure_unit, modified_date: $modified_date, modified_user: $modified_user, name: $name, number: $number, price: $price, reorder_level: $reorder_level, revenue_account_id: $revenue_account_id, selling_price: $selling_price, tags: $tags, type: $type, vat: $vat, vat_applicable: $vat_applicable
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# update existing article
#
# PUT /api/Article
# Returns: record<isError: bool, message: string, responseException: any, result: any>
# operationId: Article_Put
export def "article-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active-status: oneof<nothing, bool> # Active Status
  --apply-for-all-gyms: oneof<nothing, bool>
  --article-id: int # format: int32
  available_gyms: list # item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
  --available-qty: float # Default AvailableQty (format: decimal)
  --barcode: string # nullable
  --created-date: string # format: date-time
  --created-user: string # nullable
  --cron-expression: string # Access Schedule CRON Expression (nullable)
  --description: string # nullable
  --discount: float # format: decimal
  --employee-discount: float # Default EmployeeDiscount (format: decimal)
  --employee-price: float # Default EmployeePrice (format: decimal)
  --gym-articles: list # Gym Customizations (nullable) — item shape: {articleId?: int, availableQty?: float, createdUser?: string, employeeDiscount?: float, employeePrice?: float, gymId?: int, gymIdList?: string, gymName?: string, id?: int, isDefault?: bool, isInventoryItem?: bool, isObsolete?: bool, modifiedUser?: string, reorderLevel?: float, revenueAccountId?: int, sellingPrice?: float}
  --is-add-on: oneof<nothing, bool>
  --is-inventory-item: oneof<nothing, bool> # Default IsInventoryItem of the Article
  --is-obsolete: oneof<nothing, bool> # Default IsObsolete of the Article
  measure_unit: string
  --modified-date: string # format: date-time
  --modified-user: string # nullable
  name: string
  --number: int # format: int32
  price: float # format: decimal
  --reorder-level: float # Deafault ReorderLevel (format: decimal)
  --revenue-account-id: int # Default Revenue account (format: int32)
  --selling-price: float # Default SellingPrice (format: decimal)
  --tags: string # nullable
  type: string
  --vat: float # format: decimal
  --vat-applicable: oneof<nothing, bool> # VAT Applicable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/Article"
    body: {content_type: "application/json", kind: json, fields: [{name: activeStatus, var: active_status}, {name: applyForAllGyms, var: apply_for_all_gyms}, {name: articleId, var: article_id}, {name: availableGyms, var: available_gyms}, {name: availableQty, var: available_qty}, {name: barcode, var: barcode}, {name: createdDate, var: created_date}, {name: createdUser, var: created_user}, {name: cronExpression, var: cron_expression}, {name: description, var: description}, {name: discount, var: discount}, {name: employeeDiscount, var: employee_discount}, {name: employeePrice, var: employee_price}, {name: gymArticles, var: gym_articles}, {name: isAddOn, var: is_add_on}, {name: isInventoryItem, var: is_inventory_item}, {name: isObsolete, var: is_obsolete}, {name: measureUnit, var: measure_unit}, {name: modifiedDate, var: modified_date}, {name: modifiedUser, var: modified_user}, {name: name, var: name}, {name: number, var: number}, {name: price, var: price}, {name: reorderLevel, var: reorder_level}, {name: revenueAccountId, var: revenue_account_id}, {name: sellingPrice, var: selling_price}, {name: tags, var: tags}, {name: type, var: type}, {name: vat, var: vat}, {name: vatApplicable, var: vat_applicable}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    active_status: $active_status, apply_for_all_gyms: $apply_for_all_gyms, article_id: $article_id, available_gyms: $available_gyms, available_qty: $available_qty, barcode: $barcode, created_date: $created_date, created_user: $created_user, cron_expression: $cron_expression, description: $description, discount: $discount, employee_discount: $employee_discount, employee_price: $employee_price, gym_articles: $gym_articles, is_add_on: $is_add_on, is_inventory_item: $is_inventory_item, is_obsolete: $is_obsolete, measure_unit: $measure_unit, modified_date: $modified_date, modified_user: $modified_user, name: $name, number: $number, price: $price, reorder_level: $reorder_level, revenue_account_id: $revenue_account_id, selling_price: $selling_price, tags: $tags, type: $type, vat: $vat, vat_applicable: $vat_applicable
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add article details that associate with a Gym
#
# PUT /api/Article/ArticleGymDetails
# Returns: record<isError: bool, message: string, responseException: any, result: any>
# operationId: Article_UpdateArticleGymDetails
export def "article-update-article-gym-details" [
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/Article/ArticleGymDetails"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/Article/GetAddons
#
# Returns: record<isError: bool, message: string, responseException: any, result: table<activeStatus: bool, applyForAllGyms: bool, articleId: int, createdDate: string, createdUser: string, description: string, measureUnit: string, modifiedDate: string, modifiedUser: string, name: string, number: int, price: float, sellingPrice: float, tags: string, totalCount: int, type: string>>
# operationId: Article_GetAddons
export def "article-get-addons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-text: string # Search text - will be search by the name (nullable)
  --gym-ids: string # Comma separated gymIds deafult "-1" for all gyms (nullable, default: -1)
  --type: string # nullable, default: all
  --limit: int # format: int32, default: 100
  --offset: int # format: int32, default: 0
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Article/GetAddons"
    query: [{name: searchText, var: search_text}, {name: gymIds, var: gym_ids}, {name: type, var: type}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search_text: $search_text, gym_ids: $gym_ids, type: $type, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Gym specific properties for article
#
# GET /api/Article/GymArticle/{articleId}/{gymId}
# Returns: record<articleId: int, availableQty: float, createdUser: string, employeeDiscount: float, employeePrice: float, gymId: int, gymIdList: string, gymName: string, id: int, isDefault: bool, isInventoryItem: bool, isObsolete: bool, modifiedUser: string, reorderLevel: float, revenueAccountId: int, sellingPrice: float>
# operationId: Article_GymArticleDetails
export def "article-gym-article-details" [
  article_id: int
  gym_id: int
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
    path: "/api/Article/GymArticle/{articleId}/{gymId}"
    path_params: [{name: articleId, var: article_id}, {name: gymId, var: gym_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    article_id: $article_id, gym_id: $gym_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add measure unit
#
# POST /api/Article/MeasureUnit
# Returns: record<isError: bool, message: string, responseException: any, result: any>
# operationId: Article_AddMeasureUnit
export def "article-add-measure-unit" [
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Article/MeasureUnit"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get mesure units
#
# GET /api/Article/MeasureUnits
# Returns: record<isError: bool, message: string, responseException: any, result: any>
# operationId: Article_GetMeasureUnits
export def "article-get-measure-units" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # type of the measure unit (all, item, service) (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Article/MeasureUnits"
    query: [{name: type, var: type}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Revenue Accounts
#
# GET /api/Article/RevenueAccounts
# Returns: record<isError: bool, message: string, responseException: any, result: any>
# operationId: Article_GetRevenueAccounts
export def "article-get-revenue-accounts" [
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
    path: "/api/Article/RevenueAccounts"
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search articles It will only return basic information of article
#
# GET /api/Article/Search
# Returns: record<isError: bool, message: string, responseException: any, result: table<activeStatus: bool, applyForAllGyms: bool, articleId: int, createdDate: string, createdUser: string, description: string, measureUnit: string, modifiedDate: string, modifiedUser: string, name: string, number: int, price: float, sellingPrice: float, tags: string, totalCount: int, type: string>>
# operationId: Article_Search
export def "article-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-text: string # part of article name (nullable)
  --gym-id: int # -1 for all gyms (format: int32, default: -1)
  --type: string # filter article type. default is 'all' (nullable, default: all)
  --order-by: string # order by column.!-- invalid column will give internal server error (nullable, default: 1)
  --limit: int # number of recode in result and default is 100. use negative numbers to order by desc (format: int32, default: 100)
  --offset: int # number of recodes to skip (format: int32, default: 0)
  --active-status: int # Active Status 1 : Active, 2: Inactive, 3: All, Default : 1 (format: int32, default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Article/Search"
    query: [{name: searchText, var: search_text}, {name: gymId, var: gym_id}, {name: type, var: type}, {name: orderBy, var: order_by}, {name: limit, var: limit}, {name: offset, var: offset}, {name: activeStatus, var: active_status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search_text: $search_text, gym_id: $gym_id, type: $type, order_by: $order_by, limit: $limit, offset: $offset, active_status: $active_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate existing article
#
# PUT /api/Article/UpdateStatus
# Returns: record<isError: bool, message: string, responseException: any, result: int>
# operationId: Article_UpdateStatus
export def "article-update-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --article-id: int # format: int32
  --status: int # 1 : activate , 2 deactivate (format: int32)
  --user-name: string # Updating user (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/api/Article/UpdateStatus"
    query: [{name: ArticleId, var: article_id}, {name: status, var: status}, {name: userName, var: user_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    article_id: $article_id, status: $status, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get article details This will return all properties related to article entity
#
# GET /api/Article/{articleID}
# Returns: record<isError: bool, message: string, responseException: any, result: any>
# operationId: Article_get
export def "article-get" [
  article_id: int
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
    path: "/api/Article/{articleID}"
    path_params: [{name: articleID, var: article_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    article_id: $article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authenticate and provide token for autherizations.
#
# POST /api/Auth/login
# Returns: binary
# operationId: Auth_Login
export def "auth-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # nullable
  --remember: oneof<nothing, bool>
  --username: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/Auth/login"
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: remember, var: remember}, {name: username, var: username}]}
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    password: $password, remember: $remember, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get gym details This will return all properties related to gym entity
#
# GET /api/Gym/{gymID}
# Returns: record<isError: bool, message: string, responseException: any, result: any>
# operationId: Gym_get
export def "gym-get" [
  gym_id: int
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
    path: "/api/Gym/{gymID}"
    path_params: [{name: gymID, var: gym_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    gym_id: $gym_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all of the members details This will return all properties related to member entity
#
# GET /api/Membership
# Returns: table<name: string>
# operationId: Membership_Get
export def "membership-get" [
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
    path: "/api/Membership"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new Member
#
# POST /api/Membership
# Returns: bool
# operationId: Membership_Post
export def "membership-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/Membership"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete existing package
#
# DELETE /api/Package
# Returns: record<isError: bool, message: string, responseException: any, result: bool>
# operationId: Package_Delete
export def "package-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --package-id: int # primary key of package entity (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/Package"
    query: [{name: PackageId, var: package_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_id: $package_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get package details by packageId
#
# GET /api/Package
# Returns: record<isError: bool, message: string, responseException: any, result: any>
# operationId: Package_Get
export def "package-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --package-id: int # primary key of package entity (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Package"
    query: [{name: packageId, var: package_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_id: $package_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert new package into the system
#
# POST /api/Package
# Returns: record<isError: bool, message: string, responseException: any, result: any>
# operationId: Package_Post
export def "package-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-ons: list # Extra articles list added to the given package. (nullable) — item shape: {articleId: int, articleName?: string, articleNumber?: int, articlePrice?: float, endOrder?: int, isIncludeServiceInCharge?: bool, measureUnit?: string, numberOfItems?: float, startOrder?: int}
  --addon-fee: float # sum of addon fees. incoming values for this filed will ignore. (format: decimal)
  --apply-for-all-gyms: oneof<nothing, bool> # Boolean value to indicate wheather package is available in all the gyms.
  --available-gyms: list # Gyms list where this package is available. (nullable) — item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
  --binding-period: int # Range of period a member is bound to the contract if he/she choose this package. (format: int32)
  --created-date: string # Package created DateTime. (format: date-time)
  --created-user: string # Package created user. (nullable)
  --description: string # Common descriptions about package.If there are more instructions can be stored as comma separated values. (nullable)
  --end-date: string # End date of the package.After that package is not valid for use. (format: date-time)
  --expire-in-months: int # No of months the fixed package is valid for sale (format: int32)
  --features: string # What are the facilities, features available for package.ex:- wifi, ACm etc.Can be stored as comma seperated values. (nullable)
  --free-months: int # No of months gym member can come without payments. (format: int32)
  --instructions-to-gym-users: string # Instruction to the gym members relevant to the package. If there are more instructions can be stored as comma seperated values. (nullable)
  --instructions-to-web-users: string # Instruction to the MRM members relevant to the package. If there are more instructions can be stored as comma seperated values. (nullable)
  --is-active: oneof<nothing, bool> # Boolean value to indicate this package is still active or not.
  --is-atg: oneof<nothing, bool> # Boolean value to indicate ATG transaction from bank is applicable or not.
  --is-auto-renew: oneof<nothing, bool> # Boolean value to indicate the contract will auto renew after expiration if this package would be chosen.
  --is-first-month-free: oneof<nothing, bool> # Boolean value to indicate if the first month charges is free.
  --is-registration-fee: oneof<nothing, bool> # Boolean value to indicate this package has registration fee or not.
  --is-rest-amount: oneof<nothing, bool> # Boolean value to indicate rest amount is applicable or not.
  --is-shown-in-mobile: oneof<nothing, bool> # Boolean value to indicate package is visible in Mobile App or not.
  --is-sponsor-package: oneof<nothing, bool> # Boolean value to indicate package can be sponsored or not by other party.
  --maximum-give-away-rest-amount: float # If a member join the gym middle of a month via this package, what is the maximum amount of price can be neglected from payment from the member. (format: decimal)
  --member-can-add-add-ons: oneof<nothing, bool> # Boolean value to indicate member can add extra addons he wish if he choose this package.
  --member-can-leave-within-free-period: oneof<nothing, bool> # Boolean value to indicate if member can leave from contract within free period if he/she choose this package.
  --member-can-remove-add-ons: oneof<nothing, bool> # Boolean value to indicate member can remove already added addons if he choose this package.
  --modified-date: string # Package last modified DateTime. (format: date-time)
  --modified-user: string # Package last modified user. (nullable)
  --monthly-fee: float # Monthly installment fee if package is not fixed visit. addition of the servicefee and addon fees divided by binding period. read only (format: decimal)
  --next-package-number: int # Next Package the contract continue after the binding period of this package. (format: int32)
  --number-of-installments: int # Maximum Number of installment a member can divide the package price/cost to pay. (format: int32)
  --number-of-visits: int # If package is fixed visit type, then how many visits are available for this package. (format: int32)
  --package-id: int # format: int32
  package_name: string
  --package-number: string # nullable
  package_type: string # Package type can be either fixed visit or unlimited.
  --per-visit-price: float # Cost/Price of the single visit to gym. (format: decimal)
  registration_fee: float # Registartion fee for the package at a gym. read only (format: decimal)
  service_fee: float # total Service charge of the package for entire period. (format: decimal)
  --shown-in-web: oneof<nothing, bool> # Boolean value to show this package in MRM system or not.
  --start-date: string # Start date of the package. (format: date-time)
  --tags: string # Comma separated string values in case of need of maintain some labels kind of stuff relevant to the package. (nullable)
  --total-price: float # total price for the package including Addon fees, service fee and registration fee. incoming values for this field will ignore. (format: decimal)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Package"
    body: {content_type: "application/json", kind: json, fields: [{name: addOns, var: add_ons}, {name: addonFee, var: addon_fee}, {name: applyForAllGyms, var: apply_for_all_gyms}, {name: availableGyms, var: available_gyms}, {name: bindingPeriod, var: binding_period}, {name: createdDate, var: created_date}, {name: createdUser, var: created_user}, {name: description, var: description}, {name: endDate, var: end_date}, {name: expireInMonths, var: expire_in_months}, {name: features, var: features}, {name: freeMonths, var: free_months}, {name: instructionsToGymUsers, var: instructions_to_gym_users}, {name: instructionsToWebUsers, var: instructions_to_web_users}, {name: isActive, var: is_active}, {name: isAtg, var: is_atg}, {name: isAutoRenew, var: is_auto_renew}, {name: isFirstMonthFree, var: is_first_month_free}, {name: isRegistrationFee, var: is_registration_fee}, {name: isRestAmount, var: is_rest_amount}, {name: isShownInMobile, var: is_shown_in_mobile}, {name: isSponsorPackage, var: is_sponsor_package}, {name: maximumGiveAwayRestAmount, var: maximum_give_away_rest_amount}, {name: memberCanAddAddOns, var: member_can_add_add_ons}, {name: memberCanLeaveWithinFreePeriod, var: member_can_leave_within_free_period}, {name: memberCanRemoveAddOns, var: member_can_remove_add_ons}, {name: modifiedDate, var: modified_date}, {name: modifiedUser, var: modified_user}, {name: monthlyFee, var: monthly_fee}, {name: nextPackageNumber, var: next_package_number}, {name: numberOfInstallments, var: number_of_installments}, {name: numberOfVisits, var: number_of_visits}, {name: packageId, var: package_id}, {name: packageName, var: package_name}, {name: packageNumber, var: package_number}, {name: packageType, var: package_type}, {name: perVisitPrice, var: per_visit_price}, {name: registrationFee, var: registration_fee}, {name: serviceFee, var: service_fee}, {name: shownInWeb, var: shown_in_web}, {name: startDate, var: start_date}, {name: tags, var: tags}, {name: totalPrice, var: total_price}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    add_ons: $add_ons, addon_fee: $addon_fee, apply_for_all_gyms: $apply_for_all_gyms, available_gyms: $available_gyms, binding_period: $binding_period, created_date: $created_date, created_user: $created_user, description: $description, end_date: $end_date, expire_in_months: $expire_in_months, features: $features, free_months: $free_months, instructions_to_gym_users: $instructions_to_gym_users, instructions_to_web_users: $instructions_to_web_users, is_active: $is_active, is_atg: $is_atg, is_auto_renew: $is_auto_renew, is_first_month_free: $is_first_month_free, is_registration_fee: $is_registration_fee, is_rest_amount: $is_rest_amount, is_shown_in_mobile: $is_shown_in_mobile, is_sponsor_package: $is_sponsor_package, maximum_give_away_rest_amount: $maximum_give_away_rest_amount, member_can_add_add_ons: $member_can_add_add_ons, member_can_leave_within_free_period: $member_can_leave_within_free_period, member_can_remove_add_ons: $member_can_remove_add_ons, modified_date: $modified_date, modified_user: $modified_user, monthly_fee: $monthly_fee, next_package_number: $next_package_number, number_of_installments: $number_of_installments, number_of_visits: $number_of_visits, package_id: $package_id, package_name: $package_name, package_number: $package_number, package_type: $package_type, per_visit_price: $per_visit_price, registration_fee: $registration_fee, service_fee: $service_fee, shown_in_web: $shown_in_web, start_date: $start_date, tags: $tags, total_price: $total_price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing package by its ID
#
# PUT /api/Package
# Returns: record<isError: bool, message: string, responseException: any, result: any>
# operationId: Package_Put
export def "package-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-ons: list # Extra articles list added to the given package. (nullable) — item shape: {articleId: int, articleName?: string, articleNumber?: int, articlePrice?: float, endOrder?: int, isIncludeServiceInCharge?: bool, measureUnit?: string, numberOfItems?: float, startOrder?: int}
  --addon-fee: float # sum of addon fees. incoming values for this filed will ignore. (format: decimal)
  --apply-for-all-gyms: oneof<nothing, bool> # Boolean value to indicate wheather package is available in all the gyms.
  --available-gyms: list # Gyms list where this package is available. (nullable) — item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
  --binding-period: int # Range of period a member is bound to the contract if he/she choose this package. (format: int32)
  --created-date: string # Package created DateTime. (format: date-time)
  --created-user: string # Package created user. (nullable)
  --description: string # Common descriptions about package.If there are more instructions can be stored as comma separated values. (nullable)
  --end-date: string # End date of the package.After that package is not valid for use. (format: date-time)
  --expire-in-months: int # No of months the fixed package is valid for sale (format: int32)
  --features: string # What are the facilities, features available for package.ex:- wifi, ACm etc.Can be stored as comma seperated values. (nullable)
  --free-months: int # No of months gym member can come without payments. (format: int32)
  --instructions-to-gym-users: string # Instruction to the gym members relevant to the package. If there are more instructions can be stored as comma seperated values. (nullable)
  --instructions-to-web-users: string # Instruction to the MRM members relevant to the package. If there are more instructions can be stored as comma seperated values. (nullable)
  --is-active: oneof<nothing, bool> # Boolean value to indicate this package is still active or not.
  --is-atg: oneof<nothing, bool> # Boolean value to indicate ATG transaction from bank is applicable or not.
  --is-auto-renew: oneof<nothing, bool> # Boolean value to indicate the contract will auto renew after expiration if this package would be chosen.
  --is-first-month-free: oneof<nothing, bool> # Boolean value to indicate if the first month charges is free.
  --is-registration-fee: oneof<nothing, bool> # Boolean value to indicate this package has registration fee or not.
  --is-rest-amount: oneof<nothing, bool> # Boolean value to indicate rest amount is applicable or not.
  --is-shown-in-mobile: oneof<nothing, bool> # Boolean value to indicate package is visible in Mobile App or not.
  --is-sponsor-package: oneof<nothing, bool> # Boolean value to indicate package can be sponsored or not by other party.
  --maximum-give-away-rest-amount: float # If a member join the gym middle of a month via this package, what is the maximum amount of price can be neglected from payment from the member. (format: decimal)
  --member-can-add-add-ons: oneof<nothing, bool> # Boolean value to indicate member can add extra addons he wish if he choose this package.
  --member-can-leave-within-free-period: oneof<nothing, bool> # Boolean value to indicate if member can leave from contract within free period if he/she choose this package.
  --member-can-remove-add-ons: oneof<nothing, bool> # Boolean value to indicate member can remove already added addons if he choose this package.
  --modified-date: string # Package last modified DateTime. (format: date-time)
  --modified-user: string # Package last modified user. (nullable)
  --monthly-fee: float # Monthly installment fee if package is not fixed visit. addition of the servicefee and addon fees divided by binding period. read only (format: decimal)
  --next-package-number: int # Next Package the contract continue after the binding period of this package. (format: int32)
  --number-of-installments: int # Maximum Number of installment a member can divide the package price/cost to pay. (format: int32)
  --number-of-visits: int # If package is fixed visit type, then how many visits are available for this package. (format: int32)
  --package-id: int # format: int32
  package_name: string
  --package-number: string # nullable
  package_type: string # Package type can be either fixed visit or unlimited.
  --per-visit-price: float # Cost/Price of the single visit to gym. (format: decimal)
  registration_fee: float # Registartion fee for the package at a gym. read only (format: decimal)
  service_fee: float # total Service charge of the package for entire period. (format: decimal)
  --shown-in-web: oneof<nothing, bool> # Boolean value to show this package in MRM system or not.
  --start-date: string # Start date of the package. (format: date-time)
  --tags: string # Comma separated string values in case of need of maintain some labels kind of stuff relevant to the package. (nullable)
  --total-price: float # total price for the package including Addon fees, service fee and registration fee. incoming values for this field will ignore. (format: decimal)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/Package"
    body: {content_type: "application/json", kind: json, fields: [{name: addOns, var: add_ons}, {name: addonFee, var: addon_fee}, {name: applyForAllGyms, var: apply_for_all_gyms}, {name: availableGyms, var: available_gyms}, {name: bindingPeriod, var: binding_period}, {name: createdDate, var: created_date}, {name: createdUser, var: created_user}, {name: description, var: description}, {name: endDate, var: end_date}, {name: expireInMonths, var: expire_in_months}, {name: features, var: features}, {name: freeMonths, var: free_months}, {name: instructionsToGymUsers, var: instructions_to_gym_users}, {name: instructionsToWebUsers, var: instructions_to_web_users}, {name: isActive, var: is_active}, {name: isAtg, var: is_atg}, {name: isAutoRenew, var: is_auto_renew}, {name: isFirstMonthFree, var: is_first_month_free}, {name: isRegistrationFee, var: is_registration_fee}, {name: isRestAmount, var: is_rest_amount}, {name: isShownInMobile, var: is_shown_in_mobile}, {name: isSponsorPackage, var: is_sponsor_package}, {name: maximumGiveAwayRestAmount, var: maximum_give_away_rest_amount}, {name: memberCanAddAddOns, var: member_can_add_add_ons}, {name: memberCanLeaveWithinFreePeriod, var: member_can_leave_within_free_period}, {name: memberCanRemoveAddOns, var: member_can_remove_add_ons}, {name: modifiedDate, var: modified_date}, {name: modifiedUser, var: modified_user}, {name: monthlyFee, var: monthly_fee}, {name: nextPackageNumber, var: next_package_number}, {name: numberOfInstallments, var: number_of_installments}, {name: numberOfVisits, var: number_of_visits}, {name: packageId, var: package_id}, {name: packageName, var: package_name}, {name: packageNumber, var: package_number}, {name: packageType, var: package_type}, {name: perVisitPrice, var: per_visit_price}, {name: registrationFee, var: registration_fee}, {name: serviceFee, var: service_fee}, {name: shownInWeb, var: shown_in_web}, {name: startDate, var: start_date}, {name: tags, var: tags}, {name: totalPrice, var: total_price}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    add_ons: $add_ons, addon_fee: $addon_fee, apply_for_all_gyms: $apply_for_all_gyms, available_gyms: $available_gyms, binding_period: $binding_period, created_date: $created_date, created_user: $created_user, description: $description, end_date: $end_date, expire_in_months: $expire_in_months, features: $features, free_months: $free_months, instructions_to_gym_users: $instructions_to_gym_users, instructions_to_web_users: $instructions_to_web_users, is_active: $is_active, is_atg: $is_atg, is_auto_renew: $is_auto_renew, is_first_month_free: $is_first_month_free, is_registration_fee: $is_registration_fee, is_rest_amount: $is_rest_amount, is_shown_in_mobile: $is_shown_in_mobile, is_sponsor_package: $is_sponsor_package, maximum_give_away_rest_amount: $maximum_give_away_rest_amount, member_can_add_add_ons: $member_can_add_add_ons, member_can_leave_within_free_period: $member_can_leave_within_free_period, member_can_remove_add_ons: $member_can_remove_add_ons, modified_date: $modified_date, modified_user: $modified_user, monthly_fee: $monthly_fee, next_package_number: $next_package_number, number_of_installments: $number_of_installments, number_of_visits: $number_of_visits, package_id: $package_id, package_name: $package_name, package_number: $package_number, package_type: $package_type, per_visit_price: $per_visit_price, registration_fee: $registration_fee, service_fee: $service_fee, shown_in_web: $shown_in_web, start_date: $start_date, tags: $tags, total_price: $total_price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search packages
#
# GET /api/Package/Search
# Returns: table<isError: bool, message: string, responseException: any, result: any>
# operationId: Package_Search
export def "package-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-text: string # part of package name (nullable)
  --gym-id: int # primary key of TL gym entity (format: int32, default: -1)
  --type: string # filter package type.!-- default is 'all' (nullable, default: all)
  --order-by: string # order by column.!-- invalid column will give internal server error (nullable, default: 1)
  --limit: int # number of recode in result and default is 100. use negative numbers to order by desc (format: int32, default: 100)
  --offset: int # number of recodes to skip (format: int32, default: 0)
  --active-status: int # active status active : 1, inactive : 2, all 3, deafult : 1 (format: int32, default: 1)
  --category-id: int # Packge Category Id (format: int32, default: -1)
  --startp-price: float # Start price of the price Range (format: decimal, default: 0)
  --end-price: float # End Price of the price Range (format: decimal, default: 9999999)
  --request-source: int # 1 : MRM, 2 : Mobile (format: int32, default: 1)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/Package/Search"
    query: [{name: searchText, var: search_text}, {name: gymId, var: gym_id}, {name: type, var: type}, {name: orderBy, var: order_by}, {name: limit, var: limit}, {name: offset, var: offset}, {name: activeStatus, var: active_status}, {name: categoryId, var: category_id}, {name: startpPrice, var: startp_price}, {name: endPrice, var: end_price}, {name: requestSource, var: request_source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search_text: $search_text, gym_id: $gym_id, type: $type, order_by: $order_by, limit: $limit, offset: $offset, active_status: $active_status, category_id: $category_id, startp_price: $startp_price, end_price: $end_price, request_source: $request_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Status update of existing package
#
# PUT /api/Package/UpdateStatus
# Returns: record<isError: bool, message: string, responseException: any, result: bool>
# operationId: Package_UpdateStatus
export def "package-update-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --package-id: int # package Id (format: int32)
  --status: int # status : 1 activate, 2 : deactivate (format: int32, default: 1)
  --user-name: string # Status updated User (nullable, default: system)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/api/Package/UpdateStatus"
    query: [{name: packageId, var: package_id}, {name: status, var: status}, {name: userName, var: user_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_id: $package_id, status: $status, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the current status of message
#
# GET /api/Status
# Returns: record<messageId: string, referenceId: int, source: any, statusId: int, statusText: string>
# operationId: Status_Get
export def "status-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message-id: string # respose of POST request (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Status"
    query: [{name: messageId, var: message_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the all Test objects.
#
# GET /api/Test
# Returns: record<id: int>
# operationId: Test_get
export def "test-get" [
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
    path: "/api/Test"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Users detail This will return all properties related to User entity
#
# GET /api/User
# Returns: record<accountNumber: string, externalEntityNumber: string, guardian: int, gymNumber: string, introduceBy: int, name: string, number: string, typeId: int, userId: int>
# operationId: User_Get
export def "user-get" [
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
    path: "/api/User"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a new User
#
# POST /api/User/registerUser
# operationId: User_registerUser
export def "user-register-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # Indentity number(primary key) for user object. Generated in DB table when inserting a record. (format: int32)
  --account-number: string # Account number of the user.It can be any stakeholder of the application.even can be a gym. (nullable)
  --gym-number: string # If this user is a gym, then the gym number. (nullable)
  --external-entity-number: string # Entity number that make a relationship with BOX API DB. (nullable)
  --name: string # Name of the user. (nullable)
  --number: string # Unique number maintain by application to idenify user. (nullable)
  --introduce-by: int # If Someone introduced this user to the system, then that user's UserId. (format: int32)
  --guardian: int # Gaurdian of the this user if he/she is under 18 years old. (format: int32)
  --type-id: int # Type of the user. (format: int32)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/User/registerUser"
    query: [{name: UserId, var: user_id}, {name: AccountNumber, var: account_number}, {name: GymNumber, var: gym_number}, {name: ExternalEntityNumber, var: external_entity_number}, {name: Name, var: name}, {name: Number, var: number}, {name: IntroduceBy, var: introduce_by}, {name: Guardian, var: guardian}, {name: TypeId, var: type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, account_number: $account_number, gym_number: $gym_number, external_entity_number: $external_entity_number, name: $name, number: $number, introduce_by: $introduce_by, guardian: $guardian, type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an exsisting User
#
# PUT /api/User/updateuser
# operationId: User_updateUser
export def "user-update-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # Indentity number(primary key) for user object. Generated in DB table when inserting a record. (format: int32)
  --account-number: string # Account number of the user.It can be any stakeholder of the application.even can be a gym. (nullable)
  --gym-number: string # If this user is a gym, then the gym number. (nullable)
  --external-entity-number: string # Entity number that make a relationship with BOX API DB. (nullable)
  --name: string # Name of the user. (nullable)
  --number: string # Unique number maintain by application to idenify user. (nullable)
  --introduce-by: int # If Someone introduced this user to the system, then that user's UserId. (format: int32)
  --guardian: int # Gaurdian of the this user if he/she is under 18 years old. (format: int32)
  --type-id: int # Type of the user. (format: int32)
]: nothing -> any {
  http-request {
    method: put
    path: "/api/User/updateuser"
    query: [{name: UserId, var: user_id}, {name: AccountNumber, var: account_number}, {name: GymNumber, var: gym_number}, {name: ExternalEntityNumber, var: external_entity_number}, {name: Name, var: name}, {name: Number, var: number}, {name: IntroduceBy, var: introduce_by}, {name: Guardian, var: guardian}, {name: TypeId, var: type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, account_number: $account_number, gym_number: $gym_number, external_entity_number: $external_entity_number, name: $name, number: $number, introduce_by: $introduce_by, guardian: $guardian, type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
