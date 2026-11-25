# Auto-generated client for Amazon Chime v2018-05-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/chime/2018-05-01/openapi.json
# Auth: --token flag or $env.AMAZON_CHIME_TOKEN

const CLIENT = {
  base_url: "http://service.chime.aws.amazon.com"
  token_env_var: "AMAZON_CHIME_TOKEN"
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

def base-url-completer [] { ["http://service.chime.aws.amazon.com" "https://service.chime.aws.amazon.com" "http://chime.cn-north-1.amazonaws.com.cn" "http://chime.cn-northwest-1.amazonaws.com.cn" "https://chime.cn-north-1.amazonaws.com.cn" "https://chime.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def operation-completer [] { ["associate-phone-number"] }
def operation-completer-1 [] { ["associate-phone-numbers"] }
def operation-completer-2 [] { ["associate-signin-delegate-groups"] }
def operation-completer-3 [] { ["batch-create"] }
def type-completer [] { ["DEFAULT" "HIDDEN"] }
def operation-completer-4 [] { ["batch-delete"] }
def operation-completer-5 [] { ["suspend"] }
def operation-completer-6 [] { ["unsuspend"] }
def operation-completer-7 [] { ["batch-update"] }
def user-type-completer [] { ["PrivateUser" "SharedDevice"] }
def mode-completer [] { ["RESTRICTED" "UNRESTRICTED"] }
def privacy-completer [] { ["PRIVATE" "PUBLIC"] }
def source-type-completer [] { ["ChimeSdkMeeting"] }
def sink-type-completer [] { ["S3Bucket"] }
def operation-completer-8 [] { ["create-attendees"] }
def product-type-completer [] { ["BusinessCalling" "SipMediaApplicationDialIn" "VoiceConnector"] }
def number-selection-behavior-completer [] { ["AvoidSticky" "PreferSticky"] }
def geo-match-level-completer [] { ["AreaCode" "Country"] }
def status-completer [] { ["Closed" "InProgress" "Open"] }
def role-completer [] { ["Administrator" "Member"] }
def trigger-type-completer [] { ["RequestUriHostname" "ToPhoneNumber"] }
def operation-completer-9 [] { ["create"] }
def aws-region-completer [] { ["us-east-1" "us-west-2"] }
def default-license-completer [] { ["Basic" "Plus" "Pro" "ProTrial"] }
def operation-completer-10 [] { ["delete"] }
def scope-completer [] { ["app-instance-user-membership"] }
def scope-completer-1 [] { ["app-instance-user-moderated-channel"] }
def operation-completer-11 [] { ["disassociate-phone-number"] }
def operation-completer-12 [] { ["disassociate-phone-numbers"] }
def operation-completer-13 [] { ["disassociate-signin-delegate-groups"] }
def license-type-completer [] { ["Basic" "Plus" "Pro" "ProTrial"] }
def operation-completer-14 [] { ["add"] }
def scope-completer-2 [] { ["app-instance-user-memberships"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }
def type-completer-1 [] { ["CONTROL" "STANDARD"] }
def persistence-completer [] { ["NON_PERSISTENT" "PERSISTENT"] }
def scope-completer-3 [] { ["app-instance-user-moderated-channels"] }
def status-completer-1 [] { ["AcquireFailed" "AcquireInProgress" "Assigned" "DeleteFailed" "DeleteInProgress" "ReleaseFailed" "ReleaseInProgress" "Unassigned"] }
def filter-name-completer [] { ["AccountId" "SipRuleId" "UserId" "VoiceConnectorGroupId" "VoiceConnectorId"] }
def operation-completer-15 [] { ["logout"] }
def operation-completer-16 [] { ["put"] }
def operation-completer-17 [] { ["redact"] }
def operation-completer-18 [] { ["regenerate-security-token"] }
def operation-completer-19 [] { ["reset-personal-pin"] }
def operation-completer-20 [] { ["restore"] }
def phone-number-type-completer [] { ["Local" "TollFree"] }
def type-completer-2 [] { ["phone-numbers"] }
def operation-completer-21 [] { ["start"] }
def operation-completer-22 [] { ["stop"] }
def operation-completer-23 [] { ["tag-resource"] }
def operation-completer-24 [] { ["untag-resource"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    associate-phone-number-with-user: "record"
    associate-phone-numbers-with-voice-connector: "record<PhoneNumberErrors: table<PhoneNumberId: string, ErrorCode: string, ErrorMessage: string>>"
    associate-phone-numbers-with-voice-connector-group: "record<PhoneNumberErrors: table<PhoneNumberId: string, ErrorCode: string, ErrorMessage: string>>"
    associate-signin-delegate-groups-with-account: "record"
    batch-create-attendee: "record<Attendees: table<ExternalUserId: string, AttendeeId: string, JoinToken: string>, Errors: table<ExternalUserId: string, ErrorCode: string, ErrorMessage: string>>"
    batch-create-channel-membership: "record<BatchChannelMemberships: record<InvitedBy: record<Arn: string, Name: string>, Type: string, Members: list<record>, ChannelArn: string>, Errors: table<MemberArn: string, ErrorCode: string, ErrorMessage: string>>"
    batch-create-room-membership: "record<Errors: table<MemberId: string, ErrorCode: string, ErrorMessage: string>>"
    batch-delete-phone-number: "record<PhoneNumberErrors: table<PhoneNumberId: string, ErrorCode: string, ErrorMessage: string>>"
    batch-suspend-user: "record<UserErrors: table<UserId: string, ErrorCode: string, ErrorMessage: string>>"
    batch-unsuspend-user: "record<UserErrors: table<UserId: string, ErrorCode: string, ErrorMessage: string>>"
    batch-update-phone-number: "record<PhoneNumberErrors: table<PhoneNumberId: string, ErrorCode: string, ErrorMessage: string>>"
    batch-update-user: "record<UserErrors: table<UserId: string, ErrorCode: string, ErrorMessage: string>>"
    list-users: "record<Users: table<UserId: string, AccountId: string, PrimaryEmail: string, PrimaryProvisionedNumber: string, DisplayName: string, LicenseType: string, UserType: string, UserRegistrationStatus: string, UserInvitationStatus: string, RegisteredOn: string, InvitedOn: string, AlexaForBusinessMetadata: record, PersonalPIN: string>, NextToken: string>"
    create-account: "record<Account: record<AwsAccountId: string, AccountId: string, Name: string, AccountType: string, CreatedTimestamp: string, DefaultLicense: string, SupportedLicenses: list<string>, AccountStatus: string, SigninDelegateGroups: list<record>>>"
    list-accounts: "record<Accounts: table<AwsAccountId: string, AccountId: string, Name: string, AccountType: string, CreatedTimestamp: string, DefaultLicense: string, SupportedLicenses: list, AccountStatus: string, SigninDelegateGroups: list>, NextToken: string>"
    create-app-instance: "record<AppInstanceArn: string>"
    list-app-instances: "record<AppInstances: table<AppInstanceArn: string, Name: string, Metadata: string>, NextToken: string>"
    create-app-instance-admin: "record<AppInstanceAdmin: record<Arn: string, Name: string>, AppInstanceArn: string>"
    list-app-instance-admins: "record<AppInstanceArn: string, AppInstanceAdmins: table<Admin: record>, NextToken: string>"
    create-app-instance-user: "record<AppInstanceUserArn: string>"
    create-attendee: "record<Attendee: record<ExternalUserId: string, AttendeeId: string, JoinToken: string>>"
    list-attendees: "record<Attendees: table<ExternalUserId: string, AttendeeId: string, JoinToken: string>, NextToken: string>"
    create-bot: "record<Bot: record<BotId: string, UserId: string, DisplayName: string, BotType: string, Disabled: bool, CreatedTimestamp: string, UpdatedTimestamp: string, BotEmail: string, SecurityToken: string>>"
    list-bots: "record<Bots: table<BotId: string, UserId: string, DisplayName: string, BotType: string, Disabled: bool, CreatedTimestamp: string, UpdatedTimestamp: string, BotEmail: string, SecurityToken: string>, NextToken: string>"
    create-channel: "record<ChannelArn: string>"
    create-channel-ban: "record<ChannelArn: string, Member: record<Arn: string, Name: string>>"
    list-channel-bans: "record<ChannelArn: string, NextToken: string, ChannelBans: table<Member: record>>"
    create-channel-membership: "record<ChannelArn: string, Member: record<Arn: string, Name: string>>"
    list-channel-memberships: "record<ChannelArn: string, ChannelMemberships: table<Member: record>, NextToken: string>"
    create-channel-moderator: "record<ChannelArn: string, ChannelModerator: record<Arn: string, Name: string>>"
    list-channel-moderators: "record<ChannelArn: string, NextToken: string, ChannelModerators: table<Moderator: record>>"
    create-media-capture-pipeline: "record<MediaCapturePipeline: record<MediaPipelineId: string, SourceType: string, SourceArn: string, Status: string, SinkType: string, SinkArn: string, CreatedTimestamp: string, UpdatedTimestamp: string, ChimeSdkMeetingConfiguration: record<SourceConfiguration: record, ArtifactsConfiguration: record>>>"
    list-media-capture-pipelines: "record<MediaCapturePipelines: table<MediaPipelineId: string, SourceType: string, SourceArn: string, Status: string, SinkType: string, SinkArn: string, CreatedTimestamp: string, UpdatedTimestamp: string, ChimeSdkMeetingConfiguration: record>, NextToken: string>"
    create-meeting: "record<Meeting: record<MeetingId: string, ExternalMeetingId: string, MediaPlacement: record<AudioHostUrl: string, AudioFallbackUrl: string, ScreenDataUrl: string, ScreenSharingUrl: string, ScreenViewingUrl: string, SignalingUrl: string, TurnControlUrl: string, EventIngestionUrl: string>, MediaRegion: string>>"
    list-meetings: "record<Meetings: table<MeetingId: string, ExternalMeetingId: string, MediaPlacement: record, MediaRegion: string>, NextToken: string>"
    create-meeting-dial-out: "record<TransactionId: string>"
    create-meeting-with-attendees: "record<Meeting: record<MeetingId: string, ExternalMeetingId: string, MediaPlacement: record<AudioHostUrl: string, AudioFallbackUrl: string, ScreenDataUrl: string, ScreenSharingUrl: string, ScreenViewingUrl: string, SignalingUrl: string, TurnControlUrl: string, EventIngestionUrl: string>, MediaRegion: string>, Attendees: table<ExternalUserId: string, AttendeeId: string, JoinToken: string>, Errors: table<ExternalUserId: string, ErrorCode: string, ErrorMessage: string>>"
    create-phone-number-order: "record<PhoneNumberOrder: record<PhoneNumberOrderId: string, ProductType: string, Status: string, OrderedPhoneNumbers: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string>>"
    list-phone-number-orders: "record<PhoneNumberOrders: table<PhoneNumberOrderId: string, ProductType: string, Status: string, OrderedPhoneNumbers: list, CreatedTimestamp: string, UpdatedTimestamp: string>, NextToken: string>"
    create-proxy-session: "record<ProxySession: record<VoiceConnectorId: string, ProxySessionId: string, Name: string, Status: string, ExpiryMinutes: int, Capabilities: list<string>, CreatedTimestamp: string, UpdatedTimestamp: string, EndedTimestamp: string, Participants: list<record>, NumberSelectionBehavior: string, GeoMatchLevel: string, GeoMatchParams: record<Country: string, AreaCode: string>>>"
    list-proxy-sessions: "record<ProxySessions: table<VoiceConnectorId: string, ProxySessionId: string, Name: string, Status: string, ExpiryMinutes: int, Capabilities: list, CreatedTimestamp: string, UpdatedTimestamp: string, EndedTimestamp: string, Participants: list, NumberSelectionBehavior: string, GeoMatchLevel: string, GeoMatchParams: record>, NextToken: string>"
    create-room: "record<Room: record<RoomId: string, Name: string, AccountId: string, CreatedBy: string, CreatedTimestamp: string, UpdatedTimestamp: string>>"
    list-rooms: "record<Rooms: table<RoomId: string, Name: string, AccountId: string, CreatedBy: string, CreatedTimestamp: string, UpdatedTimestamp: string>, NextToken: string>"
    create-room-membership: "record<RoomMembership: record<RoomId: string, Member: record<MemberId: string, MemberType: string, Email: string, FullName: string, AccountId: string>, Role: string, InvitedBy: string, UpdatedTimestamp: string>>"
    list-room-memberships: "record<RoomMemberships: table<RoomId: string, Member: record, Role: string, InvitedBy: string, UpdatedTimestamp: string>, NextToken: string>"
    create-sip-media-application: "record<SipMediaApplication: record<SipMediaApplicationId: string, AwsRegion: string, Name: string, Endpoints: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string>>"
    list-sip-media-applications: "record<SipMediaApplications: table<SipMediaApplicationId: string, AwsRegion: string, Name: string, Endpoints: list, CreatedTimestamp: string, UpdatedTimestamp: string>, NextToken: string>"
    create-sip-media-application-call: "record<SipMediaApplicationCall: record<TransactionId: string>>"
    create-sip-rule: "record<SipRule: record<SipRuleId: string, Name: string, Disabled: bool, TriggerType: string, TriggerValue: string, TargetApplications: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string>>"
    list-sip-rules: "record<SipRules: table<SipRuleId: string, Name: string, Disabled: bool, TriggerType: string, TriggerValue: string, TargetApplications: list, CreatedTimestamp: string, UpdatedTimestamp: string>, NextToken: string>"
    create-user: "record<User: record<UserId: string, AccountId: string, PrimaryEmail: string, PrimaryProvisionedNumber: string, DisplayName: string, LicenseType: string, UserType: string, UserRegistrationStatus: string, UserInvitationStatus: string, RegisteredOn: string, InvitedOn: string, AlexaForBusinessMetadata: record<IsAlexaForBusinessEnabled: bool, AlexaForBusinessRoomArn: string>, PersonalPIN: string>>"
    create-voice-connector: "record<VoiceConnector: record<VoiceConnectorId: string, AwsRegion: string, Name: string, OutboundHostName: string, RequireEncryption: bool, CreatedTimestamp: string, UpdatedTimestamp: string, VoiceConnectorArn: string>>"
    list-voice-connectors: "record<VoiceConnectors: table<VoiceConnectorId: string, AwsRegion: string, Name: string, OutboundHostName: string, RequireEncryption: bool, CreatedTimestamp: string, UpdatedTimestamp: string, VoiceConnectorArn: string>, NextToken: string>"
    create-voice-connector-group: "record<VoiceConnectorGroup: record<VoiceConnectorGroupId: string, Name: string, VoiceConnectorItems: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string, VoiceConnectorGroupArn: string>>"
    list-voice-connector-groups: "record<VoiceConnectorGroups: table<VoiceConnectorGroupId: string, Name: string, VoiceConnectorItems: list, CreatedTimestamp: string, UpdatedTimestamp: string, VoiceConnectorGroupArn: string>, NextToken: string>"
    delete-account: "record"
    get-account: "record<Account: record<AwsAccountId: string, AccountId: string, Name: string, AccountType: string, CreatedTimestamp: string, DefaultLicense: string, SupportedLicenses: list<string>, AccountStatus: string, SigninDelegateGroups: list<record>>>"
    update-account: "record<Account: record<AwsAccountId: string, AccountId: string, Name: string, AccountType: string, CreatedTimestamp: string, DefaultLicense: string, SupportedLicenses: list<string>, AccountStatus: string, SigninDelegateGroups: list<record>>>"
    describe-app-instance: "record<AppInstance: record<AppInstanceArn: string, Name: string, Metadata: string, CreatedTimestamp: string, LastUpdatedTimestamp: string>>"
    update-app-instance: "record<AppInstanceArn: string>"
    describe-app-instance-admin: "record<AppInstanceAdmin: record<Admin: record<Arn: string, Name: string>, AppInstanceArn: string, CreatedTimestamp: string>>"
    get-app-instance-streaming-configurations: "record<AppInstanceStreamingConfigurations: table<AppInstanceDataType: string, ResourceArn: string>>"
    put-app-instance-streaming-configurations: "record<AppInstanceStreamingConfigurations: table<AppInstanceDataType: string, ResourceArn: string>>"
    describe-app-instance-user: "record<AppInstanceUser: record<AppInstanceUserArn: string, Name: string, CreatedTimestamp: string, Metadata: string, LastUpdatedTimestamp: string>>"
    update-app-instance-user: "record<AppInstanceUserArn: string>"
    get-attendee: "record<Attendee: record<ExternalUserId: string, AttendeeId: string, JoinToken: string>>"
    describe-channel: "record<Channel: record<Name: string, ChannelArn: string, Mode: string, Privacy: string, Metadata: string, CreatedBy: record<Arn: string, Name: string>, CreatedTimestamp: string, LastMessageTimestamp: string, LastUpdatedTimestamp: string>>"
    update-channel: "record<ChannelArn: string>"
    describe-channel-ban: "record<ChannelBan: record<Member: record<Arn: string, Name: string>, ChannelArn: string, CreatedTimestamp: string, CreatedBy: record<Arn: string, Name: string>>>"
    describe-channel-membership: "record<ChannelMembership: record<InvitedBy: record<Arn: string, Name: string>, Type: string, Member: record<Arn: string, Name: string>, ChannelArn: string, CreatedTimestamp: string, LastUpdatedTimestamp: string>>"
    get-channel-message: "record<ChannelMessage: record<ChannelArn: string, MessageId: string, Content: string, Metadata: string, Type: string, CreatedTimestamp: string, LastEditedTimestamp: string, LastUpdatedTimestamp: string, Sender: record<Arn: string, Name: string>, Redacted: bool, Persistence: string>>"
    update-channel-message: "record<ChannelArn: string, MessageId: string>"
    describe-channel-moderator: "record<ChannelModerator: record<Moderator: record<Arn: string, Name: string>, ChannelArn: string, CreatedTimestamp: string, CreatedBy: record<Arn: string, Name: string>>>"
    get-events-configuration: "record<EventsConfiguration: record<BotId: string, OutboundEventsHTTPSEndpoint: string, LambdaFunctionArn: string>>"
    put-events-configuration: "record<EventsConfiguration: record<BotId: string, OutboundEventsHTTPSEndpoint: string, LambdaFunctionArn: string>>"
    get-media-capture-pipeline: "record<MediaCapturePipeline: record<MediaPipelineId: string, SourceType: string, SourceArn: string, Status: string, SinkType: string, SinkArn: string, CreatedTimestamp: string, UpdatedTimestamp: string, ChimeSdkMeetingConfiguration: record<SourceConfiguration: record, ArtifactsConfiguration: record>>>"
    get-meeting: "record<Meeting: record<MeetingId: string, ExternalMeetingId: string, MediaPlacement: record<AudioHostUrl: string, AudioFallbackUrl: string, ScreenDataUrl: string, ScreenSharingUrl: string, ScreenViewingUrl: string, SignalingUrl: string, TurnControlUrl: string, EventIngestionUrl: string>, MediaRegion: string>>"
    get-phone-number: "record<PhoneNumber: record<PhoneNumberId: string, E164PhoneNumber: string, Country: string, Type: string, ProductType: string, Status: string, Capabilities: record<InboundCall: bool, OutboundCall: bool, InboundSMS: bool, OutboundSMS: bool, InboundMMS: bool, OutboundMMS: bool>, Associations: list<record>, CallingName: string, CallingNameStatus: string, CreatedTimestamp: string, UpdatedTimestamp: string, DeletionTimestamp: string>>"
    update-phone-number: "record<PhoneNumber: record<PhoneNumberId: string, E164PhoneNumber: string, Country: string, Type: string, ProductType: string, Status: string, Capabilities: record<InboundCall: bool, OutboundCall: bool, InboundSMS: bool, OutboundSMS: bool, InboundMMS: bool, OutboundMMS: bool>, Associations: list<record>, CallingName: string, CallingNameStatus: string, CreatedTimestamp: string, UpdatedTimestamp: string, DeletionTimestamp: string>>"
    get-proxy-session: "record<ProxySession: record<VoiceConnectorId: string, ProxySessionId: string, Name: string, Status: string, ExpiryMinutes: int, Capabilities: list<string>, CreatedTimestamp: string, UpdatedTimestamp: string, EndedTimestamp: string, Participants: list<record>, NumberSelectionBehavior: string, GeoMatchLevel: string, GeoMatchParams: record<Country: string, AreaCode: string>>>"
    update-proxy-session: "record<ProxySession: record<VoiceConnectorId: string, ProxySessionId: string, Name: string, Status: string, ExpiryMinutes: int, Capabilities: list<string>, CreatedTimestamp: string, UpdatedTimestamp: string, EndedTimestamp: string, Participants: list<record>, NumberSelectionBehavior: string, GeoMatchLevel: string, GeoMatchParams: record<Country: string, AreaCode: string>>>"
    get-room: "record<Room: record<RoomId: string, Name: string, AccountId: string, CreatedBy: string, CreatedTimestamp: string, UpdatedTimestamp: string>>"
    update-room: "record<Room: record<RoomId: string, Name: string, AccountId: string, CreatedBy: string, CreatedTimestamp: string, UpdatedTimestamp: string>>"
    update-room-membership: "record<RoomMembership: record<RoomId: string, Member: record<MemberId: string, MemberType: string, Email: string, FullName: string, AccountId: string>, Role: string, InvitedBy: string, UpdatedTimestamp: string>>"
    get-sip-media-application: "record<SipMediaApplication: record<SipMediaApplicationId: string, AwsRegion: string, Name: string, Endpoints: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string>>"
    update-sip-media-application: "record<SipMediaApplication: record<SipMediaApplicationId: string, AwsRegion: string, Name: string, Endpoints: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string>>"
    get-sip-rule: "record<SipRule: record<SipRuleId: string, Name: string, Disabled: bool, TriggerType: string, TriggerValue: string, TargetApplications: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string>>"
    update-sip-rule: "record<SipRule: record<SipRuleId: string, Name: string, Disabled: bool, TriggerType: string, TriggerValue: string, TargetApplications: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string>>"
    get-voice-connector: "record<VoiceConnector: record<VoiceConnectorId: string, AwsRegion: string, Name: string, OutboundHostName: string, RequireEncryption: bool, CreatedTimestamp: string, UpdatedTimestamp: string, VoiceConnectorArn: string>>"
    update-voice-connector: "record<VoiceConnector: record<VoiceConnectorId: string, AwsRegion: string, Name: string, OutboundHostName: string, RequireEncryption: bool, CreatedTimestamp: string, UpdatedTimestamp: string, VoiceConnectorArn: string>>"
    get-voice-connector-emergency-calling-configuration: "record<EmergencyCallingConfiguration: record<DNIS: list<record>>>"
    put-voice-connector-emergency-calling-configuration: "record<EmergencyCallingConfiguration: record<DNIS: list<record>>>"
    get-voice-connector-group: "record<VoiceConnectorGroup: record<VoiceConnectorGroupId: string, Name: string, VoiceConnectorItems: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string, VoiceConnectorGroupArn: string>>"
    update-voice-connector-group: "record<VoiceConnectorGroup: record<VoiceConnectorGroupId: string, Name: string, VoiceConnectorItems: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string, VoiceConnectorGroupArn: string>>"
    get-voice-connector-origination: "record<Origination: record<Routes: list<record>, Disabled: bool>>"
    put-voice-connector-origination: "record<Origination: record<Routes: list<record>, Disabled: bool>>"
    get-voice-connector-proxy: "record<Proxy: record<DefaultSessionExpiryMinutes: int, Disabled: bool, FallBackPhoneNumber: string, PhoneNumberCountries: list<string>>>"
    put-voice-connector-proxy: "record<Proxy: record<DefaultSessionExpiryMinutes: int, Disabled: bool, FallBackPhoneNumber: string, PhoneNumberCountries: list<string>>>"
    get-voice-connector-streaming-configuration: "record<StreamingConfiguration: record<DataRetentionInHours: int, Disabled: bool, StreamingNotificationTargets: list<record>>>"
    put-voice-connector-streaming-configuration: "record<StreamingConfiguration: record<DataRetentionInHours: int, Disabled: bool, StreamingNotificationTargets: list<record>>>"
    get-voice-connector-termination: "record<Termination: record<CpsLimit: int, DefaultPhoneNumber: string, CallingRegions: list<string>, CidrAllowedList: list<string>, Disabled: bool>>"
    put-voice-connector-termination: "record<Termination: record<CpsLimit: int, DefaultPhoneNumber: string, CallingRegions: list<string>, CidrAllowedList: list<string>, Disabled: bool>>"
    describe-channel-membership-for-app-instance-user: "record<ChannelMembership: record<ChannelSummary: record<Name: string, ChannelArn: string, Mode: string, Privacy: string, Metadata: string, LastMessageTimestamp: string>, AppInstanceUserMembershipSummary: record<Type: string, ReadMarkerTimestamp: string>>>"
    describe-channel-moderated-by-app-instance-user: "record<Channel: record<ChannelSummary: record<Name: string, ChannelArn: string, Mode: string, Privacy: string, Metadata: string, LastMessageTimestamp: string>>>"
    disassociate-phone-number-from-user: "record"
    disassociate-phone-numbers-from-voice-connector: "record<PhoneNumberErrors: table<PhoneNumberId: string, ErrorCode: string, ErrorMessage: string>>"
    disassociate-phone-numbers-from-voice-connector-group: "record<PhoneNumberErrors: table<PhoneNumberId: string, ErrorCode: string, ErrorMessage: string>>"
    disassociate-signin-delegate-groups-from-account: "record"
    get-account-settings: "record<AccountSettings: record<DisableRemoteControl: bool, EnableDialOut: bool>>"
    update-account-settings: "record"
    get-app-instance-retention-settings: "record<AppInstanceRetentionSettings: record<ChannelRetentionSettings: record<RetentionDays: int>>, InitiateDeletionTimestamp: string>"
    put-app-instance-retention-settings: "record<AppInstanceRetentionSettings: record<ChannelRetentionSettings: record<RetentionDays: int>>, InitiateDeletionTimestamp: string>"
    get-bot: "record<Bot: record<BotId: string, UserId: string, DisplayName: string, BotType: string, Disabled: bool, CreatedTimestamp: string, UpdatedTimestamp: string, BotEmail: string, SecurityToken: string>>"
    update-bot: "record<Bot: record<BotId: string, UserId: string, DisplayName: string, BotType: string, Disabled: bool, CreatedTimestamp: string, UpdatedTimestamp: string, BotEmail: string, SecurityToken: string>>"
    get-global-settings: "record<BusinessCalling: record<CdrBucket: string>, VoiceConnector: record<CdrBucket: string>>"
    get-messaging-session-endpoint: "record<Endpoint: record<Url: string>>"
    get-phone-number-order: "record<PhoneNumberOrder: record<PhoneNumberOrderId: string, ProductType: string, Status: string, OrderedPhoneNumbers: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string>>"
    get-phone-number-settings: "record<CallingName: string, CallingNameUpdatedTimestamp: string>"
    get-retention-settings: "record<RetentionSettings: record<RoomRetentionSettings: record<RetentionDays: int>, ConversationRetentionSettings: record<RetentionDays: int>>, InitiateDeletionTimestamp: string>"
    put-retention-settings: "record<RetentionSettings: record<RoomRetentionSettings: record<RetentionDays: int>, ConversationRetentionSettings: record<RetentionDays: int>>, InitiateDeletionTimestamp: string>"
    get-sip-media-application-logging-configuration: "record<SipMediaApplicationLoggingConfiguration: record<EnableSipMediaApplicationMessageLogs: bool>>"
    put-sip-media-application-logging-configuration: "record<SipMediaApplicationLoggingConfiguration: record<EnableSipMediaApplicationMessageLogs: bool>>"
    get-user: "record<User: record<UserId: string, AccountId: string, PrimaryEmail: string, PrimaryProvisionedNumber: string, DisplayName: string, LicenseType: string, UserType: string, UserRegistrationStatus: string, UserInvitationStatus: string, RegisteredOn: string, InvitedOn: string, AlexaForBusinessMetadata: record<IsAlexaForBusinessEnabled: bool, AlexaForBusinessRoomArn: string>, PersonalPIN: string>>"
    update-user: "record<User: record<UserId: string, AccountId: string, PrimaryEmail: string, PrimaryProvisionedNumber: string, DisplayName: string, LicenseType: string, UserType: string, UserRegistrationStatus: string, UserInvitationStatus: string, RegisteredOn: string, InvitedOn: string, AlexaForBusinessMetadata: record<IsAlexaForBusinessEnabled: bool, AlexaForBusinessRoomArn: string>, PersonalPIN: string>>"
    get-user-settings: "record<UserSettings: record<Telephony: record<InboundCalling: bool, OutboundCalling: bool, SMS: bool>>>"
    get-voice-connector-logging-configuration: "record<LoggingConfiguration: record<EnableSIPLogs: bool, EnableMediaMetricLogs: bool>>"
    put-voice-connector-logging-configuration: "record<LoggingConfiguration: record<EnableSIPLogs: bool, EnableMediaMetricLogs: bool>>"
    get-voice-connector-termination-health: "record<TerminationHealth: record<Timestamp: string, Source: string>>"
    invite-users: "record<Invites: table<InviteId: string, Status: string, EmailAddress: string, EmailStatus: string>>"
    list-app-instance-users: "record<AppInstanceArn: string, AppInstanceUsers: table<AppInstanceUserArn: string, Name: string, Metadata: string>, NextToken: string>"
    list-attendee-tags: "record<Tags: table<Key: string, Value: string>>"
    list-channel-memberships-for-app-instance-user: "record<ChannelMemberships: table<ChannelSummary: record, AppInstanceUserMembershipSummary: record>, NextToken: string>"
    list-channel-messages: "record<ChannelArn: string, NextToken: string, ChannelMessages: table<MessageId: string, Content: string, Metadata: string, Type: string, CreatedTimestamp: string, LastUpdatedTimestamp: string, LastEditedTimestamp: string, Sender: record, Redacted: bool>>"
    send-channel-message: "record<ChannelArn: string, MessageId: string>"
    list-channels: "record<Channels: table<Name: string, ChannelArn: string, Mode: string, Privacy: string, Metadata: string, LastMessageTimestamp: string>, NextToken: string>"
    list-channels-moderated-by-app-instance-user: "record<Channels: table<ChannelSummary: record>, NextToken: string>"
    list-meeting-tags: "record<Tags: table<Key: string, Value: string>>"
    list-phone-numbers: "record<PhoneNumbers: table<PhoneNumberId: string, E164PhoneNumber: string, Country: string, Type: string, ProductType: string, Status: string, Capabilities: record, Associations: list, CallingName: string, CallingNameStatus: string, CreatedTimestamp: string, UpdatedTimestamp: string, DeletionTimestamp: string>, NextToken: string>"
    list-supported-phone-number-countries: "record<PhoneNumberCountries: table<CountryCode: string, SupportedPhoneNumberTypes: list>>"
    list-tags-for-resource: "record<Tags: table<Key: string, Value: string>>"
    list-voice-connector-termination-credentials: "record<Usernames: list<string>>"
    logout-user: "record"
    redact-channel-message: "record<ChannelArn: string, MessageId: string>"
    redact-conversation-message: "record"
    redact-room-message: "record"
    regenerate-security-token: "record<Bot: record<BotId: string, UserId: string, DisplayName: string, BotType: string, Disabled: bool, CreatedTimestamp: string, UpdatedTimestamp: string, BotEmail: string, SecurityToken: string>>"
    reset-personal-pin: "record<User: record<UserId: string, AccountId: string, PrimaryEmail: string, PrimaryProvisionedNumber: string, DisplayName: string, LicenseType: string, UserType: string, UserRegistrationStatus: string, UserInvitationStatus: string, RegisteredOn: string, InvitedOn: string, AlexaForBusinessMetadata: record<IsAlexaForBusinessEnabled: bool, AlexaForBusinessRoomArn: string>, PersonalPIN: string>>"
    restore-phone-number: "record<PhoneNumber: record<PhoneNumberId: string, E164PhoneNumber: string, Country: string, Type: string, ProductType: string, Status: string, Capabilities: record<InboundCall: bool, OutboundCall: bool, InboundSMS: bool, OutboundSMS: bool, InboundMMS: bool, OutboundMMS: bool>, Associations: list<record>, CallingName: string, CallingNameStatus: string, CreatedTimestamp: string, UpdatedTimestamp: string, DeletionTimestamp: string>>"
    search-available-phone-numbers: "record<E164PhoneNumbers: list<string>, NextToken: string>"
    start-meeting-transcription: "record"
    stop-meeting-transcription: "record"
    update-channel-read-marker: "record<ChannelArn: string>"
    update-sip-media-application-call: "record<SipMediaApplicationCall: record<TransactionId: string>>"
    validate-e911-address: "record<ValidationResult: int, AddressExternalId: string, Address: record<streetName: string, streetSuffix: string, postDirectional: string, preDirectional: string, streetNumber: string, city: string, state: string, postalCode: string, postalCodePlus4: string, country: string>, CandidateAddressList: table<streetInfo: string, streetNumber: string, city: string, state: string, postalCode: string, postalCodePlus4: string, country: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["associate-phone-number-with-user" "associate-phone-numbers-with-voice-connector" "associate-phone-numbers-with-voice-connector-group" "associate-signin-delegate-groups-with-account" "batch-create-attendee" "batch-create-channel-membership" "batch-create-room-membership" "batch-delete-phone-number" "batch-suspend-user" "batch-unsuspend-user" "batch-update-phone-number" "batch-update-user" "list-users" "create-account" "list-accounts" "create-app-instance" "list-app-instances" "create-app-instance-admin" "list-app-instance-admins" "create-app-instance-user" "create-attendee" "list-attendees" "create-bot" "list-bots" "create-channel" "create-channel-ban" "list-channel-bans" "create-channel-membership" "list-channel-memberships" "create-channel-moderator" "list-channel-moderators" "create-media-capture-pipeline" "list-media-capture-pipelines" "create-meeting" "list-meetings" "create-meeting-dial-out" "create-meeting-with-attendees" "create-phone-number-order" "list-phone-number-orders" "create-proxy-session" "list-proxy-sessions" "create-room" "list-rooms" "create-room-membership" "list-room-memberships" "create-sip-media-application" "list-sip-media-applications" "create-sip-media-application-call" "create-sip-rule" "list-sip-rules" "create-user" "create-voice-connector" "list-voice-connectors" "create-voice-connector-group" "list-voice-connector-groups" "delete-account" "get-account" "update-account" "delete-app-instance" "describe-app-instance" "update-app-instance" "delete-app-instance-admin" "describe-app-instance-admin" "delete-app-instance-streaming-configurations" "get-app-instance-streaming-configurations" "put-app-instance-streaming-configurations" "delete-app-instance-user" "describe-app-instance-user" "update-app-instance-user" "delete-attendee" "get-attendee" "delete-channel" "describe-channel" "update-channel" "delete-channel-ban" "describe-channel-ban" "delete-channel-membership" "describe-channel-membership" "delete-channel-message" "get-channel-message" "update-channel-message" "delete-channel-moderator" "describe-channel-moderator" "delete-events-configuration" "get-events-configuration" "put-events-configuration" "delete-media-capture-pipeline" "get-media-capture-pipeline" "delete-meeting" "get-meeting" "delete-phone-number" "get-phone-number" "update-phone-number" "delete-proxy-session" "get-proxy-session" "update-proxy-session" "delete-room" "get-room" "update-room" "delete-room-membership" "update-room-membership" "delete-sip-media-application" "get-sip-media-application" "update-sip-media-application" "delete-sip-rule" "get-sip-rule" "update-sip-rule" "delete-voice-connector" "get-voice-connector" "update-voice-connector" "delete-voice-connector-emergency-calling-configuration" "get-voice-connector-emergency-calling-configuration" "put-voice-connector-emergency-calling-configuration" "delete-voice-connector-group" "get-voice-connector-group" "update-voice-connector-group" "delete-voice-connector-origination" "get-voice-connector-origination" "put-voice-connector-origination" "delete-voice-connector-proxy" "get-voice-connector-proxy" "put-voice-connector-proxy" "delete-voice-connector-streaming-configuration" "get-voice-connector-streaming-configuration" "put-voice-connector-streaming-configuration" "delete-voice-connector-termination" "get-voice-connector-termination" "put-voice-connector-termination" "delete-voice-connector-termination-credentials" "describe-channel-membership-for-app-instance-user" "describe-channel-moderated-by-app-instance-user" "disassociate-phone-number-from-user" "disassociate-phone-numbers-from-voice-connector" "disassociate-phone-numbers-from-voice-connector-group" "disassociate-signin-delegate-groups-from-account" "get-account-settings" "update-account-settings" "get-app-instance-retention-settings" "put-app-instance-retention-settings" "get-bot" "update-bot" "get-global-settings" "update-global-settings" "get-messaging-session-endpoint" "get-phone-number-order" "get-phone-number-settings" "update-phone-number-settings" "get-retention-settings" "put-retention-settings" "get-sip-media-application-logging-configuration" "put-sip-media-application-logging-configuration" "get-user" "update-user" "get-user-settings" "update-user-settings" "get-voice-connector-logging-configuration" "put-voice-connector-logging-configuration" "get-voice-connector-termination-health" "invite-users" "list-app-instance-users" "list-attendee-tags" "list-channel-memberships-for-app-instance-user" "list-channel-messages" "send-channel-message" "list-channels" "list-channels-moderated-by-app-instance-user" "list-meeting-tags" "list-phone-numbers" "list-supported-phone-number-countries" "list-tags-for-resource" "list-voice-connector-termination-credentials" "logout-user" "put-voice-connector-termination-credentials" "redact-channel-message" "redact-conversation-message" "redact-room-message" "regenerate-security-token" "reset-personal-pin" "restore-phone-number" "search-available-phone-numbers" "start-meeting-transcription" "stop-meeting-transcription" "tag-attendee" "tag-meeting" "tag-resource" "untag-attendee" "untag-meeting" "untag-resource" "update-channel-read-marker" "update-sip-media-application-call" "validate-e911-address" "commands"] | sort) } | get name | first)
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

# Associates a phone number with the specified Amazon Chime user.
#
# POST /accounts/{accountId}/users/{userId}
# Returns: record
# operationId: AssociatePhoneNumberWithUser
export def "associate-phone-number-with-user" [
  account_id: string
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
  --operation: string@operation-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  e164_phone_number: string # The phone number, in E.164 format. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/users/{userId}"
    path_params: [{name: accountId, var: account_id}, {name: userId, var: user_id}]
    query: [{name: operation, var: operation, required: true, default: associate-phone-number}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: E164PhoneNumber, var: e164_phone_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, user_id: $user_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, e164_phone_number: $e164_phone_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates phone numbers with the specified Amazon Chime Voice Connector.
#
# POST /voice-connectors/{voiceConnectorId}
# Returns: record<PhoneNumberErrors: table<PhoneNumberId: string, ErrorCode: string, ErrorMessage: string>>
# operationId: AssociatePhoneNumbersWithVoiceConnector
export def "associate-phone-numbers-with-voice-connector" [
  voice_connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-1 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  e164_phone_numbers: list<string> # List of phone numbers, in E.164 format.
  --force-associate: oneof<nothing, bool> # If true, associates the provided phone numbers with the provided Amazon Chime Voice Connector and removes any previously existing associations. If false, does not associate any phone numbers that have previously existing associations.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/voice-connectors/{voiceConnectorId}"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    query: [{name: operation, var: operation, required: true, default: associate-phone-numbers}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: E164PhoneNumbers, var: e164_phone_numbers}, {name: ForceAssociate, var: force_associate}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, e164_phone_numbers: $e164_phone_numbers, force_associate: $force_associate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates phone numbers with the specified Amazon Chime Voice Connector group.
#
# POST /voice-connector-groups/{voiceConnectorGroupId}
# Returns: record<PhoneNumberErrors: table<PhoneNumberId: string, ErrorCode: string, ErrorMessage: string>>
# operationId: AssociatePhoneNumbersWithVoiceConnectorGroup
export def "associate-phone-numbers-with-voice-connector-group" [
  voice_connector_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-1 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  e164_phone_numbers: list<string> # List of phone numbers, in E.164 format.
  --force-associate: oneof<nothing, bool> # If true, associates the provided phone numbers with the provided Amazon Chime Voice Connector Group and removes any previously existing associations. If false, does not associate any phone numbers that have previously existing associations.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/voice-connector-groups/{voiceConnectorGroupId}"
    path_params: [{name: voiceConnectorGroupId, var: voice_connector_group_id}]
    query: [{name: operation, var: operation, required: true, default: associate-phone-numbers}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: E164PhoneNumbers, var: e164_phone_numbers}, {name: ForceAssociate, var: force_associate}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_group_id: $voice_connector_group_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, e164_phone_numbers: $e164_phone_numbers, force_associate: $force_associate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates the specified sign-in delegate groups with the specified Amazon Chime account.
#
# POST /accounts/{accountId}
# Returns: record
# operationId: AssociateSigninDelegateGroupsWithAccount
export def "associate-signin-delegate-groups-with-account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-2 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  signin_delegate_groups: list # The sign-in delegate groups. — item shape: {GroupName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: operation, var: operation, required: true, default: associate-signin-delegate-groups}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SigninDelegateGroups, var: signin_delegate_groups}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, signin_delegate_groups: $signin_delegate_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates up to 100 new attendees for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide.
#
# POST /meetings/{meetingId}/attendees
# Returns: record<Attendees: table<ExternalUserId: string, AttendeeId: string, JoinToken: string>, Errors: table<ExternalUserId: string, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchCreateAttendee
export def "batch-create-attendee" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-3 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  attendees: list # The request containing the attendees to create. — item shape: {ExternalUserId: string, Tags?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/meetings/{meetingId}/attendees"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: operation, var: operation, required: true, default: batch-create}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Attendees, var: attendees}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    meeting_id: $meeting_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, attendees: $attendees
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a specified number of users to a channel.
#
# POST /channels/{channelArn}/memberships
# Returns: record<BatchChannelMemberships: record<InvitedBy: record<Arn: string, Name: string>, Type: string, Members: list<record>, ChannelArn: string>, Errors: table<MemberArn: string, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchCreateChannelMembership
export def "batch-create-channel-membership" [
  channel_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-3 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
  --type: string@type-completer # The membership type of a user, DEFAULT or HIDDEN. Default members are always returned as part of ListChannelMemberships. Hidden members are only returned if the type filter in ListChannelMemberships equals HIDDEN. Otherwise hidden members are not returned. This is only supported by moderators.
  member_arns: list<string> # The ARNs of the members you want to add to the channel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{channelArn}/memberships"
    path_params: [{name: channelArn, var: channel_arn}]
    query: [{name: operation, var: operation, required: true, default: batch-create}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    body: {content_type: "application/json", kind: json, fields: [{name: Type, var: type}, {name: MemberArns, var: member_arns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_arn: $channel_arn, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer, type: $type, member_arns: $member_arns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds up to 50 members to a chat room in an Amazon Chime Enterprise account. Members can be users or bots. The member role designates whether the member is a chat room administrator or a general chat room member.
#
# POST /accounts/{accountId}/rooms/{roomId}/memberships
# Returns: record<Errors: table<MemberId: string, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchCreateRoomMembership
export def "batch-create-room-membership" [
  account_id: string
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-3 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  membership_item_list: list # The list of membership items. — item shape: {MemberId?: string, Role?: "Administrator"|"Member"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/rooms/{roomId}/memberships"
    path_params: [{name: accountId, var: account_id}, {name: roomId, var: room_id}]
    query: [{name: operation, var: operation, required: true, default: batch-create}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MembershipItemList, var: membership_item_list}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, room_id: $room_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, membership_item_list: $membership_item_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves phone numbers into the Deletion queue. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted. Phone numbers remain in the Deletion queue for 7 days before they are deleted permanently.
#
# POST /phone-numbers
# Returns: record<PhoneNumberErrors: table<PhoneNumberId: string, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchDeletePhoneNumber
export def "batch-delete-phone-number" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-4 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  phone_number_ids: list<string> # List of phone number IDs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone-numbers"
    query: [{name: operation, var: operation, required: true, default: batch-delete}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: PhoneNumberIds, var: phone_number_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, phone_number_ids: $phone_number_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suspends up to 50 users from a Team or EnterpriseLWA Amazon Chime account. For more information about different account types, see Managing Your Amazon Chime Accounts (https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html) in the Amazon Chime Administration Guide. Users suspended from a Team account are disassociated from the account,but they can continue to use Amazon Chime as free users. To remove the suspension from suspended Team account users, invite them to the Team account again. You can use the InviteUsers action to do so. Users suspended from an EnterpriseLWA account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended EnterpriseLWA account users, use the BatchUnsuspendUser action. To sign out users without suspending them, use the LogoutUser action.
#
# POST /accounts/{accountId}/users
# Returns: record<UserErrors: table<UserId: string, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchSuspendUser
export def "batch-suspend-user" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-5 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  user_id_list: list<string> # The request containing the user IDs to suspend.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/users"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: operation, var: operation, required: true, default: suspend}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: UserIdList, var: user_id_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, user_id_list: $user_id_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime EnterpriseLWA account. Only users on EnterpriseLWA accounts can be unsuspended using this action. For more information about different account types, see Managing Your Amazon Chime Accounts (https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html) in the account types, in the Amazon Chime Administration Guide. Previously suspended users who are unsuspended using this action are returned to Registered status. Users who are not previously suspended are ignored.
#
# POST /accounts/{accountId}/users
# Returns: record<UserErrors: table<UserId: string, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchUnsuspendUser
export def "batch-unsuspend-user" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-6 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  user_id_list: list<string> # The request containing the user IDs to unsuspend.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/users"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: operation, var: operation, required: true, default: unsuspend}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: UserIdList, var: user_id_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, user_id_list: $user_id_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates phone number product types or calling names. You can update one attribute at a time for each UpdatePhoneNumberRequestItem. For example, you can update the product type or the calling name. For toll-free numbers, you cannot use the Amazon Chime Business Calling product type. For numbers outside the U.S., you must use the Amazon Chime SIP Media Application Dial-In product type. Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.
#
# POST /phone-numbers
# Returns: record<PhoneNumberErrors: table<PhoneNumberId: string, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchUpdatePhoneNumber
export def "batch-update-phone-number" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-7 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  update_phone_number_request_items: list # The request containing the phone number IDs and product types or calling names to update. — item shape: {PhoneNumberId: string, ProductType?: "BusinessCalling"|"VoiceConnector"|"SipMediaApplicationDialIn", CallingName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone-numbers"
    query: [{name: operation, var: operation, required: true, default: batch-update}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: UpdatePhoneNumberRequestItems, var: update_phone_number_request_items}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, update_phone_number_request_items: $update_phone_number_request_items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates user details within the UpdateUserRequestItem object for up to 20 users for the specified Amazon Chime account. Currently, only LicenseType updates are supported for this action.
#
# POST /accounts/{accountId}/users
# Returns: record<UserErrors: table<UserId: string, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchUpdateUser
export def "batch-update-user" [
  account_id: string
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
  update_user_request_items: list # The request containing the user IDs and details to update. — item shape: {UserId: string, LicenseType?: "Basic"|"Plus"|"Pro"|"ProTrial", UserType?: "PrivateUser"|"SharedDevice", AlexaForBusinessMetadata?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/users"
    path_params: [{name: accountId, var: account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: UpdateUserRequestItems, var: update_user_request_items}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, update_user_request_items: $update_user_request_items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
#
# GET /accounts/{accountId}/users
# Returns: record<Users: table<UserId: string, AccountId: string, PrimaryEmail: string, PrimaryProvisionedNumber: string, DisplayName: string, LicenseType: string, UserType: string, UserRegistrationStatus: string, UserInvitationStatus: string, RegisteredOn: string, InvitedOn: string, AlexaForBusinessMetadata: record, PersonalPIN: string>, NextToken: string>
# operationId: ListUsers
export def "list-users" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-email: string # Optional. The user email address used to filter results. Maximum 1. (format: password)
  --user-type: string@user-type-completer # The user type.
  --max-results: int # The maximum number of results to return in a single call. Defaults to 100.
  --next-token: string # The token to use to retrieve the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/accounts/{accountId}/users"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: user-email, var: user_email}, {name: user-type, var: user_type}, {name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, user_email: $user_email, user_type: $user_type, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon Chime account under the administrator's AWS account. Only Team account types are currently supported for this action. For more information about different account types, see Managing Your Amazon Chime Accounts (https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html) in the Amazon Chime Administration Guide.
#
# POST /accounts
# Returns: record<Account: record<AwsAccountId: string, AccountId: string, Name: string, AccountType: string, CreatedTimestamp: string, DefaultLicense: string, SupportedLicenses: list<string>, AccountStatus: string, SigninDelegateGroups: list<record>>>
# operationId: CreateAccount
export def "create-account" [
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
  name: string # The name of the Amazon Chime account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Amazon Chime accounts under the administrator's AWS account. You can filter accounts by account name prefix. To find out which Amazon Chime account a user belongs to, you can filter by the user's email address, which returns one account result.
#
# GET /accounts
# Returns: record<Accounts: table<AwsAccountId: string, AccountId: string, Name: string, AccountType: string, CreatedTimestamp: string, DefaultLicense: string, SupportedLicenses: list, AccountStatus: string, SigninDelegateGroups: list>, NextToken: string>
# operationId: ListAccounts
export def "list-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Amazon Chime account name prefix with which to filter results.
  --user-email: string # User email address with which to filter results. (format: password)
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results: int # The maximum number of results to return in a single call. Defaults to 100.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/accounts"
    query: [{name: name, var: name}, {name: user-email, var: user_email}, {name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, user_email: $user_email, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon Chime SDK messaging AppInstance under an AWS account. Only SDK messaging customers use this API. CreateAppInstance supports idempotency behavior as described in the AWS API Standard.
#
# POST /app-instances
# Returns: record<AppInstanceArn: string>
# operationId: CreateAppInstance
export def "create-app-instance" [
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
  name: string # The name of the AppInstance. (format: password)
  --metadata: string # The metadata of the AppInstance. Limited to a 1KB string in UTF-8. (format: password)
  client_request_token: string # The ClientRequestToken of the AppInstance. (format: password)
  --tags: list # Tags assigned to the AppInstance. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/app-instances"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Metadata, var: metadata}, {name: ClientRequestToken, var: client_request_token}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, metadata: $metadata, client_request_token: $client_request_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all Amazon Chime AppInstances created under a single AWS account.
#
# GET /app-instances
# Returns: record<AppInstances: table<AppInstanceArn: string, Name: string, Metadata: string>, NextToken: string>
# operationId: ListAppInstances
export def "list-app-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of AppInstances that you want to return.
  --next-token: string # The token passed by previous API requests until you reach the maximum number of AppInstances. (format: password)
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/app-instances"
    query: [{name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Promotes an AppInstanceUser to an AppInstanceAdmin. The promoted user can perform the following actions. ChannelModerator actions across all channels in the AppInstance. DeleteChannelMessage actions. Only an AppInstanceUser can be promoted to an AppInstanceAdmin role.
#
# POST /app-instances/{appInstanceArn}/admins
# Returns: record<AppInstanceAdmin: record<Arn: string, Name: string>, AppInstanceArn: string>
# operationId: CreateAppInstanceAdmin
export def "create-app-instance-admin" [
  app_instance_arn: string
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
  app_instance_admin_arn: string # The ARN of the administrator of the current AppInstance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/app-instances/{appInstanceArn}/admins"
    path_params: [{name: appInstanceArn, var: app_instance_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AppInstanceAdminArn, var: app_instance_admin_arn}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    app_instance_arn: $app_instance_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, app_instance_admin_arn: $app_instance_admin_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the administrators in the AppInstance.
#
# GET /app-instances/{appInstanceArn}/admins
# Returns: record<AppInstanceArn: string, AppInstanceAdmins: table<Admin: record>, NextToken: string>
# operationId: ListAppInstanceAdmins
export def "list-app-instance-admins" [
  app_instance_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of administrators that you want to return.
  --next-token: string # The token returned from previous API requests until the number of administrators is reached. (format: password)
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/app-instances/{appInstanceArn}/admins"
    path_params: [{name: appInstanceArn, var: app_instance_arn}]
    query: [{name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_instance_arn: $app_instance_arn, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a user under an Amazon Chime AppInstance. The request consists of a unique appInstanceUserId and Name for that user.
#
# POST /app-instance-users
# Returns: record<AppInstanceUserArn: string>
# operationId: CreateAppInstanceUser
export def "create-app-instance-user" [
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
  app_instance_arn: string # The ARN of the AppInstance request.
  app_instance_user_id: string # The user ID of the AppInstance. (format: password)
  name: string # The user's name. (format: password)
  --metadata: string # The request's metadata. Limited to a 1KB string in UTF-8. (format: password)
  client_request_token: string # The token assigned to the user requesting an AppInstance. (format: password)
  --tags: list # Tags assigned to the AppInstanceUser. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/app-instance-users"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AppInstanceArn, var: app_instance_arn}, {name: AppInstanceUserId, var: app_instance_user_id}, {name: Name, var: name}, {name: Metadata, var: metadata}, {name: ClientRequestToken, var: client_request_token}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, app_instance_arn: $app_instance_arn, app_instance_user_id: $app_instance_user_id, name: $name, metadata: $metadata, client_request_token: $client_request_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new attendee for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide.
#
# POST /meetings/{meetingId}/attendees
# Returns: record<Attendee: record<ExternalUserId: string, AttendeeId: string, JoinToken: string>>
# operationId: CreateAttendee
export def "create-attendee" [
  meeting_id: string
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
  external_user_id: string # The Amazon Chime SDK external user ID. An idempotency token. Links the attendee to an identity managed by a builder application. (format: password)
  --tags: list # The tag key-value pairs. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/meetings/{meetingId}/attendees"
    path_params: [{name: meetingId, var: meeting_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ExternalUserId, var: external_user_id}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    meeting_id: $meeting_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, external_user_id: $external_user_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the attendees for the specified Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide.
#
# GET /meetings/{meetingId}/attendees
# Returns: record<Attendees: table<ExternalUserId: string, AttendeeId: string, JoinToken: string>, NextToken: string>
# operationId: ListAttendees
export def "list-attendees" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results: int # The maximum number of results to return in a single call.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/meetings/{meetingId}/attendees"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a bot for an Amazon Chime Enterprise account.
#
# POST /accounts/{accountId}/bots
# Returns: record<Bot: record<BotId: string, UserId: string, DisplayName: string, BotType: string, Disabled: bool, CreatedTimestamp: string, UpdatedTimestamp: string, BotEmail: string, SecurityToken: string>>
# operationId: CreateBot
export def "create-bot" [
  account_id: string
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
  display_name: string # The bot display name. (format: password)
  --domain: string # The domain of the Amazon Chime Enterprise account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/bots"
    path_params: [{name: accountId, var: account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DisplayName, var: display_name}, {name: Domain, var: domain}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, display_name: $display_name, domain: $domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
#
# GET /accounts/{accountId}/bots
# Returns: record<Bots: table<BotId: string, UserId: string, DisplayName: string, BotType: string, Disabled: bool, CreatedTimestamp: string, UpdatedTimestamp: string, BotEmail: string, SecurityToken: string>, NextToken: string>
# operationId: ListBots
export def "list-bots" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return in a single call. The default is 10.
  --next-token: string # The token to use to retrieve the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/accounts/{accountId}/bots"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a channel to which you can add users and send messages. Restriction: You can't change a channel's privacy. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# POST /channels
# Returns: record<ChannelArn: string>
# operationId: CreateChannel
export def "create-channel" [
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
  app_instance_arn: string # The ARN of the channel request.
  name: string # The name of the channel. (format: password)
  --mode: string@mode-completer # The channel mode: UNRESTRICTED or RESTRICTED. Administrators, moderators, and channel members can add themselves and other members to unrestricted channels. Only administrators and moderators can add members to restricted channels.
  --privacy: string@privacy-completer # The channel's privacy level: PUBLIC or PRIVATE. Private channels aren't discoverable by users outside the channel. Public channels are discoverable by anyone in the AppInstance.
  --metadata: string # The metadata of the creation request. Limited to 1KB and UTF-8. (format: password)
  client_request_token: string # The client token for the request. An Idempotency token. (format: password)
  --tags: list # The tags for the creation request. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    body: {content_type: "application/json", kind: json, fields: [{name: AppInstanceArn, var: app_instance_arn}, {name: Name, var: name}, {name: Mode, var: mode}, {name: Privacy, var: privacy}, {name: Metadata, var: metadata}, {name: ClientRequestToken, var: client_request_token}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer, app_instance_arn: $app_instance_arn, name: $name, mode: $mode, privacy: $privacy, metadata: $metadata, client_request_token: $client_request_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently bans a member from a channel. Moderators can't add banned members to a channel. To undo a ban, you first have to DeleteChannelBan, and then CreateChannelMembership. Bans are cleaned up when you delete users or channels. If you ban a user who is already part of a channel, that user is automatically kicked from the channel. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# POST /channels/{channelArn}/bans
# Returns: record<ChannelArn: string, Member: record<Arn: string, Name: string>>
# operationId: CreateChannelBan
export def "create-channel-ban" [
  channel_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
  member_arn: string # The ARN of the member being banned.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{channelArn}/bans"
    path_params: [{name: channelArn, var: channel_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    body: {content_type: "application/json", kind: json, fields: [{name: MemberArn, var: member_arn}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    channel_arn: $channel_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer, member_arn: $member_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the users banned from a particular channel. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}/bans
# Returns: record<ChannelArn: string, NextToken: string, ChannelBans: table<Member: record>>
# operationId: ListChannelBans
export def "list-channel-bans" [
  channel_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of bans that you want returned.
  --next-token: string # The token passed by previous API calls until all requested bans are returned. (format: password)
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channelArn}/bans"
    path_params: [{name: channelArn, var: channel_arn}]
    query: [{name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_arn: $channel_arn, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a user to a channel. The InvitedBy response field is derived from the request header. A channel member can: List messages Send messages Receive messages Edit their own messages Leave the channel Privacy settings impact this action as follows: Public Channels: You do not need to be a member to list messages, but you must be a member to send messages. Private Channels: You must be a member to list or send messages. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# POST /channels/{channelArn}/memberships
# Returns: record<ChannelArn: string, Member: record<Arn: string, Name: string>>
# operationId: CreateChannelMembership
export def "create-channel-membership" [
  channel_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
  member_arn: string # The ARN of the member you want to add to the channel.
  type: string@type-completer # The membership type of a user, DEFAULT or HIDDEN. Default members are always returned as part of ListChannelMemberships. Hidden members are only returned if the type filter in ListChannelMemberships equals HIDDEN. Otherwise hidden members are not returned. This is only supported by moderators.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{channelArn}/memberships"
    path_params: [{name: channelArn, var: channel_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    body: {content_type: "application/json", kind: json, fields: [{name: MemberArn, var: member_arn}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    channel_arn: $channel_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer, member_arn: $member_arn, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all channel memberships in a channel. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}/memberships
# Returns: record<ChannelArn: string, ChannelMemberships: table<Member: record>, NextToken: string>
# operationId: ListChannelMemberships
export def "list-channel-memberships" [
  channel_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # The membership type of a user, DEFAULT or HIDDEN. Default members are always returned as part of ListChannelMemberships. Hidden members are only returned if the type filter in ListChannelMemberships equals HIDDEN. Otherwise hidden members are not returned.
  --max-results: int # The maximum number of channel memberships that you want returned.
  --next-token: string # The token passed by previous API calls until all requested channel memberships are returned. (format: password)
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channelArn}/memberships"
    path_params: [{name: channelArn, var: channel_arn}]
    query: [{name: type, var: type}, {name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_arn: $channel_arn, type: $type, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new ChannelModerator. A channel moderator can: Add and remove other members of the channel. Add and remove other moderators of the channel. Add and remove user bans for the channel. Redact messages in the channel. List messages in the channel. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# POST /channels/{channelArn}/moderators
# Returns: record<ChannelArn: string, ChannelModerator: record<Arn: string, Name: string>>
# operationId: CreateChannelModerator
export def "create-channel-moderator" [
  channel_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
  channel_moderator_arn: string # The ARN of the moderator.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{channelArn}/moderators"
    path_params: [{name: channelArn, var: channel_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    body: {content_type: "application/json", kind: json, fields: [{name: ChannelModeratorArn, var: channel_moderator_arn}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    channel_arn: $channel_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer, channel_moderator_arn: $channel_moderator_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the moderators for a channel. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}/moderators
# Returns: record<ChannelArn: string, NextToken: string, ChannelModerators: table<Moderator: record>>
# operationId: ListChannelModerators
export def "list-channel-moderators" [
  channel_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of moderators that you want returned.
  --next-token: string # The token passed by previous API calls until all requested moderators are returned. (format: password)
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channelArn}/moderators"
    path_params: [{name: channelArn, var: channel_arn}]
    query: [{name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_arn: $channel_arn, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a media capture pipeline.
#
# POST /media-capture-pipelines
# Returns: record<MediaCapturePipeline: record<MediaPipelineId: string, SourceType: string, SourceArn: string, Status: string, SinkType: string, SinkArn: string, CreatedTimestamp: string, UpdatedTimestamp: string, ChimeSdkMeetingConfiguration: record<SourceConfiguration: record, ArtifactsConfiguration: record>>>
# operationId: CreateMediaCapturePipeline
export def "create-media-capture-pipeline" [
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
  source_type: string@source-type-completer # Source type from which the media artifacts will be captured. A Chime SDK Meeting is the only supported source.
  source_arn: string # ARN of the source from which the media artifacts are captured. (format: password)
  sink_type: string@sink-type-completer # Destination type to which the media artifacts are saved. You must use an S3 bucket.
  sink_arn: string # The ARN of the sink type. (format: password)
  --client-request-token: string # The unique identifier for the client request. The token makes the API request idempotent. Use a different token for different media pipeline requests. (format: password)
  --chime-sdk-meeting-configuration: record # The configuration object of the Amazon Chime SDK meeting for a specified media capture pipeline. SourceType must be ChimeSdkMeeting. — shape: {SourceConfiguration?: record, ArtifactsConfiguration?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/media-capture-pipelines"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SourceType, var: source_type}, {name: SourceArn, var: source_arn}, {name: SinkType, var: sink_type}, {name: SinkArn, var: sink_arn}, {name: ClientRequestToken, var: client_request_token}, {name: ChimeSdkMeetingConfiguration, var: chime_sdk_meeting_configuration}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, source_type: $source_type, source_arn: $source_arn, sink_type: $sink_type, sink_arn: $sink_arn, client_request_token: $client_request_token, chime_sdk_meeting_configuration: $chime_sdk_meeting_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of media capture pipelines.
#
# GET /media-capture-pipelines
# Returns: record<MediaCapturePipelines: table<MediaPipelineId: string, SourceType: string, SourceArn: string, Status: string, SinkType: string, SinkArn: string, CreatedTimestamp: string, UpdatedTimestamp: string, ChimeSdkMeetingConfiguration: record>, NextToken: string>
# operationId: ListMediaCapturePipelines
export def "list-media-capture-pipelines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token used to retrieve the next page of results.
  --max-results: int # The maximum number of results to return in a single call. Valid Range: 1 - 99.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/media-capture-pipelines"
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Amazon Chime SDK meeting in the specified media Region with no initial attendees. For more information about specifying media Regions, see Amazon Chime SDK Media Regions (https://docs.aws.amazon.com/chime-sdk/latest/dg/chime-sdk-meetings-regions.html) in the Amazon Chime SDK Developer Guide . For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide .
#
# POST /meetings
# Returns: record<Meeting: record<MeetingId: string, ExternalMeetingId: string, MediaPlacement: record<AudioHostUrl: string, AudioFallbackUrl: string, ScreenDataUrl: string, ScreenSharingUrl: string, ScreenViewingUrl: string, SignalingUrl: string, TurnControlUrl: string, EventIngestionUrl: string>, MediaRegion: string>>
# operationId: CreateMeeting
export def "create-meeting" [
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
  client_request_token: string # The unique identifier for the client request. Use a different token for different meetings. (format: password)
  --external-meeting-id: string # The external meeting ID. (format: password)
  --meeting-host-id: string # Reserved. (format: password)
  --media-region: string # The Region in which to create the meeting. Default: us-east-1. Available values: af-south-1 , ap-northeast-1 , ap-northeast-2 , ap-south-1 , ap-southeast-1 , ap-southeast-2 , ca-central-1 , eu-central-1 , eu-north-1 , eu-south-1 , eu-west-1 , eu-west-2 , eu-west-3 , sa-east-1 , us-east-1 , us-east-2 , us-west-1 , us-west-2 .
  --tags: list # The tag key-value pairs. — item shape: {Key: string, Value: string}
  --notifications-configuration: record # The resource target configurations for receiving Amazon Chime SDK meeting and attendee event notifications. The Amazon Chime SDK supports resource targets located in the US East (N. Virginia) AWS Region (us-east-1). — shape: {SnsTopicArn?: string, SqsQueueArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/meetings"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientRequestToken, var: client_request_token}, {name: ExternalMeetingId, var: external_meeting_id}, {name: MeetingHostId, var: meeting_host_id}, {name: MediaRegion, var: media_region}, {name: Tags, var: tags}, {name: NotificationsConfiguration, var: notifications_configuration}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_request_token: $client_request_token, external_meeting_id: $external_meeting_id, meeting_host_id: $meeting_host_id, media_region: $media_region, tags: $tags, notifications_configuration: $notifications_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists up to 100 active Amazon Chime SDK meetings. For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide.
#
# GET /meetings
# Returns: record<Meetings: table<MeetingId: string, ExternalMeetingId: string, MediaPlacement: record, MediaRegion: string>, NextToken: string>
# operationId: ListMeetings
export def "list-meetings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results: int # The maximum number of results to return in a single call.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/meetings"
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uses the join token and call metadata in a meeting request (From number, To number, and so forth) to initiate an outbound call to a public switched telephone network (PSTN) and join them into a Chime meeting. Also ensures that the From number belongs to the customer. To play welcome audio or implement an interactive voice response (IVR), use the CreateSipMediaApplicationCall action with the corresponding SIP media application ID.
#
# POST /meetings/{meetingId}/dial-outs
# Returns: record<TransactionId: string>
# operationId: CreateMeetingDialOut
export def "create-meeting-dial-out" [
  meeting_id: string
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
  from_phone_number: string # Phone number used as the caller ID when the remote party receives a call. (format: password)
  to_phone_number: string # Phone number called when inviting someone to a meeting. (format: password)
  join_token: string # Token used by the Amazon Chime SDK attendee. Call the CreateAttendee (https://docs.aws.amazon.com/chime/latest/APIReference/API_CreateAttendee.html) action to get a join token. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/meetings/{meetingId}/dial-outs"
    path_params: [{name: meetingId, var: meeting_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: FromPhoneNumber, var: from_phone_number}, {name: ToPhoneNumber, var: to_phone_number}, {name: JoinToken, var: join_token}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    meeting_id: $meeting_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, from_phone_number: $from_phone_number, to_phone_number: $to_phone_number, join_token: $join_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Amazon Chime SDK meeting in the specified media Region, with attendees. For more information about specifying media Regions, see Amazon Chime SDK Media Regions (https://docs.aws.amazon.com/chime-sdk/latest/dg/chime-sdk-meetings-regions.html) in the Amazon Chime SDK Developer Guide . For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide .
#
# POST /meetings
# Returns: record<Meeting: record<MeetingId: string, ExternalMeetingId: string, MediaPlacement: record<AudioHostUrl: string, AudioFallbackUrl: string, ScreenDataUrl: string, ScreenSharingUrl: string, ScreenViewingUrl: string, SignalingUrl: string, TurnControlUrl: string, EventIngestionUrl: string>, MediaRegion: string>, Attendees: table<ExternalUserId: string, AttendeeId: string, JoinToken: string>, Errors: table<ExternalUserId: string, ErrorCode: string, ErrorMessage: string>>
# operationId: CreateMeetingWithAttendees
export def "create-meeting-with-attendees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-8 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  client_request_token: string # The unique identifier for the client request. Use a different token for different meetings. (format: password)
  --external-meeting-id: string # The external meeting ID. (format: password)
  --meeting-host-id: string # Reserved. (format: password)
  --media-region: string # The Region in which to create the meeting. Default: us-east-1 . Available values: af-south-1 , ap-northeast-1 , ap-northeast-2 , ap-south-1 , ap-southeast-1 , ap-southeast-2 , ca-central-1 , eu-central-1 , eu-north-1 , eu-south-1 , eu-west-1 , eu-west-2 , eu-west-3 , sa-east-1 , us-east-1 , us-east-2 , us-west-1 , us-west-2 .
  --tags: list # The tag key-value pairs. — item shape: {Key: string, Value: string}
  --notifications-configuration: record # The resource target configurations for receiving Amazon Chime SDK meeting and attendee event notifications. The Amazon Chime SDK supports resource targets located in the US East (N. Virginia) AWS Region (us-east-1). — shape: {SnsTopicArn?: string, SqsQueueArn?: string}
  --attendees: list # The request containing the attendees to create. — item shape: {ExternalUserId: string, Tags?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/meetings"
    query: [{name: operation, var: operation, required: true, default: create-attendees}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientRequestToken, var: client_request_token}, {name: ExternalMeetingId, var: external_meeting_id}, {name: MeetingHostId, var: meeting_host_id}, {name: MediaRegion, var: media_region}, {name: Tags, var: tags}, {name: NotificationsConfiguration, var: notifications_configuration}, {name: Attendees, var: attendees}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_request_token: $client_request_token, external_meeting_id: $external_meeting_id, meeting_host_id: $meeting_host_id, media_region: $media_region, tags: $tags, notifications_configuration: $notifications_configuration, attendees: $attendees
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an order for phone numbers to be provisioned. For toll-free numbers, you cannot use the Amazon Chime Business Calling product type. For numbers outside the U.S., you must use the Amazon Chime SIP Media Application Dial-In product type.
#
# POST /phone-number-orders
# Returns: record<PhoneNumberOrder: record<PhoneNumberOrderId: string, ProductType: string, Status: string, OrderedPhoneNumbers: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string>>
# operationId: CreatePhoneNumberOrder
export def "create-phone-number-order" [
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
  product_type: string@product-type-completer # The phone number product type.
  e164_phone_numbers: list<string> # List of phone numbers, in E.164 format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone-number-orders"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ProductType, var: product_type}, {name: E164PhoneNumbers, var: e164_phone_numbers}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, product_type: $product_type, e164_phone_numbers: $e164_phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the phone number orders for the administrator's Amazon Chime account.
#
# GET /phone-number-orders
# Returns: record<PhoneNumberOrders: table<PhoneNumberOrderId: string, ProductType: string, Status: string, OrderedPhoneNumbers: list, CreatedTimestamp: string, UpdatedTimestamp: string>, NextToken: string>
# operationId: ListPhoneNumberOrders
export def "list-phone-number-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results: int # The maximum number of results to return in a single call.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/phone-number-orders"
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a proxy session on the specified Amazon Chime Voice Connector for the specified participant phone numbers.
#
# POST /voice-connectors/{voiceConnectorId}/proxy-sessions
# Returns: record<ProxySession: record<VoiceConnectorId: string, ProxySessionId: string, Name: string, Status: string, ExpiryMinutes: int, Capabilities: list<string>, CreatedTimestamp: string, UpdatedTimestamp: string, EndedTimestamp: string, Participants: list<record>, NumberSelectionBehavior: string, GeoMatchLevel: string, GeoMatchParams: record<Country: string, AreaCode: string>>>
# operationId: CreateProxySession
export def "create-proxy-session" [
  voice_connector_id: string
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
  participant_phone_numbers: list<string> # The participant phone numbers.
  --name: string # The name of the proxy session. (format: password)
  --expiry-minutes: int # The number of minutes allowed for the proxy session.
  capabilities: list<string> # The proxy session capabilities.
  --number-selection-behavior: string@number-selection-behavior-completer # The preference for proxy phone number reuse, or stickiness, between the same participants across sessions.
  --geo-match-level: string@geo-match-level-completer # The preference for matching the country or area code of the proxy phone number with that of the first participant.
  --geo-match-params: record # The country and area code for a proxy phone number in a proxy phone session. — shape: {Country?: string, AreaCode?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/voice-connectors/{voiceConnectorId}/proxy-sessions"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ParticipantPhoneNumbers, var: participant_phone_numbers}, {name: Name, var: name}, {name: ExpiryMinutes, var: expiry_minutes}, {name: Capabilities, var: capabilities}, {name: NumberSelectionBehavior, var: number_selection_behavior}, {name: GeoMatchLevel, var: geo_match_level}, {name: GeoMatchParams, var: geo_match_params}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, participant_phone_numbers: $participant_phone_numbers, name: $name, expiry_minutes: $expiry_minutes, capabilities: $capabilities, number_selection_behavior: $number_selection_behavior, geo_match_level: $geo_match_level, geo_match_params: $geo_match_params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the proxy sessions for the specified Amazon Chime Voice Connector.
#
# GET /voice-connectors/{voiceConnectorId}/proxy-sessions
# Returns: record<ProxySessions: table<VoiceConnectorId: string, ProxySessionId: string, Name: string, Status: string, ExpiryMinutes: int, Capabilities: list, CreatedTimestamp: string, UpdatedTimestamp: string, EndedTimestamp: string, Participants: list, NumberSelectionBehavior: string, GeoMatchLevel: string, GeoMatchParams: record>, NextToken: string>
# operationId: ListProxySessions
export def "list-proxy-sessions" [
  voice_connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # The proxy session status.
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results: int # The maximum number of results to return in a single call.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/voice-connectors/{voiceConnectorId}/proxy-sessions"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    query: [{name: status, var: status}, {name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, status: $status, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a chat room for the specified Amazon Chime Enterprise account.
#
# POST /accounts/{accountId}/rooms
# Returns: record<Room: record<RoomId: string, Name: string, AccountId: string, CreatedBy: string, CreatedTimestamp: string, UpdatedTimestamp: string>>
# operationId: CreateRoom
export def "create-room" [
  account_id: string
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
  name: string # The room name. (format: password)
  --client-request-token: string # The idempotency token for the request. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/rooms"
    path_params: [{name: accountId, var: account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: ClientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the room details for the specified Amazon Chime Enterprise account. Optionally, filter the results by a member ID (user ID or bot ID) to see a list of rooms that the member belongs to.
#
# GET /accounts/{accountId}/rooms
# Returns: record<Rooms: table<RoomId: string, Name: string, AccountId: string, CreatedBy: string, CreatedTimestamp: string, UpdatedTimestamp: string>, NextToken: string>
# operationId: ListRooms
export def "list-rooms" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --member-id: string # The member ID (user ID or bot ID).
  --max-results: int # The maximum number of results to return in a single call.
  --next-token: string # The token to use to retrieve the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/accounts/{accountId}/rooms"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: member-id, var: member_id}, {name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, member_id: $member_id, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a member to a chat room in an Amazon Chime Enterprise account. A member can be either a user or a bot. The member role designates whether the member is a chat room administrator or a general chat room member.
#
# POST /accounts/{accountId}/rooms/{roomId}/memberships
# Returns: record<RoomMembership: record<RoomId: string, Member: record<MemberId: string, MemberType: string, Email: string, FullName: string, AccountId: string>, Role: string, InvitedBy: string, UpdatedTimestamp: string>>
# operationId: CreateRoomMembership
export def "create-room-membership" [
  account_id: string
  room_id: string
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
  member_id: string # The Amazon Chime member ID (user ID or bot ID).
  --role: string@role-completer # The role of the member.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/rooms/{roomId}/memberships"
    path_params: [{name: accountId, var: account_id}, {name: roomId, var: room_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MemberId, var: member_id}, {name: Role, var: role}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, room_id: $room_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, member_id: $member_id, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the membership details for the specified room in an Amazon Chime Enterprise account, such as the members' IDs, email addresses, and names.
#
# GET /accounts/{accountId}/rooms/{roomId}/memberships
# Returns: record<RoomMemberships: table<RoomId: string, Member: record, Role: string, InvitedBy: string, UpdatedTimestamp: string>, NextToken: string>
# operationId: ListRoomMemberships
export def "list-room-memberships" [
  account_id: string
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return in a single call.
  --next-token: string # The token to use to retrieve the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/accounts/{accountId}/rooms/{roomId}/memberships"
    path_params: [{name: accountId, var: account_id}, {name: roomId, var: room_id}]
    query: [{name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, room_id: $room_id, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a SIP media application.
#
# POST /sip-media-applications
# Returns: record<SipMediaApplication: record<SipMediaApplicationId: string, AwsRegion: string, Name: string, Endpoints: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string>>
# operationId: CreateSipMediaApplication
export def "create-sip-media-application" [
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
  aws_region: string # The AWS Region assigned to the SIP media application.
  name: string # The SIP media application name.
  endpoints: list # List of endpoints (Lambda Amazon Resource Names) specified for the SIP media application. Currently, only one endpoint is supported. — item shape: {LambdaArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sip-media-applications"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AwsRegion, var: aws_region}, {name: Name, var: name}, {name: Endpoints, var: endpoints}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, aws_region: $aws_region, name: $name, endpoints: $endpoints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the SIP media applications under the administrator's AWS account.
#
# GET /sip-media-applications
# Returns: record<SipMediaApplications: table<SipMediaApplicationId: string, AwsRegion: string, Name: string, Endpoints: list, CreatedTimestamp: string, UpdatedTimestamp: string>, NextToken: string>
# operationId: ListSipMediaApplications
export def "list-sip-media-applications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return in a single call. Defaults to 100.
  --next-token: string # The token to use to retrieve the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/sip-media-applications"
    query: [{name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an outbound call to a phone number from the phone number specified in the request, and it invokes the endpoint of the specified sipMediaApplicationId.
#
# POST /sip-media-applications/{sipMediaApplicationId}/calls
# Returns: record<SipMediaApplicationCall: record<TransactionId: string>>
# operationId: CreateSipMediaApplicationCall
export def "create-sip-media-application-call" [
  sip_media_application_id: string
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
  from_phone_number: string # The phone number that a user calls from. This is a phone number in your Amazon Chime phone number inventory. (format: password)
  to_phone_number: string # The phone number that the service should call. (format: password)
  --sip-headers: record # The SIP headers added to an outbound call leg.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sip-media-applications/{sipMediaApplicationId}/calls"
    path_params: [{name: sipMediaApplicationId, var: sip_media_application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: FromPhoneNumber, var: from_phone_number}, {name: ToPhoneNumber, var: to_phone_number}, {name: SipHeaders, var: sip_headers}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    sip_media_application_id: $sip_media_application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, from_phone_number: $from_phone_number, to_phone_number: $to_phone_number, sip_headers: $sip_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a SIP rule which can be used to run a SIP media application as a target for a specific trigger type.
#
# POST /sip-rules
# Returns: record<SipRule: record<SipRuleId: string, Name: string, Disabled: bool, TriggerType: string, TriggerValue: string, TargetApplications: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string>>
# operationId: CreateSipRule
export def "create-sip-rule" [
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
  name: string # The name of the SIP rule.
  trigger_type: string@trigger-type-completer # The type of trigger assigned to the SIP rule in TriggerValue, currently RequestUriHostname or ToPhoneNumber.
  trigger_value: string # If TriggerType is RequestUriHostname, the value can be the outbound host name of an Amazon Chime Voice Connector. If TriggerType is ToPhoneNumber, the value can be a customer-owned phone number in the E164 format. The SipMediaApplication specified in the SipRule is triggered if the request URI in an incoming SIP request matches the RequestUriHostname, or if the To header in the incoming SIP request matches the ToPhoneNumber value.
  --disabled: oneof<nothing, bool> # Enables or disables a rule. You must disable rules before you can delete them.
  target_applications: list # List of SIP media applications with priority and AWS Region. Only one SIP application per AWS Region can be used. — item shape: {SipMediaApplicationId?: string, Priority?: int, AwsRegion?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sip-rules"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: TriggerType, var: trigger_type}, {name: TriggerValue, var: trigger_value}, {name: Disabled, var: disabled}, {name: TargetApplications, var: target_applications}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, trigger_type: $trigger_type, trigger_value: $trigger_value, disabled: $disabled, target_applications: $target_applications
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the SIP rules under the administrator's AWS account.
#
# GET /sip-rules
# Returns: record<SipRules: table<SipRuleId: string, Name: string, Disabled: bool, TriggerType: string, TriggerValue: string, TargetApplications: list, CreatedTimestamp: string, UpdatedTimestamp: string>, NextToken: string>
# operationId: ListSipRules
export def "list-sip-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sip-media-application: string # The SIP media application ID.
  --max-results: int # The maximum number of results to return in a single call. Defaults to 100.
  --next-token: string # The token to use to retrieve the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/sip-rules"
    query: [{name: sip-media-application, var: sip_media_application}, {name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sip_media_application: $sip_media_application, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a user under the specified Amazon Chime account.
#
# POST /accounts/{accountId}/users
# Returns: record<User: record<UserId: string, AccountId: string, PrimaryEmail: string, PrimaryProvisionedNumber: string, DisplayName: string, LicenseType: string, UserType: string, UserRegistrationStatus: string, UserInvitationStatus: string, RegisteredOn: string, InvitedOn: string, AlexaForBusinessMetadata: record<IsAlexaForBusinessEnabled: bool, AlexaForBusinessRoomArn: string>, PersonalPIN: string>>
# operationId: CreateUser
export def "create-user" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-9 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --username: string # The user name.
  --email: string # The user's email address. (format: password)
  --user-type: string@user-type-completer # The user type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/users"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: operation, var: operation, required: true, default: create}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Username, var: username}, {name: Email, var: email}, {name: UserType, var: user_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, username: $username, email: $email, user_type: $user_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region. Enabling CreateVoiceConnectorRequest$RequireEncryption configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.
#
# POST /voice-connectors
# Returns: record<VoiceConnector: record<VoiceConnectorId: string, AwsRegion: string, Name: string, OutboundHostName: string, RequireEncryption: bool, CreatedTimestamp: string, UpdatedTimestamp: string, VoiceConnectorArn: string>>
# operationId: CreateVoiceConnector
export def "create-voice-connector" [
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
  name: string # The name of the Amazon Chime Voice Connector.
  --aws-region: string@aws-region-completer # The AWS Region in which the Amazon Chime Voice Connector is created. Default value: us-east-1 .
  --require-encryption: oneof<nothing, bool> # When enabled, requires encryption for the Amazon Chime Voice Connector.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/voice-connectors"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: AwsRegion, var: aws_region}, {name: RequireEncryption, var: require_encryption, required: true}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, aws_region: $aws_region, require_encryption: $require_encryption
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Amazon Chime Voice Connectors for the administrator's AWS account.
#
# GET /voice-connectors
# Returns: record<VoiceConnectors: table<VoiceConnectorId: string, AwsRegion: string, Name: string, OutboundHostName: string, RequireEncryption: bool, CreatedTimestamp: string, UpdatedTimestamp: string, VoiceConnectorArn: string>, NextToken: string>
# operationId: ListVoiceConnectors
export def "list-voice-connectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results: int # The maximum number of results to return in a single call.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/voice-connectors"
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including VoiceConnectorItems in the request. You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.
#
# POST /voice-connector-groups
# Returns: record<VoiceConnectorGroup: record<VoiceConnectorGroupId: string, Name: string, VoiceConnectorItems: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string, VoiceConnectorGroupArn: string>>
# operationId: CreateVoiceConnectorGroup
export def "create-voice-connector-group" [
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
  name: string # The name of the Amazon Chime Voice Connector group.
  --voice-connector-items: list # The Amazon Chime Voice Connectors to route inbound calls to. — item shape: {VoiceConnectorId: string, Priority: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/voice-connector-groups"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: VoiceConnectorItems, var: voice_connector_items}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, voice_connector_items: $voice_connector_items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Amazon Chime Voice Connector groups for the administrator's AWS account.
#
# GET /voice-connector-groups
# Returns: record<VoiceConnectorGroups: table<VoiceConnectorGroupId: string, Name: string, VoiceConnectorItems: list, CreatedTimestamp: string, UpdatedTimestamp: string, VoiceConnectorGroupArn: string>, NextToken: string>
# operationId: ListVoiceConnectorGroups
export def "list-voice-connector-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results: int # The maximum number of results to return in a single call.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/voice-connector-groups"
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified Amazon Chime account. You must suspend all users before deleting Team account. You can use the BatchSuspendUser action to dodo. For EnterpriseLWA and EnterpriseAD accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended. Deleted accounts appear in your Disabled accounts list for 90 days. To restore deleted account from your Disabled accounts list, you must contact AWS Support. After 90 days, deleted accounts are permanently removed from your Disabled accounts list.
#
# DELETE /accounts/{accountId}
# Returns: record
# operationId: DeleteAccount
export def "delete-account" [
  account_id: string
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
    method: delete
    path: "/accounts/{accountId}"
    path_params: [{name: accountId, var: account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
#
# GET /accounts/{accountId}
# Returns: record<Account: record<AwsAccountId: string, AccountId: string, Name: string, AccountType: string, CreatedTimestamp: string, DefaultLicense: string, SupportedLicenses: list<string>, AccountStatus: string, SigninDelegateGroups: list<record>>>
# operationId: GetAccount
export def "get-account" [
  account_id: string
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
    path: "/accounts/{accountId}"
    path_params: [{name: accountId, var: account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates account details for the specified Amazon Chime account. Currently, only account name and default license updates are supported for this action.
#
# POST /accounts/{accountId}
# Returns: record<Account: record<AwsAccountId: string, AccountId: string, Name: string, AccountType: string, CreatedTimestamp: string, DefaultLicense: string, SupportedLicenses: list<string>, AccountStatus: string, SigninDelegateGroups: list<record>>>
# operationId: UpdateAccount
export def "update-account" [
  account_id: string
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
  --name: string # The new name for the specified Amazon Chime account.
  --default-license: string@default-license-completer # The default license applied when you add users to an Amazon Chime account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}"
    path_params: [{name: accountId, var: account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: DefaultLicense, var: default_license}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, default_license: $default_license
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an AppInstance and all associated data asynchronously.
#
# DELETE /app-instances/{appInstanceArn}
# operationId: DeleteAppInstance
export def "delete-app-instance" [
  app_instance_arn: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/app-instances/{appInstanceArn}"
    path_params: [{name: appInstanceArn, var: app_instance_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    app_instance_arn: $app_instance_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the full details of an AppInstance.
#
# GET /app-instances/{appInstanceArn}
# Returns: record<AppInstance: record<AppInstanceArn: string, Name: string, Metadata: string, CreatedTimestamp: string, LastUpdatedTimestamp: string>>
# operationId: DescribeAppInstance
export def "describe-app-instance" [
  app_instance_arn: string
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
    path: "/app-instances/{appInstanceArn}"
    path_params: [{name: appInstanceArn, var: app_instance_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_instance_arn: $app_instance_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates AppInstance metadata.
#
# PUT /app-instances/{appInstanceArn}
# Returns: record<AppInstanceArn: string>
# operationId: UpdateAppInstance
export def "update-app-instance" [
  app_instance_arn: string
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
  name: string # The name that you want to change. (format: password)
  --metadata: string # The metadata that you want to change. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/app-instances/{appInstanceArn}"
    path_params: [{name: appInstanceArn, var: app_instance_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_instance_arn: $app_instance_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Demotes an AppInstanceAdmin to an AppInstanceUser. This action does not delete the user.
#
# DELETE /app-instances/{appInstanceArn}/admins/{appInstanceAdminArn}
# operationId: DeleteAppInstanceAdmin
export def "delete-app-instance-admin" [
  app_instance_arn: string
  app_instance_admin_arn: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/app-instances/{appInstanceArn}/admins/{appInstanceAdminArn}"
    path_params: [{name: appInstanceArn, var: app_instance_arn}, {name: appInstanceAdminArn, var: app_instance_admin_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    app_instance_arn: $app_instance_arn, app_instance_admin_arn: $app_instance_admin_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the full details of an AppInstanceAdmin.
#
# GET /app-instances/{appInstanceArn}/admins/{appInstanceAdminArn}
# Returns: record<AppInstanceAdmin: record<Admin: record<Arn: string, Name: string>, AppInstanceArn: string, CreatedTimestamp: string>>
# operationId: DescribeAppInstanceAdmin
export def "describe-app-instance-admin" [
  app_instance_arn: string
  app_instance_admin_arn: string
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
    path: "/app-instances/{appInstanceArn}/admins/{appInstanceAdminArn}"
    path_params: [{name: appInstanceArn, var: app_instance_arn}, {name: appInstanceAdminArn, var: app_instance_admin_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_instance_arn: $app_instance_arn, app_instance_admin_arn: $app_instance_admin_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the streaming configurations of an AppInstance.
#
# DELETE /app-instances/{appInstanceArn}/streaming-configurations
# operationId: DeleteAppInstanceStreamingConfigurations
export def "delete-app-instance-streaming-configurations" [
  app_instance_arn: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/app-instances/{appInstanceArn}/streaming-configurations"
    path_params: [{name: appInstanceArn, var: app_instance_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    app_instance_arn: $app_instance_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the streaming settings for an AppInstance.
#
# GET /app-instances/{appInstanceArn}/streaming-configurations
# Returns: record<AppInstanceStreamingConfigurations: table<AppInstanceDataType: string, ResourceArn: string>>
# operationId: GetAppInstanceStreamingConfigurations
export def "get-app-instance-streaming-configurations" [
  app_instance_arn: string
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
    path: "/app-instances/{appInstanceArn}/streaming-configurations"
    path_params: [{name: appInstanceArn, var: app_instance_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_instance_arn: $app_instance_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The data streaming configurations of an AppInstance.
#
# PUT /app-instances/{appInstanceArn}/streaming-configurations
# Returns: record<AppInstanceStreamingConfigurations: table<AppInstanceDataType: string, ResourceArn: string>>
# operationId: PutAppInstanceStreamingConfigurations
export def "put-app-instance-streaming-configurations" [
  app_instance_arn: string
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
  app_instance_streaming_configurations: list # The streaming configurations set for an AppInstance. — item shape: {AppInstanceDataType: "Channel"|"ChannelMessage", ResourceArn: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/app-instances/{appInstanceArn}/streaming-configurations"
    path_params: [{name: appInstanceArn, var: app_instance_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AppInstanceStreamingConfigurations, var: app_instance_streaming_configurations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_instance_arn: $app_instance_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, app_instance_streaming_configurations: $app_instance_streaming_configurations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an AppInstanceUser.
#
# DELETE /app-instance-users/{appInstanceUserArn}
# operationId: DeleteAppInstanceUser
export def "delete-app-instance-user" [
  app_instance_user_arn: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/app-instance-users/{appInstanceUserArn}"
    path_params: [{name: appInstanceUserArn, var: app_instance_user_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    app_instance_user_arn: $app_instance_user_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the full details of an AppInstanceUser.
#
# GET /app-instance-users/{appInstanceUserArn}
# Returns: record<AppInstanceUser: record<AppInstanceUserArn: string, Name: string, CreatedTimestamp: string, Metadata: string, LastUpdatedTimestamp: string>>
# operationId: DescribeAppInstanceUser
export def "describe-app-instance-user" [
  app_instance_user_arn: string
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
    path: "/app-instance-users/{appInstanceUserArn}"
    path_params: [{name: appInstanceUserArn, var: app_instance_user_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_instance_user_arn: $app_instance_user_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the details of an AppInstanceUser. You can update names and metadata.
#
# PUT /app-instance-users/{appInstanceUserArn}
# Returns: record<AppInstanceUserArn: string>
# operationId: UpdateAppInstanceUser
export def "update-app-instance-user" [
  app_instance_user_arn: string
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
  name: string # The name of the AppInstanceUser. (format: password)
  --metadata: string # The metadata of the AppInstanceUser. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/app-instance-users/{appInstanceUserArn}"
    path_params: [{name: appInstanceUserArn, var: app_instance_user_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_instance_user_arn: $app_instance_user_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an attendee from the specified Amazon Chime SDK meeting and deletes their JoinToken. Attendees are automatically deleted when a Amazon Chime SDK meeting is deleted. For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide.
#
# DELETE /meetings/{meetingId}/attendees/{attendeeId}
# operationId: DeleteAttendee
export def "delete-attendee" [
  meeting_id: string
  attendee_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/meetings/{meetingId}/attendees/{attendeeId}"
    path_params: [{name: meetingId, var: meeting_id}, {name: attendeeId, var: attendee_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    meeting_id: $meeting_id, attendee_id: $attendee_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Amazon Chime SDK attendee details for a specified meeting ID and attendee ID. For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide .
#
# GET /meetings/{meetingId}/attendees/{attendeeId}
# Returns: record<Attendee: record<ExternalUserId: string, AttendeeId: string, JoinToken: string>>
# operationId: GetAttendee
export def "get-attendee" [
  meeting_id: string
  attendee_id: string
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
    path: "/meetings/{meetingId}/attendees/{attendeeId}"
    path_params: [{name: meetingId, var: meeting_id}, {name: attendeeId, var: attendee_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id, attendee_id: $attendee_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Immediately makes a channel and its memberships inaccessible and marks them for deletion. This is an irreversible process. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# DELETE /channels/{channelArn}
# operationId: DeleteChannel
export def "delete-channel" [
  channel_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> any {
  http-request {
    method: delete
    path: "/channels/{channelArn}"
    path_params: [{name: channelArn, var: channel_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_arn: $channel_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the full details of a channel in an Amazon Chime AppInstance. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}
# Returns: record<Channel: record<Name: string, ChannelArn: string, Mode: string, Privacy: string, Metadata: string, CreatedBy: record<Arn: string, Name: string>, CreatedTimestamp: string, LastMessageTimestamp: string, LastUpdatedTimestamp: string>>
# operationId: DescribeChannel
export def "describe-channel" [
  channel_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channelArn}"
    path_params: [{name: channelArn, var: channel_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_arn: $channel_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a channel's attributes. Restriction: You can't change a channel's privacy. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# PUT /channels/{channelArn}
# Returns: record<ChannelArn: string>
# operationId: UpdateChannel
export def "update-channel" [
  channel_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
  name: string # The name of the channel. (format: password)
  mode: string@mode-completer # The mode of the update request.
  --metadata: string # The metadata for the update request. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/channels/{channelArn}"
    path_params: [{name: channelArn, var: channel_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Mode, var: mode}, {name: Metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_arn: $channel_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer, name: $name, mode: $mode, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user from a channel's ban list. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# DELETE /channels/{channelArn}/bans/{memberArn}
# operationId: DeleteChannelBan
export def "delete-channel-ban" [
  channel_arn: string
  member_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> any {
  http-request {
    method: delete
    path: "/channels/{channelArn}/bans/{memberArn}"
    path_params: [{name: channelArn, var: channel_arn}, {name: memberArn, var: member_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_arn: $channel_arn, member_arn: $member_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the full details of a channel ban. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}/bans/{memberArn}
# Returns: record<ChannelBan: record<Member: record<Arn: string, Name: string>, ChannelArn: string, CreatedTimestamp: string, CreatedBy: record<Arn: string, Name: string>>>
# operationId: DescribeChannelBan
export def "describe-channel-ban" [
  channel_arn: string
  member_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channelArn}/bans/{memberArn}"
    path_params: [{name: channelArn, var: channel_arn}, {name: memberArn, var: member_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_arn: $channel_arn, member_arn: $member_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a member from a channel. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# DELETE /channels/{channelArn}/memberships/{memberArn}
# operationId: DeleteChannelMembership
export def "delete-channel-membership" [
  channel_arn: string
  member_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> any {
  http-request {
    method: delete
    path: "/channels/{channelArn}/memberships/{memberArn}"
    path_params: [{name: channelArn, var: channel_arn}, {name: memberArn, var: member_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_arn: $channel_arn, member_arn: $member_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the full details of a user's channel membership. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}/memberships/{memberArn}
# Returns: record<ChannelMembership: record<InvitedBy: record<Arn: string, Name: string>, Type: string, Member: record<Arn: string, Name: string>, ChannelArn: string, CreatedTimestamp: string, LastUpdatedTimestamp: string>>
# operationId: DescribeChannelMembership
export def "describe-channel-membership" [
  channel_arn: string
  member_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channelArn}/memberships/{memberArn}"
    path_params: [{name: channelArn, var: channel_arn}, {name: memberArn, var: member_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_arn: $channel_arn, member_arn: $member_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a channel message. Only admins can perform this action. Deletion makes messages inaccessible immediately. A background process deletes any revisions created by UpdateChannelMessage. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# DELETE /channels/{channelArn}/messages/{messageId}
# operationId: DeleteChannelMessage
export def "delete-channel-message" [
  channel_arn: string
  message_id: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> any {
  http-request {
    method: delete
    path: "/channels/{channelArn}/messages/{messageId}"
    path_params: [{name: channelArn, var: channel_arn}, {name: messageId, var: message_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_arn: $channel_arn, message_id: $message_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the full details of a channel message. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}/messages/{messageId}
# Returns: record<ChannelMessage: record<ChannelArn: string, MessageId: string, Content: string, Metadata: string, Type: string, CreatedTimestamp: string, LastEditedTimestamp: string, LastUpdatedTimestamp: string, Sender: record<Arn: string, Name: string>, Redacted: bool, Persistence: string>>
# operationId: GetChannelMessage
export def "get-channel-message" [
  channel_arn: string
  message_id: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channelArn}/messages/{messageId}"
    path_params: [{name: channelArn, var: channel_arn}, {name: messageId, var: message_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_arn: $channel_arn, message_id: $message_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the content of a message. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# PUT /channels/{channelArn}/messages/{messageId}
# Returns: record<ChannelArn: string, MessageId: string>
# operationId: UpdateChannelMessage
export def "update-channel-message" [
  channel_arn: string
  message_id: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
  --content: string # The content of the message being updated. (format: password)
  --metadata: string # The metadata of the message being updated. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/channels/{channelArn}/messages/{messageId}"
    path_params: [{name: channelArn, var: channel_arn}, {name: messageId, var: message_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    body: {content_type: "application/json", kind: json, fields: [{name: Content, var: content}, {name: Metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_arn: $channel_arn, message_id: $message_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer, content: $content, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a channel moderator. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# DELETE /channels/{channelArn}/moderators/{channelModeratorArn}
# operationId: DeleteChannelModerator
export def "delete-channel-moderator" [
  channel_arn: string
  channel_moderator_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> any {
  http-request {
    method: delete
    path: "/channels/{channelArn}/moderators/{channelModeratorArn}"
    path_params: [{name: channelArn, var: channel_arn}, {name: channelModeratorArn, var: channel_moderator_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_arn: $channel_arn, channel_moderator_arn: $channel_moderator_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the full details of a single ChannelModerator. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}/moderators/{channelModeratorArn}
# Returns: record<ChannelModerator: record<Moderator: record<Arn: string, Name: string>, ChannelArn: string, CreatedTimestamp: string, CreatedBy: record<Arn: string, Name: string>>>
# operationId: DescribeChannelModerator
export def "describe-channel-moderator" [
  channel_arn: string
  channel_moderator_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channelArn}/moderators/{channelModeratorArn}"
    path_params: [{name: channelArn, var: channel_arn}, {name: channelModeratorArn, var: channel_moderator_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_arn: $channel_arn, channel_moderator_arn: $channel_moderator_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the events configuration that allows a bot to receive outgoing events.
#
# DELETE /accounts/{accountId}/bots/{botId}/events-configuration
# operationId: DeleteEventsConfiguration
export def "delete-events-configuration" [
  account_id: string
  bot_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/accounts/{accountId}/bots/{botId}/events-configuration"
    path_params: [{name: accountId, var: account_id}, {name: botId, var: bot_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, bot_id: $bot_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN.
#
# GET /accounts/{accountId}/bots/{botId}/events-configuration
# Returns: record<EventsConfiguration: record<BotId: string, OutboundEventsHTTPSEndpoint: string, LambdaFunctionArn: string>>
# operationId: GetEventsConfiguration
export def "get-events-configuration" [
  account_id: string
  bot_id: string
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
    path: "/accounts/{accountId}/bots/{botId}/events-configuration"
    path_params: [{name: accountId, var: account_id}, {name: botId, var: bot_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, bot_id: $bot_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see Bot.
#
# PUT /accounts/{accountId}/bots/{botId}/events-configuration
# Returns: record<EventsConfiguration: record<BotId: string, OutboundEventsHTTPSEndpoint: string, LambdaFunctionArn: string>>
# operationId: PutEventsConfiguration
export def "put-events-configuration" [
  account_id: string
  bot_id: string
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
  --outbound-events-https-endpoint: string # HTTPS endpoint that allows the bot to receive outgoing events. (format: password)
  --lambda-function-arn: string # Lambda function ARN that allows the bot to receive outgoing events. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{accountId}/bots/{botId}/events-configuration"
    path_params: [{name: accountId, var: account_id}, {name: botId, var: bot_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: OutboundEventsHTTPSEndpoint, var: outbound_events_https_endpoint}, {name: LambdaFunctionArn, var: lambda_function_arn}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, bot_id: $bot_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, outbound_events_https_endpoint: $outbound_events_https_endpoint, lambda_function_arn: $lambda_function_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the media capture pipeline.
#
# DELETE /media-capture-pipelines/{mediaPipelineId}
# operationId: DeleteMediaCapturePipeline
export def "delete-media-capture-pipeline" [
  media_pipeline_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/media-capture-pipelines/{mediaPipelineId}"
    path_params: [{name: mediaPipelineId, var: media_pipeline_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    media_pipeline_id: $media_pipeline_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an existing media capture pipeline.
#
# GET /media-capture-pipelines/{mediaPipelineId}
# Returns: record<MediaCapturePipeline: record<MediaPipelineId: string, SourceType: string, SourceArn: string, Status: string, SinkType: string, SinkArn: string, CreatedTimestamp: string, UpdatedTimestamp: string, ChimeSdkMeetingConfiguration: record<SourceConfiguration: record, ArtifactsConfiguration: record>>>
# operationId: GetMediaCapturePipeline
export def "get-media-capture-pipeline" [
  media_pipeline_id: string
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
    path: "/media-capture-pipelines/{mediaPipelineId}"
    path_params: [{name: mediaPipelineId, var: media_pipeline_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    media_pipeline_id: $media_pipeline_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified Amazon Chime SDK meeting. The operation deletes all attendees, disconnects all clients, and prevents new clients from joining the meeting. For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide.
#
# DELETE /meetings/{meetingId}
# operationId: DeleteMeeting
export def "delete-meeting" [
  meeting_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/meetings/{meetingId}"
    path_params: [{name: meetingId, var: meeting_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    meeting_id: $meeting_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Amazon Chime SDK meeting details for the specified meeting ID. For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide .
#
# GET /meetings/{meetingId}
# Returns: record<Meeting: record<MeetingId: string, ExternalMeetingId: string, MediaPlacement: record<AudioHostUrl: string, AudioFallbackUrl: string, ScreenDataUrl: string, ScreenSharingUrl: string, ScreenViewingUrl: string, SignalingUrl: string, TurnControlUrl: string, EventIngestionUrl: string>, MediaRegion: string>>
# operationId: GetMeeting
export def "get-meeting" [
  meeting_id: string
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
    path: "/meetings/{meetingId}"
    path_params: [{name: meetingId, var: meeting_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves the specified phone number into the Deletion queue. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted. Deleted phone numbers remain in the Deletion queue for 7 days before they are deleted permanently.
#
# DELETE /phone-numbers/{phoneNumberId}
# operationId: DeletePhoneNumber
export def "delete-phone-number" [
  phone_number_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/phone-numbers/{phoneNumberId}"
    path_params: [{name: phoneNumberId, var: phone_number_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    phone_number_id: $phone_number_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
#
# GET /phone-numbers/{phoneNumberId}
# Returns: record<PhoneNumber: record<PhoneNumberId: string, E164PhoneNumber: string, Country: string, Type: string, ProductType: string, Status: string, Capabilities: record<InboundCall: bool, OutboundCall: bool, InboundSMS: bool, OutboundSMS: bool, InboundMMS: bool, OutboundMMS: bool>, Associations: list<record>, CallingName: string, CallingNameStatus: string, CreatedTimestamp: string, UpdatedTimestamp: string, DeletionTimestamp: string>>
# operationId: GetPhoneNumber
export def "get-phone-number" [
  phone_number_id: string
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
    path: "/phone-numbers/{phoneNumberId}"
    path_params: [{name: phoneNumberId, var: phone_number_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    phone_number_id: $phone_number_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates phone number details, such as product type or calling name, for the specified phone number ID. You can update one phone number detail at a time. For example, you can update either the product type or the calling name in one action. For toll-free numbers, you cannot use the Amazon Chime Business Calling product type. For numbers outside the U.S., you must use the Amazon Chime SIP Media Application Dial-In product type. Updates to outbound calling names can take 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.
#
# POST /phone-numbers/{phoneNumberId}
# Returns: record<PhoneNumber: record<PhoneNumberId: string, E164PhoneNumber: string, Country: string, Type: string, ProductType: string, Status: string, Capabilities: record<InboundCall: bool, OutboundCall: bool, InboundSMS: bool, OutboundSMS: bool, InboundMMS: bool, OutboundMMS: bool>, Associations: list<record>, CallingName: string, CallingNameStatus: string, CreatedTimestamp: string, UpdatedTimestamp: string, DeletionTimestamp: string>>
# operationId: UpdatePhoneNumber
export def "update-phone-number" [
  phone_number_id: string
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
  --product-type: string@product-type-completer # The product type.
  --calling-name: string # The outbound calling name associated with the phone number. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone-numbers/{phoneNumberId}"
    path_params: [{name: phoneNumberId, var: phone_number_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ProductType, var: product_type}, {name: CallingName, var: calling_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    phone_number_id: $phone_number_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, product_type: $product_type, calling_name: $calling_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified proxy session from the specified Amazon Chime Voice Connector.
#
# DELETE /voice-connectors/{voiceConnectorId}/proxy-sessions/{proxySessionId}
# operationId: DeleteProxySession
export def "delete-proxy-session" [
  voice_connector_id: string
  proxy_session_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/voice-connectors/{voiceConnectorId}/proxy-sessions/{proxySessionId}"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}, {name: proxySessionId, var: proxy_session_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, proxy_session_id: $proxy_session_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified proxy session details for the specified Amazon Chime Voice Connector.
#
# GET /voice-connectors/{voiceConnectorId}/proxy-sessions/{proxySessionId}
# Returns: record<ProxySession: record<VoiceConnectorId: string, ProxySessionId: string, Name: string, Status: string, ExpiryMinutes: int, Capabilities: list<string>, CreatedTimestamp: string, UpdatedTimestamp: string, EndedTimestamp: string, Participants: list<record>, NumberSelectionBehavior: string, GeoMatchLevel: string, GeoMatchParams: record<Country: string, AreaCode: string>>>
# operationId: GetProxySession
export def "get-proxy-session" [
  voice_connector_id: string
  proxy_session_id: string
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
    path: "/voice-connectors/{voiceConnectorId}/proxy-sessions/{proxySessionId}"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}, {name: proxySessionId, var: proxy_session_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, proxy_session_id: $proxy_session_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified proxy session details, such as voice or SMS capabilities.
#
# POST /voice-connectors/{voiceConnectorId}/proxy-sessions/{proxySessionId}
# Returns: record<ProxySession: record<VoiceConnectorId: string, ProxySessionId: string, Name: string, Status: string, ExpiryMinutes: int, Capabilities: list<string>, CreatedTimestamp: string, UpdatedTimestamp: string, EndedTimestamp: string, Participants: list<record>, NumberSelectionBehavior: string, GeoMatchLevel: string, GeoMatchParams: record<Country: string, AreaCode: string>>>
# operationId: UpdateProxySession
export def "update-proxy-session" [
  voice_connector_id: string
  proxy_session_id: string
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
  capabilities: list<string> # The proxy session capabilities.
  --expiry-minutes: int # The number of minutes allowed for the proxy session.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/voice-connectors/{voiceConnectorId}/proxy-sessions/{proxySessionId}"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}, {name: proxySessionId, var: proxy_session_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Capabilities, var: capabilities}, {name: ExpiryMinutes, var: expiry_minutes}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, proxy_session_id: $proxy_session_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, capabilities: $capabilities, expiry_minutes: $expiry_minutes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a chat room in an Amazon Chime Enterprise account.
#
# DELETE /accounts/{accountId}/rooms/{roomId}
# operationId: DeleteRoom
export def "delete-room" [
  account_id: string
  room_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/accounts/{accountId}/rooms/{roomId}"
    path_params: [{name: accountId, var: account_id}, {name: roomId, var: room_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, room_id: $room_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves room details, such as the room name, for a room in an Amazon Chime Enterprise account.
#
# GET /accounts/{accountId}/rooms/{roomId}
# Returns: record<Room: record<RoomId: string, Name: string, AccountId: string, CreatedBy: string, CreatedTimestamp: string, UpdatedTimestamp: string>>
# operationId: GetRoom
export def "get-room" [
  account_id: string
  room_id: string
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
    path: "/accounts/{accountId}/rooms/{roomId}"
    path_params: [{name: accountId, var: account_id}, {name: roomId, var: room_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, room_id: $room_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates room details, such as the room name, for a room in an Amazon Chime Enterprise account.
#
# POST /accounts/{accountId}/rooms/{roomId}
# Returns: record<Room: record<RoomId: string, Name: string, AccountId: string, CreatedBy: string, CreatedTimestamp: string, UpdatedTimestamp: string>>
# operationId: UpdateRoom
export def "update-room" [
  account_id: string
  room_id: string
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
  --name: string # The room name. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/rooms/{roomId}"
    path_params: [{name: accountId, var: account_id}, {name: roomId, var: room_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, room_id: $room_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a member from a chat room in an Amazon Chime Enterprise account.
#
# DELETE /accounts/{accountId}/rooms/{roomId}/memberships/{memberId}
# operationId: DeleteRoomMembership
export def "delete-room-membership" [
  account_id: string
  room_id: string
  member_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/accounts/{accountId}/rooms/{roomId}/memberships/{memberId}"
    path_params: [{name: accountId, var: account_id}, {name: roomId, var: room_id}, {name: memberId, var: member_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, room_id: $room_id, member_id: $member_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates room membership details, such as the member role, for a room in an Amazon Chime Enterprise account. The member role designates whether the member is a chat room administrator or a general chat room member. The member role can be updated only for user IDs.
#
# POST /accounts/{accountId}/rooms/{roomId}/memberships/{memberId}
# Returns: record<RoomMembership: record<RoomId: string, Member: record<MemberId: string, MemberType: string, Email: string, FullName: string, AccountId: string>, Role: string, InvitedBy: string, UpdatedTimestamp: string>>
# operationId: UpdateRoomMembership
export def "update-room-membership" [
  account_id: string
  room_id: string
  member_id: string
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
  --role: string@role-completer # The role of the member.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/rooms/{roomId}/memberships/{memberId}"
    path_params: [{name: accountId, var: account_id}, {name: roomId, var: room_id}, {name: memberId, var: member_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Role, var: role}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, room_id: $room_id, member_id: $member_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a SIP media application.
#
# DELETE /sip-media-applications/{sipMediaApplicationId}
# operationId: DeleteSipMediaApplication
export def "delete-sip-media-application" [
  sip_media_application_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/sip-media-applications/{sipMediaApplicationId}"
    path_params: [{name: sipMediaApplicationId, var: sip_media_application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    sip_media_application_id: $sip_media_application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the information for a SIP media application, including name, AWS Region, and endpoints.
#
# GET /sip-media-applications/{sipMediaApplicationId}
# Returns: record<SipMediaApplication: record<SipMediaApplicationId: string, AwsRegion: string, Name: string, Endpoints: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string>>
# operationId: GetSipMediaApplication
export def "get-sip-media-application" [
  sip_media_application_id: string
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
    path: "/sip-media-applications/{sipMediaApplicationId}"
    path_params: [{name: sipMediaApplicationId, var: sip_media_application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sip_media_application_id: $sip_media_application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the details of the specified SIP media application.
#
# PUT /sip-media-applications/{sipMediaApplicationId}
# Returns: record<SipMediaApplication: record<SipMediaApplicationId: string, AwsRegion: string, Name: string, Endpoints: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string>>
# operationId: UpdateSipMediaApplication
export def "update-sip-media-application" [
  sip_media_application_id: string
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
  --name: string # The new name for the specified SIP media application.
  --endpoints: list # The new set of endpoints for the specified SIP media application. — item shape: {LambdaArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sip-media-applications/{sipMediaApplicationId}"
    path_params: [{name: sipMediaApplicationId, var: sip_media_application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Endpoints, var: endpoints}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sip_media_application_id: $sip_media_application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, endpoints: $endpoints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a SIP rule. You must disable a SIP rule before you can delete it.
#
# DELETE /sip-rules/{sipRuleId}
# operationId: DeleteSipRule
export def "delete-sip-rule" [
  sip_rule_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/sip-rules/{sipRuleId}"
    path_params: [{name: sipRuleId, var: sip_rule_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    sip_rule_id: $sip_rule_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details of a SIP rule, such as the rule ID, name, triggers, and target endpoints.
#
# GET /sip-rules/{sipRuleId}
# Returns: record<SipRule: record<SipRuleId: string, Name: string, Disabled: bool, TriggerType: string, TriggerValue: string, TargetApplications: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string>>
# operationId: GetSipRule
export def "get-sip-rule" [
  sip_rule_id: string
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
    path: "/sip-rules/{sipRuleId}"
    path_params: [{name: sipRuleId, var: sip_rule_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sip_rule_id: $sip_rule_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the details of the specified SIP rule.
#
# PUT /sip-rules/{sipRuleId}
# Returns: record<SipRule: record<SipRuleId: string, Name: string, Disabled: bool, TriggerType: string, TriggerValue: string, TargetApplications: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string>>
# operationId: UpdateSipRule
export def "update-sip-rule" [
  sip_rule_id: string
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
  name: string # The new name for the specified SIP rule.
  --disabled: oneof<nothing, bool> # The new value specified to indicate whether the rule is disabled.
  --target-applications: list # The new value of the list of target applications. — item shape: {SipMediaApplicationId?: string, Priority?: int, AwsRegion?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sip-rules/{sipRuleId}"
    path_params: [{name: sipRuleId, var: sip_rule_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Disabled, var: disabled}, {name: TargetApplications, var: target_applications}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    sip_rule_id: $sip_rule_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, disabled: $disabled, target_applications: $target_applications
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified Amazon Chime Voice Connector. Any phone numbers associated with the Amazon Chime Voice Connector must be disassociated from it before it can be deleted.
#
# DELETE /voice-connectors/{voiceConnectorId}
# operationId: DeleteVoiceConnector
export def "delete-voice-connector" [
  voice_connector_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/voice-connectors/{voiceConnectorId}"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps,name, outbound host, and encryption requirements.
#
# GET /voice-connectors/{voiceConnectorId}
# Returns: record<VoiceConnector: record<VoiceConnectorId: string, AwsRegion: string, Name: string, OutboundHostName: string, RequireEncryption: bool, CreatedTimestamp: string, UpdatedTimestamp: string, VoiceConnectorArn: string>>
# operationId: GetVoiceConnector
export def "get-voice-connector" [
  voice_connector_id: string
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
    path: "/voice-connectors/{voiceConnectorId}"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates details for the specified Amazon Chime Voice Connector.
#
# PUT /voice-connectors/{voiceConnectorId}
# Returns: record<VoiceConnector: record<VoiceConnectorId: string, AwsRegion: string, Name: string, OutboundHostName: string, RequireEncryption: bool, CreatedTimestamp: string, UpdatedTimestamp: string, VoiceConnectorArn: string>>
# operationId: UpdateVoiceConnector
export def "update-voice-connector" [
  voice_connector_id: string
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
  name: string # The name of the Amazon Chime Voice Connector.
  --require-encryption: oneof<nothing, bool> # When enabled, requires encryption for the Amazon Chime Voice Connector.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/voice-connectors/{voiceConnectorId}"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: RequireEncryption, var: require_encryption, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, require_encryption: $require_encryption
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the emergency calling configuration details from the specified Amazon Chime Voice Connector.
#
# DELETE /voice-connectors/{voiceConnectorId}/emergency-calling-configuration
# operationId: DeleteVoiceConnectorEmergencyCallingConfiguration
export def "delete-voice-connector-emergency-calling-configuration" [
  voice_connector_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/voice-connectors/{voiceConnectorId}/emergency-calling-configuration"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the emergency calling configuration details for the specified Amazon Chime Voice Connector.
#
# GET /voice-connectors/{voiceConnectorId}/emergency-calling-configuration
# Returns: record<EmergencyCallingConfiguration: record<DNIS: list<record>>>
# operationId: GetVoiceConnectorEmergencyCallingConfiguration
export def "get-voice-connector-emergency-calling-configuration" [
  voice_connector_id: string
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
    path: "/voice-connectors/{voiceConnectorId}/emergency-calling-configuration"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Puts emergency calling configuration details to the specified Amazon Chime Voice Connector, such as emergency phone numbers and calling countries. Origination and termination settings must be enabled for the Amazon Chime Voice Connector before emergency calling can be configured.
#
# PUT /voice-connectors/{voiceConnectorId}/emergency-calling-configuration
# Returns: record<EmergencyCallingConfiguration: record<DNIS: list<record>>>
# operationId: PutVoiceConnectorEmergencyCallingConfiguration
export def "put-voice-connector-emergency-calling-configuration" [
  voice_connector_id: string
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
  emergency_calling_configuration: record # The emergency calling configuration details associated with an Amazon Chime Voice Connector. — shape: {DNIS?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/voice-connectors/{voiceConnectorId}/emergency-calling-configuration"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: EmergencyCallingConfiguration, var: emergency_calling_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, emergency_calling_configuration: $emergency_calling_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified Amazon Chime Voice Connector group. Any VoiceConnectorItems and phone numbers associated with the group must be removed before it can be deleted.
#
# DELETE /voice-connector-groups/{voiceConnectorGroupId}
# operationId: DeleteVoiceConnectorGroup
export def "delete-voice-connector-group" [
  voice_connector_group_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/voice-connector-groups/{voiceConnectorGroupId}"
    path_params: [{name: voiceConnectorGroupId, var: voice_connector_group_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    voice_connector_group_id: $voice_connector_group_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps,name, and associated VoiceConnectorItems.
#
# GET /voice-connector-groups/{voiceConnectorGroupId}
# Returns: record<VoiceConnectorGroup: record<VoiceConnectorGroupId: string, Name: string, VoiceConnectorItems: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string, VoiceConnectorGroupArn: string>>
# operationId: GetVoiceConnectorGroup
export def "get-voice-connector-group" [
  voice_connector_group_id: string
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
    path: "/voice-connector-groups/{voiceConnectorGroupId}"
    path_params: [{name: voiceConnectorGroupId, var: voice_connector_group_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_group_id: $voice_connector_group_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates details of the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
#
# PUT /voice-connector-groups/{voiceConnectorGroupId}
# Returns: record<VoiceConnectorGroup: record<VoiceConnectorGroupId: string, Name: string, VoiceConnectorItems: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string, VoiceConnectorGroupArn: string>>
# operationId: UpdateVoiceConnectorGroup
export def "update-voice-connector-group" [
  voice_connector_group_id: string
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
  name: string # The name of the Amazon Chime Voice Connector group.
  voice_connector_items: list # The VoiceConnectorItems to associate with the group. — item shape: {VoiceConnectorId: string, Priority: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/voice-connector-groups/{voiceConnectorGroupId}"
    path_params: [{name: voiceConnectorGroupId, var: voice_connector_group_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: VoiceConnectorItems, var: voice_connector_items}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    voice_connector_group_id: $voice_connector_group_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, voice_connector_items: $voice_connector_items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the origination settings for the specified Amazon Chime Voice Connector. If emergency calling is configured for the Amazon Chime Voice Connector, it must be deleted prior to deleting the origination settings.
#
# DELETE /voice-connectors/{voiceConnectorId}/origination
# operationId: DeleteVoiceConnectorOrigination
export def "delete-voice-connector-origination" [
  voice_connector_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/voice-connectors/{voiceConnectorId}/origination"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves origination setting details for the specified Amazon Chime Voice Connector.
#
# GET /voice-connectors/{voiceConnectorId}/origination
# Returns: record<Origination: record<Routes: list<record>, Disabled: bool>>
# operationId: GetVoiceConnectorOrigination
export def "get-voice-connector-origination" [
  voice_connector_id: string
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
    path: "/voice-connectors/{voiceConnectorId}/origination"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds origination settings for the specified Amazon Chime Voice Connector. If emergency calling is configured for the Amazon Chime Voice Connector, it must be deleted prior to turning off origination settings.
#
# PUT /voice-connectors/{voiceConnectorId}/origination
# Returns: record<Origination: record<Routes: list<record>, Disabled: bool>>
# operationId: PutVoiceConnectorOrigination
export def "put-voice-connector-origination" [
  voice_connector_id: string
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
  origination: record # Origination settings enable your SIP hosts to receive inbound calls using your Amazon Chime Voice Connector. The parameters listed below are not required, but you must use at least one. — shape: {Routes?: list, Disabled?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/voice-connectors/{voiceConnectorId}/origination"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Origination, var: origination}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, origination: $origination
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the proxy configuration from the specified Amazon Chime Voice Connector.
#
# DELETE /voice-connectors/{voiceConnectorId}/programmable-numbers/proxy
# operationId: DeleteVoiceConnectorProxy
export def "delete-voice-connector-proxy" [
  voice_connector_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/voice-connectors/{voiceConnectorId}/programmable-numbers/proxy"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the proxy configuration details for the specified Amazon Chime Voice Connector.
#
# GET /voice-connectors/{voiceConnectorId}/programmable-numbers/proxy
# Returns: record<Proxy: record<DefaultSessionExpiryMinutes: int, Disabled: bool, FallBackPhoneNumber: string, PhoneNumberCountries: list<string>>>
# operationId: GetVoiceConnectorProxy
export def "get-voice-connector-proxy" [
  voice_connector_id: string
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
    path: "/voice-connectors/{voiceConnectorId}/programmable-numbers/proxy"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Puts the specified proxy configuration to the specified Amazon Chime Voice Connector.
#
# PUT /voice-connectors/{voiceConnectorId}/programmable-numbers/proxy
# Returns: record<Proxy: record<DefaultSessionExpiryMinutes: int, Disabled: bool, FallBackPhoneNumber: string, PhoneNumberCountries: list<string>>>
# operationId: PutVoiceConnectorProxy
export def "put-voice-connector-proxy" [
  voice_connector_id: string
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
  default_session_expiry_minutes: int # The default number of minutes allowed for proxy sessions.
  phone_number_pool_countries: list<string> # The countries for proxy phone numbers to be selected from.
  --fall-back-phone-number: string # The phone number to route calls to after a proxy session expires. (format: password)
  --disabled: oneof<nothing, bool> # When true, stops proxy sessions from being created on the specified Amazon Chime Voice Connector.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/voice-connectors/{voiceConnectorId}/programmable-numbers/proxy"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DefaultSessionExpiryMinutes, var: default_session_expiry_minutes}, {name: PhoneNumberPoolCountries, var: phone_number_pool_countries}, {name: FallBackPhoneNumber, var: fall_back_phone_number}, {name: Disabled, var: disabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, default_session_expiry_minutes: $default_session_expiry_minutes, phone_number_pool_countries: $phone_number_pool_countries, fall_back_phone_number: $fall_back_phone_number, disabled: $disabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the streaming configuration for the specified Amazon Chime Voice Connector.
#
# DELETE /voice-connectors/{voiceConnectorId}/streaming-configuration
# operationId: DeleteVoiceConnectorStreamingConfiguration
export def "delete-voice-connector-streaming-configuration" [
  voice_connector_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/voice-connectors/{voiceConnectorId}/streaming-configuration"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis. It also shows the retention period, in hours, for the Amazon Kinesis data.
#
# GET /voice-connectors/{voiceConnectorId}/streaming-configuration
# Returns: record<StreamingConfiguration: record<DataRetentionInHours: int, Disabled: bool, StreamingNotificationTargets: list<record>>>
# operationId: GetVoiceConnectorStreamingConfiguration
export def "get-voice-connector-streaming-configuration" [
  voice_connector_id: string
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
    path: "/voice-connectors/{voiceConnectorId}/streaming-configuration"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Kinesis. It also sets the retention period, in hours, for the Amazon Kinesis data.
#
# PUT /voice-connectors/{voiceConnectorId}/streaming-configuration
# Returns: record<StreamingConfiguration: record<DataRetentionInHours: int, Disabled: bool, StreamingNotificationTargets: list<record>>>
# operationId: PutVoiceConnectorStreamingConfiguration
export def "put-voice-connector-streaming-configuration" [
  voice_connector_id: string
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
  streaming_configuration: record # The streaming configuration associated with an Amazon Chime Voice Connector. Specifies whether media streaming is enabled for sending to Amazon Kinesis, and shows the retention period for the Amazon Kinesis data, in hours. — shape: {DataRetentionInHours?: int, Disabled?: bool, StreamingNotificationTargets?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/voice-connectors/{voiceConnectorId}/streaming-configuration"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamingConfiguration, var: streaming_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, streaming_configuration: $streaming_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the termination settings for the specified Amazon Chime Voice Connector. If emergency calling is configured for the Amazon Chime Voice Connector, it must be deleted prior to deleting the termination settings.
#
# DELETE /voice-connectors/{voiceConnectorId}/termination
# operationId: DeleteVoiceConnectorTermination
export def "delete-voice-connector-termination" [
  voice_connector_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/voice-connectors/{voiceConnectorId}/termination"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves termination setting details for the specified Amazon Chime Voice Connector.
#
# GET /voice-connectors/{voiceConnectorId}/termination
# Returns: record<Termination: record<CpsLimit: int, DefaultPhoneNumber: string, CallingRegions: list<string>, CidrAllowedList: list<string>, Disabled: bool>>
# operationId: GetVoiceConnectorTermination
export def "get-voice-connector-termination" [
  voice_connector_id: string
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
    path: "/voice-connectors/{voiceConnectorId}/termination"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds termination settings for the specified Amazon Chime Voice Connector. If emergency calling is configured for the Amazon Chime Voice Connector, it must be deleted prior to turning off termination settings.
#
# PUT /voice-connectors/{voiceConnectorId}/termination
# Returns: record<Termination: record<CpsLimit: int, DefaultPhoneNumber: string, CallingRegions: list<string>, CidrAllowedList: list<string>, Disabled: bool>>
# operationId: PutVoiceConnectorTermination
export def "put-voice-connector-termination" [
  voice_connector_id: string
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
  termination: record # Termination settings enable your SIP hosts to make outbound calls using your Amazon Chime Voice Connector. — shape: {CpsLimit?: int, DefaultPhoneNumber?: string, CallingRegions?: list<string>, CidrAllowedList?: list<string>, Disabled?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/voice-connectors/{voiceConnectorId}/termination"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Termination, var: termination}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, termination: $termination
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
#
# POST /voice-connectors/{voiceConnectorId}/termination/credentials
# operationId: DeleteVoiceConnectorTerminationCredentials
export def "delete-voice-connector-termination-credentials" [
  voice_connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-10 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  usernames: list<string> # The RFC2617 compliant username associated with the SIP credentials, in US-ASCII format.
]: any -> any {
  $in | http-request {
    method: post
    path: "/voice-connectors/{voiceConnectorId}/termination/credentials"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    query: [{name: operation, var: operation, required: true, default: delete}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Usernames, var: usernames}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, usernames: $usernames
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the details of a channel based on the membership of the specified AppInstanceUser. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}
# Returns: record<ChannelMembership: record<ChannelSummary: record<Name: string, ChannelArn: string, Mode: string, Privacy: string, Metadata: string, LastMessageTimestamp: string>, AppInstanceUserMembershipSummary: record<Type: string, ReadMarkerTimestamp: string>>>
# operationId: DescribeChannelMembershipForAppInstanceUser
export def "describe-channel-membership-for-app-instance-user" [
  channel_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-instance-user-arn: string # The ARN of the user in a channel. (required)
  --scope: string@scope-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channelArn}"
    path_params: [{name: channelArn, var: channel_arn}]
    query: [{name: app-instance-user-arn, var: app_instance_user_arn, required: true}, {name: scope, var: scope, required: true, default: app-instance-user-membership}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_arn: $channel_arn, app_instance_user_arn: $app_instance_user_arn, scope: $scope, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the full details of a channel moderated by the specified AppInstanceUser. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}
# Returns: record<Channel: record<ChannelSummary: record<Name: string, ChannelArn: string, Mode: string, Privacy: string, Metadata: string, LastMessageTimestamp: string>>>
# operationId: DescribeChannelModeratedByAppInstanceUser
export def "describe-channel-moderated-by-app-instance-user" [
  channel_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-instance-user-arn: string # The ARN of the AppInstanceUser in the moderated channel. (required)
  --scope: string@scope-completer-1 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channelArn}"
    path_params: [{name: channelArn, var: channel_arn}]
    query: [{name: app-instance-user-arn, var: app_instance_user_arn, required: true}, {name: scope, var: scope, required: true, default: app-instance-user-moderated-channel}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_arn: $channel_arn, app_instance_user_arn: $app_instance_user_arn, scope: $scope, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates the primary provisioned phone number from the specified Amazon Chime user.
#
# POST /accounts/{accountId}/users/{userId}
# Returns: record
# operationId: DisassociatePhoneNumberFromUser
export def "disassociate-phone-number-from-user" [
  account_id: string
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
  --operation: string@operation-completer-11 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/accounts/{accountId}/users/{userId}"
    path_params: [{name: accountId, var: account_id}, {name: userId, var: user_id}]
    query: [{name: operation, var: operation, required: true, default: disassociate-phone-number}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, user_id: $user_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector.
#
# POST /voice-connectors/{voiceConnectorId}
# Returns: record<PhoneNumberErrors: table<PhoneNumberId: string, ErrorCode: string, ErrorMessage: string>>
# operationId: DisassociatePhoneNumbersFromVoiceConnector
export def "disassociate-phone-numbers-from-voice-connector" [
  voice_connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-12 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  e164_phone_numbers: list<string> # List of phone numbers, in E.164 format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/voice-connectors/{voiceConnectorId}"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    query: [{name: operation, var: operation, required: true, default: disassociate-phone-numbers}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: E164PhoneNumbers, var: e164_phone_numbers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, e164_phone_numbers: $e164_phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
#
# POST /voice-connector-groups/{voiceConnectorGroupId}
# Returns: record<PhoneNumberErrors: table<PhoneNumberId: string, ErrorCode: string, ErrorMessage: string>>
# operationId: DisassociatePhoneNumbersFromVoiceConnectorGroup
export def "disassociate-phone-numbers-from-voice-connector-group" [
  voice_connector_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-12 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  e164_phone_numbers: list<string> # List of phone numbers, in E.164 format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/voice-connector-groups/{voiceConnectorGroupId}"
    path_params: [{name: voiceConnectorGroupId, var: voice_connector_group_id}]
    query: [{name: operation, var: operation, required: true, default: disassociate-phone-numbers}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: E164PhoneNumbers, var: e164_phone_numbers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_group_id: $voice_connector_group_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, e164_phone_numbers: $e164_phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates the specified sign-in delegate groups from the specified Amazon Chime account.
#
# POST /accounts/{accountId}
# Returns: record
# operationId: DisassociateSigninDelegateGroupsFromAccount
export def "disassociate-signin-delegate-groups-from-account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-13 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  group_names: list<string> # The sign-in delegate group names.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: operation, var: operation, required: true, default: disassociate-signin-delegate-groups}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: GroupNames, var: group_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, group_names: $group_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dialout settings. For more information about these settings, see Use the Policies Page (https://docs.aws.amazon.com/chime/latest/ag/policies.html) in the Amazon Chime Administration Guide.
#
# GET /accounts/{accountId}/settings
# Returns: record<AccountSettings: record<DisableRemoteControl: bool, EnableDialOut: bool>>
# operationId: GetAccountSettings
export def "get-account-settings" [
  account_id: string
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
    path: "/accounts/{accountId}/settings"
    path_params: [{name: accountId, var: account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see Use the Policies Page (https://docs.aws.amazon.com/chime/latest/ag/policies.html) in the Amazon Chime Administration Guide.
#
# PUT /accounts/{accountId}/settings
# Returns: record
# operationId: UpdateAccountSettings
export def "update-account-settings" [
  account_id: string
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
  account_settings: record # Settings related to the Amazon Chime account. This includes settings that start or stop remote control of shared screens, or start or stop the dial-out option in the Amazon Chime web application. For more information about these settings, see Use the Policies Page (https://docs.aws.amazon.com/chime/latest/ag/policies.html) in the Amazon Chime Administration Guide. — shape: {DisableRemoteControl?: bool, EnableDialOut?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{accountId}/settings"
    path_params: [{name: accountId, var: account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AccountSettings, var: account_settings}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, account_settings: $account_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the retention settings for an AppInstance.
#
# GET /app-instances/{appInstanceArn}/retention-settings
# Returns: record<AppInstanceRetentionSettings: record<ChannelRetentionSettings: record<RetentionDays: int>>, InitiateDeletionTimestamp: string>
# operationId: GetAppInstanceRetentionSettings
export def "get-app-instance-retention-settings" [
  app_instance_arn: string
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
    path: "/app-instances/{appInstanceArn}/retention-settings"
    path_params: [{name: appInstanceArn, var: app_instance_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_instance_arn: $app_instance_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the amount of time in days that a given AppInstance retains data.
#
# PUT /app-instances/{appInstanceArn}/retention-settings
# Returns: record<AppInstanceRetentionSettings: record<ChannelRetentionSettings: record<RetentionDays: int>>, InitiateDeletionTimestamp: string>
# operationId: PutAppInstanceRetentionSettings
export def "put-app-instance-retention-settings" [
  app_instance_arn: string
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
  app_instance_retention_settings: record # The details of the data-retention settings for an AppInstance. — shape: {ChannelRetentionSettings?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/app-instances/{appInstanceArn}/retention-settings"
    path_params: [{name: appInstanceArn, var: app_instance_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AppInstanceRetentionSettings, var: app_instance_retention_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_instance_arn: $app_instance_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, app_instance_retention_settings: $app_instance_retention_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
#
# GET /accounts/{accountId}/bots/{botId}
# Returns: record<Bot: record<BotId: string, UserId: string, DisplayName: string, BotType: string, Disabled: bool, CreatedTimestamp: string, UpdatedTimestamp: string, BotEmail: string, SecurityToken: string>>
# operationId: GetBot
export def "get-bot" [
  account_id: string
  bot_id: string
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
    path: "/accounts/{accountId}/bots/{botId}"
    path_params: [{name: accountId, var: account_id}, {name: botId, var: bot_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, bot_id: $bot_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
#
# POST /accounts/{accountId}/bots/{botId}
# Returns: record<Bot: record<BotId: string, UserId: string, DisplayName: string, BotType: string, Disabled: bool, CreatedTimestamp: string, UpdatedTimestamp: string, BotEmail: string, SecurityToken: string>>
# operationId: UpdateBot
export def "update-bot" [
  account_id: string
  bot_id: string
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
  --disabled: oneof<nothing, bool> # When true, stops the specified bot from running in your account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/bots/{botId}"
    path_params: [{name: accountId, var: account_id}, {name: botId, var: bot_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Disabled, var: disabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, bot_id: $bot_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, disabled: $disabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
#
# GET /settings
# Returns: record<BusinessCalling: record<CdrBucket: string>, VoiceConnector: record<CdrBucket: string>>
# operationId: GetGlobalSettings
export def "get-global-settings" [
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
    path: "/settings"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
#
# PUT /settings
# operationId: UpdateGlobalSettings
export def "update-global-settings" [
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
  --business-calling: record # The Amazon Chime Business Calling settings for the administrator's AWS account. Includes any Amazon S3 buckets designated for storing call detail records. — shape: {CdrBucket?: string}
  --voice-connector: record # The Amazon Chime Voice Connector settings. Includes any Amazon S3 buckets designated for storing call detail records. — shape: {CdrBucket?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/settings"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: BusinessCalling, var: business_calling}, {name: VoiceConnector, var: voice_connector}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, business_calling: $business_calling, voice_connector: $voice_connector
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The details of the endpoint for the messaging session.
#
# GET /endpoints/messaging-session
# Returns: record<Endpoint: record<Url: string>>
# operationId: GetMessagingSessionEndpoint
export def "get-messaging-session-endpoint" [
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
    path: "/endpoints/messaging-session"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves details for the specified phone number order, such as the order creation timestamp, phone numbers in E.164 format, product type, and order status.
#
# GET /phone-number-orders/{phoneNumberOrderId}
# Returns: record<PhoneNumberOrder: record<PhoneNumberOrderId: string, ProductType: string, Status: string, OrderedPhoneNumbers: list<record>, CreatedTimestamp: string, UpdatedTimestamp: string>>
# operationId: GetPhoneNumberOrder
export def "get-phone-number-order" [
  phone_number_order_id: string
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
    path: "/phone-number-orders/{phoneNumberOrderId}"
    path_params: [{name: phoneNumberOrderId, var: phone_number_order_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    phone_number_order_id: $phone_number_order_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
#
# GET /settings/phone-number
# Returns: record<CallingName: string, CallingNameUpdatedTimestamp: string>
# operationId: GetPhoneNumberSettings
export def "get-phone-number-settings" [
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
    path: "/settings/phone-number"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to update.
#
# PUT /settings/phone-number
# operationId: UpdatePhoneNumberSettings
export def "update-phone-number-settings" [
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
  calling_name: string # The default outbound calling name for the account. (format: password)
]: any -> any {
  $in | http-request {
    method: put
    path: "/settings/phone-number"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: CallingName, var: calling_name}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, calling_name: $calling_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the retention settings for the specified Amazon Chime Enterprise account. For more information about retention settings, see Managing Chat Retention Policies (https://docs.aws.amazon.com/chime/latest/ag/chat-retention.html) in the Amazon Chime Administration Guide.
#
# GET /accounts/{accountId}/retention-settings
# Returns: record<RetentionSettings: record<RoomRetentionSettings: record<RetentionDays: int>, ConversationRetentionSettings: record<RetentionDays: int>>, InitiateDeletionTimestamp: string>
# operationId: GetRetentionSettings
export def "get-retention-settings" [
  account_id: string
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
    path: "/accounts/{accountId}/retention-settings"
    path_params: [{name: accountId, var: account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Puts retention settings for the specified Amazon Chime Enterprise account. We recommend using AWS CloudTrail to monitor usage of this API for your account. For more information, see Logging Amazon Chime API Calls with AWS CloudTrail (https://docs.aws.amazon.com/chime/latest/ag/cloudtrail.html) in the Amazon Chime Administration Guide. To turn off existing retention settings, remove the number of days from the corresponding RetentionDays field in the RetentionSettings object. For more information about retention settings, see Managing Chat Retention Policies (https://docs.aws.amazon.com/chime/latest/ag/chat-retention.html) in the Amazon Chime Administration Guide.
#
# PUT /accounts/{accountId}/retention-settings
# Returns: record<RetentionSettings: record<RoomRetentionSettings: record<RetentionDays: int>, ConversationRetentionSettings: record<RetentionDays: int>>, InitiateDeletionTimestamp: string>
# operationId: PutRetentionSettings
export def "put-retention-settings" [
  account_id: string
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
  retention_settings: record # The retention settings for an Amazon Chime Enterprise account that determine how long to retain items such as chat-room messages and chat-conversation messages. — shape: {RoomRetentionSettings?: record, ConversationRetentionSettings?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{accountId}/retention-settings"
    path_params: [{name: accountId, var: account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: RetentionSettings, var: retention_settings}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, retention_settings: $retention_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the logging configuration for the specified SIP media application.
#
# GET /sip-media-applications/{sipMediaApplicationId}/logging-configuration
# Returns: record<SipMediaApplicationLoggingConfiguration: record<EnableSipMediaApplicationMessageLogs: bool>>
# operationId: GetSipMediaApplicationLoggingConfiguration
export def "get-sip-media-application-logging-configuration" [
  sip_media_application_id: string
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
    path: "/sip-media-applications/{sipMediaApplicationId}/logging-configuration"
    path_params: [{name: sipMediaApplicationId, var: sip_media_application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sip_media_application_id: $sip_media_application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the logging configuration for the specified SIP media application.
#
# PUT /sip-media-applications/{sipMediaApplicationId}/logging-configuration
# Returns: record<SipMediaApplicationLoggingConfiguration: record<EnableSipMediaApplicationMessageLogs: bool>>
# operationId: PutSipMediaApplicationLoggingConfiguration
export def "put-sip-media-application-logging-configuration" [
  sip_media_application_id: string
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
  --sip-media-application-logging-configuration: record # Logging configuration of the SIP media application. — shape: {EnableSipMediaApplicationMessageLogs?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sip-media-applications/{sipMediaApplicationId}/logging-configuration"
    path_params: [{name: sipMediaApplicationId, var: sip_media_application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SipMediaApplicationLoggingConfiguration, var: sip_media_application_logging_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sip_media_application_id: $sip_media_application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, sip_media_application_logging_configuration: $sip_media_application_logging_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves details for the specified user ID, such as primary email address, license type,and personal meeting PIN. To retrieve user details with an email address instead of a user ID, use the ListUsers action, and then filter by email address.
#
# GET /accounts/{accountId}/users/{userId}
# Returns: record<User: record<UserId: string, AccountId: string, PrimaryEmail: string, PrimaryProvisionedNumber: string, DisplayName: string, LicenseType: string, UserType: string, UserRegistrationStatus: string, UserInvitationStatus: string, RegisteredOn: string, InvitedOn: string, AlexaForBusinessMetadata: record<IsAlexaForBusinessEnabled: bool, AlexaForBusinessRoomArn: string>, PersonalPIN: string>>
# operationId: GetUser
export def "get-user" [
  account_id: string
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
    path: "/accounts/{accountId}/users/{userId}"
    path_params: [{name: accountId, var: account_id}, {name: userId, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates user details for a specified user ID. Currently, only LicenseType updates are supported for this action.
#
# POST /accounts/{accountId}/users/{userId}
# Returns: record<User: record<UserId: string, AccountId: string, PrimaryEmail: string, PrimaryProvisionedNumber: string, DisplayName: string, LicenseType: string, UserType: string, UserRegistrationStatus: string, UserInvitationStatus: string, RegisteredOn: string, InvitedOn: string, AlexaForBusinessMetadata: record<IsAlexaForBusinessEnabled: bool, AlexaForBusinessRoomArn: string>, PersonalPIN: string>>
# operationId: UpdateUser
export def "update-user" [
  account_id: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --license-type: string@license-type-completer # The user license type to update. This must be a supported license type for the Amazon Chime account that the user belongs to.
  --user-type: string@user-type-completer # The user type.
  --alexa-for-business-metadata: record # The Alexa for Business metadata associated with an Amazon Chime user, used to integrate Alexa for Business with a device. — shape: {IsAlexaForBusinessEnabled?: bool, AlexaForBusinessRoomArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/users/{userId}"
    path_params: [{name: accountId, var: account_id}, {name: userId, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseType, var: license_type}, {name: UserType, var: user_type}, {name: AlexaForBusinessMetadata, var: alexa_for_business_metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, license_type: $license_type, user_type: $user_type, alexa_for_business_metadata: $alexa_for_business_metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves settings for the specified user ID, such as any associated phone number settings.
#
# GET /accounts/{accountId}/users/{userId}/settings
# Returns: record<UserSettings: record<Telephony: record<InboundCalling: bool, OutboundCalling: bool, SMS: bool>>>
# operationId: GetUserSettings
export def "get-user-settings" [
  account_id: string
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
    path: "/accounts/{accountId}/users/{userId}/settings"
    path_params: [{name: accountId, var: account_id}, {name: userId, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the settings for the specified user, such as phone number settings.
#
# PUT /accounts/{accountId}/users/{userId}/settings
# operationId: UpdateUserSettings
export def "update-user-settings" [
  account_id: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  user_settings: record # Settings associated with an Amazon Chime user, including inbound and outbound calling and text messaging. — shape: {Telephony?: record}
]: any -> any {
  $in | http-request {
    method: put
    path: "/accounts/{accountId}/users/{userId}/settings"
    path_params: [{name: accountId, var: account_id}, {name: userId, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: UserSettings, var: user_settings}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, user_settings: $user_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the logging configuration details for the specified Amazon Chime Voice Connector. Shows whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
#
# GET /voice-connectors/{voiceConnectorId}/logging-configuration
# Returns: record<LoggingConfiguration: record<EnableSIPLogs: bool, EnableMediaMetricLogs: bool>>
# operationId: GetVoiceConnectorLoggingConfiguration
export def "get-voice-connector-logging-configuration" [
  voice_connector_id: string
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
    path: "/voice-connectors/{voiceConnectorId}/logging-configuration"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a logging configuration for the specified Amazon Chime Voice Connector. The logging configuration specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
#
# PUT /voice-connectors/{voiceConnectorId}/logging-configuration
# Returns: record<LoggingConfiguration: record<EnableSIPLogs: bool, EnableMediaMetricLogs: bool>>
# operationId: PutVoiceConnectorLoggingConfiguration
export def "put-voice-connector-logging-configuration" [
  voice_connector_id: string
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
  logging_configuration: record # The logging configuration associated with an Amazon Chime Voice Connector. Specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs. — shape: {EnableSIPLogs?: bool, EnableMediaMetricLogs?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/voice-connectors/{voiceConnectorId}/logging-configuration"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: LoggingConfiguration, var: logging_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, logging_configuration: $logging_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the last time a SIP OPTIONS ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
#
# GET /voice-connectors/{voiceConnectorId}/termination/health
# Returns: record<TerminationHealth: record<Timestamp: string, Source: string>>
# operationId: GetVoiceConnectorTerminationHealth
export def "get-voice-connector-termination-health" [
  voice_connector_id: string
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
    path: "/voice-connectors/{voiceConnectorId}/termination/health"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends email to a maximum of 50 users, inviting them to the specified Amazon Chime Team account. Only Team account types are currently supported for this action.
#
# POST /accounts/{accountId}/users
# Returns: record<Invites: table<InviteId: string, Status: string, EmailAddress: string, EmailStatus: string>>
# operationId: InviteUsers
export def "invite-users" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-14 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  user_email_list: list<string> # The user email addresses to which to send the email invitation.
  --user-type: string@user-type-completer # The user type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/users"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: operation, var: operation, required: true, default: add}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: UserEmailList, var: user_email_list}, {name: UserType, var: user_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, user_email_list: $user_email_list, user_type: $user_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all AppInstanceUsers created under a single AppInstance.
#
# GET /app-instance-users
# Returns: record<AppInstanceArn: string, AppInstanceUsers: table<AppInstanceUserArn: string, Name: string, Metadata: string>, NextToken: string>
# operationId: ListAppInstanceUsers
export def "list-app-instance-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-instance-arn: string # The ARN of the AppInstance. (required)
  --max-results: int # The maximum number of requests that you want returned.
  --next-token: string # The token passed by previous API calls until all requested users are returned. (format: password)
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/app-instance-users"
    query: [{name: app-instance-arn, var: app_instance_arn, required: true}, {name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_instance_arn: $app_instance_arn, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tags applied to an Amazon Chime SDK attendee resource.
#
# GET /meetings/{meetingId}/attendees/{attendeeId}/tags
# Returns: record<Tags: table<Key: string, Value: string>>
# operationId: ListAttendeeTags
export def "list-attendee-tags" [
  meeting_id: string
  attendee_id: string
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
    path: "/meetings/{meetingId}/attendees/{attendeeId}/tags"
    path_params: [{name: meetingId, var: meeting_id}, {name: attendeeId, var: attendee_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id, attendee_id: $attendee_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all channels that a particular AppInstanceUser is a part of. Only an AppInstanceAdmin can call the API with a user ARN that is not their own. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels
# Returns: record<ChannelMemberships: table<ChannelSummary: record, AppInstanceUserMembershipSummary: record>, NextToken: string>
# operationId: ListChannelMembershipsForAppInstanceUser
export def "list-channel-memberships-for-app-instance-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-instance-user-arn: string # The ARN of the AppInstanceUsers
  --max-results: int # The maximum number of users that you want returned.
  --next-token: string # The token returned from previous API requests until the number of channel memberships is reached. (format: password)
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --scope: string@scope-completer-2 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channels"
    query: [{name: app-instance-user-arn, var: app_instance_user_arn}, {name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}, {name: scope, var: scope, required: true, default: app-instance-user-memberships}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_instance_user_arn: $app_instance_user_arn, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, scope: $scope, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all the messages in a channel. Returns a paginated list of ChannelMessages. By default, sorted by creation timestamp in descending order. Redacted messages appear in the results as empty, since they are only redacted, not deleted. Deleted messages do not appear in the results. This action always returns the latest version of an edited message. Also, the x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}/messages
# Returns: record<ChannelArn: string, NextToken: string, ChannelMessages: table<MessageId: string, Content: string, Metadata: string, Type: string, CreatedTimestamp: string, LastUpdatedTimestamp: string, LastEditedTimestamp: string, Sender: record, Redacted: bool>>
# operationId: ListChannelMessages
export def "list-channel-messages" [
  channel_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-order: string@sort-order-completer # The order in which you want messages sorted. Default is Descending, based on time created.
  --not-before: string # The initial or starting time stamp for your requested messages. (format: date-time)
  --not-after: string # The final or ending time stamp for your requested messages. (format: date-time)
  --max-results: int # The maximum number of messages that you want returned.
  --next-token: string # The token passed by previous API calls until all requested messages are returned. (format: password)
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channelArn}/messages"
    path_params: [{name: channelArn, var: channel_arn}]
    query: [{name: sort-order, var: sort_order}, {name: not-before, var: not_before}, {name: not-after, var: not_after}, {name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_arn: $channel_arn, sort_order: $sort_order, not_before: $not_before, not_after: $not_after, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a message to a particular channel that the member is a part of. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header. Also, STANDARD messages can contain 4KB of data and the 1KB of metadata. CONTROL messages can contain 30 bytes of data and no metadata.
#
# POST /channels/{channelArn}/messages
# Returns: record<ChannelArn: string, MessageId: string>
# operationId: SendChannelMessage
export def "send-channel-message" [
  channel_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
  content: string # The content of the message. (format: password)
  type: string@type-completer-1 # The type of message, STANDARD or CONTROL.
  persistence: string@persistence-completer # Boolean that controls whether the message is persisted on the back end. Required.
  --metadata: string # The optional metadata for each message. (format: password)
  client_request_token: string # The Idempotency token for each client request. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{channelArn}/messages"
    path_params: [{name: channelArn, var: channel_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    body: {content_type: "application/json", kind: json, fields: [{name: Content, var: content}, {name: Type, var: type}, {name: Persistence, var: persistence}, {name: Metadata, var: metadata}, {name: ClientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    channel_arn: $channel_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer, content: $content, type: $type, persistence: $persistence, metadata: $metadata, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all Channels created under a single Chime App as a paginated list. You can specify filters to narrow results. Functionality & restrictions Use privacy = PUBLIC to retrieve all public channels in the account. Only an AppInstanceAdmin can set privacy = PRIVATE to list the private channels in an account. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels
# Returns: record<Channels: table<Name: string, ChannelArn: string, Mode: string, Privacy: string, Metadata: string, LastMessageTimestamp: string>, NextToken: string>
# operationId: ListChannels
export def "list-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-instance-arn: string # The ARN of the AppInstance. (required)
  --privacy: string@privacy-completer # The privacy setting. PUBLIC retrieves all the public channels. PRIVATE retrieves private channels. Only an AppInstanceAdmin can retrieve private channels.
  --max-results: int # The maximum number of channels that you want to return.
  --next-token: string # The token passed by previous API calls until all requested channels are returned. (format: password)
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channels"
    query: [{name: app-instance-arn, var: app_instance_arn, required: true}, {name: privacy, var: privacy}, {name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_instance_arn: $app_instance_arn, privacy: $privacy, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A list of the channels moderated by an AppInstanceUser. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels
# Returns: record<Channels: table<ChannelSummary: record>, NextToken: string>
# operationId: ListChannelsModeratedByAppInstanceUser
export def "list-channels-moderated-by-app-instance-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-instance-user-arn: string # The ARN of the user in the moderated channel.
  --max-results: int # The maximum number of channels in the request.
  --next-token: string # The token returned from previous API requests until the number of channels moderated by the user is reached. (format: password)
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --scope: string@scope-completer-3 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channels"
    query: [{name: app-instance-user-arn, var: app_instance_user_arn}, {name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}, {name: scope, var: scope, required: true, default: app-instance-user-moderated-channels}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_instance_user_arn: $app_instance_user_arn, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, scope: $scope, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tags applied to an Amazon Chime SDK meeting resource.
#
# GET /meetings/{meetingId}/tags
# Returns: record<Tags: table<Key: string, Value: string>>
# operationId: ListMeetingTags
export def "list-meeting-tags" [
  meeting_id: string
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
    path: "/meetings/{meetingId}/tags"
    path_params: [{name: meetingId, var: meeting_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, Amazon Chime Voice Connector, or Amazon Chime Voice Connector group.
#
# GET /phone-numbers
# Returns: record<PhoneNumbers: table<PhoneNumberId: string, E164PhoneNumber: string, Country: string, Type: string, ProductType: string, Status: string, Capabilities: record, Associations: list, CallingName: string, CallingNameStatus: string, CreatedTimestamp: string, UpdatedTimestamp: string, DeletionTimestamp: string>, NextToken: string>
# operationId: ListPhoneNumbers
export def "list-phone-numbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # The phone number status.
  --product-type: string@product-type-completer # The phone number product type.
  --filter-name: string@filter-name-completer # The filter to use to limit the number of results.
  --filter-value: string # The value to use for the filter.
  --max-results: int # The maximum number of results to return in a single call.
  --next-token: string # The token to use to retrieve the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/phone-numbers"
    query: [{name: status, var: status}, {name: product-type, var: product_type}, {name: filter-name, var: filter_name}, {name: filter-value, var: filter_value}, {name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, product_type: $product_type, filter_name: $filter_name, filter_value: $filter_value, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists supported phone number countries.
#
# GET /phone-number-countries
# Returns: record<PhoneNumberCountries: table<CountryCode: string, SupportedPhoneNumberTypes: list>>
# operationId: ListSupportedPhoneNumberCountries
export def "list-supported-phone-number-countries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-type: string@product-type-completer # The phone number product type. (required)
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
    path: "/phone-number-countries"
    query: [{name: product-type, var: product_type, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    product_type: $product_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tags applied to an Amazon Chime SDK meeting resource.
#
# GET /tags
# Returns: record<Tags: table<Key: string, Value: string>>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --arn: string # The resource ARN. (required, format: password)
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
    path: "/tags"
    query: [{name: arn, var: arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    arn: $arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the SIP credentials for the specified Amazon Chime Voice Connector.
#
# GET /voice-connectors/{voiceConnectorId}/termination/credentials
# Returns: record<Usernames: list<string>>
# operationId: ListVoiceConnectorTerminationCredentials
export def "list-voice-connector-termination-credentials" [
  voice_connector_id: string
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
    path: "/voice-connectors/{voiceConnectorId}/termination/credentials"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Logs out the specified user from all of the devices they are currently logged into.
#
# POST /accounts/{accountId}/users/{userId}
# Returns: record
# operationId: LogoutUser
export def "logout-user" [
  account_id: string
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
  --operation: string@operation-completer-15 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/accounts/{accountId}/users/{userId}"
    path_params: [{name: accountId, var: account_id}, {name: userId, var: user_id}]
    query: [{name: operation, var: operation, required: true, default: logout}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, user_id: $user_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
#
# POST /voice-connectors/{voiceConnectorId}/termination/credentials
# operationId: PutVoiceConnectorTerminationCredentials
export def "put-voice-connector-termination-credentials" [
  voice_connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-16 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --credentials: list # The termination SIP credentials. — item shape: {Username?: string, Password?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/voice-connectors/{voiceConnectorId}/termination/credentials"
    path_params: [{name: voiceConnectorId, var: voice_connector_id}]
    query: [{name: operation, var: operation, required: true, default: put}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Credentials, var: credentials}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    voice_connector_id: $voice_connector_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Redacts message content, but not metadata. The message exists in the back end, but the action returns null content, and the state shows as redacted. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# POST /channels/{channelArn}/messages/{messageId}
# Returns: record<ChannelArn: string, MessageId: string>
# operationId: RedactChannelMessage
export def "redact-channel-message" [
  channel_arn: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-17 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/channels/{channelArn}/messages/{messageId}"
    path_params: [{name: channelArn, var: channel_arn}, {name: messageId, var: message_id}]
    query: [{name: operation, var: operation, required: true, default: redact}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_arn: $channel_arn, message_id: $message_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Redacts the specified message from the specified Amazon Chime conversation.
#
# POST /accounts/{accountId}/conversations/{conversationId}/messages/{messageId}
# Returns: record
# operationId: RedactConversationMessage
export def "redact-conversation-message" [
  account_id: string
  conversation_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-17 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/accounts/{accountId}/conversations/{conversationId}/messages/{messageId}"
    path_params: [{name: accountId, var: account_id}, {name: conversationId, var: conversation_id}, {name: messageId, var: message_id}]
    query: [{name: operation, var: operation, required: true, default: redact}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, conversation_id: $conversation_id, message_id: $message_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Redacts the specified message from the specified Amazon Chime channel.
#
# POST /accounts/{accountId}/rooms/{roomId}/messages/{messageId}
# Returns: record
# operationId: RedactRoomMessage
export def "redact-room-message" [
  account_id: string
  room_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-17 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/accounts/{accountId}/rooms/{roomId}/messages/{messageId}"
    path_params: [{name: accountId, var: account_id}, {name: roomId, var: room_id}, {name: messageId, var: message_id}]
    query: [{name: operation, var: operation, required: true, default: redact}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, room_id: $room_id, message_id: $message_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Regenerates the security token for a bot.
#
# POST /accounts/{accountId}/bots/{botId}
# Returns: record<Bot: record<BotId: string, UserId: string, DisplayName: string, BotType: string, Disabled: bool, CreatedTimestamp: string, UpdatedTimestamp: string, BotEmail: string, SecurityToken: string>>
# operationId: RegenerateSecurityToken
export def "regenerate-security-token" [
  account_id: string
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-18 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/accounts/{accountId}/bots/{botId}"
    path_params: [{name: accountId, var: account_id}, {name: botId, var: bot_id}]
    query: [{name: operation, var: operation, required: true, default: regenerate-security-token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, bot_id: $bot_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the User object with the updated personal meeting PIN.
#
# POST /accounts/{accountId}/users/{userId}
# Returns: record<User: record<UserId: string, AccountId: string, PrimaryEmail: string, PrimaryProvisionedNumber: string, DisplayName: string, LicenseType: string, UserType: string, UserRegistrationStatus: string, UserInvitationStatus: string, RegisteredOn: string, InvitedOn: string, AlexaForBusinessMetadata: record<IsAlexaForBusinessEnabled: bool, AlexaForBusinessRoomArn: string>, PersonalPIN: string>>
# operationId: ResetPersonalPIN
export def "reset-personal-pin" [
  account_id: string
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
  --operation: string@operation-completer-19 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/accounts/{accountId}/users/{userId}"
    path_params: [{name: accountId, var: account_id}, {name: userId, var: user_id}]
    query: [{name: operation, var: operation, required: true, default: reset-personal-pin}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, user_id: $user_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves a phone number from the Deletion queue back into the phone number Inventory.
#
# POST /phone-numbers/{phoneNumberId}
# Returns: record<PhoneNumber: record<PhoneNumberId: string, E164PhoneNumber: string, Country: string, Type: string, ProductType: string, Status: string, Capabilities: record<InboundCall: bool, OutboundCall: bool, InboundSMS: bool, OutboundSMS: bool, InboundMMS: bool, OutboundMMS: bool>, Associations: list<record>, CallingName: string, CallingNameStatus: string, CreatedTimestamp: string, UpdatedTimestamp: string, DeletionTimestamp: string>>
# operationId: RestorePhoneNumber
export def "restore-phone-number" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-20 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/phone-numbers/{phoneNumberId}"
    path_params: [{name: phoneNumberId, var: phone_number_id}]
    query: [{name: operation, var: operation, required: true, default: restore}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    phone_number_id: $phone_number_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches for phone numbers that can be ordered. For US numbers, provide at least one of the following search filters: AreaCode, City, State, or TollFreePrefix. If you provide City, you must also provide State. Numbers outside the US only support the PhoneNumberType filter, which you must use.
#
# GET /search
# Returns: record<E164PhoneNumbers: list<string>, NextToken: string>
# operationId: SearchAvailablePhoneNumbers
export def "search-available-phone-numbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area-code: string # The area code used to filter results. Only applies to the US.
  --city: string # The city used to filter results. Only applies to the US.
  --country: string # The country used to filter results. Defaults to the US Format: ISO 3166-1 alpha-2.
  --state: string # The state used to filter results. Required only if you provide City. Only applies to the US.
  --toll-free-prefix: string # The toll-free prefix that you use to filter results. Only applies to the US.
  --phone-number-type: string@phone-number-type-completer # The phone number type used to filter results. Required for non-US numbers.
  --max-results: int # The maximum number of results to return in a single call.
  --next-token: string # The token used to retrieve the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --type: string@type-completer-2 # required
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
    path: "/search"
    query: [{name: area-code, var: area_code}, {name: city, var: city}, {name: country, var: country}, {name: state, var: state}, {name: toll-free-prefix, var: toll_free_prefix}, {name: phone-number-type, var: phone_number_type}, {name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}, {name: type, var: type, required: true, default: phone-numbers}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    area_code: $area_code, city: $city, country: $country, state: $state, toll_free_prefix: $toll_free_prefix, phone_number_type: $phone_number_type, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, type: $type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts transcription for the specified meetingId. For more information, refer to Using Amazon Chime SDK live transcription (https://docs.aws.amazon.com/chime-sdk/latest/dg/meeting-transcription.html) in the Amazon Chime SDK Developer Guide. If you specify an invalid configuration, a TranscriptFailed event will be sent with the contents of the BadRequestException generated by Amazon Transcribe. For more information on each parameter and which combinations are valid, refer to the StartStreamTranscription (https://docs.aws.amazon.com/transcribe/latest/APIReference/API_streaming_StartStreamTranscription.html) API in the Amazon Transcribe Developer Guide. Amazon Chime SDK live transcription is powered by Amazon Transcribe. Use of Amazon Transcribe is subject to the AWS Service Terms (https://aws.amazon.com/service-terms/), including the terms specific to the AWS Machine Learning and Artificial Intelligence Services.
#
# POST /meetings/{meetingId}/transcription
# Returns: record
# operationId: StartMeetingTranscription
export def "start-meeting-transcription" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-21 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  transcription_configuration: record # The configuration for the current transcription operation. Must contain EngineTranscribeSettings or EngineTranscribeMedicalSettings. — shape: {EngineTranscribeSettings?: record, EngineTranscribeMedicalSettings?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/meetings/{meetingId}/transcription"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: operation, var: operation, required: true, default: start}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: TranscriptionConfiguration, var: transcription_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, transcription_configuration: $transcription_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops transcription for the specified meetingId.
#
# POST /meetings/{meetingId}/transcription
# Returns: record
# operationId: StopMeetingTranscription
export def "stop-meeting-transcription" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-22 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/meetings/{meetingId}/transcription"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: operation, var: operation, required: true, default: stop}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applies the specified tags to the specified Amazon Chime SDK attendee.
#
# POST /meetings/{meetingId}/attendees/{attendeeId}/tags
# operationId: TagAttendee
export def "tag-attendee" [
  meeting_id: string
  attendee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-14 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: list # The tag key-value pairs. — item shape: {Key: string, Value: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/meetings/{meetingId}/attendees/{attendeeId}/tags"
    path_params: [{name: meetingId, var: meeting_id}, {name: attendeeId, var: attendee_id}]
    query: [{name: operation, var: operation, required: true, default: add}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    meeting_id: $meeting_id, attendee_id: $attendee_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applies the specified tags to the specified Amazon Chime SDK meeting.
#
# POST /meetings/{meetingId}/tags
# operationId: TagMeeting
export def "tag-meeting" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-14 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: list # The tag key-value pairs. — item shape: {Key: string, Value: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/meetings/{meetingId}/tags"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: operation, var: operation, required: true, default: add}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    meeting_id: $meeting_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applies the specified tags to the specified Amazon Chime SDK meeting resource.
#
# POST /tags
# operationId: TagResource
export def "tag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-23 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  resource_arn: string # The resource ARN. (format: password)
  tags: list # The tag key-value pairs. — item shape: {Key: string, Value: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/tags"
    query: [{name: operation, var: operation, required: true, default: tag-resource}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceARN, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Untags the specified tags from the specified Amazon Chime SDK attendee.
#
# POST /meetings/{meetingId}/attendees/{attendeeId}/tags
# operationId: UntagAttendee
export def "untag-attendee" [
  meeting_id: string
  attendee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-10 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tag_keys: list<string> # The tag keys.
]: any -> any {
  $in | http-request {
    method: post
    path: "/meetings/{meetingId}/attendees/{attendeeId}/tags"
    path_params: [{name: meetingId, var: meeting_id}, {name: attendeeId, var: attendee_id}]
    query: [{name: operation, var: operation, required: true, default: delete}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    meeting_id: $meeting_id, attendee_id: $attendee_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Untags the specified tags from the specified Amazon Chime SDK meeting.
#
# POST /meetings/{meetingId}/tags
# operationId: UntagMeeting
export def "untag-meeting" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-10 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tag_keys: list<string> # The tag keys.
]: any -> any {
  $in | http-request {
    method: post
    path: "/meetings/{meetingId}/tags"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: operation, var: operation, required: true, default: delete}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    meeting_id: $meeting_id, operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Untags the specified tags from the specified Amazon Chime SDK meeting resource.
#
# POST /tags
# operationId: UntagResource
export def "untag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-24 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  resource_arn: string # The resource ARN. (format: password)
  tag_keys: list<string> # The tag keys.
]: any -> any {
  $in | http-request {
    method: post
    path: "/tags"
    query: [{name: operation, var: operation, required: true, default: untag-resource}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceARN, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    operation: $operation, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The details of the time when a user last read messages in a channel. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# PUT /channels/{channelArn}/readMarker
# Returns: record<ChannelArn: string>
# operationId: UpdateChannelReadMarker
export def "update-channel-read-marker" [
  channel_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/channels/{channelArn}/readMarker"
    path_params: [{name: channelArn, var: channel_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-chime-bearer, var: x_amz_chime_bearer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_arn: $channel_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_chime_bearer: $x_amz_chime_bearer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invokes the AWS Lambda function associated with the SIP media application and transaction ID in an update request. The Lambda function can then return a new set of actions.
#
# POST /sip-media-applications/{sipMediaApplicationId}/calls/{transactionId}
# Returns: record<SipMediaApplicationCall: record<TransactionId: string>>
# operationId: UpdateSipMediaApplicationCall
export def "update-sip-media-application-call" [
  sip_media_application_id: string
  transaction_id: string
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
  arguments: record # Arguments made available to the Lambda function as part of the CALL_UPDATE_REQUESTED event. Can contain 0-20 key-value pairs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sip-media-applications/{sipMediaApplicationId}/calls/{transactionId}"
    path_params: [{name: sipMediaApplicationId, var: sip_media_application_id}, {name: transactionId, var: transaction_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Arguments, var: arguments}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    sip_media_application_id: $sip_media_application_id, transaction_id: $transaction_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, arguments: $arguments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates an address to be used for 911 calls made with Amazon Chime Voice Connectors. You can use validated addresses in a Presence Information Data Format Location Object file that you include in SIP requests. That helps ensure that addresses are routed to the appropriate Public Safety Answering Point.
#
# POST /emergency-calling/address
# Returns: record<ValidationResult: int, AddressExternalId: string, Address: record<streetName: string, streetSuffix: string, postDirectional: string, preDirectional: string, streetNumber: string, city: string, state: string, postalCode: string, postalCodePlus4: string, country: string>, CandidateAddressList: table<streetInfo: string, streetNumber: string, city: string, state: string, postalCode: string, postalCodePlus4: string, country: string>>
# operationId: ValidateE911Address
export def "validate-e911-address" [
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
  aws_account_id: string # The AWS account ID.
  street_number: string # The address street number, such as 200 or 2121. (format: password)
  street_info: string # The address street information, such as 8th Avenue. (format: password)
  city: string # The address city, such as Portland. (format: password)
  state: string # The address state, such as ME. (format: password)
  country: string # The address country, such as US. (format: password)
  postal_code: string # The address postal code, such as 04352. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/emergency-calling/address"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AwsAccountId, var: aws_account_id}, {name: StreetNumber, var: street_number}, {name: StreetInfo, var: street_info}, {name: City, var: city}, {name: State, var: state}, {name: Country, var: country}, {name: PostalCode, var: postal_code}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, aws_account_id: $aws_account_id, street_number: $street_number, street_info: $street_info, city: $city, state: $state, country: $country, postal_code: $postal_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
