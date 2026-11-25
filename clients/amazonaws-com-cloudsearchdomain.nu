# Auto-generated client for Amazon CloudSearch Domain v2013-01-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/cloudsearchdomain/2013-01-01/openapi.json
# Auth: --token flag or $env.AMAZON_CLOUDSEARCH_DOMAIN_TOKEN

const CLIENT = {
  base_url: "http://cloudsearchdomain.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_CLOUDSEARCH_DOMAIN_TOKEN"
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

def base-url-completer [] { ["http://cloudsearchdomain.us-east-1.amazonaws.com" "http://cloudsearchdomain.us-east-2.amazonaws.com" "http://cloudsearchdomain.us-west-1.amazonaws.com" "http://cloudsearchdomain.us-west-2.amazonaws.com" "http://cloudsearchdomain.us-gov-west-1.amazonaws.com" "http://cloudsearchdomain.us-gov-east-1.amazonaws.com" "http://cloudsearchdomain.ca-central-1.amazonaws.com" "http://cloudsearchdomain.eu-north-1.amazonaws.com" "http://cloudsearchdomain.eu-west-1.amazonaws.com" "http://cloudsearchdomain.eu-west-2.amazonaws.com" "http://cloudsearchdomain.eu-west-3.amazonaws.com" "http://cloudsearchdomain.eu-central-1.amazonaws.com" "http://cloudsearchdomain.eu-south-1.amazonaws.com" "http://cloudsearchdomain.af-south-1.amazonaws.com" "http://cloudsearchdomain.ap-northeast-1.amazonaws.com" "http://cloudsearchdomain.ap-northeast-2.amazonaws.com" "http://cloudsearchdomain.ap-northeast-3.amazonaws.com" "http://cloudsearchdomain.ap-southeast-1.amazonaws.com" "http://cloudsearchdomain.ap-southeast-2.amazonaws.com" "http://cloudsearchdomain.ap-east-1.amazonaws.com" "http://cloudsearchdomain.ap-south-1.amazonaws.com" "http://cloudsearchdomain.sa-east-1.amazonaws.com" "http://cloudsearchdomain.me-south-1.amazonaws.com" "https://cloudsearchdomain.us-east-1.amazonaws.com" "https://cloudsearchdomain.us-east-2.amazonaws.com" "https://cloudsearchdomain.us-west-1.amazonaws.com" "https://cloudsearchdomain.us-west-2.amazonaws.com" "https://cloudsearchdomain.us-gov-west-1.amazonaws.com" "https://cloudsearchdomain.us-gov-east-1.amazonaws.com" "https://cloudsearchdomain.ca-central-1.amazonaws.com" "https://cloudsearchdomain.eu-north-1.amazonaws.com" "https://cloudsearchdomain.eu-west-1.amazonaws.com" "https://cloudsearchdomain.eu-west-2.amazonaws.com" "https://cloudsearchdomain.eu-west-3.amazonaws.com" "https://cloudsearchdomain.eu-central-1.amazonaws.com" "https://cloudsearchdomain.eu-south-1.amazonaws.com" "https://cloudsearchdomain.af-south-1.amazonaws.com" "https://cloudsearchdomain.ap-northeast-1.amazonaws.com" "https://cloudsearchdomain.ap-northeast-2.amazonaws.com" "https://cloudsearchdomain.ap-northeast-3.amazonaws.com" "https://cloudsearchdomain.ap-southeast-1.amazonaws.com" "https://cloudsearchdomain.ap-southeast-2.amazonaws.com" "https://cloudsearchdomain.ap-east-1.amazonaws.com" "https://cloudsearchdomain.ap-south-1.amazonaws.com" "https://cloudsearchdomain.sa-east-1.amazonaws.com" "https://cloudsearchdomain.me-south-1.amazonaws.com" "http://cloudsearchdomain.cn-north-1.amazonaws.com.cn" "http://cloudsearchdomain.cn-northwest-1.amazonaws.com.cn" "https://cloudsearchdomain.cn-north-1.amazonaws.com.cn" "https://cloudsearchdomain.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def q-parser-completer [] { ["dismax" "lucene" "simple" "structured"] }
def format-completer [] { ["sdk"] }
def pretty-completer [] { ["true"] }
def content-type-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    search: "record<status: record<timems: int, rid: string>, hits: record<found: int, start: int, cursor: string, hit: list<record>>, facets: record, stats: record>"
    suggest: "record<status: record<timems: int, rid: string>, suggest: record<query: string, found: int, suggestions: list<record>>>"
    upload-documents: "record<status: string, adds: int, deletes: int, warnings: table<message: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["search" "suggest" "upload-documents" "commands"] | sort) } | get name | first)
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

# Retrieves a list of documents that match the specified search criteria. How you specify the search criteria depends on which query parser you use. Amazon CloudSearch supports four query parsers: simple: search all text and text-array fields for the specified string. Search for phrases, individual terms, and prefixes. structured: search specific fields, construct compound queries using Boolean operators, and use advanced features such as term boosting and proximity searching. lucene: specify search criteria using the Apache Lucene query parser syntax. dismax: specify search criteria using the simplified subset of the Apache Lucene query parser syntax defined by the DisMax query parser. For more information, see Searching Your Data (http://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching.html) in the Amazon CloudSearch Developer Guide. The endpoint for submitting Search requests is domain-specific. You submit search requests to a domain's search endpoint. To get the search endpoint for your domain, use the Amazon CloudSearch configuration service DescribeDomains action. A domain's endpoints are also displayed on the domain dashboard in the Amazon CloudSearch console.
#
# GET /2013-01-01/search
# Returns: record<status: record<timems: int, rid: string>, hits: record<found: int, start: int, cursor: string, hit: list<record>>, facets: record, stats: record>
# operationId: Search
export def "search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Retrieves a cursor value you can use to page through large result sets. Use the size parameter to control the number of hits to include in each response. You can specify either the cursor or start parameter in a request; they are mutually exclusive. To get the first cursor, set the cursor value to initial. In subsequent requests, specify the cursor value returned in the hits section of the response. For more information, see Paginating Results (http://docs.aws.amazon.com/cloudsearch/latest/developerguide/paginating-results.html) in the Amazon CloudSearch Developer Guide.
  --expr: string # Defines one or more numeric expressions that can be used to sort results or specify search or filter criteria. You can also specify expressions as return fields. You specify the expressions in JSON using the form {"EXPRESSIONNAME":"EXPRESSION"}. You can define and use multiple expressions in a search request. For example: {"expression1":"_score*rating", "expression2":"(1/rank)*year"} For information about the variables, operators, and functions you can use in expressions, see Writing Expressions (http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html#writing-expressions) in the Amazon CloudSearch Developer Guide.
  --facet: string # Specifies one or more fields for which to get facet information, and options that control how the facet information is returned. Each specified field must be facet-enabled in the domain configuration. The fields and options are specified in JSON using the form {"FIELD":{"OPTION":VALUE,"OPTION:"STRING"},"FIELD":{"OPTION":VALUE,"OPTION":"STRING"}}. You can specify the following faceting options: buckets specifies an array of the facet values or ranges to count. Ranges are specified using the same syntax that you use to search for a range of values. For more information, see Searching for a Range of Values (http://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching-ranges.html) in the Amazon CloudSearch Developer Guide. Buckets are returned in the order they are specified in the request. The sort and size options are not valid if you specify buckets. size specifies the maximum number of facets to include in the results. By default, Amazon CloudSearch returns counts for the top 10. The size parameter is only valid when you specify the sort option; it cannot be used in conjunction with buckets. sort specifies how you want to sort the facets in the results: bucket or count. Specify bucket to sort alphabetically or numerically by facet value (in ascending order). Specify count to sort by the facet counts computed for each facet value (in descending order). To retrieve facet counts for particular values or ranges of values, use the buckets option instead of sort. If no facet options are specified, facet counts are computed for all field values, the facets are sorted by facet count, and the top 10 facets are returned in the results. To count particular buckets of values, use the buckets option. For example, the following request uses the buckets option to calculate and return facet counts by decade. {"year":{"buckets":["[1970,1979]","[1980,1989]","[1990,1999]","[2000,2009]","[2010,}"]}} To sort facets by facet count, use the count option. For example, the following request sets the sort option to count to sort the facet values by facet count, with the facet values that have the most matching documents listed first. Setting the size option to 3 returns only the top three facet values. {"year":{"sort":"count","size":3}} To sort the facets by value, use the bucket option. For example, the following request sets the sort option to bucket to sort the facet values numerically by year, with earliest year listed first. {"year":{"sort":"bucket"}} For more information, see Getting and Using Facet Information (http://docs.aws.amazon.com/cloudsearch/latest/developerguide/faceting.html) in the Amazon CloudSearch Developer Guide.
  --fq: string # Specifies a structured query that filters the results of a search without affecting how the results are scored and sorted. You use filterQuery in conjunction with the query parameter to filter the documents that match the constraints specified in the query parameter. Specifying a filter controls only which matching documents are included in the results, it has no effect on how they are scored and sorted. The filterQuery parameter supports the full structured query syntax. For more information about using filters, see Filtering Matching Documents (http://docs.aws.amazon.com/cloudsearch/latest/developerguide/filtering-results.html) in the Amazon CloudSearch Developer Guide.
  --highlight: string # Retrieves highlights for matches in the specified text or text-array fields. Each specified field must be highlight enabled in the domain configuration. The fields and options are specified in JSON using the form {"FIELD":{"OPTION":VALUE,"OPTION:"STRING"},"FIELD":{"OPTION":VALUE,"OPTION":"STRING"}}. You can specify the following highlight options: format: specifies the format of the data in the text field: text or html. When data is returned as HTML, all non-alphanumeric characters are encoded. The default is html. max_phrases: specifies the maximum number of occurrences of the search term(s) you want to highlight. By default, the first occurrence is highlighted. pre_tag: specifies the string to prepend to an occurrence of a search term. The default for HTML highlights is &lt;em&gt;. The default for text highlights is *. post_tag: specifies the string to append to an occurrence of a search term. The default for HTML highlights is &lt;/em&gt;. The default for text highlights is *. If no highlight options are specified for a field, the returned field text is treated as HTML and the first match is highlighted with emphasis tags: &lt;em>search-term&lt;/em&gt;. For example, the following request retrieves highlights for the actors and title fields. { "actors": {}, "title": {"format": "text","max_phrases": 2,"pre_tag": "","post_tag": ""} }
  --partial: oneof<nothing, bool> # Enables partial results to be returned if one or more index partitions are unavailable. When your search index is partitioned across multiple search instances, by default Amazon CloudSearch only returns results if every partition can be queried. This means that the failure of a single search instance can result in 5xx (internal server) errors. When you enable partial results, Amazon CloudSearch returns whatever results are available and includes the percentage of documents searched in the search results (percent-searched). This enables you to more gracefully degrade your users' search experience. For example, rather than displaying no results, you could display the partial results and a message indicating that the results might be incomplete due to a temporary system outage.
  --q: string # Specifies the search criteria for the request. How you specify the search criteria depends on the query parser used for the request and the parser options specified in the queryOptions parameter. By default, the simple query parser is used to process requests. To use the structured, lucene, or dismax query parser, you must also specify the queryParser parameter. For more information about specifying search criteria, see Searching Your Data (http://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching.html) in the Amazon CloudSearch Developer Guide. (required)
  --q-options: string # Configures options for the query parser specified in the queryParser parameter. You specify the options in JSON using the following form {"OPTION1":"VALUE1","OPTION2":VALUE2"..."OPTIONN":"VALUEN"}. The options you can configure vary according to which parser you use: defaultOperator: The default operator used to combine individual terms in the search string. For example: defaultOperator: 'or'. For the dismax parser, you specify a percentage that represents the percentage of terms in the search string (rounded down) that must match, rather than a default operator. A value of 0% is the equivalent to OR, and a value of 100% is equivalent to AND. The percentage must be specified as a value in the range 0-100 followed by the percent (%) symbol. For example, defaultOperator: 50%. Valid values: and, or, a percentage in the range 0%-100% (dismax). Default: and (simple, structured, lucene) or 100 (dismax). Valid for: simple, structured, lucene, and dismax. fields: An array of the fields to search when no fields are specified in a search. If no fields are specified in a search and this option is not specified, all text and text-array fields are searched. You can specify a weight for each field to control the relative importance of each field when Amazon CloudSearch calculates relevance scores. To specify a field weight, append a caret (^) symbol and the weight to the field name. For example, to boost the importance of the title field over the description field you could specify: "fields":["title^5","description"]. Valid values: The name of any configured field and an optional numeric value greater than zero. Default: All text and text-array fields. Valid for: simple, structured, lucene, and dismax. operators: An array of the operators or special characters you want to disable for the simple query parser. If you disable the and, or, or not operators, the corresponding operators (+, |, -) have no special meaning and are dropped from the search string. Similarly, disabling prefix disables the wildcard operator (*) and disabling phrase disables the ability to search for phrases by enclosing phrases in double quotes. Disabling precedence disables the ability to control order of precedence using parentheses. Disabling near disables the ability to use the ~ operator to perform a sloppy phrase search. Disabling the fuzzy operator disables the ability to use the ~ operator to perform a fuzzy search. escape disables the ability to use a backslash (\) to escape special characters within the search string. Disabling whitespace is an advanced option that prevents the parser from tokenizing on whitespace, which can be useful for Vietnamese. (It prevents Vietnamese words from being split incorrectly.) For example, you could disable all operators other than the phrase operator to support just simple term and phrase queries: "operators":["and","not","or", "prefix"]. Valid values: and, escape, fuzzy, near, not, or, phrase, precedence, prefix, whitespace. Default: All operators and special characters are enabled. Valid for: simple. phraseFields: An array of the text or text-array fields you want to use for phrase searches. When the terms in the search string appear in close proximity within a field, the field scores higher. You can specify a weight for each field to boost that score. The phraseSlop option controls how much the matches can deviate from the search string and still be boosted. To specify a field weight, append a caret (^) symbol and the weight to the field name. For example, to boost phrase matches in the title field over the abstract field, you could specify: "phraseFields":["title^3", "plot"] Valid values: The name of any text or text-array field and an optional numeric value greater than zero. Default: No fields. If you don't specify any fields with phraseFields, proximity scoring is disabled even if phraseSlop is specified. Valid for: dismax. phraseSlop: An integer value that specifies how much matches can deviate from the search phrase and still be boosted according to the weights specified in the phraseFields option; for example, phraseSlop: 2. You must also specify phraseFields to enable proximity scoring. Valid values: positive integers. Default: 0. Valid for: dismax. explicitPhraseSlop: An integer value that specifies how much a match can deviate from the search phrase when the phrase is enclosed in double quotes in the search string. (Phrases that exceed this proximity distance are not considered a match.) For example, to specify a slop of three for dismax phrase queries, you would specify "explicitPhraseSlop":3. Valid values: positive integers. Default: 0. Valid for: dismax. tieBreaker: When a term in the search string is found in a document's field, a score is calculated for that field based on how common the word is in that field compared to other documents. If the term occurs in multiple fields within a document, by default only the highest scoring field contributes to the document's overall score. You can specify a tieBreaker value to enable the matches in lower-scoring fields to contribute to the document's score. That way, if two documents have the same max field score for a particular term, the score for the document that has matches in more fields will be higher. The formula for calculating the score with a tieBreaker is (max field score) + (tieBreaker) * (sum of the scores for the rest of the matching fields). Set tieBreaker to 0 to disregard all but the highest scoring field (pure max): "tieBreaker":0. Set to 1 to sum the scores from all fields (pure sum): "tieBreaker":1. Valid values: 0.0 to 1.0. Default: 0.0. Valid for: dismax.
  --q-parser: string@q-parser-completer # Specifies which query parser to use to process the request. If queryParser is not specified, Amazon CloudSearch uses the simple query parser. Amazon CloudSearch supports four query parsers: simple: perform simple searches of text and text-array fields. By default, the simple query parser searches all text and text-array fields. You can specify which fields to search by with the queryOptions parameter. If you prefix a search term with a plus sign (+) documents must contain the term to be considered a match. (This is the default, unless you configure the default operator with the queryOptions parameter.) You can use the - (NOT), | (OR), and * (wildcard) operators to exclude particular terms, find results that match any of the specified terms, or search for a prefix. To search for a phrase rather than individual terms, enclose the phrase in double quotes. For more information, see Searching for Text (http://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching-text.html) in the Amazon CloudSearch Developer Guide. structured: perform advanced searches by combining multiple expressions to define the search criteria. You can also search within particular fields, search for values and ranges of values, and use advanced options such as term boosting, matchall, and near. For more information, see Constructing Compound Queries (http://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching-compound-queries.html) in the Amazon CloudSearch Developer Guide. lucene: search using the Apache Lucene query parser syntax. For more information, see Apache Lucene Query Parser Syntax (http://lucene.apache.org/core/4_6_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html#package_description). dismax: search using the simplified subset of the Apache Lucene query parser syntax defined by the DisMax query parser. For more information, see DisMax Query Parser Syntax (http://wiki.apache.org/solr/DisMaxQParserPlugin#Query_Syntax).
  --return: string # Specifies the field and expression values to include in the response. Multiple fields or expressions are specified as a comma-separated list. By default, a search response includes all return enabled fields (_all_fields). To return only the document IDs for the matching documents, specify _no_fields. To retrieve the relevance score calculated for each document, specify _score.
  --size: int # Specifies the maximum number of search hits to include in the response.
  --sort: string # Specifies the fields or custom expressions to use to sort the search results. Multiple fields or expressions are specified as a comma-separated list. You must specify the sort direction (asc or desc) for each field; for example, year desc,title asc. To use a field to sort results, the field must be sort-enabled in the domain configuration. Array type fields cannot be used for sorting. If no sort parameter is specified, results are sorted by their default relevance scores in descending order: _score desc. You can also sort by document ID (_id asc) and version (_version desc). For more information, see Sorting Results (http://docs.aws.amazon.com/cloudsearch/latest/developerguide/sorting-results.html) in the Amazon CloudSearch Developer Guide.
  --start: int # Specifies the offset of the first search hit you want to return. Note that the result set is zero-based; the first result is at index 0. You can specify either the start or cursor parameter in a request, they are mutually exclusive. For more information, see Paginating Results (http://docs.aws.amazon.com/cloudsearch/latest/developerguide/paginating-results.html) in the Amazon CloudSearch Developer Guide.
  --stats: string # Specifies one or more fields for which to get statistics information. Each specified field must be facet-enabled in the domain configuration. The fields are specified in JSON using the form: {"FIELD-A":{},"FIELD-B":{}} There are currently no options supported for statistics.
  --format: string@format-completer # required
  --pretty: string@pretty-completer # required
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
    path: "/2013-01-01/search"
    query: [{name: cursor, var: cursor}, {name: expr, var: expr}, {name: facet, var: facet}, {name: fq, var: fq}, {name: highlight, var: highlight}, {name: partial, var: partial}, {name: q, var: q, required: true}, {name: "q.options", var: q_options}, {name: "q.parser", var: q_parser}, {name: return, var: return}, {name: size, var: size}, {name: sort, var: sort}, {name: start, var: start}, {name: stats, var: stats}, {name: format, var: format, required: true, default: sdk}, {name: pretty, var: pretty, required: true, default: "true"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, expr: $expr, facet: $facet, fq: $fq, highlight: $highlight, partial: $partial, q: $q, q_options: $q_options, q_parser: $q_parser, return: $return, size: $size, sort: $sort, start: $start, stats: $stats, format: $format, pretty: $pretty, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves autocomplete suggestions for a partial query string. You can use suggestions enable you to display likely matches before users finish typing. In Amazon CloudSearch, suggestions are based on the contents of a particular text field. When you request suggestions, Amazon CloudSearch finds all of the documents whose values in the suggester field start with the specified query string. The beginning of the field must match the query string to be considered a match. For more information about configuring suggesters and retrieving suggestions, see Getting Suggestions (http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html) in the Amazon CloudSearch Developer Guide. The endpoint for submitting Suggest requests is domain-specific. You submit suggest requests to a domain's search endpoint. To get the search endpoint for your domain, use the Amazon CloudSearch configuration service DescribeDomains action. A domain's endpoints are also displayed on the domain dashboard in the Amazon CloudSearch console.
#
# GET /2013-01-01/suggest
# Returns: record<status: record<timems: int, rid: string>, suggest: record<query: string, found: int, suggestions: list<record>>>
# operationId: Suggest
export def "suggest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Specifies the string for which you want to get suggestions. (required)
  --suggester: string # Specifies the name of the suggester to use to find suggested matches. (required)
  --size: int # Specifies the maximum number of suggestions to return.
  --format: string@format-completer # required
  --pretty: string@pretty-completer # required
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
    path: "/2013-01-01/suggest"
    query: [{name: q, var: q, required: true}, {name: suggester, var: suggester, required: true}, {name: size, var: size}, {name: format, var: format, required: true, default: sdk}, {name: pretty, var: pretty, required: true, default: "true"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, suggester: $suggester, size: $size, format: $format, pretty: $pretty, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Posts a batch of documents to a search domain for indexing. A document batch is a collection of add and delete operations that represent the documents you want to add, update, or delete from your domain. Batches can be described in either JSON or XML. Each item that you want Amazon CloudSearch to return as a search result (such as a product) is represented as a document. Every document has a unique ID and one or more fields that contain the data that you want to search and return in results. Individual documents cannot contain more than 1 MB of data. The entire batch cannot exceed 5 MB. To get the best possible upload performance, group add and delete operations in batches that are close the 5 MB limit. Submitting a large volume of single-document batches can overload a domain's document service. The endpoint for submitting UploadDocuments requests is domain-specific. To get the document endpoint for your domain, use the Amazon CloudSearch configuration service DescribeDomains action. A domain's endpoints are also displayed on the domain dashboard in the Amazon CloudSearch console. For more information about formatting your data for Amazon CloudSearch, see Preparing Your Data (http://docs.aws.amazon.com/cloudsearch/latest/developerguide/preparing-data.html) in the Amazon CloudSearch Developer Guide. For more information about uploading data for indexing, see Uploading Data (http://docs.aws.amazon.com/cloudsearch/latest/developerguide/uploading-data.html) in the Amazon CloudSearch Developer Guide.
#
# POST /2013-01-01/documents/batch
# Returns: record<status: string, adds: int, deletes: int, warnings: table<message: string>>
# operationId: UploadDocuments
export def "upload-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --content-type: string@content-type-completer # The format of the batch you are uploading. Amazon CloudSearch supports two document batch formats: application/json application/xml (required)
  documents: string # A batch of documents formatted in JSON or HTML.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2013-01-01/documents/batch"
    query: [{name: format, var: format, required: true, default: sdk}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: documents, var: documents}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    format: $format, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, content_type: $content_type, documents: $documents
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
