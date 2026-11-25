# Auto-generated client for AWS Outposts v2019-12-03
# Source: https://api.apis.guru/v2/specs/amazonaws.com/outposts/2019-12-03/openapi.json
# Auth: --token flag or $env.AWS_OUTPOSTS_TOKEN

const CLIENT = {
  base_url: "http://outposts.us-east-1.amazonaws.com"
  token_env_var: "AWS_OUTPOSTS_TOKEN"
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

def base-url-completer [] { ["http://outposts.us-east-1.amazonaws.com" "http://outposts.us-east-2.amazonaws.com" "http://outposts.us-west-1.amazonaws.com" "http://outposts.us-west-2.amazonaws.com" "http://outposts.us-gov-west-1.amazonaws.com" "http://outposts.us-gov-east-1.amazonaws.com" "http://outposts.ca-central-1.amazonaws.com" "http://outposts.eu-north-1.amazonaws.com" "http://outposts.eu-west-1.amazonaws.com" "http://outposts.eu-west-2.amazonaws.com" "http://outposts.eu-west-3.amazonaws.com" "http://outposts.eu-central-1.amazonaws.com" "http://outposts.eu-south-1.amazonaws.com" "http://outposts.af-south-1.amazonaws.com" "http://outposts.ap-northeast-1.amazonaws.com" "http://outposts.ap-northeast-2.amazonaws.com" "http://outposts.ap-northeast-3.amazonaws.com" "http://outposts.ap-southeast-1.amazonaws.com" "http://outposts.ap-southeast-2.amazonaws.com" "http://outposts.ap-east-1.amazonaws.com" "http://outposts.ap-south-1.amazonaws.com" "http://outposts.sa-east-1.amazonaws.com" "http://outposts.me-south-1.amazonaws.com" "https://outposts.us-east-1.amazonaws.com" "https://outposts.us-east-2.amazonaws.com" "https://outposts.us-west-1.amazonaws.com" "https://outposts.us-west-2.amazonaws.com" "https://outposts.us-gov-west-1.amazonaws.com" "https://outposts.us-gov-east-1.amazonaws.com" "https://outposts.ca-central-1.amazonaws.com" "https://outposts.eu-north-1.amazonaws.com" "https://outposts.eu-west-1.amazonaws.com" "https://outposts.eu-west-2.amazonaws.com" "https://outposts.eu-west-3.amazonaws.com" "https://outposts.eu-central-1.amazonaws.com" "https://outposts.eu-south-1.amazonaws.com" "https://outposts.af-south-1.amazonaws.com" "https://outposts.ap-northeast-1.amazonaws.com" "https://outposts.ap-northeast-2.amazonaws.com" "https://outposts.ap-northeast-3.amazonaws.com" "https://outposts.ap-southeast-1.amazonaws.com" "https://outposts.ap-southeast-2.amazonaws.com" "https://outposts.ap-east-1.amazonaws.com" "https://outposts.ap-south-1.amazonaws.com" "https://outposts.sa-east-1.amazonaws.com" "https://outposts.me-south-1.amazonaws.com" "http://outposts.cn-north-1.amazonaws.com.cn" "http://outposts.cn-northwest-1.amazonaws.com.cn" "https://outposts.cn-north-1.amazonaws.com.cn" "https://outposts.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def payment-option-completer [] { ["ALL_UPFRONT" "NO_UPFRONT" "PARTIAL_UPFRONT"] }
def payment-term-completer [] { ["ONE_YEAR" "THREE_YEARS"] }
def supported-hardware-type-completer [] { ["RACK" "SERVER"] }
def address-type-completer [] { ["OPERATING_ADDRESS" "SHIPPING_ADDRESS"] }
def power-draw-kva-completer [] { ["POWER_10_KVA" "POWER_15_KVA" "POWER_30_KVA" "POWER_5_KVA"] }
def power-phase-completer [] { ["SINGLE_PHASE" "THREE_PHASE"] }
def power-connector-completer [] { ["AH530P7W" "AH532P6W" "IEC309" "L6_30P"] }
def power-feed-drop-completer [] { ["ABOVE_RACK" "BELOW_RACK"] }
def uplink-gbps-completer [] { ["UPLINK_100G" "UPLINK_10G" "UPLINK_1G" "UPLINK_40G"] }
def uplink-count-completer [] { ["UPLINK_COUNT_1" "UPLINK_COUNT_12" "UPLINK_COUNT_16" "UPLINK_COUNT_2" "UPLINK_COUNT_3" "UPLINK_COUNT_4" "UPLINK_COUNT_5" "UPLINK_COUNT_6" "UPLINK_COUNT_7" "UPLINK_COUNT_8"] }
def fiber-optic-cable-type-completer [] { ["MULTI_MODE" "SINGLE_MODE"] }
def optical-standard-completer [] { ["OPTIC_1000BASE_LX" "OPTIC_1000BASE_SX" "OPTIC_100GBASE_CWDM4" "OPTIC_100GBASE_LR4" "OPTIC_100GBASE_SR4" "OPTIC_100G_PSM4_MSA" "OPTIC_10GBASE_IR" "OPTIC_10GBASE_LR" "OPTIC_10GBASE_SR" "OPTIC_40GBASE_ESR" "OPTIC_40GBASE_IR4_LR4L" "OPTIC_40GBASE_LR4" "OPTIC_40GBASE_SR"] }
def maximum-supported-weight-lbs-completer [] { ["MAX_1400_LBS" "MAX_1600_LBS" "MAX_1800_LBS" "MAX_2000_LBS" "NO_LIMIT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    cancel-order: "record"
    create-order: "record<Order: record<OutpostId: string, OrderId: string, Status: string, LineItems: list<record>, PaymentOption: string, OrderSubmissionDate: string, OrderFulfilledDate: string, PaymentTerm: string, OrderType: string>>"
    create-outpost: "record<Outpost: record<OutpostId: string, OwnerId: string, OutpostArn: string, SiteId: string, Name: string, Description: string, LifeCycleStatus: string, AvailabilityZone: string, AvailabilityZoneId: string, Tags: record, SiteArn: string, SupportedHardwareType: string>>"
    list-outposts: "record<Outposts: table<OutpostId: string, OwnerId: string, OutpostArn: string, SiteId: string, Name: string, Description: string, LifeCycleStatus: string, AvailabilityZone: string, AvailabilityZoneId: string, Tags: record, SiteArn: string, SupportedHardwareType: string>, NextToken: string>"
    create-site: "record<Site: record<SiteId: string, AccountId: string, Name: string, Description: string, Tags: record, SiteArn: string, Notes: string, OperatingAddressCountryCode: string, OperatingAddressStateOrRegion: string, OperatingAddressCity: string, RackPhysicalProperties: record<PowerDrawKva: string, PowerPhase: string, PowerConnector: string, PowerFeedDrop: string, UplinkGbps: string, UplinkCount: string, FiberOpticCableType: string, OpticalStandard: string, MaximumSupportedWeightLbs: string>>>"
    list-sites: "record<Sites: table<SiteId: string, AccountId: string, Name: string, Description: string, Tags: record, SiteArn: string, Notes: string, OperatingAddressCountryCode: string, OperatingAddressStateOrRegion: string, OperatingAddressCity: string, RackPhysicalProperties: record>, NextToken: string>"
    delete-outpost: "record"
    get-outpost: "record<Outpost: record<OutpostId: string, OwnerId: string, OutpostArn: string, SiteId: string, Name: string, Description: string, LifeCycleStatus: string, AvailabilityZone: string, AvailabilityZoneId: string, Tags: record, SiteArn: string, SupportedHardwareType: string>>"
    update-outpost: "record<Outpost: record<OutpostId: string, OwnerId: string, OutpostArn: string, SiteId: string, Name: string, Description: string, LifeCycleStatus: string, AvailabilityZone: string, AvailabilityZoneId: string, Tags: record, SiteArn: string, SupportedHardwareType: string>>"
    delete-site: "record"
    get-site: "record<Site: record<SiteId: string, AccountId: string, Name: string, Description: string, Tags: record, SiteArn: string, Notes: string, OperatingAddressCountryCode: string, OperatingAddressStateOrRegion: string, OperatingAddressCity: string, RackPhysicalProperties: record<PowerDrawKva: string, PowerPhase: string, PowerConnector: string, PowerFeedDrop: string, UplinkGbps: string, UplinkCount: string, FiberOpticCableType: string, OpticalStandard: string, MaximumSupportedWeightLbs: string>>>"
    update-site: "record<Site: record<SiteId: string, AccountId: string, Name: string, Description: string, Tags: record, SiteArn: string, Notes: string, OperatingAddressCountryCode: string, OperatingAddressStateOrRegion: string, OperatingAddressCity: string, RackPhysicalProperties: record<PowerDrawKva: string, PowerPhase: string, PowerConnector: string, PowerFeedDrop: string, UplinkGbps: string, UplinkCount: string, FiberOpticCableType: string, OpticalStandard: string, MaximumSupportedWeightLbs: string>>>"
    get-catalog-item: "record<CatalogItem: record<CatalogItemId: string, ItemStatus: string, EC2Capacities: list<record>, PowerKva: float, WeightLbs: int, SupportedUplinkGbps: list<int>, SupportedStorage: list<string>>>"
    get-connection: "record<ConnectionId: string, ConnectionDetails: record<ClientPublicKey: string, ServerPublicKey: string, ServerEndpoint: string, ClientTunnelAddress: string, ServerTunnelAddress: string, AllowedIps: list<string>>>"
    get-order: "record<Order: record<OutpostId: string, OrderId: string, Status: string, LineItems: list<record>, PaymentOption: string, OrderSubmissionDate: string, OrderFulfilledDate: string, PaymentTerm: string, OrderType: string>>"
    get-outpost-instance-types: "record<InstanceTypes: table<InstanceType: string>, NextToken: string, OutpostId: string, OutpostArn: string>"
    get-site-address: "record<SiteId: string, AddressType: string, Address: record<ContactName: string, ContactPhoneNumber: string, AddressLine1: string, AddressLine2: string, AddressLine3: string, City: string, StateOrRegion: string, DistrictOrCounty: string, PostalCode: string, CountryCode: string, Municipality: string>>"
    list-assets: "record<Assets: table<AssetId: string, RackId: string, AssetType: string, ComputeAttributes: record, AssetLocation: record>, NextToken: string>"
    list-catalog-items: "record<CatalogItems: table<CatalogItemId: string, ItemStatus: string, EC2Capacities: list, PowerKva: float, WeightLbs: int, SupportedUplinkGbps: list, SupportedStorage: list>, NextToken: string>"
    list-orders: "record<Orders: table<OutpostId: string, OrderId: string, OrderType: string, Status: string, LineItemCountsByStatus: record, OrderSubmissionDate: string, OrderFulfilledDate: string>, NextToken: string>"
    list-tags-for-resource: "record<Tags: record>"
    tag-resource: "record"
    start-connection: "record<ConnectionId: string, UnderlayIpAddress: string>"
    untag-resource: "record"
    update-site-address: "record<AddressType: string, Address: record<ContactName: string, ContactPhoneNumber: string, AddressLine1: string, AddressLine2: string, AddressLine3: string, City: string, StateOrRegion: string, DistrictOrCounty: string, PostalCode: string, CountryCode: string, Municipality: string>>"
    update-site-rack-physical-properties: "record<Site: record<SiteId: string, AccountId: string, Name: string, Description: string, Tags: record, SiteArn: string, Notes: string, OperatingAddressCountryCode: string, OperatingAddressStateOrRegion: string, OperatingAddressCity: string, RackPhysicalProperties: record<PowerDrawKva: string, PowerPhase: string, PowerConnector: string, PowerFeedDrop: string, UplinkGbps: string, UplinkCount: string, FiberOpticCableType: string, OpticalStandard: string, MaximumSupportedWeightLbs: string>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["cancel-order" "create-order" "create-outpost" "list-outposts" "create-site" "list-sites" "delete-outpost" "get-outpost" "update-outpost" "delete-site" "get-site" "update-site" "get-catalog-item" "get-connection" "get-order" "get-outpost-instance-types" "get-site-address" "list-assets" "list-catalog-items" "list-orders" "list-tags-for-resource" "tag-resource" "start-connection" "untag-resource" "update-site-address" "update-site-rack-physical-properties" "commands"] | sort) } | get name | first)
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

# Cancels the specified order for an Outpost.
#
# POST /orders/{OrderId}/cancel
# Returns: record
# operationId: CancelOrder
export def "cancel-order" [
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
    path: "/orders/{OrderId}/cancel"
    path_params: [{name: OrderId, var: order_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an order for an Outpost.
#
# POST /orders
# Returns: record<Order: record<OutpostId: string, OrderId: string, Status: string, LineItems: list<record>, PaymentOption: string, OrderSubmissionDate: string, OrderFulfilledDate: string, PaymentTerm: string, OrderType: string>>
# operationId: CreateOrder
export def "create-order" [
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
  outpost_identifier: string # The ID or the Amazon Resource Name (ARN) of the Outpost.
  line_items: list # The line items that make up the order. — item shape: {CatalogItemId?: string, Quantity?: int}
  payment_option: string@payment-option-completer # The payment option.
  --payment-term: string@payment-term-completer # The payment terms.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orders"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: OutpostIdentifier, var: outpost_identifier}, {name: LineItems, var: line_items}, {name: PaymentOption, var: payment_option}, {name: PaymentTerm, var: payment_term}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, outpost_identifier: $outpost_identifier, line_items: $line_items, payment_option: $payment_option, payment_term: $payment_term
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Outpost. You can specify either an Availability one or an AZ ID.
#
# POST /outposts
# Returns: record<Outpost: record<OutpostId: string, OwnerId: string, OutpostArn: string, SiteId: string, Name: string, Description: string, LifeCycleStatus: string, AvailabilityZone: string, AvailabilityZoneId: string, Tags: record, SiteArn: string, SupportedHardwareType: string>>
# operationId: CreateOutpost
export def "create-outpost" [
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
  name: string # The name of the Outpost.
  --description: string # The description of the Outpost.
  site_id: string # The ID of the site.
  --availability-zone: string # The Availability Zone.
  --availability-zone-id: string # The ID of the Availability Zone.
  --tags: record # The tags to apply to the Outpost.
  --supported-hardware-type: string@supported-hardware-type-completer # The type of hardware for this Outpost.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/outposts"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: SiteId, var: site_id}, {name: AvailabilityZone, var: availability_zone}, {name: AvailabilityZoneId, var: availability_zone_id}, {name: Tags, var: tags}, {name: SupportedHardwareType, var: supported_hardware_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, site_id: $site_id, availability_zone: $availability_zone, availability_zone_id: $availability_zone_id, tags: $tags, supported_hardware_type: $supported_hardware_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Outposts for your Amazon Web Services account. Use filters to return specific results. If you specify multiple filters, the results include only the resources that match all of the specified filters. For a filter where you can specify multiple values, the results include items that match any of the values that you specify for the filter.
#
# GET /outposts
# Returns: record<Outposts: table<OutpostId: string, OwnerId: string, OutpostArn: string, SiteId: string, Name: string, Description: string, LifeCycleStatus: string, AvailabilityZone: string, AvailabilityZoneId: string, Tags: record, SiteArn: string, SupportedHardwareType: string>, NextToken: string>
# operationId: ListOutposts
export def "list-outposts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: int
  --life-cycle-status-filter: list<string> # Filters the results by the lifecycle status.
  --availability-zone-filter: list<string> # Filters the results by Availability Zone (for example, us-east-1a).
  --availability-zone-id-filter: list<string> # Filters the results by AZ ID (for example, use1-az1).
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
    path: "/outposts"
    query: [{name: NextToken, var: next_token}, {name: MaxResults, var: max_results}, {name: LifeCycleStatusFilter, var: life_cycle_status_filter, style: multi}, {name: AvailabilityZoneFilter, var: availability_zone_filter, style: multi}, {name: AvailabilityZoneIdFilter, var: availability_zone_id_filter, style: multi}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, life_cycle_status_filter: $life_cycle_status_filter, availability_zone_filter: $availability_zone_filter, availability_zone_id_filter: $availability_zone_id_filter, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a site for an Outpost.
#
# POST /sites
# Returns: record<Site: record<SiteId: string, AccountId: string, Name: string, Description: string, Tags: record, SiteArn: string, Notes: string, OperatingAddressCountryCode: string, OperatingAddressStateOrRegion: string, OperatingAddressCity: string, RackPhysicalProperties: record<PowerDrawKva: string, PowerPhase: string, PowerConnector: string, PowerFeedDrop: string, UplinkGbps: string, UplinkCount: string, FiberOpticCableType: string, OpticalStandard: string, MaximumSupportedWeightLbs: string>>>
# operationId: CreateSite
export def "create-site" [
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
  name: string # The name of the site.
  --description: string # The description of the site.
  --notes: string # Additional information that you provide about site access requirements, electrician scheduling, personal protective equipment, or regulation of equipment materials that could affect your installation process.
  --tags: record # The tags to apply to a site.
  --operating-address: record # Information about an address. — shape: {ContactName?: string, ContactPhoneNumber?: string, AddressLine1?: string, AddressLine2?: string, AddressLine3?: string, City?: string, StateOrRegion?: string, DistrictOrCounty?: string, PostalCode?: string, CountryCode?: string, Municipality?: string}
  --shipping-address: record # Information about an address. — shape: {ContactName?: string, ContactPhoneNumber?: string, AddressLine1?: string, AddressLine2?: string, AddressLine3?: string, City?: string, StateOrRegion?: string, DistrictOrCounty?: string, PostalCode?: string, CountryCode?: string, Municipality?: string}
  --rack-physical-properties: record # Information about the physical and logistical details for racks at sites. For more information about hardware requirements for racks, see Network readiness checklist (https://docs.aws.amazon.com/outposts/latest/userguide/outposts-requirements.html#checklist) in the Amazon Web Services Outposts User Guide. — shape: {PowerDrawKva?: "POWER_5_KVA"|"POWER_10_KVA"|"POWER_15_KVA"|"POWER_30_KVA", PowerPhase?: "SINGLE_PHASE"|"THREE_PHASE", PowerConnector?: "L6_30P"|"IEC309"|"AH530P7W"|"AH532P6W", PowerFeedDrop?: "ABOVE_RACK"|"BELOW_RACK", UplinkGbps?: "UPLINK_1G"|"UPLINK_10G"|"UPLINK_40G"|"UPLINK_100G", UplinkCount?: "UPLINK_COUNT_1"|"UPLINK_COUNT_2"|"UPLINK_COUNT_3"|"UPLINK_COUNT_4"|"UPLINK_COUNT_5"|"UPLINK_COUNT_6"|"UPLINK_COUNT_7"|"UPLINK_COUNT_8"|"UPLINK_COUNT_12"|"UPLINK_COUNT_16", ... (3 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sites"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: Notes, var: notes}, {name: Tags, var: tags}, {name: OperatingAddress, var: operating_address}, {name: ShippingAddress, var: shipping_address}, {name: RackPhysicalProperties, var: rack_physical_properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, notes: $notes, tags: $tags, operating_address: $operating_address, shipping_address: $shipping_address, rack_physical_properties: $rack_physical_properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Outpost sites for your Amazon Web Services account. Use filters to return specific results. Use filters to return specific results. If you specify multiple filters, the results include only the resources that match all of the specified filters. For a filter where you can specify multiple values, the results include items that match any of the values that you specify for the filter.
#
# GET /sites
# Returns: record<Sites: table<SiteId: string, AccountId: string, Name: string, Description: string, Tags: record, SiteArn: string, Notes: string, OperatingAddressCountryCode: string, OperatingAddressStateOrRegion: string, OperatingAddressCity: string, RackPhysicalProperties: record>, NextToken: string>
# operationId: ListSites
export def "list-sites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: int
  --operating-address-country-code-filter: list<string> # Filters the results by country code.
  --operating-address-state-or-region-filter: list<string> # Filters the results by state or region.
  --operating-address-city-filter: list<string> # Filters the results by city.
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
    path: "/sites"
    query: [{name: NextToken, var: next_token}, {name: MaxResults, var: max_results}, {name: OperatingAddressCountryCodeFilter, var: operating_address_country_code_filter, style: multi}, {name: OperatingAddressStateOrRegionFilter, var: operating_address_state_or_region_filter, style: multi}, {name: OperatingAddressCityFilter, var: operating_address_city_filter, style: multi}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, operating_address_country_code_filter: $operating_address_country_code_filter, operating_address_state_or_region_filter: $operating_address_state_or_region_filter, operating_address_city_filter: $operating_address_city_filter, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified Outpost.
#
# DELETE /outposts/{OutpostId}
# Returns: record
# operationId: DeleteOutpost
export def "delete-outpost" [
  outpost_id: string
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
    path: "/outposts/{OutpostId}"
    path_params: [{name: OutpostId, var: outpost_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    outpost_id: $outpost_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified Outpost.
#
# GET /outposts/{OutpostId}
# Returns: record<Outpost: record<OutpostId: string, OwnerId: string, OutpostArn: string, SiteId: string, Name: string, Description: string, LifeCycleStatus: string, AvailabilityZone: string, AvailabilityZoneId: string, Tags: record, SiteArn: string, SupportedHardwareType: string>>
# operationId: GetOutpost
export def "get-outpost" [
  outpost_id: string
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
    path: "/outposts/{OutpostId}"
    path_params: [{name: OutpostId, var: outpost_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    outpost_id: $outpost_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Outpost.
#
# PATCH /outposts/{OutpostId}
# Returns: record<Outpost: record<OutpostId: string, OwnerId: string, OutpostArn: string, SiteId: string, Name: string, Description: string, LifeCycleStatus: string, AvailabilityZone: string, AvailabilityZoneId: string, Tags: record, SiteArn: string, SupportedHardwareType: string>>
# operationId: UpdateOutpost
export def "update-outpost" [
  outpost_id: string
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
  --name: string # The name of the Outpost.
  --description: string # The description of the Outpost.
  --supported-hardware-type: string@supported-hardware-type-completer # The type of hardware for this Outpost.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/outposts/{OutpostId}"
    path_params: [{name: OutpostId, var: outpost_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: SupportedHardwareType, var: supported_hardware_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    outpost_id: $outpost_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, supported_hardware_type: $supported_hardware_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified site.
#
# DELETE /sites/{SiteId}
# Returns: record
# operationId: DeleteSite
export def "delete-site" [
  site_id: string
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
    path: "/sites/{SiteId}"
    path_params: [{name: SiteId, var: site_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified Outpost site.
#
# GET /sites/{SiteId}
# Returns: record<Site: record<SiteId: string, AccountId: string, Name: string, Description: string, Tags: record, SiteArn: string, Notes: string, OperatingAddressCountryCode: string, OperatingAddressStateOrRegion: string, OperatingAddressCity: string, RackPhysicalProperties: record<PowerDrawKva: string, PowerPhase: string, PowerConnector: string, PowerFeedDrop: string, UplinkGbps: string, UplinkCount: string, FiberOpticCableType: string, OpticalStandard: string, MaximumSupportedWeightLbs: string>>>
# operationId: GetSite
export def "get-site" [
  site_id: string
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
    path: "/sites/{SiteId}"
    path_params: [{name: SiteId, var: site_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified site.
#
# PATCH /sites/{SiteId}
# Returns: record<Site: record<SiteId: string, AccountId: string, Name: string, Description: string, Tags: record, SiteArn: string, Notes: string, OperatingAddressCountryCode: string, OperatingAddressStateOrRegion: string, OperatingAddressCity: string, RackPhysicalProperties: record<PowerDrawKva: string, PowerPhase: string, PowerConnector: string, PowerFeedDrop: string, UplinkGbps: string, UplinkCount: string, FiberOpticCableType: string, OpticalStandard: string, MaximumSupportedWeightLbs: string>>>
# operationId: UpdateSite
export def "update-site" [
  site_id: string
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
  --name: string # The name of the site.
  --description: string # The description of the site.
  --notes: string # Notes about a site.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/sites/{SiteId}"
    path_params: [{name: SiteId, var: site_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: Notes, var: notes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, notes: $notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified catalog item.
#
# GET /catalog/item/{CatalogItemId}
# Returns: record<CatalogItem: record<CatalogItemId: string, ItemStatus: string, EC2Capacities: list<record>, PowerKva: float, WeightLbs: int, SupportedUplinkGbps: list<int>, SupportedStorage: list<string>>>
# operationId: GetCatalogItem
export def "get-catalog-item" [
  catalog_item_id: string
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
    path: "/catalog/item/{CatalogItemId}"
    path_params: [{name: CatalogItemId, var: catalog_item_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    catalog_item_id: $catalog_item_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Amazon Web Services uses this action to install Outpost servers. Gets information about the specified connection. Use CloudTrail to monitor this action or Amazon Web Services managed policy for Amazon Web Services Outposts to secure it. For more information, see Amazon Web Services managed policies for Amazon Web Services Outposts (https://docs.aws.amazon.com/outposts/latest/userguide/security-iam-awsmanpol.html) and Logging Amazon Web Services Outposts API calls with Amazon Web Services CloudTrail (https://docs.aws.amazon.com/outposts/latest/userguide/logging-using-cloudtrail.html) in the Amazon Web Services Outposts User Guide.
#
# GET /connections/{ConnectionId}
# Returns: record<ConnectionId: string, ConnectionDetails: record<ClientPublicKey: string, ServerPublicKey: string, ServerEndpoint: string, ClientTunnelAddress: string, ServerTunnelAddress: string, AllowedIps: list<string>>>
# operationId: GetConnection
export def "get-connection" [
  connection_id: string
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
    path: "/connections/{ConnectionId}"
    path_params: [{name: ConnectionId, var: connection_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified order.
#
# GET /orders/{OrderId}
# Returns: record<Order: record<OutpostId: string, OrderId: string, Status: string, LineItems: list<record>, PaymentOption: string, OrderSubmissionDate: string, OrderFulfilledDate: string, PaymentTerm: string, OrderType: string>>
# operationId: GetOrder
export def "get-order" [
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
    path: "/orders/{OrderId}"
    path_params: [{name: OrderId, var: order_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the instance types for the specified Outpost.
#
# GET /outposts/{OutpostId}/instanceTypes
# Returns: record<InstanceTypes: table<InstanceType: string>, NextToken: string, OutpostId: string, OutpostArn: string>
# operationId: GetOutpostInstanceTypes
export def "get-outpost-instance-types" [
  outpost_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: int
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
    path: "/outposts/{OutpostId}/instanceTypes"
    path_params: [{name: OutpostId, var: outpost_id}]
    query: [{name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    outpost_id: $outpost_id, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the site address of the specified site.
#
# GET /sites/{SiteId}/address
# Returns: record<SiteId: string, AddressType: string, Address: record<ContactName: string, ContactPhoneNumber: string, AddressLine1: string, AddressLine2: string, AddressLine3: string, City: string, StateOrRegion: string, DistrictOrCounty: string, PostalCode: string, CountryCode: string, Municipality: string>>
# operationId: GetSiteAddress
export def "get-site-address" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-type: string@address-type-completer # The type of the address you request. (required)
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
    path: "/sites/{SiteId}/address"
    path_params: [{name: SiteId, var: site_id}]
    query: [{name: AddressType, var: address_type, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, address_type: $address_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the hardware assets for the specified Outpost. Use filters to return specific results. If you specify multiple filters, the results include only the resources that match all of the specified filters. For a filter where you can specify multiple values, the results include items that match any of the values that you specify for the filter.
#
# GET /outposts/{OutpostId}/assets
# Returns: record<Assets: table<AssetId: string, RackId: string, AssetType: string, ComputeAttributes: record, AssetLocation: record>, NextToken: string>
# operationId: ListAssets
export def "list-assets" [
  outpost_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id-filter: list<string> # Filters the results by the host ID of a Dedicated Host.
  --max-results: int
  --next-token: string
  --status-filter: list<string> # Filters the results by state.
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
    path: "/outposts/{OutpostId}/assets"
    path_params: [{name: OutpostId, var: outpost_id}]
    query: [{name: HostIdFilter, var: host_id_filter, style: multi}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}, {name: StatusFilter, var: status_filter, style: multi}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    outpost_id: $outpost_id, host_id_filter: $host_id_filter, max_results: $max_results, next_token: $next_token, status_filter: $status_filter, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the items in the catalog. Use filters to return specific results. If you specify multiple filters, the results include only the resources that match all of the specified filters. For a filter where you can specify multiple values, the results include items that match any of the values that you specify for the filter.
#
# GET /catalog/items
# Returns: record<CatalogItems: table<CatalogItemId: string, ItemStatus: string, EC2Capacities: list, PowerKva: float, WeightLbs: int, SupportedUplinkGbps: list, SupportedStorage: list>, NextToken: string>
# operationId: ListCatalogItems
export def "list-catalog-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: int
  --item-class-filter: list<string> # Filters the results by item class.
  --supported-storage-filter: list<string> # Filters the results by storage option.
  --ec2-family-filter: list<string> # Filters the results by EC2 family (for example, M5).
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
    path: "/catalog/items"
    query: [{name: NextToken, var: next_token}, {name: MaxResults, var: max_results}, {name: ItemClassFilter, var: item_class_filter, style: multi}, {name: SupportedStorageFilter, var: supported_storage_filter, style: multi}, {name: EC2FamilyFilter, var: ec2_family_filter, style: multi}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, item_class_filter: $item_class_filter, supported_storage_filter: $supported_storage_filter, ec2_family_filter: $ec2_family_filter, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Outpost orders for your Amazon Web Services account.
#
# GET /list-orders
# Returns: record<Orders: table<OutpostId: string, OrderId: string, OrderType: string, Status: string, LineItemCountsByStatus: record, OrderSubmissionDate: string, OrderFulfilledDate: string>, NextToken: string>
# operationId: ListOrders
export def "list-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --outpost-identifier-filter: string # The ID or the Amazon Resource Name (ARN) of the Outpost.
  --next-token: string
  --max-results: int
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
    path: "/list-orders"
    query: [{name: OutpostIdentifierFilter, var: outpost_identifier_filter}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    outpost_identifier_filter: $outpost_identifier_filter, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tags for the specified resource.
#
# GET /tags/{ResourceArn}
# Returns: record<Tags: record>
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
    path: "/tags/{ResourceArn}"
    path_params: [{name: ResourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds tags to the specified resource.
#
# POST /tags/{ResourceArn}
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
  tags: record # The tags to add to the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags/{ResourceArn}"
    path_params: [{name: ResourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Amazon Web Services uses this action to install Outpost servers. Starts the connection required for Outpost server installation. Use CloudTrail to monitor this action or Amazon Web Services managed policy for Amazon Web Services Outposts to secure it. For more information, see Amazon Web Services managed policies for Amazon Web Services Outposts (https://docs.aws.amazon.com/outposts/latest/userguide/security-iam-awsmanpol.html) and Logging Amazon Web Services Outposts API calls with Amazon Web Services CloudTrail (https://docs.aws.amazon.com/outposts/latest/userguide/logging-using-cloudtrail.html) in the Amazon Web Services Outposts User Guide.
#
# POST /connections
# Returns: record<ConnectionId: string, UnderlayIpAddress: string>
# operationId: StartConnection
export def "start-connection" [
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
  device_serial_number: string # The serial number of the dongle.
  asset_id: string # The ID of the Outpost server.
  client_public_key: string # The public key of the client.
  network_interface_device_index: int # The device index of the network interface on the Outpost server.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/connections"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DeviceSerialNumber, var: device_serial_number}, {name: AssetId, var: asset_id}, {name: ClientPublicKey, var: client_public_key}, {name: NetworkInterfaceDeviceIndex, var: network_interface_device_index}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, device_serial_number: $device_serial_number, asset_id: $asset_id, client_public_key: $client_public_key, network_interface_device_index: $network_interface_device_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes tags from the specified resource.
#
# DELETE /tags/{ResourceArn}
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
  --tag-keys: list<string> # The tag keys. (required)
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
    path: "/tags/{ResourceArn}"
    path_params: [{name: ResourceArn, var: resource_arn}]
    query: [{name: tagKeys, var: tag_keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, tag_keys: $tag_keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the address of the specified site. You can't update a site address if there is an order in progress. You must wait for the order to complete or cancel the order. You can update the operating address before you place an order at the site, or after all Outposts that belong to the site have been deactivated.
#
# PUT /sites/{SiteId}/address
# Returns: record<AddressType: string, Address: record<ContactName: string, ContactPhoneNumber: string, AddressLine1: string, AddressLine2: string, AddressLine3: string, City: string, StateOrRegion: string, DistrictOrCounty: string, PostalCode: string, CountryCode: string, Municipality: string>>
# operationId: UpdateSiteAddress
export def "update-site-address" [
  site_id: string
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
  address_type: string@address-type-completer # The type of the address.
  address: record # Information about an address. — shape: {ContactName?: string, ContactPhoneNumber?: string, AddressLine1?: string, AddressLine2?: string, AddressLine3?: string, City?: string, StateOrRegion?: string, DistrictOrCounty?: string, PostalCode?: string, CountryCode?: string, Municipality?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sites/{SiteId}/address"
    path_params: [{name: SiteId, var: site_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AddressType, var: address_type}, {name: Address, var: address}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, address_type: $address_type, address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the physical and logistical details for a rack at a site. For more information about hardware requirements for racks, see Network readiness checklist (https://docs.aws.amazon.com/outposts/latest/userguide/outposts-requirements.html#checklist) in the Amazon Web Services Outposts User Guide. To update a rack at a site with an order of IN_PROGRESS, you must wait for the order to complete or cancel the order.
#
# PATCH /sites/{SiteId}/rackPhysicalProperties
# Returns: record<Site: record<SiteId: string, AccountId: string, Name: string, Description: string, Tags: record, SiteArn: string, Notes: string, OperatingAddressCountryCode: string, OperatingAddressStateOrRegion: string, OperatingAddressCity: string, RackPhysicalProperties: record<PowerDrawKva: string, PowerPhase: string, PowerConnector: string, PowerFeedDrop: string, UplinkGbps: string, UplinkCount: string, FiberOpticCableType: string, OpticalStandard: string, MaximumSupportedWeightLbs: string>>>
# operationId: UpdateSiteRackPhysicalProperties
export def "update-site-rack-physical-properties" [
  site_id: string
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
  --power-draw-kva: string@power-draw-kva-completer # The power draw, in kVA, available at the hardware placement position for the rack.
  --power-phase: string@power-phase-completer # The power option that you can provide for hardware. Single-phase AC feed: 200 V to 277 V, 50 Hz or 60 Hz Three-phase AC feed: 346 V to 480 V, 50 Hz or 60 Hz
  --power-connector: string@power-connector-completer # The power connector that Amazon Web Services should plan to provide for connections to the hardware. Note the correlation between PowerPhase and PowerConnector. Single-phase AC feed L6-30P – (common in US); 30A; single phase IEC309 (blue) – P+N+E, 6hr; 32 A; single phase Three-phase AC feed AH530P7W (red) – 3P+N+E, 7hr; 30A; three phase AH532P6W (red) – 3P+N+E, 6hr; 32A; three phase
  --power-feed-drop: string@power-feed-drop-completer # Indicates whether the power feed comes above or below the rack.
  --uplink-gbps: string@uplink-gbps-completer # The uplink speed the rack should support for the connection to the Region.
  --uplink-count: string@uplink-count-completer # Racks come with two Outpost network devices. Depending on the supported uplink speed at the site, the Outpost network devices provide a variable number of uplinks. Specify the number of uplinks for each Outpost network device that you intend to use to connect the rack to your network. Note the correlation between UplinkGbps and UplinkCount. 1Gbps - Uplinks available: 1, 2, 4, 6, 8 10Gbps - Uplinks available: 1, 2, 4, 8, 12, 16 40 and 100 Gbps- Uplinks available: 1, 2, 4
  --fiber-optic-cable-type: string@fiber-optic-cable-type-completer # The type of fiber that you will use to attach the Outpost to your network.
  --optical-standard: string@optical-standard-completer # The type of optical standard that you will use to attach the Outpost to your network. This field is dependent on uplink speed, fiber type, and distance to the upstream device. For more information about networking requirements for racks, see Network (https://docs.aws.amazon.com/outposts/latest/userguide/outposts-requirements.html#facility-networking) in the Amazon Web Services Outposts User Guide. OPTIC_10GBASE_SR: 10GBASE-SR OPTIC_10GBASE_IR: 10GBASE-IR OPTIC_10GBASE_LR: 10GBASE-LR OPTIC_40GBASE_SR: 40GBASE-SR OPTIC_40GBASE_ESR: 40GBASE-ESR OPTIC_40GBASE_IR4_LR4L: 40GBASE-IR (LR4L) OPTIC_40GBASE_LR4: 40GBASE-LR4 OPTIC_100GBASE_SR4: 100GBASE-SR4 OPTIC_100GBASE_CWDM4: 100GBASE-CWDM4 OPTIC_100GBASE_LR4: 100GBASE-LR4 OPTIC_100G_PSM4_MSA: 100G PSM4 MSA OPTIC_1000BASE_LX: 1000Base-LX OPTIC_1000BASE_SX : 1000Base-SX
  --maximum-supported-weight-lbs: string@maximum-supported-weight-lbs-completer # The maximum rack weight that this site can support. NO_LIMIT is over 2000lbs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/sites/{SiteId}/rackPhysicalProperties"
    path_params: [{name: SiteId, var: site_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: PowerDrawKva, var: power_draw_kva}, {name: PowerPhase, var: power_phase}, {name: PowerConnector, var: power_connector}, {name: PowerFeedDrop, var: power_feed_drop}, {name: UplinkGbps, var: uplink_gbps}, {name: UplinkCount, var: uplink_count}, {name: FiberOpticCableType, var: fiber_optic_cable_type}, {name: OpticalStandard, var: optical_standard}, {name: MaximumSupportedWeightLbs, var: maximum_supported_weight_lbs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, power_draw_kva: $power_draw_kva, power_phase: $power_phase, power_connector: $power_connector, power_feed_drop: $power_feed_drop, uplink_gbps: $uplink_gbps, uplink_count: $uplink_count, fiber_optic_cable_type: $fiber_optic_cable_type, optical_standard: $optical_standard, maximum_supported_weight_lbs: $maximum_supported_weight_lbs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
