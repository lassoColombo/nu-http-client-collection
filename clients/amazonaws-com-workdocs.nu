# Auto-generated client for Amazon WorkDocs v2016-05-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/workdocs/2016-05-01/openapi.json
# Auth: --token flag or $env.AMAZON_WORKDOCS_TOKEN

const CLIENT = {
  base_url: "http://workdocs.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_WORKDOCS_TOKEN"
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

def base-url-completer [] { ["http://workdocs.us-east-1.amazonaws.com" "http://workdocs.us-east-2.amazonaws.com" "http://workdocs.us-west-1.amazonaws.com" "http://workdocs.us-west-2.amazonaws.com" "http://workdocs.us-gov-west-1.amazonaws.com" "http://workdocs.us-gov-east-1.amazonaws.com" "http://workdocs.ca-central-1.amazonaws.com" "http://workdocs.eu-north-1.amazonaws.com" "http://workdocs.eu-west-1.amazonaws.com" "http://workdocs.eu-west-2.amazonaws.com" "http://workdocs.eu-west-3.amazonaws.com" "http://workdocs.eu-central-1.amazonaws.com" "http://workdocs.eu-south-1.amazonaws.com" "http://workdocs.af-south-1.amazonaws.com" "http://workdocs.ap-northeast-1.amazonaws.com" "http://workdocs.ap-northeast-2.amazonaws.com" "http://workdocs.ap-northeast-3.amazonaws.com" "http://workdocs.ap-southeast-1.amazonaws.com" "http://workdocs.ap-southeast-2.amazonaws.com" "http://workdocs.ap-east-1.amazonaws.com" "http://workdocs.ap-south-1.amazonaws.com" "http://workdocs.sa-east-1.amazonaws.com" "http://workdocs.me-south-1.amazonaws.com" "https://workdocs.us-east-1.amazonaws.com" "https://workdocs.us-east-2.amazonaws.com" "https://workdocs.us-west-1.amazonaws.com" "https://workdocs.us-west-2.amazonaws.com" "https://workdocs.us-gov-west-1.amazonaws.com" "https://workdocs.us-gov-east-1.amazonaws.com" "https://workdocs.ca-central-1.amazonaws.com" "https://workdocs.eu-north-1.amazonaws.com" "https://workdocs.eu-west-1.amazonaws.com" "https://workdocs.eu-west-2.amazonaws.com" "https://workdocs.eu-west-3.amazonaws.com" "https://workdocs.eu-central-1.amazonaws.com" "https://workdocs.eu-south-1.amazonaws.com" "https://workdocs.af-south-1.amazonaws.com" "https://workdocs.ap-northeast-1.amazonaws.com" "https://workdocs.ap-northeast-2.amazonaws.com" "https://workdocs.ap-northeast-3.amazonaws.com" "https://workdocs.ap-southeast-1.amazonaws.com" "https://workdocs.ap-southeast-2.amazonaws.com" "https://workdocs.ap-east-1.amazonaws.com" "https://workdocs.ap-south-1.amazonaws.com" "https://workdocs.sa-east-1.amazonaws.com" "https://workdocs.me-south-1.amazonaws.com" "http://workdocs.cn-north-1.amazonaws.com.cn" "http://workdocs.cn-northwest-1.amazonaws.com.cn" "https://workdocs.cn-north-1.amazonaws.com.cn" "https://workdocs.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def version-status-completer [] { ["ACTIVE"] }
def visibility-completer [] { ["PRIVATE" "PUBLIC"] }
def protocol-completer [] { ["HTTPS" "SQS"] }
def subscription-type-completer [] { ["ALL"] }
def include-completer [] { ["ACTIVE_PENDING" "ALL"] }
def order-completer [] { ["ASCENDING" "DESCENDING"] }
def sort-completer [] { ["FULL_NAME" "STORAGE_LIMIT" "STORAGE_USED" "USER_NAME" "USER_STATUS"] }
def resource-state-completer [] { ["ACTIVE" "RECYCLED" "RECYCLING" "RESTORING"] }
def sort-completer-1 [] { ["DATE" "NAME"] }
def type-completer [] { ["ALL" "DOCUMENT" "FOLDER"] }
def type-completer-1 [] { ["ADMIN" "MINIMALUSER" "POWERUSER" "USER" "WORKSPACESUSER"] }
def locale-completer [] { ["de" "default" "en" "es" "fr" "ja" "ko" "pt_BR" "ru" "zh_CN" "zh_TW"] }
def grant-poweruser-privileges-completer [] { ["FALSE" "TRUE"] }
def collection-type-completer [] { ["SHARED_WITH_ME"] }
def type-completer-2 [] { ["ANONYMOUS" "GROUP" "INVITE" "ORGANIZATION" "USER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-document-version: "record<Metadata: record<Id: string, Name: string, ContentType: string, Size: int, Signature: string, Status: string, CreatedTimestamp: string, ModifiedTimestamp: string, ContentCreatedTimestamp: string, ContentModifiedTimestamp: string, CreatorId: string, Thumbnail: record, Source: record>, CustomMetadata: record>"
    activate-user: "record<User: record<Id: string, Username: string, EmailAddress: string, GivenName: string, Surname: string, OrganizationId: string, RootFolderId: string, RecycleBinFolderId: string, Status: string, Type: string, CreatedTimestamp: string, ModifiedTimestamp: string, TimeZoneId: string, Locale: string, Storage: record<StorageUtilizedInBytes: int, StorageRule: record>>>"
    add-resource-permissions: "record<ShareResults: table<PrincipalId: string, InviteePrincipalId: string, Role: string, Status: string, ShareId: string, StatusMessage: string>>"
    describe-resource-permissions: "record<Principals: table<Id: string, Type: string, Roles: list>, Marker: string>"
    create-comment: "record<Comment: record<CommentId: string, ParentId: string, ThreadId: string, Text: string, Contributor: record<Id: string, Username: string, EmailAddress: string, GivenName: string, Surname: string, OrganizationId: string, RootFolderId: string, RecycleBinFolderId: string, Status: string, Type: string, CreatedTimestamp: string, ModifiedTimestamp: string, TimeZoneId: string, Locale: string, Storage: record>, CreatedTimestamp: string, Status: string, Visibility: string, RecipientId: string>>"
    create-custom-metadata: "record"
    delete-custom-metadata: "record"
    create-folder: "record<Metadata: record<Id: string, Name: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, ResourceState: string, Signature: string, Labels: list<string>, Size: int, LatestVersionSize: int>>"
    create-labels: "record"
    delete-labels: "record"
    create-notification-subscription: "record<Subscription: record<SubscriptionId: string, EndPoint: string, Protocol: string>>"
    describe-notification-subscriptions: "record<Subscriptions: table<SubscriptionId: string, EndPoint: string, Protocol: string>, Marker: string>"
    create-user: "record<User: record<Id: string, Username: string, EmailAddress: string, GivenName: string, Surname: string, OrganizationId: string, RootFolderId: string, RecycleBinFolderId: string, Status: string, Type: string, CreatedTimestamp: string, ModifiedTimestamp: string, TimeZoneId: string, Locale: string, Storage: record<StorageUtilizedInBytes: int, StorageRule: record>>>"
    describe-users: "record<Users: table<Id: string, Username: string, EmailAddress: string, GivenName: string, Surname: string, OrganizationId: string, RootFolderId: string, RecycleBinFolderId: string, Status: string, Type: string, CreatedTimestamp: string, ModifiedTimestamp: string, TimeZoneId: string, Locale: string, Storage: record>, TotalNumberOfUsers: int, Marker: string>"
    get-document: "record<Metadata: record<Id: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, LatestVersionMetadata: record<Id: string, Name: string, ContentType: string, Size: int, Signature: string, Status: string, CreatedTimestamp: string, ModifiedTimestamp: string, ContentCreatedTimestamp: string, ContentModifiedTimestamp: string, CreatorId: string, Thumbnail: record, Source: record>, ResourceState: string, Labels: list<string>>, CustomMetadata: record>"
    get-folder: "record<Metadata: record<Id: string, Name: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, ResourceState: string, Signature: string, Labels: list<string>, Size: int, LatestVersionSize: int>, CustomMetadata: record>"
    describe-folder-contents: "record<Folders: table<Id: string, Name: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, ResourceState: string, Signature: string, Labels: list, Size: int, LatestVersionSize: int>, Documents: table<Id: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, LatestVersionMetadata: record, ResourceState: string, Labels: list>, Marker: string>"
    update-user: "record<User: record<Id: string, Username: string, EmailAddress: string, GivenName: string, Surname: string, OrganizationId: string, RootFolderId: string, RecycleBinFolderId: string, Status: string, Type: string, CreatedTimestamp: string, ModifiedTimestamp: string, TimeZoneId: string, Locale: string, Storage: record<StorageUtilizedInBytes: int, StorageRule: record>>>"
    describe-activities: "record<UserActivities: table<Type: string, TimeStamp: string, IsIndirectActivity: bool, OrganizationId: string, Initiator: record, Participants: record, ResourceMetadata: record, OriginalParent: record, CommentMetadata: record>, Marker: string>"
    describe-comments: "record<Comments: table<CommentId: string, ParentId: string, ThreadId: string, Text: string, Contributor: record, CreatedTimestamp: string, Status: string, Visibility: string, RecipientId: string>, Marker: string>"
    describe-document-versions: "record<DocumentVersions: table<Id: string, Name: string, ContentType: string, Size: int, Signature: string, Status: string, CreatedTimestamp: string, ModifiedTimestamp: string, ContentCreatedTimestamp: string, ContentModifiedTimestamp: string, CreatorId: string, Thumbnail: record, Source: record>, Marker: string>"
    describe-groups: "record<Groups: table<Id: string, Name: string>, Marker: string>"
    describe-root-folders: "record<Folders: table<Id: string, Name: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, ResourceState: string, Signature: string, Labels: list, Size: int, LatestVersionSize: int>, Marker: string>"
    get-current-user: "record<User: record<Id: string, Username: string, EmailAddress: string, GivenName: string, Surname: string, OrganizationId: string, RootFolderId: string, RecycleBinFolderId: string, Status: string, Type: string, CreatedTimestamp: string, ModifiedTimestamp: string, TimeZoneId: string, Locale: string, Storage: record<StorageUtilizedInBytes: int, StorageRule: record>>>"
    get-document-path: "record<Path: record<Components: list<record>>>"
    get-folder-path: "record<Path: record<Components: list<record>>>"
    get-resources: "record<Folders: table<Id: string, Name: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, ResourceState: string, Signature: string, Labels: list, Size: int, LatestVersionSize: int>, Documents: table<Id: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, LatestVersionMetadata: record, ResourceState: string, Labels: list>, Marker: string>"
    initiate-document-version-upload: "record<Metadata: record<Id: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, LatestVersionMetadata: record<Id: string, Name: string, ContentType: string, Size: int, Signature: string, Status: string, CreatedTimestamp: string, ModifiedTimestamp: string, ContentCreatedTimestamp: string, ContentModifiedTimestamp: string, CreatorId: string, Thumbnail: record, Source: record>, ResourceState: string, Labels: list<string>>, UploadMetadata: record<UploadUrl: string, SignedHeaders: record>>"
    search-resources: "record<Items: table<ResourceType: string, WebUrl: string, DocumentMetadata: record, FolderMetadata: record, CommentMetadata: record, DocumentVersionMetadata: record>, Marker: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["abort-document-version-upload" "get-document-version" "update-document-version" "activate-user" "deactivate-user" "add-resource-permissions" "describe-resource-permissions" "remove-all-resource-permissions" "create-comment" "create-custom-metadata" "delete-custom-metadata" "create-folder" "create-labels" "delete-labels" "create-notification-subscription" "describe-notification-subscriptions" "create-user" "describe-users" "delete-comment" "delete-document" "get-document" "update-document" "delete-document-version" "delete-folder" "get-folder" "update-folder" "delete-folder-contents" "describe-folder-contents" "delete-notification-subscription" "delete-user" "update-user" "describe-activities" "describe-comments" "describe-document-versions" "describe-groups" "describe-root-folders" "get-current-user" "get-document-path" "get-folder-path" "get-resources" "initiate-document-version-upload" "remove-resource-permission" "restore-document-versions" "search-resources" "commands"] | sort) } | get name | first)
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

# Aborts the upload of the specified document version that was previously initiated by InitiateDocumentVersionUpload. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
#
# DELETE /api/v1/documents/{DocumentId}/versions/{VersionId}
# operationId: AbortDocumentVersionUpload
export def "abort-document-version-upload" [
  document_id: string
  version_id: string
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/documents/{DocumentId}/versions/{VersionId}"
    path_params: [{name: DocumentId, var: document_id}, {name: VersionId, var: version_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    document_id: $document_id, version_id: $version_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves version metadata for the specified document.
#
# GET /api/v1/documents/{DocumentId}/versions/{VersionId}
# Returns: record<Metadata: record<Id: string, Name: string, ContentType: string, Size: int, Signature: string, Status: string, CreatedTimestamp: string, ModifiedTimestamp: string, ContentCreatedTimestamp: string, ContentModifiedTimestamp: string, CreatorId: string, Thumbnail: record, Source: record>, CustomMetadata: record>
# operationId: GetDocumentVersion
export def "get-document-version" [
  document_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # A comma-separated list of values. Specify "SOURCE" to include a URL for the source document.
  --include-custom-metadata: oneof<nothing, bool> # Set this to TRUE to include custom metadata in the response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/documents/{DocumentId}/versions/{VersionId}"
    path_params: [{name: DocumentId, var: document_id}, {name: VersionId, var: version_id}]
    query: [{name: fields, var: fields}, {name: includeCustomMetadata, var: include_custom_metadata}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id, version_id: $version_id, fields: $fields, include_custom_metadata: $include_custom_metadata, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the status of the document version to ACTIVE. Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by InitiateDocumentVersionUpload.
#
# PATCH /api/v1/documents/{DocumentId}/versions/{VersionId}
# operationId: UpdateDocumentVersion
export def "update-document-version" [
  document_id: string
  version_id: string
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
  --version-status: string@version-status-completer # The status of the version.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/v1/documents/{DocumentId}/versions/{VersionId}"
    path_params: [{name: DocumentId, var: document_id}, {name: VersionId, var: version_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    body: {content_type: "application/json", kind: json, fields: [{name: VersionStatus, var: version_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id, version_id: $version_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication, version_status: $version_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activates the specified user. Only active users can access Amazon WorkDocs.
#
# POST /api/v1/users/{UserId}/activation
# Returns: record<User: record<Id: string, Username: string, EmailAddress: string, GivenName: string, Surname: string, OrganizationId: string, RootFolderId: string, RecycleBinFolderId: string, Status: string, Type: string, CreatedTimestamp: string, ModifiedTimestamp: string, TimeZoneId: string, Locale: string, Storage: record<StorageUtilizedInBytes: int, StorageRule: record>>>
# operationId: ActivateUser
export def "activate-user" [
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/v1/users/{UserId}/activation"
    path_params: [{name: UserId, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
#
# DELETE /api/v1/users/{UserId}/activation
# operationId: DeactivateUser
export def "deactivate-user" [
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/users/{UserId}/activation"
    path_params: [{name: UserId, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
#
# POST /api/v1/resources/{ResourceId}/permissions
# Returns: record<ShareResults: table<PrincipalId: string, InviteePrincipalId: string, Role: string, Status: string, ShareId: string, StatusMessage: string>>
# operationId: AddResourcePermissions
export def "add-resource-permissions" [
  resource_id: string
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
  principals: list # The users, groups, or organization being granted permission. — item shape: {Id: string, Type: "USER"|"GROUP"|"INVITE"|"ANONYMOUS"|"ORGANIZATION", Role: "VIEWER"|"CONTRIBUTOR"|"OWNER"|"COOWNER"}
  --notification-options: record # Set of options which defines notification preferences of given action. — shape: {SendEmail?: bool, EmailMessage?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/resources/{ResourceId}/permissions"
    path_params: [{name: ResourceId, var: resource_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    body: {content_type: "application/json", kind: json, fields: [{name: Principals, var: principals}, {name: NotificationOptions, var: notification_options}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    resource_id: $resource_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication, principals: $principals, notification_options: $notification_options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the permissions of a specified resource.
#
# GET /api/v1/resources/{ResourceId}/permissions
# Returns: record<Principals: table<Id: string, Type: string, Roles: list>, Marker: string>
# operationId: DescribeResourcePermissions
export def "describe-resource-permissions" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --principal-id: string # The ID of the principal to filter permissions by.
  --limit: int # The maximum number of items to return with this call.
  --marker: string # The marker for the next set of results. (You received this marker from a previous call)
  --qp-limit: string # Pagination limit (spec name: Limit)
  --qp-marker: string # Pagination token (spec name: Marker)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/resources/{ResourceId}/permissions"
    path_params: [{name: ResourceId, var: resource_id}]
    query: [{name: principalId, var: principal_id}, {name: limit, var: limit}, {name: marker, var: marker}, {name: Limit, var: qp_limit}, {name: Marker, var: qp_marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_id: $resource_id, principal_id: $principal_id, limit: $limit, marker: $marker, qp_limit: $qp_limit, qp_marker: $qp_marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes all the permissions from the specified resource.
#
# DELETE /api/v1/resources/{ResourceId}/permissions
# operationId: RemoveAllResourcePermissions
export def "remove-all-resource-permissions" [
  resource_id: string
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/resources/{ResourceId}/permissions"
    path_params: [{name: ResourceId, var: resource_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_id: $resource_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new comment to the specified document version.
#
# POST /api/v1/documents/{DocumentId}/versions/{VersionId}/comment
# Returns: record<Comment: record<CommentId: string, ParentId: string, ThreadId: string, Text: string, Contributor: record<Id: string, Username: string, EmailAddress: string, GivenName: string, Surname: string, OrganizationId: string, RootFolderId: string, RecycleBinFolderId: string, Status: string, Type: string, CreatedTimestamp: string, ModifiedTimestamp: string, TimeZoneId: string, Locale: string, Storage: record>, CreatedTimestamp: string, Status: string, Visibility: string, RecipientId: string>>
# operationId: CreateComment
export def "create-comment" [
  document_id: string
  version_id: string
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
  --parent-id: string # The ID of the parent comment.
  --thread-id: string # The ID of the root comment in the thread.
  text: string # The text of the comment. (format: password)
  --visibility: string@visibility-completer # The visibility of the comment. Options are either PRIVATE, where the comment is visible only to the comment author and document owner and co-owners, or PUBLIC, where the comment is visible to document owners, co-owners, and contributors.
  --notify-collaborators: oneof<nothing, bool> # Set this parameter to TRUE to send an email out to the document collaborators after the comment is created.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment"
    path_params: [{name: DocumentId, var: document_id}, {name: VersionId, var: version_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    body: {content_type: "application/json", kind: json, fields: [{name: ParentId, var: parent_id}, {name: ThreadId, var: thread_id}, {name: Text, var: text}, {name: Visibility, var: visibility}, {name: NotifyCollaborators, var: notify_collaborators}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    document_id: $document_id, version_id: $version_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication, parent_id: $parent_id, thread_id: $thread_id, text: $text, visibility: $visibility, notify_collaborators: $notify_collaborators
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds one or more custom properties to the specified resource (a folder, document, or version).
#
# PUT /api/v1/resources/{ResourceId}/customMetadata
# Returns: record
# operationId: CreateCustomMetadata
export def "create-custom-metadata" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --versionid: string # The ID of the version, if the custom metadata is being added to a document version.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
  custom_metadata: record # Custom metadata in the form of name-value pairs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/resources/{ResourceId}/customMetadata"
    path_params: [{name: ResourceId, var: resource_id}]
    query: [{name: versionid, var: versionid}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    body: {content_type: "application/json", kind: json, fields: [{name: CustomMetadata, var: custom_metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_id: $resource_id, versionid: $versionid, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication, custom_metadata: $custom_metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes custom metadata from the specified resource.
#
# DELETE /api/v1/resources/{ResourceId}/customMetadata
# Returns: record
# operationId: DeleteCustomMetadata
export def "delete-custom-metadata" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-id: string # The ID of the version, if the custom metadata is being deleted from a document version.
  --keys: list<string> # List of properties to remove.
  --delete-all: oneof<nothing, bool> # Flag to indicate removal of all custom metadata properties from the specified resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/v1/resources/{ResourceId}/customMetadata"
    path_params: [{name: ResourceId, var: resource_id}]
    query: [{name: versionId, var: version_id}, {name: keys, var: keys, style: multi}, {name: deleteAll, var: delete_all}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_id: $resource_id, version_id: $version_id, keys: $keys, delete_all: $delete_all, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a folder with the specified name and parent folder.
#
# POST /api/v1/folders
# Returns: record<Metadata: record<Id: string, Name: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, ResourceState: string, Signature: string, Labels: list<string>, Size: int, LatestVersionSize: int>>
# operationId: CreateFolder
export def "create-folder" [
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
  --name: string # The name of the new folder. (format: password)
  parent_folder_id: string # The ID of the parent folder.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/folders"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: ParentFolderId, var: parent_folder_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication, name: $name, parent_folder_id: $parent_folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds the specified list of labels to the given resource (a document or folder)
#
# PUT /api/v1/resources/{ResourceId}/labels
# Returns: record
# operationId: CreateLabels
export def "create-labels" [
  resource_id: string
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
  labels: list<string> # List of labels to add to the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/resources/{ResourceId}/labels"
    path_params: [{name: ResourceId, var: resource_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    body: {content_type: "application/json", kind: json, fields: [{name: Labels, var: labels}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_id: $resource_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified list of labels from a resource.
#
# DELETE /api/v1/resources/{ResourceId}/labels
# Returns: record
# operationId: DeleteLabels
export def "delete-labels" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --labels: list<string> # List of labels to delete from the resource.
  --delete-all: oneof<nothing, bool> # Flag to request removal of all labels from the specified resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/v1/resources/{ResourceId}/labels"
    path_params: [{name: ResourceId, var: resource_id}]
    query: [{name: labels, var: labels, style: multi}, {name: deleteAll, var: delete_all}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_id: $resource_id, labels: $labels, delete_all: $delete_all, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription. For more information, see Setting up notifications for an IAM user or role (https://docs.aws.amazon.com/workdocs/latest/developerguide/manage-notifications.html) in the Amazon WorkDocs Developer Guide.
#
# POST /api/v1/organizations/{OrganizationId}/subscriptions
# Returns: record<Subscription: record<SubscriptionId: string, EndPoint: string, Protocol: string>>
# operationId: CreateNotificationSubscription
export def "create-notification-subscription" [
  organization_id: string
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
  endpoint: string # The endpoint to receive the notifications. If the protocol is HTTPS, the endpoint is a URL that begins with https.
  protocol: string@protocol-completer # The protocol to use. The supported value is https, which delivers JSON-encoded messages using HTTPS POST.
  subscription_type: string@subscription-type-completer # The notification type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/organizations/{OrganizationId}/subscriptions"
    path_params: [{name: OrganizationId, var: organization_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Endpoint, var: endpoint}, {name: Protocol, var: protocol}, {name: SubscriptionType, var: subscription_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_id: $organization_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, endpoint: $endpoint, protocol: $protocol, subscription_type: $subscription_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the specified notification subscriptions.
#
# GET /api/v1/organizations/{OrganizationId}/subscriptions
# Returns: record<Subscriptions: table<SubscriptionId: string, EndPoint: string, Protocol: string>, Marker: string>
# operationId: DescribeNotificationSubscriptions
export def "describe-notification-subscriptions" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # The marker for the next set of results. (You received this marker from a previous call.)
  --limit: int # The maximum number of items to return with this call.
  --qp-limit: string # Pagination limit (spec name: Limit)
  --qp-marker: string # Pagination token (spec name: Marker)
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
    path: "/api/v1/organizations/{OrganizationId}/subscriptions"
    path_params: [{name: OrganizationId, var: organization_id}]
    query: [{name: marker, var: marker}, {name: limit, var: limit}, {name: Limit, var: qp_limit}, {name: Marker, var: qp_marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_id: $organization_id, marker: $marker, limit: $limit, qp_limit: $qp_limit, qp_marker: $qp_marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
#
# POST /api/v1/users
# Returns: record<User: record<Id: string, Username: string, EmailAddress: string, GivenName: string, Surname: string, OrganizationId: string, RootFolderId: string, RecycleBinFolderId: string, Status: string, Type: string, CreatedTimestamp: string, ModifiedTimestamp: string, TimeZoneId: string, Locale: string, Storage: record<StorageUtilizedInBytes: int, StorageRule: record>>>
# operationId: CreateUser
export def "create-user" [
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
  --organization-id: string # The ID of the organization.
  username: string # The login name of the user. (format: password)
  --email-address: string # The email address of the user. (format: password)
  given_name: string # The given name of the user. (format: password)
  surname: string # The surname of the user. (format: password)
  password: string # The password of the user. (format: password)
  --time-zone-id: string # The time zone ID of the user.
  --storage-rule: record # Describes the storage for a user. — shape: {StorageAllocatedInBytes?: int, StorageType?: "UNLIMITED"|"QUOTA"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/users"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    body: {content_type: "application/json", kind: json, fields: [{name: OrganizationId, var: organization_id}, {name: Username, var: username}, {name: EmailAddress, var: email_address}, {name: GivenName, var: given_name}, {name: Surname, var: surname}, {name: Password, var: password}, {name: TimeZoneId, var: time_zone_id}, {name: StorageRule, var: storage_rule}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication, organization_id: $organization_id, username: $username, email_address: $email_address, given_name: $given_name, surname: $surname, password: $password, time_zone_id: $time_zone_id, storage_rule: $storage_rule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the specified users. You can describe all users or filter the results (for example, by status or organization). By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.
#
# GET /api/v1/users
# Returns: record<Users: table<Id: string, Username: string, EmailAddress: string, GivenName: string, Surname: string, OrganizationId: string, RootFolderId: string, RecycleBinFolderId: string, Status: string, Type: string, CreatedTimestamp: string, ModifiedTimestamp: string, TimeZoneId: string, Locale: string, Storage: record>, TotalNumberOfUsers: int, Marker: string>
# operationId: DescribeUsers
export def "describe-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # The ID of the organization.
  --user-ids: string # The IDs of the users.
  --query: string # A query to filter users by user name. Remember the following about the Userids and Query parameters: If you don't use either parameter, the API returns a paginated list of all users on the site. If you use both parameters, the API ignores the Query parameter. The Userid parameter only returns user names that match a corresponding user ID. The Query parameter runs a "prefix" search for users by the GivenName, SurName, or UserName fields included in a CreateUser (https://docs.aws.amazon.com/workdocs/latest/APIReference/API_CreateUser.html) API call. For example, querying on Ma returns Márcia Oliveira, María García, and Mateo Jackson. If you use multiple characters, the API only returns data that matches all characters. For example, querying on Ma J only returns Mateo Jackson. (format: password)
  --include: string@include-completer # The state of the users. Specify "ALL" to include inactive users.
  --order: string@order-completer # The order for the results.
  --sort: string@sort-completer # The sorting criteria.
  --marker: string # The marker for the next set of results. (You received this marker from a previous call.)
  --limit: int # The maximum number of items to return.
  --fields: string # A comma-separated list of values. Specify "STORAGE_METADATA" to include the user storage quota and utilization information.
  --qp-limit: string # Pagination limit (spec name: Limit)
  --qp-marker: string # Pagination token (spec name: Marker)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/users"
    query: [{name: organizationId, var: organization_id}, {name: userIds, var: user_ids}, {name: query, var: query}, {name: include, var: include}, {name: order, var: order}, {name: sort, var: sort}, {name: marker, var: marker}, {name: limit, var: limit}, {name: fields, var: fields}, {name: Limit, var: qp_limit}, {name: Marker, var: qp_marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_id: $organization_id, user_ids: $user_ids, query: $query, include: $include, order: $order, sort: $sort, marker: $marker, limit: $limit, fields: $fields, qp_limit: $qp_limit, qp_marker: $qp_marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified comment from the document version.
#
# DELETE /api/v1/documents/{DocumentId}/versions/{VersionId}/comment/{CommentId}
# operationId: DeleteComment
export def "delete-comment" [
  document_id: string
  version_id: string
  comment_id: string
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment/{CommentId}"
    path_params: [{name: DocumentId, var: document_id}, {name: VersionId, var: version_id}, {name: CommentId, var: comment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    document_id: $document_id, version_id: $version_id, comment_id: $comment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently deletes the specified document and its associated metadata.
#
# DELETE /api/v1/documents/{DocumentId}
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/documents/{DocumentId}"
    path_params: [{name: DocumentId, var: document_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    document_id: $document_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves details of a document.
#
# GET /api/v1/documents/{DocumentId}
# Returns: record<Metadata: record<Id: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, LatestVersionMetadata: record<Id: string, Name: string, ContentType: string, Size: int, Signature: string, Status: string, CreatedTimestamp: string, ModifiedTimestamp: string, ContentCreatedTimestamp: string, ContentModifiedTimestamp: string, CreatorId: string, Thumbnail: record, Source: record>, ResourceState: string, Labels: list<string>>, CustomMetadata: record>
# operationId: GetDocument
export def "get-document" [
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
  --include-custom-metadata: oneof<nothing, bool> # Set this to TRUE to include custom metadata in the response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/documents/{DocumentId}"
    path_params: [{name: DocumentId, var: document_id}]
    query: [{name: includeCustomMetadata, var: include_custom_metadata}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id, include_custom_metadata: $include_custom_metadata, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
#
# PATCH /api/v1/documents/{DocumentId}
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
  --name: string # The name of the document. (format: password)
  --parent-folder-id: string # The ID of the parent folder.
  --resource-state: string@resource-state-completer # The resource state of the document. Only ACTIVE and RECYCLED are supported.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/v1/documents/{DocumentId}"
    path_params: [{name: DocumentId, var: document_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: ParentFolderId, var: parent_folder_id}, {name: ResourceState, var: resource_state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication, name: $name, parent_folder_id: $parent_folder_id, resource_state: $resource_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specific version of a document.
#
# DELETE /api/v1/documentVersions/{DocumentId}/versions/{VersionId}
# operationId: DeleteDocumentVersion
export def "delete-document-version" [
  document_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-prior-versions: oneof<nothing, bool> # Deletes all versions of a document prior to the current version. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/documentVersions/{DocumentId}/versions/{VersionId}"
    path_params: [{name: DocumentId, var: document_id}, {name: VersionId, var: version_id}]
    query: [{name: deletePriorVersions, var: delete_prior_versions, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    document_id: $document_id, version_id: $version_id, delete_prior_versions: $delete_prior_versions, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently deletes the specified folder and its contents.
#
# DELETE /api/v1/folders/{FolderId}
# operationId: DeleteFolder
export def "delete-folder" [
  folder_id: string
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/folders/{FolderId}"
    path_params: [{name: FolderId, var: folder_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    folder_id: $folder_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the metadata of the specified folder.
#
# GET /api/v1/folders/{FolderId}
# Returns: record<Metadata: record<Id: string, Name: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, ResourceState: string, Signature: string, Labels: list<string>, Size: int, LatestVersionSize: int>, CustomMetadata: record>
# operationId: GetFolder
export def "get-folder" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-custom-metadata: oneof<nothing, bool> # Set to TRUE to include custom metadata in the response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/folders/{FolderId}"
    path_params: [{name: FolderId, var: folder_id}]
    query: [{name: includeCustomMetadata, var: include_custom_metadata}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, include_custom_metadata: $include_custom_metadata, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
#
# PATCH /api/v1/folders/{FolderId}
# operationId: UpdateFolder
export def "update-folder" [
  folder_id: string
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
  --name: string # The name of the folder. (format: password)
  --parent-folder-id: string # The ID of the parent folder.
  --resource-state: string@resource-state-completer # The resource state of the folder. Only ACTIVE and RECYCLED are accepted values from the API.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/v1/folders/{FolderId}"
    path_params: [{name: FolderId, var: folder_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: ParentFolderId, var: parent_folder_id}, {name: ResourceState, var: resource_state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication, name: $name, parent_folder_id: $parent_folder_id, resource_state: $resource_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the contents of the specified folder.
#
# DELETE /api/v1/folders/{FolderId}/contents
# operationId: DeleteFolderContents
export def "delete-folder-contents" [
  folder_id: string
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/folders/{FolderId}/contents"
    path_params: [{name: FolderId, var: folder_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    folder_id: $folder_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the contents of the specified folder, including its documents and subfolders. By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.
#
# GET /api/v1/folders/{FolderId}/contents
# Returns: record<Folders: table<Id: string, Name: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, ResourceState: string, Signature: string, Labels: list, Size: int, LatestVersionSize: int>, Documents: table<Id: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, LatestVersionMetadata: record, ResourceState: string, Labels: list>, Marker: string>
# operationId: DescribeFolderContents
export def "describe-folder-contents" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer-1 # The sorting criteria.
  --order: string@order-completer # The order for the contents of the folder.
  --limit: int # The maximum number of items to return with this call.
  --marker: string # The marker for the next set of results. This marker was received from a previous call.
  --type: string@type-completer # The type of items.
  --include: string # The contents to include. Specify "INITIALIZED" to include initialized documents.
  --qp-limit: string # Pagination limit (spec name: Limit)
  --qp-marker: string # Pagination token (spec name: Marker)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/folders/{FolderId}/contents"
    path_params: [{name: FolderId, var: folder_id}]
    query: [{name: sort, var: sort}, {name: order, var: order}, {name: limit, var: limit}, {name: marker, var: marker}, {name: type, var: type}, {name: include, var: include}, {name: Limit, var: qp_limit}, {name: Marker, var: qp_marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, sort: $sort, order: $order, limit: $limit, marker: $marker, type: $type, include: $include, qp_limit: $qp_limit, qp_marker: $qp_marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified subscription from the specified organization.
#
# DELETE /api/v1/organizations/{OrganizationId}/subscriptions/{SubscriptionId}
# operationId: DeleteNotificationSubscription
export def "delete-notification-subscription" [
  organization_id: string
  subscription_id: string
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
    path: "/api/v1/organizations/{OrganizationId}/subscriptions/{SubscriptionId}"
    path_params: [{name: OrganizationId, var: organization_id}, {name: SubscriptionId, var: subscription_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_id: $organization_id, subscription_id: $subscription_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified user from a Simple AD or Microsoft AD directory. Deleting a user immediately and permanently deletes all content in that user's folder structure. Site retention policies do NOT apply to this type of deletion.
#
# DELETE /api/v1/users/{UserId}
# operationId: DeleteUser
export def "delete-user" [
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
  --authentication: string # Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using Amazon Web Services credentials. (format: password)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/users/{UserId}"
    path_params: [{name: UserId, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
#
# PATCH /api/v1/users/{UserId}
# Returns: record<User: record<Id: string, Username: string, EmailAddress: string, GivenName: string, Surname: string, OrganizationId: string, RootFolderId: string, RecycleBinFolderId: string, Status: string, Type: string, CreatedTimestamp: string, ModifiedTimestamp: string, TimeZoneId: string, Locale: string, Storage: record<StorageUtilizedInBytes: int, StorageRule: record>>>
# operationId: UpdateUser
export def "update-user" [
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
  --given-name: string # The given name of the user. (format: password)
  --surname: string # The surname of the user. (format: password)
  --type: string@type-completer-1 # The type of the user.
  --storage-rule: record # Describes the storage for a user. — shape: {StorageAllocatedInBytes?: int, StorageType?: "UNLIMITED"|"QUOTA"}
  --time-zone-id: string # The time zone ID of the user.
  --locale: string@locale-completer # The locale of the user.
  --grant-poweruser-privileges: string@grant-poweruser-privileges-completer # Boolean value to determine whether the user is granted Power user privileges.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/v1/users/{UserId}"
    path_params: [{name: UserId, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    body: {content_type: "application/json", kind: json, fields: [{name: GivenName, var: given_name}, {name: Surname, var: surname}, {name: Type, var: type}, {name: StorageRule, var: storage_rule}, {name: TimeZoneId, var: time_zone_id}, {name: Locale, var: locale}, {name: GrantPoweruserPrivileges, var: grant_poweruser_privileges}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication, given_name: $given_name, surname: $surname, type: $type, storage_rule: $storage_rule, time_zone_id: $time_zone_id, locale: $locale, grant_poweruser_privileges: $grant_poweruser_privileges
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the user activities in a specified time period.
#
# GET /api/v1/activities
# Returns: record<UserActivities: table<Type: string, TimeStamp: string, IsIndirectActivity: bool, OrganizationId: string, Initiator: record, Participants: record, ResourceMetadata: record, OriginalParent: record, CommentMetadata: record>, Marker: string>
# operationId: DescribeActivities
export def "describe-activities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-time: string # The timestamp that determines the starting time of the activities. The response includes the activities performed after the specified timestamp. (format: date-time)
  --end-time: string # The timestamp that determines the end time of the activities. The response includes the activities performed before the specified timestamp. (format: date-time)
  --organization-id: string # The ID of the organization. This is a mandatory parameter when using administrative API (SigV4) requests.
  --activity-types: string # Specifies which activity types to include in the response. If this field is left empty, all activity types are returned.
  --resource-id: string # The document or folder ID for which to describe activity types.
  --user-id: string # The ID of the user who performed the action. The response includes activities pertaining to this user. This is an optional parameter and is only applicable for administrative API (SigV4) requests.
  --include-indirect-activities: oneof<nothing, bool> # Includes indirect activities. An indirect activity results from a direct activity performed on a parent resource. For example, sharing a parent folder (the direct activity) shares all of the subfolders and documents within the parent folder (the indirect activity).
  --limit: int # The maximum number of items to return.
  --marker: string # The marker for the next set of results.
  --qp-limit: string # Pagination limit (spec name: Limit)
  --qp-marker: string # Pagination token (spec name: Marker)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/activities"
    query: [{name: startTime, var: start_time}, {name: endTime, var: end_time}, {name: organizationId, var: organization_id}, {name: activityTypes, var: activity_types}, {name: resourceId, var: resource_id}, {name: userId, var: user_id}, {name: includeIndirectActivities, var: include_indirect_activities}, {name: limit, var: limit}, {name: marker, var: marker}, {name: Limit, var: qp_limit}, {name: Marker, var: qp_marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_time: $start_time, end_time: $end_time, organization_id: $organization_id, activity_types: $activity_types, resource_id: $resource_id, user_id: $user_id, include_indirect_activities: $include_indirect_activities, limit: $limit, marker: $marker, qp_limit: $qp_limit, qp_marker: $qp_marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all the comments for the specified document version.
#
# GET /api/v1/documents/{DocumentId}/versions/{VersionId}/comments
# Returns: record<Comments: table<CommentId: string, ParentId: string, ThreadId: string, Text: string, Contributor: record, CreatedTimestamp: string, Status: string, Visibility: string, RecipientId: string>, Marker: string>
# operationId: DescribeComments
export def "describe-comments" [
  document_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of items to return.
  --marker: string # The marker for the next set of results. This marker was received from a previous call.
  --qp-limit: string # Pagination limit (spec name: Limit)
  --qp-marker: string # Pagination token (spec name: Marker)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comments"
    path_params: [{name: DocumentId, var: document_id}, {name: VersionId, var: version_id}]
    query: [{name: limit, var: limit}, {name: marker, var: marker}, {name: Limit, var: qp_limit}, {name: Marker, var: qp_marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id, version_id: $version_id, limit: $limit, marker: $marker, qp_limit: $qp_limit, qp_marker: $qp_marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the document versions for the specified document. By default, only active versions are returned.
#
# GET /api/v1/documents/{DocumentId}/versions
# Returns: record<DocumentVersions: table<Id: string, Name: string, ContentType: string, Size: int, Signature: string, Status: string, CreatedTimestamp: string, ModifiedTimestamp: string, ContentCreatedTimestamp: string, ContentModifiedTimestamp: string, CreatorId: string, Thumbnail: record, Source: record>, Marker: string>
# operationId: DescribeDocumentVersions
export def "describe-document-versions" [
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
  --marker: string # The marker for the next set of results. (You received this marker from a previous call.)
  --limit: int # The maximum number of versions to return with this call.
  --include: string # A comma-separated list of values. Specify "INITIALIZED" to include incomplete versions.
  --fields: string # Specify "SOURCE" to include initialized versions and a URL for the source document.
  --qp-limit: string # Pagination limit (spec name: Limit)
  --qp-marker: string # Pagination token (spec name: Marker)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/documents/{DocumentId}/versions"
    path_params: [{name: DocumentId, var: document_id}]
    query: [{name: marker, var: marker}, {name: limit, var: limit}, {name: include, var: include}, {name: fields, var: fields}, {name: Limit, var: qp_limit}, {name: Marker, var: qp_marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id, marker: $marker, limit: $limit, include: $include, fields: $fields, qp_limit: $qp_limit, qp_marker: $qp_marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the groups specified by the query. Groups are defined by the underlying Active Directory.
#
# GET /api/v1/groups
# Returns: record<Groups: table<Id: string, Name: string>, Marker: string>
# operationId: DescribeGroups
export def "describe-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-query: string # A query to describe groups by group name. (required, format: password)
  --organization-id: string # The ID of the organization.
  --marker: string # The marker for the next set of results. (You received this marker from a previous call.)
  --limit: int # The maximum number of items to return with this call.
  --qp-limit: string # Pagination limit (spec name: Limit)
  --qp-marker: string # Pagination token (spec name: Marker)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/groups"
    query: [{name: searchQuery, var: search_query, required: true}, {name: organizationId, var: organization_id}, {name: marker, var: marker}, {name: limit, var: limit}, {name: Limit, var: qp_limit}, {name: Marker, var: qp_marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search_query: $search_query, organization_id: $organization_id, marker: $marker, limit: $limit, qp_limit: $qp_limit, qp_marker: $qp_marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the current user's special folders; the RootFolder and the RecycleBin. RootFolder is the root of user's files and folders and RecycleBin is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients. This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see Authentication and Access Control for User Applications (https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html) in the Amazon WorkDocs Developer Guide.
#
# GET /api/v1/me/root
# Returns: record<Folders: table<Id: string, Name: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, ResourceState: string, Signature: string, Labels: list, Size: int, LatestVersionSize: int>, Marker: string>
# operationId: DescribeRootFolders
export def "describe-root-folders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of items to return.
  --marker: string # The marker for the next set of results. (You received this marker from a previous call.)
  --qp-limit: string # Pagination limit (spec name: Limit)
  --qp-marker: string # Pagination token (spec name: Marker)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. (required, format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/me/root"
    query: [{name: limit, var: limit}, {name: marker, var: marker}, {name: Limit, var: qp_limit}, {name: Marker, var: qp_marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, marker: $marker, qp_limit: $qp_limit, qp_marker: $qp_marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients. This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see Authentication and Access Control for User Applications (https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html) in the Amazon WorkDocs Developer Guide.
#
# GET /api/v1/me
# Returns: record<User: record<Id: string, Username: string, EmailAddress: string, GivenName: string, Surname: string, OrganizationId: string, RootFolderId: string, RecycleBinFolderId: string, Status: string, Type: string, CreatedTimestamp: string, ModifiedTimestamp: string, TimeZoneId: string, Locale: string, Storage: record<StorageUtilizedInBytes: int, StorageRule: record>>>
# operationId: GetCurrentUser
export def "get-current-user" [
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
  --authentication: string # Amazon WorkDocs authentication token. (required, format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/me"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the path information (the hierarchy from the root folder) for the requested document. By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested document and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the names of the parent folders.
#
# GET /api/v1/documents/{DocumentId}/path
# Returns: record<Path: record<Components: list<record>>>
# operationId: GetDocumentPath
export def "get-document-path" [
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
  --limit: int # The maximum number of levels in the hierarchy to return.
  --fields: string # A comma-separated list of values. Specify NAME to include the names of the parent folders.
  --marker: string # This value is not supported.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/documents/{DocumentId}/path"
    path_params: [{name: DocumentId, var: document_id}]
    query: [{name: limit, var: limit}, {name: fields, var: fields}, {name: marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id, limit: $limit, fields: $fields, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the path information (the hierarchy from the root folder) for the specified folder. By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.
#
# GET /api/v1/folders/{FolderId}/path
# Returns: record<Path: record<Components: list<record>>>
# operationId: GetFolderPath
export def "get-folder-path" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of levels in the hierarchy to return.
  --fields: string # A comma-separated list of values. Specify "NAME" to include the names of the parent folders.
  --marker: string # This value is not supported.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/folders/{FolderId}/path"
    path_params: [{name: FolderId, var: folder_id}]
    query: [{name: limit, var: limit}, {name: fields, var: fields}, {name: marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, limit: $limit, fields: $fields, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a collection of resources, including folders and documents. The only CollectionType supported is SHARED_WITH_ME.
#
# GET /api/v1/resources
# Returns: record<Folders: table<Id: string, Name: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, ResourceState: string, Signature: string, Labels: list, Size: int, LatestVersionSize: int>, Documents: table<Id: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, LatestVersionMetadata: record, ResourceState: string, Labels: list>, Marker: string>
# operationId: GetResources
export def "get-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The user ID for the resource collection. This is a required field for accessing the API operation using IAM credentials.
  --collection-type: string@collection-type-completer # The collection type.
  --limit: int # The maximum number of resources to return.
  --marker: string # The marker for the next set of results. This marker was received from a previous call.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # The Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/resources"
    query: [{name: userId, var: user_id}, {name: collectionType, var: collection_type}, {name: limit, var: limit}, {name: marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, collection_type: $collection_type, limit: $limit, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new document object and version object. The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call UpdateDocumentVersion. To cancel the document upload, call AbortDocumentVersionUpload.
#
# POST /api/v1/documents
# Returns: record<Metadata: record<Id: string, CreatorId: string, ParentFolderId: string, CreatedTimestamp: string, ModifiedTimestamp: string, LatestVersionMetadata: record<Id: string, Name: string, ContentType: string, Size: int, Signature: string, Status: string, CreatedTimestamp: string, ModifiedTimestamp: string, ContentCreatedTimestamp: string, ContentModifiedTimestamp: string, CreatorId: string, Thumbnail: record, Source: record>, ResourceState: string, Labels: list<string>>, UploadMetadata: record<UploadUrl: string, SignedHeaders: record>>
# operationId: InitiateDocumentVersionUpload
export def "initiate-document-version-upload" [
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
  --id: string # The ID of the document.
  --name: string # The name of the document. (format: password)
  --content-created-timestamp: string # The timestamp when the content of the document was originally created. (format: date-time)
  --content-modified-timestamp: string # The timestamp when the content of the document was modified. (format: date-time)
  --content-type: string # The content type of the document.
  --document-size-in-bytes: int # The size of the document, in bytes.
  --parent-folder-id: string # The ID of the parent folder.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/documents"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Name, var: name}, {name: ContentCreatedTimestamp, var: content_created_timestamp}, {name: ContentModifiedTimestamp, var: content_modified_timestamp}, {name: ContentType, var: content_type}, {name: DocumentSizeInBytes, var: document_size_in_bytes}, {name: ParentFolderId, var: parent_folder_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication, id: $id, name: $name, content_created_timestamp: $content_created_timestamp, content_modified_timestamp: $content_modified_timestamp, content_type: $content_type, document_size_in_bytes: $document_size_in_bytes, parent_folder_id: $parent_folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the permission for the specified principal from the specified resource.
#
# DELETE /api/v1/resources/{ResourceId}/permissions/{PrincipalId}
# operationId: RemoveResourcePermission
export def "remove-resource-permission" [
  resource_id: string
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
  --type: string@type-completer-2 # The principal type of the resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/resources/{ResourceId}/permissions/{PrincipalId}"
    path_params: [{name: ResourceId, var: resource_id}, {name: PrincipalId, var: principal_id}]
    query: [{name: type, var: type}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_id: $resource_id, principal_id: $principal_id, type: $type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recovers a deleted version of an Amazon WorkDocs document.
#
# POST /api/v1/documentVersions/restore/{DocumentId}
# operationId: RestoreDocumentVersions
export def "restore-document-versions" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/documentVersions/restore/{DocumentId}"
    path_params: [{name: DocumentId, var: document_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    document_id: $document_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches metadata and the content of folders, documents, document versions, and comments.
#
# POST /api/v1/search
# Returns: record<Items: table<ResourceType: string, WebUrl: string, DocumentMetadata: record, FolderMetadata: record, CommentMetadata: record, DocumentVersionMetadata: record>, Marker: string>
# operationId: SearchResources
export def "search-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API. (format: password)
  --query-text: string # The String to search for. Searches across different text fields based on request parameters. Use double quotes around the query string for exact phrase matches. (format: password)
  --query-scopes: list<string> # Filter based on the text field type. A Folder has only a name and no content. A Comment has only content and no name. A Document or Document Version has a name and content
  --organization-id: string # Filters based on the resource owner OrgId. This is a mandatory parameter when using Admin SigV4 credentials.
  --additional-response-fields: list<string> # A list of attributes to include in the response. Used to request fields that are not normally returned in a standard response.
  --filters: record # Filters results based on entity metadata. — shape: {TextLocales?: list<string>, ContentCategories?: list<string>, ResourceTypes?: list<string>, Labels?: list<string>, Principals?: list, AncestorIds?: list<string>, SearchCollectionTypes?: list<string>, SizeRange?: record, CreatedRange?: record, ModifiedRange?: record}
  --order-by: list # Order by results in one or more categories. — item shape: {Field?: "RELEVANCE"|"NAME"|"SIZE"|"CREATED_TIMESTAMP"|"MODIFIED_TIMESTAMP", Order?: "ASC"|"DESC"}
  --body-limit: int # Max results count per page. (spec name: Limit)
  --body-marker: string # The marker for the next set of results. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/search"
    query: [{name: Limit, var: limit}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Authentication, var: authentication}]
    body: {content_type: "application/json", kind: json, fields: [{name: QueryText, var: query_text}, {name: QueryScopes, var: query_scopes}, {name: OrganizationId, var: organization_id}, {name: AdditionalResponseFields, var: additional_response_fields}, {name: Filters, var: filters}, {name: OrderBy, var: order_by}, {name: Limit, var: body_limit}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authentication: $authentication, query_text: $query_text, query_scopes: $query_scopes, organization_id: $organization_id, additional_response_fields: $additional_response_fields, filters: $filters, order_by: $order_by, body_limit: $body_limit, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
