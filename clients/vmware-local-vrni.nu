# Auto-generated client for vRealize Network Insight API Reference v1.0.0
# Source: https://api.apis.guru/v2/specs/vmware.local/vrni/1.0.0/openapi.json
# Auth: --token flag or $env.VREALIZE_NETWORK_INSIGHT_API_REFERENCE_TOKEN

const CLIENT = {
  base_url: "http://vmware.local"
  token_env_var: "VREALIZE_NETWORK_INSIGHT_API_REFERENCE_TOKEN"
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

def base-url-completer [] { ["http://vmware.local" "https://vrni.example.com/api/ni"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "expiry" "token"] }
def entity-type-completer [] { ["AristaSwitchDataSource" "BrocadeSwitchDataSource" "CheckpointFirewallDataSource" "CiscoSwitchDataSource" "DellSwitchDataSource" "HPOneViewDataSource" "HPVCManagerDataSource" "JuniperSwitchDataSource" "NSXVManagerDataSource" "PanFirewallDataSource" "UCSManagerDataSource" "VCenterDataSource"] }
def snmp-version-completer [] { ["v2c" "v3"] }
def switch-type-completer [] { ["CATALYST_3000" "CATALYST_4500" "CATALYST_6500" "NEXUS_5K" "NEXUS_7K" "NEXUS_9K"] }
def switch-type-completer-1 [] { ["FORCE_10_MXL_10" "POWERCONNECT_8024" "S4048" "S6000" "Z9100"] }
def accept-completer-1 [] { ["application/json" "results" "total_count"] }
def accept-completer-2 [] { ["application/json" "credentials" "enabled" "entity_id" "entity_type" "fqdn" "ip" "nickname" "notes" "proxy_id"] }
def accept-completer-3 [] { ["application/json" "cursor" "end_time" "results" "start_time" "total_count"] }
def accept-completer-4 [] { ["application/json" "entity_id" "entity_type" "name" "nsx_manager" "num_cpu_cores" "num_datastores" "num_hosts" "total_cpus" "total_memory" "vcenter_manager" "vendor_id"] }
def accept-completer-5 [] { ["application/json" "entity_id" "entity_type" "name" "vcenter_manager" "vendor_id"] }
def accept-completer-6 [] { ["application/json" "distributed_virtual_switch" "entity_id" "entity_type" "name" "vcenter_manager" "vendor_id"] }
def accept-completer-7 [] { ["application/json" "entity_id" "entity_type" "hosts" "name" "vcenter_manager" "vendor_id"] }
def accept-completer-8 [] { ["action" "application/json" "destination_any" "destination_inversion" "destinations" "direction" "disabled" "entity_id" "entity_type" "logging_enabled" "name" "nsx_managers" "port_ranges" "rule_id" "scope" "section_id" "section_name" "sequence_number" "service_any" "services" "source_any" "source_inversion" "sources"] }
def accept-completer-9 [] { ["application/json" "entity_id" "entity_type" "exclusions" "firewall_rules" "name"] }
def accept-completer-10 [] { ["application/json" "destination_folders" "destination_ip" "destination_ip_sets" "destination_security_groups" "destination_security_tags" "destination_vm_tags" "entity_id" "entity_type" "firewall_action" "flow_tag" "name" "port" "protocol" "source_folders" "source_ip" "source_ip_sets" "source_security_groups" "source_security_tags" "source_vm_tags" "traffic_type" "within_host"] }
def accept-completer-11 [] { ["application/json" "cluster" "connection_state" "datastores" "entity_id" "entity_type" "maintenance_mode" "name" "nsx_manager" "service_tag" "vcenter_manager" "vendor_id" "vm_count" "vmknics"] }
def accept-completer-12 [] { ["application/json" "direct_destination_rules" "direct_source_rules" "entity_id" "entity_type" "indirect_destination_rules" "indirect_source_rules" "ip_addresses" "ip_numeric_ranges" "ip_ranges" "name" "nsx_managers" "parent_security_groups" "scope" "translated_vm_count" "vendor" "vendor_id"] }
def accept-completer-13 [] { ["application/json" "entity_id" "entity_type" "gateways" "name" "network_addresses" "nsx_managers" "scope" "segment_id" "vteps"] }
def accept-completer-14 [] { ["application/json" "entity_id" "entity_type" "ip_address" "name" "role" "version"] }
def accept-completer-15 [] { ["admin_state" "anchor_entities" "application/json" "archived" "entity_id" "entity_type" "event_tags" "event_time_epoch_ms" "message" "name" "related_entities" "severity"] }
def accept-completer-16 [] { ["application/json" "direct_destination_rules" "direct_members" "direct_source_rules" "entity_id" "entity_type" "excluded_members" "indirect_destination_rules" "indirect_source_rules" "ip_sets" "members" "name" "nsx_managers" "parents" "scope" "security_tags" "translated_vm_count" "vendor_id"] }
def accept-completer-17 [] { ["application/json" "description" "direct_security_groups" "entity_id" "entity_type" "name" "nsx_manager" "security_groups" "vendor_id"] }
def accept-completer-18 [] { ["application/json" "entity_id" "entity_type" "members" "name" "nsx_managers" "scope" "vendor_id"] }
def accept-completer-19 [] { ["application/json" "entity_id" "entity_type" "name" "nsx_managers" "port_ranges" "protocol" "scope" "vendor_id"] }
def accept-completer-20 [] { ["application/json" "entity_id" "entity_type" "ip_address" "name"] }
def accept-completer-21 [] { ["application/json" "entity_id" "entity_type" "host" "ip_addresses" "layer2_network" "name" "vlan"] }
def accept-completer-22 [] { ["application/json" "applied_to_destination_rules" "applied_to_source_rules" "cluster" "datacenter" "datastores" "default_gateway" "destination_firewall_rules" "destination_inversion_rules" "entity_id" "entity_type" "folders" "host" "ip_addresses" "ip_sets" "layer2_networks" "name" "nsx_manager" "resource_pool" "security_groups" "security_tags" "source_firewall_rules" "source_inversion_rules" "vcenter_manager" "vendor_id" "vlans" "vnics"] }
def accept-completer-23 [] { ["application/json" "entity_id" "entity_type" "ip_addresses" "layer2_network" "name" "vlan" "vm"] }
def accept-completer-24 [] { ["application/json" "create_time" "created_by" "entity_id" "entity_type" "last_modified_by" "last_modified_time" "name"] }
def accept-completer-25 [] { ["application/json" "results"] }
def accept-completer-26 [] { ["application" "application/json" "entity_id" "entity_type" "group_membership_criteria" "name"] }
def accept-completer-27 [] { ["application/json" "entity_type" "id" "ip_address" "node_id" "node_type"] }
def accept-completer-28 [] { ["application/json" "results" "time_range"] }
def entity-type-completer-1 [] { ["Application" "BaseEvent" "BaseFirewall" "BaseFirewallRule" "BaseIPSet" "BaseL2Network" "BaseManager" "BaseNSXManager" "BaseSecurityGroup" "BaseService" "BaseServiceGroup" "BaseVirtualMachine" "BaseVnic" "Cluster" "Datastore" "DistributedVirtualPortgroup" "DistributedVirtualSwitch" "EC2Firewall" "EC2IPSet" "EC2Instance" "EC2SGFirewallRule" "EC2SecurityGroup" "EC2Service" "Flow" "Folder" "Group" "Host" "NSXDistributedFirewall" "NSXFirewallRule" "NSXIPSet" "NSXRedirectRule" "NSXSecurityGroup" "NSXService" "NSXServiceGroup" "NSXVManager" "ProblemEvent" "ResourcePool" "SecurityTag" "Tier" "VCDatacenter" "VCenterManager" "VPC" "VirtualMachine" "VlanL2Network" "Vmknic" "Vnic" "VxlanLayer2Network"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create: "record<expiry: int, token: string>"
    list-arista-switches: "record<results: table<entity_id: string, entity_type: string>, total_count: int>"
    add-arista-switch: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    get-arista-switch: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    update-arista-switch: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    get-arista-switch-snmp-config: "record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>"
    update-arista-switch-snmp-config: "record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>"
    list-brocade-switches: "record<results: table<entity_id: string, entity_type: string>, total_count: int>"
    add-brocade-switch: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    get-brocade-switch: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    update-brocade-switch: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    get-brocade-switch-snmp-config: "record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>"
    update-brocade-switch-snmp-config: "record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>"
    list-checkpoint-firewalls: "record<results: table<entity_id: string, entity_type: string>, total_count: int>"
    add-checkpoint-firewall: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    get-checkpoint-firewall: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    update-checkpoint-firewall: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    list-cisco-switches: "record<results: table<entity_id: string, entity_type: string>, total_count: int>"
    add-cisco-switch: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>, switch_type: string>"
    get-cisco-switch: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>, switch_type: string>"
    update-cisco-switch: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>, switch_type: string>"
    get-cisco-switch-snmp-config: "record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>"
    update-cisco-switch-snmp-config: "record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>"
    list-dell-switches: "record<results: table<entity_id: string, entity_type: string>, total_count: int>"
    add-dell-switch: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>, switch_type: string>"
    get-dell-switch: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>, switch_type: string>"
    update-dell-switch: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>, switch_type: string>"
    get-dell-switch-snmp-config: "record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>"
    update-dell-switch-snmp-config: "record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>"
    list-hpov-managers: "record<results: table<entity_id: string, entity_type: string>, total_count: int>"
    add-hpov-manager: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    get-hpov-manager: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    update-hpov-manager: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    list-hpvc-managers: "record<results: table<entity_id: string, entity_type: string>, total_count: int>"
    add-hpvc-manager: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    get-hpvc-manager: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    update-hpvc-manager: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    list-juniper-switches: "record<results: table<entity_id: string, entity_type: string>, total_count: int>"
    add-juniper-switch: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    get-juniper-switch: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    update-juniper-switch: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    get-juniper-switch-snmp-config: "record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>"
    update-juniper-switch-snmp-config: "record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>"
    list-nsxv-managers: "record<results: table<entity_id: string, entity_type: string>, total_count: int>"
    add-nsxv-manager-datasource: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, central_cli_enabled: bool, credentials: record<password: string, username: string>, ipfix_enabled: bool, vcenter_id: string>"
    get-nsxv-manager: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, central_cli_enabled: bool, credentials: record<password: string, username: string>, ipfix_enabled: bool, vcenter_id: string>"
    update-nsxv-manager: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, central_cli_enabled: bool, credentials: record<password: string, username: string>, ipfix_enabled: bool, vcenter_id: string>"
    get-nsxv-controller-cluster: "record<controller_password: string, enabled: bool>"
    update-nsxv-controller-cluster: "record<controller_password: string, enabled: bool>"
    list-panorama-firewalls: "record<results: table<entity_id: string, entity_type: string>, total_count: int>"
    add-panorama-firewall: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    get-panorama-firewall: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    update-panorama-firewall: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    list-ucs-managers: "record<results: table<entity_id: string, entity_type: string>, total_count: int>"
    add-ucs-manager: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    get-ucs-manager: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    update-ucs-manager: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    get-ucs-snmp-config: "record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>"
    update-ucs-snmp-config: "record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>"
    list-vcenters: "record<results: table<entity_id: string, entity_type: string>, total_count: int>"
    add-vcenter-datasource: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    get-vcenter: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    update-vcenter: "record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>"
    list-clusters: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-cluster: "record<entity_id: string, entity_type: string, name: string, nsx_manager: record<entity_id: string, entity_type: string>, num_cpu_cores: int, num_datastores: int, num_hosts: int, total_cpus: int, total_memory: int, vcenter_manager: record<entity_id: string, entity_type: string>, vendor_id: string>"
    list-datastores: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-datastore: "record<entity_id: string, entity_type: string, name: string, vcenter_manager: record<entity_id: string, entity_type: string>, vendor_id: string>"
    list-distributed-virtual-portgroups: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-distributed-virtual-portgroup: "record<entity_id: string, entity_type: string, name: string, distributed_virtual_switch: record<entity_id: string, entity_type: string>, vcenter_manager: record<entity_id: string, entity_type: string>, vendor_id: string>"
    list-distributed-virtual-switches: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-distributed-virtual-switch: "record<entity_id: string, entity_type: string, name: string, hosts: table<entity_id: string, entity_type: string>, vcenter_manager: record<entity_id: string, entity_type: string>, vendor_id: string>"
    list-firewall-rules: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-firewall-rule: "record<entity_id: string, entity_type: string, name: string, action: string, destination_any: bool, destination_inversion: bool, destinations: table<entity_id: string, entity_type: string>, disabled: bool, port_ranges: table<display: string, end: int, iana_name: string, iana_port_display: string, start: int>, rule_id: string, section_id: string, section_name: string, sequence_number: int, service_any: bool, services: table<entity_id: string, entity_type: string>, source_any: bool, source_inversion: bool, sources: table<entity_id: string, entity_type: string>>"
    list-firewalls: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-firewall: "record<entity_id: string, entity_type: string, name: string, action: string, destination_any: bool, destination_inversion: bool, destinations: table<entity_id: string, entity_type: string>, disabled: bool, port_ranges: table<display: string, end: int, iana_name: string, iana_port_display: string, start: int>, rule_id: string, section_id: string, section_name: string, sequence_number: int, service_any: bool, services: table<entity_id: string, entity_type: string>, source_any: bool, source_inversion: bool, sources: table<entity_id: string, entity_type: string>>"
    get-flows: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-flow: "record<entity_id: string, entity_type: string, name: string, destination_cluster: record<entity_id: string, entity_type: string>, destination_datacenter: record<entity_id: string, entity_type: string>, destination_folders: table<entity_id: string, entity_type: string>, destination_host: record<entity_id: string, entity_type: string>, destination_ip: record<ip_address: string, netmask: string, network_address: string>, destination_ip_sets: table<entity_id: string, entity_type: string>, destination_l2_network: record<entity_id: string, entity_type: string>, destination_resource_pool: record<entity_id: string, entity_type: string>, destination_security_groups: table<entity_id: string, entity_type: string>, destination_security_tags: table<entity_id: string, entity_type: string>, destination_vm: record<entity_id: string, entity_type: string>, destination_vm_tags: list<string>, destination_vnic: record<entity_id: string, entity_type: string>, destination_vpc: record<entity_id: string, entity_type: string>, firewall_action: string, flow_tag: list<string>, port: record<display: string, end: int, iana_name: string, iana_port_display: string, start: int>, protocol: string, source_cluster: record<entity_id: string, entity_type: string>, source_datacenter: record<entity_id: string, entity_type: string>, source_folders: table<entity_id: string, entity_type: string>, source_host: record<entity_id: string, entity_type: string>, source_ip: record<ip_address: string, netmask: string, network_address: string>, source_ip_sets: table<entity_id: string, entity_type: string>, source_l2_network: record<entity_id: string, entity_type: string>, source_resource_pool: record<entity_id: string, entity_type: string>, source_security_groups: table<entity_id: string, entity_type: string>, source_security_tags: table<entity_id: string, entity_type: string>, source_vm: record<entity_id: string, entity_type: string>, source_vm_tags: list<string>, source_vnic: record<entity_id: string, entity_type: string>, source_vpc: record<entity_id: string, entity_type: string>, traffic_type: string, within_host: bool>"
    list-folders: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-folder: "record<entity_id: string, entity_type: string, name: string, vcenter_manager: record<entity_id: string, entity_type: string>, vendor_id: string>"
    list-hosts: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-host: "record<entity_id: string, entity_type: string, name: string, cluster: record<entity_id: string, entity_type: string>, connection_state: string, datastores: table<entity_id: string, entity_type: string>, maintenance_mode: string, nsx_manager: record<entity_id: string, entity_type: string>, service_tag: string, vcenter_manager: record<entity_id: string, entity_type: string>, vendor_id: string, vm_count: int, vmknics: table<entity_id: string, entity_type: string>>"
    list-ip-sets: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-ip-set: "record<entity_id: string, entity_type: string, name: string, direct_destination_rules: table<firewall: record, rule_set_type: string, rules: list>, direct_source_rules: table<firewall: record, rule_set_type: string, rules: list>, indirect_destination_rules: table<firewall: record, rule_set_type: string, rules: list>, indirect_source_rules: table<firewall: record, rule_set_type: string, rules: list>, ip_addresses: table<ip_address: string, netmask: string, network_address: string>, ip_numeric_ranges: table<end: int, start: int>, ip_ranges: table<end_ip: string, start_ip: string>, parent_security_groups: table<entity_id: string, entity_type: string>, translated_vm_count: int, vendor: string, vendor_id: string>"
    list-layer2-networks: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-layer2-network: "record<entity_id: string, entity_type: string, name: string, gateways: list<string>, network_addresses: list<string>>"
    get-names: "record<entities: table<entity_id: string, entity_type: string, time: int, name: string>>"
    get-name: "record<entity_id: string, entity_type: string, time: int, name: string>"
    list-nsx-managers: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-nsx-manager: "record<entity_id: string, entity_type: string, name: string>"
    list-problem-events: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-problem-event: "record<entity_id: string, entity_type: string, name: string, admin_state: string, anchor_entities: table<entity_id: string, entity_type: string>, archived: bool, event_tags: list<string>, event_time_epoch_ms: int, message: string, related_entities: table<entity_id: string, entity_type: string>, event_close_time_epoch_ms: int, severity: string>"
    list-security-groups: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-security-group: "record<entity_id: string, entity_type: string, name: string, members: table<entity_id: string, entity_type: string>, direct_destination_rules: table<firewall: record, rule_set_type: string, rules: list>, direct_members: table<entity_id: string, entity_type: string>, direct_source_rules: table<firewall: record, rule_set_type: string, rules: list>, excluded_members: table<entity_id: string, entity_type: string>, indirect_destination_rules: table<firewall: record, rule_set_type: string, rules: list>, indirect_source_rules: table<firewall: record, rule_set_type: string, rules: list>, parents: table<entity_id: string, entity_type: string>, translated_vm_count: int, vendor_id: string>"
    list-security-tags: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-security-tag: "record<entity_id: string, entity_type: string, name: string, description: string, direct_security_groups: table<entity_id: string, entity_type: string>, nsx_manager: record<entity_id: string, entity_type: string>, security_groups: table<entity_id: string, entity_type: string>, vendor_id: string>"
    list-service-groups: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-service-group: "record<entity_id: string, entity_type: string, name: string, members: table<entity_id: string, entity_type: string>>"
    list-services: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-service: "record<entity_id: string, entity_type: string, name: string, port_ranges: table<display: string, end: int, iana_name: string, iana_port_display: string, start: int>, protocol: string>"
    list-datacenters: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-datacenter: "record<entity_id: string, entity_type: string, name: string, vcenter_manager: record<entity_id: string, entity_type: string>, vendor_id: string>"
    list-vcenter-managers: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-vcenter-manager: "record<entity_id: string, entity_type: string, name: string, fqdn: string, ip_address: record<ip_address: string, netmask: string, network_address: string>, nsx_manager: record<entity_id: string, entity_type: string>, vm: record<entity_id: string, entity_type: string>>"
    list-vmknics: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-vmknic: "record<entity_id: string, entity_type: string, name: string, host: record<entity_id: string, entity_type: string>, ip_addresses: table<ip_address: string, netmask: string, network_address: string>, layer2_network: record<entity_id: string, entity_type: string>, vlan: record<begin: int, end: int>>"
    list-vms: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-vm: "record<entity_id: string, entity_type: string, name: string, default_gateway: string, destination_firewall_rules: table<firewall: record, rule_set_type: string, rules: list>, ip_addresses: table<ip_address: string, netmask: string, network_address: string>, ip_sets: table<entity_id: string, entity_type: string>, security_groups: table<entity_id: string, entity_type: string>, source_firewall_rules: table<firewall: record, rule_set_type: string, rules: list>, vnics: table<entity_id: string, entity_type: string>>"
    list-vnics: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
    get-vnic: "record<entity_id: string, entity_type: string, name: string, ip_addresses: table<ip_address: string, netmask: string, network_address: string>, layer2_network: record<entity_id: string, entity_type: string>, vlan: record<begin: int, end: int>, vm: record<entity_id: string, entity_type: string>>"
    list-applications: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string>, start_time: int, total_count: int>"
    add-application: "record<entity_id: string, entity_type: string, name: string, create_time: int, created_by: string, last_modified_by: string, last_modified_time: int>"
    get-application: "record<entity_id: string, entity_type: string, name: string, create_time: int, created_by: string, last_modified_by: string, last_modified_time: int>"
    list-application-tiers: "record<results: table<entity_id: string, entity_type: string, name: string, application: record, group_membership_criteria: list>>"
    add-tier: "record<entity_id: string, entity_type: string, name: string, application: record<entity_id: string, entity_type: string>, group_membership_criteria: table<ip_address_membership_criteria: record, membership_type: string, search_membership_criteria: record>>"
    get-application-tier: "record<entity_id: string, entity_type: string, name: string, application: record<entity_id: string, entity_type: string>, group_membership_criteria: table<ip_address_membership_criteria: record, membership_type: string, search_membership_criteria: record>>"
    get-tier: "record<entity_id: string, entity_type: string, name: string, application: record<entity_id: string, entity_type: string>, group_membership_criteria: table<ip_address_membership_criteria: record, membership_type: string, search_membership_criteria: record>>"
    get-version: "record<api_version: string>"
    list-nodes: "record<results: table<entity_type: string, id: string>, total_count: int>"
    get-node: "record<entity_type: string, id: string, ip_address: string, name: string, node_id: string, node_type: string>"
    list-recommended-rules: "record<results: table<action: string, destinations: list, port_ranges: list, protocols: list, sources: list>, time_range: record<end_time: int, start_time: int>>"
    export-nsx-recommended-rules: "binary"
    search-entities: "record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["delete" "create" "list-arista-switches" "add-arista-switch" "delete-arista-switch" "get-arista-switch" "update-arista-switch" "disable-arista-switch" "enable-arista-switch" "get-arista-switch-snmp-config" "update-arista-switch-snmp-config" "list-brocade-switches" "add-brocade-switch" "delete-brocade-switch" "get-brocade-switch" "update-brocade-switch" "disable-brocade-switch" "enable-brocade-switch" "get-brocade-switch-snmp-config" "update-brocade-switch-snmp-config" "list-checkpoint-firewalls" "add-checkpoint-firewall" "delete-checkpoint-firewall" "get-checkpoint-firewall" "update-checkpoint-firewall" "disable-checkpoint-firewall" "enable-checkpoint-firewall" "list-cisco-switches" "add-cisco-switch" "delete-cisco-switch" "get-cisco-switch" "update-cisco-switch" "disable-cisco-switch" "enable-cisco-switch" "get-cisco-switch-snmp-config" "update-cisco-switch-snmp-config" "list-dell-switches" "add-dell-switch" "delete-dell-switch" "get-dell-switch" "update-dell-switch" "disable-dell-switch" "enable-dell-switch" "get-dell-switch-snmp-config" "update-dell-switch-snmp-config" "list-hpov-managers" "add-hpov-manager" "delete-hpov-manager" "get-hpov-manager" "update-hpov-manager" "disable-hpov-manager" "enable-hpov-manager" "list-hpvc-managers" "add-hpvc-manager" "delete-hpvc-manager" "get-hpvc-manager" "update-hpvc-manager" "disable-hpvc-manager" "enable-hpvc-manager" "list-juniper-switches" "add-juniper-switch" "delete-juniper-switch" "get-juniper-switch" "update-juniper-switch" "disable-juniper-switch" "enable-juniper-switch" "get-juniper-switch-snmp-config" "update-juniper-switch-snmp-config" "list-nsxv-managers" "add-nsxv-manager-datasource" "delete-nsxv-manager" "get-nsxv-manager" "update-nsxv-manager" "get-nsxv-controller-cluster" "update-nsxv-controller-cluster" "disable-nsxv-manager" "enable-nsxv-manager" "list-panorama-firewalls" "add-panorama-firewall" "delete-panorama-firewall" "get-panorama-firewall" "update-panorama-firewall" "disable-panorama-firewall" "enable-panorama-firewall" "list-ucs-managers" "add-ucs-manager" "delete-ucs-manager" "get-ucs-manager" "update-ucs-manager" "disable-ucs-manager" "enable-ucs-manager" "get-ucs-snmp-config" "update-ucs-snmp-config" "list-vcenters" "add-vcenter-datasource" "delete-vcenter" "get-vcenter" "update-vcenter" "disable-vcenter" "enable-vcenter" "list-clusters" "get-cluster" "list-datastores" "get-datastore" "list-distributed-virtual-portgroups" "get-distributed-virtual-portgroup" "list-distributed-virtual-switches" "get-distributed-virtual-switch" "list-firewall-rules" "get-firewall-rule" "list-firewalls" "get-firewall" "get-flows" "get-flow" "list-folders" "get-folder" "list-hosts" "get-host" "list-ip-sets" "get-ip-set" "list-layer2-networks" "get-layer2-network" "get-names" "get-name" "list-nsx-managers" "get-nsx-manager" "list-problem-events" "get-problem-event" "list-security-groups" "get-security-group" "list-security-tags" "get-security-tag" "list-service-groups" "get-service-group" "list-services" "get-service" "list-datacenters" "get-datacenter" "list-vcenter-managers" "get-vcenter-manager" "list-vmknics" "get-vmknic" "list-vms" "get-vm" "list-vnics" "get-vnic" "list-applications" "add-application" "delete-application" "get-application" "list-application-tiers" "add-tier" "delete-tier" "get-application-tier" "get-tier" "get-version" "list-nodes" "get-node" "list-recommended-rules" "export-nsx-recommended-rules" "search-entities" "commands"] | sort) } | get name | first)
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

# Delete an auth token.
#
# DELETE /auth/token
# operationId: delete
export def "delete" [
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
    path: "/auth/token"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an auth token
#
# POST /auth/token
# Returns: record<expiry: int, token: string>
# operationId: create
export def "create" [
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
  --domain: record # shape: {domain_type?: "LDAP"|"LOCAL", value?: string}
  --password: string # e.g. password
  --username: string # e.g. admin@vrni.com
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/token"
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json", expiry, token]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List arista switch data sources
#
# GET /data-sources/arista-switches
# Returns: record<results: table<entity_id: string, entity_type: string>, total_count: int>
# operationId: listAristaSwitches
export def "list-arista-switches" [
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
    path: "/data-sources/arista-switches"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an arista switch data source
#
# POST /data-sources/arista-switches
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: addAristaSwitch
export def "add-arista-switch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # default: true
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  nickname: string # e.g. vc1
  --notes: string
  proxy_id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/data-sources/arista-switches"
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    enabled: $enabled, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an arista switch data source
#
# DELETE /data-sources/arista-switches/{id}
# operationId: deleteAristaSwitch
export def "delete-arista-switch" [
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
    path: "/data-sources/arista-switches/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show arista switch data source details
#
# GET /data-sources/arista-switches/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: getAristaSwitch
export def "get-arista-switch" [
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
    path: "/data-sources/arista-switches/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an arista switch data source
#
# PUT /data-sources/arista-switches/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: updateAristaSwitch
export def "update-arista-switch" [
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
  --enabled: oneof<nothing, bool> # default: true
  --entity-id: string
  --entity-type: string@entity-type-completer
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  --nickname: string # e.g. vc1
  --notes: string
  --proxy-id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/arista-switches/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: entity_id, var: entity_id}, {name: entity_type, var: entity_type}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, enabled: $enabled, entity_id: $entity_id, entity_type: $entity_type, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable an arista switch data source
#
# POST /data-sources/arista-switches/{id}/disable
# operationId: disableAristaSwitch
export def "disable-arista-switch" [
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
    path: "/data-sources/arista-switches/{id}/disable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable an arista switch data source
#
# POST /data-sources/arista-switches/{id}/enable
# operationId: enableAristaSwitch
export def "enable-arista-switch" [
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
    path: "/data-sources/arista-switches/{id}/enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show snmp config for arista switch data source
#
# GET /data-sources/arista-switches/{id}/snmp-config
# Returns: record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>
# operationId: getAristaSwitchSnmpConfig
export def "get-arista-switch-snmp-config" [
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
    path: "/data-sources/arista-switches/{id}/snmp-config"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update snmp config for arista switch data source
#
# PUT /data-sources/arista-switches/{id}/snmp-config
# Returns: record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>
# operationId: updateAristaSwitchSnmpConfig
export def "update-arista-switch-snmp-config" [
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
  --config-snmp-2c: record # shape: {community_string?: string}
  --config-snmp-3: record # shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
  --snmp-enabled: oneof<nothing, bool> # default: false
  --snmp-version: string@snmp-version-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/arista-switches/{id}/snmp-config"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config_snmp_2c, var: config_snmp_2c}, {name: config_snmp_3, var: config_snmp_3}, {name: snmp_enabled, var: snmp_enabled}, {name: snmp_version, var: snmp_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, config_snmp_2c: $config_snmp_2c, config_snmp_3: $config_snmp_3, snmp_enabled: $snmp_enabled, snmp_version: $snmp_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List brocade switch data sources
#
# GET /data-sources/brocade-switches
# Returns: record<results: table<entity_id: string, entity_type: string>, total_count: int>
# operationId: listBrocadeSwitches
export def "list-brocade-switches" [
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
    path: "/data-sources/brocade-switches"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a brocade switch data source
#
# POST /data-sources/brocade-switches
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: addBrocadeSwitch
export def "add-brocade-switch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # default: true
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  nickname: string # e.g. vc1
  --notes: string
  proxy_id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/data-sources/brocade-switches"
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    enabled: $enabled, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a brocade switch data source
#
# DELETE /data-sources/brocade-switches/{id}
# operationId: deleteBrocadeSwitch
export def "delete-brocade-switch" [
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
    path: "/data-sources/brocade-switches/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show brocade switch data source details
#
# GET /data-sources/brocade-switches/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: getBrocadeSwitch
export def "get-brocade-switch" [
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
    path: "/data-sources/brocade-switches/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a brocade switch data source
#
# PUT /data-sources/brocade-switches/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: updateBrocadeSwitch
export def "update-brocade-switch" [
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
  --enabled: oneof<nothing, bool> # default: true
  --entity-id: string
  --entity-type: string@entity-type-completer
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  --nickname: string # e.g. vc1
  --notes: string
  --proxy-id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/brocade-switches/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: entity_id, var: entity_id}, {name: entity_type, var: entity_type}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, enabled: $enabled, entity_id: $entity_id, entity_type: $entity_type, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a brocade switch data source
#
# POST /data-sources/brocade-switches/{id}/disable
# operationId: disableBrocadeSwitch
export def "disable-brocade-switch" [
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
    path: "/data-sources/brocade-switches/{id}/disable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a brocade switch data source
#
# POST /data-sources/brocade-switches/{id}/enable
# operationId: enableBrocadeSwitch
export def "enable-brocade-switch" [
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
    path: "/data-sources/brocade-switches/{id}/enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show snmp config for brocade switch data source
#
# GET /data-sources/brocade-switches/{id}/snmp-config
# Returns: record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>
# operationId: getBrocadeSwitchSnmpConfig
export def "get-brocade-switch-snmp-config" [
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
    path: "/data-sources/brocade-switches/{id}/snmp-config"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update snmp config for brocade switch data source
#
# PUT /data-sources/brocade-switches/{id}/snmp-config
# Returns: record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>
# operationId: updateBrocadeSwitchSnmpConfig
export def "update-brocade-switch-snmp-config" [
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
  --config-snmp-2c: record # shape: {community_string?: string}
  --config-snmp-3: record # shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
  --snmp-enabled: oneof<nothing, bool> # default: false
  --snmp-version: string@snmp-version-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/brocade-switches/{id}/snmp-config"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config_snmp_2c, var: config_snmp_2c}, {name: config_snmp_3, var: config_snmp_3}, {name: snmp_enabled, var: snmp_enabled}, {name: snmp_version, var: snmp_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, config_snmp_2c: $config_snmp_2c, config_snmp_3: $config_snmp_3, snmp_enabled: $snmp_enabled, snmp_version: $snmp_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List checkpoint firewall data sources
#
# GET /data-sources/checkpoint-firewalls
# Returns: record<results: table<entity_id: string, entity_type: string>, total_count: int>
# operationId: listCheckpointFirewalls
export def "list-checkpoint-firewalls" [
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
    path: "/data-sources/checkpoint-firewalls"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a checkpoint firewall
#
# POST /data-sources/checkpoint-firewalls
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: addCheckpointFirewall
export def "add-checkpoint-firewall" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # default: true
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  nickname: string # e.g. vc1
  --notes: string
  proxy_id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/data-sources/checkpoint-firewalls"
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    enabled: $enabled, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a checkpoint firewall data source
#
# DELETE /data-sources/checkpoint-firewalls/{id}
# operationId: deleteCheckpointFirewall
export def "delete-checkpoint-firewall" [
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
    path: "/data-sources/checkpoint-firewalls/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show checkpoint firewall data source details
#
# GET /data-sources/checkpoint-firewalls/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: getCheckpointFirewall
export def "get-checkpoint-firewall" [
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
    path: "/data-sources/checkpoint-firewalls/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a checkpoint firewall data source
#
# PUT /data-sources/checkpoint-firewalls/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: updateCheckpointFirewall
export def "update-checkpoint-firewall" [
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
  --enabled: oneof<nothing, bool> # default: true
  --entity-id: string
  --entity-type: string@entity-type-completer
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  --nickname: string # e.g. vc1
  --notes: string
  --proxy-id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/checkpoint-firewalls/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: entity_id, var: entity_id}, {name: entity_type, var: entity_type}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, enabled: $enabled, entity_id: $entity_id, entity_type: $entity_type, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a checkpoint firewall data source
#
# POST /data-sources/checkpoint-firewalls/{id}/disable
# operationId: disableCheckpointFirewall
export def "disable-checkpoint-firewall" [
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
    path: "/data-sources/checkpoint-firewalls/{id}/disable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a checkpoint firewall data source
#
# POST /data-sources/checkpoint-firewalls/{id}/enable
# operationId: enableCheckpointFirewall
export def "enable-checkpoint-firewall" [
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
    path: "/data-sources/checkpoint-firewalls/{id}/enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List cisco switch data sources
#
# GET /data-sources/cisco-switches
# Returns: record<results: table<entity_id: string, entity_type: string>, total_count: int>
# operationId: listCiscoSwitches
export def "list-cisco-switches" [
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
    path: "/data-sources/cisco-switches"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a cisco switch data source
#
# POST /data-sources/cisco-switches
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>, switch_type: string>
# operationId: addCiscoSwitch
export def "add-cisco-switch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # default: true
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  nickname: string # e.g. vc1
  --notes: string
  proxy_id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
  --switch-type: string@switch-type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/data-sources/cisco-switches"
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}, {name: switch_type, var: switch_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    enabled: $enabled, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials, switch_type: $switch_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a cisco switch data source
#
# DELETE /data-sources/cisco-switches/{id}
# operationId: deleteCiscoSwitch
export def "delete-cisco-switch" [
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
    path: "/data-sources/cisco-switches/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show cisco switch data source details
#
# GET /data-sources/cisco-switches/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>, switch_type: string>
# operationId: getCiscoSwitch
export def "get-cisco-switch" [
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
    path: "/data-sources/cisco-switches/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a cisco switch data source
#
# PUT /data-sources/cisco-switches/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>, switch_type: string>
# operationId: updateCiscoSwitch
export def "update-cisco-switch" [
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
  --enabled: oneof<nothing, bool> # default: true
  --entity-id: string
  --entity-type: string@entity-type-completer
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  --nickname: string # e.g. vc1
  --notes: string
  --proxy-id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
  --switch-type: string@switch-type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/cisco-switches/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: entity_id, var: entity_id}, {name: entity_type, var: entity_type}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}, {name: switch_type, var: switch_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, enabled: $enabled, entity_id: $entity_id, entity_type: $entity_type, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials, switch_type: $switch_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a cisco switch data source
#
# POST /data-sources/cisco-switches/{id}/disable
# operationId: disableCiscoSwitch
export def "disable-cisco-switch" [
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
    path: "/data-sources/cisco-switches/{id}/disable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a cisco switch data source
#
# POST /data-sources/cisco-switches/{id}/enable
# operationId: enableCiscoSwitch
export def "enable-cisco-switch" [
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
    path: "/data-sources/cisco-switches/{id}/enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show snmp config for cisco switch data source
#
# GET /data-sources/cisco-switches/{id}/snmp-config
# Returns: record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>
# operationId: getCiscoSwitchSnmpConfig
export def "get-cisco-switch-snmp-config" [
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
    path: "/data-sources/cisco-switches/{id}/snmp-config"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update snmp config for cisco switch data source
#
# PUT /data-sources/cisco-switches/{id}/snmp-config
# Returns: record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>
# operationId: updateCiscoSwitchSnmpConfig
export def "update-cisco-switch-snmp-config" [
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
  --config-snmp-2c: record # shape: {community_string?: string}
  --config-snmp-3: record # shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
  --snmp-enabled: oneof<nothing, bool> # default: false
  --snmp-version: string@snmp-version-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/cisco-switches/{id}/snmp-config"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config_snmp_2c, var: config_snmp_2c}, {name: config_snmp_3, var: config_snmp_3}, {name: snmp_enabled, var: snmp_enabled}, {name: snmp_version, var: snmp_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, config_snmp_2c: $config_snmp_2c, config_snmp_3: $config_snmp_3, snmp_enabled: $snmp_enabled, snmp_version: $snmp_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List dell switch data sources
#
# GET /data-sources/dell-switches
# Returns: record<results: table<entity_id: string, entity_type: string>, total_count: int>
# operationId: listDellSwitches
export def "list-dell-switches" [
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
    path: "/data-sources/dell-switches"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a dell switch data source
#
# POST /data-sources/dell-switches
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>, switch_type: string>
# operationId: addDellSwitch
export def "add-dell-switch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # default: true
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  nickname: string # e.g. vc1
  --notes: string
  proxy_id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
  --switch-type: string@switch-type-completer-1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/data-sources/dell-switches"
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}, {name: switch_type, var: switch_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    enabled: $enabled, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials, switch_type: $switch_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a dell switch data source
#
# DELETE /data-sources/dell-switches/{id}
# operationId: deleteDellSwitch
export def "delete-dell-switch" [
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
    path: "/data-sources/dell-switches/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show dell switch data source details
#
# GET /data-sources/dell-switches/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>, switch_type: string>
# operationId: getDellSwitch
export def "get-dell-switch" [
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
    path: "/data-sources/dell-switches/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a dell switch data source
#
# PUT /data-sources/dell-switches/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>, switch_type: string>
# operationId: updateDellSwitch
export def "update-dell-switch" [
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
  --enabled: oneof<nothing, bool> # default: true
  --entity-id: string
  --entity-type: string@entity-type-completer
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  --nickname: string # e.g. vc1
  --notes: string
  --proxy-id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
  --switch-type: string@switch-type-completer-1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/dell-switches/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: entity_id, var: entity_id}, {name: entity_type, var: entity_type}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}, {name: switch_type, var: switch_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, enabled: $enabled, entity_id: $entity_id, entity_type: $entity_type, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials, switch_type: $switch_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a dell switch data source
#
# POST /data-sources/dell-switches/{id}/disable
# operationId: disableDellSwitch
export def "disable-dell-switch" [
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
    path: "/data-sources/dell-switches/{id}/disable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a dell switch data source
#
# POST /data-sources/dell-switches/{id}/enable
# operationId: enableDellSwitch
export def "enable-dell-switch" [
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
    path: "/data-sources/dell-switches/{id}/enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show snmp config for dell switch data source
#
# GET /data-sources/dell-switches/{id}/snmp-config
# Returns: record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>
# operationId: getDellSwitchSnmpConfig
export def "get-dell-switch-snmp-config" [
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
    path: "/data-sources/dell-switches/{id}/snmp-config"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update snmp config for dell switch data source
#
# PUT /data-sources/dell-switches/{id}/snmp-config
# Returns: record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>
# operationId: updateDellSwitchSnmpConfig
export def "update-dell-switch-snmp-config" [
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
  --config-snmp-2c: record # shape: {community_string?: string}
  --config-snmp-3: record # shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
  --snmp-enabled: oneof<nothing, bool> # default: false
  --snmp-version: string@snmp-version-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/dell-switches/{id}/snmp-config"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config_snmp_2c, var: config_snmp_2c}, {name: config_snmp_3, var: config_snmp_3}, {name: snmp_enabled, var: snmp_enabled}, {name: snmp_version, var: snmp_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, config_snmp_2c: $config_snmp_2c, config_snmp_3: $config_snmp_3, snmp_enabled: $snmp_enabled, snmp_version: $snmp_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List hp oneview manager data sources
#
# GET /data-sources/hpov-managers
# Returns: record<results: table<entity_id: string, entity_type: string>, total_count: int>
# operationId: listHpovManagers
export def "list-hpov-managers" [
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
    path: "/data-sources/hpov-managers"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a hp oneview manager data source
#
# POST /data-sources/hpov-managers
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: addHpovManager
export def "add-hpov-manager" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # default: true
  --entity-id: string
  --entity-type: string@entity-type-completer
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  --nickname: string # e.g. vc1
  --notes: string
  --proxy-id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/data-sources/hpov-managers"
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: entity_id, var: entity_id}, {name: entity_type, var: entity_type}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    enabled: $enabled, entity_id: $entity_id, entity_type: $entity_type, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a hp oneview data source
#
# DELETE /data-sources/hpov-managers/{id}
# operationId: deleteHpovManager
export def "delete-hpov-manager" [
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
    path: "/data-sources/hpov-managers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show hp oneview data source details
#
# GET /data-sources/hpov-managers/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: getHpovManager
export def "get-hpov-manager" [
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
    path: "/data-sources/hpov-managers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a hp oneview data source
#
# PUT /data-sources/hpov-managers/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: updateHpovManager
export def "update-hpov-manager" [
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
  --enabled: oneof<nothing, bool> # default: true
  --entity-id: string
  --entity-type: string@entity-type-completer
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  --nickname: string # e.g. vc1
  --notes: string
  --proxy-id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/hpov-managers/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: entity_id, var: entity_id}, {name: entity_type, var: entity_type}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, enabled: $enabled, entity_id: $entity_id, entity_type: $entity_type, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a hp oneview data source
#
# POST /data-sources/hpov-managers/{id}/disable
# operationId: disableHpovManager
export def "disable-hpov-manager" [
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
    path: "/data-sources/hpov-managers/{id}/disable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a hp oneview data source
#
# POST /data-sources/hpov-managers/{id}/enable
# operationId: enableHpovManager
export def "enable-hpov-manager" [
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
    path: "/data-sources/hpov-managers/{id}/enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List hpvc manager data sources
#
# GET /data-sources/hpvc-managers
# Returns: record<results: table<entity_id: string, entity_type: string>, total_count: int>
# operationId: listHpvcManagers
export def "list-hpvc-managers" [
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
    path: "/data-sources/hpvc-managers"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a hpvc manager data source
#
# POST /data-sources/hpvc-managers
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: addHpvcManager
export def "add-hpvc-manager" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # default: true
  --entity-id: string
  --entity-type: string@entity-type-completer
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  --nickname: string # e.g. vc1
  --notes: string
  --proxy-id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/data-sources/hpvc-managers"
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: entity_id, var: entity_id}, {name: entity_type, var: entity_type}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    enabled: $enabled, entity_id: $entity_id, entity_type: $entity_type, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a hpvc manager data source
#
# DELETE /data-sources/hpvc-managers/{id}
# operationId: deleteHpvcManager
export def "delete-hpvc-manager" [
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
    path: "/data-sources/hpvc-managers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show hpvc data source details
#
# GET /data-sources/hpvc-managers/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: getHpvcManager
export def "get-hpvc-manager" [
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
    path: "/data-sources/hpvc-managers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a hpvc manager data source
#
# PUT /data-sources/hpvc-managers/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: updateHpvcManager
export def "update-hpvc-manager" [
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
  --enabled: oneof<nothing, bool> # default: true
  --entity-id: string
  --entity-type: string@entity-type-completer
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  --nickname: string # e.g. vc1
  --notes: string
  --proxy-id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/hpvc-managers/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: entity_id, var: entity_id}, {name: entity_type, var: entity_type}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, enabled: $enabled, entity_id: $entity_id, entity_type: $entity_type, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a hpvc manager data source
#
# POST /data-sources/hpvc-managers/{id}/disable
# operationId: disableHpvcManager
export def "disable-hpvc-manager" [
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
    path: "/data-sources/hpvc-managers/{id}/disable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a hpvc manager data source
#
# POST /data-sources/hpvc-managers/{id}/enable
# operationId: enableHpvcManager
export def "enable-hpvc-manager" [
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
    path: "/data-sources/hpvc-managers/{id}/enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List juniper switch data sources
#
# GET /data-sources/juniper-switches
# Returns: record<results: table<entity_id: string, entity_type: string>, total_count: int>
# operationId: listJuniperSwitches
export def "list-juniper-switches" [
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
    path: "/data-sources/juniper-switches"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a juniper switch as data source
#
# POST /data-sources/juniper-switches
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: addJuniperSwitch
export def "add-juniper-switch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # default: true
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  nickname: string # e.g. vc1
  --notes: string
  proxy_id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/data-sources/juniper-switches"
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    enabled: $enabled, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a juniper switch data source
#
# DELETE /data-sources/juniper-switches/{id}
# operationId: deleteJuniperSwitch
export def "delete-juniper-switch" [
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
    path: "/data-sources/juniper-switches/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show juniper switch data source details
#
# GET /data-sources/juniper-switches/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: getJuniperSwitch
export def "get-juniper-switch" [
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
    path: "/data-sources/juniper-switches/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a juniper switch data source
#
# PUT /data-sources/juniper-switches/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: updateJuniperSwitch
export def "update-juniper-switch" [
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
  --enabled: oneof<nothing, bool> # default: true
  --entity-id: string
  --entity-type: string@entity-type-completer
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  --nickname: string # e.g. vc1
  --notes: string
  --proxy-id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/juniper-switches/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: entity_id, var: entity_id}, {name: entity_type, var: entity_type}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, enabled: $enabled, entity_id: $entity_id, entity_type: $entity_type, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a juniper switch data source
#
# POST /data-sources/juniper-switches/{id}/disable
# operationId: disableJuniperSwitch
export def "disable-juniper-switch" [
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
    path: "/data-sources/juniper-switches/{id}/disable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a juniper switch data source
#
# POST /data-sources/juniper-switches/{id}/enable
# operationId: enableJuniperSwitch
export def "enable-juniper-switch" [
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
    path: "/data-sources/juniper-switches/{id}/enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show snmp config for juniper switch data source
#
# GET /data-sources/juniper-switches/{id}/snmp-config
# Returns: record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>
# operationId: getJuniperSwitchSnmpConfig
export def "get-juniper-switch-snmp-config" [
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
    path: "/data-sources/juniper-switches/{id}/snmp-config"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update snmp config for a juniper switch data source
#
# PUT /data-sources/juniper-switches/{id}/snmp-config
# Returns: record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>
# operationId: updateJuniperSwitchSnmpConfig
export def "update-juniper-switch-snmp-config" [
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
  --config-snmp-2c: record # shape: {community_string?: string}
  --config-snmp-3: record # shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
  --snmp-enabled: oneof<nothing, bool> # default: false
  --snmp-version: string@snmp-version-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/juniper-switches/{id}/snmp-config"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config_snmp_2c, var: config_snmp_2c}, {name: config_snmp_3, var: config_snmp_3}, {name: snmp_enabled, var: snmp_enabled}, {name: snmp_version, var: snmp_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, config_snmp_2c: $config_snmp_2c, config_snmp_3: $config_snmp_3, snmp_enabled: $snmp_enabled, snmp_version: $snmp_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List nsx-v manager data sources
#
# GET /data-sources/nsxv-managers
# Returns: record<results: table<entity_id: string, entity_type: string>, total_count: int>
# operationId: listNsxvManagers
export def "list-nsxv-managers" [
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
    path: "/data-sources/nsxv-managers"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a nsx-v manager data source
#
# POST /data-sources/nsxv-managers
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, central_cli_enabled: bool, credentials: record<password: string, username: string>, ipfix_enabled: bool, vcenter_id: string>
# operationId: addNsxvManagerDatasource
export def "add-nsxv-manager-datasource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # default: true
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  nickname: string # e.g. vc1
  --notes: string
  proxy_id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --central-cli-enabled: oneof<nothing, bool> # default: false
  credentials: record # shape: {password: string, username: string}
  --ipfix-enabled: oneof<nothing, bool> # default: false
  vcenter_id: string # Associated vcenter data source entity Id
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/data-sources/nsxv-managers"
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: central_cli_enabled, var: central_cli_enabled}, {name: credentials, var: credentials}, {name: ipfix_enabled, var: ipfix_enabled}, {name: vcenter_id, var: vcenter_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    enabled: $enabled, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, central_cli_enabled: $central_cli_enabled, credentials: $credentials, ipfix_enabled: $ipfix_enabled, vcenter_id: $vcenter_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a nsx-v manager data source
#
# DELETE /data-sources/nsxv-managers/{id}
# operationId: deleteNsxvManager
export def "delete-nsxv-manager" [
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
    path: "/data-sources/nsxv-managers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show nsx-v manager data source details
#
# GET /data-sources/nsxv-managers/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, central_cli_enabled: bool, credentials: record<password: string, username: string>, ipfix_enabled: bool, vcenter_id: string>
# operationId: getNsxvManager
export def "get-nsxv-manager" [
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
    path: "/data-sources/nsxv-managers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a nsx-v manager data source
#
# PUT /data-sources/nsxv-managers/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, central_cli_enabled: bool, credentials: record<password: string, username: string>, ipfix_enabled: bool, vcenter_id: string>
# operationId: updateNsxvManager
export def "update-nsxv-manager" [
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
  --enabled: oneof<nothing, bool> # default: true
  --entity-id: string
  --entity-type: string@entity-type-completer
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  --nickname: string # e.g. vc1
  --notes: string
  --proxy-id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --central-cli-enabled: oneof<nothing, bool> # default: false
  --credentials: record # shape: {password: string, username: string}
  --ipfix-enabled: oneof<nothing, bool> # default: false
  --vcenter-id: string # Associated vcenter data source entity Id
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/nsxv-managers/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: entity_id, var: entity_id}, {name: entity_type, var: entity_type}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: central_cli_enabled, var: central_cli_enabled}, {name: credentials, var: credentials}, {name: ipfix_enabled, var: ipfix_enabled}, {name: vcenter_id, var: vcenter_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, enabled: $enabled, entity_id: $entity_id, entity_type: $entity_type, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, central_cli_enabled: $central_cli_enabled, credentials: $credentials, ipfix_enabled: $ipfix_enabled, vcenter_id: $vcenter_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show nsx controller-cluster details
#
# GET /data-sources/nsxv-managers/{id}/controller-cluster
# Returns: record<controller_password: string, enabled: bool>
# operationId: getNsxvControllerCluster
export def "get-nsxv-controller-cluster" [
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
    path: "/data-sources/nsxv-managers/{id}/controller-cluster"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update nsx controller-cluster details
#
# PUT /data-sources/nsxv-managers/{id}/controller-cluster
# Returns: record<controller_password: string, enabled: bool>
# operationId: updateNsxvControllerCluster
export def "update-nsxv-controller-cluster" [
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
  --controller-password: string
  --enabled: oneof<nothing, bool> # default: false
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/nsxv-managers/{id}/controller-cluster"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: controller_password, var: controller_password}, {name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, controller_password: $controller_password, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a nsx-v manager data source
#
# POST /data-sources/nsxv-managers/{id}/disable
# operationId: disableNsxvManager
export def "disable-nsxv-manager" [
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
    path: "/data-sources/nsxv-managers/{id}/disable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a nsx-v manager data source
#
# POST /data-sources/nsxv-managers/{id}/enable
# operationId: enableNsxvManager
export def "enable-nsxv-manager" [
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
    path: "/data-sources/nsxv-managers/{id}/enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List panorama firewall data sources
#
# GET /data-sources/panorama-firewalls
# Returns: record<results: table<entity_id: string, entity_type: string>, total_count: int>
# operationId: listPanoramaFirewalls
export def "list-panorama-firewalls" [
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
    path: "/data-sources/panorama-firewalls"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create panorama firewall data source
#
# POST /data-sources/panorama-firewalls
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: addPanoramaFirewall
export def "add-panorama-firewall" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # default: true
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  nickname: string # e.g. vc1
  --notes: string
  proxy_id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/data-sources/panorama-firewalls"
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    enabled: $enabled, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a panorama firewall data source
#
# DELETE /data-sources/panorama-firewalls/{id}
# operationId: deletePanoramaFirewall
export def "delete-panorama-firewall" [
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
    path: "/data-sources/panorama-firewalls/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show panorama firewall data source details
#
# GET /data-sources/panorama-firewalls/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: getPanoramaFirewall
export def "get-panorama-firewall" [
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
    path: "/data-sources/panorama-firewalls/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a panorama firewall data source
#
# PUT /data-sources/panorama-firewalls/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: updatePanoramaFirewall
export def "update-panorama-firewall" [
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
  --enabled: oneof<nothing, bool> # default: true
  --entity-id: string
  --entity-type: string@entity-type-completer
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  --nickname: string # e.g. vc1
  --notes: string
  --proxy-id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/panorama-firewalls/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: entity_id, var: entity_id}, {name: entity_type, var: entity_type}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, enabled: $enabled, entity_id: $entity_id, entity_type: $entity_type, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a panorama firewall data source
#
# POST /data-sources/panorama-firewalls/{id}/disable
# operationId: disablePanoramaFirewall
export def "disable-panorama-firewall" [
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
    path: "/data-sources/panorama-firewalls/{id}/disable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a panorama firewall data source
#
# POST /data-sources/panorama-firewalls/{id}/enable
# operationId: enablePanoramaFirewall
export def "enable-panorama-firewall" [
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
    path: "/data-sources/panorama-firewalls/{id}/enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List ucs manager data sources
#
# GET /data-sources/ucs-managers
# Returns: record<results: table<entity_id: string, entity_type: string>, total_count: int>
# operationId: listUcsManagers
export def "list-ucs-managers" [
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
    path: "/data-sources/ucs-managers"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an ucs manager data source
#
# POST /data-sources/ucs-managers
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: addUcsManager
export def "add-ucs-manager" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # default: true
  --entity-id: string
  --entity-type: string@entity-type-completer
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  --nickname: string # e.g. vc1
  --notes: string
  --proxy-id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/data-sources/ucs-managers"
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: entity_id, var: entity_id}, {name: entity_type, var: entity_type}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    enabled: $enabled, entity_id: $entity_id, entity_type: $entity_type, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an ucs manager data source
#
# DELETE /data-sources/ucs-managers/{id}
# operationId: deleteUcsManager
export def "delete-ucs-manager" [
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
    path: "/data-sources/ucs-managers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show ucs manager data source details
#
# GET /data-sources/ucs-managers/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: getUcsManager
export def "get-ucs-manager" [
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
    path: "/data-sources/ucs-managers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an ucs manager data source
#
# PUT /data-sources/ucs-managers/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: updateUcsManager
export def "update-ucs-manager" [
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
  --enabled: oneof<nothing, bool> # default: true
  --entity-id: string
  --entity-type: string@entity-type-completer
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  --nickname: string # e.g. vc1
  --notes: string
  --proxy-id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/ucs-managers/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: entity_id, var: entity_id}, {name: entity_type, var: entity_type}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, enabled: $enabled, entity_id: $entity_id, entity_type: $entity_type, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable an ucs manager data source
#
# POST /data-sources/ucs-managers/{id}/disable
# operationId: disableUcsManager
export def "disable-ucs-manager" [
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
    path: "/data-sources/ucs-managers/{id}/disable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable an ucs manager data source
#
# POST /data-sources/ucs-managers/{id}/enable
# operationId: enableUcsManager
export def "enable-ucs-manager" [
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
    path: "/data-sources/ucs-managers/{id}/enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show snmp config for ucs fabric interconnects
#
# GET /data-sources/ucs-managers/{id}/snmp-config
# Returns: record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>
# operationId: getUcsSnmpConfig
export def "get-ucs-snmp-config" [
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
    path: "/data-sources/ucs-managers/{id}/snmp-config"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update snmp config for ucs fabric interconnects
#
# PUT /data-sources/ucs-managers/{id}/snmp-config
# Returns: record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string>
# operationId: updateUcsSnmpConfig
export def "update-ucs-snmp-config" [
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
  --config-snmp-2c: record # shape: {community_string?: string}
  --config-snmp-3: record # shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
  --snmp-enabled: oneof<nothing, bool> # default: false
  --snmp-version: string@snmp-version-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/ucs-managers/{id}/snmp-config"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config_snmp_2c, var: config_snmp_2c}, {name: config_snmp_3, var: config_snmp_3}, {name: snmp_enabled, var: snmp_enabled}, {name: snmp_version, var: snmp_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, config_snmp_2c: $config_snmp_2c, config_snmp_3: $config_snmp_3, snmp_enabled: $snmp_enabled, snmp_version: $snmp_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List vCenter data sources
#
# GET /data-sources/vcenters
# Returns: record<results: table<entity_id: string, entity_type: string>, total_count: int>
# operationId: listVcenters
export def "list-vcenters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data-sources/vcenters"
    accept: ["application/json", results, total_count]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a vCenter data source
#
# POST /data-sources/vcenters
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: addVcenterDatasource
export def "add-vcenter-datasource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --enabled: oneof<nothing, bool> # default: true
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  nickname: string # e.g. vc1
  --notes: string
  proxy_id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/data-sources/vcenters"
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json", credentials, enabled, entity_id, entity_type, fqdn, ip, nickname, notes, proxy_id]
    ok: [201]
    auth: bearer
  } {
    enabled: $enabled, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a vCenter data source
#
# DELETE /data-sources/vcenters/{id}
# operationId: deleteVcenter
export def "delete-vcenter" [
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
    path: "/data-sources/vcenters/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show vCenter data source details
#
# GET /data-sources/vcenters/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: getVcenter
export def "get-vcenter" [
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
  --accept: string@accept-completer-2 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data-sources/vcenters/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", credentials, enabled, entity_id, entity_type, fqdn, ip, nickname, notes, proxy_id]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a vCenter data source.
#
# PUT /data-sources/vcenters/{id}
# Returns: record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>>
# operationId: updateVcenter
export def "update-vcenter" [
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
  --enabled: oneof<nothing, bool> # default: true
  --entity-id: string
  --entity-type: string@entity-type-completer
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  --nickname: string # e.g. vc1
  --notes: string
  --proxy-id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data-sources/vcenters/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: entity_id, var: entity_id}, {name: entity_type, var: entity_type}, {name: fqdn, var: fqdn}, {name: ip, var: ip}, {name: nickname, var: nickname}, {name: notes, var: notes}, {name: proxy_id, var: proxy_id}, {name: credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, enabled: $enabled, entity_id: $entity_id, entity_type: $entity_type, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a vCenter data source
#
# POST /data-sources/vcenters/{id}/disable
# operationId: disableVcenter
export def "disable-vcenter" [
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
    path: "/data-sources/vcenters/{id}/disable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a vCenter data source
#
# POST /data-sources/vcenters/{id}/enable
# operationId: enableVcenter
export def "enable-vcenter" [
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
    path: "/data-sources/vcenters/{id}/enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List clusters
#
# GET /entities/clusters
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listClusters
export def "list-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/clusters"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show cluster details
#
# GET /entities/clusters/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, nsx_manager: record<entity_id: string, entity_type: string>, num_cpu_cores: int, num_datastores: int, num_hosts: int, total_cpus: int, total_memory: int, vcenter_manager: record<entity_id: string, entity_type: string>, vendor_id: string>
# operationId: getCluster
export def "get-cluster" [
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
  --accept: string@accept-completer-4 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/clusters/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", entity_id, entity_type, name, nsx_manager, num_cpu_cores, num_datastores, num_hosts, total_cpus, total_memory, vcenter_manager, vendor_id]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List datastores
#
# GET /entities/datastores
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listDatastores
export def "list-datastores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/datastores"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show datastore details
#
# GET /entities/datastores/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, vcenter_manager: record<entity_id: string, entity_type: string>, vendor_id: string>
# operationId: getDatastore
export def "get-datastore" [
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
  --accept: string@accept-completer-5 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/datastores/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", entity_id, entity_type, name, vcenter_manager, vendor_id]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List distributed virtual portgroups
#
# GET /entities/distributed-virtual-portgroups
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listDistributedVirtualPortgroups
export def "list-distributed-virtual-portgroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/distributed-virtual-portgroups"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show distributed virtual portgroup details
#
# GET /entities/distributed-virtual-portgroups/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, distributed_virtual_switch: record<entity_id: string, entity_type: string>, vcenter_manager: record<entity_id: string, entity_type: string>, vendor_id: string>
# operationId: getDistributedVirtualPortgroup
export def "get-distributed-virtual-portgroup" [
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
  --accept: string@accept-completer-6 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/distributed-virtual-portgroups/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", distributed_virtual_switch, entity_id, entity_type, name, vcenter_manager, vendor_id]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List distributed virtual switches
#
# GET /entities/distributed-virtual-switches
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listDistributedVirtualSwitches
export def "list-distributed-virtual-switches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/distributed-virtual-switches"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show distributed virtual switch details
#
# GET /entities/distributed-virtual-switches/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, hosts: table<entity_id: string, entity_type: string>, vcenter_manager: record<entity_id: string, entity_type: string>, vendor_id: string>
# operationId: getDistributedVirtualSwitch
export def "get-distributed-virtual-switch" [
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
  --accept: string@accept-completer-7 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/distributed-virtual-switches/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", entity_id, entity_type, hosts, name, vcenter_manager, vendor_id]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List firewall rules
#
# GET /entities/firewall-rules
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listFirewallRules
export def "list-firewall-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/firewall-rules"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show firewall rule details
#
# GET /entities/firewall-rules/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, action: string, destination_any: bool, destination_inversion: bool, destinations: table<entity_id: string, entity_type: string>, disabled: bool, port_ranges: table<display: string, end: int, iana_name: string, iana_port_display: string, start: int>, rule_id: string, section_id: string, section_name: string, sequence_number: int, service_any: bool, services: table<entity_id: string, entity_type: string>, source_any: bool, source_inversion: bool, sources: table<entity_id: string, entity_type: string>>
# operationId: getFirewallRule
export def "get-firewall-rule" [
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
  --accept: string@accept-completer-8 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/firewall-rules/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: [action, "application/json", destination_any, destination_inversion, destinations, direction, disabled, entity_id, entity_type, logging_enabled, name, nsx_managers, port_ranges, rule_id, scope, section_id, section_name, sequence_number, service_any, services, source_any, source_inversion, sources]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List firewalls
#
# GET /entities/firewalls
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listFirewalls
export def "list-firewalls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/firewalls"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show firewall details
#
# GET /entities/firewalls/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, action: string, destination_any: bool, destination_inversion: bool, destinations: table<entity_id: string, entity_type: string>, disabled: bool, port_ranges: table<display: string, end: int, iana_name: string, iana_port_display: string, start: int>, rule_id: string, section_id: string, section_name: string, sequence_number: int, service_any: bool, services: table<entity_id: string, entity_type: string>, source_any: bool, source_inversion: bool, sources: table<entity_id: string, entity_type: string>>
# operationId: getFirewall
export def "get-firewall" [
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
  --accept: string@accept-completer-9 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/firewalls/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", entity_id, entity_type, exclusions, firewall_rules, name]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List flows
#
# GET /entities/flows
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: getFlows
export def "get-flows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/flows"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show flow details
#
# GET /entities/flows/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, destination_cluster: record<entity_id: string, entity_type: string>, destination_datacenter: record<entity_id: string, entity_type: string>, destination_folders: table<entity_id: string, entity_type: string>, destination_host: record<entity_id: string, entity_type: string>, destination_ip: record<ip_address: string, netmask: string, network_address: string>, destination_ip_sets: table<entity_id: string, entity_type: string>, destination_l2_network: record<entity_id: string, entity_type: string>, destination_resource_pool: record<entity_id: string, entity_type: string>, destination_security_groups: table<entity_id: string, entity_type: string>, destination_security_tags: table<entity_id: string, entity_type: string>, destination_vm: record<entity_id: string, entity_type: string>, destination_vm_tags: list<string>, destination_vnic: record<entity_id: string, entity_type: string>, destination_vpc: record<entity_id: string, entity_type: string>, firewall_action: string, flow_tag: list<string>, port: record<display: string, end: int, iana_name: string, iana_port_display: string, start: int>, protocol: string, source_cluster: record<entity_id: string, entity_type: string>, source_datacenter: record<entity_id: string, entity_type: string>, source_folders: table<entity_id: string, entity_type: string>, source_host: record<entity_id: string, entity_type: string>, source_ip: record<ip_address: string, netmask: string, network_address: string>, source_ip_sets: table<entity_id: string, entity_type: string>, source_l2_network: record<entity_id: string, entity_type: string>, source_resource_pool: record<entity_id: string, entity_type: string>, source_security_groups: table<entity_id: string, entity_type: string>, source_security_tags: table<entity_id: string, entity_type: string>, source_vm: record<entity_id: string, entity_type: string>, source_vm_tags: list<string>, source_vnic: record<entity_id: string, entity_type: string>, source_vpc: record<entity_id: string, entity_type: string>, traffic_type: string, within_host: bool>
# operationId: getFlow
export def "get-flow" [
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
  --accept: string@accept-completer-10 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/flows/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", destination_folders, destination_ip, destination_ip_sets, destination_security_groups, destination_security_tags, destination_vm_tags, entity_id, entity_type, firewall_action, flow_tag, name, port, protocol, source_folders, source_ip, source_ip_sets, source_security_groups, source_security_tags, source_vm_tags, traffic_type, within_host]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List folders
#
# GET /entities/folders
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listFolders
export def "list-folders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/folders"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show folder details
#
# GET /entities/folders/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, vcenter_manager: record<entity_id: string, entity_type: string>, vendor_id: string>
# operationId: getFolder
export def "get-folder" [
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
  --accept: string@accept-completer-5 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/folders/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", entity_id, entity_type, name, vcenter_manager, vendor_id]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List hosts
#
# GET /entities/hosts
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listHosts
export def "list-hosts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/hosts"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show host details
#
# GET /entities/hosts/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, cluster: record<entity_id: string, entity_type: string>, connection_state: string, datastores: table<entity_id: string, entity_type: string>, maintenance_mode: string, nsx_manager: record<entity_id: string, entity_type: string>, service_tag: string, vcenter_manager: record<entity_id: string, entity_type: string>, vendor_id: string, vm_count: int, vmknics: table<entity_id: string, entity_type: string>>
# operationId: getHost
export def "get-host" [
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
  --accept: string@accept-completer-11 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/hosts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", cluster, connection_state, datastores, entity_id, entity_type, maintenance_mode, name, nsx_manager, service_tag, vcenter_manager, vendor_id, vm_count, vmknics]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List ip sets
#
# GET /entities/ip-sets
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listIPSets
export def "list-ip-sets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/ip-sets"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show ip set details
#
# GET /entities/ip-sets/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, direct_destination_rules: table<firewall: record, rule_set_type: string, rules: list>, direct_source_rules: table<firewall: record, rule_set_type: string, rules: list>, indirect_destination_rules: table<firewall: record, rule_set_type: string, rules: list>, indirect_source_rules: table<firewall: record, rule_set_type: string, rules: list>, ip_addresses: table<ip_address: string, netmask: string, network_address: string>, ip_numeric_ranges: table<end: int, start: int>, ip_ranges: table<end_ip: string, start_ip: string>, parent_security_groups: table<entity_id: string, entity_type: string>, translated_vm_count: int, vendor: string, vendor_id: string>
# operationId: getIPSet
export def "get-ip-set" [
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
  --accept: string@accept-completer-12 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/ip-sets/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", direct_destination_rules, direct_source_rules, entity_id, entity_type, indirect_destination_rules, indirect_source_rules, ip_addresses, ip_numeric_ranges, ip_ranges, name, nsx_managers, parent_security_groups, scope, translated_vm_count, vendor, vendor_id]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List layer2 networks
#
# GET /entities/layer2-networks
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listLayer2Networks
export def "list-layer2-networks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/layer2-networks"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show layer2 network details
#
# GET /entities/layer2-networks/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, gateways: list<string>, network_addresses: list<string>>
# operationId: getLayer2Network
export def "get-layer2-network" [
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
  --accept: string@accept-completer-13 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/layer2-networks/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", entity_id, entity_type, gateways, name, network_addresses, nsx_managers, scope, segment_id, vteps]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get names for entities
#
# POST /entities/names
# Returns: record<entities: table<entity_id: string, entity_type: string, time: int, name: string>>
# operationId: getNames
export def "get-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: list # item shape: {entity_id?: string, time?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/entities/names"
    body: {content_type: "application/json", kind: json, fields: [{name: entities, var: entities}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    entities: $entities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get name of an entity
#
# GET /entities/names/{id}
# Returns: record<entity_id: string, entity_type: string, time: int, name: string>
# operationId: getName
export def "get-name" [
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
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/names/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List nsx managers
#
# GET /entities/nsx-managers
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listNSXManagers
export def "list-nsx-managers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/nsx-managers"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show nsx manager details
#
# GET /entities/nsx-managers/{id}
# Returns: record<entity_id: string, entity_type: string, name: string>
# operationId: getNSXManager
export def "get-nsx-manager" [
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
  --accept: string@accept-completer-14 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/nsx-managers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", entity_id, entity_type, ip_address, name, role, version]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List problems
#
# GET /entities/problems
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listProblemEvents
export def "list-problem-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/problems"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show problem details
#
# GET /entities/problems/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, admin_state: string, anchor_entities: table<entity_id: string, entity_type: string>, archived: bool, event_tags: list<string>, event_time_epoch_ms: int, message: string, related_entities: table<entity_id: string, entity_type: string>, event_close_time_epoch_ms: int, severity: string>
# operationId: getProblemEvent
export def "get-problem-event" [
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
  --accept: string@accept-completer-15 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/problems/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: [admin_state, anchor_entities, "application/json", archived, entity_id, entity_type, event_tags, event_time_epoch_ms, message, name, related_entities, severity]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List security groups
#
# GET /entities/security-groups
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listSecurityGroups
export def "list-security-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/security-groups"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show security group details
#
# GET /entities/security-groups/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, members: table<entity_id: string, entity_type: string>, direct_destination_rules: table<firewall: record, rule_set_type: string, rules: list>, direct_members: table<entity_id: string, entity_type: string>, direct_source_rules: table<firewall: record, rule_set_type: string, rules: list>, excluded_members: table<entity_id: string, entity_type: string>, indirect_destination_rules: table<firewall: record, rule_set_type: string, rules: list>, indirect_source_rules: table<firewall: record, rule_set_type: string, rules: list>, parents: table<entity_id: string, entity_type: string>, translated_vm_count: int, vendor_id: string>
# operationId: getSecurityGroup
export def "get-security-group" [
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
  --accept: string@accept-completer-16 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/security-groups/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", direct_destination_rules, direct_members, direct_source_rules, entity_id, entity_type, excluded_members, indirect_destination_rules, indirect_source_rules, ip_sets, members, name, nsx_managers, parents, scope, security_tags, translated_vm_count, vendor_id]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List security tags
#
# GET /entities/security-tags
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listSecurityTags
export def "list-security-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/security-tags"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show security tag details
#
# GET /entities/security-tags/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, description: string, direct_security_groups: table<entity_id: string, entity_type: string>, nsx_manager: record<entity_id: string, entity_type: string>, security_groups: table<entity_id: string, entity_type: string>, vendor_id: string>
# operationId: getSecurityTag
export def "get-security-tag" [
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
  --accept: string@accept-completer-17 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/security-tags/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", description, direct_security_groups, entity_id, entity_type, name, nsx_manager, security_groups, vendor_id]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List service groups
#
# GET /entities/service-groups
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listServiceGroups
export def "list-service-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/service-groups"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show service group details
#
# GET /entities/service-groups/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, members: table<entity_id: string, entity_type: string>>
# operationId: getServiceGroup
export def "get-service-group" [
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
  --accept: string@accept-completer-18 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/service-groups/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", entity_id, entity_type, members, name, nsx_managers, scope, vendor_id]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List services
#
# GET /entities/services
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listServices
export def "list-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/services"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show service details
#
# GET /entities/services/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, port_ranges: table<display: string, end: int, iana_name: string, iana_port_display: string, start: int>, protocol: string>
# operationId: getService
export def "get-service" [
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
  --accept: string@accept-completer-19 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/services/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", entity_id, entity_type, name, nsx_managers, port_ranges, protocol, scope, vendor_id]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List vCenter datacenters
#
# GET /entities/vc-datacenters
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listDatacenters
export def "list-datacenters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/vc-datacenters"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show vCenter datacenter details
#
# GET /entities/vc-datacenters/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, vcenter_manager: record<entity_id: string, entity_type: string>, vendor_id: string>
# operationId: getDatacenter
export def "get-datacenter" [
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
  --accept: string@accept-completer-5 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/vc-datacenters/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", entity_id, entity_type, name, vcenter_manager, vendor_id]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List vCenter managers
#
# GET /entities/vcenter-managers
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listVcenterManagers
export def "list-vcenter-managers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/vcenter-managers"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show vCenter manager details
#
# GET /entities/vcenter-managers/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, fqdn: string, ip_address: record<ip_address: string, netmask: string, network_address: string>, nsx_manager: record<entity_id: string, entity_type: string>, vm: record<entity_id: string, entity_type: string>>
# operationId: getVcenterManager
export def "get-vcenter-manager" [
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
  --accept: string@accept-completer-20 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/vcenter-managers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", entity_id, entity_type, ip_address, name]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List vmknics
#
# GET /entities/vmknics
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listVmknics
export def "list-vmknics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/vmknics"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show vmknic details
#
# GET /entities/vmknics/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, host: record<entity_id: string, entity_type: string>, ip_addresses: table<ip_address: string, netmask: string, network_address: string>, layer2_network: record<entity_id: string, entity_type: string>, vlan: record<begin: int, end: int>>
# operationId: getVmknic
export def "get-vmknic" [
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
  --accept: string@accept-completer-21 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/vmknics/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", entity_id, entity_type, host, ip_addresses, layer2_network, name, vlan]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List vms
#
# GET /entities/vms
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listVms
export def "list-vms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/vms"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show vm details
#
# GET /entities/vms/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, default_gateway: string, destination_firewall_rules: table<firewall: record, rule_set_type: string, rules: list>, ip_addresses: table<ip_address: string, netmask: string, network_address: string>, ip_sets: table<entity_id: string, entity_type: string>, security_groups: table<entity_id: string, entity_type: string>, source_firewall_rules: table<firewall: record, rule_set_type: string, rules: list>, vnics: table<entity_id: string, entity_type: string>>
# operationId: getVm
export def "get-vm" [
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
  --accept: string@accept-completer-22 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/vms/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", applied_to_destination_rules, applied_to_source_rules, cluster, datacenter, datastores, default_gateway, destination_firewall_rules, destination_inversion_rules, entity_id, entity_type, folders, host, ip_addresses, ip_sets, layer2_networks, name, nsx_manager, resource_pool, security_groups, security_tags, source_firewall_rules, source_inversion_rules, vcenter_manager, vendor_id, vlans, vnics]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List vnics
#
# GET /entities/vnics
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: listVnics
export def "list-vnics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/vnics"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", cursor, end_time, results, start_time, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show vnic details
#
# GET /entities/vnics/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, ip_addresses: table<ip_address: string, netmask: string, network_address: string>, layer2_network: record<entity_id: string, entity_type: string>, vlan: record<begin: int, end: int>, vm: record<entity_id: string, entity_type: string>>
# operationId: getVnic
export def "get-vnic" [
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
  --accept: string@accept-completer-23 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities/vnics/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: time, var: time}]
    accept: ["application/json", entity_id, entity_type, ip_addresses, layer2_network, name, vlan, vm]
    ok: [200]
    auth: bearer
  } {
    id: $id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List applications
#
# GET /groups/applications
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string>, start_time: int, total_count: int>
# operationId: listApplications
export def "list-applications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/applications"
    query: [{name: size, var: size}, {name: cursor, var: cursor}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", results, total_count]
    ok: [200]
    auth: bearer
  } {
    size: $size, cursor: $cursor, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an application
#
# POST /groups/applications
# Returns: record<entity_id: string, entity_type: string, name: string, create_time: int, created_by: string, last_modified_by: string, last_modified_time: int>
# operationId: addApplication
export def "add-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-24 # Response content type
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/applications"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", create_time, created_by, entity_id, entity_type, last_modified_by, last_modified_time, name]
    ok: [201]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an application
#
# DELETE /groups/applications/{id}
# operationId: deleteApplication
export def "delete-application" [
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
    path: "/groups/applications/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show application details
#
# GET /groups/applications/{id}
# Returns: record<entity_id: string, entity_type: string, name: string, create_time: int, created_by: string, last_modified_by: string, last_modified_time: int>
# operationId: getApplication
export def "get-application" [
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
  --accept: string@accept-completer-24 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/applications/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", create_time, created_by, entity_id, entity_type, last_modified_by, last_modified_time, name]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List tiers of an application
#
# GET /groups/applications/{id}/tiers
# Returns: record<results: table<entity_id: string, entity_type: string, name: string, application: record, group_membership_criteria: list>>
# operationId: listApplicationTiers
export def "list-application-tiers" [
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
  --accept: string@accept-completer-25 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/applications/{id}/tiers"
    path_params: [{name: id, var: id}]
    accept: ["application/json", results]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create tier in application
#
# POST /groups/applications/{id}/tiers
# Returns: record<entity_id: string, entity_type: string, name: string, application: record<entity_id: string, entity_type: string>, group_membership_criteria: table<ip_address_membership_criteria: record, membership_type: string, search_membership_criteria: record>>
# operationId: addTier
export def "add-tier" [
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
  --accept: string@accept-completer-26 # Response content type
  --group-membership-criteria: list # item shape: {ip_address_membership_criteria?: record, membership_type?: "SearchMembershipCriteria"|"IPAddressMembershipCriteria", search_membership_criteria?: record}
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/applications/{id}/tiers"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: group_membership_criteria, var: group_membership_criteria}, {name: name, var: name}]}
    accept: [application, "application/json", entity_id, entity_type, group_membership_criteria, name]
    ok: [201]
    auth: bearer
  } {
    id: $id, group_membership_criteria: $group_membership_criteria, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete tier
#
# DELETE /groups/applications/{id}/tiers/{tier-id}
# operationId: deleteTier
export def "delete-tier" [
  id: string
  tier_id: string
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
    path: "/groups/applications/{id}/tiers/{tier-id}"
    path_params: [{name: id, var: id}, {name: tier-id, var: tier_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, tier_id: $tier_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show tier details
#
# GET /groups/applications/{id}/tiers/{tier-id}
# Returns: record<entity_id: string, entity_type: string, name: string, application: record<entity_id: string, entity_type: string>, group_membership_criteria: table<ip_address_membership_criteria: record, membership_type: string, search_membership_criteria: record>>
# operationId: getApplicationTier
export def "get-application-tier" [
  id: string
  tier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-26 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/applications/{id}/tiers/{tier-id}"
    path_params: [{name: id, var: id}, {name: tier-id, var: tier_id}]
    accept: [application, "application/json", entity_id, entity_type, group_membership_criteria, name]
    ok: [200]
    auth: bearer
  } {
    id: $id, tier_id: $tier_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show tier details
#
# GET /groups/tiers/{tier-id}
# Returns: record<entity_id: string, entity_type: string, name: string, application: record<entity_id: string, entity_type: string>, group_membership_criteria: table<ip_address_membership_criteria: record, membership_type: string, search_membership_criteria: record>>
# operationId: getTier
export def "get-tier" [
  tier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-26 # Response content type
  --authorization: string # Authorization Header (required, format: NetworkInsight <token>)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/tiers/{tier-id}"
    path_params: [{name: tier-id, var: tier_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: [application, "application/json", entity_id, entity_type, group_membership_criteria, name]
    ok: [200]
    auth: bearer
  } {
    tier_id: $tier_id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show version info
#
# GET /info/version
# Returns: record<api_version: string>
# operationId: getVersion
export def "get-version" [
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
    path: "/info/version"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List nodes
#
# GET /infra/nodes
# Returns: record<results: table<entity_type: string, id: string>, total_count: int>
# operationId: listNodes
export def "list-nodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/infra/nodes"
    accept: ["application/json", results, total_count]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Show node details
#
# GET /infra/nodes/{id}
# Returns: record<entity_type: string, id: string, ip_address: string, name: string, node_id: string, node_type: string>
# operationId: getNode
export def "get-node" [
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
  --accept: string@accept-completer-27 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/infra/nodes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", entity_type, id, ip_address, node_id, node_type]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get logical recommended rules
#
# POST /micro-seg/recommended-rules
# Returns: record<results: table<action: string, destinations: list, port_ranges: list, protocols: list, sources: list>, time_range: record<end_time: int, start_time: int>>
# operationId: listRecommendedRules
export def "list-recommended-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-28 # Response content type
  --group-1: record # shape: {entity?: record}
  --group-2: record # shape: {entity?: record}
  --time-range: record # shape: {end_time?: int, start_time?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/micro-seg/recommended-rules"
    body: {content_type: "application/json", kind: json, fields: [{name: group_1, var: group_1}, {name: group_2, var: group_2}, {name: time_range, var: time_range}]}
    accept: ["application/json", results, time_range]
    ok: [200]
    auth: bearer
  } {
    group_1: $group_1, group_2: $group_2, time_range: $time_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Export recommended rules for NSX-V
#
# POST /micro-seg/recommended-rules/nsx
# Returns: binary
# operationId: exportNsxRecommendedRules
export def "export-nsx-recommended-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-1: record # shape: {entity?: record}
  --group-2: record # shape: {entity?: record}
  --time-range: record # shape: {end_time?: int, start_time?: int}
]: any -> any {
  $in | http-request {
    method: post
    path: "/micro-seg/recommended-rules/nsx"
    body: {content_type: "application/json", kind: json, fields: [{name: group_1, var: group_1}, {name: group_2, var: group_2}, {name: time_range, var: time_range}]}
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    group_1: $group_1, group_2: $group_2, time_range: $time_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search entities
#
# POST /search
# Returns: record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int>
# operationId: searchEntities
export def "search-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --entity-type: string@entity-type-completer-1
  --filter: string # query filter
  --size: int # format: int32
  --sort-by: record # shape: {field?: string, order?: "ASC"|"DESC"}
  --time-range: record # shape: {end_time?: int, start_time?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/search"
    body: {content_type: "application/json", kind: json, fields: [{name: cursor, var: cursor}, {name: entity_type, var: entity_type}, {name: filter, var: filter}, {name: size, var: size}, {name: sort_by, var: sort_by}, {name: time_range, var: time_range}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, entity_type: $entity_type, filter: $filter, size: $size, sort_by: $sort_by, time_range: $time_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
