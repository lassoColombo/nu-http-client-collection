# Auto-generated client for AmazonNimbleStudio v2020-08-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/nimble/2020-08-01/openapi.json
# Auth: --token flag or $env.AMAZONNIMBLESTUDIO_TOKEN

const CLIENT = {
  base_url: "http://nimble.us-east-1.amazonaws.com"
  token_env_var: "AMAZONNIMBLESTUDIO_TOKEN"
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

def base-url-completer [] { ["http://nimble.us-east-1.amazonaws.com" "http://nimble.us-east-2.amazonaws.com" "http://nimble.us-west-1.amazonaws.com" "http://nimble.us-west-2.amazonaws.com" "http://nimble.us-gov-west-1.amazonaws.com" "http://nimble.us-gov-east-1.amazonaws.com" "http://nimble.ca-central-1.amazonaws.com" "http://nimble.eu-north-1.amazonaws.com" "http://nimble.eu-west-1.amazonaws.com" "http://nimble.eu-west-2.amazonaws.com" "http://nimble.eu-west-3.amazonaws.com" "http://nimble.eu-central-1.amazonaws.com" "http://nimble.eu-south-1.amazonaws.com" "http://nimble.af-south-1.amazonaws.com" "http://nimble.ap-northeast-1.amazonaws.com" "http://nimble.ap-northeast-2.amazonaws.com" "http://nimble.ap-northeast-3.amazonaws.com" "http://nimble.ap-southeast-1.amazonaws.com" "http://nimble.ap-southeast-2.amazonaws.com" "http://nimble.ap-east-1.amazonaws.com" "http://nimble.ap-south-1.amazonaws.com" "http://nimble.sa-east-1.amazonaws.com" "http://nimble.me-south-1.amazonaws.com" "https://nimble.us-east-1.amazonaws.com" "https://nimble.us-east-2.amazonaws.com" "https://nimble.us-west-1.amazonaws.com" "https://nimble.us-west-2.amazonaws.com" "https://nimble.us-gov-west-1.amazonaws.com" "https://nimble.us-gov-east-1.amazonaws.com" "https://nimble.ca-central-1.amazonaws.com" "https://nimble.eu-north-1.amazonaws.com" "https://nimble.eu-west-1.amazonaws.com" "https://nimble.eu-west-2.amazonaws.com" "https://nimble.eu-west-3.amazonaws.com" "https://nimble.eu-central-1.amazonaws.com" "https://nimble.eu-south-1.amazonaws.com" "https://nimble.af-south-1.amazonaws.com" "https://nimble.ap-northeast-1.amazonaws.com" "https://nimble.ap-northeast-2.amazonaws.com" "https://nimble.ap-northeast-3.amazonaws.com" "https://nimble.ap-southeast-1.amazonaws.com" "https://nimble.ap-southeast-2.amazonaws.com" "https://nimble.ap-east-1.amazonaws.com" "https://nimble.ap-south-1.amazonaws.com" "https://nimble.sa-east-1.amazonaws.com" "https://nimble.me-south-1.amazonaws.com" "http://nimble.cn-north-1.amazonaws.com.cn" "http://nimble.cn-northwest-1.amazonaws.com.cn" "https://nimble.cn-north-1.amazonaws.com.cn" "https://nimble.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def ec2-instance-type-completer [] { ["g3.4xlarge" "g3s.xlarge" "g4dn.12xlarge" "g4dn.16xlarge" "g4dn.2xlarge" "g4dn.4xlarge" "g4dn.8xlarge" "g4dn.xlarge" "g5.16xlarge" "g5.2xlarge" "g5.4xlarge" "g5.8xlarge" "g5.xlarge"] }
def subtype-completer [] { ["AMAZON_FSX_FOR_LUSTRE" "AMAZON_FSX_FOR_WINDOWS" "AWS_MANAGED_MICROSOFT_AD" "CUSTOM"] }
def type-completer [] { ["ACTIVE_DIRECTORY" "COMPUTE_FARM" "CUSTOM" "LICENSE_SERVICE" "SHARED_FILE_SYSTEM"] }
def persona-completer [] { ["USER"] }
def volume-retention-mode-completer [] { ["DELETE" "RETAIN"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    accept-eulas: "record<eulaAcceptances: table<acceptedAt: string, acceptedBy: string, accepteeId: string, eulaAcceptanceId: string, eulaId: string>>"
    list-eula-acceptances: "record<eulaAcceptances: table<acceptedAt: string, acceptedBy: string, accepteeId: string, eulaAcceptanceId: string, eulaId: string>, nextToken: string>"
    create-launch-profile: "record<launchProfile: record<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list<string>, launchProfileId: string, launchProfileProtocolVersions: list<string>, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record<automaticTerminationMode: string, clipboardMode: string, ec2InstanceTypes: list, maxSessionLengthInMinutes: int, maxStoppedSessionLengthInMinutes: int, sessionBackup: record, sessionPersistenceMode: string, sessionStorage: record, streamingImageIds: list, volumeConfiguration: record>, studioComponentIds: list<string>, tags: record, updatedAt: string, updatedBy: string, validationResults: list<record>>>"
    list-launch-profiles: "record<launchProfiles: table<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list, launchProfileId: string, launchProfileProtocolVersions: list, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record, studioComponentIds: list, tags: record, updatedAt: string, updatedBy: string, validationResults: list>, nextToken: string>"
    create-streaming-image: "record<streamingImage: record<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record<keyArn: string, keyType: string>, eulaIds: list<string>, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>>"
    list-streaming-images: "record<nextToken: string, streamingImages: table<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record, eulaIds: list, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>>"
    create-streaming-session: "record<session: record<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record<iops: int, size: int, throughput: int>, volumeRetentionMode: string>>"
    list-streaming-sessions: "record<nextToken: string, sessions: table<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record, volumeRetentionMode: string>>"
    create-streaming-session-stream: "record<stream: record<createdAt: string, createdBy: string, expiresAt: string, ownedBy: string, state: string, statusCode: string, streamId: string, url: string>>"
    create-studio: "record<studio: record<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record<keyArn: string, keyType: string>, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>"
    list-studios: "record<nextToken: string, studios: table<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>"
    create-studio-component: "record<studioComponent: record<arn: string, configuration: record<activeDirectoryConfiguration: record, computeFarmConfiguration: record, licenseServiceConfiguration: record, sharedFileSystemConfiguration: record>, createdAt: string, createdBy: string, description: string, ec2SecurityGroupIds: list<string>, initializationScripts: list<record>, name: string, runtimeRoleArn: string, scriptParameters: list<record>, secureInitializationRoleArn: string, state: string, statusCode: string, statusMessage: string, studioComponentId: string, subtype: string, tags: record, type: string, updatedAt: string, updatedBy: string>>"
    list-studio-components: "record<nextToken: string, studioComponents: table<arn: string, configuration: record, createdAt: string, createdBy: string, description: string, ec2SecurityGroupIds: list, initializationScripts: list, name: string, runtimeRoleArn: string, scriptParameters: list, secureInitializationRoleArn: string, state: string, statusCode: string, statusMessage: string, studioComponentId: string, subtype: string, tags: record, type: string, updatedAt: string, updatedBy: string>>"
    delete-launch-profile: "record<launchProfile: record<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list<string>, launchProfileId: string, launchProfileProtocolVersions: list<string>, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record<automaticTerminationMode: string, clipboardMode: string, ec2InstanceTypes: list, maxSessionLengthInMinutes: int, maxStoppedSessionLengthInMinutes: int, sessionBackup: record, sessionPersistenceMode: string, sessionStorage: record, streamingImageIds: list, volumeConfiguration: record>, studioComponentIds: list<string>, tags: record, updatedAt: string, updatedBy: string, validationResults: list<record>>>"
    get-launch-profile: "record<launchProfile: record<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list<string>, launchProfileId: string, launchProfileProtocolVersions: list<string>, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record<automaticTerminationMode: string, clipboardMode: string, ec2InstanceTypes: list, maxSessionLengthInMinutes: int, maxStoppedSessionLengthInMinutes: int, sessionBackup: record, sessionPersistenceMode: string, sessionStorage: record, streamingImageIds: list, volumeConfiguration: record>, studioComponentIds: list<string>, tags: record, updatedAt: string, updatedBy: string, validationResults: list<record>>>"
    update-launch-profile: "record<launchProfile: record<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list<string>, launchProfileId: string, launchProfileProtocolVersions: list<string>, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record<automaticTerminationMode: string, clipboardMode: string, ec2InstanceTypes: list, maxSessionLengthInMinutes: int, maxStoppedSessionLengthInMinutes: int, sessionBackup: record, sessionPersistenceMode: string, sessionStorage: record, streamingImageIds: list, volumeConfiguration: record>, studioComponentIds: list<string>, tags: record, updatedAt: string, updatedBy: string, validationResults: list<record>>>"
    delete-launch-profile-member: "record"
    get-launch-profile-member: "record<member: record<identityStoreId: string, persona: string, principalId: string, sid: string>>"
    update-launch-profile-member: "record<member: record<identityStoreId: string, persona: string, principalId: string, sid: string>>"
    delete-streaming-image: "record<streamingImage: record<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record<keyArn: string, keyType: string>, eulaIds: list<string>, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>>"
    get-streaming-image: "record<streamingImage: record<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record<keyArn: string, keyType: string>, eulaIds: list<string>, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>>"
    update-streaming-image: "record<streamingImage: record<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record<keyArn: string, keyType: string>, eulaIds: list<string>, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>>"
    delete-streaming-session: "record<session: record<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record<iops: int, size: int, throughput: int>, volumeRetentionMode: string>>"
    get-streaming-session: "record<session: record<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record<iops: int, size: int, throughput: int>, volumeRetentionMode: string>>"
    delete-studio: "record<studio: record<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record<keyArn: string, keyType: string>, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>"
    get-studio: "record<studio: record<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record<keyArn: string, keyType: string>, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>"
    update-studio: "record<studio: record<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record<keyArn: string, keyType: string>, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>"
    delete-studio-component: "record<studioComponent: record<arn: string, configuration: record<activeDirectoryConfiguration: record, computeFarmConfiguration: record, licenseServiceConfiguration: record, sharedFileSystemConfiguration: record>, createdAt: string, createdBy: string, description: string, ec2SecurityGroupIds: list<string>, initializationScripts: list<record>, name: string, runtimeRoleArn: string, scriptParameters: list<record>, secureInitializationRoleArn: string, state: string, statusCode: string, statusMessage: string, studioComponentId: string, subtype: string, tags: record, type: string, updatedAt: string, updatedBy: string>>"
    get-studio-component: "record<studioComponent: record<arn: string, configuration: record<activeDirectoryConfiguration: record, computeFarmConfiguration: record, licenseServiceConfiguration: record, sharedFileSystemConfiguration: record>, createdAt: string, createdBy: string, description: string, ec2SecurityGroupIds: list<string>, initializationScripts: list<record>, name: string, runtimeRoleArn: string, scriptParameters: list<record>, secureInitializationRoleArn: string, state: string, statusCode: string, statusMessage: string, studioComponentId: string, subtype: string, tags: record, type: string, updatedAt: string, updatedBy: string>>"
    update-studio-component: "record<studioComponent: record<arn: string, configuration: record<activeDirectoryConfiguration: record, computeFarmConfiguration: record, licenseServiceConfiguration: record, sharedFileSystemConfiguration: record>, createdAt: string, createdBy: string, description: string, ec2SecurityGroupIds: list<string>, initializationScripts: list<record>, name: string, runtimeRoleArn: string, scriptParameters: list<record>, secureInitializationRoleArn: string, state: string, statusCode: string, statusMessage: string, studioComponentId: string, subtype: string, tags: record, type: string, updatedAt: string, updatedBy: string>>"
    delete-studio-member: "record"
    get-studio-member: "record<member: record<identityStoreId: string, persona: string, principalId: string, sid: string>>"
    get-eula: "record<eula: record<content: string, createdAt: string, eulaId: string, name: string, updatedAt: string>>"
    get-launch-profile-details: "record<launchProfile: record<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list<string>, launchProfileId: string, launchProfileProtocolVersions: list<string>, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record<automaticTerminationMode: string, clipboardMode: string, ec2InstanceTypes: list, maxSessionLengthInMinutes: int, maxStoppedSessionLengthInMinutes: int, sessionBackup: record, sessionPersistenceMode: string, sessionStorage: record, streamingImageIds: list, volumeConfiguration: record>, studioComponentIds: list<string>, tags: record, updatedAt: string, updatedBy: string, validationResults: list<record>>, streamingImages: table<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record, eulaIds: list, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>, studioComponentSummaries: table<createdAt: string, createdBy: string, description: string, name: string, studioComponentId: string, subtype: string, type: string, updatedAt: string, updatedBy: string>>"
    get-launch-profile-initialization: "record<launchProfileInitialization: record<activeDirectory: record<computerAttributes: list, directoryId: string, directoryName: string, dnsIpAddresses: list, organizationalUnitDistinguishedName: string, studioComponentId: string, studioComponentName: string>, ec2SecurityGroupIds: list<string>, launchProfileId: string, launchProfileProtocolVersion: string, launchPurpose: string, name: string, platform: string, systemInitializationScripts: list<record>, userInitializationScripts: list<record>>>"
    get-streaming-session-backup: "record<streamingSessionBackup: record<arn: string, backupId: string, createdAt: string, launchProfileId: string, ownedBy: string, sessionId: string, state: string, statusCode: string, statusMessage: string, tags: record>>"
    get-streaming-session-stream: "record<stream: record<createdAt: string, createdBy: string, expiresAt: string, ownedBy: string, state: string, statusCode: string, streamId: string, url: string>>"
    list-eulas: "record<eulas: table<content: string, createdAt: string, eulaId: string, name: string, updatedAt: string>, nextToken: string>"
    list-launch-profile-members: "record<members: table<identityStoreId: string, persona: string, principalId: string, sid: string>, nextToken: string>"
    put-launch-profile-members: "record"
    list-streaming-session-backups: "record<nextToken: string, streamingSessionBackups: table<arn: string, backupId: string, createdAt: string, launchProfileId: string, ownedBy: string, sessionId: string, state: string, statusCode: string, statusMessage: string, tags: record>>"
    list-studio-members: "record<members: table<identityStoreId: string, persona: string, principalId: string, sid: string>, nextToken: string>"
    put-studio-members: "record"
    list-tags-for-resource: "record<tags: record>"
    tag-resource: "record"
    start-streaming-session: "record<session: record<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record<iops: int, size: int, throughput: int>, volumeRetentionMode: string>>"
    start-studio-sso-configuration-repair: "record<studio: record<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record<keyArn: string, keyType: string>, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>"
    stop-streaming-session: "record<session: record<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record<iops: int, size: int, throughput: int>, volumeRetentionMode: string>>"
    untag-resource: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accept-eulas" "list-eula-acceptances" "create-launch-profile" "list-launch-profiles" "create-streaming-image" "list-streaming-images" "create-streaming-session" "list-streaming-sessions" "create-streaming-session-stream" "create-studio" "list-studios" "create-studio-component" "list-studio-components" "delete-launch-profile" "get-launch-profile" "update-launch-profile" "delete-launch-profile-member" "get-launch-profile-member" "update-launch-profile-member" "delete-streaming-image" "get-streaming-image" "update-streaming-image" "delete-streaming-session" "get-streaming-session" "delete-studio" "get-studio" "update-studio" "delete-studio-component" "get-studio-component" "update-studio-component" "delete-studio-member" "get-studio-member" "get-eula" "get-launch-profile-details" "get-launch-profile-initialization" "get-streaming-session-backup" "get-streaming-session-stream" "list-eulas" "list-launch-profile-members" "put-launch-profile-members" "list-streaming-session-backups" "list-studio-members" "put-studio-members" "list-tags-for-resource" "tag-resource" "start-streaming-session" "start-studio-sso-configuration-repair" "stop-streaming-session" "untag-resource" "commands"] | sort) } | get name | first)
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

# Accept EULAs.
#
# POST /2020-08-01/studios/{studioId}/eula-acceptances
# Returns: record<eulaAcceptances: table<acceptedAt: string, acceptedBy: string, accepteeId: string, eulaAcceptanceId: string, eulaId: string>>
# operationId: AcceptEulas
export def "accept-eulas" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --eula-ids: list<string> # The EULA ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-08-01/studios/{studioId}/eula-acceptances"
    path_params: [{name: studioId, var: studio_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: eulaIds, var: eula_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token, eula_ids: $eula_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List EULA acceptances.
#
# GET /2020-08-01/studios/{studioId}/eula-acceptances
# Returns: record<eulaAcceptances: table<acceptedAt: string, acceptedBy: string, accepteeId: string, eulaAcceptanceId: string, eulaId: string>, nextToken: string>
# operationId: ListEulaAcceptances
export def "list-eula-acceptances" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --eula-ids: list<string> # The list of EULA IDs that have been previously accepted.
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/eula-acceptances"
    path_params: [{name: studioId, var: studio_id}]
    query: [{name: eulaIds, var: eula_ids, style: multi}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, eula_ids: $eula_ids, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a launch profile.
#
# POST /2020-08-01/studios/{studioId}/launch-profiles
# Returns: record<launchProfile: record<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list<string>, launchProfileId: string, launchProfileProtocolVersions: list<string>, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record<automaticTerminationMode: string, clipboardMode: string, ec2InstanceTypes: list, maxSessionLengthInMinutes: int, maxStoppedSessionLengthInMinutes: int, sessionBackup: record, sessionPersistenceMode: string, sessionStorage: record, streamingImageIds: list, volumeConfiguration: record>, studioComponentIds: list<string>, tags: record, updatedAt: string, updatedBy: string, validationResults: list<record>>>
# operationId: CreateLaunchProfile
export def "create-launch-profile" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --description: string # A human-readable description of the launch profile. (format: password)
  ec2_subnet_ids: list<string> # Specifies the IDs of the EC2 subnets where streaming sessions will be accessible from. These subnets must support the specified instance types.
  launch_profile_protocol_versions: list<string> # The version number of the protocol that is used by the launch profile. The only valid version is "2021-03-31".
  name: string # The name for the launch profile. (format: password)
  stream_configuration: record # Configuration for streaming workstations created using this launch profile. — shape: {automaticTerminationMode?: "DEACTIVATED"|"ACTIVATED", clipboardMode?: "ENABLED"|"DISABLED", ec2InstanceTypes?: list<string>, maxSessionLengthInMinutes?: int, maxStoppedSessionLengthInMinutes?: int, sessionBackup?: record, sessionPersistenceMode?: "DEACTIVATED"|"ACTIVATED", sessionStorage?: record, streamingImageIds?: list<string>, volumeConfiguration?: record}
  studio_component_ids: list<string> # Unique identifiers for a collection of studio components that can be used with this launch profile.
  --tags: record # A collection of labels, in the form of key-value pairs, that apply to this resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-08-01/studios/{studioId}/launch-profiles"
    path_params: [{name: studioId, var: studio_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: ec2SubnetIds, var: ec2_subnet_ids}, {name: launchProfileProtocolVersions, var: launch_profile_protocol_versions}, {name: name, var: name}, {name: streamConfiguration, var: stream_configuration}, {name: studioComponentIds, var: studio_component_ids}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token, description: $description, ec2_subnet_ids: $ec2_subnet_ids, launch_profile_protocol_versions: $launch_profile_protocol_versions, name: $name, stream_configuration: $stream_configuration, studio_component_ids: $studio_component_ids, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all the launch profiles a studio.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles
# Returns: record<launchProfiles: table<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list, launchProfileId: string, launchProfileProtocolVersions: list, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record, studioComponentIds: list, tags: record, updatedAt: string, updatedBy: string, validationResults: list>, nextToken: string>
# operationId: ListLaunchProfiles
export def "list-launch-profiles" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The max number of results to return in the response.
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --principal-id: string # The principal ID. This currently supports a IAM Identity Center UserId.
  --states: list<string> # Filter this request to launch profiles in any of the given states.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/launch-profiles"
    path_params: [{name: studioId, var: studio_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: principalId, var: principal_id}, {name: states, var: states, style: multi}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, max_results: $max_results, next_token: $next_token, principal_id: $principal_id, states: $states, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a streaming image resource in a studio.
#
# POST /2020-08-01/studios/{studioId}/streaming-images
# Returns: record<streamingImage: record<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record<keyArn: string, keyType: string>, eulaIds: list<string>, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>>
# operationId: CreateStreamingImage
export def "create-streaming-image" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --description: string # The description. (format: password)
  ec2_image_id: string # The ID of an EC2 machine image with which to create this streaming image.
  name: string # A friendly name for a streaming image resource. (format: password)
  --tags: record # A collection of labels, in the form of key-value pairs, that apply to this resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-08-01/studios/{studioId}/streaming-images"
    path_params: [{name: studioId, var: studio_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: ec2ImageId, var: ec2_image_id}, {name: name, var: name}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token, description: $description, ec2_image_id: $ec2_image_id, name: $name, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the streaming image resources available to this studio. This list will contain both images provided by Amazon Web Services, as well as streaming images that you have created in your studio.
#
# GET /2020-08-01/studios/{studioId}/streaming-images
# Returns: record<nextToken: string, streamingImages: table<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record, eulaIds: list, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>>
# operationId: ListStreamingImages
export def "list-streaming-images" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --owner: string # Filter this request to streaming images with the given owner
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/streaming-images"
    path_params: [{name: studioId, var: studio_id}]
    query: [{name: nextToken, var: next_token}, {name: owner, var: owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, next_token: $next_token, owner: $owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a streaming session in a studio. After invoking this operation, you must poll GetStreamingSession until the streaming session is in the READY state.
#
# POST /2020-08-01/studios/{studioId}/streaming-sessions
# Returns: record<session: record<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record<iops: int, size: int, throughput: int>, volumeRetentionMode: string>>
# operationId: CreateStreamingSession
export def "create-streaming-session" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --ec2-instance-type: string@ec2-instance-type-completer # The EC2 Instance type used for the streaming session.
  launch_profile_id: string # The ID of the launch profile used to control access from the streaming session.
  --owned-by: string # The user ID of the user that owns the streaming session. The user that owns the session will be logging into the session and interacting with the virtual workstation.
  --streaming-image-id: string # The ID of the streaming image.
  --tags: record # A collection of labels, in the form of key-value pairs, that apply to this resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-08-01/studios/{studioId}/streaming-sessions"
    path_params: [{name: studioId, var: studio_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: ec2InstanceType, var: ec2_instance_type}, {name: launchProfileId, var: launch_profile_id}, {name: ownedBy, var: owned_by}, {name: streamingImageId, var: streaming_image_id}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token, ec2_instance_type: $ec2_instance_type, launch_profile_id: $launch_profile_id, owned_by: $owned_by, streaming_image_id: $streaming_image_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the streaming sessions in a studio.
#
# GET /2020-08-01/studios/{studioId}/streaming-sessions
# Returns: record<nextToken: string, sessions: table<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record, volumeRetentionMode: string>>
# operationId: ListStreamingSessions
export def "list-streaming-sessions" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-by: string # Filters the request to streaming sessions created by the given user.
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --owned-by: string # Filters the request to streaming session owned by the given user
  --session-ids: string # Filters the request to only the provided session IDs.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/streaming-sessions"
    path_params: [{name: studioId, var: studio_id}]
    query: [{name: createdBy, var: created_by}, {name: nextToken, var: next_token}, {name: ownedBy, var: owned_by}, {name: sessionIds, var: session_ids}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, created_by: $created_by, next_token: $next_token, owned_by: $owned_by, session_ids: $session_ids, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a streaming session stream for a streaming session. After invoking this API, invoke GetStreamingSessionStream with the returned streamId to poll the resource until it is in the READY state.
#
# POST /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}/streams
# Returns: record<stream: record<createdAt: string, createdBy: string, expiresAt: string, ownedBy: string, state: string, statusCode: string, streamId: string, url: string>>
# operationId: CreateStreamingSessionStream
export def "create-streaming-session-stream" [
  studio_id: string
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --expiration-in-seconds: int # The expiration time in seconds.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}/streams"
    path_params: [{name: studioId, var: studio_id}, {name: sessionId, var: session_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: expirationInSeconds, var: expiration_in_seconds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, session_id: $session_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token, expiration_in_seconds: $expiration_in_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new studio. When creating a studio, two IAM roles must be provided: the admin role and the user role. These roles are assumed by your users when they log in to the Nimble Studio portal. The user role must have the AmazonNimbleStudio-StudioUser managed policy attached for the portal to function properly. The admin role must have the AmazonNimbleStudio-StudioAdmin managed policy attached for the portal to function properly. You may optionally specify a KMS key in the StudioEncryptionConfiguration. In Nimble Studio, resource names, descriptions, initialization scripts, and other data you provide are always encrypted at rest using an KMS key. By default, this key is owned by Amazon Web Services and managed on your behalf. You may provide your own KMS key when calling CreateStudio to encrypt this data using a key you own and manage. When providing an KMS key during studio creation, Nimble Studio creates KMS grants in your account to provide your studio user and admin roles access to these KMS keys. If you delete this grant, the studio will no longer be accessible to your portal users. If you delete the studio KMS key, your studio will no longer be accessible.
#
# POST /2020-08-01/studios
# Returns: record<studio: record<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record<keyArn: string, keyType: string>, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>
# operationId: CreateStudio
export def "create-studio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  admin_role_arn: string # The IAM role that studio admins will assume when logging in to the Nimble Studio portal.
  display_name: string # A friendly name for the studio. (format: password)
  --studio-encryption-configuration: record # Configuration of the encryption method that is used for the studio. — shape: {keyArn?: string, keyType?: "AWS_OWNED_KEY"|"CUSTOMER_MANAGED_KEY"}
  studio_name: string # The studio name that is used in the URL of the Nimble Studio portal when accessed by Nimble Studio users.
  --tags: record # A collection of labels, in the form of key-value pairs, that apply to this resource.
  user_role_arn: string # The IAM role that studio users will assume when logging in to the Nimble Studio portal.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-08-01/studios"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: adminRoleArn, var: admin_role_arn}, {name: displayName, var: display_name}, {name: studioEncryptionConfiguration, var: studio_encryption_configuration}, {name: studioName, var: studio_name}, {name: tags, var: tags}, {name: userRoleArn, var: user_role_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token, admin_role_arn: $admin_role_arn, display_name: $display_name, studio_encryption_configuration: $studio_encryption_configuration, studio_name: $studio_name, tags: $tags, user_role_arn: $user_role_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List studios in your Amazon Web Services accounts in the requested Amazon Web Services Region.
#
# GET /2020-08-01/studios
# Returns: record<nextToken: string, studios: table<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>
# operationId: ListStudios
export def "list-studios" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a studio component resource.
#
# POST /2020-08-01/studios/{studioId}/studio-components
# Returns: record<studioComponent: record<arn: string, configuration: record<activeDirectoryConfiguration: record, computeFarmConfiguration: record, licenseServiceConfiguration: record, sharedFileSystemConfiguration: record>, createdAt: string, createdBy: string, description: string, ec2SecurityGroupIds: list<string>, initializationScripts: list<record>, name: string, runtimeRoleArn: string, scriptParameters: list<record>, secureInitializationRoleArn: string, state: string, statusCode: string, statusMessage: string, studioComponentId: string, subtype: string, tags: record, type: string, updatedAt: string, updatedBy: string>>
# operationId: CreateStudioComponent
export def "create-studio-component" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --configuration: record # The configuration of the studio component, based on component type. — shape: {activeDirectoryConfiguration?: record, computeFarmConfiguration?: record, licenseServiceConfiguration?: record, sharedFileSystemConfiguration?: record}
  --description: string # The description. (format: password)
  --ec2-security-group-ids: list<string> # The EC2 security groups that control access to the studio component.
  --initialization-scripts: list # Initialization scripts for studio components. — item shape: {launchProfileProtocolVersion?: string, platform?: "LINUX"|"WINDOWS", runContext?: "SYSTEM_INITIALIZATION"|"USER_INITIALIZATION", script?: string}
  name: string # The name for the studio component. (format: password)
  --runtime-role-arn: string # An IAM role attached to a Studio Component that gives the studio component access to Amazon Web Services resources at anytime while the instance is running.
  --script-parameters: list # Parameters for the studio component scripts. — item shape: {key?: string, value?: string}
  --secure-initialization-role-arn: string # An IAM role attached to Studio Component when the system initialization script runs which give the studio component access to Amazon Web Services resources when the system initialization script runs.
  --subtype: string@subtype-completer # The specific subtype of a studio component.
  --tags: record # A collection of labels, in the form of key-value pairs, that apply to this resource.
  type: string@type-completer # The type of the studio component.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-08-01/studios/{studioId}/studio-components"
    path_params: [{name: studioId, var: studio_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: configuration, var: configuration}, {name: description, var: description}, {name: ec2SecurityGroupIds, var: ec2_security_group_ids}, {name: initializationScripts, var: initialization_scripts}, {name: name, var: name}, {name: runtimeRoleArn, var: runtime_role_arn}, {name: scriptParameters, var: script_parameters}, {name: secureInitializationRoleArn, var: secure_initialization_role_arn}, {name: subtype, var: subtype}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token, configuration: $configuration, description: $description, ec2_security_group_ids: $ec2_security_group_ids, initialization_scripts: $initialization_scripts, name: $name, runtime_role_arn: $runtime_role_arn, script_parameters: $script_parameters, secure_initialization_role_arn: $secure_initialization_role_arn, subtype: $subtype, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the StudioComponents in a studio.
#
# GET /2020-08-01/studios/{studioId}/studio-components
# Returns: record<nextToken: string, studioComponents: table<arn: string, configuration: record, createdAt: string, createdBy: string, description: string, ec2SecurityGroupIds: list, initializationScripts: list, name: string, runtimeRoleArn: string, scriptParameters: list, secureInitializationRoleArn: string, state: string, statusCode: string, statusMessage: string, studioComponentId: string, subtype: string, tags: record, type: string, updatedAt: string, updatedBy: string>>
# operationId: ListStudioComponents
export def "list-studio-components" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The max number of results to return in the response.
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --states: list<string> # Filters the request to studio components that are in one of the given states.
  --types: list<string> # Filters the request to studio components that are of one of the given types.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/studio-components"
    path_params: [{name: studioId, var: studio_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: states, var: states, style: multi}, {name: types, var: types, style: multi}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, max_results: $max_results, next_token: $next_token, states: $states, types: $types, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently delete a launch profile.
#
# DELETE /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}
# Returns: record<launchProfile: record<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list<string>, launchProfileId: string, launchProfileProtocolVersions: list<string>, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record<automaticTerminationMode: string, clipboardMode: string, ec2InstanceTypes: list, maxSessionLengthInMinutes: int, maxStoppedSessionLengthInMinutes: int, sessionBackup: record, sessionPersistenceMode: string, sessionStorage: record, streamingImageIds: list, volumeConfiguration: record>, studioComponentIds: list<string>, tags: record, updatedAt: string, updatedBy: string, validationResults: list<record>>>
# operationId: DeleteLaunchProfile
export def "delete-launch-profile" [
  studio_id: string
  launch_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}"
    path_params: [{name: studioId, var: studio_id}, {name: launchProfileId, var: launch_profile_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, launch_profile_id: $launch_profile_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a launch profile.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}
# Returns: record<launchProfile: record<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list<string>, launchProfileId: string, launchProfileProtocolVersions: list<string>, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record<automaticTerminationMode: string, clipboardMode: string, ec2InstanceTypes: list, maxSessionLengthInMinutes: int, maxStoppedSessionLengthInMinutes: int, sessionBackup: record, sessionPersistenceMode: string, sessionStorage: record, streamingImageIds: list, volumeConfiguration: record>, studioComponentIds: list<string>, tags: record, updatedAt: string, updatedBy: string, validationResults: list<record>>>
# operationId: GetLaunchProfile
export def "get-launch-profile" [
  studio_id: string
  launch_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}"
    path_params: [{name: studioId, var: studio_id}, {name: launchProfileId, var: launch_profile_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, launch_profile_id: $launch_profile_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a launch profile.
#
# PATCH /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}
# Returns: record<launchProfile: record<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list<string>, launchProfileId: string, launchProfileProtocolVersions: list<string>, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record<automaticTerminationMode: string, clipboardMode: string, ec2InstanceTypes: list, maxSessionLengthInMinutes: int, maxStoppedSessionLengthInMinutes: int, sessionBackup: record, sessionPersistenceMode: string, sessionStorage: record, streamingImageIds: list, volumeConfiguration: record>, studioComponentIds: list<string>, tags: record, updatedAt: string, updatedBy: string, validationResults: list<record>>>
# operationId: UpdateLaunchProfile
export def "update-launch-profile" [
  studio_id: string
  launch_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --description: string # A human-readable description of the launch profile. (format: password)
  --launch-profile-protocol-versions: list<string> # The version number of the protocol that is used by the launch profile. The only valid version is "2021-03-31".
  --name: string # The name for the launch profile. (format: password)
  --stream-configuration: record # Configuration for streaming workstations created using this launch profile. — shape: {automaticTerminationMode?: "DEACTIVATED"|"ACTIVATED", clipboardMode?: "ENABLED"|"DISABLED", ec2InstanceTypes?: list<string>, maxSessionLengthInMinutes?: int, maxStoppedSessionLengthInMinutes?: int, sessionBackup?: record, sessionPersistenceMode?: "DEACTIVATED"|"ACTIVATED", sessionStorage?: record, streamingImageIds?: list<string>, volumeConfiguration?: record}
  --studio-component-ids: list<string> # Unique identifiers for a collection of studio components that can be used with this launch profile.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}"
    path_params: [{name: studioId, var: studio_id}, {name: launchProfileId, var: launch_profile_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: launchProfileProtocolVersions, var: launch_profile_protocol_versions}, {name: name, var: name}, {name: streamConfiguration, var: stream_configuration}, {name: studioComponentIds, var: studio_component_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, launch_profile_id: $launch_profile_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token, description: $description, launch_profile_protocol_versions: $launch_profile_protocol_versions, name: $name, stream_configuration: $stream_configuration, studio_component_ids: $studio_component_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user from launch profile membership.
#
# DELETE /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership/{principalId}
# Returns: record
# operationId: DeleteLaunchProfileMember
export def "delete-launch-profile-member" [
  studio_id: string
  launch_profile_id: string
  principal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership/{principalId}"
    path_params: [{name: studioId, var: studio_id}, {name: launchProfileId, var: launch_profile_id}, {name: principalId, var: principal_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, launch_profile_id: $launch_profile_id, principal_id: $principal_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user persona in launch profile membership.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership/{principalId}
# Returns: record<member: record<identityStoreId: string, persona: string, principalId: string, sid: string>>
# operationId: GetLaunchProfileMember
export def "get-launch-profile-member" [
  studio_id: string
  launch_profile_id: string
  principal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership/{principalId}"
    path_params: [{name: studioId, var: studio_id}, {name: launchProfileId, var: launch_profile_id}, {name: principalId, var: principal_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, launch_profile_id: $launch_profile_id, principal_id: $principal_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a user persona in launch profile membership.
#
# PATCH /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership/{principalId}
# Returns: record<member: record<identityStoreId: string, persona: string, principalId: string, sid: string>>
# operationId: UpdateLaunchProfileMember
export def "update-launch-profile-member" [
  studio_id: string
  launch_profile_id: string
  principal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  persona: string@persona-completer # The persona.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership/{principalId}"
    path_params: [{name: studioId, var: studio_id}, {name: launchProfileId, var: launch_profile_id}, {name: principalId, var: principal_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: persona, var: persona}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, launch_profile_id: $launch_profile_id, principal_id: $principal_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token, persona: $persona
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete streaming image.
#
# DELETE /2020-08-01/studios/{studioId}/streaming-images/{streamingImageId}
# Returns: record<streamingImage: record<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record<keyArn: string, keyType: string>, eulaIds: list<string>, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>>
# operationId: DeleteStreamingImage
export def "delete-streaming-image" [
  studio_id: string
  streaming_image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2020-08-01/studios/{studioId}/streaming-images/{streamingImageId}"
    path_params: [{name: studioId, var: studio_id}, {name: streamingImageId, var: streaming_image_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, streaming_image_id: $streaming_image_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get streaming image.
#
# GET /2020-08-01/studios/{studioId}/streaming-images/{streamingImageId}
# Returns: record<streamingImage: record<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record<keyArn: string, keyType: string>, eulaIds: list<string>, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>>
# operationId: GetStreamingImage
export def "get-streaming-image" [
  studio_id: string
  streaming_image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/streaming-images/{streamingImageId}"
    path_params: [{name: studioId, var: studio_id}, {name: streamingImageId, var: streaming_image_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, streaming_image_id: $streaming_image_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update streaming image.
#
# PATCH /2020-08-01/studios/{studioId}/streaming-images/{streamingImageId}
# Returns: record<streamingImage: record<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record<keyArn: string, keyType: string>, eulaIds: list<string>, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>>
# operationId: UpdateStreamingImage
export def "update-streaming-image" [
  studio_id: string
  streaming_image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --description: string # The description. (format: password)
  --name: string # A friendly name for a streaming image resource. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/2020-08-01/studios/{studioId}/streaming-images/{streamingImageId}"
    path_params: [{name: studioId, var: studio_id}, {name: streamingImageId, var: streaming_image_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, streaming_image_id: $streaming_image_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes streaming session resource. After invoking this operation, use GetStreamingSession to poll the resource until it transitions to a DELETED state. A streaming session will count against your streaming session quota until it is marked DELETED.
#
# DELETE /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}
# Returns: record<session: record<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record<iops: int, size: int, throughput: int>, volumeRetentionMode: string>>
# operationId: DeleteStreamingSession
export def "delete-streaming-session" [
  studio_id: string
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}"
    path_params: [{name: studioId, var: studio_id}, {name: sessionId, var: session_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, session_id: $session_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets StreamingSession resource. Invoke this operation to poll for a streaming session state while creating or deleting a session.
#
# GET /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}
# Returns: record<session: record<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record<iops: int, size: int, throughput: int>, volumeRetentionMode: string>>
# operationId: GetStreamingSession
export def "get-streaming-session" [
  studio_id: string
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}"
    path_params: [{name: studioId, var: studio_id}, {name: sessionId, var: session_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, session_id: $session_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a studio resource.
#
# DELETE /2020-08-01/studios/{studioId}
# Returns: record<studio: record<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record<keyArn: string, keyType: string>, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>
# operationId: DeleteStudio
export def "delete-studio" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2020-08-01/studios/{studioId}"
    path_params: [{name: studioId, var: studio_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a studio resource.
#
# GET /2020-08-01/studios/{studioId}
# Returns: record<studio: record<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record<keyArn: string, keyType: string>, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>
# operationId: GetStudio
export def "get-studio" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}"
    path_params: [{name: studioId, var: studio_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Studio resource. Currently, this operation only supports updating the displayName of your studio.
#
# PATCH /2020-08-01/studios/{studioId}
# Returns: record<studio: record<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record<keyArn: string, keyType: string>, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>
# operationId: UpdateStudio
export def "update-studio" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --admin-role-arn: string # The IAM role that Studio Admins will assume when logging in to the Nimble Studio portal.
  --display-name: string # A friendly name for the studio. (format: password)
  --user-role-arn: string # The IAM role that Studio Users will assume when logging in to the Nimble Studio portal.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/2020-08-01/studios/{studioId}"
    path_params: [{name: studioId, var: studio_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: adminRoleArn, var: admin_role_arn}, {name: displayName, var: display_name}, {name: userRoleArn, var: user_role_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token, admin_role_arn: $admin_role_arn, display_name: $display_name, user_role_arn: $user_role_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a studio component resource.
#
# DELETE /2020-08-01/studios/{studioId}/studio-components/{studioComponentId}
# Returns: record<studioComponent: record<arn: string, configuration: record<activeDirectoryConfiguration: record, computeFarmConfiguration: record, licenseServiceConfiguration: record, sharedFileSystemConfiguration: record>, createdAt: string, createdBy: string, description: string, ec2SecurityGroupIds: list<string>, initializationScripts: list<record>, name: string, runtimeRoleArn: string, scriptParameters: list<record>, secureInitializationRoleArn: string, state: string, statusCode: string, statusMessage: string, studioComponentId: string, subtype: string, tags: record, type: string, updatedAt: string, updatedBy: string>>
# operationId: DeleteStudioComponent
export def "delete-studio-component" [
  studio_id: string
  studio_component_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2020-08-01/studios/{studioId}/studio-components/{studioComponentId}"
    path_params: [{name: studioId, var: studio_id}, {name: studioComponentId, var: studio_component_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, studio_component_id: $studio_component_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a studio component resource.
#
# GET /2020-08-01/studios/{studioId}/studio-components/{studioComponentId}
# Returns: record<studioComponent: record<arn: string, configuration: record<activeDirectoryConfiguration: record, computeFarmConfiguration: record, licenseServiceConfiguration: record, sharedFileSystemConfiguration: record>, createdAt: string, createdBy: string, description: string, ec2SecurityGroupIds: list<string>, initializationScripts: list<record>, name: string, runtimeRoleArn: string, scriptParameters: list<record>, secureInitializationRoleArn: string, state: string, statusCode: string, statusMessage: string, studioComponentId: string, subtype: string, tags: record, type: string, updatedAt: string, updatedBy: string>>
# operationId: GetStudioComponent
export def "get-studio-component" [
  studio_id: string
  studio_component_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/studio-components/{studioComponentId}"
    path_params: [{name: studioId, var: studio_id}, {name: studioComponentId, var: studio_component_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, studio_component_id: $studio_component_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a studio component resource.
#
# PATCH /2020-08-01/studios/{studioId}/studio-components/{studioComponentId}
# Returns: record<studioComponent: record<arn: string, configuration: record<activeDirectoryConfiguration: record, computeFarmConfiguration: record, licenseServiceConfiguration: record, sharedFileSystemConfiguration: record>, createdAt: string, createdBy: string, description: string, ec2SecurityGroupIds: list<string>, initializationScripts: list<record>, name: string, runtimeRoleArn: string, scriptParameters: list<record>, secureInitializationRoleArn: string, state: string, statusCode: string, statusMessage: string, studioComponentId: string, subtype: string, tags: record, type: string, updatedAt: string, updatedBy: string>>
# operationId: UpdateStudioComponent
export def "update-studio-component" [
  studio_id: string
  studio_component_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --configuration: record # The configuration of the studio component, based on component type. — shape: {activeDirectoryConfiguration?: record, computeFarmConfiguration?: record, licenseServiceConfiguration?: record, sharedFileSystemConfiguration?: record}
  --description: string # The description. (format: password)
  --ec2-security-group-ids: list<string> # The EC2 security groups that control access to the studio component.
  --initialization-scripts: list # Initialization scripts for studio components. — item shape: {launchProfileProtocolVersion?: string, platform?: "LINUX"|"WINDOWS", runContext?: "SYSTEM_INITIALIZATION"|"USER_INITIALIZATION", script?: string}
  --name: string # The name for the studio component. (format: password)
  --runtime-role-arn: string # An IAM role attached to a Studio Component that gives the studio component access to Amazon Web Services resources at anytime while the instance is running.
  --script-parameters: list # Parameters for the studio component scripts. — item shape: {key?: string, value?: string}
  --secure-initialization-role-arn: string # An IAM role attached to Studio Component when the system initialization script runs which give the studio component access to Amazon Web Services resources when the system initialization script runs.
  --subtype: string@subtype-completer # The specific subtype of a studio component.
  --type: string@type-completer # The type of the studio component.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/2020-08-01/studios/{studioId}/studio-components/{studioComponentId}"
    path_params: [{name: studioId, var: studio_id}, {name: studioComponentId, var: studio_component_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: configuration, var: configuration}, {name: description, var: description}, {name: ec2SecurityGroupIds, var: ec2_security_group_ids}, {name: initializationScripts, var: initialization_scripts}, {name: name, var: name}, {name: runtimeRoleArn, var: runtime_role_arn}, {name: scriptParameters, var: script_parameters}, {name: secureInitializationRoleArn, var: secure_initialization_role_arn}, {name: subtype, var: subtype}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, studio_component_id: $studio_component_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token, configuration: $configuration, description: $description, ec2_security_group_ids: $ec2_security_group_ids, initialization_scripts: $initialization_scripts, name: $name, runtime_role_arn: $runtime_role_arn, script_parameters: $script_parameters, secure_initialization_role_arn: $secure_initialization_role_arn, subtype: $subtype, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user from studio membership.
#
# DELETE /2020-08-01/studios/{studioId}/membership/{principalId}
# Returns: record
# operationId: DeleteStudioMember
export def "delete-studio-member" [
  studio_id: string
  principal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2020-08-01/studios/{studioId}/membership/{principalId}"
    path_params: [{name: studioId, var: studio_id}, {name: principalId, var: principal_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, principal_id: $principal_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user's membership in a studio.
#
# GET /2020-08-01/studios/{studioId}/membership/{principalId}
# Returns: record<member: record<identityStoreId: string, persona: string, principalId: string, sid: string>>
# operationId: GetStudioMember
export def "get-studio-member" [
  studio_id: string
  principal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/membership/{principalId}"
    path_params: [{name: studioId, var: studio_id}, {name: principalId, var: principal_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, principal_id: $principal_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get EULA.
#
# GET /2020-08-01/eulas/{eulaId}
# Returns: record<eula: record<content: string, createdAt: string, eulaId: string, name: string, updatedAt: string>>
# operationId: GetEula
export def "get-eula" [
  eula_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/eulas/{eulaId}"
    path_params: [{name: eulaId, var: eula_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    eula_id: $eula_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Launch profile details include the launch profile resource and summary information of resources that are used by, or available to, the launch profile. This includes the name and description of all studio components used by the launch profiles, and the name and description of streaming images that can be used with this launch profile.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/details
# Returns: record<launchProfile: record<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list<string>, launchProfileId: string, launchProfileProtocolVersions: list<string>, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record<automaticTerminationMode: string, clipboardMode: string, ec2InstanceTypes: list, maxSessionLengthInMinutes: int, maxStoppedSessionLengthInMinutes: int, sessionBackup: record, sessionPersistenceMode: string, sessionStorage: record, streamingImageIds: list, volumeConfiguration: record>, studioComponentIds: list<string>, tags: record, updatedAt: string, updatedBy: string, validationResults: list<record>>, streamingImages: table<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record, eulaIds: list, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>, studioComponentSummaries: table<createdAt: string, createdBy: string, description: string, name: string, studioComponentId: string, subtype: string, type: string, updatedAt: string, updatedBy: string>>
# operationId: GetLaunchProfileDetails
export def "get-launch-profile-details" [
  studio_id: string
  launch_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/details"
    path_params: [{name: studioId, var: studio_id}, {name: launchProfileId, var: launch_profile_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, launch_profile_id: $launch_profile_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a launch profile initialization.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/init
# Returns: record<launchProfileInitialization: record<activeDirectory: record<computerAttributes: list, directoryId: string, directoryName: string, dnsIpAddresses: list, organizationalUnitDistinguishedName: string, studioComponentId: string, studioComponentName: string>, ec2SecurityGroupIds: list<string>, launchProfileId: string, launchProfileProtocolVersion: string, launchPurpose: string, name: string, platform: string, systemInitializationScripts: list<record>, userInitializationScripts: list<record>>>
# operationId: GetLaunchProfileInitialization
export def "get-launch-profile-initialization" [
  studio_id: string
  launch_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --launch-profile-protocol-versions: list<string> # The launch profile protocol versions supported by the client. (required)
  --launch-purpose: string # The launch purpose. (required)
  --platform: string # The platform where this Launch Profile will be used, either Windows or Linux. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/init"
    path_params: [{name: studioId, var: studio_id}, {name: launchProfileId, var: launch_profile_id}]
    query: [{name: launchProfileProtocolVersions, var: launch_profile_protocol_versions, style: multi, required: true}, {name: launchPurpose, var: launch_purpose, required: true}, {name: platform, var: platform, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, launch_profile_id: $launch_profile_id, launch_profile_protocol_versions: $launch_profile_protocol_versions, launch_purpose: $launch_purpose, platform: $platform, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets StreamingSessionBackup resource. Invoke this operation to poll for a streaming session backup while stopping a streaming session.
#
# GET /2020-08-01/studios/{studioId}/streaming-session-backups/{backupId}
# Returns: record<streamingSessionBackup: record<arn: string, backupId: string, createdAt: string, launchProfileId: string, ownedBy: string, sessionId: string, state: string, statusCode: string, statusMessage: string, tags: record>>
# operationId: GetStreamingSessionBackup
export def "get-streaming-session-backup" [
  studio_id: string
  backup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/streaming-session-backups/{backupId}"
    path_params: [{name: studioId, var: studio_id}, {name: backupId, var: backup_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, backup_id: $backup_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a StreamingSessionStream for a streaming session. Invoke this operation to poll the resource after invoking CreateStreamingSessionStream. After the StreamingSessionStream changes to the READY state, the url property will contain a stream to be used with the DCV streaming client.
#
# GET /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}/streams/{streamId}
# Returns: record<stream: record<createdAt: string, createdBy: string, expiresAt: string, ownedBy: string, state: string, statusCode: string, streamId: string, url: string>>
# operationId: GetStreamingSessionStream
export def "get-streaming-session-stream" [
  studio_id: string
  session_id: string
  stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}/streams/{streamId}"
    path_params: [{name: studioId, var: studio_id}, {name: sessionId, var: session_id}, {name: streamId, var: stream_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, session_id: $session_id, stream_id: $stream_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List EULAs.
#
# GET /2020-08-01/eulas
# Returns: record<eulas: table<content: string, createdAt: string, eulaId: string, name: string, updatedAt: string>, nextToken: string>
# operationId: ListEulas
export def "list-eulas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --eula-ids: list<string> # The list of EULA IDs that should be returned
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/eulas"
    query: [{name: eulaIds, var: eula_ids, style: multi}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    eula_ids: $eula_ids, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all users in a given launch profile membership.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership
# Returns: record<members: table<identityStoreId: string, persona: string, principalId: string, sid: string>, nextToken: string>
# operationId: ListLaunchProfileMembers
export def "list-launch-profile-members" [
  studio_id: string
  launch_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The max number of results to return in the response.
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership"
    path_params: [{name: studioId, var: studio_id}, {name: launchProfileId, var: launch_profile_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, launch_profile_id: $launch_profile_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add/update users with given persona to launch profile membership.
#
# POST /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership
# Returns: record
# operationId: PutLaunchProfileMembers
export def "put-launch-profile-members" [
  studio_id: string
  launch_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  identity_store_id: string # The ID of the identity store.
  members: list # A list of members. — item shape: {persona: "USER", principalId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership"
    path_params: [{name: studioId, var: studio_id}, {name: launchProfileId, var: launch_profile_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: identityStoreId, var: identity_store_id}, {name: members, var: members}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, launch_profile_id: $launch_profile_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token, identity_store_id: $identity_store_id, members: $members
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the backups of a streaming session in a studio.
#
# GET /2020-08-01/studios/{studioId}/streaming-session-backups
# Returns: record<nextToken: string, streamingSessionBackups: table<arn: string, backupId: string, createdAt: string, launchProfileId: string, ownedBy: string, sessionId: string, state: string, statusCode: string, statusMessage: string, tags: record>>
# operationId: ListStreamingSessionBackups
export def "list-streaming-session-backups" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --owned-by: string # The user ID of the user that owns the streaming session.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/streaming-session-backups"
    path_params: [{name: studioId, var: studio_id}]
    query: [{name: nextToken, var: next_token}, {name: ownedBy, var: owned_by}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, next_token: $next_token, owned_by: $owned_by, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all users in a given studio membership. ListStudioMembers only returns admin members.
#
# GET /2020-08-01/studios/{studioId}/membership
# Returns: record<members: table<identityStoreId: string, persona: string, principalId: string, sid: string>, nextToken: string>
# operationId: ListStudioMembers
export def "list-studio-members" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The max number of results to return in the response.
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/studios/{studioId}/membership"
    path_params: [{name: studioId, var: studio_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add/update users with given persona to studio membership.
#
# POST /2020-08-01/studios/{studioId}/membership
# Returns: record
# operationId: PutStudioMembers
export def "put-studio-members" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  identity_store_id: string # The ID of the identity store.
  members: list # A list of members. — item shape: {persona: "ADMINISTRATOR", principalId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-08-01/studios/{studioId}/membership"
    path_params: [{name: studioId, var: studio_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: identityStoreId, var: identity_store_id}, {name: members, var: members}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token, identity_store_id: $identity_store_id, members: $members
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the tags for a resource, given its Amazon Resource Names (ARN). This operation supports ARNs for all resource types in Nimble Studio that support tags, including studio, studio component, launch profile, streaming image, and streaming session. All resources that can be tagged will contain an ARN property, so you do not have to create this ARN yourself.
#
# GET /2020-08-01/tags/{resourceArn}
# Returns: record<tags: record>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-08-01/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates tags for a resource, given its ARN.
#
# POST /2020-08-01/tags/{resourceArn}
# Returns: record
# operationId: TagResource
export def "tag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --tags: record # A collection of labels, in the form of key-value pairs, that apply to this resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-08-01/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transitions sessions from the STOPPED state into the READY state. The START_IN_PROGRESS state is the intermediate state between the STOPPED and READY states.
#
# POST /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}/start
# Returns: record<session: record<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record<iops: int, size: int, throughput: int>, volumeRetentionMode: string>>
# operationId: StartStreamingSession
export def "start-streaming-session" [
  studio_id: string
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --backup-id: string # The ID of the backup.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}/start"
    path_params: [{name: studioId, var: studio_id}, {name: sessionId, var: session_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: backupId, var: backup_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, session_id: $session_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token, backup_id: $backup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Repairs the IAM Identity Center configuration for a given studio. If the studio has a valid IAM Identity Center configuration currently associated with it, this operation will fail with a validation error. If the studio does not have a valid IAM Identity Center configuration currently associated with it, then a new IAM Identity Center application is created for the studio and the studio is changed to the READY state. After the IAM Identity Center application is repaired, you must use the Amazon Nimble Studio console to add administrators and users to your studio.
#
# PUT /2020-08-01/studios/{studioId}/sso-configuration
# Returns: record<studio: record<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record<keyArn: string, keyType: string>, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>
# operationId: StartStudioSSOConfigurationRepair
export def "start-studio-sso-configuration-repair" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/2020-08-01/studios/{studioId}/sso-configuration"
    path_params: [{name: studioId, var: studio_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transitions sessions from the READY state into the STOPPED state. The STOP_IN_PROGRESS state is the intermediate state between the READY and STOPPED states.
#
# POST /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}/stop
# Returns: record<session: record<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record<iops: int, size: int, throughput: int>, volumeRetentionMode: string>>
# operationId: StopStreamingSession
export def "stop-streaming-session" [
  studio_id: string
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --volume-retention-mode: string@volume-retention-mode-completer # Adds additional instructions to a streaming session stop action to either retain the EBS volumes or delete the EBS volumes.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}/stop"
    path_params: [{name: studioId, var: studio_id}, {name: sessionId, var: session_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Client-Token, var: x_amz_client_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: volumeRetentionMode, var: volume_retention_mode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    studio_id: $studio_id, session_id: $session_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_client_token: $x_amz_client_token, volume_retention_mode: $volume_retention_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the tags for a resource.
#
# DELETE /2020-08-01/tags/{resourceArn}
# Returns: record
# operationId: UntagResource
export def "untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list<string> # One or more tag keys. Specify only the tag keys, not the tag values. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2020-08-01/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    query: [{name: tagKeys, var: tag_keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_arn: $resource_arn, tag_keys: $tag_keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
