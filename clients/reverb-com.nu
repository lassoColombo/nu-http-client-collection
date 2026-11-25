# Auto-generated client for reverb v3.0
# Source: https://api.apis.guru/v2/specs/reverb.com/3.0/openapi.json
# Auth: --token flag or $env.REVERB_TOKEN

const CLIENT = {
  base_url: "https://api.reverb.com/api"
  token_env_var: "REVERB_TOKEN"
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

def base-url-completer [] { ["https://api.reverb.com/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def exclusive-channel-completer [] { ["none" "reverb" "seller_site"] }
def conditions-completer [] { ["all" "all-but-new" "b-stock" "excellent" "fair" "good" "mint" "new" "non-functioning" "poor" "used" "very-good"] }
def currency-completer [] { ["ARS" "AUD" "BRL" "CAD" "CHF" "DKK" "EUR" "GBP" "HKD" "JPY" "MXN" "NOK" "NZD" "PHP" "PLN" "RUB" "SEK" "USD"] }
def listing-type-completer [] { ["auctions" "offers"] }
def reason-completer [] { ["not_sold" "reverb_sale"] }
def currency-completer-1 [] { ["AUD" "CAD" "EUR" "GBP" "JPY" "MXN" "NZD" "USD"] }
def legal-country-code-completer [] { ["AD" "AE" "AF" "AG" "AI" "AL" "AM" "AO" "AR" "AS" "AT" "AU" "AW" "AX" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BQ" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "SS" "ST" "SV" "SX" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "YE" "YT" "ZA" "ZM" "ZW"] }
def legal-country-code-confirmed-completer [] { ["true"] }
def shop-type-completer [] { ["business" "individual"] }
def topic-completer [] { ["app/uninstalled" "listings/bumps-ran-out" "listings/publish" "listings/update" "orders/create" "orders/update" "payments/create" "payments/update"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {}
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-articles" "get-articles-categories" "get-categories" "get-categories-flat" "get-categories-taxonomy" "get-categories-product-type-category" "get-categories-uuid" "get-comparison-shopping-pages" "get-comparison-shopping-pages-find" "get-comparison-shopping-pages-id" "get-comparison-shopping-pages-id-listings" "get-comparison-shopping-pages-id-reviews" "post-conversations-conversation-id-offer" "post-conversations-id-offer" "get-countries" "get-csps" "get-csps-categories" "get-csps-find" "get-csps-id" "get-curated-sets-slug" "get-currencies-display" "get-currencies-listing" "get-feedback-feedback-id" "get-handpicked-slug" "get-listing-conditions" "get-listings" "post-listings" "get-listings-all" "get-listings-facets-seller-location" "get-listings-id-negotiation" "post-listings-id-offer" "get-listings-listing-id-bump" "post-listings-listing-id-bump-budget-type" "post-listings-listing-id-conversations" "get-listings-listing-id-images" "delete-listings-listing-id-images-image-id" "get-listings-listing-id-sales" "delete-listings-slug" "get-listings-slug" "put-listings-slug" "get-listings-slug-edit" "post-listings-slug-flag" "get-listings-slug-reviews" "post-listings-slug-reviews" "get-listings-slug-similar-listings" "get-my-account" "put-my-account" "get-my-addresses" "post-my-addresses" "delete-my-addresses-address-id" "put-my-addresses-address-id" "get-my-conversations" "post-my-conversations" "post-my-conversations-conversation-id-messages" "get-my-conversations-id" "put-my-conversations-id" "get-my-counts" "delete-my-curated-set-product-product-id" "post-my-curated-set-product-product-id" "get-my-feed" "get-my-feed-customize" "get-my-feed-grid" "get-my-feedback-received" "get-my-feedback-sent" "get-my-follows" "get-my-follows-articles" "post-my-follows-articles" "delete-my-follows-brands-slug" "get-my-follows-brands-slug" "post-my-follows-brands-slug" "delete-my-follows-categories-category-subcategory" "get-my-follows-categories-category-subcategory" "post-my-follows-categories-category-subcategory" "delete-my-follows-categories-identifier" "get-my-follows-categories-identifier" "post-my-follows-categories-identifier" "post-my-follows-categories-uuid" "delete-my-follows-collections-slug" "get-my-follows-collections-slug" "post-my-follows-collections-slug" "delete-my-follows-handpicked-slug" "get-my-follows-handpicked-slug" "post-my-follows-handpicked-slug" "get-my-follows-search" "post-my-follows-search" "delete-my-follows-shops-slug" "get-my-follows-shops-slug" "post-my-follows-shops-slug" "delete-my-follows-follow-id" "delete-my-follows-follow-id-alert" "post-my-follows-follow-id-alert" "get-my-listings" "get-my-listings-drafts" "get-my-listings-negotiations" "put-my-listings-slug-state-end" "get-my-lists" "get-my-negotiations-buying" "get-my-negotiations-id" "post-my-negotiations-id-accept" "post-my-negotiations-id-counter" "post-my-negotiations-id-decline" "get-my-orders-awaiting-feedback" "get-my-orders-buying-all" "get-my-orders-buying-by-uuid-uuid" "get-my-orders-buying-unpaid" "get-my-orders-buying-id" "post-my-orders-buying-id-mark-received" "get-my-orders-selling-all" "get-my-orders-selling-awaiting-shipment" "get-my-orders-selling-buyer-history-buyer-id" "get-my-orders-selling-by-uuid-uuid" "get-my-orders-selling-unpaid" "get-my-orders-selling-id" "post-my-orders-selling-id-mark-picked-up" "post-my-orders-selling-id-ship" "post-my-orders-selling-order-id-refund-requests" "get-my-payments-selling" "get-my-payments-selling-id" "get-my-payouts" "get-my-payouts-id-line-items" "get-my-refund-requests-selling" "put-my-refund-requests-selling-id" "get-my-viewed-listings" "get-my-wishlist" "delete-my-wishlist-id" "put-my-wishlist-id" "get-orders-order-id-feedback-buyer" "post-orders-order-id-feedback-buyer" "get-orders-order-id-feedback-seller" "post-orders-order-id-feedback-seller" "get-payment-methods" "get-priceguide-id-transactions-summary" "get-products-reviews-id" "put-products-reviews-id" "get-products-slug-reviews" "post-products-slug-reviews" "get-sales-reverb" "get-sales-seller" "delete-sales-sale-id-listings" "post-sales-sale-id-listings" "get-sales-slug" "get-shipping-providers" "get-shipping-regions" "get-shop" "put-shop" "get-shop-listing-conditions" "get-shop-payment-methods" "delete-shop-vacation" "get-shop-vacation" "post-shop-vacation" "get-shops-id-storefronts" "get-shops-shop-id-shipping-profiles" "get-shops-slug" "get-shops-slug-feedback" "get-shops-slug-feedback-buyer" "get-shops-slug-feedback-seller" "get-wants" "delete-wants-id" "put-wants-id" "get-webhooks-registrations" "post-webhooks-registrations" "delete-webhooks-registrations-id" "get-webhooks-registrations-id" "commands"] | sort) } | get name | first)
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

# GET /articles
export def "get-articles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # default: 1
  --per-page: int # default: 24
  --offset: int
  --query: string # What's being searched for
  --exclude-featured: int # Number of featured articles to exclude
]: nothing -> any {
  http-request {
    method: get
    path: "/articles"
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: offset, var: offset}, {name: query, var: query}, {name: exclude_featured, var: exclude_featured}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    page: $page, per_page: $per_page, offset: $offset, query: $query, exclude_featured: $exclude_featured
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of all article categories
#
# GET /articles/categories
export def "get-articles-categories" [
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
    path: "/articles/categories"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of supported product categories
#
# GET /categories
export def "get-categories" [
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
    path: "/categories"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /categories/flat
export def "get-categories-flat" [
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
    path: "/categories/flat"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Full taxonomy tree of categories including middle categories
#
# GET /categories/taxonomy
export def "get-categories-taxonomy" [
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
    path: "/categories/taxonomy"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get subcategory details
#
# GET /categories/{product_type}/{category}
export def "get-categories-product-type-category" [
  product_type: string
  category: string
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
    path: "/categories/{product_type}/{category}"
    path_params: [{name: product_type, var: product_type}, {name: category, var: category}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    product_type: $product_type, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get category details
#
# GET /categories/{uuid}
export def "get-categories-uuid" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/categories/{uuid}"
    path_params: [{name: uuid, var: uuid}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a set of comparison shopping pages based on the current params
#
# GET /comparison_shopping_pages
export def "get-comparison-shopping-pages" [
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
    path: "/comparison_shopping_pages"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show comparison shopping page
#
# GET /comparison_shopping_pages/find
export def "get-comparison-shopping-pages-find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # ID of the comparison shopping page
  --slug: string # Slug of the comparison shopping page
]: nothing -> any {
  http-request {
    method: get
    path: "/comparison_shopping_pages/find"
    query: [{name: id, var: id}, {name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id, slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /comparison_shopping_pages/{id}
export def "get-comparison-shopping-pages-id" [
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
    path: "/comparison_shopping_pages/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return new or used listings for a comparison shopping page
#
# GET /comparison_shopping_pages/{id}/listings
export def "get-comparison-shopping-pages-id-listings" [
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
  --condition: string # Condition of the listing (required)
  --page: int # default: 1
  --per-page: int # default: 24
  --offset: int
]: nothing -> any {
  http-request {
    method: get
    path: "/comparison_shopping_pages/{id}/listings"
    path_params: [{name: id, var: id}]
    query: [{name: condition, var: condition, required: true}, {name: page, var: page}, {name: per_page, var: per_page}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id, condition: $condition, page: $page, per_page: $per_page, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View reviews of a comparison shopping page
#
# GET /comparison_shopping_pages/{id}/reviews
export def "get-comparison-shopping-pages-id-reviews" [
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
    path: "/comparison_shopping_pages/{id}/reviews"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Make an offer to the other participant in the conversation
#
# POST /conversations/{conversation_id}/offer
export def "post-conversations-conversation-id-offer" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-code: string
  --layaway-terms-slug: string
  --message: string # Message to include with counter offer
  --offer-items: list # item shape: {listing_id: string, price: string, shipping_price: string}
  --price: record # shape: {amount: string, currency: "USD"|"CAD"|"EUR"|"GBP"|"AUD"|"JPY"|"NZD"|"MXN"}
  --quantity: string
  --recipient-id: string # ID of the recipient of the offer. Required if you are the seller pushing an offer to a buyer.
  --region-code: string
  --shipping-price: record # Shipping price (sellers only) — shape: {amount: string, currency: "USD"|"CAD"|"EUR"|"GBP"|"AUD"|"JPY"|"NZD"|"MXN"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/conversations/{conversation_id}/offer"
    path_params: [{name: conversation_id, var: conversation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: country_code, var: country_code}, {name: layaway_terms_slug, var: layaway_terms_slug}, {name: message, var: message}, {name: offer_items, var: offer_items}, {name: price, var: price}, {name: quantity, var: quantity}, {name: recipient_id, var: recipient_id}, {name: region_code, var: region_code}, {name: shipping_price, var: shipping_price}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    conversation_id: $conversation_id, country_code: $country_code, layaway_terms_slug: $layaway_terms_slug, message: $message, offer_items: $offer_items, price: $price, quantity: $quantity, recipient_id: $recipient_id, region_code: $region_code, shipping_price: $shipping_price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Make an offer to the other participant in the conversation
#
# POST /conversations/{id}/offer
export def "post-conversations-id-offer" [
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
  --message: string # Message to include with counter offer
  price: string # Offer price
  --shipping-price: string # Shipping price (sellers only)
]: any -> any {
  $in | http-request {
    method: post
    path: "/conversations/{id}/offer"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: price, var: price}, {name: shipping_price, var: shipping_price}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id, message: $message, price: $price, shipping_price: $shipping_price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of country codes with corresponding subregions
#
# GET /countries
export def "get-countries" [
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
    path: "/countries"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a set of comparison shopping pages based on the current params
#
# GET /csps
export def "get-csps" [
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
    path: "/csps"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /csps/categories
export def "get-csps-categories" [
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
    path: "/csps/categories"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show comparison shopping page
#
# GET /csps/find
export def "get-csps-find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # ID of the comparison shopping page
  --slug: string # Slug of the comparison shopping page
]: nothing -> any {
  http-request {
    method: get
    path: "/csps/find"
    query: [{name: id, var: id}, {name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id, slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /csps/{id}
export def "get-csps-id" [
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
    path: "/csps/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /curated_sets/{slug}
export def "get-curated-sets-slug" [
  slug: string
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
    path: "/curated_sets/{slug}"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of supported display currencies for browsing listings
#
# GET /currencies/display
export def "get-currencies-display" [
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
    path: "/currencies/display"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of supported listing currencies for shops
#
# GET /currencies/listing
export def "get-currencies-listing" [
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
    path: "/currencies/listing"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Feedback details
#
# GET /feedback/{feedback_id}
export def "get-feedback-feedback-id" [
  feedback_id: string
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
    path: "/feedback/{feedback_id}"
    path_params: [{name: feedback_id, var: feedback_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    feedback_id: $feedback_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get results from a handpicked collection
#
# GET /handpicked/{slug}
export def "get-handpicked-slug" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Search query.
  --auction-price-max: float # Maximum current auction price (format: float)
  --category: string # Category slug from /api/categories
  --product-type: string # Product type slug from /api/categories
  --conditions: list<string> # Condition: all,new,b-stock,used,non-functioning,all-but-new,poor,fair,good,very-good,excellent,mint
  --decade: string # Decade: e.g. 1970s, early 70s
  --finish: string # Visual finish of the item, common for guitars
  --handmade: oneof<nothing, bool> # Handmade items only
  --item-city: string # City where item is located
  --item-country: string # DEPRECATED - Country code where item is located
  --item-region: string # Country code where item is located
  --item-state: string # State or region code where item is located
  --make: list<string> # Make(s)/brand of item (e.g. Fender). Can take a single value or an array.
  --model: string # Model of item (e.g. Stratocaster)
  --must-not: string # Search term negation. If you want to exclude a term, add it here
  --price-max: float # Maximum price of search results (USD) (format: float)
  --price-min: float # Minimum price of search results (USD) (format: float)
  --currency: string # The currency to be used for the price filters
  --year-max: int # Maximum year of manufacture
  --year-min: int # Minumum year of manufacture
  --accepts-gift-cards: oneof<nothing, bool> # If true, include only items that accept gift cards
  --preferred-seller: oneof<nothing, bool> # If true, include only items by Reverb Preferred Sellers
  --shop: string # Slug of shop to search
  --shop-id: string # ID of shop to search
  --listing-type: string # Type of listing: auctions,offers
  --ships-to: string # Limit search to items that ship to this country code
  --exclude-auctions: oneof<nothing, bool> # If true, exclude auctions
  --accepts-payment-plans: oneof<nothing, bool> # If true, only show items that can be purchased with a payment plan
  --watchers-count-min: int # Minimum number of watchers (used to find popular items)
  --not-ids: list<string> # Listing ID negation. If you want to exclude a listing, add it here.
  --local-pickup: oneof<nothing, bool> # Only items that offer local pickup
  --page: int # default: 1
  --per-page: int # default: 24
  --offset: int
]: nothing -> any {
  http-request {
    method: get
    path: "/handpicked/{slug}"
    path_params: [{name: slug, var: slug}]
    query: [{name: query, var: query}, {name: auction_price_max, var: auction_price_max}, {name: category, var: category}, {name: product_type, var: product_type}, {name: conditions, var: conditions, style: csv}, {name: decade, var: decade}, {name: finish, var: finish}, {name: handmade, var: handmade}, {name: item_city, var: item_city}, {name: item_country, var: item_country}, {name: item_region, var: item_region}, {name: item_state, var: item_state}, {name: make, var: make, style: csv}, {name: model, var: model}, {name: must_not, var: must_not}, {name: price_max, var: price_max}, {name: price_min, var: price_min}, {name: currency, var: currency}, {name: year_max, var: year_max}, {name: year_min, var: year_min}, {name: accepts_gift_cards, var: accepts_gift_cards}, {name: preferred_seller, var: preferred_seller}, {name: shop, var: shop}, {name: shop_id, var: shop_id}, {name: listing_type, var: listing_type}, {name: ships_to, var: ships_to}, {name: exclude_auctions, var: exclude_auctions}, {name: accepts_payment_plans, var: accepts_payment_plans}, {name: watchers_count_min, var: watchers_count_min}, {name: not_ids, var: not_ids, style: csv}, {name: local_pickup, var: local_pickup}, {name: page, var: page}, {name: per_page, var: per_page}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug, query: $query, auction_price_max: $auction_price_max, category: $category, product_type: $product_type, conditions: $conditions, decade: $decade, finish: $finish, handmade: $handmade, item_city: $item_city, item_country: $item_country, item_region: $item_region, item_state: $item_state, make: $make, model: $model, must_not: $must_not, price_max: $price_max, price_min: $price_min, currency: $currency, year_max: $year_max, year_min: $year_min, accepts_gift_cards: $accepts_gift_cards, preferred_seller: $preferred_seller, shop: $shop, shop_id: $shop_id, listing_type: $listing_type, ships_to: $ships_to, exclude_auctions: $exclude_auctions, accepts_payment_plans: $accepts_payment_plans, watchers_count_min: $watchers_count_min, not_ids: $not_ids, local_pickup: $local_pickup, page: $page, per_page: $per_page, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of supported product conditions
#
# GET /listing_conditions
export def "get-listing-conditions" [
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
    path: "/listing_conditions"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Default search of listings includes only used & handmade. Add a filter to view all listings or use the /listings/all endpoint.
#
# GET /listings
export def "get-listings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Search query.
  --auction-price-max: float # Maximum current auction price (format: float)
  --category: string # Category slug from /api/categories
  --product-type: string # Product type slug from /api/categories
  --conditions: list<string> # Condition: all,new,b-stock,used,non-functioning,all-but-new,poor,fair,good,very-good,excellent,mint
  --decade: string # Decade: e.g. 1970s, early 70s
  --finish: string # Visual finish of the item, common for guitars
  --handmade: oneof<nothing, bool> # Handmade items only
  --item-city: string # City where item is located
  --item-country: string # DEPRECATED - Country code where item is located
  --item-region: string # Country code where item is located
  --item-state: string # State or region code where item is located
  --make: list<string> # Make(s)/brand of item (e.g. Fender). Can take a single value or an array.
  --model: string # Model of item (e.g. Stratocaster)
  --must-not: string # Search term negation. If you want to exclude a term, add it here
  --price-max: float # Maximum price of search results (USD) (format: float)
  --price-min: float # Minimum price of search results (USD) (format: float)
  --currency: string # The currency to be used for the price filters
  --year-max: int # Maximum year of manufacture
  --year-min: int # Minumum year of manufacture
  --accepts-gift-cards: oneof<nothing, bool> # If true, include only items that accept gift cards
  --preferred-seller: oneof<nothing, bool> # If true, include only items by Reverb Preferred Sellers
  --shop: string # Slug of shop to search
  --shop-id: string # ID of shop to search
  --listing-type: string # Type of listing: auctions,offers
  --ships-to: string # Limit search to items that ship to this country code
  --exclude-auctions: oneof<nothing, bool> # If true, exclude auctions
  --accepts-payment-plans: oneof<nothing, bool> # If true, only show items that can be purchased with a payment plan
  --watchers-count-min: int # Minimum number of watchers (used to find popular items)
  --not-ids: list<string> # Listing ID negation. If you want to exclude a listing, add it here.
  --local-pickup: oneof<nothing, bool> # Only items that offer local pickup
  --page: int # default: 1
  --per-page: int # default: 24
  --offset: int
]: nothing -> any {
  http-request {
    method: get
    path: "/listings"
    query: [{name: query, var: query}, {name: auction_price_max, var: auction_price_max}, {name: category, var: category}, {name: product_type, var: product_type}, {name: conditions, var: conditions, style: csv}, {name: decade, var: decade}, {name: finish, var: finish}, {name: handmade, var: handmade}, {name: item_city, var: item_city}, {name: item_country, var: item_country}, {name: item_region, var: item_region}, {name: item_state, var: item_state}, {name: make, var: make, style: csv}, {name: model, var: model}, {name: must_not, var: must_not}, {name: price_max, var: price_max}, {name: price_min, var: price_min}, {name: currency, var: currency}, {name: year_max, var: year_max}, {name: year_min, var: year_min}, {name: accepts_gift_cards, var: accepts_gift_cards}, {name: preferred_seller, var: preferred_seller}, {name: shop, var: shop}, {name: shop_id, var: shop_id}, {name: listing_type, var: listing_type}, {name: ships_to, var: ships_to}, {name: exclude_auctions, var: exclude_auctions}, {name: accepts_payment_plans, var: accepts_payment_plans}, {name: watchers_count_min, var: watchers_count_min}, {name: not_ids, var: not_ids, style: csv}, {name: local_pickup, var: local_pickup}, {name: page, var: page}, {name: per_page, var: per_page}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    query: $query, auction_price_max: $auction_price_max, category: $category, product_type: $product_type, conditions: $conditions, decade: $decade, finish: $finish, handmade: $handmade, item_city: $item_city, item_country: $item_country, item_region: $item_region, item_state: $item_state, make: $make, model: $model, must_not: $must_not, price_max: $price_max, price_min: $price_min, currency: $currency, year_max: $year_max, year_min: $year_min, accepts_gift_cards: $accepts_gift_cards, preferred_seller: $preferred_seller, shop: $shop, shop_id: $shop_id, listing_type: $listing_type, ships_to: $ships_to, exclude_auctions: $exclude_auctions, accepts_payment_plans: $accepts_payment_plans, watchers_count_min: $watchers_count_min, not_ids: $not_ids, local_pickup: $local_pickup, page: $page, per_page: $per_page, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a listing
#
# POST /listings
export def "post-listings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list # item shape: {uuid?: string}
  --condition: record # Condition — shape: {uuid: "fbf35668-96a0-4baa-bcde-ab18d6b1b329"|"6a9dfcad-600b-46c8-9e08-ce6e5057921e"|"98777886-76d0-44c8-865e-bb40e669e934"|"f7a3f48c-972a-44c6-b01a-0cd27488d3f6"|"ae4d9114-1bd7-4ec5-a4ba-6653af5ac84d"|"df268ad1-c462-4ba6-b6db-e007e23922ea"|"ac5b9c1e-dc78-466d-b0b3-7cf712967a48"|"6db7df88-293b-4017-a1c1-cdb5e599fa1a"|"9225283f-60c2-4413-ad18-1f5eba7a856f"|"7c3f45de-2ae0-4c81-8400-fdb6b1d74890"}
  --description: string # Product description. Please keep formatting to a minimum.
  --exclusive-channel: string@exclusive-channel-completer # Currently for users of seller sites only, this allows you to have a listing available only to your seller site by setting this to 'seller_site'
  --finish: string # Finish, e.g. 'Sunburst'
  --has-inventory: oneof<nothing, bool> # Set true if selling more than one
  --inventory: int # Number of items available for sale. Reverb will increment and decrement automatically.
  --location: record # shape: {country_code?: string, locality?: string, region?: string}
  --make: string # ex: Fender, Gibson
  --model: string # ex: Stratocaster, SG
  --multi-item: oneof<nothing, bool> # Specifies if the listing is a bundle of multiple individual items
  --offers-enabled: oneof<nothing, bool> # Whether the listing accepts negotiated offers (default: true)
  --origin-country-code: string # Country of origin/manufacture, ISO code (e.g: US)
  --photos: list<string> # An array of image URLs. Ex: ['http://my.site.com/image.jpg']
  --preorder-info: record # Create or update a preorder listing. Requires opt-in. Please contact sales@reverb.com if you would like to activate this feature. — shape: {lead_time?: int, lead_time_unit: "days"|"weeks", ship_date?: string}
  --price: record # shape: {amount: string, currency: "USD"|"CAD"|"EUR"|"GBP"|"AUD"|"JPY"|"NZD"|"MXN"}
  --prop-65-warning: string # If your listing contains chemicals that are required to be reported under California Prop 65, please provide your warning statement. We will add the required 'Warning' label and link to California's information page, so you only need to provide the body of the warning. For more information, see https://www.p65warnings.ca.gov/new-proposition-65-warnings
  --publish: oneof<nothing, bool> # Publish your listing if draft
  --seller: record # shape: {paypal_email?: string}
  --seller-cost: string # Cost of goods in your currency as a POSIX-compliant decimal number (internal use only, not shown to buyers)
  --shipping: record # shape: {local?: bool, rates?: list}
  --shipping-profile-id: string # id of a shop's shipping profile
  --shipping-profile-name: string # DEPRECATED, please use shipping_profile_id. Name of a shipping profile
  --sku: string # Unique identifier for product
  --sold-as-is: oneof<nothing, bool> # This item is sold As-Is and cannot be returned
  --storage-location: string # Internal note used by sellers to back reference their catalog system when entering a listing
  --tax-exempt: oneof<nothing, bool> # Listing is exempt from taxes / VAT
  --title: string # Title of your listing
  --upc: string # Valid UPC code
  --upc-does-not-apply: oneof<nothing, bool> # True if a brand new product has no UPC code, ie for a handmade or custom item
  --videos: list # List of YouTube video urls. Note: ONLY ONE ALLOWED — item shape: {link: string}
  --year: string # Supports many formats. Ex: 1979, mid-70s, late 90s
]: any -> any {
  $in | http-request {
    method: post
    path: "/listings"
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}, {name: condition, var: condition}, {name: description, var: description}, {name: exclusive_channel, var: exclusive_channel}, {name: finish, var: finish}, {name: has_inventory, var: has_inventory}, {name: inventory, var: inventory}, {name: location, var: location}, {name: make, var: make}, {name: model, var: model}, {name: multi_item, var: multi_item}, {name: offers_enabled, var: offers_enabled}, {name: origin_country_code, var: origin_country_code}, {name: photos, var: photos}, {name: preorder_info, var: preorder_info}, {name: price, var: price}, {name: prop_65_warning, var: prop_65_warning}, {name: publish, var: publish}, {name: seller, var: seller}, {name: seller_cost, var: seller_cost}, {name: shipping, var: shipping}, {name: shipping_profile_id, var: shipping_profile_id}, {name: shipping_profile_name, var: shipping_profile_name}, {name: sku, var: sku}, {name: sold_as_is, var: sold_as_is}, {name: storage_location, var: storage_location}, {name: tax_exempt, var: tax_exempt}, {name: title, var: title}, {name: upc, var: upc}, {name: upc_does_not_apply, var: upc_does_not_apply}, {name: videos, var: videos}, {name: year, var: year}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    categories: $categories, condition: $condition, description: $description, exclusive_channel: $exclusive_channel, finish: $finish, has_inventory: $has_inventory, inventory: $inventory, location: $location, make: $make, model: $model, multi_item: $multi_item, offers_enabled: $offers_enabled, origin_country_code: $origin_country_code, photos: $photos, preorder_info: $preorder_info, price: $price, prop_65_warning: $prop_65_warning, publish: $publish, seller: $seller, seller_cost: $seller_cost, shipping: $shipping, shipping_profile_id: $shipping_profile_id, shipping_profile_name: $shipping_profile_name, sku: $sku, sold_as_is: $sold_as_is, storage_location: $storage_location, tax_exempt: $tax_exempt, title: $title, upc: $upc, upc_does_not_apply: $upc_does_not_apply, videos: $videos, year: $year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All listings including used, handmade, and brand new
#
# GET /listings/all
export def "get-listings-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Search query.
  --auction-price-max: float # Maximum current auction price (format: float)
  --category: string # Category slug from /api/categories
  --product-type: string # Product type slug from /api/categories
  --conditions: list<string> # Condition: all,new,b-stock,used,non-functioning,all-but-new,poor,fair,good,very-good,excellent,mint
  --decade: string # Decade: e.g. 1970s, early 70s
  --finish: string # Visual finish of the item, common for guitars
  --handmade: oneof<nothing, bool> # Handmade items only
  --item-city: string # City where item is located
  --item-country: string # DEPRECATED - Country code where item is located
  --item-region: string # Country code where item is located
  --item-state: string # State or region code where item is located
  --make: list<string> # Make(s)/brand of item (e.g. Fender). Can take a single value or an array.
  --model: string # Model of item (e.g. Stratocaster)
  --must-not: string # Search term negation. If you want to exclude a term, add it here
  --price-max: float # Maximum price of search results (USD) (format: float)
  --price-min: float # Minimum price of search results (USD) (format: float)
  --currency: string # The currency to be used for the price filters
  --year-max: int # Maximum year of manufacture
  --year-min: int # Minumum year of manufacture
  --accepts-gift-cards: oneof<nothing, bool> # If true, include only items that accept gift cards
  --preferred-seller: oneof<nothing, bool> # If true, include only items by Reverb Preferred Sellers
  --shop: string # Slug of shop to search
  --shop-id: string # ID of shop to search
  --listing-type: string # Type of listing: auctions,offers
  --ships-to: string # Limit search to items that ship to this country code
  --exclude-auctions: oneof<nothing, bool> # If true, exclude auctions
  --accepts-payment-plans: oneof<nothing, bool> # If true, only show items that can be purchased with a payment plan
  --watchers-count-min: int # Minimum number of watchers (used to find popular items)
  --not-ids: list<string> # Listing ID negation. If you want to exclude a listing, add it here.
  --local-pickup: oneof<nothing, bool> # Only items that offer local pickup
  --page: int # default: 1
  --per-page: int # default: 24
  --offset: int
]: nothing -> any {
  http-request {
    method: get
    path: "/listings/all"
    query: [{name: query, var: query}, {name: auction_price_max, var: auction_price_max}, {name: category, var: category}, {name: product_type, var: product_type}, {name: conditions, var: conditions, style: csv}, {name: decade, var: decade}, {name: finish, var: finish}, {name: handmade, var: handmade}, {name: item_city, var: item_city}, {name: item_country, var: item_country}, {name: item_region, var: item_region}, {name: item_state, var: item_state}, {name: make, var: make, style: csv}, {name: model, var: model}, {name: must_not, var: must_not}, {name: price_max, var: price_max}, {name: price_min, var: price_min}, {name: currency, var: currency}, {name: year_max, var: year_max}, {name: year_min, var: year_min}, {name: accepts_gift_cards, var: accepts_gift_cards}, {name: preferred_seller, var: preferred_seller}, {name: shop, var: shop}, {name: shop_id, var: shop_id}, {name: listing_type, var: listing_type}, {name: ships_to, var: ships_to}, {name: exclude_auctions, var: exclude_auctions}, {name: accepts_payment_plans, var: accepts_payment_plans}, {name: watchers_count_min, var: watchers_count_min}, {name: not_ids, var: not_ids, style: csv}, {name: local_pickup, var: local_pickup}, {name: page, var: page}, {name: per_page, var: per_page}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    query: $query, auction_price_max: $auction_price_max, category: $category, product_type: $product_type, conditions: $conditions, decade: $decade, finish: $finish, handmade: $handmade, item_city: $item_city, item_country: $item_country, item_region: $item_region, item_state: $item_state, make: $make, model: $model, must_not: $must_not, price_max: $price_max, price_min: $price_min, currency: $currency, year_max: $year_max, year_min: $year_min, accepts_gift_cards: $accepts_gift_cards, preferred_seller: $preferred_seller, shop: $shop, shop_id: $shop_id, listing_type: $listing_type, ships_to: $ships_to, exclude_auctions: $exclude_auctions, accepts_payment_plans: $accepts_payment_plans, watchers_count_min: $watchers_count_min, not_ids: $not_ids, local_pickup: $local_pickup, page: $page, per_page: $per_page, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Individual facets
#
# GET /listings/facets/seller_location
export def "get-listings-facets-seller-location" [
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
    path: "/listings/facets/seller_location"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the latest negotiation for the requesting user given a listing id
#
# GET /listings/{id}/negotiation
export def "get-listings-id-negotiation" [
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
    path: "/listings/{id}/negotiation"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Make an offer to the seller of a listing
#
# POST /listings/{id}/offer
export def "post-listings-id-offer" [
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
  --message: string # Message to include with counter offer
  price: string # Offer price
  --shipping-price: string # Shipping price (sellers only)
]: any -> any {
  $in | http-request {
    method: post
    path: "/listings/{id}/offer"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: price, var: price}, {name: shipping_price, var: shipping_price}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id, message: $message, price: $price, shipping_price: $shipping_price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View available bump tiers and stats for a listing
#
# GET /listings/{listing_id}/bump
export def "get-listings-listing-id-bump" [
  listing_id: string
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
    path: "/listings/{listing_id}/bump"
    path_params: [{name: listing_id, var: listing_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    listing_id: $listing_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bump a listing
#
# POST /listings/{listing_id}/bump/{budget_type}
export def "post-listings-listing-id-bump-budget-type" [
  listing_id: string
  budget_type: string
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
    path: "/listings/{listing_id}/bump/{budget_type}"
    path_params: [{name: listing_id, var: listing_id}, {name: budget_type, var: budget_type}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    listing_id: $listing_id, budget_type: $budget_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start a conversation with a seller
#
# POST /listings/{listing_id}/conversations
export def "post-listings-listing-id-conversations" [
  listing_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/listings/{listing_id}/conversations"
    path_params: [{name: listing_id, var: listing_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    listing_id: $listing_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View the images associated with a particular listing
#
# GET /listings/{listing_id}/images
export def "get-listings-listing-id-images" [
  listing_id: string
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
    path: "/listings/{listing_id}/images"
    path_params: [{name: listing_id, var: listing_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    listing_id: $listing_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an image from a listing
#
# DELETE /listings/{listing_id}/images/{image_id}
export def "delete-listings-listing-id-images-image-id" [
  listing_id: string
  image_id: string
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
    path: "/listings/{listing_id}/images/{image_id}"
    path_params: [{name: listing_id, var: listing_id}, {name: image_id, var: image_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    listing_id: $listing_id, image_id: $image_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# See all sales that include a listing.
#
# GET /listings/{listing_id}/sales
export def "get-listings-listing-id-sales" [
  listing_id: string
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
    path: "/listings/{listing_id}/sales"
    path_params: [{name: listing_id, var: listing_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    listing_id: $listing_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a draft listing. Cannot be used on non-drafts.
#
# DELETE /listings/{slug}
export def "delete-listings-slug" [
  slug: string
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
    path: "/listings/{slug}"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Listing details
#
# GET /listings/{slug}
export def "get-listings-slug" [
  slug: string
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
    path: "/listings/{slug}"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a listing
#
# PUT /listings/{slug}
export def "put-listings-slug" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list # item shape: {uuid?: string}
  --condition: record # Condition — shape: {uuid: "fbf35668-96a0-4baa-bcde-ab18d6b1b329"|"6a9dfcad-600b-46c8-9e08-ce6e5057921e"|"98777886-76d0-44c8-865e-bb40e669e934"|"f7a3f48c-972a-44c6-b01a-0cd27488d3f6"|"ae4d9114-1bd7-4ec5-a4ba-6653af5ac84d"|"df268ad1-c462-4ba6-b6db-e007e23922ea"|"ac5b9c1e-dc78-466d-b0b3-7cf712967a48"|"6db7df88-293b-4017-a1c1-cdb5e599fa1a"|"9225283f-60c2-4413-ad18-1f5eba7a856f"|"7c3f45de-2ae0-4c81-8400-fdb6b1d74890"}
  --description: string # Product description. Please keep formatting to a minimum.
  --exclusive-channel: string@exclusive-channel-completer # Currently for users of seller sites only, this allows you to have a listing available only to your seller site by setting this to 'seller_site'
  --finish: string # Finish, e.g. 'Sunburst'
  --has-inventory: oneof<nothing, bool> # Set true if selling more than one
  --inventory: int # Number of items available for sale. Reverb will increment and decrement automatically.
  --location: record # shape: {country_code?: string, locality?: string, region?: string}
  --make: string # ex: Fender, Gibson
  --model: string # ex: Stratocaster, SG
  --multi-item: oneof<nothing, bool> # Specifies if the listing is a bundle of multiple individual items
  --offers-enabled: oneof<nothing, bool> # Whether the listing accepts negotiated offers (default: true)
  --origin-country-code: string # Country of origin/manufacture, ISO code (e.g: US)
  --photos: list<string> # An array of image URLs. Ex: ['http://my.site.com/image.jpg']
  --preorder-info: record # Create or update a preorder listing. Requires opt-in. Please contact sales@reverb.com if you would like to activate this feature. — shape: {lead_time?: int, lead_time_unit: "days"|"weeks", ship_date?: string}
  --price: record # shape: {amount: string, currency: "USD"|"CAD"|"EUR"|"GBP"|"AUD"|"JPY"|"NZD"|"MXN"}
  --prop-65-warning: string # If your listing contains chemicals that are required to be reported under California Prop 65, please provide your warning statement. We will add the required 'Warning' label and link to California's information page, so you only need to provide the body of the warning. For more information, see https://www.p65warnings.ca.gov/new-proposition-65-warnings
  --publish: oneof<nothing, bool> # Publish your listing if draft
  --seller: record # shape: {paypal_email?: string}
  --seller-cost: string # Cost of goods in your currency as a POSIX-compliant decimal number (internal use only, not shown to buyers)
  --shipping: record # shape: {local?: bool, rates?: list}
  --shipping-profile-id: string # id of a shop's shipping profile
  --shipping-profile-name: string # DEPRECATED, please use shipping_profile_id. Name of a shipping profile
  --sku: string # Unique identifier for product
  --sold-as-is: oneof<nothing, bool> # This item is sold As-Is and cannot be returned
  --storage-location: string # Internal note used by sellers to back reference their catalog system when entering a listing
  --tax-exempt: oneof<nothing, bool> # Listing is exempt from taxes / VAT
  --title: string # Title of your listing
  --upc: string # Valid UPC code
  --upc-does-not-apply: oneof<nothing, bool> # True if a brand new product has no UPC code, ie for a handmade or custom item
  --videos: list # List of YouTube video urls. Note: ONLY ONE ALLOWED — item shape: {link: string}
  --year: string # Supports many formats. Ex: 1979, mid-70s, late 90s
]: any -> any {
  $in | http-request {
    method: put
    path: "/listings/{slug}"
    path_params: [{name: slug, var: slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}, {name: condition, var: condition}, {name: description, var: description}, {name: exclusive_channel, var: exclusive_channel}, {name: finish, var: finish}, {name: has_inventory, var: has_inventory}, {name: inventory, var: inventory}, {name: location, var: location}, {name: make, var: make}, {name: model, var: model}, {name: multi_item, var: multi_item}, {name: offers_enabled, var: offers_enabled}, {name: origin_country_code, var: origin_country_code}, {name: photos, var: photos}, {name: preorder_info, var: preorder_info}, {name: price, var: price}, {name: prop_65_warning, var: prop_65_warning}, {name: publish, var: publish}, {name: seller, var: seller}, {name: seller_cost, var: seller_cost}, {name: shipping, var: shipping}, {name: shipping_profile_id, var: shipping_profile_id}, {name: shipping_profile_name, var: shipping_profile_name}, {name: sku, var: sku}, {name: sold_as_is, var: sold_as_is}, {name: storage_location, var: storage_location}, {name: tax_exempt, var: tax_exempt}, {name: title, var: title}, {name: upc, var: upc}, {name: upc_does_not_apply, var: upc_does_not_apply}, {name: videos, var: videos}, {name: year, var: year}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug, categories: $categories, condition: $condition, description: $description, exclusive_channel: $exclusive_channel, finish: $finish, has_inventory: $has_inventory, inventory: $inventory, location: $location, make: $make, model: $model, multi_item: $multi_item, offers_enabled: $offers_enabled, origin_country_code: $origin_country_code, photos: $photos, preorder_info: $preorder_info, price: $price, prop_65_warning: $prop_65_warning, publish: $publish, seller: $seller, seller_cost: $seller_cost, shipping: $shipping, shipping_profile_id: $shipping_profile_id, shipping_profile_name: $shipping_profile_name, sku: $sku, sold_as_is: $sold_as_is, storage_location: $storage_location, tax_exempt: $tax_exempt, title: $title, upc: $upc, upc_does_not_apply: $upc_does_not_apply, videos: $videos, year: $year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit listing.
#
# GET /listings/{slug}/edit
export def "get-listings-slug-edit" [
  slug: string
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
    path: "/listings/{slug}/edit"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Flag a listing for inappropriate content or fraud
#
# POST /listings/{slug}/flag
export def "post-listings-slug-flag" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # User input description specifying what is flag-worthy about this listing
  reason: string # Valid reasons: 'Sexuality/nudity', 'Hateful or inappropriate speech', 'Item not as described or potential fraud', 'Trademark infringement', 'Other'
]: any -> any {
  $in | http-request {
    method: post
    path: "/listings/{slug}/flag"
    path_params: [{name: slug, var: slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: reason, var: reason}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug, description: $description, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View reviews of a listing
#
# GET /listings/{slug}/reviews
export def "get-listings-slug-reviews" [
  slug: string
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
    path: "/listings/{slug}/reviews"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a review for a listing
#
# POST /listings/{slug}/reviews
export def "post-listings-slug-reviews" [
  slug: string
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
    path: "/listings/{slug}/reviews"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Listing details
#
# GET /listings/{slug}/similar_listings
export def "get-listings-slug-similar-listings" [
  slug: string
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
    path: "/listings/{slug}/similar_listings"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get account details
#
# GET /my/account
export def "get-my-account" [
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
    path: "/my/account"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update account details
#
# PUT /my/account
export def "put-my-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency: string # The currency preference for the account
  --first-name: string # The first name of the account holder
  --last-name: string # The last name of the account holder
  --locale-code: string # The locale code for the account
  --shipping-region-code: string # The shipping region preference for the account
  --third-party-ad-data-consent: oneof<nothing, bool> # The privacy setting preference for the account
]: any -> any {
  $in | http-request {
    method: put
    path: "/my/account"
    body: {content_type: "application/json", kind: json, fields: [{name: currency, var: currency}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: locale_code, var: locale_code}, {name: shipping_region_code, var: shipping_region_code}, {name: third_party_ad_data_consent, var: third_party_ad_data_consent}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    currency: $currency, first_name: $first_name, last_name: $last_name, locale_code: $locale_code, shipping_region_code: $shipping_region_code, third_party_ad_data_consent: $third_party_ad_data_consent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# See all addresses in your address book
#
# GET /my/addresses
export def "get-my-addresses" [
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
    path: "/my/addresses"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new address in your address book
#
# POST /my/addresses
export def "post-my-addresses" [
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
    path: "/my/addresses"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing address in your address book
#
# DELETE /my/addresses/{address_id}
export def "delete-my-addresses-address-id" [
  address_id: string
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
    path: "/my/addresses/{address_id}"
    path_params: [{name: address_id, var: address_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    address_id: $address_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing address in your address book
#
# PUT /my/addresses/{address_id}
export def "put-my-addresses-address-id" [
  address_id: string
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
    method: put
    path: "/my/addresses/{address_id}"
    path_params: [{name: address_id, var: address_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    address_id: $address_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of your conversations
#
# GET /my/conversations
export def "get-my-conversations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Query string to search conversations by
  --unread-only: oneof<nothing, bool> # Show unread conversations only
  --page: int # default: 1
  --per-page: int # default: 24
  --offset: int
]: nothing -> any {
  http-request {
    method: get
    path: "/my/conversations"
    query: [{name: search, var: search}, {name: unread_only, var: unread_only}, {name: page, var: page}, {name: per_page, var: per_page}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    search: $search, unread_only: $unread_only, page: $page, per_page: $per_page, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start a conversation
#
# POST /my/conversations
export def "post-my-conversations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # The body of the message
  --cloudinary-photos: list<string> # An array of cloudinary data hashes (Reverb internal use only).
  --listing-id: int # The id of the listing being discussed
  --recipient-id: int # The id of the user you are trying to contact
  --recipient-uuid: string # The uuid of the user you are trying to contact
  --shop-id: string # The id of the shop you are trying to contact
]: any -> any {
  $in | http-request {
    method: post
    path: "/my/conversations"
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: cloudinary_photos, var: cloudinary_photos}, {name: listing_id, var: listing_id}, {name: recipient_id, var: recipient_id}, {name: recipient_uuid, var: recipient_uuid}, {name: shop_id, var: shop_id}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    body: $body, cloudinary_photos: $cloudinary_photos, listing_id: $listing_id, recipient_id: $recipient_id, recipient_uuid: $recipient_uuid, shop_id: $shop_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a message
#
# POST /my/conversations/{conversation_id}/messages
export def "post-my-conversations-conversation-id-messages" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/my/conversations/{conversation_id}/messages"
    path_params: [{name: conversation_id, var: conversation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    conversation_id: $conversation_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Display conversation details with messages in natural time order (oldest to newest)
#
# GET /my/conversations/{id}
export def "get-my-conversations-id" [
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
    path: "/my/conversations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark a conversation read/unread
#
# PUT /my/conversations/{id}
export def "put-my-conversations-id" [
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
  --read: oneof<nothing, bool> # Should the conversation be marked as read
]: any -> any {
  $in | http-request {
    method: put
    path: "/my/conversations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: read, var: read}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id, read: $read
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get your actionable status counts
#
# GET /my/counts
export def "get-my-counts" [
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
    path: "/my/counts"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /my/curated_set/product/{product_id}
export def "delete-my-curated-set-product-product-id" [
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
    method: delete
    path: "/my/curated_set/product/{product_id}"
    path_params: [{name: product_id, var: product_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /my/curated_set/product/{product_id}
export def "post-my-curated-set-product-product-id" [
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
    path: "/my/curated_set/product/{product_id}"
    path_params: [{name: product_id, var: product_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get listings from your feed
#
# GET /my/feed
export def "get-my-feed" [
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
    path: "/my/feed"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get your feed customization options
#
# GET /my/feed/customize
export def "get-my-feed-customize" [
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
    path: "/my/feed/customize"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get your feed
#
# GET /my/feed/grid
export def "get-my-feed-grid" [
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
    path: "/my/feed/grid"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of received feedback
#
# GET /my/feedback/received
export def "get-my-feedback-received" [
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
    path: "/my/feedback/received"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of sent feedback
#
# GET /my/feedback/sent
export def "get-my-feedback-sent" [
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
    path: "/my/feedback/sent"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# See what the user is following
#
# GET /my/follows
export def "get-my-follows" [
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
    path: "/my/follows"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a user's ArticleCategoryFollows
#
# GET /my/follows/articles
export def "get-my-follows-articles" [
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
    path: "/my/follows/articles"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set a user's ArticleCategoryFollows
#
# POST /my/follows/articles
export def "post-my-follows-articles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  category_uuids: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/my/follows/articles"
    body: {content_type: "application/json", kind: json, fields: [{name: category_uuids, var: category_uuids}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    category_uuids: $category_uuids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfollow a brand
#
# DELETE /my/follows/brands/{slug}
export def "delete-my-follows-brands-slug" [
  slug: string
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
    path: "/my/follows/brands/{slug}"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow status for a brand
#
# GET /my/follows/brands/{slug}
export def "get-my-follows-brands-slug" [
  slug: string
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
    path: "/my/follows/brands/{slug}"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow a brand
#
# POST /my/follows/brands/{slug}
export def "post-my-follows-brands-slug" [
  slug: string
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
    path: "/my/follows/brands/{slug}"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfollow a subcategory
#
# DELETE /my/follows/categories/{category}/{subcategory}
export def "delete-my-follows-categories-category-subcategory" [
  category: string
  subcategory: string
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
    path: "/my/follows/categories/{category}/{subcategory}"
    path_params: [{name: category, var: category}, {name: subcategory, var: subcategory}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    category: $category, subcategory: $subcategory
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow status for a subcategory
#
# GET /my/follows/categories/{category}/{subcategory}
export def "get-my-follows-categories-category-subcategory" [
  category: string
  subcategory: string
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
    path: "/my/follows/categories/{category}/{subcategory}"
    path_params: [{name: category, var: category}, {name: subcategory, var: subcategory}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    category: $category, subcategory: $subcategory
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow a subcategory
#
# POST /my/follows/categories/{category}/{subcategory}
export def "post-my-follows-categories-category-subcategory" [
  category: string
  subcategory: string
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
    path: "/my/follows/categories/{category}/{subcategory}"
    path_params: [{name: category, var: category}, {name: subcategory, var: subcategory}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    category: $category, subcategory: $subcategory
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfollow a category
#
# DELETE /my/follows/categories/{identifier}
export def "delete-my-follows-categories-identifier" [
  identifier: string
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
    path: "/my/follows/categories/{identifier}"
    path_params: [{name: identifier, var: identifier}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    identifier: $identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow status for a category
#
# GET /my/follows/categories/{identifier}
export def "get-my-follows-categories-identifier" [
  identifier: string
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
    path: "/my/follows/categories/{identifier}"
    path_params: [{name: identifier, var: identifier}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    identifier: $identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow a category
#
# POST /my/follows/categories/{identifier}
export def "post-my-follows-categories-identifier" [
  identifier: string
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
    path: "/my/follows/categories/{identifier}"
    path_params: [{name: identifier, var: identifier}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    identifier: $identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow a category
#
# POST /my/follows/categories/{uuid}
export def "post-my-follows-categories-uuid" [
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
]: nothing -> any {
  http-request {
    method: post
    path: "/my/follows/categories/{uuid}"
    path_params: [{name: uuid, var: uuid}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfollow a collection
#
# DELETE /my/follows/collections/{slug}
export def "delete-my-follows-collections-slug" [
  slug: string
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
    path: "/my/follows/collections/{slug}"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow status for a collection
#
# GET /my/follows/collections/{slug}
export def "get-my-follows-collections-slug" [
  slug: string
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
    path: "/my/follows/collections/{slug}"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow a collection
#
# POST /my/follows/collections/{slug}
export def "post-my-follows-collections-slug" [
  slug: string
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
    path: "/my/follows/collections/{slug}"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfollow a handpicked collection
#
# DELETE /my/follows/handpicked/{slug}
export def "delete-my-follows-handpicked-slug" [
  slug: string
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
    path: "/my/follows/handpicked/{slug}"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow status for a handpicked collection
#
# GET /my/follows/handpicked/{slug}
export def "get-my-follows-handpicked-slug" [
  slug: string
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
    path: "/my/follows/handpicked/{slug}"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow a handpicked collection
#
# POST /my/follows/handpicked/{slug}
export def "post-my-follows-handpicked-slug" [
  slug: string
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
    path: "/my/follows/handpicked/{slug}"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow status for a search
#
# GET /my/follows/search
export def "get-my-follows-search" [
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
    path: "/my/follows/search"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow a search
#
# POST /my/follows/search
export def "post-my-follows-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accepts-gift-cards: oneof<nothing, bool> # If true, include only items that accept gift cards
  --accepts-payment-plans: oneof<nothing, bool> # If true, only show items that can be purchased with a payment plan
  --auction-price-max: float # Maximum current auction price (format: float)
  --category: string # Category slug from /api/categories
  --conditions: list<string>@conditions-completer # Condition: all,new,b-stock,used,non-functioning,all-but-new,poor,fair,good,very-good,excellent,mint
  --currency: string@currency-completer # The currency to be used for the price filters
  --decade: string # Decade: e.g. 1970s, early 70s
  --exclude-auctions: oneof<nothing, bool> # If true, exclude auctions
  --finish: string # Visual finish of the item, common for guitars
  --handmade: oneof<nothing, bool> # Handmade items only
  --item-city: string # City where item is located
  --item-country: string # DEPRECATED - Country code where item is located
  --item-region: string # Country code where item is located
  --item-state: string # State or region code where item is located
  --listing-type: string@listing-type-completer # Type of listing: auctions,offers
  --local-pickup: oneof<nothing, bool> # Only items that offer local pickup
  --make: list<string> # Make(s)/brand of item (e.g. Fender). Can take a single value or an array.
  --model: string # Model of item (e.g. Stratocaster)
  --must-not: string # Search term negation. If you want to exclude a term, add it here
  --not-ids: list<int> # Listing ID negation. If you want to exclude a listing, add it here.
  --preferred-seller: oneof<nothing, bool> # If true, include only items by Reverb Preferred Sellers
  --price-max: float # Maximum price of search results (USD) (format: float)
  --price-min: float # Minimum price of search results (USD) (format: float)
  --product-type: string # Product type slug from /api/categories
  --query: string # Search query.
  --ships-to: string # Limit search to items that ship to this country code
  --shop: string # Slug of shop to search
  --shop-id: string # ID of shop to search
  --watchers-count-min: int # Minimum number of watchers (used to find popular items)
  --year-max: int # Maximum year of manufacture
  --year-min: int # Minumum year of manufacture
]: any -> any {
  $in | http-request {
    method: post
    path: "/my/follows/search"
    body: {content_type: "application/json", kind: json, fields: [{name: accepts_gift_cards, var: accepts_gift_cards}, {name: accepts_payment_plans, var: accepts_payment_plans}, {name: auction_price_max, var: auction_price_max}, {name: category, var: category}, {name: conditions, var: conditions}, {name: currency, var: currency}, {name: decade, var: decade}, {name: exclude_auctions, var: exclude_auctions}, {name: finish, var: finish}, {name: handmade, var: handmade}, {name: item_city, var: item_city}, {name: item_country, var: item_country}, {name: item_region, var: item_region}, {name: item_state, var: item_state}, {name: listing_type, var: listing_type}, {name: local_pickup, var: local_pickup}, {name: make, var: make}, {name: model, var: model}, {name: must_not, var: must_not}, {name: not_ids, var: not_ids}, {name: preferred_seller, var: preferred_seller}, {name: price_max, var: price_max}, {name: price_min, var: price_min}, {name: product_type, var: product_type}, {name: query, var: query}, {name: ships_to, var: ships_to}, {name: shop, var: shop}, {name: shop_id, var: shop_id}, {name: watchers_count_min, var: watchers_count_min}, {name: year_max, var: year_max}, {name: year_min, var: year_min}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    accepts_gift_cards: $accepts_gift_cards, accepts_payment_plans: $accepts_payment_plans, auction_price_max: $auction_price_max, category: $category, conditions: $conditions, currency: $currency, decade: $decade, exclude_auctions: $exclude_auctions, finish: $finish, handmade: $handmade, item_city: $item_city, item_country: $item_country, item_region: $item_region, item_state: $item_state, listing_type: $listing_type, local_pickup: $local_pickup, make: $make, model: $model, must_not: $must_not, not_ids: $not_ids, preferred_seller: $preferred_seller, price_max: $price_max, price_min: $price_min, product_type: $product_type, query: $query, ships_to: $ships_to, shop: $shop, shop_id: $shop_id, watchers_count_min: $watchers_count_min, year_max: $year_max, year_min: $year_min
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfollow a shop
#
# DELETE /my/follows/shops/{slug}
export def "delete-my-follows-shops-slug" [
  slug: string
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
    path: "/my/follows/shops/{slug}"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow status for a shop
#
# GET /my/follows/shops/{slug}
export def "get-my-follows-shops-slug" [
  slug: string
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
    path: "/my/follows/shops/{slug}"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow a shop
#
# POST /my/follows/shops/{slug}
export def "post-my-follows-shops-slug" [
  slug: string
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
    path: "/my/follows/shops/{slug}"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a follow
#
# DELETE /my/follows/{follow_id}
export def "delete-my-follows-follow-id" [
  follow_id: string
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
    path: "/my/follows/{follow_id}"
    path_params: [{name: follow_id, var: follow_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    follow_id: $follow_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /my/follows/{follow_id}/alert
export def "delete-my-follows-follow-id-alert" [
  follow_id: string
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
    path: "/my/follows/{follow_id}/alert"
    path_params: [{name: follow_id, var: follow_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    follow_id: $follow_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /my/follows/{follow_id}/alert
export def "post-my-follows-follow-id-alert" [
  follow_id: string
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
    path: "/my/follows/{follow_id}/alert"
    path_params: [{name: follow_id, var: follow_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    follow_id: $follow_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of live listings for the seller. To search all listings specify state=all
#
# GET /my/listings
export def "get-my-listings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Search query.
  --auction-price-max: float # Maximum current auction price (format: float)
  --category: string # Category slug from /api/categories
  --product-type: string # Product type slug from /api/categories
  --conditions: list<string> # Condition: all,new,b-stock,used,non-functioning,all-but-new,poor,fair,good,very-good,excellent,mint
  --decade: string # Decade: e.g. 1970s, early 70s
  --finish: string # Visual finish of the item, common for guitars
  --handmade: oneof<nothing, bool> # Handmade items only
  --item-city: string # City where item is located
  --item-country: string # DEPRECATED - Country code where item is located
  --item-region: string # Country code where item is located
  --item-state: string # State or region code where item is located
  --make: list<string> # Make(s)/brand of item (e.g. Fender). Can take a single value or an array.
  --model: string # Model of item (e.g. Stratocaster)
  --must-not: string # Search term negation. If you want to exclude a term, add it here
  --price-max: float # Maximum price of search results (USD) (format: float)
  --price-min: float # Minimum price of search results (USD) (format: float)
  --currency: string # The currency to be used for the price filters
  --year-max: int # Maximum year of manufacture
  --year-min: int # Minumum year of manufacture
  --accepts-gift-cards: oneof<nothing, bool> # If true, include only items that accept gift cards
  --preferred-seller: oneof<nothing, bool> # If true, include only items by Reverb Preferred Sellers
  --shop: string # Slug of shop to search
  --shop-id: string # ID of shop to search
  --listing-type: string # Type of listing: auctions,offers
  --ships-to: string # Limit search to items that ship to this country code
  --exclude-auctions: oneof<nothing, bool> # If true, exclude auctions
  --accepts-payment-plans: oneof<nothing, bool> # If true, only show items that can be purchased with a payment plan
  --watchers-count-min: int # Minimum number of watchers (used to find popular items)
  --not-ids: list<string> # Listing ID negation. If you want to exclude a listing, add it here.
  --local-pickup: oneof<nothing, bool> # Only items that offer local pickup
  --state: string # Available: ["all", "draft", "ended", "live", "ordered", "sold_out", "suspended", "seller_unavailable"]. Defaults to 'live' (default: live)
  --sku: string # Find a listing by sku
]: nothing -> any {
  http-request {
    method: get
    path: "/my/listings"
    query: [{name: query, var: query}, {name: auction_price_max, var: auction_price_max}, {name: category, var: category}, {name: product_type, var: product_type}, {name: conditions, var: conditions, style: csv}, {name: decade, var: decade}, {name: finish, var: finish}, {name: handmade, var: handmade}, {name: item_city, var: item_city}, {name: item_country, var: item_country}, {name: item_region, var: item_region}, {name: item_state, var: item_state}, {name: make, var: make, style: csv}, {name: model, var: model}, {name: must_not, var: must_not}, {name: price_max, var: price_max}, {name: price_min, var: price_min}, {name: currency, var: currency}, {name: year_max, var: year_max}, {name: year_min, var: year_min}, {name: accepts_gift_cards, var: accepts_gift_cards}, {name: preferred_seller, var: preferred_seller}, {name: shop, var: shop}, {name: shop_id, var: shop_id}, {name: listing_type, var: listing_type}, {name: ships_to, var: ships_to}, {name: exclude_auctions, var: exclude_auctions}, {name: accepts_payment_plans, var: accepts_payment_plans}, {name: watchers_count_min, var: watchers_count_min}, {name: not_ids, var: not_ids, style: csv}, {name: local_pickup, var: local_pickup}, {name: state, var: state}, {name: sku, var: sku}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    query: $query, auction_price_max: $auction_price_max, category: $category, product_type: $product_type, conditions: $conditions, decade: $decade, finish: $finish, handmade: $handmade, item_city: $item_city, item_country: $item_country, item_region: $item_region, item_state: $item_state, make: $make, model: $model, must_not: $must_not, price_max: $price_max, price_min: $price_min, currency: $currency, year_max: $year_max, year_min: $year_min, accepts_gift_cards: $accepts_gift_cards, preferred_seller: $preferred_seller, shop: $shop, shop_id: $shop_id, listing_type: $listing_type, ships_to: $ships_to, exclude_auctions: $exclude_auctions, accepts_payment_plans: $accepts_payment_plans, watchers_count_min: $watchers_count_min, not_ids: $not_ids, local_pickup: $local_pickup, state: $state, sku: $sku
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list your draft listings
#
# GET /my/listings/drafts
export def "get-my-listings-drafts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Search query.
  --auction-price-max: float # Maximum current auction price (format: float)
  --category: string # Category slug from /api/categories
  --product-type: string # Product type slug from /api/categories
  --conditions: list<string> # Condition: all,new,b-stock,used,non-functioning,all-but-new,poor,fair,good,very-good,excellent,mint
  --decade: string # Decade: e.g. 1970s, early 70s
  --finish: string # Visual finish of the item, common for guitars
  --handmade: oneof<nothing, bool> # Handmade items only
  --item-city: string # City where item is located
  --item-country: string # DEPRECATED - Country code where item is located
  --item-region: string # Country code where item is located
  --item-state: string # State or region code where item is located
  --make: list<string> # Make(s)/brand of item (e.g. Fender). Can take a single value or an array.
  --model: string # Model of item (e.g. Stratocaster)
  --must-not: string # Search term negation. If you want to exclude a term, add it here
  --price-max: float # Maximum price of search results (USD) (format: float)
  --price-min: float # Minimum price of search results (USD) (format: float)
  --currency: string # The currency to be used for the price filters
  --year-max: int # Maximum year of manufacture
  --year-min: int # Minumum year of manufacture
  --accepts-gift-cards: oneof<nothing, bool> # If true, include only items that accept gift cards
  --preferred-seller: oneof<nothing, bool> # If true, include only items by Reverb Preferred Sellers
  --shop: string # Slug of shop to search
  --shop-id: string # ID of shop to search
  --listing-type: string # Type of listing: auctions,offers
  --ships-to: string # Limit search to items that ship to this country code
  --exclude-auctions: oneof<nothing, bool> # If true, exclude auctions
  --accepts-payment-plans: oneof<nothing, bool> # If true, only show items that can be purchased with a payment plan
  --watchers-count-min: int # Minimum number of watchers (used to find popular items)
  --not-ids: list<string> # Listing ID negation. If you want to exclude a listing, add it here.
  --local-pickup: oneof<nothing, bool> # Only items that offer local pickup
]: nothing -> any {
  http-request {
    method: get
    path: "/my/listings/drafts"
    query: [{name: query, var: query}, {name: auction_price_max, var: auction_price_max}, {name: category, var: category}, {name: product_type, var: product_type}, {name: conditions, var: conditions, style: csv}, {name: decade, var: decade}, {name: finish, var: finish}, {name: handmade, var: handmade}, {name: item_city, var: item_city}, {name: item_country, var: item_country}, {name: item_region, var: item_region}, {name: item_state, var: item_state}, {name: make, var: make, style: csv}, {name: model, var: model}, {name: must_not, var: must_not}, {name: price_max, var: price_max}, {name: price_min, var: price_min}, {name: currency, var: currency}, {name: year_max, var: year_max}, {name: year_min, var: year_min}, {name: accepts_gift_cards, var: accepts_gift_cards}, {name: preferred_seller, var: preferred_seller}, {name: shop, var: shop}, {name: shop_id, var: shop_id}, {name: listing_type, var: listing_type}, {name: ships_to, var: ships_to}, {name: exclude_auctions, var: exclude_auctions}, {name: accepts_payment_plans, var: accepts_payment_plans}, {name: watchers_count_min, var: watchers_count_min}, {name: not_ids, var: not_ids, style: csv}, {name: local_pickup, var: local_pickup}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    query: $query, auction_price_max: $auction_price_max, category: $category, product_type: $product_type, conditions: $conditions, decade: $decade, finish: $finish, handmade: $handmade, item_city: $item_city, item_country: $item_country, item_region: $item_region, item_state: $item_state, make: $make, model: $model, must_not: $must_not, price_max: $price_max, price_min: $price_min, currency: $currency, year_max: $year_max, year_min: $year_min, accepts_gift_cards: $accepts_gift_cards, preferred_seller: $preferred_seller, shop: $shop, shop_id: $shop_id, listing_type: $listing_type, ships_to: $ships_to, exclude_auctions: $exclude_auctions, accepts_payment_plans: $accepts_payment_plans, watchers_count_min: $watchers_count_min, not_ids: $not_ids, local_pickup: $local_pickup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of active negotiations as a seller
#
# GET /my/listings/negotiations
export def "get-my-listings-negotiations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # default: 1
  --per-page: int # default: 24
  --offset: int
]: nothing -> any {
  http-request {
    method: get
    path: "/my/listings/negotiations"
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    page: $page, per_page: $per_page, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# End a listing
#
# PUT /my/listings/{slug}/state/end
export def "put-my-listings-slug-state-end" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  reason: string@reason-completer # The reason this listing is being ended. Valid reasons: ["not_sold", "reverb_sale"].
]: any -> any {
  $in | http-request {
    method: put
    path: "/my/listings/{slug}/state/end"
    path_params: [{name: slug, var: slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: reason, var: reason}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of your lists (wishlist, watch list, etc)
#
# GET /my/lists
export def "get-my-lists" [
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
    path: "/my/lists"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of active negotiations as a buyer
#
# GET /my/negotiations/buying
export def "get-my-negotiations-buying" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # default: 1
  --per-page: int # default: 24
  --offset: int
]: nothing -> any {
  http-request {
    method: get
    path: "/my/negotiations/buying"
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    page: $page, per_page: $per_page, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get offer details
#
# GET /my/negotiations/{id}
export def "get-my-negotiations-id" [
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
    path: "/my/negotiations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accept an offer
#
# POST /my/negotiations/{id}/accept
export def "post-my-negotiations-id-accept" [
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
  --message: string # Message to include with accepted offer
]: any -> any {
  $in | http-request {
    method: post
    path: "/my/negotiations/{id}/accept"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Counter an offer
#
# POST /my/negotiations/{id}/counter
export def "post-my-negotiations-id-counter" [
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
  --country-code: string
  --layaway-terms-slug: string
  --message: string # Message to include with counter offer
  --offer-items: list # item shape: {listing_id: string, price: string, shipping_price: string}
  --price: record # shape: {amount: string, currency: "USD"|"CAD"|"EUR"|"GBP"|"AUD"|"JPY"|"NZD"|"MXN"}
  --quantity: string
  --recipient-id: string # ID of the recipient of the offer. Required if you are the seller pushing an offer to a buyer.
  --region-code: string
  --shipping-price: record # Shipping price (sellers only) — shape: {amount: string, currency: "USD"|"CAD"|"EUR"|"GBP"|"AUD"|"JPY"|"NZD"|"MXN"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/my/negotiations/{id}/counter"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: country_code, var: country_code}, {name: layaway_terms_slug, var: layaway_terms_slug}, {name: message, var: message}, {name: offer_items, var: offer_items}, {name: price, var: price}, {name: quantity, var: quantity}, {name: recipient_id, var: recipient_id}, {name: region_code, var: region_code}, {name: shipping_price, var: shipping_price}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id, country_code: $country_code, layaway_terms_slug: $layaway_terms_slug, message: $message, offer_items: $offer_items, price: $price, quantity: $quantity, recipient_id: $recipient_id, region_code: $region_code, shipping_price: $shipping_price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Decline an offer
#
# POST /my/negotiations/{id}/decline
export def "post-my-negotiations-id-decline" [
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
    path: "/my/negotiations/{id}/decline"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of orders that need feedback
#
# GET /my/orders/awaiting_feedback
export def "get-my-orders-awaiting-feedback" [
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
    path: "/my/orders/awaiting_feedback"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all orders, newest first.
#
# GET /my/orders/buying/all
export def "get-my-orders-buying-all" [
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
    path: "/my/orders/buying/all"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /my/orders/buying/by_uuid/{uuid}
export def "get-my-orders-buying-by-uuid-uuid" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/my/orders/buying/by_uuid/{uuid}"
    path_params: [{name: uuid, var: uuid}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns unpaid orders, newest first.
#
# GET /my/orders/buying/unpaid
export def "get-my-orders-buying-unpaid" [
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
    path: "/my/orders/buying/unpaid"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns order details for a buyer
#
# GET /my/orders/buying/{id}
export def "get-my-orders-buying-id" [
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
    path: "/my/orders/buying/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Marks an order as received by the buyer
#
# POST /my/orders/buying/{id}/mark_received
export def "post-my-orders-buying-id-mark-received" [
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
    path: "/my/orders/buying/{id}/mark_received"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all seller orders, newest first.
#
# GET /my/orders/selling/all
export def "get-my-orders-selling-all" [
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
    path: "/my/orders/selling/all"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get unpaid seller orders, newest first.
#
# GET /my/orders/selling/awaiting_shipment
export def "get-my-orders-selling-awaiting-shipment" [
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
    path: "/my/orders/selling/awaiting_shipment"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# See previous orders from buyer
#
# GET /my/orders/selling/buyer_history/{buyer_id}
export def "get-my-orders-selling-buyer-history-buyer-id" [
  buyer_id: string
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
    path: "/my/orders/selling/buyer_history/{buyer_id}"
    path_params: [{name: buyer_id, var: buyer_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    buyer_id: $buyer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /my/orders/selling/by_uuid/{uuid}
export def "get-my-orders-selling-by-uuid-uuid" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/my/orders/selling/by_uuid/{uuid}"
    path_params: [{name: uuid, var: uuid}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get unpaid seller orders, newest first.
#
# GET /my/orders/selling/unpaid
export def "get-my-orders-selling-unpaid" [
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
    path: "/my/orders/selling/unpaid"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns order details for a seller
#
# GET /my/orders/selling/{id}
export def "get-my-orders-selling-id" [
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
    path: "/my/orders/selling/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Marks an order as picked up
#
# POST /my/orders/selling/{id}/mark_picked_up
export def "post-my-orders-selling-id-mark-picked-up" [
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
  --date: string # Date the item was picked up.
]: any -> any {
  $in | http-request {
    method: post
    path: "/my/orders/selling/{id}/mark_picked_up"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: date, var: date}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Marks an order as shipped
#
# POST /my/orders/selling/{id}/ship
export def "post-my-orders-selling-id-ship" [
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
  provider: string # Shipping provider: One of UPS, USPS, FedEx, DHL Deutschland, DHLExpress, DHLGlobalMail, DHL, Canada Post, CanPar, Royal Mail, PostNL, Australia Post, EMS, La Poste - Colissimo, China Post, GLS, Parcelforce, Purolator, Interlogistica, Correos España, Ukraine Post, DPD Germany, DPD UK, DPD France, Hermes, TNT, Other
  --send-notification: oneof<nothing, bool> # Should we send an email notification to the buyer
  tracking_number: string # Tracking number provided by the shipping provider
]: any -> any {
  $in | http-request {
    method: post
    path: "/my/orders/selling/{id}/ship"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: provider, var: provider}, {name: send_notification, var: send_notification, required: true}, {name: tracking_number, var: tracking_number}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id, provider: $provider, send_notification: $send_notification, tracking_number: $tracking_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiate a refund for a sold order
#
# POST /my/orders/selling/{order_id}/refund_requests
export def "post-my-orders-selling-order-id-refund-requests" [
  order_id: string
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
    path: "/my/orders/selling/{order_id}/refund_requests"
    path_params: [{name: order_id, var: order_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get payments
#
# GET /my/payments/selling
export def "get-my-payments-selling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # default: 1
  --per-page: int # default: 24
  --offset: int
  --created-start-date: string # Filter by date created in ISO8601 format - e.g: 2015-04-09T10:52:23-00:00
  --created-end-date: string # Filter by date created in ISO8601 format - e.g: 2015-04-09T10:52:23-00:00
  --updated-start-date: string # Filter by date modified in ISO8601 format - e.g: 2015-04-09T10:52:23-00:00
  --updated-end-date: string # Filter by date modified in ISO8601 format - e.g: 2015-04-09T10:52:23-00:00
  --order-id: string # Look up payments by order id
]: nothing -> any {
  http-request {
    method: get
    path: "/my/payments/selling"
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: offset, var: offset}, {name: created_start_date, var: created_start_date}, {name: created_end_date, var: created_end_date}, {name: updated_start_date, var: updated_start_date}, {name: updated_end_date, var: updated_end_date}, {name: order_id, var: order_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    page: $page, per_page: $per_page, offset: $offset, created_start_date: $created_start_date, created_end_date: $created_end_date, updated_start_date: $updated_start_date, updated_end_date: $updated_end_date, order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get payment
#
# GET /my/payments/selling/{id}
export def "get-my-payments-selling-id" [
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
    path: "/my/payments/selling/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of payouts
#
# GET /my/payouts
export def "get-my-payouts" [
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
    path: "/my/payouts"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read the line items of a payout
#
# GET /my/payouts/{id}/line_items
export def "get-my-payouts-id-line-items" [
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
    path: "/my/payouts/{id}/line_items"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of refund requests as a seller
#
# GET /my/refund_requests/selling
export def "get-my-refund-requests-selling" [
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
    path: "/my/refund_requests/selling"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a refund request for a sold order
#
# PUT /my/refund_requests/selling/{id}
export def "put-my-refund-requests-selling-id" [
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
    method: put
    path: "/my/refund_requests/selling/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of your recently viewed listings.
#
# GET /my/viewed_listings
export def "get-my-viewed-listings" [
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
    path: "/my/viewed_listings"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of wishlisted items
#
# GET /my/wishlist
export def "get-my-wishlist" [
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
    path: "/my/wishlist"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a listing from your wishlist
#
# DELETE /my/wishlist/{id}
export def "delete-my-wishlist-id" [
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
    path: "/my/wishlist/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a listing to your wishlist
#
# PUT /my/wishlist/{id}
export def "put-my-wishlist-id" [
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
    method: put
    path: "/my/wishlist/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Feedback details for an order's buyer
#
# GET /orders/{order_id}/feedback/buyer
export def "get-orders-order-id-feedback-buyer" [
  order_id: string
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
    path: "/orders/{order_id}/feedback/buyer"
    path_params: [{name: order_id, var: order_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add feedback about an order's buyer
#
# POST /orders/{order_id}/feedback/buyer
export def "post-orders-order-id-feedback-buyer" [
  order_id: string
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
    path: "/orders/{order_id}/feedback/buyer"
    path_params: [{name: order_id, var: order_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Feedback details for an order's seller
#
# GET /orders/{order_id}/feedback/seller
export def "get-orders-order-id-feedback-seller" [
  order_id: string
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
    path: "/orders/{order_id}/feedback/seller"
    path_params: [{name: order_id, var: order_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add feedback about an order's seller
#
# POST /orders/{order_id}/feedback/seller
export def "post-orders-order-id-feedback-seller" [
  order_id: string
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
    path: "/orders/{order_id}/feedback/seller"
    path_params: [{name: order_id, var: order_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of payment methods
#
# GET /payment_methods
export def "get-payment-methods" [
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
    path: "/payment_methods"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a summary of transactions for a given price guide
#
# GET /priceguide/{id}/transactions/summary
export def "get-priceguide-id-transactions-summary" [
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
  --number-of-months: int # default: 3
  --condition: string # default: used
]: nothing -> any {
  http-request {
    method: get
    path: "/priceguide/{id}/transactions/summary"
    path_params: [{name: id, var: id}]
    query: [{name: number_of_months, var: number_of_months}, {name: condition, var: condition}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id, number_of_months: $number_of_months, condition: $condition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a review
#
# GET /products/reviews/{id}
export def "get-products-reviews-id" [
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
    path: "/products/reviews/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a review
#
# PUT /products/reviews/{id}
export def "put-products-reviews-id" [
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
  --body: string # Content of the review
  --rating: int # Rating from 1 to 5
  --title: string # Title for the review
]: any -> any {
  $in | http-request {
    method: put
    path: "/products/reviews/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: rating, var: rating}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id, body: $body, rating: $rating, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View reviews of a comparison shopping page
#
# GET /products/{slug}/reviews
export def "get-products-slug-reviews" [
  slug: string
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
    path: "/products/{slug}/reviews"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a review for a product
#
# POST /products/{slug}/reviews
export def "post-products-slug-reviews" [
  slug: string
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
    path: "/products/{slug}/reviews"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View upcoming and live Reverb official sales.
#
# GET /sales/reverb
export def "get-sales-reverb" [
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
    path: "/sales/reverb"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View your created sales.
#
# GET /sales/seller
export def "get-sales-seller" [
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
    path: "/sales/seller"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a listing from a sale
#
# DELETE /sales/{sale_id}/listings
export def "delete-sales-sale-id-listings" [
  sale_id: string
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
    path: "/sales/{sale_id}/listings"
    path_params: [{name: sale_id, var: sale_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    sale_id: $sale_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add listings to a sale
#
# POST /sales/{sale_id}/listings
export def "post-sales-sale-id-listings" [
  sale_id: string
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
    path: "/sales/{sale_id}/listings"
    path_params: [{name: sale_id, var: sale_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    sale_id: $sale_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sales/{slug}
export def "get-sales-slug" [
  slug: string
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
    path: "/sales/{slug}"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of supported shipping providers
#
# GET /shipping/providers
export def "get-shipping-providers" [
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
    path: "/shipping/providers"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /shipping/regions
export def "get-shipping-regions" [
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
    path: "/shipping/regions"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get your own shop details
#
# GET /shop
export def "get-shop" [
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
    path: "/shop"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update your shop profile
#
# PUT /shop
export def "put-shop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {country_code?: string, extended_address?: string, locality?: string, name?: string, phone?: string, postal_code?: string, region?: string, street_address?: string}
  --currency: string@currency-completer-1
  --description: string
  --legal-country-code: string@legal-country-code-completer
  --legal-country-code-confirmed: oneof<nothing, bool>
  --name: string
  --payment-policy: string
  --return-policy: string
  --shipping-policy: string
  --shop-type: string@shop-type-completer
  --website: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/shop"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: currency, var: currency}, {name: description, var: description}, {name: legal_country_code, var: legal_country_code}, {name: legal_country_code_confirmed, var: legal_country_code_confirmed}, {name: name, var: name}, {name: payment_policy, var: payment_policy}, {name: return_policy, var: return_policy}, {name: shipping_policy, var: shipping_policy}, {name: shop_type, var: shop_type}, {name: website, var: website}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    address: $address, currency: $currency, description: $description, legal_country_code: $legal_country_code, legal_country_code_confirmed: $legal_country_code_confirmed, name: $name, payment_policy: $payment_policy, return_policy: $return_policy, shipping_policy: $shipping_policy, shop_type: $shop_type, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of supported product conditions
#
# GET /shop/listing_conditions
export def "get-shop-listing-conditions" [
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
    path: "/shop/listing_conditions"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get accepted payment methods
#
# GET /shop/payment_methods
export def "get-shop-payment-methods" [
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
    path: "/shop/payment_methods"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable vacation mode. All listings will be re-enabled.
#
# DELETE /shop/vacation
export def "delete-shop-vacation" [
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
    path: "/shop/vacation"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns shop vacation status
#
# GET /shop/vacation
export def "get-shop-vacation" [
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
    path: "/shop/vacation"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable vacation mode. All listings will be unavailable until vacation mode is turned off.
#
# POST /shop/vacation
export def "post-shop-vacation" [
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
    path: "/shop/vacation"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get storefront details on a shop.
#
# GET /shops/{id}/storefronts
export def "get-shops-id-storefronts" [
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
    path: "/shops/{id}/storefronts"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of shipping profiles for your shop
#
# GET /shops/{shop_id}/shipping_profiles
export def "get-shops-shop-id-shipping-profiles" [
  shop_id: string
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
    path: "/shops/{shop_id}/shipping_profiles"
    path_params: [{name: shop_id, var: shop_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    shop_id: $shop_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details on a shop.
#
# GET /shops/{slug}
export def "get-shops-slug" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-listing-count: oneof<nothing, bool> # Include the live listing count in the response.
]: nothing -> any {
  http-request {
    method: get
    path: "/shops/{slug}"
    path_params: [{name: slug, var: slug}]
    query: [{name: include_listing_count, var: include_listing_count}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug, include_listing_count: $include_listing_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get seller's feedback
#
# GET /shops/{slug}/feedback
export def "get-shops-slug-feedback" [
  slug: string
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
    path: "/shops/{slug}/feedback"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get seller's feedback as a buyer
#
# GET /shops/{slug}/feedback/buyer
export def "get-shops-slug-feedback-buyer" [
  slug: string
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
    path: "/shops/{slug}/feedback/buyer"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get seller's feedback as a seller
#
# GET /shops/{slug}/feedback/seller
export def "get-shops-slug-feedback-seller" [
  slug: string
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
    path: "/shops/{slug}/feedback/seller"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A list of wanted items by the user
#
# GET /wants
export def "get-wants" [
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
    path: "/wants"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unmark an item wanted.
#
# DELETE /wants/{id}
export def "delete-wants-id" [
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
    path: "/wants/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark an item wanted. Returns 200 on success or 422 on failure.
#
# PUT /wants/{id}
export def "put-wants-id" [
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
    method: put
    path: "/wants/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get webhook registrations
#
# GET /webhooks/registrations
export def "get-webhooks-registrations" [
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
    path: "/webhooks/registrations"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a webhook
#
# POST /webhooks/registrations
export def "post-webhooks-registrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  topic: string@topic-completer # Valid values: listings/update, listings/publish, listings/bumps-ran-out, orders/create, orders/update, payments/create, payments/update, app/uninstalled
  url: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/webhooks/registrations"
    body: {content_type: "application/json", kind: json, fields: [{name: topic, var: topic}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    topic: $topic, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a webhook
#
# DELETE /webhooks/registrations/{id}
export def "delete-webhooks-registrations-id" [
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
    path: "/webhooks/registrations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details of a webhook registration
#
# GET /webhooks/registrations/{id}
export def "get-webhooks-registrations-id" [
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
    path: "/webhooks/registrations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
