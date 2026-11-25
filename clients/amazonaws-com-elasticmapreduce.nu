# Auto-generated client for Amazon EMR v2009-03-31
# Source: https://api.apis.guru/v2/specs/amazonaws.com/elasticmapreduce/2009-03-31/openapi.json
# Auth: --token flag or $env.AMAZON_EMR_TOKEN

const CLIENT = {
  base_url: "http://elasticmapreduce.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_EMR_TOKEN"
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

def base-url-completer [] { ["http://elasticmapreduce.us-east-1.amazonaws.com" "http://elasticmapreduce.us-east-2.amazonaws.com" "http://elasticmapreduce.us-west-1.amazonaws.com" "http://elasticmapreduce.us-west-2.amazonaws.com" "http://elasticmapreduce.us-gov-west-1.amazonaws.com" "http://elasticmapreduce.us-gov-east-1.amazonaws.com" "http://elasticmapreduce.ca-central-1.amazonaws.com" "http://elasticmapreduce.eu-north-1.amazonaws.com" "http://elasticmapreduce.eu-west-1.amazonaws.com" "http://elasticmapreduce.eu-west-2.amazonaws.com" "http://elasticmapreduce.eu-west-3.amazonaws.com" "http://elasticmapreduce.eu-central-1.amazonaws.com" "http://elasticmapreduce.eu-south-1.amazonaws.com" "http://elasticmapreduce.af-south-1.amazonaws.com" "http://elasticmapreduce.ap-northeast-1.amazonaws.com" "http://elasticmapreduce.ap-northeast-2.amazonaws.com" "http://elasticmapreduce.ap-northeast-3.amazonaws.com" "http://elasticmapreduce.ap-southeast-1.amazonaws.com" "http://elasticmapreduce.ap-southeast-2.amazonaws.com" "http://elasticmapreduce.ap-east-1.amazonaws.com" "http://elasticmapreduce.ap-south-1.amazonaws.com" "http://elasticmapreduce.sa-east-1.amazonaws.com" "http://elasticmapreduce.me-south-1.amazonaws.com" "https://elasticmapreduce.us-east-1.amazonaws.com" "https://elasticmapreduce.us-east-2.amazonaws.com" "https://elasticmapreduce.us-west-1.amazonaws.com" "https://elasticmapreduce.us-west-2.amazonaws.com" "https://elasticmapreduce.us-gov-west-1.amazonaws.com" "https://elasticmapreduce.us-gov-east-1.amazonaws.com" "https://elasticmapreduce.ca-central-1.amazonaws.com" "https://elasticmapreduce.eu-north-1.amazonaws.com" "https://elasticmapreduce.eu-west-1.amazonaws.com" "https://elasticmapreduce.eu-west-2.amazonaws.com" "https://elasticmapreduce.eu-west-3.amazonaws.com" "https://elasticmapreduce.eu-central-1.amazonaws.com" "https://elasticmapreduce.eu-south-1.amazonaws.com" "https://elasticmapreduce.af-south-1.amazonaws.com" "https://elasticmapreduce.ap-northeast-1.amazonaws.com" "https://elasticmapreduce.ap-northeast-2.amazonaws.com" "https://elasticmapreduce.ap-northeast-3.amazonaws.com" "https://elasticmapreduce.ap-southeast-1.amazonaws.com" "https://elasticmapreduce.ap-southeast-2.amazonaws.com" "https://elasticmapreduce.ap-east-1.amazonaws.com" "https://elasticmapreduce.ap-south-1.amazonaws.com" "https://elasticmapreduce.sa-east-1.amazonaws.com" "https://elasticmapreduce.me-south-1.amazonaws.com" "http://elasticmapreduce.amazonaws.com" "https://elasticmapreduce.amazonaws.com" "http://elasticmapreduce.cn-north-1.amazonaws.com.cn" "http://elasticmapreduce.cn-northwest-1.amazonaws.com.cn" "https://elasticmapreduce.cn-north-1.amazonaws.com.cn" "https://elasticmapreduce.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["ElasticMapReduce.AddInstanceFleet"] }
def x-amz-target-completer-1 [] { ["ElasticMapReduce.AddInstanceGroups"] }
def x-amz-target-completer-2 [] { ["ElasticMapReduce.AddJobFlowSteps"] }
def x-amz-target-completer-3 [] { ["ElasticMapReduce.AddTags"] }
def step-cancellation-option-completer [] { ["SEND_INTERRUPT" "TERMINATE_PROCESS"] }
def x-amz-target-completer-4 [] { ["ElasticMapReduce.CancelSteps"] }
def x-amz-target-completer-5 [] { ["ElasticMapReduce.CreateSecurityConfiguration"] }
def auth-mode-completer [] { ["IAM" "SSO"] }
def x-amz-target-completer-6 [] { ["ElasticMapReduce.CreateStudio"] }
def identity-type-completer [] { ["GROUP" "USER"] }
def x-amz-target-completer-7 [] { ["ElasticMapReduce.CreateStudioSessionMapping"] }
def x-amz-target-completer-8 [] { ["ElasticMapReduce.DeleteSecurityConfiguration"] }
def x-amz-target-completer-9 [] { ["ElasticMapReduce.DeleteStudio"] }
def x-amz-target-completer-10 [] { ["ElasticMapReduce.DeleteStudioSessionMapping"] }
def x-amz-target-completer-11 [] { ["ElasticMapReduce.DescribeCluster"] }
def x-amz-target-completer-12 [] { ["ElasticMapReduce.DescribeJobFlows"] }
def x-amz-target-completer-13 [] { ["ElasticMapReduce.DescribeNotebookExecution"] }
def x-amz-target-completer-14 [] { ["ElasticMapReduce.DescribeReleaseLabel"] }
def x-amz-target-completer-15 [] { ["ElasticMapReduce.DescribeSecurityConfiguration"] }
def x-amz-target-completer-16 [] { ["ElasticMapReduce.DescribeStep"] }
def x-amz-target-completer-17 [] { ["ElasticMapReduce.DescribeStudio"] }
def x-amz-target-completer-18 [] { ["ElasticMapReduce.GetAutoTerminationPolicy"] }
def x-amz-target-completer-19 [] { ["ElasticMapReduce.GetBlockPublicAccessConfiguration"] }
def x-amz-target-completer-20 [] { ["ElasticMapReduce.GetClusterSessionCredentials"] }
def x-amz-target-completer-21 [] { ["ElasticMapReduce.GetManagedScalingPolicy"] }
def x-amz-target-completer-22 [] { ["ElasticMapReduce.GetStudioSessionMapping"] }
def x-amz-target-completer-23 [] { ["ElasticMapReduce.ListBootstrapActions"] }
def x-amz-target-completer-24 [] { ["ElasticMapReduce.ListClusters"] }
def x-amz-target-completer-25 [] { ["ElasticMapReduce.ListInstanceFleets"] }
def x-amz-target-completer-26 [] { ["ElasticMapReduce.ListInstanceGroups"] }
def instance-fleet-type-completer [] { ["CORE" "MASTER" "TASK"] }
def x-amz-target-completer-27 [] { ["ElasticMapReduce.ListInstances"] }
def status-completer [] { ["FAILED" "FAILING" "FINISHED" "FINISHING" "RUNNING" "STARTING" "START_PENDING" "STOPPED" "STOPPING" "STOP_PENDING"] }
def x-amz-target-completer-28 [] { ["ElasticMapReduce.ListNotebookExecutions"] }
def x-amz-target-completer-29 [] { ["ElasticMapReduce.ListReleaseLabels"] }
def x-amz-target-completer-30 [] { ["ElasticMapReduce.ListSecurityConfigurations"] }
def x-amz-target-completer-31 [] { ["ElasticMapReduce.ListSteps"] }
def x-amz-target-completer-32 [] { ["ElasticMapReduce.ListStudioSessionMappings"] }
def x-amz-target-completer-33 [] { ["ElasticMapReduce.ListStudios"] }
def x-amz-target-completer-34 [] { ["ElasticMapReduce.ModifyCluster"] }
def x-amz-target-completer-35 [] { ["ElasticMapReduce.ModifyInstanceFleet"] }
def x-amz-target-completer-36 [] { ["ElasticMapReduce.ModifyInstanceGroups"] }
def x-amz-target-completer-37 [] { ["ElasticMapReduce.PutAutoScalingPolicy"] }
def x-amz-target-completer-38 [] { ["ElasticMapReduce.PutAutoTerminationPolicy"] }
def x-amz-target-completer-39 [] { ["ElasticMapReduce.PutBlockPublicAccessConfiguration"] }
def x-amz-target-completer-40 [] { ["ElasticMapReduce.PutManagedScalingPolicy"] }
def x-amz-target-completer-41 [] { ["ElasticMapReduce.RemoveAutoScalingPolicy"] }
def x-amz-target-completer-42 [] { ["ElasticMapReduce.RemoveAutoTerminationPolicy"] }
def x-amz-target-completer-43 [] { ["ElasticMapReduce.RemoveManagedScalingPolicy"] }
def x-amz-target-completer-44 [] { ["ElasticMapReduce.RemoveTags"] }
def scale-down-behavior-completer [] { ["TERMINATE_AT_INSTANCE_HOUR" "TERMINATE_AT_TASK_COMPLETION"] }
def repo-upgrade-on-boot-completer [] { ["NONE" "SECURITY"] }
def x-amz-target-completer-45 [] { ["ElasticMapReduce.RunJobFlow"] }
def x-amz-target-completer-46 [] { ["ElasticMapReduce.SetTerminationProtection"] }
def x-amz-target-completer-47 [] { ["ElasticMapReduce.SetVisibleToAllUsers"] }
def x-amz-target-completer-48 [] { ["ElasticMapReduce.StartNotebookExecution"] }
def x-amz-target-completer-49 [] { ["ElasticMapReduce.StopNotebookExecution"] }
def x-amz-target-completer-50 [] { ["ElasticMapReduce.TerminateJobFlows"] }
def x-amz-target-completer-51 [] { ["ElasticMapReduce.UpdateStudio"] }
def x-amz-target-completer-52 [] { ["ElasticMapReduce.UpdateStudioSessionMapping"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    add-instance-fleet: "record<ClusterId: string, InstanceFleetId: string, ClusterArn: string>"
    add-instance-groups: "record<JobFlowId: string, InstanceGroupIds: list<string>, ClusterArn: string>"
    add-job-flow-steps: "record<StepIds: list<string>>"
    add-tags: "record"
    cancel-steps: "record<CancelStepsInfoList: table<StepId: string, Status: string, Reason: string>>"
    create-security-configuration: "record<Name: string, CreationDateTime: string>"
    create-studio: "record<StudioId: string, Url: string>"
    delete-security-configuration: "record"
    describe-cluster: "record<Cluster: record<Id: string, Name: string, Status: record<State: string, StateChangeReason: record, Timeline: record, ErrorDetails: list>, Ec2InstanceAttributes: record<Ec2KeyName: string, Ec2SubnetId: string, RequestedEc2SubnetIds: list, Ec2AvailabilityZone: string, RequestedEc2AvailabilityZones: list, IamInstanceProfile: string, EmrManagedMasterSecurityGroup: string, EmrManagedSlaveSecurityGroup: string, ServiceAccessSecurityGroup: string, AdditionalMasterSecurityGroups: list, AdditionalSlaveSecurityGroups: list>, InstanceCollectionType: string, LogUri: string, LogEncryptionKmsKeyId: string, RequestedAmiVersion: string, RunningAmiVersion: string, ReleaseLabel: string, AutoTerminate: bool, TerminationProtected: bool, VisibleToAllUsers: bool, Applications: list<record>, Tags: list<record>, ServiceRole: string, NormalizedInstanceHours: int, MasterPublicDnsName: string, Configurations: list<record>, SecurityConfiguration: string, AutoScalingRole: string, ScaleDownBehavior: string, CustomAmiId: string, EbsRootVolumeSize: int, RepoUpgradeOnBoot: string, KerberosAttributes: record<Realm: string, KdcAdminPassword: string, CrossRealmTrustPrincipalPassword: string, ADDomainJoinUser: string, ADDomainJoinPassword: string>, ClusterArn: string, OutpostArn: string, StepConcurrencyLevel: int, PlacementGroups: list<record>, OSReleaseLabel: string>>"
    describe-job-flows: "record<JobFlows: table<JobFlowId: string, Name: string, LogUri: string, LogEncryptionKmsKeyId: string, AmiVersion: string, ExecutionStatusDetail: record, Instances: record, Steps: list, BootstrapActions: list, SupportedProducts: list, VisibleToAllUsers: bool, JobFlowRole: string, ServiceRole: string, AutoScalingRole: string, ScaleDownBehavior: string>>"
    describe-notebook-execution: "record<NotebookExecution: record<NotebookExecutionId: string, EditorId: string, ExecutionEngine: record<Id: string, Type: string, MasterInstanceSecurityGroupId: string>, NotebookExecutionName: string, NotebookParams: string, Status: string, StartTime: string, EndTime: string, Arn: string, OutputNotebookURI: string, LastStateChangeReason: string, NotebookInstanceSecurityGroupId: string, Tags: list<record>>>"
    describe-release-label: "record<ReleaseLabel: string, Applications: table<Name: string, Version: string>, NextToken: string, AvailableOSReleases: table<Label: string>>"
    describe-security-configuration: "record<Name: string, SecurityConfiguration: string, CreationDateTime: string>"
    describe-step: "record<Step: record<Id: string, Name: string, Config: record<Jar: string, Properties: record, MainClass: string, Args: list>, ActionOnFailure: string, Status: record<State: string, StateChangeReason: record, FailureDetails: record, Timeline: record>, ExecutionRoleArn: string>>"
    describe-studio: "record<Studio: record<StudioId: string, StudioArn: string, Name: string, Description: string, AuthMode: string, VpcId: string, SubnetIds: list<string>, ServiceRole: string, UserRole: string, WorkspaceSecurityGroupId: string, EngineSecurityGroupId: string, Url: string, CreationTime: string, DefaultS3Location: string, IdpAuthUrl: string, IdpRelayStateParameterName: string, Tags: list<record>>>"
    get-auto-termination-policy: "record<AutoTerminationPolicy: record<IdleTimeout: int>>"
    get-block-public-access-configuration: "record<BlockPublicAccessConfiguration: record<BlockPublicSecurityGroupRules: bool, PermittedPublicSecurityGroupRuleRanges: list<record>>, BlockPublicAccessConfigurationMetadata: record<CreationDateTime: string, CreatedByArn: string>>"
    get-cluster-session-credentials: "record<Credentials: record<UsernamePassword: record<Username: string, Password: string>>, ExpiresAt: string>"
    get-managed-scaling-policy: "record<ManagedScalingPolicy: record<ComputeLimits: record<UnitType: string, MinimumCapacityUnits: int, MaximumCapacityUnits: int, MaximumOnDemandCapacityUnits: int, MaximumCoreCapacityUnits: int>>>"
    get-studio-session-mapping: "record<SessionMapping: record<StudioId: string, IdentityId: string, IdentityName: string, IdentityType: string, SessionPolicyArn: string, CreationTime: string, LastModifiedTime: string>>"
    list-bootstrap-actions: "record<BootstrapActions: table<Name: string, ScriptPath: string, Args: list>, Marker: string>"
    list-clusters: "record<Clusters: table<Id: string, Name: string, Status: record, NormalizedInstanceHours: int, ClusterArn: string, OutpostArn: string>, Marker: string>"
    list-instance-fleets: "record<InstanceFleets: table<Id: string, Name: string, Status: record, InstanceFleetType: string, TargetOnDemandCapacity: int, TargetSpotCapacity: int, ProvisionedOnDemandCapacity: int, ProvisionedSpotCapacity: int, InstanceTypeSpecifications: list, LaunchSpecifications: record, ResizeSpecifications: record>, Marker: string>"
    list-instance-groups: "record<InstanceGroups: table<Id: string, Name: string, Market: string, InstanceGroupType: string, BidPrice: string, InstanceType: string, RequestedInstanceCount: int, RunningInstanceCount: int, Status: record, Configurations: list, ConfigurationsVersion: int, LastSuccessfullyAppliedConfigurations: list, LastSuccessfullyAppliedConfigurationsVersion: int, EbsBlockDevices: list, EbsOptimized: bool, ShrinkPolicy: record, AutoScalingPolicy: record, CustomAmiId: string>, Marker: string>"
    list-instances: "record<Instances: table<Id: string, Ec2InstanceId: string, PublicDnsName: string, PublicIpAddress: string, PrivateDnsName: string, PrivateIpAddress: string, Status: record, InstanceGroupId: string, InstanceFleetId: string, Market: string, InstanceType: string, EbsVolumes: list>, Marker: string>"
    list-notebook-executions: "record<NotebookExecutions: table<NotebookExecutionId: string, EditorId: string, NotebookExecutionName: string, Status: string, StartTime: string, EndTime: string>, Marker: string>"
    list-release-labels: "record<ReleaseLabels: list<string>, NextToken: string>"
    list-security-configurations: "record<SecurityConfigurations: table<Name: string, CreationDateTime: string>, Marker: string>"
    list-steps: "record<Steps: table<Id: string, Name: string, Config: record, ActionOnFailure: string, Status: record>, Marker: string>"
    list-studio-session-mappings: "record<SessionMappings: table<StudioId: string, IdentityId: string, IdentityName: string, IdentityType: string, SessionPolicyArn: string, CreationTime: string>, Marker: string>"
    list-studios: "record<Studios: table<StudioId: string, Name: string, VpcId: string, Description: string, Url: string, AuthMode: string, CreationTime: string>, Marker: string>"
    modify-cluster: "record<StepConcurrencyLevel: int>"
    put-auto-scaling-policy: "record<ClusterId: string, InstanceGroupId: string, AutoScalingPolicy: record<Status: record<State: string, StateChangeReason: record>, Constraints: record<MinCapacity: int, MaxCapacity: int>, Rules: list<record>>, ClusterArn: string>"
    put-auto-termination-policy: "record"
    put-block-public-access-configuration: "record"
    put-managed-scaling-policy: "record"
    remove-auto-scaling-policy: "record"
    remove-auto-termination-policy: "record"
    remove-managed-scaling-policy: "record"
    remove-tags: "record"
    run-job-flow: "record<JobFlowId: string, ClusterArn: string>"
    start-notebook-execution: "record<NotebookExecutionId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["add-instance-fleet" "add-instance-groups" "add-job-flow-steps" "add-tags" "cancel-steps" "create-security-configuration" "create-studio" "create-studio-session-mapping" "delete-security-configuration" "delete-studio" "delete-studio-session-mapping" "describe-cluster" "describe-job-flows" "describe-notebook-execution" "describe-release-label" "describe-security-configuration" "describe-step" "describe-studio" "get-auto-termination-policy" "get-block-public-access-configuration" "get-cluster-session-credentials" "get-managed-scaling-policy" "get-studio-session-mapping" "list-bootstrap-actions" "list-clusters" "list-instance-fleets" "list-instance-groups" "list-instances" "list-notebook-executions" "list-release-labels" "list-security-configurations" "list-steps" "list-studio-session-mappings" "list-studios" "modify-cluster" "modify-instance-fleet" "modify-instance-groups" "put-auto-scaling-policy" "put-auto-termination-policy" "put-block-public-access-configuration" "put-managed-scaling-policy" "remove-auto-scaling-policy" "remove-auto-termination-policy" "remove-managed-scaling-policy" "remove-tags" "run-job-flow" "set-termination-protection" "set-visible-to-all-users" "start-notebook-execution" "stop-notebook-execution" "terminate-job-flows" "update-studio" "update-studio-session-mapping" "commands"] | sort) } | get name | first)
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

# Adds an instance fleet to a running cluster. The instance fleet configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x.
#
# POST /
# Returns: record<ClusterId: string, InstanceFleetId: string, ClusterArn: string>
# operationId: AddInstanceFleet
export def "add-instance-fleet" [
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
  --x-amz-target: string@x-amz-target-completer # required
  cluster_id: string # The unique identifier of the cluster.
  instance_fleet: record # The configuration that defines an instance fleet. The instance fleet configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x versions. — shape: {Name?: string, InstanceFleetType: "MASTER"|"CORE"|"TASK", TargetOnDemandCapacity?: int, TargetSpotCapacity?: int, InstanceTypeConfigs?: list, LaunchSpecifications?: record, ResizeSpecifications?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.AddInstanceFleet"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: InstanceFleet, var: instance_fleet}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, instance_fleet: $instance_fleet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds one or more instance groups to a running cluster.
#
# POST /
# Returns: record<JobFlowId: string, InstanceGroupIds: list<string>, ClusterArn: string>
# operationId: AddInstanceGroups
export def "add-instance-groups" [
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
  --x-amz-target: string@x-amz-target-completer-1 # required
  instance_groups: list # Instance groups to add. — item shape: {Name?: string, Market?: "ON_DEMAND"|"SPOT", InstanceRole: "MASTER"|"CORE"|"TASK", BidPrice?: string, InstanceType: string, InstanceCount: int, Configurations?: list, EbsConfiguration?: record, AutoScalingPolicy?: record, CustomAmiId?: string}
  job_flow_id: string # Job flow in which to add the instance groups.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.AddInstanceGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceGroups, var: instance_groups}, {name: JobFlowId, var: job_flow_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_groups: $instance_groups, job_flow_id: $job_flow_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AddJobFlowSteps adds new steps to a running cluster. A maximum of 256 steps are allowed in each job flow. If your cluster is long-running (such as a Hive data warehouse) or complex, you may require more than 256 steps to process your data. You can bypass the 256-step limitation in various ways, including using SSH to connect to the master node and submitting queries directly to the software running on the master node, such as Hive and Hadoop. A step specifies the location of a JAR file stored either on the master node of the cluster or in Amazon S3. Each step is performed by the main function of the main class of the JAR file. The main class can be specified either in the manifest of the JAR or by using the MainFunction parameter of the step. Amazon EMR executes each step in the order listed. For a step to be considered complete, the main function must exit with a zero exit code and all Hadoop jobs started while the step was running must have completed and run successfully. You can only add steps to a cluster that is in one of the following states: STARTING, BOOTSTRAPPING, RUNNING, or WAITING. The string values passed into HadoopJarStep object cannot exceed a total of 10240 characters.
#
# POST /
# Returns: record<StepIds: list<string>>
# operationId: AddJobFlowSteps
export def "add-job-flow-steps" [
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
  --x-amz-target: string@x-amz-target-completer-2 # required
  job_flow_id: string # A string that uniquely identifies the job flow. This identifier is returned by RunJobFlow and can also be obtained from ListClusters.
  steps: list # A list of StepConfig to be executed by the job flow. — item shape: {Name: string, ActionOnFailure?: "TERMINATE_JOB_FLOW"|"TERMINATE_CLUSTER"|"CANCEL_AND_WAIT"|"CONTINUE", HadoopJarStep: record}
  --execution-role-arn: string # The Amazon Resource Name (ARN) of the runtime role for a step on the cluster. The runtime role can be a cross-account IAM role. The runtime role ARN is a combination of account ID, role name, and role type using the following format: arn:partition:service:region:account:resource. For example, arn:aws:iam::1234567890:role/ReadOnly is a correctly formatted runtime role ARN.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.AddJobFlowSteps"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobFlowId, var: job_flow_id}, {name: Steps, var: steps}, {name: ExecutionRoleArn, var: execution_role_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_flow_id: $job_flow_id, steps: $steps, execution_role_arn: $execution_role_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds tags to an Amazon EMR resource, such as a cluster or an Amazon EMR Studio. Tags make it easier to associate resources in various ways, such as grouping clusters to track your Amazon EMR resource allocation costs. For more information, see Tag Clusters (https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-tags.html).
#
# POST /
# Returns: record
# operationId: AddTags
export def "add-tags" [
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
  --x-amz-target: string@x-amz-target-completer-3 # required
  resource_id: string # The Amazon EMR resource identifier to which tags will be added. For example, a cluster identifier or an Amazon EMR Studio ID.
  tags: list # A list of tags to associate with a resource. Tags are user-defined key-value pairs that consist of a required key string with a maximum of 128 characters, and an optional value string with a maximum of 256 characters. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.AddTags"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a pending step or steps in a running cluster. Available only in Amazon EMR versions 4.8.0 and later, excluding version 5.0.0. A maximum of 256 steps are allowed in each CancelSteps request. CancelSteps is idempotent but asynchronous; it does not guarantee that a step will be canceled, even if the request is successfully submitted. When you use Amazon EMR versions 5.28.0 and later, you can cancel steps that are in a PENDING or RUNNING state. In earlier versions of Amazon EMR, you can only cancel steps that are in a PENDING state.
#
# POST /
# Returns: record<CancelStepsInfoList: table<StepId: string, Status: string, Reason: string>>
# operationId: CancelSteps
export def "cancel-steps" [
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
  --x-amz-target: string@x-amz-target-completer-4 # required
  cluster_id: string # The ClusterID for the specified steps that will be canceled. Use RunJobFlow and ListClusters to get ClusterIDs.
  step_ids: list<string> # The list of StepIDs to cancel. Use ListSteps to get steps and their states for the specified cluster.
  --step-cancellation-option: string@step-cancellation-option-completer # The option to choose to cancel RUNNING steps. By default, the value is SEND_INTERRUPT.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.CancelSteps"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: StepIds, var: step_ids}, {name: StepCancellationOption, var: step_cancellation_option}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, step_ids: $step_ids, step_cancellation_option: $step_cancellation_option
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a security configuration, which is stored in the service and can be specified when a cluster is created.
#
# POST /
# Returns: record<Name: string, CreationDateTime: string>
# operationId: CreateSecurityConfiguration
export def "create-security-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-5 # required
  name: string # The name of the security configuration.
  security_configuration: string # The security configuration details in JSON format. For JSON parameters and examples, see Use Security Configurations to Set Up Cluster Security (https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-security-configurations.html) in the Amazon EMR Management Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.CreateSecurityConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: SecurityConfiguration, var: security_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, security_configuration: $security_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Amazon EMR Studio.
#
# POST /
# Returns: record<StudioId: string, Url: string>
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
  --x-amz-target: string@x-amz-target-completer-6 # required
  name: string # A descriptive name for the Amazon EMR Studio.
  --description: string # A detailed description of the Amazon EMR Studio.
  auth_mode: string@auth-mode-completer # Specifies whether the Studio authenticates users using IAM or IAM Identity Center.
  vpc_id: string # The ID of the Amazon Virtual Private Cloud (Amazon VPC) to associate with the Studio.
  subnet_ids: list<string> # A list of subnet IDs to associate with the Amazon EMR Studio. A Studio can have a maximum of 5 subnets. The subnets must belong to the VPC specified by VpcId. Studio users can create a Workspace in any of the specified subnets.
  service_role: string # The IAM role that the Amazon EMR Studio assumes. The service role provides a way for Amazon EMR Studio to interoperate with other Amazon Web Services services.
  --user-role: string # The IAM user role that users and groups assume when logged in to an Amazon EMR Studio. Only specify a UserRole when you use IAM Identity Center authentication. The permissions attached to the UserRole can be scoped down for each user or group using session policies.
  workspace_security_group_id: string # The ID of the Amazon EMR Studio Workspace security group. The Workspace security group allows outbound network traffic to resources in the Engine security group, and it must be in the same VPC specified by VpcId.
  engine_security_group_id: string # The ID of the Amazon EMR Studio Engine security group. The Engine security group allows inbound network traffic from the Workspace security group, and it must be in the same VPC specified by VpcId.
  default_s3_location: string # The Amazon S3 location to back up Amazon EMR Studio Workspaces and notebook files.
  --idp-auth-url: string # The authentication endpoint of your identity provider (IdP). Specify this value when you use IAM authentication and want to let federated users log in to a Studio with the Studio URL and credentials from your IdP. Amazon EMR Studio redirects users to this endpoint to enter credentials.
  --idp-relay-state-parameter-name: string # The name that your identity provider (IdP) uses for its RelayState parameter. For example, RelayState or TargetSource. Specify this value when you use IAM authentication and want to let federated users log in to a Studio using the Studio URL. The RelayState parameter differs by IdP.
  --tags: list # A list of tags to associate with the Amazon EMR Studio. Tags are user-defined key-value pairs that consist of a required key string with a maximum of 128 characters, and an optional value string with a maximum of 256 characters. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.CreateStudio"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: AuthMode, var: auth_mode}, {name: VpcId, var: vpc_id}, {name: SubnetIds, var: subnet_ids}, {name: ServiceRole, var: service_role}, {name: UserRole, var: user_role}, {name: WorkspaceSecurityGroupId, var: workspace_security_group_id}, {name: EngineSecurityGroupId, var: engine_security_group_id}, {name: DefaultS3Location, var: default_s3_location}, {name: IdpAuthUrl, var: idp_auth_url}, {name: IdpRelayStateParameterName, var: idp_relay_state_parameter_name}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, auth_mode: $auth_mode, vpc_id: $vpc_id, subnet_ids: $subnet_ids, service_role: $service_role, user_role: $user_role, workspace_security_group_id: $workspace_security_group_id, engine_security_group_id: $engine_security_group_id, default_s3_location: $default_s3_location, idp_auth_url: $idp_auth_url, idp_relay_state_parameter_name: $idp_relay_state_parameter_name, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Maps a user or group to the Amazon EMR Studio specified by StudioId, and applies a session policy to refine Studio permissions for that user or group. Use CreateStudioSessionMapping to assign users to a Studio when you use IAM Identity Center authentication. For instructions on how to assign users to a Studio when you use IAM authentication, see Assign a user or group to your EMR Studio (https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-studio-manage-users.html#emr-studio-assign-users-groups).
#
# POST /
# operationId: CreateStudioSessionMapping
export def "create-studio-session-mapping" [
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
  --x-amz-target: string@x-amz-target-completer-7 # required
  studio_id: string # The ID of the Amazon EMR Studio to which the user or group will be mapped.
  --identity-id: string # The globally unique identifier (GUID) of the user or group from the IAM Identity Center Identity Store. For more information, see UserId (https://docs.aws.amazon.com/singlesignon/latest/IdentityStoreAPIReference/API_User.html#singlesignon-Type-User-UserId) and GroupId (https://docs.aws.amazon.com/singlesignon/latest/IdentityStoreAPIReference/API_Group.html#singlesignon-Type-Group-GroupId) in the IAM Identity Center Identity Store API Reference. Either IdentityName or IdentityId must be specified, but not both.
  --identity-name: string # The name of the user or group. For more information, see UserName (https://docs.aws.amazon.com/singlesignon/latest/IdentityStoreAPIReference/API_User.html#singlesignon-Type-User-UserName) and DisplayName (https://docs.aws.amazon.com/singlesignon/latest/IdentityStoreAPIReference/API_Group.html#singlesignon-Type-Group-DisplayName) in the IAM Identity Center Identity Store API Reference. Either IdentityName or IdentityId must be specified, but not both.
  identity_type: string@identity-type-completer # Specifies whether the identity to map to the Amazon EMR Studio is a user or a group.
  session_policy_arn: string # The Amazon Resource Name (ARN) for the session policy that will be applied to the user or group. You should specify the ARN for the session policy that you want to apply, not the ARN of your user role. For more information, see Create an EMR Studio User Role with Session Policies (https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-studio-user-role.html).
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.CreateStudioSessionMapping"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StudioId, var: studio_id}, {name: IdentityId, var: identity_id}, {name: IdentityName, var: identity_name}, {name: IdentityType, var: identity_type}, {name: SessionPolicyArn, var: session_policy_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, studio_id: $studio_id, identity_id: $identity_id, identity_name: $identity_name, identity_type: $identity_type, session_policy_arn: $session_policy_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a security configuration.
#
# POST /
# Returns: record
# operationId: DeleteSecurityConfiguration
export def "delete-security-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  name: string # The name of the security configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.DeleteSecurityConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an Amazon EMR Studio from the Studio metadata store.
#
# POST /
# operationId: DeleteStudio
export def "delete-studio" [
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
  --x-amz-target: string@x-amz-target-completer-9 # required
  studio_id: string # The ID of the Amazon EMR Studio.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.DeleteStudio"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StudioId, var: studio_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, studio_id: $studio_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user or group from an Amazon EMR Studio.
#
# POST /
# operationId: DeleteStudioSessionMapping
export def "delete-studio-session-mapping" [
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
  --x-amz-target: string@x-amz-target-completer-10 # required
  studio_id: string # The ID of the Amazon EMR Studio.
  --identity-id: string # The globally unique identifier (GUID) of the user or group to remove from the Amazon EMR Studio. For more information, see UserId (https://docs.aws.amazon.com/singlesignon/latest/IdentityStoreAPIReference/API_User.html#singlesignon-Type-User-UserId) and GroupId (https://docs.aws.amazon.com/singlesignon/latest/IdentityStoreAPIReference/API_Group.html#singlesignon-Type-Group-GroupId) in the IAM Identity Center Identity Store API Reference. Either IdentityName or IdentityId must be specified.
  --identity-name: string # The name of the user name or group to remove from the Amazon EMR Studio. For more information, see UserName (https://docs.aws.amazon.com/singlesignon/latest/IdentityStoreAPIReference/API_User.html#singlesignon-Type-User-UserName) and DisplayName (https://docs.aws.amazon.com/singlesignon/latest/IdentityStoreAPIReference/API_Group.html#singlesignon-Type-Group-DisplayName) in the IAM Identity Center Store API Reference. Either IdentityName or IdentityId must be specified.
  identity_type: string@identity-type-completer # Specifies whether the identity to delete from the Amazon EMR Studio is a user or a group.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.DeleteStudioSessionMapping"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StudioId, var: studio_id}, {name: IdentityId, var: identity_id}, {name: IdentityName, var: identity_name}, {name: IdentityType, var: identity_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, studio_id: $studio_id, identity_id: $identity_id, identity_name: $identity_name, identity_type: $identity_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides cluster-level details including status, hardware and software configuration, VPC settings, and so on.
#
# POST /
# Returns: record<Cluster: record<Id: string, Name: string, Status: record<State: string, StateChangeReason: record, Timeline: record, ErrorDetails: list>, Ec2InstanceAttributes: record<Ec2KeyName: string, Ec2SubnetId: string, RequestedEc2SubnetIds: list, Ec2AvailabilityZone: string, RequestedEc2AvailabilityZones: list, IamInstanceProfile: string, EmrManagedMasterSecurityGroup: string, EmrManagedSlaveSecurityGroup: string, ServiceAccessSecurityGroup: string, AdditionalMasterSecurityGroups: list, AdditionalSlaveSecurityGroups: list>, InstanceCollectionType: string, LogUri: string, LogEncryptionKmsKeyId: string, RequestedAmiVersion: string, RunningAmiVersion: string, ReleaseLabel: string, AutoTerminate: bool, TerminationProtected: bool, VisibleToAllUsers: bool, Applications: list<record>, Tags: list<record>, ServiceRole: string, NormalizedInstanceHours: int, MasterPublicDnsName: string, Configurations: list<record>, SecurityConfiguration: string, AutoScalingRole: string, ScaleDownBehavior: string, CustomAmiId: string, EbsRootVolumeSize: int, RepoUpgradeOnBoot: string, KerberosAttributes: record<Realm: string, KdcAdminPassword: string, CrossRealmTrustPrincipalPassword: string, ADDomainJoinUser: string, ADDomainJoinPassword: string>, ClusterArn: string, OutpostArn: string, StepConcurrencyLevel: int, PlacementGroups: list<record>, OSReleaseLabel: string>>
# operationId: DescribeCluster
export def "describe-cluster" [
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
  --x-amz-target: string@x-amz-target-completer-11 # required
  cluster_id: string # The identifier of the cluster to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.DescribeCluster"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is no longer supported and will eventually be removed. We recommend you use ListClusters, DescribeCluster, ListSteps, ListInstanceGroups and ListBootstrapActions instead. DescribeJobFlows returns a list of job flows that match all of the supplied parameters. The parameters can include a list of job flow IDs, job flow states, and restrictions on job flow creation date and time. Regardless of supplied parameters, only job flows created within the last two months are returned. If no parameters are supplied, then job flows matching either of the following criteria are returned: Job flows created and completed in the last two weeks Job flows created within the last two months that are in one of the following states: RUNNING, WAITING, SHUTTING_DOWN, STARTING Amazon EMR can return a maximum of 512 job flow descriptions.
#
# POST /
# DEPRECATED
# Returns: record<JobFlows: table<JobFlowId: string, Name: string, LogUri: string, LogEncryptionKmsKeyId: string, AmiVersion: string, ExecutionStatusDetail: record, Instances: record, Steps: list, BootstrapActions: list, SupportedProducts: list, VisibleToAllUsers: bool, JobFlowRole: string, ServiceRole: string, AutoScalingRole: string, ScaleDownBehavior: string>>
# operationId: DescribeJobFlows
@deprecated
export def "describe-job-flows" [
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
  --x-amz-target: string@x-amz-target-completer-12 # required
  --created-after: string # Return only job flows created after this date and time. (format: date-time)
  --created-before: string # Return only job flows created before this date and time. (format: date-time)
  --job-flow-ids: list<string> # Return only job flows whose job flow ID is contained in this list.
  --job-flow-states: list<string> # Return only job flows whose state is contained in this list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.DescribeJobFlows"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreatedAfter, var: created_after}, {name: CreatedBefore, var: created_before}, {name: JobFlowIds, var: job_flow_ids}, {name: JobFlowStates, var: job_flow_states}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, created_after: $created_after, created_before: $created_before, job_flow_ids: $job_flow_ids, job_flow_states: $job_flow_states
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides details of a notebook execution.
#
# POST /
# Returns: record<NotebookExecution: record<NotebookExecutionId: string, EditorId: string, ExecutionEngine: record<Id: string, Type: string, MasterInstanceSecurityGroupId: string>, NotebookExecutionName: string, NotebookParams: string, Status: string, StartTime: string, EndTime: string, Arn: string, OutputNotebookURI: string, LastStateChangeReason: string, NotebookInstanceSecurityGroupId: string, Tags: list<record>>>
# operationId: DescribeNotebookExecution
export def "describe-notebook-execution" [
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
  --x-amz-target: string@x-amz-target-completer-13 # required
  notebook_execution_id: string # The unique identifier of the notebook execution.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.DescribeNotebookExecution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NotebookExecutionId, var: notebook_execution_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, notebook_execution_id: $notebook_execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides EMR release label details, such as releases available the region where the API request is run, and the available applications for a specific EMR release label. Can also list EMR release versions that support a specified version of Spark.
#
# POST /
# Returns: record<ReleaseLabel: string, Applications: table<Name: string, Version: string>, NextToken: string, AvailableOSReleases: table<Label: string>>
# operationId: DescribeReleaseLabel
export def "describe-release-label" [
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
  --x-amz-target: string@x-amz-target-completer-14 # required
  --release-label: string # The target release label to be described.
  --next-token: string # The pagination token. Reserved for future use. Currently set to null.
  --max-results: int # Reserved for future use. Currently set to null.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.DescribeReleaseLabel"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReleaseLabel, var: release_label}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, release_label: $release_label, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides the details of a security configuration by returning the configuration JSON.
#
# POST /
# Returns: record<Name: string, SecurityConfiguration: string, CreationDateTime: string>
# operationId: DescribeSecurityConfiguration
export def "describe-security-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  name: string # The name of the security configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.DescribeSecurityConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides more detail about the cluster step.
#
# POST /
# Returns: record<Step: record<Id: string, Name: string, Config: record<Jar: string, Properties: record, MainClass: string, Args: list>, ActionOnFailure: string, Status: record<State: string, StateChangeReason: record, FailureDetails: record, Timeline: record>, ExecutionRoleArn: string>>
# operationId: DescribeStep
export def "describe-step" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  cluster_id: string # The identifier of the cluster with steps to describe.
  step_id: string # The identifier of the step to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.DescribeStep"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: StepId, var: step_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, step_id: $step_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns details for the specified Amazon EMR Studio including ID, Name, VPC, Studio access URL, and so on.
#
# POST /
# Returns: record<Studio: record<StudioId: string, StudioArn: string, Name: string, Description: string, AuthMode: string, VpcId: string, SubnetIds: list<string>, ServiceRole: string, UserRole: string, WorkspaceSecurityGroupId: string, EngineSecurityGroupId: string, Url: string, CreationTime: string, DefaultS3Location: string, IdpAuthUrl: string, IdpRelayStateParameterName: string, Tags: list<record>>>
# operationId: DescribeStudio
export def "describe-studio" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  studio_id: string # The Amazon EMR Studio ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.DescribeStudio"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StudioId, var: studio_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, studio_id: $studio_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the auto-termination policy for an Amazon EMR cluster.
#
# POST /
# Returns: record<AutoTerminationPolicy: record<IdleTimeout: int>>
# operationId: GetAutoTerminationPolicy
export def "get-auto-termination-policy" [
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  cluster_id: string # Specifies the ID of the Amazon EMR cluster for which the auto-termination policy will be fetched.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.GetAutoTerminationPolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the Amazon EMR block public access configuration for your Amazon Web Services account in the current Region. For more information see Configure Block Public Access for Amazon EMR (https://docs.aws.amazon.com/emr/latest/ManagementGuide/configure-block-public-access.html) in the Amazon EMR Management Guide.
#
# POST /
# Returns: record<BlockPublicAccessConfiguration: record<BlockPublicSecurityGroupRules: bool, PermittedPublicSecurityGroupRuleRanges: list<record>>, BlockPublicAccessConfigurationMetadata: record<CreationDateTime: string, CreatedByArn: string>>
# operationId: GetBlockPublicAccessConfiguration
export def "get-block-public-access-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.GetBlockPublicAccessConfiguration"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides temporary, HTTP basic credentials that are associated with a given runtime IAM role and used by a cluster with fine-grained access control activated. You can use these credentials to connect to cluster endpoints that support username and password authentication.
#
# POST /
# Returns: record<Credentials: record<UsernamePassword: record<Username: string, Password: string>>, ExpiresAt: string>
# operationId: GetClusterSessionCredentials
export def "get-cluster-session-credentials" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  cluster_id: string # The unique identifier of the cluster.
  execution_role_arn: string # The Amazon Resource Name (ARN) of the runtime role for interactive workload submission on the cluster. The runtime role can be a cross-account IAM role. The runtime role ARN is a combination of account ID, role name, and role type using the following format: arn:partition:service:region:account:resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.GetClusterSessionCredentials"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: ExecutionRoleArn, var: execution_role_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, execution_role_arn: $execution_role_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the attached managed scaling policy for an Amazon EMR cluster.
#
# POST /
# Returns: record<ManagedScalingPolicy: record<ComputeLimits: record<UnitType: string, MinimumCapacityUnits: int, MaximumCapacityUnits: int, MaximumOnDemandCapacityUnits: int, MaximumCoreCapacityUnits: int>>>
# operationId: GetManagedScalingPolicy
export def "get-managed-scaling-policy" [
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
  --x-amz-target: string@x-amz-target-completer-21 # required
  cluster_id: string # Specifies the ID of the cluster for which the managed scaling policy will be fetched.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.GetManagedScalingPolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches mapping details for the specified Amazon EMR Studio and identity (user or group).
#
# POST /
# Returns: record<SessionMapping: record<StudioId: string, IdentityId: string, IdentityName: string, IdentityType: string, SessionPolicyArn: string, CreationTime: string, LastModifiedTime: string>>
# operationId: GetStudioSessionMapping
export def "get-studio-session-mapping" [
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
  --x-amz-target: string@x-amz-target-completer-22 # required
  studio_id: string # The ID of the Amazon EMR Studio.
  --identity-id: string # The globally unique identifier (GUID) of the user or group. For more information, see UserId (https://docs.aws.amazon.com/singlesignon/latest/IdentityStoreAPIReference/API_User.html#singlesignon-Type-User-UserId) and GroupId (https://docs.aws.amazon.com/singlesignon/latest/IdentityStoreAPIReference/API_Group.html#singlesignon-Type-Group-GroupId) in the IAM Identity Center Identity Store API Reference. Either IdentityName or IdentityId must be specified.
  --identity-name: string # The name of the user or group to fetch. For more information, see UserName (https://docs.aws.amazon.com/singlesignon/latest/IdentityStoreAPIReference/API_User.html#singlesignon-Type-User-UserName) and DisplayName (https://docs.aws.amazon.com/singlesignon/latest/IdentityStoreAPIReference/API_Group.html#singlesignon-Type-Group-DisplayName) in the IAM Identity Center Identity Store API Reference. Either IdentityName or IdentityId must be specified.
  identity_type: string@identity-type-completer # Specifies whether the identity to fetch is a user or a group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.GetStudioSessionMapping"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StudioId, var: studio_id}, {name: IdentityId, var: identity_id}, {name: IdentityName, var: identity_name}, {name: IdentityType, var: identity_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, studio_id: $studio_id, identity_id: $identity_id, identity_name: $identity_name, identity_type: $identity_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides information about the bootstrap actions associated with a cluster.
#
# POST /
# Returns: record<BootstrapActions: table<Name: string, ScriptPath: string, Args: list>, Marker: string>
# operationId: ListBootstrapActions
export def "list-bootstrap-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-23 # required
  cluster_id: string # The cluster identifier for the bootstrap actions to list.
  --body-marker: string # The pagination token that indicates the next set of results to retrieve. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.ListBootstrapActions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides the status of all clusters visible to this Amazon Web Services account. Allows you to filter the list of clusters based on certain criteria; for example, filtering by cluster creation date and time or by status. This call returns a maximum of 50 clusters in unsorted order per call, but returns a marker to track the paging of the cluster list across multiple ListClusters calls.
#
# POST /
# Returns: record<Clusters: table<Id: string, Name: string, Status: record, NormalizedInstanceHours: int, ClusterArn: string, OutpostArn: string>, Marker: string>
# operationId: ListClusters
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-24 # required
  --created-after: string # The creation date and time beginning value filter for listing clusters. (format: date-time)
  --created-before: string # The creation date and time end value filter for listing clusters. (format: date-time)
  --cluster-states: list<string> # The cluster state filters to apply when listing clusters. Clusters that change state while this action runs may be not be returned as expected in the list of clusters.
  --body-marker: string # The pagination token that indicates the next set of results to retrieve. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.ListClusters"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreatedAfter, var: created_after}, {name: CreatedBefore, var: created_before}, {name: ClusterStates, var: cluster_states}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, created_after: $created_after, created_before: $created_before, cluster_states: $cluster_states, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all available details about the instance fleets in a cluster. The instance fleet configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x versions.
#
# POST /
# Returns: record<InstanceFleets: table<Id: string, Name: string, Status: record, InstanceFleetType: string, TargetOnDemandCapacity: int, TargetSpotCapacity: int, ProvisionedOnDemandCapacity: int, ProvisionedSpotCapacity: int, InstanceTypeSpecifications: list, LaunchSpecifications: record, ResizeSpecifications: record>, Marker: string>
# operationId: ListInstanceFleets
export def "list-instance-fleets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-25 # required
  cluster_id: string # The unique identifier of the cluster.
  --body-marker: string # The pagination token that indicates the next set of results to retrieve. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.ListInstanceFleets"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides all available details about the instance groups in a cluster.
#
# POST /
# Returns: record<InstanceGroups: table<Id: string, Name: string, Market: string, InstanceGroupType: string, BidPrice: string, InstanceType: string, RequestedInstanceCount: int, RunningInstanceCount: int, Status: record, Configurations: list, ConfigurationsVersion: int, LastSuccessfullyAppliedConfigurations: list, LastSuccessfullyAppliedConfigurationsVersion: int, EbsBlockDevices: list, EbsOptimized: bool, ShrinkPolicy: record, AutoScalingPolicy: record, CustomAmiId: string>, Marker: string>
# operationId: ListInstanceGroups
export def "list-instance-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-26 # required
  cluster_id: string # The identifier of the cluster for which to list the instance groups.
  --body-marker: string # The pagination token that indicates the next set of results to retrieve. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.ListInstanceGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides information for all active EC2 instances and EC2 instances terminated in the last 30 days, up to a maximum of 2,000. EC2 instances in any of the following states are considered active: AWAITING_FULFILLMENT, PROVISIONING, BOOTSTRAPPING, RUNNING.
#
# POST /
# Returns: record<Instances: table<Id: string, Ec2InstanceId: string, PublicDnsName: string, PublicIpAddress: string, PrivateDnsName: string, PrivateIpAddress: string, Status: record, InstanceGroupId: string, InstanceFleetId: string, Market: string, InstanceType: string, EbsVolumes: list>, Marker: string>
# operationId: ListInstances
export def "list-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-27 # required
  cluster_id: string # The identifier of the cluster for which to list the instances.
  --instance-group-id: string # The identifier of the instance group for which to list the instances.
  --instance-group-types: list<string> # The type of instance group for which to list the instances.
  --instance-fleet-id: string # The unique identifier of the instance fleet.
  --instance-fleet-type: string@instance-fleet-type-completer # The node type of the instance fleet. For example MASTER, CORE, or TASK.
  --instance-states: list<string> # A list of instance states that will filter the instances returned with this request.
  --body-marker: string # The pagination token that indicates the next set of results to retrieve. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.ListInstances"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: InstanceGroupId, var: instance_group_id}, {name: InstanceGroupTypes, var: instance_group_types}, {name: InstanceFleetId, var: instance_fleet_id}, {name: InstanceFleetType, var: instance_fleet_type}, {name: InstanceStates, var: instance_states}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, instance_group_id: $instance_group_id, instance_group_types: $instance_group_types, instance_fleet_id: $instance_fleet_id, instance_fleet_type: $instance_fleet_type, instance_states: $instance_states, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides summaries of all notebook executions. You can filter the list based on multiple criteria such as status, time range, and editor id. Returns a maximum of 50 notebook executions and a marker to track the paging of a longer notebook execution list across multiple ListNotebookExecution calls.
#
# POST /
# Returns: record<NotebookExecutions: table<NotebookExecutionId: string, EditorId: string, NotebookExecutionName: string, Status: string, StartTime: string, EndTime: string>, Marker: string>
# operationId: ListNotebookExecutions
export def "list-notebook-executions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-28 # required
  --editor-id: string # The unique ID of the editor associated with the notebook execution.
  --status: string@status-completer # The status filter for listing notebook executions. START_PENDING indicates that the cluster has received the execution request but execution has not begun. STARTING indicates that the execution is starting on the cluster. RUNNING indicates that the execution is being processed by the cluster. FINISHING indicates that execution processing is in the final stages. FINISHED indicates that the execution has completed without error. FAILING indicates that the execution is failing and will not finish successfully. FAILED indicates that the execution failed. STOP_PENDING indicates that the cluster has received a StopNotebookExecution request and the stop is pending. STOPPING indicates that the cluster is in the process of stopping the execution as a result of a StopNotebookExecution request. STOPPED indicates that the execution stopped because of a StopNotebookExecution request.
  --from: string # The beginning of time range filter for listing notebook executions. The default is the timestamp of 30 days ago. (format: date-time)
  --to: string # The end of time range filter for listing notebook executions. The default is the current timestamp. (format: date-time)
  --body-marker: string # The pagination token, returned by a previous ListNotebookExecutions call, that indicates the start of the list for this ListNotebookExecutions call. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.ListNotebookExecutions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EditorId, var: editor_id}, {name: Status, var: status}, {name: From, var: from}, {name: To, var: to}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, editor_id: $editor_id, status: $status, from: $from, to: $to, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves release labels of EMR services in the region where the API is called.
#
# POST /
# Returns: record<ReleaseLabels: list<string>, NextToken: string>
# operationId: ListReleaseLabels
export def "list-release-labels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-29 # required
  --filters: record # The release label filters by application or version prefix. — shape: {Prefix?: string, Application?: string}
  --body-next-token: string # Specifies the next page of results. If NextToken is not specified, which is usually the case for the first request of ListReleaseLabels, the first page of results are determined by other filtering parameters or by the latest version. The ListReleaseLabels request fails if the identity (Amazon Web Services account ID) and all filtering parameters are different from the original request, or if the NextToken is expired or tampered with. (spec name: NextToken)
  --body-max-results: int # Defines the maximum number of release labels to return in a single response. The default is 100. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.ListReleaseLabels"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the security configurations visible to this account, providing their creation dates and times, and their names. This call returns a maximum of 50 clusters per call, but returns a marker to track the paging of the cluster list across multiple ListSecurityConfigurations calls.
#
# POST /
# Returns: record<SecurityConfigurations: table<Name: string, CreationDateTime: string>, Marker: string>
# operationId: ListSecurityConfigurations
export def "list-security-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-30 # required
  --body-marker: string # The pagination token that indicates the set of results to retrieve. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.ListSecurityConfigurations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a list of steps for the cluster in reverse order unless you specify stepIds with the request or filter by StepStates. You can specify a maximum of 10 stepIDs. The CLI automatically paginates results to return a list greater than 50 steps. To return more than 50 steps using the CLI, specify a Marker, which is a pagination token that indicates the next set of steps to retrieve.
#
# POST /
# Returns: record<Steps: table<Id: string, Name: string, Config: record, ActionOnFailure: string, Status: record>, Marker: string>
# operationId: ListSteps
export def "list-steps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-31 # required
  cluster_id: string # The identifier of the cluster for which to list the steps.
  --step-states: list<string> # The filter to limit the step list based on certain states.
  --step-ids: list<string> # The filter to limit the step list based on the identifier of the steps. You can specify a maximum of ten Step IDs. The character constraint applies to the overall length of the array.
  --body-marker: string # The maximum number of steps that a single ListSteps action returns is 50. To return a longer list of steps, use multiple ListSteps actions along with the Marker parameter, which is a pagination token that indicates the next set of results to retrieve. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.ListSteps"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: StepStates, var: step_states}, {name: StepIds, var: step_ids}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, step_states: $step_states, step_ids: $step_ids, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all user or group session mappings for the Amazon EMR Studio specified by StudioId.
#
# POST /
# Returns: record<SessionMappings: table<StudioId: string, IdentityId: string, IdentityName: string, IdentityType: string, SessionPolicyArn: string, CreationTime: string>, Marker: string>
# operationId: ListStudioSessionMappings
export def "list-studio-session-mappings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-32 # required
  --studio-id: string # The ID of the Amazon EMR Studio.
  --identity-type: string@identity-type-completer # Specifies whether to return session mappings for users or groups. If not specified, the results include session mapping details for both users and groups.
  --body-marker: string # The pagination token that indicates the set of results to retrieve. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.ListStudioSessionMappings"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StudioId, var: studio_id}, {name: IdentityType, var: identity_type}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, studio_id: $studio_id, identity_type: $identity_type, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all Amazon EMR Studios associated with the Amazon Web Services account. The list includes details such as ID, Studio Access URL, and creation time for each Studio.
#
# POST /
# Returns: record<Studios: table<StudioId: string, Name: string, VpcId: string, Description: string, Url: string, AuthMode: string, CreationTime: string>, Marker: string>
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-33 # required
  --body-marker: string # The pagination token that indicates the set of results to retrieve. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.ListStudios"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the number of steps that can be executed concurrently for the cluster specified using ClusterID.
#
# POST /
# Returns: record<StepConcurrencyLevel: int>
# operationId: ModifyCluster
export def "modify-cluster" [
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
  --x-amz-target: string@x-amz-target-completer-34 # required
  cluster_id: string # The unique identifier of the cluster.
  --step-concurrency-level: int # The number of steps that can be executed concurrently. You can specify a minimum of 1 step and a maximum of 256 steps. We recommend that you do not change this parameter while steps are running or the ActionOnFailure setting may not behave as expected. For more information see Step$ActionOnFailure.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.ModifyCluster"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: StepConcurrencyLevel, var: step_concurrency_level}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, step_concurrency_level: $step_concurrency_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the target On-Demand and target Spot capacities for the instance fleet with the specified InstanceFleetID within the cluster specified using ClusterID. The call either succeeds or fails atomically. The instance fleet configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x versions.
#
# POST /
# operationId: ModifyInstanceFleet
export def "modify-instance-fleet" [
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
  --x-amz-target: string@x-amz-target-completer-35 # required
  cluster_id: string # The unique identifier of the cluster.
  instance_fleet: record # Configuration parameters for an instance fleet modification request. The instance fleet configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x versions. — shape: {InstanceFleetId: string, TargetOnDemandCapacity?: int, TargetSpotCapacity?: int, ResizeSpecifications?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.ModifyInstanceFleet"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: InstanceFleet, var: instance_fleet}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, instance_fleet: $instance_fleet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ModifyInstanceGroups modifies the number of nodes and configuration settings of an instance group. The input parameters include the new target instance count for the group and the instance group ID. The call will either succeed or fail atomically.
#
# POST /
# operationId: ModifyInstanceGroups
export def "modify-instance-groups" [
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  --cluster-id: string # The ID of the cluster to which the instance group belongs.
  --instance-groups: list # Instance groups to change. — item shape: {InstanceGroupId: string, InstanceCount?: int, EC2InstanceIdsToTerminate?: list<string>, ShrinkPolicy?: record, ReconfigurationType?: "OVERWRITE"|"MERGE", Configurations?: list}
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.ModifyInstanceGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: InstanceGroups, var: instance_groups}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, instance_groups: $instance_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates an automatic scaling policy for a core instance group or task instance group in an Amazon EMR cluster. The automatic scaling policy defines how an instance group dynamically adds and terminates EC2 instances in response to the value of a CloudWatch metric.
#
# POST /
# Returns: record<ClusterId: string, InstanceGroupId: string, AutoScalingPolicy: record<Status: record<State: string, StateChangeReason: record>, Constraints: record<MinCapacity: int, MaxCapacity: int>, Rules: list<record>>, ClusterArn: string>
# operationId: PutAutoScalingPolicy
export def "put-auto-scaling-policy" [
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
  --x-amz-target: string@x-amz-target-completer-37 # required
  cluster_id: string # Specifies the ID of a cluster. The instance group to which the automatic scaling policy is applied is within this cluster.
  instance_group_id: string # Specifies the ID of the instance group to which the automatic scaling policy is applied.
  auto_scaling_policy: record # An automatic scaling policy for a core instance group or task instance group in an Amazon EMR cluster. An automatic scaling policy defines how an instance group dynamically adds and terminates EC2 instances in response to the value of a CloudWatch metric. See PutAutoScalingPolicy. — shape: {Constraints: record, Rules: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.PutAutoScalingPolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: InstanceGroupId, var: instance_group_id}, {name: AutoScalingPolicy, var: auto_scaling_policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, instance_group_id: $instance_group_id, auto_scaling_policy: $auto_scaling_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Auto-termination is supported in Amazon EMR versions 5.30.0 and 6.1.0 and later. For more information, see Using an auto-termination policy (https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-auto-termination-policy.html). Creates or updates an auto-termination policy for an Amazon EMR cluster. An auto-termination policy defines the amount of idle time in seconds after which a cluster automatically terminates. For alternative cluster termination options, see Control cluster termination (https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-termination.html).
#
# POST /
# Returns: record
# operationId: PutAutoTerminationPolicy
export def "put-auto-termination-policy" [
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
  --x-amz-target: string@x-amz-target-completer-38 # required
  cluster_id: string # Specifies the ID of the Amazon EMR cluster to which the auto-termination policy will be attached.
  --auto-termination-policy: record # An auto-termination policy for an Amazon EMR cluster. An auto-termination policy defines the amount of idle time in seconds after which a cluster automatically terminates. For alternative cluster termination options, see Control cluster termination (https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-termination.html). — shape: {IdleTimeout?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.PutAutoTerminationPolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: AutoTerminationPolicy, var: auto_termination_policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, auto_termination_policy: $auto_termination_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates an Amazon EMR block public access configuration for your Amazon Web Services account in the current Region. For more information see Configure Block Public Access for Amazon EMR (https://docs.aws.amazon.com/emr/latest/ManagementGuide/configure-block-public-access.html) in the Amazon EMR Management Guide.
#
# POST /
# Returns: record
# operationId: PutBlockPublicAccessConfiguration
export def "put-block-public-access-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-39 # required
  block_public_access_configuration: record # A configuration for Amazon EMR block public access. When BlockPublicSecurityGroupRules is set to true, Amazon EMR prevents cluster creation if one of the cluster's security groups has a rule that allows inbound traffic from 0.0.0.0/0 or ::/0 on a port, unless the port is specified as an exception using PermittedPublicSecurityGroupRuleRanges. — shape: {BlockPublicSecurityGroupRules: bool, PermittedPublicSecurityGroupRuleRanges?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.PutBlockPublicAccessConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BlockPublicAccessConfiguration, var: block_public_access_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, block_public_access_configuration: $block_public_access_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a managed scaling policy for an Amazon EMR cluster. The managed scaling policy defines the limits for resources, such as EC2 instances that can be added or terminated from a cluster. The policy only applies to the core and task nodes. The master node cannot be scaled after initial configuration.
#
# POST /
# Returns: record
# operationId: PutManagedScalingPolicy
export def "put-managed-scaling-policy" [
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
  --x-amz-target: string@x-amz-target-completer-40 # required
  cluster_id: string # Specifies the ID of an EMR cluster where the managed scaling policy is attached.
  managed_scaling_policy: record # Managed scaling policy for an Amazon EMR cluster. The policy specifies the limits for resources that can be added or terminated from a cluster. The policy only applies to the core and task nodes. The master node cannot be scaled after initial configuration. — shape: {ComputeLimits?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.PutManagedScalingPolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: ManagedScalingPolicy, var: managed_scaling_policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, managed_scaling_policy: $managed_scaling_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an automatic scaling policy from a specified instance group within an EMR cluster.
#
# POST /
# Returns: record
# operationId: RemoveAutoScalingPolicy
export def "remove-auto-scaling-policy" [
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
  --x-amz-target: string@x-amz-target-completer-41 # required
  cluster_id: string # Specifies the ID of a cluster. The instance group to which the automatic scaling policy is applied is within this cluster.
  instance_group_id: string # Specifies the ID of the instance group to which the scaling policy is applied.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.RemoveAutoScalingPolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: InstanceGroupId, var: instance_group_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, instance_group_id: $instance_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an auto-termination policy from an Amazon EMR cluster.
#
# POST /
# Returns: record
# operationId: RemoveAutoTerminationPolicy
export def "remove-auto-termination-policy" [
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
  --x-amz-target: string@x-amz-target-completer-42 # required
  cluster_id: string # Specifies the ID of the Amazon EMR cluster from which the auto-termination policy will be removed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.RemoveAutoTerminationPolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a managed scaling policy from a specified EMR cluster.
#
# POST /
# Returns: record
# operationId: RemoveManagedScalingPolicy
export def "remove-managed-scaling-policy" [
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
  --x-amz-target: string@x-amz-target-completer-43 # required
  cluster_id: string # Specifies the ID of the cluster from which the managed scaling policy will be removed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.RemoveManagedScalingPolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes tags from an Amazon EMR resource, such as a cluster or Amazon EMR Studio. Tags make it easier to associate resources in various ways, such as grouping clusters to track your Amazon EMR resource allocation costs. For more information, see Tag Clusters (https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-tags.html). The following example removes the stack tag with value Prod from a cluster:
#
# POST /
# Returns: record
# operationId: RemoveTags
export def "remove-tags" [
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
  --x-amz-target: string@x-amz-target-completer-44 # required
  resource_id: string # The Amazon EMR resource identifier from which tags will be removed. For example, a cluster identifier or an Amazon EMR Studio ID.
  tag_keys: list<string> # A list of tag keys to remove from the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.RemoveTags"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RunJobFlow creates and starts running a new cluster (job flow). The cluster runs the steps specified. After the steps complete, the cluster stops and the HDFS partition is lost. To prevent loss of data, configure the last step of the job flow to store results in Amazon S3. If the JobFlowInstancesConfig KeepJobFlowAliveWhenNoSteps parameter is set to TRUE, the cluster transitions to the WAITING state rather than shutting down after the steps have completed. For additional protection, you can set the JobFlowInstancesConfig TerminationProtected parameter to TRUE to lock the cluster and prevent it from being terminated by API call, user intervention, or in the event of a job flow error. A maximum of 256 steps are allowed in each job flow. If your cluster is long-running (such as a Hive data warehouse) or complex, you may require more than 256 steps to process your data. You can bypass the 256-step limitation in various ways, including using the SSH shell to connect to the master node and submitting queries directly to the software running on the master node, such as Hive and Hadoop. For long-running clusters, we recommend that you periodically store your results. The instance fleets configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x versions. The RunJobFlow request can contain InstanceFleets parameters or InstanceGroups parameters, but not both.
#
# POST /
# Returns: record<JobFlowId: string, ClusterArn: string>
# operationId: RunJobFlow
export def "run-job-flow" [
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
  --x-amz-target: string@x-amz-target-completer-45 # required
  name: string # The name of the job flow.
  --log-uri: string # The location in Amazon S3 to write the log files of the job flow. If a value is not provided, logs are not created.
  --log-encryption-kms-key-id: string # The KMS key used for encrypting log files. If a value is not provided, the logs remain encrypted by AES-256. This attribute is only available with Amazon EMR version 5.30.0 and later, excluding Amazon EMR 6.0.0.
  --additional-info: string # A JSON string for selecting additional features.
  --ami-version: string # Applies only to Amazon EMR AMI versions 3.x and 2.x. For Amazon EMR releases 4.0 and later, ReleaseLabel is used. To specify a custom AMI, use CustomAmiID.
  --release-label: string # The Amazon EMR release label, which determines the version of open-source application packages installed on the cluster. Release labels are in the form emr-x.x.x, where x.x.x is an Amazon EMR release version such as emr-5.14.0. For more information about Amazon EMR release versions and included application versions and features, see https://docs.aws.amazon.com/emr/latest/ReleaseGuide/ (https://docs.aws.amazon.com/emr/latest/ReleaseGuide/). The release label applies only to Amazon EMR releases version 4.0 and later. Earlier versions use AmiVersion.
  instances: record # A description of the Amazon EC2 instance on which the cluster (job flow) runs. A valid JobFlowInstancesConfig must contain either InstanceGroups or InstanceFleets. They cannot be used together. You may also have MasterInstanceType, SlaveInstanceType, and InstanceCount (all three must be present), but we don't recommend this configuration. — shape: {MasterInstanceType?: string, SlaveInstanceType?: string, InstanceCount?: int, InstanceGroups?: list, InstanceFleets?: list, Ec2KeyName?: string, Placement?: record, KeepJobFlowAliveWhenNoSteps?: bool, TerminationProtected?: bool, HadoopVersion?: string, Ec2SubnetId?: string, Ec2SubnetIds?: list<string>, EmrManagedMasterSecurityGroup?: string, EmrManagedSlaveSecurityGroup?: string, ServiceAccessSecurityGroup?: string, AdditionalMasterSecurityGroups?: list<string>, ... (1 more fields)}
  --steps: list # A list of steps to run. — item shape: {Name: string, ActionOnFailure?: "TERMINATE_JOB_FLOW"|"TERMINATE_CLUSTER"|"CANCEL_AND_WAIT"|"CONTINUE", HadoopJarStep: record}
  --bootstrap-actions: list # A list of bootstrap actions to run before Hadoop starts on the cluster nodes. — item shape: {Name: string, ScriptBootstrapAction: record}
  --supported-products: list<string> # For Amazon EMR releases 3.x and 2.x. For Amazon EMR releases 4.x and later, use Applications. A list of strings that indicates third-party software to use. For more information, see the Amazon EMR Developer Guide (https://docs.aws.amazon.com/emr/latest/DeveloperGuide/emr-dg.pdf). Currently supported values are: "mapr-m3" - launch the job flow using MapR M3 Edition. "mapr-m5" - launch the job flow using MapR M5 Edition.
  --new-supported-products: list # For Amazon EMR releases 3.x and 2.x. For Amazon EMR releases 4.x and later, use Applications. A list of strings that indicates third-party software to use with the job flow that accepts a user argument list. EMR accepts and forwards the argument list to the corresponding installation script as bootstrap action arguments. For more information, see "Launch a Job Flow on the MapR Distribution for Hadoop" in the Amazon EMR Developer Guide (https://docs.aws.amazon.com/emr/latest/DeveloperGuide/emr-dg.pdf). Supported values are: "mapr-m3" - launch the cluster using MapR M3 Edition. "mapr-m5" - launch the cluster using MapR M5 Edition. "mapr" with the user arguments specifying "--edition,m3" or "--edition,m5" - launch the job flow using MapR M3 or M5 Edition respectively. "mapr-m7" - launch the cluster using MapR M7 Edition. "hunk" - launch the cluster with the Hunk Big Data Analytics Platform. "hue"- launch the cluster with Hue installed. "spark" - launch the cluster with Apache Spark installed. "ganglia" - launch the cluster with the Ganglia Monitoring System installed. — item shape: {Name?: string, Args?: list<string>}
  --applications: list # Applies to Amazon EMR releases 4.0 and later. A case-insensitive list of applications for Amazon EMR to install and configure when launching the cluster. For a list of applications available for each Amazon EMR release version, see the Amazon EMRRelease Guide (https://docs.aws.amazon.com/emr/latest/ReleaseGuide/). — item shape: {Name?: string, Version?: string, Args?: list<string>, AdditionalInfo?: record}
  --configurations: list # For Amazon EMR releases 4.0 and later. The list of configurations supplied for the EMR cluster you are creating. — item shape: {Classification?: string, Configurations?: list, Properties?: record}
  --visible-to-all-users: oneof<nothing, bool> # The VisibleToAllUsers parameter is no longer supported. By default, the value is set to true. Setting it to false now has no effect. Set this value to true so that IAM principals in the Amazon Web Services account associated with the cluster can perform EMR actions on the cluster that their IAM policies allow. This value defaults to true for clusters created using the EMR API or the CLI create-cluster (https://docs.aws.amazon.com/cli/latest/reference/emr/create-cluster.html) command. When set to false, only the IAM principal that created the cluster and the Amazon Web Services account root user can perform EMR actions for the cluster, regardless of the IAM permissions policies attached to other IAM principals. For more information, see Understanding the EMR Cluster VisibleToAllUsers Setting (https://docs.aws.amazon.com/emr/latest/ManagementGuide/security_iam_emr-with-iam.html#security_set_visible_to_all_users) in the Amazon EMRManagement Guide.
  --job-flow-role: string # Also called instance profile and EC2 role. An IAM role for an EMR cluster. The EC2 instances of the cluster assume this role. The default role is EMR_EC2_DefaultRole. In order to use the default role, you must have already created it using the CLI or console.
  --service-role: string # The IAM role that Amazon EMR assumes in order to access Amazon Web Services resources on your behalf. If you've created a custom service role path, you must specify it for the service role when you launch your cluster.
  --tags: list # A list of tags to associate with a cluster and propagate to Amazon EC2 instances. — item shape: {Key?: string, Value?: string}
  --security-configuration: string # The name of a security configuration to apply to the cluster.
  --auto-scaling-role: string # An IAM role for automatic scaling policies. The default role is EMR_AutoScaling_DefaultRole. The IAM role provides permissions that the automatic scaling feature requires to launch and terminate EC2 instances in an instance group.
  --scale-down-behavior: string@scale-down-behavior-completer # Specifies the way that individual Amazon EC2 instances terminate when an automatic scale-in activity occurs or an instance group is resized. TERMINATE_AT_INSTANCE_HOUR indicates that Amazon EMR terminates nodes at the instance-hour boundary, regardless of when the request to terminate the instance was submitted. This option is only available with Amazon EMR 5.1.0 and later and is the default for clusters created using that version. TERMINATE_AT_TASK_COMPLETION indicates that Amazon EMR adds nodes to a deny list and drains tasks from nodes before terminating the Amazon EC2 instances, regardless of the instance-hour boundary. With either behavior, Amazon EMR removes the least active nodes first and blocks instance termination if it could lead to HDFS corruption. TERMINATE_AT_TASK_COMPLETION available only in Amazon EMR version 4.1.0 and later, and is the default for versions of Amazon EMR earlier than 5.1.0.
  --custom-ami-id: string # Available only in Amazon EMR version 5.7.0 and later. The ID of a custom Amazon EBS-backed Linux AMI. If specified, Amazon EMR uses this AMI when it launches cluster EC2 instances. For more information about custom AMIs in Amazon EMR, see Using a Custom AMI (https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-custom-ami.html) in the Amazon EMR Management Guide. If omitted, the cluster uses the base Linux AMI for the ReleaseLabel specified. For Amazon EMR versions 2.x and 3.x, use AmiVersion instead. For information about creating a custom AMI, see Creating an Amazon EBS-Backed Linux AMI (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/creating-an-ami-ebs.html) in the Amazon Elastic Compute Cloud User Guide for Linux Instances. For information about finding an AMI ID, see Finding a Linux AMI (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html).
  --ebs-root-volume-size: int # The size, in GiB, of the Amazon EBS root device volume of the Linux AMI that is used for each EC2 instance. Available in Amazon EMR version 4.x and later.
  --repo-upgrade-on-boot: string@repo-upgrade-on-boot-completer # Applies only when CustomAmiID is used. Specifies which updates from the Amazon Linux AMI package repositories to apply automatically when the instance boots using the AMI. If omitted, the default is SECURITY, which indicates that only security updates are applied. If NONE is specified, no updates are applied, and all updates must be applied manually.
  --kerberos-attributes: record # Attributes for Kerberos configuration when Kerberos authentication is enabled using a security configuration. For more information see Use Kerberos Authentication (https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-kerberos.html) in the Amazon EMR Management Guide. — shape: {Realm: string, KdcAdminPassword: string, CrossRealmTrustPrincipalPassword?: string, ADDomainJoinUser?: string, ADDomainJoinPassword?: string}
  --step-concurrency-level: int # Specifies the number of steps that can be executed concurrently. The default value is 1. The maximum value is 256.
  --managed-scaling-policy: record # Managed scaling policy for an Amazon EMR cluster. The policy specifies the limits for resources that can be added or terminated from a cluster. The policy only applies to the core and task nodes. The master node cannot be scaled after initial configuration. — shape: {ComputeLimits?: record}
  --placement-group-configs: list # The specified placement group configuration for an Amazon EMR cluster. — item shape: {InstanceRole: "MASTER"|"CORE"|"TASK", PlacementStrategy?: "SPREAD"|"PARTITION"|"CLUSTER"|"NONE"}
  --auto-termination-policy: record # An auto-termination policy for an Amazon EMR cluster. An auto-termination policy defines the amount of idle time in seconds after which a cluster automatically terminates. For alternative cluster termination options, see Control cluster termination (https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-termination.html). — shape: {IdleTimeout?: int}
  --os-release-label: string # Specifies a particular Amazon Linux release for all nodes in a cluster launch RunJobFlow request. If a release is not specified, Amazon EMR uses the latest validated Amazon Linux release for cluster launch.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.RunJobFlow"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: LogUri, var: log_uri}, {name: LogEncryptionKmsKeyId, var: log_encryption_kms_key_id}, {name: AdditionalInfo, var: additional_info}, {name: AmiVersion, var: ami_version}, {name: ReleaseLabel, var: release_label}, {name: Instances, var: instances}, {name: Steps, var: steps}, {name: BootstrapActions, var: bootstrap_actions}, {name: SupportedProducts, var: supported_products}, {name: NewSupportedProducts, var: new_supported_products}, {name: Applications, var: applications}, {name: Configurations, var: configurations}, {name: VisibleToAllUsers, var: visible_to_all_users}, {name: JobFlowRole, var: job_flow_role}, {name: ServiceRole, var: service_role}, {name: Tags, var: tags}, {name: SecurityConfiguration, var: security_configuration}, {name: AutoScalingRole, var: auto_scaling_role}, {name: ScaleDownBehavior, var: scale_down_behavior}, {name: CustomAmiId, var: custom_ami_id}, {name: EbsRootVolumeSize, var: ebs_root_volume_size}, {name: RepoUpgradeOnBoot, var: repo_upgrade_on_boot}, {name: KerberosAttributes, var: kerberos_attributes}, {name: StepConcurrencyLevel, var: step_concurrency_level}, {name: ManagedScalingPolicy, var: managed_scaling_policy}, {name: PlacementGroupConfigs, var: placement_group_configs}, {name: AutoTerminationPolicy, var: auto_termination_policy}, {name: OSReleaseLabel, var: os_release_label}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, log_uri: $log_uri, log_encryption_kms_key_id: $log_encryption_kms_key_id, additional_info: $additional_info, ami_version: $ami_version, release_label: $release_label, instances: $instances, steps: $steps, bootstrap_actions: $bootstrap_actions, supported_products: $supported_products, new_supported_products: $new_supported_products, applications: $applications, configurations: $configurations, visible_to_all_users: $visible_to_all_users, job_flow_role: $job_flow_role, service_role: $service_role, tags: $tags, security_configuration: $security_configuration, auto_scaling_role: $auto_scaling_role, scale_down_behavior: $scale_down_behavior, custom_ami_id: $custom_ami_id, ebs_root_volume_size: $ebs_root_volume_size, repo_upgrade_on_boot: $repo_upgrade_on_boot, kerberos_attributes: $kerberos_attributes, step_concurrency_level: $step_concurrency_level, managed_scaling_policy: $managed_scaling_policy, placement_group_configs: $placement_group_configs, auto_termination_policy: $auto_termination_policy, os_release_label: $os_release_label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SetTerminationProtection locks a cluster (job flow) so the EC2 instances in the cluster cannot be terminated by user intervention, an API call, or in the event of a job-flow error. The cluster still terminates upon successful completion of the job flow. Calling SetTerminationProtection on a cluster is similar to calling the Amazon EC2 DisableAPITermination API on all EC2 instances in a cluster. SetTerminationProtection is used to prevent accidental termination of a cluster and to ensure that in the event of an error, the instances persist so that you can recover any data stored in their ephemeral instance storage. To terminate a cluster that has been locked by setting SetTerminationProtection to true, you must first unlock the job flow by a subsequent call to SetTerminationProtection in which you set the value to false. For more information, seeManaging Cluster Termination (https://docs.aws.amazon.com/emr/latest/ManagementGuide/UsingEMR_TerminationProtection.html) in the Amazon EMR Management Guide.
#
# POST /
# operationId: SetTerminationProtection
export def "set-termination-protection" [
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
  --x-amz-target: string@x-amz-target-completer-46 # required
  job_flow_ids: list<string> # A list of strings that uniquely identify the clusters to protect. This identifier is returned by RunJobFlow and can also be obtained from DescribeJobFlows .
  --termination-protected: oneof<nothing, bool> # A Boolean that indicates whether to protect the cluster and prevent the Amazon EC2 instances in the cluster from shutting down due to API calls, user intervention, or job-flow error.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.SetTerminationProtection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobFlowIds, var: job_flow_ids}, {name: TerminationProtected, var: termination_protected, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_flow_ids: $job_flow_ids, termination_protected: $termination_protected
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The SetVisibleToAllUsers parameter is no longer supported. Your cluster may be visible to all users in your account. To restrict cluster access using an IAM policy, see Identity and Access Management for EMR (https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-access-iam.html). Sets the Cluster$VisibleToAllUsers value for an EMR cluster. When true, IAM principals in the Amazon Web Services account can perform EMR cluster actions that their IAM policies allow. When false, only the IAM principal that created the cluster and the Amazon Web Services account root user can perform EMR actions on the cluster, regardless of IAM permissions policies attached to other IAM principals. This action works on running clusters. When you create a cluster, use the RunJobFlowInput$VisibleToAllUsers parameter. For more information, see Understanding the EMR Cluster VisibleToAllUsers Setting (https://docs.aws.amazon.com/emr/latest/ManagementGuide/security_iam_emr-with-iam.html#security_set_visible_to_all_users) in the Amazon EMRManagement Guide.
#
# POST /
# operationId: SetVisibleToAllUsers
export def "set-visible-to-all-users" [
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
  --x-amz-target: string@x-amz-target-completer-47 # required
  job_flow_ids: list<string> # The unique identifier of the job flow (cluster).
  --visible-to-all-users: oneof<nothing, bool> # A value of true indicates that an IAM principal in the Amazon Web Services account can perform EMR actions on the cluster that the IAM policies attached to the principal allow. A value of false indicates that only the IAM principal that created the cluster and the Amazon Web Services root user can perform EMR actions on the cluster.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.SetVisibleToAllUsers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobFlowIds, var: job_flow_ids}, {name: VisibleToAllUsers, var: visible_to_all_users, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_flow_ids: $job_flow_ids, visible_to_all_users: $visible_to_all_users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a notebook execution.
#
# POST /
# Returns: record<NotebookExecutionId: string>
# operationId: StartNotebookExecution
export def "start-notebook-execution" [
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
  --x-amz-target: string@x-amz-target-completer-48 # required
  editor_id: string # The unique identifier of the EMR Notebook to use for notebook execution.
  relative_path: string # The path and file name of the notebook file for this execution, relative to the path specified for the EMR Notebook. For example, if you specify a path of s3://MyBucket/MyNotebooks when you create an EMR Notebook for a notebook with an ID of e-ABCDEFGHIJK1234567890ABCD (the EditorID of this request), and you specify a RelativePath of my_notebook_executions/notebook_execution.ipynb, the location of the file for the notebook execution is s3://MyBucket/MyNotebooks/e-ABCDEFGHIJK1234567890ABCD/my_notebook_executions/notebook_execution.ipynb.
  --notebook-execution-name: string # An optional name for the notebook execution.
  --notebook-params: string # Input parameters in JSON format passed to the EMR Notebook at runtime for execution.
  execution_engine: record # Specifies the execution engine (cluster) to run the notebook and perform the notebook execution, for example, an EMR cluster. — shape: {Id: string, Type?: "EMR", MasterInstanceSecurityGroupId?: string}
  service_role: string # The name or ARN of the IAM role that is used as the service role for Amazon EMR (the EMR role) for the notebook execution.
  --notebook-instance-security-group-id: string # The unique identifier of the Amazon EC2 security group to associate with the EMR Notebook for this notebook execution.
  --tags: list # A list of tags associated with a notebook execution. Tags are user-defined key-value pairs that consist of a required key string with a maximum of 128 characters and an optional value string with a maximum of 256 characters. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.StartNotebookExecution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EditorId, var: editor_id}, {name: RelativePath, var: relative_path}, {name: NotebookExecutionName, var: notebook_execution_name}, {name: NotebookParams, var: notebook_params}, {name: ExecutionEngine, var: execution_engine}, {name: ServiceRole, var: service_role}, {name: NotebookInstanceSecurityGroupId, var: notebook_instance_security_group_id}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, editor_id: $editor_id, relative_path: $relative_path, notebook_execution_name: $notebook_execution_name, notebook_params: $notebook_params, execution_engine: $execution_engine, service_role: $service_role, notebook_instance_security_group_id: $notebook_instance_security_group_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a notebook execution.
#
# POST /
# operationId: StopNotebookExecution
export def "stop-notebook-execution" [
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
  --x-amz-target: string@x-amz-target-completer-49 # required
  notebook_execution_id: string # The unique identifier of the notebook execution.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.StopNotebookExecution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NotebookExecutionId, var: notebook_execution_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, notebook_execution_id: $notebook_execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# TerminateJobFlows shuts a list of clusters (job flows) down. When a job flow is shut down, any step not yet completed is canceled and the EC2 instances on which the cluster is running are stopped. Any log files not already saved are uploaded to Amazon S3 if a LogUri was specified when the cluster was created. The maximum number of clusters allowed is 10. The call to TerminateJobFlows is asynchronous. Depending on the configuration of the cluster, it may take up to 1-5 minutes for the cluster to completely terminate and release allocated resources, such as Amazon EC2 instances.
#
# POST /
# operationId: TerminateJobFlows
export def "terminate-job-flows" [
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
  --x-amz-target: string@x-amz-target-completer-50 # required
  job_flow_ids: list<string> # A list of job flows to be shut down.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.TerminateJobFlows"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobFlowIds, var: job_flow_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_flow_ids: $job_flow_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Amazon EMR Studio configuration, including attributes such as name, description, and subnets.
#
# POST /
# operationId: UpdateStudio
export def "update-studio" [
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
  --x-amz-target: string@x-amz-target-completer-51 # required
  studio_id: string # The ID of the Amazon EMR Studio to update.
  --name: string # A descriptive name for the Amazon EMR Studio.
  --description: string # A detailed description to assign to the Amazon EMR Studio.
  --subnet-ids: list<string> # A list of subnet IDs to associate with the Amazon EMR Studio. The list can include new subnet IDs, but must also include all of the subnet IDs previously associated with the Studio. The list order does not matter. A Studio can have a maximum of 5 subnets. The subnets must belong to the same VPC as the Studio.
  --default-s3-location: string # The Amazon S3 location to back up Workspaces and notebook files for the Amazon EMR Studio.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.UpdateStudio"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StudioId, var: studio_id}, {name: Name, var: name}, {name: Description, var: description}, {name: SubnetIds, var: subnet_ids}, {name: DefaultS3Location, var: default_s3_location}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, studio_id: $studio_id, name: $name, description: $description, subnet_ids: $subnet_ids, default_s3_location: $default_s3_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the session policy attached to the user or group for the specified Amazon EMR Studio.
#
# POST /
# operationId: UpdateStudioSessionMapping
export def "update-studio-session-mapping" [
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
  --x-amz-target: string@x-amz-target-completer-52 # required
  studio_id: string # The ID of the Amazon EMR Studio.
  --identity-id: string # The globally unique identifier (GUID) of the user or group. For more information, see UserId (https://docs.aws.amazon.com/singlesignon/latest/IdentityStoreAPIReference/API_User.html#singlesignon-Type-User-UserId) and GroupId (https://docs.aws.amazon.com/singlesignon/latest/IdentityStoreAPIReference/API_Group.html#singlesignon-Type-Group-GroupId) in the IAM Identity Center Identity Store API Reference. Either IdentityName or IdentityId must be specified.
  --identity-name: string # The name of the user or group to update. For more information, see UserName (https://docs.aws.amazon.com/singlesignon/latest/IdentityStoreAPIReference/API_User.html#singlesignon-Type-User-UserName) and DisplayName (https://docs.aws.amazon.com/singlesignon/latest/IdentityStoreAPIReference/API_Group.html#singlesignon-Type-Group-DisplayName) in the IAM Identity Center Identity Store API Reference. Either IdentityName or IdentityId must be specified.
  identity_type: string@identity-type-completer # Specifies whether the identity to update is a user or a group.
  session_policy_arn: string # The Amazon Resource Name (ARN) of the session policy to associate with the specified user or group.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ElasticMapReduce.UpdateStudioSessionMapping"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StudioId, var: studio_id}, {name: IdentityId, var: identity_id}, {name: IdentityName, var: identity_name}, {name: IdentityType, var: identity_type}, {name: SessionPolicyArn, var: session_policy_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, studio_id: $studio_id, identity_id: $identity_id, identity_name: $identity_name, identity_type: $identity_type, session_policy_arn: $session_policy_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
