# Auto-generated client for AWS CodeCommit v2015-04-13
# Source: https://api.apis.guru/v2/specs/amazonaws.com/codecommit/2015-04-13/openapi.json
# Auth: --token flag or $env.AWS_CODECOMMIT_TOKEN

const CLIENT = {
  base_url: "http://codecommit.us-east-1.amazonaws.com"
  token_env_var: "AWS_CODECOMMIT_TOKEN"
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

def base-url-completer [] { ["http://codecommit.us-east-1.amazonaws.com" "http://codecommit.us-east-2.amazonaws.com" "http://codecommit.us-west-1.amazonaws.com" "http://codecommit.us-west-2.amazonaws.com" "http://codecommit.us-gov-west-1.amazonaws.com" "http://codecommit.us-gov-east-1.amazonaws.com" "http://codecommit.ca-central-1.amazonaws.com" "http://codecommit.eu-north-1.amazonaws.com" "http://codecommit.eu-west-1.amazonaws.com" "http://codecommit.eu-west-2.amazonaws.com" "http://codecommit.eu-west-3.amazonaws.com" "http://codecommit.eu-central-1.amazonaws.com" "http://codecommit.eu-south-1.amazonaws.com" "http://codecommit.af-south-1.amazonaws.com" "http://codecommit.ap-northeast-1.amazonaws.com" "http://codecommit.ap-northeast-2.amazonaws.com" "http://codecommit.ap-northeast-3.amazonaws.com" "http://codecommit.ap-southeast-1.amazonaws.com" "http://codecommit.ap-southeast-2.amazonaws.com" "http://codecommit.ap-east-1.amazonaws.com" "http://codecommit.ap-south-1.amazonaws.com" "http://codecommit.sa-east-1.amazonaws.com" "http://codecommit.me-south-1.amazonaws.com" "https://codecommit.us-east-1.amazonaws.com" "https://codecommit.us-east-2.amazonaws.com" "https://codecommit.us-west-1.amazonaws.com" "https://codecommit.us-west-2.amazonaws.com" "https://codecommit.us-gov-west-1.amazonaws.com" "https://codecommit.us-gov-east-1.amazonaws.com" "https://codecommit.ca-central-1.amazonaws.com" "https://codecommit.eu-north-1.amazonaws.com" "https://codecommit.eu-west-1.amazonaws.com" "https://codecommit.eu-west-2.amazonaws.com" "https://codecommit.eu-west-3.amazonaws.com" "https://codecommit.eu-central-1.amazonaws.com" "https://codecommit.eu-south-1.amazonaws.com" "https://codecommit.af-south-1.amazonaws.com" "https://codecommit.ap-northeast-1.amazonaws.com" "https://codecommit.ap-northeast-2.amazonaws.com" "https://codecommit.ap-northeast-3.amazonaws.com" "https://codecommit.ap-southeast-1.amazonaws.com" "https://codecommit.ap-southeast-2.amazonaws.com" "https://codecommit.ap-east-1.amazonaws.com" "https://codecommit.ap-south-1.amazonaws.com" "https://codecommit.sa-east-1.amazonaws.com" "https://codecommit.me-south-1.amazonaws.com" "http://codecommit.cn-north-1.amazonaws.com.cn" "http://codecommit.cn-northwest-1.amazonaws.com.cn" "https://codecommit.cn-north-1.amazonaws.com.cn" "https://codecommit.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["CodeCommit_20150413.AssociateApprovalRuleTemplateWithRepository"] }
def x-amz-target-completer-1 [] { ["CodeCommit_20150413.BatchAssociateApprovalRuleTemplateWithRepositories"] }
def merge-option-completer [] { ["FAST_FORWARD_MERGE" "SQUASH_MERGE" "THREE_WAY_MERGE"] }
def conflict-detail-level-completer [] { ["FILE_LEVEL" "LINE_LEVEL"] }
def conflict-resolution-strategy-completer [] { ["ACCEPT_DESTINATION" "ACCEPT_SOURCE" "AUTOMERGE" "NONE"] }
def x-amz-target-completer-2 [] { ["CodeCommit_20150413.BatchDescribeMergeConflicts"] }
def x-amz-target-completer-3 [] { ["CodeCommit_20150413.BatchDisassociateApprovalRuleTemplateFromRepositories"] }
def x-amz-target-completer-4 [] { ["CodeCommit_20150413.BatchGetCommits"] }
def x-amz-target-completer-5 [] { ["CodeCommit_20150413.BatchGetRepositories"] }
def x-amz-target-completer-6 [] { ["CodeCommit_20150413.CreateApprovalRuleTemplate"] }
def x-amz-target-completer-7 [] { ["CodeCommit_20150413.CreateBranch"] }
def x-amz-target-completer-8 [] { ["CodeCommit_20150413.CreateCommit"] }
def x-amz-target-completer-9 [] { ["CodeCommit_20150413.CreatePullRequest"] }
def x-amz-target-completer-10 [] { ["CodeCommit_20150413.CreatePullRequestApprovalRule"] }
def x-amz-target-completer-11 [] { ["CodeCommit_20150413.CreateRepository"] }
def x-amz-target-completer-12 [] { ["CodeCommit_20150413.CreateUnreferencedMergeCommit"] }
def x-amz-target-completer-13 [] { ["CodeCommit_20150413.DeleteApprovalRuleTemplate"] }
def x-amz-target-completer-14 [] { ["CodeCommit_20150413.DeleteBranch"] }
def x-amz-target-completer-15 [] { ["CodeCommit_20150413.DeleteCommentContent"] }
def x-amz-target-completer-16 [] { ["CodeCommit_20150413.DeleteFile"] }
def x-amz-target-completer-17 [] { ["CodeCommit_20150413.DeletePullRequestApprovalRule"] }
def x-amz-target-completer-18 [] { ["CodeCommit_20150413.DeleteRepository"] }
def x-amz-target-completer-19 [] { ["CodeCommit_20150413.DescribeMergeConflicts"] }
def pull-request-event-type-completer [] { ["PULL_REQUEST_APPROVAL_RULE_CREATED" "PULL_REQUEST_APPROVAL_RULE_DELETED" "PULL_REQUEST_APPROVAL_RULE_OVERRIDDEN" "PULL_REQUEST_APPROVAL_RULE_UPDATED" "PULL_REQUEST_APPROVAL_STATE_CHANGED" "PULL_REQUEST_CREATED" "PULL_REQUEST_MERGE_STATE_CHANGED" "PULL_REQUEST_SOURCE_REFERENCE_UPDATED" "PULL_REQUEST_STATUS_CHANGED"] }
def x-amz-target-completer-20 [] { ["CodeCommit_20150413.DescribePullRequestEvents"] }
def x-amz-target-completer-21 [] { ["CodeCommit_20150413.DisassociateApprovalRuleTemplateFromRepository"] }
def x-amz-target-completer-22 [] { ["CodeCommit_20150413.EvaluatePullRequestApprovalRules"] }
def x-amz-target-completer-23 [] { ["CodeCommit_20150413.GetApprovalRuleTemplate"] }
def x-amz-target-completer-24 [] { ["CodeCommit_20150413.GetBlob"] }
def x-amz-target-completer-25 [] { ["CodeCommit_20150413.GetBranch"] }
def x-amz-target-completer-26 [] { ["CodeCommit_20150413.GetComment"] }
def x-amz-target-completer-27 [] { ["CodeCommit_20150413.GetCommentReactions"] }
def x-amz-target-completer-28 [] { ["CodeCommit_20150413.GetCommentsForComparedCommit"] }
def x-amz-target-completer-29 [] { ["CodeCommit_20150413.GetCommentsForPullRequest"] }
def x-amz-target-completer-30 [] { ["CodeCommit_20150413.GetCommit"] }
def x-amz-target-completer-31 [] { ["CodeCommit_20150413.GetDifferences"] }
def x-amz-target-completer-32 [] { ["CodeCommit_20150413.GetFile"] }
def x-amz-target-completer-33 [] { ["CodeCommit_20150413.GetFolder"] }
def x-amz-target-completer-34 [] { ["CodeCommit_20150413.GetMergeCommit"] }
def x-amz-target-completer-35 [] { ["CodeCommit_20150413.GetMergeConflicts"] }
def x-amz-target-completer-36 [] { ["CodeCommit_20150413.GetMergeOptions"] }
def x-amz-target-completer-37 [] { ["CodeCommit_20150413.GetPullRequest"] }
def x-amz-target-completer-38 [] { ["CodeCommit_20150413.GetPullRequestApprovalStates"] }
def x-amz-target-completer-39 [] { ["CodeCommit_20150413.GetPullRequestOverrideState"] }
def x-amz-target-completer-40 [] { ["CodeCommit_20150413.GetRepository"] }
def x-amz-target-completer-41 [] { ["CodeCommit_20150413.GetRepositoryTriggers"] }
def x-amz-target-completer-42 [] { ["CodeCommit_20150413.ListApprovalRuleTemplates"] }
def x-amz-target-completer-43 [] { ["CodeCommit_20150413.ListAssociatedApprovalRuleTemplatesForRepository"] }
def x-amz-target-completer-44 [] { ["CodeCommit_20150413.ListBranches"] }
def pull-request-status-completer [] { ["CLOSED" "OPEN"] }
def x-amz-target-completer-45 [] { ["CodeCommit_20150413.ListPullRequests"] }
def sort-by-completer [] { ["lastModifiedDate" "repositoryName"] }
def order-completer [] { ["ascending" "descending"] }
def x-amz-target-completer-46 [] { ["CodeCommit_20150413.ListRepositories"] }
def x-amz-target-completer-47 [] { ["CodeCommit_20150413.ListRepositoriesForApprovalRuleTemplate"] }
def x-amz-target-completer-48 [] { ["CodeCommit_20150413.ListTagsForResource"] }
def x-amz-target-completer-49 [] { ["CodeCommit_20150413.MergeBranchesByFastForward"] }
def x-amz-target-completer-50 [] { ["CodeCommit_20150413.MergeBranchesBySquash"] }
def x-amz-target-completer-51 [] { ["CodeCommit_20150413.MergeBranchesByThreeWay"] }
def x-amz-target-completer-52 [] { ["CodeCommit_20150413.MergePullRequestByFastForward"] }
def x-amz-target-completer-53 [] { ["CodeCommit_20150413.MergePullRequestBySquash"] }
def x-amz-target-completer-54 [] { ["CodeCommit_20150413.MergePullRequestByThreeWay"] }
def override-status-completer [] { ["OVERRIDE" "REVOKE"] }
def x-amz-target-completer-55 [] { ["CodeCommit_20150413.OverridePullRequestApprovalRules"] }
def x-amz-target-completer-56 [] { ["CodeCommit_20150413.PostCommentForComparedCommit"] }
def x-amz-target-completer-57 [] { ["CodeCommit_20150413.PostCommentForPullRequest"] }
def x-amz-target-completer-58 [] { ["CodeCommit_20150413.PostCommentReply"] }
def x-amz-target-completer-59 [] { ["CodeCommit_20150413.PutCommentReaction"] }
def file-mode-completer [] { ["EXECUTABLE" "NORMAL" "SYMLINK"] }
def x-amz-target-completer-60 [] { ["CodeCommit_20150413.PutFile"] }
def x-amz-target-completer-61 [] { ["CodeCommit_20150413.PutRepositoryTriggers"] }
def x-amz-target-completer-62 [] { ["CodeCommit_20150413.TagResource"] }
def x-amz-target-completer-63 [] { ["CodeCommit_20150413.TestRepositoryTriggers"] }
def x-amz-target-completer-64 [] { ["CodeCommit_20150413.UntagResource"] }
def x-amz-target-completer-65 [] { ["CodeCommit_20150413.UpdateApprovalRuleTemplateContent"] }
def x-amz-target-completer-66 [] { ["CodeCommit_20150413.UpdateApprovalRuleTemplateDescription"] }
def x-amz-target-completer-67 [] { ["CodeCommit_20150413.UpdateApprovalRuleTemplateName"] }
def x-amz-target-completer-68 [] { ["CodeCommit_20150413.UpdateComment"] }
def x-amz-target-completer-69 [] { ["CodeCommit_20150413.UpdateDefaultBranch"] }
def x-amz-target-completer-70 [] { ["CodeCommit_20150413.UpdatePullRequestApprovalRuleContent"] }
def approval-state-completer [] { ["APPROVE" "REVOKE"] }
def x-amz-target-completer-71 [] { ["CodeCommit_20150413.UpdatePullRequestApprovalState"] }
def x-amz-target-completer-72 [] { ["CodeCommit_20150413.UpdatePullRequestDescription"] }
def x-amz-target-completer-73 [] { ["CodeCommit_20150413.UpdatePullRequestStatus"] }
def x-amz-target-completer-74 [] { ["CodeCommit_20150413.UpdatePullRequestTitle"] }
def x-amz-target-completer-75 [] { ["CodeCommit_20150413.UpdateRepositoryDescription"] }
def x-amz-target-completer-76 [] { ["CodeCommit_20150413.UpdateRepositoryName"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    batch-associate-approval-rule-template-with-repositories: "record<associatedRepositoryNames: list<string>, errors: table<repositoryName: string, errorCode: string, errorMessage: string>>"
    batch-describe-merge-conflicts: "record<conflicts: table<conflictMetadata: record, mergeHunks: list>, nextToken: string, errors: table<filePath: string, exceptionName: string, message: string>, destinationCommitId: string, sourceCommitId: string, baseCommitId: string>"
    batch-disassociate-approval-rule-template-from-repositories: "record<disassociatedRepositoryNames: list<string>, errors: table<repositoryName: string, errorCode: string, errorMessage: string>>"
    batch-get-commits: "record<commits: table<commitId: string, treeId: string, parents: list, message: string, author: record, committer: record, additionalData: string>, errors: table<commitId: string, errorCode: string, errorMessage: string>>"
    batch-get-repositories: "record<repositories: table<accountId: string, repositoryId: string, repositoryName: string, repositoryDescription: string, defaultBranch: string, lastModifiedDate: string, creationDate: string, cloneUrlHttp: string, cloneUrlSsh: string, Arn: string>, repositoriesNotFound: list<string>>"
    create-approval-rule-template: "record<approvalRuleTemplate: record<approvalRuleTemplateId: string, approvalRuleTemplateName: string, approvalRuleTemplateDescription: string, approvalRuleTemplateContent: string, ruleContentSha256: string, lastModifiedDate: string, creationDate: string, lastModifiedUser: string>>"
    create-commit: "record<commitId: string, treeId: string, filesAdded: table<absolutePath: string, blobId: string, fileMode: string>, filesUpdated: table<absolutePath: string, blobId: string, fileMode: string>, filesDeleted: table<absolutePath: string, blobId: string, fileMode: string>>"
    create-pull-request: "record<pullRequest: record<pullRequestId: string, title: string, description: string, lastActivityDate: string, creationDate: string, pullRequestStatus: string, authorArn: string, pullRequestTargets: list<record>, clientRequestToken: string, revisionId: string, approvalRules: list<record>>>"
    create-pull-request-approval-rule: "record<approvalRule: record<approvalRuleId: string, approvalRuleName: string, approvalRuleContent: string, ruleContentSha256: string, lastModifiedDate: string, creationDate: string, lastModifiedUser: string, originApprovalRuleTemplate: record<approvalRuleTemplateId: string, approvalRuleTemplateName: string>>>"
    create-repository: "record<repositoryMetadata: record<accountId: string, repositoryId: string, repositoryName: string, repositoryDescription: string, defaultBranch: string, lastModifiedDate: string, creationDate: string, cloneUrlHttp: string, cloneUrlSsh: string, Arn: string>>"
    create-unreferenced-merge-commit: "record<commitId: string, treeId: string>"
    delete-approval-rule-template: "record<approvalRuleTemplateId: string>"
    delete-branch: "record<deletedBranch: record<branchName: string, commitId: string>>"
    delete-comment-content: "record<comment: record<commentId: string, content: string, inReplyTo: string, creationDate: string, lastModifiedDate: string, authorArn: string, deleted: bool, clientRequestToken: string, callerReactions: list<string>, reactionCounts: record>>"
    delete-file: "record<commitId: string, blobId: string, treeId: string, filePath: string>"
    delete-pull-request-approval-rule: "record<approvalRuleId: string>"
    delete-repository: "record<repositoryId: string>"
    describe-merge-conflicts: "record<conflictMetadata: record<filePath: string, fileSizes: record<source: int, destination: int, base: int>, fileModes: record<source: string, destination: string, base: string>, objectTypes: record<source: string, destination: string, base: string>, numberOfConflicts: int, isBinaryFile: record<source: bool, destination: bool, base: bool>, contentConflict: bool, fileModeConflict: bool, objectTypeConflict: bool, mergeOperations: record<source: string, destination: string>>, mergeHunks: table<isConflict: bool, source: record, destination: record, base: record>, nextToken: string, destinationCommitId: string, sourceCommitId: string, baseCommitId: string>"
    describe-pull-request-events: "record<pullRequestEvents: table<pullRequestId: string, eventDate: string, pullRequestEventType: string, actorArn: string, pullRequestCreatedEventMetadata: record, pullRequestStatusChangedEventMetadata: record, pullRequestSourceReferenceUpdatedEventMetadata: record, pullRequestMergedStateChangedEventMetadata: record, approvalRuleEventMetadata: record, approvalStateChangedEventMetadata: record, approvalRuleOverriddenEventMetadata: record>, nextToken: string>"
    evaluate-pull-request-approval-rules: "record<evaluation: record<approved: bool, overridden: bool, approvalRulesSatisfied: list<string>, approvalRulesNotSatisfied: list<string>>>"
    get-approval-rule-template: "record<approvalRuleTemplate: record<approvalRuleTemplateId: string, approvalRuleTemplateName: string, approvalRuleTemplateDescription: string, approvalRuleTemplateContent: string, ruleContentSha256: string, lastModifiedDate: string, creationDate: string, lastModifiedUser: string>>"
    get-blob: "record<content: string>"
    get-branch: "record<branch: record<branchName: string, commitId: string>>"
    get-comment: "record<comment: record<commentId: string, content: string, inReplyTo: string, creationDate: string, lastModifiedDate: string, authorArn: string, deleted: bool, clientRequestToken: string, callerReactions: list<string>, reactionCounts: record>>"
    get-comment-reactions: "record<reactionsForComment: table<reaction: record, reactionUsers: list, reactionsFromDeletedUsersCount: int>, nextToken: string>"
    get-comments-for-compared-commit: "record<commentsForComparedCommitData: table<repositoryName: string, beforeCommitId: string, afterCommitId: string, beforeBlobId: string, afterBlobId: string, location: record, comments: list>, nextToken: string>"
    get-comments-for-pull-request: "record<commentsForPullRequestData: table<pullRequestId: string, repositoryName: string, beforeCommitId: string, afterCommitId: string, beforeBlobId: string, afterBlobId: string, location: record, comments: list>, nextToken: string>"
    get-commit: "record<commit: record<commitId: string, treeId: string, parents: list<string>, message: string, author: record<name: string, email: string, date: string>, committer: record<name: string, email: string, date: string>, additionalData: string>>"
    get-differences: "record<differences: table<beforeBlob: record, afterBlob: record, changeType: string>, NextToken: string>"
    get-file: "record<commitId: string, blobId: string, filePath: string, fileMode: string, fileSize: int, fileContent: string>"
    get-folder: "record<commitId: string, folderPath: string, treeId: string, subFolders: table<treeId: string, absolutePath: string, relativePath: string>, files: table<blobId: string, absolutePath: string, relativePath: string, fileMode: string>, symbolicLinks: table<blobId: string, absolutePath: string, relativePath: string, fileMode: string>, subModules: table<commitId: string, absolutePath: string, relativePath: string>>"
    get-merge-commit: "record<sourceCommitId: string, destinationCommitId: string, baseCommitId: string, mergedCommitId: string>"
    get-merge-conflicts: "record<mergeable: bool, destinationCommitId: string, sourceCommitId: string, baseCommitId: string, conflictMetadataList: table<filePath: string, fileSizes: record, fileModes: record, objectTypes: record, numberOfConflicts: int, isBinaryFile: record, contentConflict: bool, fileModeConflict: bool, objectTypeConflict: bool, mergeOperations: record>, nextToken: string>"
    get-merge-options: "record<mergeOptions: list<string>, sourceCommitId: string, destinationCommitId: string, baseCommitId: string>"
    get-pull-request: "record<pullRequest: record<pullRequestId: string, title: string, description: string, lastActivityDate: string, creationDate: string, pullRequestStatus: string, authorArn: string, pullRequestTargets: list<record>, clientRequestToken: string, revisionId: string, approvalRules: list<record>>>"
    get-pull-request-approval-states: "record<approvals: table<userArn: string, approvalState: string>>"
    get-pull-request-override-state: "record<overridden: bool, overrider: string>"
    get-repository: "record<repositoryMetadata: record<accountId: string, repositoryId: string, repositoryName: string, repositoryDescription: string, defaultBranch: string, lastModifiedDate: string, creationDate: string, cloneUrlHttp: string, cloneUrlSsh: string, Arn: string>>"
    get-repository-triggers: "record<configurationId: string, triggers: table<name: string, destinationArn: string, customData: string, branches: list, events: list>>"
    list-approval-rule-templates: "record<approvalRuleTemplateNames: list<string>, nextToken: string>"
    list-associated-approval-rule-templates-for-repository: "record<approvalRuleTemplateNames: list<string>, nextToken: string>"
    list-branches: "record<branches: list<string>, nextToken: string>"
    list-pull-requests: "record<pullRequestIds: list<string>, nextToken: string>"
    list-repositories: "record<repositories: table<repositoryName: string, repositoryId: string>, nextToken: string>"
    list-repositories-for-approval-rule-template: "record<repositoryNames: list<string>, nextToken: string>"
    list-tags-for-resource: "record<tags: record, nextToken: string>"
    merge-branches-by-fast-forward: "record<commitId: string, treeId: string>"
    merge-branches-by-squash: "record<commitId: string, treeId: string>"
    merge-branches-by-three-way: "record<commitId: string, treeId: string>"
    merge-pull-request-by-fast-forward: "record<pullRequest: record<pullRequestId: string, title: string, description: string, lastActivityDate: string, creationDate: string, pullRequestStatus: string, authorArn: string, pullRequestTargets: list<record>, clientRequestToken: string, revisionId: string, approvalRules: list<record>>>"
    merge-pull-request-by-squash: "record<pullRequest: record<pullRequestId: string, title: string, description: string, lastActivityDate: string, creationDate: string, pullRequestStatus: string, authorArn: string, pullRequestTargets: list<record>, clientRequestToken: string, revisionId: string, approvalRules: list<record>>>"
    merge-pull-request-by-three-way: "record<pullRequest: record<pullRequestId: string, title: string, description: string, lastActivityDate: string, creationDate: string, pullRequestStatus: string, authorArn: string, pullRequestTargets: list<record>, clientRequestToken: string, revisionId: string, approvalRules: list<record>>>"
    post-comment-for-compared-commit: "record<repositoryName: string, beforeCommitId: string, afterCommitId: string, beforeBlobId: string, afterBlobId: string, location: record<filePath: string, filePosition: int, relativeFileVersion: string>, comment: record<commentId: string, content: string, inReplyTo: string, creationDate: string, lastModifiedDate: string, authorArn: string, deleted: bool, clientRequestToken: string, callerReactions: list<string>, reactionCounts: record>>"
    post-comment-for-pull-request: "record<repositoryName: string, pullRequestId: string, beforeCommitId: string, afterCommitId: string, beforeBlobId: string, afterBlobId: string, location: record<filePath: string, filePosition: int, relativeFileVersion: string>, comment: record<commentId: string, content: string, inReplyTo: string, creationDate: string, lastModifiedDate: string, authorArn: string, deleted: bool, clientRequestToken: string, callerReactions: list<string>, reactionCounts: record>>"
    post-comment-reply: "record<comment: record<commentId: string, content: string, inReplyTo: string, creationDate: string, lastModifiedDate: string, authorArn: string, deleted: bool, clientRequestToken: string, callerReactions: list<string>, reactionCounts: record>>"
    put-file: "record<commitId: string, blobId: string, treeId: string>"
    put-repository-triggers: "record<configurationId: string>"
    test-repository-triggers: "record<successfulExecutions: list<string>, failedExecutions: table<trigger: string, failureMessage: string>>"
    update-approval-rule-template-content: "record<approvalRuleTemplate: record<approvalRuleTemplateId: string, approvalRuleTemplateName: string, approvalRuleTemplateDescription: string, approvalRuleTemplateContent: string, ruleContentSha256: string, lastModifiedDate: string, creationDate: string, lastModifiedUser: string>>"
    update-approval-rule-template-description: "record<approvalRuleTemplate: record<approvalRuleTemplateId: string, approvalRuleTemplateName: string, approvalRuleTemplateDescription: string, approvalRuleTemplateContent: string, ruleContentSha256: string, lastModifiedDate: string, creationDate: string, lastModifiedUser: string>>"
    update-approval-rule-template-name: "record<approvalRuleTemplate: record<approvalRuleTemplateId: string, approvalRuleTemplateName: string, approvalRuleTemplateDescription: string, approvalRuleTemplateContent: string, ruleContentSha256: string, lastModifiedDate: string, creationDate: string, lastModifiedUser: string>>"
    update-comment: "record<comment: record<commentId: string, content: string, inReplyTo: string, creationDate: string, lastModifiedDate: string, authorArn: string, deleted: bool, clientRequestToken: string, callerReactions: list<string>, reactionCounts: record>>"
    update-pull-request-approval-rule-content: "record<approvalRule: record<approvalRuleId: string, approvalRuleName: string, approvalRuleContent: string, ruleContentSha256: string, lastModifiedDate: string, creationDate: string, lastModifiedUser: string, originApprovalRuleTemplate: record<approvalRuleTemplateId: string, approvalRuleTemplateName: string>>>"
    update-pull-request-description: "record<pullRequest: record<pullRequestId: string, title: string, description: string, lastActivityDate: string, creationDate: string, pullRequestStatus: string, authorArn: string, pullRequestTargets: list<record>, clientRequestToken: string, revisionId: string, approvalRules: list<record>>>"
    update-pull-request-status: "record<pullRequest: record<pullRequestId: string, title: string, description: string, lastActivityDate: string, creationDate: string, pullRequestStatus: string, authorArn: string, pullRequestTargets: list<record>, clientRequestToken: string, revisionId: string, approvalRules: list<record>>>"
    update-pull-request-title: "record<pullRequest: record<pullRequestId: string, title: string, description: string, lastActivityDate: string, creationDate: string, pullRequestStatus: string, authorArn: string, pullRequestTargets: list<record>, clientRequestToken: string, revisionId: string, approvalRules: list<record>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["associate-approval-rule-template-with-repository" "batch-associate-approval-rule-template-with-repositories" "batch-describe-merge-conflicts" "batch-disassociate-approval-rule-template-from-repositories" "batch-get-commits" "batch-get-repositories" "create-approval-rule-template" "create-branch" "create-commit" "create-pull-request" "create-pull-request-approval-rule" "create-repository" "create-unreferenced-merge-commit" "delete-approval-rule-template" "delete-branch" "delete-comment-content" "delete-file" "delete-pull-request-approval-rule" "delete-repository" "describe-merge-conflicts" "describe-pull-request-events" "disassociate-approval-rule-template-from-repository" "evaluate-pull-request-approval-rules" "get-approval-rule-template" "get-blob" "get-branch" "get-comment" "get-comment-reactions" "get-comments-for-compared-commit" "get-comments-for-pull-request" "get-commit" "get-differences" "get-file" "get-folder" "get-merge-commit" "get-merge-conflicts" "get-merge-options" "get-pull-request" "get-pull-request-approval-states" "get-pull-request-override-state" "get-repository" "get-repository-triggers" "list-approval-rule-templates" "list-associated-approval-rule-templates-for-repository" "list-branches" "list-pull-requests" "list-repositories" "list-repositories-for-approval-rule-template" "list-tags-for-resource" "merge-branches-by-fast-forward" "merge-branches-by-squash" "merge-branches-by-three-way" "merge-pull-request-by-fast-forward" "merge-pull-request-by-squash" "merge-pull-request-by-three-way" "override-pull-request-approval-rules" "post-comment-for-compared-commit" "post-comment-for-pull-request" "post-comment-reply" "put-comment-reaction" "put-file" "put-repository-triggers" "tag-resource" "test-repository-triggers" "untag-resource" "update-approval-rule-template-content" "update-approval-rule-template-description" "update-approval-rule-template-name" "update-comment" "update-default-branch" "update-pull-request-approval-rule-content" "update-pull-request-approval-state" "update-pull-request-description" "update-pull-request-status" "update-pull-request-title" "update-repository-description" "update-repository-name" "commands"] | sort) } | get name | first)
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

# Creates an association between an approval rule template and a specified repository. Then, the next time a pull request is created in the repository where the destination reference (if specified) matches the destination reference (branch) for the pull request, an approval rule that matches the template conditions is automatically created for that pull request. If no destination references are specified in the template, an approval rule that matches the template contents is created for all pull requests in that repository.
#
# POST /
# operationId: AssociateApprovalRuleTemplateWithRepository
export def "associate-approval-rule-template-with-repository" [
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
  approval_rule_template_name: string # The name for the approval rule template.
  repository_name: string # The name of the repository that you want to associate with the template.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.AssociateApprovalRuleTemplateWithRepository"}]
    body: {content_type: "application/json", kind: json, fields: [{name: approvalRuleTemplateName, var: approval_rule_template_name}, {name: repositoryName, var: repository_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, approval_rule_template_name: $approval_rule_template_name, repository_name: $repository_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an association between an approval rule template and one or more specified repositories.
#
# POST /
# Returns: record<associatedRepositoryNames: list<string>, errors: table<repositoryName: string, errorCode: string, errorMessage: string>>
# operationId: BatchAssociateApprovalRuleTemplateWithRepositories
export def "batch-associate-approval-rule-template-with-repositories" [
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
  approval_rule_template_name: string # The name of the template you want to associate with one or more repositories.
  repository_names: list<string> # The names of the repositories you want to associate with the template. The length constraint limit is for each string in the array. The array itself can be empty.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.BatchAssociateApprovalRuleTemplateWithRepositories"}]
    body: {content_type: "application/json", kind: json, fields: [{name: approvalRuleTemplateName, var: approval_rule_template_name}, {name: repositoryNames, var: repository_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, approval_rule_template_name: $approval_rule_template_name, repository_names: $repository_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
#
# POST /
# Returns: record<conflicts: table<conflictMetadata: record, mergeHunks: list>, nextToken: string, errors: table<filePath: string, exceptionName: string, message: string>, destinationCommitId: string, sourceCommitId: string, baseCommitId: string>
# operationId: BatchDescribeMergeConflicts
export def "batch-describe-merge-conflicts" [
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
  repository_name: string # The name of the repository that contains the merge conflicts you want to review.
  destination_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  source_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  merge_option: string@merge-option-completer # The merge option or strategy you want to use to merge the code.
  --max-merge-hunks: int # The maximum number of merge hunks to include in the output.
  --max-conflict-files: int # The maximum number of files to include in the output.
  --file-paths: list<string> # The path of the target files used to describe the conflicts. If not specified, the default is all conflict files.
  --conflict-detail-level: string@conflict-detail-level-completer # The level of conflict detail to use. If unspecified, the default FILE_LEVEL is used, which returns a not-mergeable result if the same file has differences in both branches. If LINE_LEVEL is specified, a conflict is considered not mergeable if the same file in both branches has differences on the same line.
  --conflict-resolution-strategy: string@conflict-resolution-strategy-completer # Specifies which branch to use when resolving conflicts, or whether to attempt automatically merging two versions of a file. The default is NONE, which requires any conflicts to be resolved manually before the merge operation is successful.
  --next-token: string # An enumeration token that, when provided in a request, returns the next batch of the results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.BatchDescribeMergeConflicts"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: destinationCommitSpecifier, var: destination_commit_specifier}, {name: sourceCommitSpecifier, var: source_commit_specifier}, {name: mergeOption, var: merge_option}, {name: maxMergeHunks, var: max_merge_hunks}, {name: maxConflictFiles, var: max_conflict_files}, {name: filePaths, var: file_paths}, {name: conflictDetailLevel, var: conflict_detail_level}, {name: conflictResolutionStrategy, var: conflict_resolution_strategy}, {name: nextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, destination_commit_specifier: $destination_commit_specifier, source_commit_specifier: $source_commit_specifier, merge_option: $merge_option, max_merge_hunks: $max_merge_hunks, max_conflict_files: $max_conflict_files, file_paths: $file_paths, conflict_detail_level: $conflict_detail_level, conflict_resolution_strategy: $conflict_resolution_strategy, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the association between an approval rule template and one or more specified repositories.
#
# POST /
# Returns: record<disassociatedRepositoryNames: list<string>, errors: table<repositoryName: string, errorCode: string, errorMessage: string>>
# operationId: BatchDisassociateApprovalRuleTemplateFromRepositories
export def "batch-disassociate-approval-rule-template-from-repositories" [
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
  approval_rule_template_name: string # The name of the template that you want to disassociate from one or more repositories.
  repository_names: list<string> # The repository names that you want to disassociate from the approval rule template. The length constraint limit is for each string in the array. The array itself can be empty.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.BatchDisassociateApprovalRuleTemplateFromRepositories"}]
    body: {content_type: "application/json", kind: json, fields: [{name: approvalRuleTemplateName, var: approval_rule_template_name}, {name: repositoryNames, var: repository_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, approval_rule_template_name: $approval_rule_template_name, repository_names: $repository_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the contents of one or more commits in a repository.
#
# POST /
# Returns: record<commits: table<commitId: string, treeId: string, parents: list, message: string, author: record, committer: record, additionalData: string>, errors: table<commitId: string, errorCode: string, errorMessage: string>>
# operationId: BatchGetCommits
export def "batch-get-commits" [
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
  commit_ids: list<string> # The full commit IDs of the commits to get information about. You must supply the full SHA IDs of each commit. You cannot use shortened SHA IDs.
  repository_name: string # The name of the repository that contains the commits.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.BatchGetCommits"}]
    body: {content_type: "application/json", kind: json, fields: [{name: commitIds, var: commit_ids}, {name: repositoryName, var: repository_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, commit_ids: $commit_ids, repository_name: $repository_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about one or more repositories. The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.
#
# POST /
# Returns: record<repositories: table<accountId: string, repositoryId: string, repositoryName: string, repositoryDescription: string, defaultBranch: string, lastModifiedDate: string, creationDate: string, cloneUrlHttp: string, cloneUrlSsh: string, Arn: string>, repositoriesNotFound: list<string>>
# operationId: BatchGetRepositories
export def "batch-get-repositories" [
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
  repository_names: list<string> # The names of the repositories to get information about. The length constraint limit is for each string in the array. The array itself can be empty.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.BatchGetRepositories"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryNames, var: repository_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_names: $repository_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a template for approval rules that can then be associated with one or more repositories in your AWS account. When you associate a template with a repository, AWS CodeCommit creates an approval rule that matches the conditions of the template for all pull requests that meet the conditions of the template. For more information, see AssociateApprovalRuleTemplateWithRepository.
#
# POST /
# Returns: record<approvalRuleTemplate: record<approvalRuleTemplateId: string, approvalRuleTemplateName: string, approvalRuleTemplateDescription: string, approvalRuleTemplateContent: string, ruleContentSha256: string, lastModifiedDate: string, creationDate: string, lastModifiedUser: string>>
# operationId: CreateApprovalRuleTemplate
export def "create-approval-rule-template" [
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
  approval_rule_template_name: string # The name of the approval rule template. Provide descriptive names, because this name is applied to the approval rules created automatically in associated repositories.
  approval_rule_template_content: string # The content of the approval rule that is created on pull requests in associated repositories. If you specify one or more destination references (branches), approval rules are created in an associated repository only if their destination references (branches) match those specified in the template. When you create the content of the approval rule template, you can specify approvers in an approval pool in one of two ways: CodeCommitApprovers: This option only requires an AWS account and a resource. It can be used for both IAM users and federated access users whose name matches the provided resource name. This is a very powerful option that offers a great deal of flexibility. For example, if you specify the AWS account 123456789012 and Mary_Major, all of the following are counted as approvals coming from that user: An IAM user in the account (arn:aws:iam::123456789012:user/Mary_Major) A federated user identified in IAM as Mary_Major (arn:aws:sts::123456789012:federated-user/Mary_Major) This option does not recognize an active session of someone assuming the role of CodeCommitReview with a role session name of Mary_Major (arn:aws:sts::123456789012:assumed-role/CodeCommitReview/Mary_Major) unless you include a wildcard (*Mary_Major). Fully qualified ARN: This option allows you to specify the fully qualified Amazon Resource Name (ARN) of the IAM user or role. For more information about IAM ARNs, wildcards, and formats, see IAM Identifiers (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html) in the IAM User Guide.
  --approval-rule-template-description: string # The description of the approval rule template. Consider providing a description that explains what this template does and when it might be appropriate to associate it with repositories.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.CreateApprovalRuleTemplate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: approvalRuleTemplateName, var: approval_rule_template_name}, {name: approvalRuleTemplateContent, var: approval_rule_template_content}, {name: approvalRuleTemplateDescription, var: approval_rule_template_description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, approval_rule_template_name: $approval_rule_template_name, approval_rule_template_content: $approval_rule_template_content, approval_rule_template_description: $approval_rule_template_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a branch in a repository and points the branch to a commit. Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.
#
# POST /
# operationId: CreateBranch
export def "create-branch" [
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
  repository_name: string # The name of the repository in which you want to create the new branch.
  branch_name: string # The name of the new branch to create.
  commit_id: string # The ID of the commit to point the new branch to.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.CreateBranch"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: branchName, var: branch_name}, {name: commitId, var: commit_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, branch_name: $branch_name, commit_id: $commit_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a commit for a repository on the tip of a specified branch.
#
# POST /
# Returns: record<commitId: string, treeId: string, filesAdded: table<absolutePath: string, blobId: string, fileMode: string>, filesUpdated: table<absolutePath: string, blobId: string, fileMode: string>, filesDeleted: table<absolutePath: string, blobId: string, fileMode: string>>
# operationId: CreateCommit
export def "create-commit" [
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
  repository_name: string # The name of the repository where you create the commit.
  branch_name: string # The name of the branch where you create the commit.
  --parent-commit-id: string # The ID of the commit that is the parent of the commit you create. Not required if this is an empty repository.
  --author-name: string # The name of the author who created the commit. This information is used as both the author and committer for the commit.
  --email: string # The email address of the person who created the commit.
  --commit-message: string # The commit message you want to include in the commit. Commit messages are limited to 256 KB. If no message is specified, a default message is used.
  --keep-empty-folders: oneof<nothing, bool> # If the commit contains deletions, whether to keep a folder or folder structure if the changes leave the folders empty. If true, a ..gitkeep file is created for empty folders. The default is false.
  --put-files: list # The files to add or update in this commit. — item shape: {filePath: string, fileMode?: "EXECUTABLE"|"NORMAL"|"SYMLINK", fileContent?: string, sourceFile?: record}
  --delete-files: list # The files to delete in this commit. These files still exist in earlier commits. — item shape: {filePath: string}
  --set-file-modes: list # The file modes to update for files in this commit. — item shape: {filePath: string, fileMode: "EXECUTABLE"|"NORMAL"|"SYMLINK"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.CreateCommit"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: branchName, var: branch_name}, {name: parentCommitId, var: parent_commit_id}, {name: authorName, var: author_name}, {name: email, var: email}, {name: commitMessage, var: commit_message}, {name: keepEmptyFolders, var: keep_empty_folders}, {name: putFiles, var: put_files}, {name: deleteFiles, var: delete_files}, {name: setFileModes, var: set_file_modes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, branch_name: $branch_name, parent_commit_id: $parent_commit_id, author_name: $author_name, email: $email, commit_message: $commit_message, keep_empty_folders: $keep_empty_folders, put_files: $put_files, delete_files: $delete_files, set_file_modes: $set_file_modes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a pull request in the specified repository.
#
# POST /
# Returns: record<pullRequest: record<pullRequestId: string, title: string, description: string, lastActivityDate: string, creationDate: string, pullRequestStatus: string, authorArn: string, pullRequestTargets: list<record>, clientRequestToken: string, revisionId: string, approvalRules: list<record>>>
# operationId: CreatePullRequest
export def "create-pull-request" [
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
  title: string # The title of the pull request. This title is used to identify the pull request to other users in the repository.
  --description: string # A description of the pull request.
  targets: list # The targets for the pull request, including the source of the code to be reviewed (the source branch) and the destination where the creator of the pull request intends the code to be merged after the pull request is closed (the destination branch). — item shape: {repositoryName: string, sourceReference: string, destinationReference?: string}
  --client-request-token: string # A unique, client-generated idempotency token that, when provided in a request, ensures the request cannot be repeated with a changed parameter. If a request is received with the same parameters and a token is included, the request returns information about the initial request that used that token. The AWS SDKs prepopulate client request tokens. If you are using an AWS SDK, an idempotency token is created for you.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.CreatePullRequest"}]
    body: {content_type: "application/json", kind: json, fields: [{name: title, var: title}, {name: description, var: description}, {name: targets, var: targets}, {name: clientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, title: $title, description: $description, targets: $targets, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an approval rule for a pull request.
#
# POST /
# Returns: record<approvalRule: record<approvalRuleId: string, approvalRuleName: string, approvalRuleContent: string, ruleContentSha256: string, lastModifiedDate: string, creationDate: string, lastModifiedUser: string, originApprovalRuleTemplate: record<approvalRuleTemplateId: string, approvalRuleTemplateName: string>>>
# operationId: CreatePullRequestApprovalRule
export def "create-pull-request-approval-rule" [
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
  pull_request_id: string # The system-generated ID of the pull request for which you want to create the approval rule.
  approval_rule_name: string # The name for the approval rule.
  approval_rule_content: string # The content of the approval rule, including the number of approvals needed and the structure of an approval pool defined for approvals, if any. For more information about approval pools, see the AWS CodeCommit User Guide. When you create the content of the approval rule, you can specify approvers in an approval pool in one of two ways: CodeCommitApprovers: This option only requires an AWS account and a resource. It can be used for both IAM users and federated access users whose name matches the provided resource name. This is a very powerful option that offers a great deal of flexibility. For example, if you specify the AWS account 123456789012 and Mary_Major, all of the following would be counted as approvals coming from that user: An IAM user in the account (arn:aws:iam::123456789012:user/Mary_Major) A federated user identified in IAM as Mary_Major (arn:aws:sts::123456789012:federated-user/Mary_Major) This option does not recognize an active session of someone assuming the role of CodeCommitReview with a role session name of Mary_Major (arn:aws:sts::123456789012:assumed-role/CodeCommitReview/Mary_Major) unless you include a wildcard (*Mary_Major). Fully qualified ARN: This option allows you to specify the fully qualified Amazon Resource Name (ARN) of the IAM user or role. For more information about IAM ARNs, wildcards, and formats, see IAM Identifiers (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html) in the IAM User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.CreatePullRequestApprovalRule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}, {name: approvalRuleName, var: approval_rule_name}, {name: approvalRuleContent, var: approval_rule_content}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id, approval_rule_name: $approval_rule_name, approval_rule_content: $approval_rule_content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new, empty repository.
#
# POST /
# Returns: record<repositoryMetadata: record<accountId: string, repositoryId: string, repositoryName: string, repositoryDescription: string, defaultBranch: string, lastModifiedDate: string, creationDate: string, cloneUrlHttp: string, cloneUrlSsh: string, Arn: string>>
# operationId: CreateRepository
export def "create-repository" [
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
  repository_name: string # The name of the new repository to be created. The repository name must be unique across the calling AWS account. Repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. For more information about the limits on repository names, see Limits (https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html) in the AWS CodeCommit User Guide. The suffix .git is prohibited.
  --repository-description: string # A comment or description about the new repository. The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.
  --tags: record # One or more tag key-value pairs to use when tagging this repository.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.CreateRepository"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: repositoryDescription, var: repository_description}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, repository_description: $repository_description, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy because that strategy does not create a merge commit. This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.
#
# POST /
# Returns: record<commitId: string, treeId: string>
# operationId: CreateUnreferencedMergeCommit
export def "create-unreferenced-merge-commit" [
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
  repository_name: string # The name of the repository where you want to create the unreferenced merge commit.
  source_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  destination_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  merge_option: string@merge-option-completer # The merge option or strategy you want to use to merge the code.
  --conflict-detail-level: string@conflict-detail-level-completer # The level of conflict detail to use. If unspecified, the default FILE_LEVEL is used, which returns a not-mergeable result if the same file has differences in both branches. If LINE_LEVEL is specified, a conflict is considered not mergeable if the same file in both branches has differences on the same line.
  --conflict-resolution-strategy: string@conflict-resolution-strategy-completer # Specifies which branch to use when resolving conflicts, or whether to attempt automatically merging two versions of a file. The default is NONE, which requires any conflicts to be resolved manually before the merge operation is successful.
  --author-name: string # The name of the author who created the unreferenced commit. This information is used as both the author and committer for the commit.
  --email: string # The email address for the person who created the unreferenced commit.
  --commit-message: string # The commit message for the unreferenced commit.
  --keep-empty-folders: oneof<nothing, bool> # If the commit contains deletions, whether to keep a folder or folder structure if the changes leave the folders empty. If this is specified as true, a .gitkeep file is created for empty folders. The default is false.
  --conflict-resolution: record # If AUTOMERGE is the conflict resolution strategy, a list of inputs to use when resolving conflicts during a merge. — shape: {replaceContents?: list, deleteFiles?: list, setFileModes?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.CreateUnreferencedMergeCommit"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: sourceCommitSpecifier, var: source_commit_specifier}, {name: destinationCommitSpecifier, var: destination_commit_specifier}, {name: mergeOption, var: merge_option}, {name: conflictDetailLevel, var: conflict_detail_level}, {name: conflictResolutionStrategy, var: conflict_resolution_strategy}, {name: authorName, var: author_name}, {name: email, var: email}, {name: commitMessage, var: commit_message}, {name: keepEmptyFolders, var: keep_empty_folders}, {name: conflictResolution, var: conflict_resolution}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, source_commit_specifier: $source_commit_specifier, destination_commit_specifier: $destination_commit_specifier, merge_option: $merge_option, conflict_detail_level: $conflict_detail_level, conflict_resolution_strategy: $conflict_resolution_strategy, author_name: $author_name, email: $email, commit_message: $commit_message, keep_empty_folders: $keep_empty_folders, conflict_resolution: $conflict_resolution
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified approval rule template. Deleting a template does not remove approval rules on pull requests already created with the template.
#
# POST /
# Returns: record<approvalRuleTemplateId: string>
# operationId: DeleteApprovalRuleTemplate
export def "delete-approval-rule-template" [
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
  approval_rule_template_name: string # The name of the approval rule template to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.DeleteApprovalRuleTemplate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: approvalRuleTemplateName, var: approval_rule_template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, approval_rule_template_name: $approval_rule_template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a branch from a repository, unless that branch is the default branch for the repository.
#
# POST /
# Returns: record<deletedBranch: record<branchName: string, commitId: string>>
# operationId: DeleteBranch
export def "delete-branch" [
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
  repository_name: string # The name of the repository that contains the branch to be deleted.
  branch_name: string # The name of the branch to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.DeleteBranch"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: branchName, var: branch_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, branch_name: $branch_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the content of a comment made on a change, file, or commit in a repository.
#
# POST /
# Returns: record<comment: record<commentId: string, content: string, inReplyTo: string, creationDate: string, lastModifiedDate: string, authorArn: string, deleted: bool, clientRequestToken: string, callerReactions: list<string>, reactionCounts: record>>
# operationId: DeleteCommentContent
export def "delete-comment-content" [
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
  comment_id: string # The unique, system-generated ID of the comment. To get this ID, use GetCommentsForComparedCommit or GetCommentsForPullRequest.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.DeleteCommentContent"}]
    body: {content_type: "application/json", kind: json, fields: [{name: commentId, var: comment_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file still exists in the commits earlier to the commit that contains the deletion.
#
# POST /
# Returns: record<commitId: string, blobId: string, treeId: string, filePath: string>
# operationId: DeleteFile
export def "delete-file" [
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
  repository_name: string # The name of the repository that contains the file to delete.
  branch_name: string # The name of the branch where the commit that deletes the file is made.
  file_path: string # The fully qualified path to the file that to be deleted, including the full name and extension of that file. For example, /examples/file.md is a fully qualified path to a file named file.md in a folder named examples.
  parent_commit_id: string # The ID of the commit that is the tip of the branch where you want to create the commit that deletes the file. This must be the HEAD commit for the branch. The commit that deletes the file is created from this commit ID.
  --keep-empty-folders: oneof<nothing, bool> # If a file is the only object in the folder or directory, specifies whether to delete the folder or directory that contains the file. By default, empty folders are deleted. This includes empty folders that are part of the directory structure. For example, if the path to a file is dir1/dir2/dir3/dir4, and dir2 and dir3 are empty, deleting the last file in dir4 also deletes the empty folders dir4, dir3, and dir2.
  --commit-message: string # The commit message you want to include as part of deleting the file. Commit messages are limited to 256 KB. If no message is specified, a default message is used.
  --name: string # The name of the author of the commit that deletes the file. If no name is specified, the user's ARN is used as the author name and committer name.
  --email: string # The email address for the commit that deletes the file. If no email address is specified, the email address is left blank.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.DeleteFile"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: branchName, var: branch_name}, {name: filePath, var: file_path}, {name: parentCommitId, var: parent_commit_id}, {name: keepEmptyFolders, var: keep_empty_folders}, {name: commitMessage, var: commit_message}, {name: name, var: name}, {name: email, var: email}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, branch_name: $branch_name, file_path: $file_path, parent_commit_id: $parent_commit_id, keep_empty_folders: $keep_empty_folders, commit_message: $commit_message, name: $name, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an approval rule from a specified pull request. Approval rules can be deleted from a pull request only if the pull request is open, and if the approval rule was created specifically for a pull request and not generated from an approval rule template associated with the repository where the pull request was created. You cannot delete an approval rule from a merged or closed pull request.
#
# POST /
# Returns: record<approvalRuleId: string>
# operationId: DeletePullRequestApprovalRule
export def "delete-pull-request-approval-rule" [
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
  pull_request_id: string # The system-generated ID of the pull request that contains the approval rule you want to delete.
  approval_rule_name: string # The name of the approval rule you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.DeletePullRequestApprovalRule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}, {name: approvalRuleName, var: approval_rule_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id, approval_rule_name: $approval_rule_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a repository. If a specified repository was already deleted, a null repository ID is returned. Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository fail.
#
# POST /
# Returns: record<repositoryId: string>
# operationId: DeleteRepository
export def "delete-repository" [
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
  repository_name: string # The name of the repository to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.DeleteRepository"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception is thrown.
#
# POST /
# Returns: record<conflictMetadata: record<filePath: string, fileSizes: record<source: int, destination: int, base: int>, fileModes: record<source: string, destination: string, base: string>, objectTypes: record<source: string, destination: string, base: string>, numberOfConflicts: int, isBinaryFile: record<source: bool, destination: bool, base: bool>, contentConflict: bool, fileModeConflict: bool, objectTypeConflict: bool, mergeOperations: record<source: string, destination: string>>, mergeHunks: table<isConflict: bool, source: record, destination: record, base: record>, nextToken: string, destinationCommitId: string, sourceCommitId: string, baseCommitId: string>
# operationId: DescribeMergeConflicts
export def "describe-merge-conflicts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-merge-hunks: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-19 # required
  repository_name: string # The name of the repository where you want to get information about a merge conflict.
  destination_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  source_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  merge_option: string@merge-option-completer # The merge option or strategy you want to use to merge the code.
  --body-max-merge-hunks: int # The maximum number of merge hunks to include in the output. (spec name: maxMergeHunks)
  file_path: string # The path of the target files used to describe the conflicts.
  --conflict-detail-level: string@conflict-detail-level-completer # The level of conflict detail to use. If unspecified, the default FILE_LEVEL is used, which returns a not-mergeable result if the same file has differences in both branches. If LINE_LEVEL is specified, a conflict is considered not mergeable if the same file in both branches has differences on the same line.
  --conflict-resolution-strategy: string@conflict-resolution-strategy-completer # Specifies which branch to use when resolving conflicts, or whether to attempt automatically merging two versions of a file. The default is NONE, which requires any conflicts to be resolved manually before the merge operation is successful.
  --body-next-token: string # An enumeration token that, when provided in a request, returns the next batch of the results. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxMergeHunks, var: max_merge_hunks}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.DescribeMergeConflicts"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: destinationCommitSpecifier, var: destination_commit_specifier}, {name: sourceCommitSpecifier, var: source_commit_specifier}, {name: mergeOption, var: merge_option}, {name: maxMergeHunks, var: body_max_merge_hunks}, {name: filePath, var: file_path}, {name: conflictDetailLevel, var: conflict_detail_level}, {name: conflictResolutionStrategy, var: conflict_resolution_strategy}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_merge_hunks: $max_merge_hunks, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, destination_commit_specifier: $destination_commit_specifier, source_commit_specifier: $source_commit_specifier, merge_option: $merge_option, body_max_merge_hunks: $body_max_merge_hunks, file_path: $file_path, conflict_detail_level: $conflict_detail_level, conflict_resolution_strategy: $conflict_resolution_strategy, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about one or more pull request events.
#
# POST /
# Returns: record<pullRequestEvents: table<pullRequestId: string, eventDate: string, pullRequestEventType: string, actorArn: string, pullRequestCreatedEventMetadata: record, pullRequestStatusChangedEventMetadata: record, pullRequestSourceReferenceUpdatedEventMetadata: record, pullRequestMergedStateChangedEventMetadata: record, approvalRuleEventMetadata: record, approvalStateChangedEventMetadata: record, approvalRuleOverriddenEventMetadata: record>, nextToken: string>
# operationId: DescribePullRequestEvents
export def "describe-pull-request-events" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  pull_request_id: string # The system-generated ID of the pull request. To get this ID, use ListPullRequests.
  --pull-request-event-type: string@pull-request-event-type-completer # Optional. The pull request event type about which you want to return information.
  --actor-arn: string # The Amazon Resource Name (ARN) of the user whose actions resulted in the event. Examples include updating the pull request with more commits or changing the status of a pull request.
  --body-next-token: string # An enumeration token that, when provided in a request, returns the next batch of the results. (spec name: nextToken)
  --body-max-results: int # A non-zero, non-negative integer used to limit the number of returned results. The default is 100 events, which is also the maximum number of events that can be returned in a result. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.DescribePullRequestEvents"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}, {name: pullRequestEventType, var: pull_request_event_type}, {name: actorArn, var: actor_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id, pull_request_event_type: $pull_request_event_type, actor_arn: $actor_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the association between a template and a repository so that approval rules based on the template are not automatically created when pull requests are created in the specified repository. This does not delete any approval rules previously created for pull requests through the template association.
#
# POST /
# operationId: DisassociateApprovalRuleTemplateFromRepository
export def "disassociate-approval-rule-template-from-repository" [
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
  approval_rule_template_name: string # The name of the approval rule template to disassociate from a specified repository.
  repository_name: string # The name of the repository you want to disassociate from the template.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.DisassociateApprovalRuleTemplateFromRepository"}]
    body: {content_type: "application/json", kind: json, fields: [{name: approvalRuleTemplateName, var: approval_rule_template_name}, {name: repositoryName, var: repository_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, approval_rule_template_name: $approval_rule_template_name, repository_name: $repository_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Evaluates whether a pull request has met all the conditions specified in its associated approval rules.
#
# POST /
# Returns: record<evaluation: record<approved: bool, overridden: bool, approvalRulesSatisfied: list<string>, approvalRulesNotSatisfied: list<string>>>
# operationId: EvaluatePullRequestApprovalRules
export def "evaluate-pull-request-approval-rules" [
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
  pull_request_id: string # The system-generated ID of the pull request you want to evaluate.
  revision_id: string # The system-generated ID for the pull request revision. To retrieve the most recent revision ID for a pull request, use GetPullRequest.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.EvaluatePullRequestApprovalRules"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}, {name: revisionId, var: revision_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id, revision_id: $revision_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a specified approval rule template.
#
# POST /
# Returns: record<approvalRuleTemplate: record<approvalRuleTemplateId: string, approvalRuleTemplateName: string, approvalRuleTemplateDescription: string, approvalRuleTemplateContent: string, ruleContentSha256: string, lastModifiedDate: string, creationDate: string, lastModifiedUser: string>>
# operationId: GetApprovalRuleTemplate
export def "get-approval-rule-template" [
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
  --x-amz-target: string@x-amz-target-completer-23 # required
  approval_rule_template_name: string # The name of the approval rule template for which you want to get information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetApprovalRuleTemplate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: approvalRuleTemplateName, var: approval_rule_template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, approval_rule_template_name: $approval_rule_template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the base-64 encoded content of an individual blob in a repository.
#
# POST /
# Returns: record<content: string>
# operationId: GetBlob
export def "get-blob" [
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
  --x-amz-target: string@x-amz-target-completer-24 # required
  repository_name: string # The name of the repository that contains the blob.
  blob_id: string # The ID of the blob, which is its SHA-1 pointer.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetBlob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: blobId, var: blob_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, blob_id: $blob_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a repository branch, including its name and the last commit ID.
#
# POST /
# Returns: record<branch: record<branchName: string, commitId: string>>
# operationId: GetBranch
export def "get-branch" [
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
  --x-amz-target: string@x-amz-target-completer-25 # required
  --repository-name: string # The name of the repository that contains the branch for which you want to retrieve information.
  --branch-name: string # The name of the branch for which you want to retrieve information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetBranch"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: branchName, var: branch_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, branch_name: $branch_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the content of a comment made on a change, file, or commit in a repository. Reaction counts might include numbers from user identities who were deleted after the reaction was made. For a count of reactions from active identities, use GetCommentReactions.
#
# POST /
# Returns: record<comment: record<commentId: string, content: string, inReplyTo: string, creationDate: string, lastModifiedDate: string, authorArn: string, deleted: bool, clientRequestToken: string, callerReactions: list<string>, reactionCounts: record>>
# operationId: GetComment
export def "get-comment" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  comment_id: string # The unique, system-generated ID of the comment. To get this ID, use GetCommentsForComparedCommit or GetCommentsForPullRequest.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetComment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: commentId, var: comment_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about reactions to a specified comment ID. Reactions from users who have been deleted will not be included in the count.
#
# POST /
# Returns: record<reactionsForComment: table<reaction: record, reactionUsers: list, reactionsFromDeletedUsersCount: int>, nextToken: string>
# operationId: GetCommentReactions
export def "get-comment-reactions" [
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
  --x-amz-target: string@x-amz-target-completer-27 # required
  comment_id: string # The ID of the comment for which you want to get reactions information.
  --reaction-user-arn: string # Optional. The Amazon Resource Name (ARN) of the user or identity for which you want to get reaction information.
  --body-next-token: string # An enumeration token that, when provided in a request, returns the next batch of the results. (spec name: nextToken)
  --body-max-results: int # A non-zero, non-negative integer used to limit the number of returned results. The default is the same as the allowed maximum, 1,000. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetCommentReactions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: commentId, var: comment_id}, {name: reactionUserArn, var: reaction_user_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, comment_id: $comment_id, reaction_user_arn: $reaction_user_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about comments made on the comparison between two commits. Reaction counts might include numbers from user identities who were deleted after the reaction was made. For a count of reactions from active identities, use GetCommentReactions.
#
# POST /
# Returns: record<commentsForComparedCommitData: table<repositoryName: string, beforeCommitId: string, afterCommitId: string, beforeBlobId: string, afterBlobId: string, location: record, comments: list>, nextToken: string>
# operationId: GetCommentsForComparedCommit
export def "get-comments-for-compared-commit" [
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  repository_name: string # The name of the repository where you want to compare commits.
  --before-commit-id: string # To establish the directionality of the comparison, the full commit ID of the before commit.
  after_commit_id: string # To establish the directionality of the comparison, the full commit ID of the after commit.
  --body-next-token: string # An enumeration token that when provided in a request, returns the next batch of the results. (spec name: nextToken)
  --body-max-results: int # A non-zero, non-negative integer used to limit the number of returned results. The default is 100 comments, but you can configure up to 500. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetCommentsForComparedCommit"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: beforeCommitId, var: before_commit_id}, {name: afterCommitId, var: after_commit_id}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, before_commit_id: $before_commit_id, after_commit_id: $after_commit_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns comments made on a pull request. Reaction counts might include numbers from user identities who were deleted after the reaction was made. For a count of reactions from active identities, use GetCommentReactions.
#
# POST /
# Returns: record<commentsForPullRequestData: table<pullRequestId: string, repositoryName: string, beforeCommitId: string, afterCommitId: string, beforeBlobId: string, afterBlobId: string, location: record, comments: list>, nextToken: string>
# operationId: GetCommentsForPullRequest
export def "get-comments-for-pull-request" [
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
  pull_request_id: string # The system-generated ID of the pull request. To get this ID, use ListPullRequests.
  --repository-name: string # The name of the repository that contains the pull request.
  --before-commit-id: string # The full commit ID of the commit in the destination branch that was the tip of the branch at the time the pull request was created.
  --after-commit-id: string # The full commit ID of the commit in the source branch that was the tip of the branch at the time the comment was made.
  --body-next-token: string # An enumeration token that, when provided in a request, returns the next batch of the results. (spec name: nextToken)
  --body-max-results: int # A non-zero, non-negative integer used to limit the number of returned results. The default is 100 comments. You can return up to 500 comments with a single request. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetCommentsForPullRequest"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}, {name: repositoryName, var: repository_name}, {name: beforeCommitId, var: before_commit_id}, {name: afterCommitId, var: after_commit_id}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id, repository_name: $repository_name, before_commit_id: $before_commit_id, after_commit_id: $after_commit_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a commit, including commit message and committer information.
#
# POST /
# Returns: record<commit: record<commitId: string, treeId: string, parents: list<string>, message: string, author: record<name: string, email: string, date: string>, committer: record<name: string, email: string, date: string>, additionalData: string>>
# operationId: GetCommit
export def "get-commit" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  repository_name: string # The name of the repository to which the commit was made.
  commit_id: string # The commit ID. Commit IDs are the full SHA ID of the commit.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetCommit"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: commitId, var: commit_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, commit_id: $commit_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID, or other fully qualified reference). Results can be limited to a specified path.
#
# POST /
# Returns: record<differences: table<beforeBlob: record, afterBlob: record, changeType: string>, NextToken: string>
# operationId: GetDifferences
export def "get-differences" [
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  repository_name: string # The name of the repository where you want to get differences.
  --before-commit-specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, the full commit ID). Optional. If not specified, all changes before the afterCommitSpecifier value are shown. If you do not use beforeCommitSpecifier in your request, consider limiting the results with maxResults.
  after_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit.
  --before-path: string # The file path in which to check for differences. Limits the results to this path. Can also be used to specify the previous name of a directory or folder. If beforePath and afterPath are not specified, differences are shown for all paths.
  --after-path: string # The file path in which to check differences. Limits the results to this path. Can also be used to specify the changed name of a directory or folder, if it has changed. If not specified, differences are shown for all paths.
  --body-max-results: int # A non-zero, non-negative integer used to limit the number of returned results. (spec name: MaxResults)
  --body-next-token: string # An enumeration token that, when provided in a request, returns the next batch of the results. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetDifferences"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: beforeCommitSpecifier, var: before_commit_specifier}, {name: afterCommitSpecifier, var: after_commit_specifier}, {name: beforePath, var: before_path}, {name: afterPath, var: after_path}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, before_commit_specifier: $before_commit_specifier, after_commit_specifier: $after_commit_specifier, before_path: $before_path, after_path: $after_path, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the base-64 encoded contents of a specified file and its metadata.
#
# POST /
# Returns: record<commitId: string, blobId: string, filePath: string, fileMode: string, fileSize: int, fileContent: string>
# operationId: GetFile
export def "get-file" [
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  repository_name: string # The name of the repository that contains the file.
  --commit-specifier: string # The fully quaified reference that identifies the commit that contains the file. For example, you can specify a full commit ID, a tag, a branch name, or a reference such as refs/heads/master. If none is provided, the head commit is used.
  file_path: string # The fully qualified path to the file, including the full name and extension of the file. For example, /examples/file.md is the fully qualified path to a file named file.md in a folder named examples.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetFile"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: commitSpecifier, var: commit_specifier}, {name: filePath, var: file_path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, commit_specifier: $commit_specifier, file_path: $file_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the contents of a specified folder in a repository.
#
# POST /
# Returns: record<commitId: string, folderPath: string, treeId: string, subFolders: table<treeId: string, absolutePath: string, relativePath: string>, files: table<blobId: string, absolutePath: string, relativePath: string, fileMode: string>, symbolicLinks: table<blobId: string, absolutePath: string, relativePath: string, fileMode: string>, subModules: table<commitId: string, absolutePath: string, relativePath: string>>
# operationId: GetFolder
export def "get-folder" [
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  repository_name: string # The name of the repository.
  --commit-specifier: string # A fully qualified reference used to identify a commit that contains the version of the folder's content to return. A fully qualified reference can be a commit ID, branch name, tag, or reference such as HEAD. If no specifier is provided, the folder content is returned as it exists in the HEAD commit.
  folder_path: string # The fully qualified path to the folder whose contents are returned, including the folder name. For example, /examples is a fully-qualified path to a folder named examples that was created off of the root directory (/) of a repository.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetFolder"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: commitSpecifier, var: commit_specifier}, {name: folderPath, var: folder_path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, commit_specifier: $commit_specifier, folder_path: $folder_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a specified merge commit.
#
# POST /
# Returns: record<sourceCommitId: string, destinationCommitId: string, baseCommitId: string, mergedCommitId: string>
# operationId: GetMergeCommit
export def "get-merge-commit" [
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
  repository_name: string # The name of the repository that contains the merge commit about which you want to get information.
  source_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  destination_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  --conflict-detail-level: string@conflict-detail-level-completer # The level of conflict detail to use. If unspecified, the default FILE_LEVEL is used, which returns a not-mergeable result if the same file has differences in both branches. If LINE_LEVEL is specified, a conflict is considered not mergeable if the same file in both branches has differences on the same line.
  --conflict-resolution-strategy: string@conflict-resolution-strategy-completer # Specifies which branch to use when resolving conflicts, or whether to attempt automatically merging two versions of a file. The default is NONE, which requires any conflicts to be resolved manually before the merge operation is successful.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetMergeCommit"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: sourceCommitSpecifier, var: source_commit_specifier}, {name: destinationCommitSpecifier, var: destination_commit_specifier}, {name: conflictDetailLevel, var: conflict_detail_level}, {name: conflictResolutionStrategy, var: conflict_resolution_strategy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, source_commit_specifier: $source_commit_specifier, destination_commit_specifier: $destination_commit_specifier, conflict_detail_level: $conflict_detail_level, conflict_resolution_strategy: $conflict_resolution_strategy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
#
# POST /
# Returns: record<mergeable: bool, destinationCommitId: string, sourceCommitId: string, baseCommitId: string, conflictMetadataList: table<filePath: string, fileSizes: record, fileModes: record, objectTypes: record, numberOfConflicts: int, isBinaryFile: record, contentConflict: bool, fileModeConflict: bool, objectTypeConflict: bool, mergeOperations: record>, nextToken: string>
# operationId: GetMergeConflicts
export def "get-merge-conflicts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-conflict-files: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-35 # required
  repository_name: string # The name of the repository where the pull request was created.
  destination_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  source_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  merge_option: string@merge-option-completer # The merge option or strategy you want to use to merge the code.
  --conflict-detail-level: string@conflict-detail-level-completer # The level of conflict detail to use. If unspecified, the default FILE_LEVEL is used, which returns a not-mergeable result if the same file has differences in both branches. If LINE_LEVEL is specified, a conflict is considered not mergeable if the same file in both branches has differences on the same line.
  --body-max-conflict-files: int # The maximum number of files to include in the output. (spec name: maxConflictFiles)
  --conflict-resolution-strategy: string@conflict-resolution-strategy-completer # Specifies which branch to use when resolving conflicts, or whether to attempt automatically merging two versions of a file. The default is NONE, which requires any conflicts to be resolved manually before the merge operation is successful.
  --body-next-token: string # An enumeration token that, when provided in a request, returns the next batch of the results. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxConflictFiles, var: max_conflict_files}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetMergeConflicts"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: destinationCommitSpecifier, var: destination_commit_specifier}, {name: sourceCommitSpecifier, var: source_commit_specifier}, {name: mergeOption, var: merge_option}, {name: conflictDetailLevel, var: conflict_detail_level}, {name: maxConflictFiles, var: body_max_conflict_files}, {name: conflictResolutionStrategy, var: conflict_resolution_strategy}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_conflict_files: $max_conflict_files, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, destination_commit_specifier: $destination_commit_specifier, source_commit_specifier: $source_commit_specifier, merge_option: $merge_option, conflict_detail_level: $conflict_detail_level, body_max_conflict_files: $body_max_conflict_files, conflict_resolution_strategy: $conflict_resolution_strategy, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the merge options available for merging two specified branches. For details about why a merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
#
# POST /
# Returns: record<mergeOptions: list<string>, sourceCommitId: string, destinationCommitId: string, baseCommitId: string>
# operationId: GetMergeOptions
export def "get-merge-options" [
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
  repository_name: string # The name of the repository that contains the commits about which you want to get merge options.
  source_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  destination_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  --conflict-detail-level: string@conflict-detail-level-completer # The level of conflict detail to use. If unspecified, the default FILE_LEVEL is used, which returns a not-mergeable result if the same file has differences in both branches. If LINE_LEVEL is specified, a conflict is considered not mergeable if the same file in both branches has differences on the same line.
  --conflict-resolution-strategy: string@conflict-resolution-strategy-completer # Specifies which branch to use when resolving conflicts, or whether to attempt automatically merging two versions of a file. The default is NONE, which requires any conflicts to be resolved manually before the merge operation is successful.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetMergeOptions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: sourceCommitSpecifier, var: source_commit_specifier}, {name: destinationCommitSpecifier, var: destination_commit_specifier}, {name: conflictDetailLevel, var: conflict_detail_level}, {name: conflictResolutionStrategy, var: conflict_resolution_strategy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, source_commit_specifier: $source_commit_specifier, destination_commit_specifier: $destination_commit_specifier, conflict_detail_level: $conflict_detail_level, conflict_resolution_strategy: $conflict_resolution_strategy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a pull request in a specified repository.
#
# POST /
# Returns: record<pullRequest: record<pullRequestId: string, title: string, description: string, lastActivityDate: string, creationDate: string, pullRequestStatus: string, authorArn: string, pullRequestTargets: list<record>, clientRequestToken: string, revisionId: string, approvalRules: list<record>>>
# operationId: GetPullRequest
export def "get-pull-request" [
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
  pull_request_id: string # The system-generated ID of the pull request. To get this ID, use ListPullRequests.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetPullRequest"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the approval states for a specified pull request. Approval states only apply to pull requests that have one or more approval rules applied to them.
#
# POST /
# Returns: record<approvals: table<userArn: string, approvalState: string>>
# operationId: GetPullRequestApprovalStates
export def "get-pull-request-approval-states" [
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
  pull_request_id: string # The system-generated ID for the pull request.
  revision_id: string # The system-generated ID for the pull request revision.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetPullRequestApprovalStates"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}, {name: revisionId, var: revision_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id, revision_id: $revision_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about whether approval rules have been set aside (overridden) for a pull request, and if so, the Amazon Resource Name (ARN) of the user or identity that overrode the rules and their requirements for the pull request.
#
# POST /
# Returns: record<overridden: bool, overrider: string>
# operationId: GetPullRequestOverrideState
export def "get-pull-request-override-state" [
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
  pull_request_id: string # The ID of the pull request for which you want to get information about whether approval rules have been set aside (overridden).
  revision_id: string # The system-generated ID of the revision for the pull request. To retrieve the most recent revision ID, use GetPullRequest.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetPullRequestOverrideState"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}, {name: revisionId, var: revision_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id, revision_id: $revision_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a repository. The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.
#
# POST /
# Returns: record<repositoryMetadata: record<accountId: string, repositoryId: string, repositoryName: string, repositoryDescription: string, defaultBranch: string, lastModifiedDate: string, creationDate: string, cloneUrlHttp: string, cloneUrlSsh: string, Arn: string>>
# operationId: GetRepository
export def "get-repository" [
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
  repository_name: string # The name of the repository to get information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetRepository"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about triggers configured for a repository.
#
# POST /
# Returns: record<configurationId: string, triggers: table<name: string, destinationArn: string, customData: string, branches: list, events: list>>
# operationId: GetRepositoryTriggers
export def "get-repository-triggers" [
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
  repository_name: string # The name of the repository for which the trigger is configured.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.GetRepositoryTriggers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all approval rule templates in the specified AWS Region in your AWS account. If an AWS Region is not specified, the AWS Region where you are signed in is used.
#
# POST /
# Returns: record<approvalRuleTemplateNames: list<string>, nextToken: string>
# operationId: ListApprovalRuleTemplates
export def "list-approval-rule-templates" [
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
  --x-amz-target: string@x-amz-target-completer-42 # required
  --body-next-token: string # An enumeration token that, when provided in a request, returns the next batch of the results. (spec name: nextToken)
  --body-max-results: int # A non-zero, non-negative integer used to limit the number of returned results. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.ListApprovalRuleTemplates"}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all approval rule templates that are associated with a specified repository.
#
# POST /
# Returns: record<approvalRuleTemplateNames: list<string>, nextToken: string>
# operationId: ListAssociatedApprovalRuleTemplatesForRepository
export def "list-associated-approval-rule-templates-for-repository" [
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
  --x-amz-target: string@x-amz-target-completer-43 # required
  repository_name: string # The name of the repository for which you want to list all associated approval rule templates.
  --body-next-token: string # An enumeration token that, when provided in a request, returns the next batch of the results. (spec name: nextToken)
  --body-max-results: int # A non-zero, non-negative integer used to limit the number of returned results. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.ListAssociatedApprovalRuleTemplatesForRepository"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about one or more branches in a repository.
#
# POST /
# Returns: record<branches: list<string>, nextToken: string>
# operationId: ListBranches
export def "list-branches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-44 # required
  repository_name: string # The name of the repository that contains the branches.
  --body-next-token: string # An enumeration token that allows the operation to batch the results. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.ListBranches"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
#
# POST /
# Returns: record<pullRequestIds: list<string>, nextToken: string>
# operationId: ListPullRequests
export def "list-pull-requests" [
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
  --x-amz-target: string@x-amz-target-completer-45 # required
  repository_name: string # The name of the repository for which you want to list pull requests.
  --author-arn: string # Optional. The Amazon Resource Name (ARN) of the user who created the pull request. If used, this filters the results to pull requests created by that user.
  --pull-request-status: string@pull-request-status-completer # Optional. The status of the pull request. If used, this refines the results to the pull requests that match the specified status.
  --body-next-token: string # An enumeration token that, when provided in a request, returns the next batch of the results. (spec name: nextToken)
  --body-max-results: int # A non-zero, non-negative integer used to limit the number of returned results. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.ListPullRequests"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: authorArn, var: author_arn}, {name: pullRequestStatus, var: pull_request_status}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, author_arn: $author_arn, pull_request_status: $pull_request_status, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about one or more repositories.
#
# POST /
# Returns: record<repositories: table<repositoryName: string, repositoryId: string>, nextToken: string>
# operationId: ListRepositories
export def "list-repositories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46 # required
  --body-next-token: string # An enumeration token that allows the operation to batch the results of the operation. Batch sizes are 1,000 for list repository operations. When the client sends the token back to AWS CodeCommit, another page of 1,000 records is retrieved. (spec name: nextToken)
  --sort-by: string@sort-by-completer # The criteria used to sort the results of a list repositories operation.
  --order: string@order-completer # The order in which to sort the results of a list repositories operation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.ListRepositories"}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: body_next_token}, {name: sortBy, var: sort_by}, {name: order, var: order}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, sort_by: $sort_by, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all repositories associated with the specified approval rule template.
#
# POST /
# Returns: record<repositoryNames: list<string>, nextToken: string>
# operationId: ListRepositoriesForApprovalRuleTemplate
export def "list-repositories-for-approval-rule-template" [
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
  --x-amz-target: string@x-amz-target-completer-47 # required
  approval_rule_template_name: string # The name of the approval rule template for which you want to list repositories that are associated with that template.
  --body-next-token: string # An enumeration token that, when provided in a request, returns the next batch of the results. (spec name: nextToken)
  --body-max-results: int # A non-zero, non-negative integer used to limit the number of returned results. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.ListRepositoriesForApprovalRuleTemplate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: approvalRuleTemplateName, var: approval_rule_template_name}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, approval_rule_template_name: $approval_rule_template_name, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see CodeCommit Resources and Operations (https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats) in the AWS CodeCommit User Guide.
#
# POST /
# Returns: record<tags: record, nextToken: string>
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-48 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource for which you want to get information about tags, if any.
  --next-token: string # An enumeration token that, when provided in a request, returns the next batch of the results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceArn, var: resource_arn}, {name: nextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Merges two branches using the fast-forward merge strategy.
#
# POST /
# Returns: record<commitId: string, treeId: string>
# operationId: MergeBranchesByFastForward
export def "merge-branches-by-fast-forward" [
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
  repository_name: string # The name of the repository where you want to merge two branches.
  source_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  destination_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  --target-branch: string # The branch where the merge is applied.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.MergeBranchesByFastForward"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: sourceCommitSpecifier, var: source_commit_specifier}, {name: destinationCommitSpecifier, var: destination_commit_specifier}, {name: targetBranch, var: target_branch}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, source_commit_specifier: $source_commit_specifier, destination_commit_specifier: $destination_commit_specifier, target_branch: $target_branch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Merges two branches using the squash merge strategy.
#
# POST /
# Returns: record<commitId: string, treeId: string>
# operationId: MergeBranchesBySquash
export def "merge-branches-by-squash" [
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
  repository_name: string # The name of the repository where you want to merge two branches.
  source_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  destination_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  --target-branch: string # The branch where the merge is applied.
  --conflict-detail-level: string@conflict-detail-level-completer # The level of conflict detail to use. If unspecified, the default FILE_LEVEL is used, which returns a not-mergeable result if the same file has differences in both branches. If LINE_LEVEL is specified, a conflict is considered not mergeable if the same file in both branches has differences on the same line.
  --conflict-resolution-strategy: string@conflict-resolution-strategy-completer # Specifies which branch to use when resolving conflicts, or whether to attempt automatically merging two versions of a file. The default is NONE, which requires any conflicts to be resolved manually before the merge operation is successful.
  --author-name: string # The name of the author who created the commit. This information is used as both the author and committer for the commit.
  --email: string # The email address of the person merging the branches. This information is used in the commit information for the merge.
  --commit-message: string # The commit message for the merge.
  --keep-empty-folders: oneof<nothing, bool> # If the commit contains deletions, whether to keep a folder or folder structure if the changes leave the folders empty. If this is specified as true, a .gitkeep file is created for empty folders. The default is false.
  --conflict-resolution: record # If AUTOMERGE is the conflict resolution strategy, a list of inputs to use when resolving conflicts during a merge. — shape: {replaceContents?: list, deleteFiles?: list, setFileModes?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.MergeBranchesBySquash"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: sourceCommitSpecifier, var: source_commit_specifier}, {name: destinationCommitSpecifier, var: destination_commit_specifier}, {name: targetBranch, var: target_branch}, {name: conflictDetailLevel, var: conflict_detail_level}, {name: conflictResolutionStrategy, var: conflict_resolution_strategy}, {name: authorName, var: author_name}, {name: email, var: email}, {name: commitMessage, var: commit_message}, {name: keepEmptyFolders, var: keep_empty_folders}, {name: conflictResolution, var: conflict_resolution}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, source_commit_specifier: $source_commit_specifier, destination_commit_specifier: $destination_commit_specifier, target_branch: $target_branch, conflict_detail_level: $conflict_detail_level, conflict_resolution_strategy: $conflict_resolution_strategy, author_name: $author_name, email: $email, commit_message: $commit_message, keep_empty_folders: $keep_empty_folders, conflict_resolution: $conflict_resolution
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Merges two specified branches using the three-way merge strategy.
#
# POST /
# Returns: record<commitId: string, treeId: string>
# operationId: MergeBranchesByThreeWay
export def "merge-branches-by-three-way" [
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
  repository_name: string # The name of the repository where you want to merge two branches.
  source_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  destination_commit_specifier: string # The branch, tag, HEAD, or other fully qualified reference used to identify a commit (for example, a branch name or a full commit ID).
  --target-branch: string # The branch where the merge is applied.
  --conflict-detail-level: string@conflict-detail-level-completer # The level of conflict detail to use. If unspecified, the default FILE_LEVEL is used, which returns a not-mergeable result if the same file has differences in both branches. If LINE_LEVEL is specified, a conflict is considered not mergeable if the same file in both branches has differences on the same line.
  --conflict-resolution-strategy: string@conflict-resolution-strategy-completer # Specifies which branch to use when resolving conflicts, or whether to attempt automatically merging two versions of a file. The default is NONE, which requires any conflicts to be resolved manually before the merge operation is successful.
  --author-name: string # The name of the author who created the commit. This information is used as both the author and committer for the commit.
  --email: string # The email address of the person merging the branches. This information is used in the commit information for the merge.
  --commit-message: string # The commit message to include in the commit information for the merge.
  --keep-empty-folders: oneof<nothing, bool> # If the commit contains deletions, whether to keep a folder or folder structure if the changes leave the folders empty. If true, a .gitkeep file is created for empty folders. The default is false.
  --conflict-resolution: record # If AUTOMERGE is the conflict resolution strategy, a list of inputs to use when resolving conflicts during a merge. — shape: {replaceContents?: list, deleteFiles?: list, setFileModes?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.MergeBranchesByThreeWay"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: sourceCommitSpecifier, var: source_commit_specifier}, {name: destinationCommitSpecifier, var: destination_commit_specifier}, {name: targetBranch, var: target_branch}, {name: conflictDetailLevel, var: conflict_detail_level}, {name: conflictResolutionStrategy, var: conflict_resolution_strategy}, {name: authorName, var: author_name}, {name: email, var: email}, {name: commitMessage, var: commit_message}, {name: keepEmptyFolders, var: keep_empty_folders}, {name: conflictResolution, var: conflict_resolution}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, source_commit_specifier: $source_commit_specifier, destination_commit_specifier: $destination_commit_specifier, target_branch: $target_branch, conflict_detail_level: $conflict_detail_level, conflict_resolution_strategy: $conflict_resolution_strategy, author_name: $author_name, email: $email, commit_message: $commit_message, keep_empty_folders: $keep_empty_folders, conflict_resolution: $conflict_resolution
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
#
# POST /
# Returns: record<pullRequest: record<pullRequestId: string, title: string, description: string, lastActivityDate: string, creationDate: string, pullRequestStatus: string, authorArn: string, pullRequestTargets: list<record>, clientRequestToken: string, revisionId: string, approvalRules: list<record>>>
# operationId: MergePullRequestByFastForward
export def "merge-pull-request-by-fast-forward" [
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
  pull_request_id: string # The system-generated ID of the pull request. To get this ID, use ListPullRequests.
  repository_name: string # The name of the repository where the pull request was created.
  --source-commit-id: string # The full commit ID of the original or updated commit in the pull request source branch. Pass this value if you want an exception thrown if the current commit ID of the tip of the source branch does not match this commit ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.MergePullRequestByFastForward"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}, {name: repositoryName, var: repository_name}, {name: sourceCommitId, var: source_commit_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id, repository_name: $repository_name, source_commit_id: $source_commit_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
#
# POST /
# Returns: record<pullRequest: record<pullRequestId: string, title: string, description: string, lastActivityDate: string, creationDate: string, pullRequestStatus: string, authorArn: string, pullRequestTargets: list<record>, clientRequestToken: string, revisionId: string, approvalRules: list<record>>>
# operationId: MergePullRequestBySquash
export def "merge-pull-request-by-squash" [
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
  --x-amz-target: string@x-amz-target-completer-53 # required
  pull_request_id: string # The system-generated ID of the pull request. To get this ID, use ListPullRequests.
  repository_name: string # The name of the repository where the pull request was created.
  --source-commit-id: string # The full commit ID of the original or updated commit in the pull request source branch. Pass this value if you want an exception thrown if the current commit ID of the tip of the source branch does not match this commit ID.
  --conflict-detail-level: string@conflict-detail-level-completer # The level of conflict detail to use. If unspecified, the default FILE_LEVEL is used, which returns a not-mergeable result if the same file has differences in both branches. If LINE_LEVEL is specified, a conflict is considered not mergeable if the same file in both branches has differences on the same line.
  --conflict-resolution-strategy: string@conflict-resolution-strategy-completer # Specifies which branch to use when resolving conflicts, or whether to attempt automatically merging two versions of a file. The default is NONE, which requires any conflicts to be resolved manually before the merge operation is successful.
  --commit-message: string # The commit message to include in the commit information for the merge.
  --author-name: string # The name of the author who created the commit. This information is used as both the author and committer for the commit.
  --email: string # The email address of the person merging the branches. This information is used in the commit information for the merge.
  --keep-empty-folders: oneof<nothing, bool> # If the commit contains deletions, whether to keep a folder or folder structure if the changes leave the folders empty. If true, a .gitkeep file is created for empty folders. The default is false.
  --conflict-resolution: record # If AUTOMERGE is the conflict resolution strategy, a list of inputs to use when resolving conflicts during a merge. — shape: {replaceContents?: list, deleteFiles?: list, setFileModes?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.MergePullRequestBySquash"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}, {name: repositoryName, var: repository_name}, {name: sourceCommitId, var: source_commit_id}, {name: conflictDetailLevel, var: conflict_detail_level}, {name: conflictResolutionStrategy, var: conflict_resolution_strategy}, {name: commitMessage, var: commit_message}, {name: authorName, var: author_name}, {name: email, var: email}, {name: keepEmptyFolders, var: keep_empty_folders}, {name: conflictResolution, var: conflict_resolution}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id, repository_name: $repository_name, source_commit_id: $source_commit_id, conflict_detail_level: $conflict_detail_level, conflict_resolution_strategy: $conflict_resolution_strategy, commit_message: $commit_message, author_name: $author_name, email: $email, keep_empty_folders: $keep_empty_folders, conflict_resolution: $conflict_resolution
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
#
# POST /
# Returns: record<pullRequest: record<pullRequestId: string, title: string, description: string, lastActivityDate: string, creationDate: string, pullRequestStatus: string, authorArn: string, pullRequestTargets: list<record>, clientRequestToken: string, revisionId: string, approvalRules: list<record>>>
# operationId: MergePullRequestByThreeWay
export def "merge-pull-request-by-three-way" [
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
  --x-amz-target: string@x-amz-target-completer-54 # required
  pull_request_id: string # The system-generated ID of the pull request. To get this ID, use ListPullRequests.
  repository_name: string # The name of the repository where the pull request was created.
  --source-commit-id: string # The full commit ID of the original or updated commit in the pull request source branch. Pass this value if you want an exception thrown if the current commit ID of the tip of the source branch does not match this commit ID.
  --conflict-detail-level: string@conflict-detail-level-completer # The level of conflict detail to use. If unspecified, the default FILE_LEVEL is used, which returns a not-mergeable result if the same file has differences in both branches. If LINE_LEVEL is specified, a conflict is considered not mergeable if the same file in both branches has differences on the same line.
  --conflict-resolution-strategy: string@conflict-resolution-strategy-completer # Specifies which branch to use when resolving conflicts, or whether to attempt automatically merging two versions of a file. The default is NONE, which requires any conflicts to be resolved manually before the merge operation is successful.
  --commit-message: string # The commit message to include in the commit information for the merge.
  --author-name: string # The name of the author who created the commit. This information is used as both the author and committer for the commit.
  --email: string # The email address of the person merging the branches. This information is used in the commit information for the merge.
  --keep-empty-folders: oneof<nothing, bool> # If the commit contains deletions, whether to keep a folder or folder structure if the changes leave the folders empty. If true, a .gitkeep file is created for empty folders. The default is false.
  --conflict-resolution: record # If AUTOMERGE is the conflict resolution strategy, a list of inputs to use when resolving conflicts during a merge. — shape: {replaceContents?: list, deleteFiles?: list, setFileModes?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.MergePullRequestByThreeWay"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}, {name: repositoryName, var: repository_name}, {name: sourceCommitId, var: source_commit_id}, {name: conflictDetailLevel, var: conflict_detail_level}, {name: conflictResolutionStrategy, var: conflict_resolution_strategy}, {name: commitMessage, var: commit_message}, {name: authorName, var: author_name}, {name: email, var: email}, {name: keepEmptyFolders, var: keep_empty_folders}, {name: conflictResolution, var: conflict_resolution}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id, repository_name: $repository_name, source_commit_id: $source_commit_id, conflict_detail_level: $conflict_detail_level, conflict_resolution_strategy: $conflict_resolution_strategy, commit_message: $commit_message, author_name: $author_name, email: $email, keep_empty_folders: $keep_empty_folders, conflict_resolution: $conflict_resolution
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets aside (overrides) all approval rule requirements for a specified pull request.
#
# POST /
# operationId: OverridePullRequestApprovalRules
export def "override-pull-request-approval-rules" [
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
  --x-amz-target: string@x-amz-target-completer-55 # required
  pull_request_id: string # The system-generated ID of the pull request for which you want to override all approval rule requirements. To get this information, use GetPullRequest.
  revision_id: string # The system-generated ID of the most recent revision of the pull request. You cannot override approval rules for anything but the most recent revision of a pull request. To get the revision ID, use GetPullRequest.
  override_status: string@override-status-completer # Whether you want to set aside approval rule requirements for the pull request (OVERRIDE) or revoke a previous override and apply approval rule requirements (REVOKE). REVOKE status is not stored.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.OverridePullRequestApprovalRules"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}, {name: revisionId, var: revision_id}, {name: overrideStatus, var: override_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id, revision_id: $revision_id, override_status: $override_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Posts a comment on the comparison between two commits.
#
# POST /
# Returns: record<repositoryName: string, beforeCommitId: string, afterCommitId: string, beforeBlobId: string, afterBlobId: string, location: record<filePath: string, filePosition: int, relativeFileVersion: string>, comment: record<commentId: string, content: string, inReplyTo: string, creationDate: string, lastModifiedDate: string, authorArn: string, deleted: bool, clientRequestToken: string, callerReactions: list<string>, reactionCounts: record>>
# operationId: PostCommentForComparedCommit
export def "post-comment-for-compared-commit" [
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
  --x-amz-target: string@x-amz-target-completer-56 # required
  repository_name: string # The name of the repository where you want to post a comment on the comparison between commits.
  --before-commit-id: string # To establish the directionality of the comparison, the full commit ID of the before commit. Required for commenting on any commit unless that commit is the initial commit.
  after_commit_id: string # To establish the directionality of the comparison, the full commit ID of the after commit.
  --location: record # Returns information about the location of a change or comment in the comparison between two commits or a pull request. — shape: {filePath?: string, filePosition?: int, relativeFileVersion?: "BEFORE"|"AFTER"}
  content: string # The content of the comment you want to make.
  --client-request-token: string # A unique, client-generated idempotency token that, when provided in a request, ensures the request cannot be repeated with a changed parameter. If a request is received with the same parameters and a token is included, the request returns information about the initial request that used that token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.PostCommentForComparedCommit"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: beforeCommitId, var: before_commit_id}, {name: afterCommitId, var: after_commit_id}, {name: location, var: location}, {name: content, var: content}, {name: clientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, before_commit_id: $before_commit_id, after_commit_id: $after_commit_id, location: $location, content: $content, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Posts a comment on a pull request.
#
# POST /
# Returns: record<repositoryName: string, pullRequestId: string, beforeCommitId: string, afterCommitId: string, beforeBlobId: string, afterBlobId: string, location: record<filePath: string, filePosition: int, relativeFileVersion: string>, comment: record<commentId: string, content: string, inReplyTo: string, creationDate: string, lastModifiedDate: string, authorArn: string, deleted: bool, clientRequestToken: string, callerReactions: list<string>, reactionCounts: record>>
# operationId: PostCommentForPullRequest
export def "post-comment-for-pull-request" [
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
  --x-amz-target: string@x-amz-target-completer-57 # required
  pull_request_id: string # The system-generated ID of the pull request. To get this ID, use ListPullRequests.
  repository_name: string # The name of the repository where you want to post a comment on a pull request.
  before_commit_id: string # The full commit ID of the commit in the destination branch that was the tip of the branch at the time the pull request was created.
  after_commit_id: string # The full commit ID of the commit in the source branch that is the current tip of the branch for the pull request when you post the comment.
  --location: record # Returns information about the location of a change or comment in the comparison between two commits or a pull request. — shape: {filePath?: string, filePosition?: int, relativeFileVersion?: "BEFORE"|"AFTER"}
  content: string # The content of your comment on the change.
  --client-request-token: string # A unique, client-generated idempotency token that, when provided in a request, ensures the request cannot be repeated with a changed parameter. If a request is received with the same parameters and a token is included, the request returns information about the initial request that used that token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.PostCommentForPullRequest"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}, {name: repositoryName, var: repository_name}, {name: beforeCommitId, var: before_commit_id}, {name: afterCommitId, var: after_commit_id}, {name: location, var: location}, {name: content, var: content}, {name: clientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id, repository_name: $repository_name, before_commit_id: $before_commit_id, after_commit_id: $after_commit_id, location: $location, content: $content, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
#
# POST /
# Returns: record<comment: record<commentId: string, content: string, inReplyTo: string, creationDate: string, lastModifiedDate: string, authorArn: string, deleted: bool, clientRequestToken: string, callerReactions: list<string>, reactionCounts: record>>
# operationId: PostCommentReply
export def "post-comment-reply" [
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
  --x-amz-target: string@x-amz-target-completer-58 # required
  in_reply_to: string # The system-generated ID of the comment to which you want to reply. To get this ID, use GetCommentsForComparedCommit or GetCommentsForPullRequest.
  --client-request-token: string # A unique, client-generated idempotency token that, when provided in a request, ensures the request cannot be repeated with a changed parameter. If a request is received with the same parameters and a token is included, the request returns information about the initial request that used that token.
  content: string # The contents of your reply to a comment.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.PostCommentReply"}]
    body: {content_type: "application/json", kind: json, fields: [{name: inReplyTo, var: in_reply_to}, {name: clientRequestToken, var: client_request_token}, {name: content, var: content}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, in_reply_to: $in_reply_to, client_request_token: $client_request_token, content: $content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds or updates a reaction to a specified comment for the user whose identity is used to make the request. You can only add or update a reaction for yourself. You cannot add, modify, or delete a reaction for another user.
#
# POST /
# operationId: PutCommentReaction
export def "put-comment-reaction" [
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
  --x-amz-target: string@x-amz-target-completer-59 # required
  comment_id: string # The ID of the comment to which you want to add or update a reaction.
  reaction_value: string # The emoji reaction you want to add or update. To remove a reaction, provide a value of blank or null. You can also provide the value of none. For information about emoji reaction values supported in AWS CodeCommit, see the AWS CodeCommit User Guide (https://docs.aws.amazon.com/codecommit/latest/userguide/how-to-commit-comment.html#emoji-reaction-table).
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.PutCommentReaction"}]
    body: {content_type: "application/json", kind: json, fields: [{name: commentId, var: comment_id}, {name: reactionValue, var: reaction_value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, comment_id: $comment_id, reaction_value: $reaction_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
#
# POST /
# Returns: record<commitId: string, blobId: string, treeId: string>
# operationId: PutFile
export def "put-file" [
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
  --x-amz-target: string@x-amz-target-completer-60 # required
  repository_name: string # The name of the repository where you want to add or update the file.
  branch_name: string # The name of the branch where you want to add or update the file. If this is an empty repository, this branch is created.
  file_content: string # The content of the file, in binary object format.
  file_path: string # The name of the file you want to add or update, including the relative path to the file in the repository. If the path does not currently exist in the repository, the path is created as part of adding the file.
  --file-mode: string@file-mode-completer # The file mode permissions of the blob. Valid file mode permissions are listed here.
  --parent-commit-id: string # The full commit ID of the head commit in the branch where you want to add or update the file. If this is an empty repository, no commit ID is required. If this is not an empty repository, a commit ID is required. The commit ID must match the ID of the head commit at the time of the operation. Otherwise, an error occurs, and the file is not added or updated.
  --commit-message: string # A message about why this file was added or updated. Although it is optional, a message makes the commit history for your repository more useful.
  --name: string # The name of the person adding or updating the file. Although it is optional, a name makes the commit history for your repository more useful.
  --email: string # An email address for the person adding or updating the file.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.PutFile"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: branchName, var: branch_name}, {name: fileContent, var: file_content}, {name: filePath, var: file_path}, {name: fileMode, var: file_mode}, {name: parentCommitId, var: parent_commit_id}, {name: commitMessage, var: commit_message}, {name: name, var: name}, {name: email, var: email}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, branch_name: $branch_name, file_content: $file_content, file_path: $file_path, file_mode: $file_mode, parent_commit_id: $parent_commit_id, commit_message: $commit_message, name: $name, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replaces all triggers for a repository. Used to create or delete triggers.
#
# POST /
# Returns: record<configurationId: string>
# operationId: PutRepositoryTriggers
export def "put-repository-triggers" [
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
  --x-amz-target: string@x-amz-target-completer-61 # required
  repository_name: string # The name of the repository where you want to create or update the trigger.
  triggers: list # The JSON block of configuration information for each trigger. — item shape: {name: string, destinationArn: string, customData?: string, branches?: list<string>, events: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.PutRepositoryTriggers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: triggers, var: triggers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, triggers: $triggers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see CodeCommit Resources and Operations (https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats) in the AWS CodeCommit User Guide.
#
# POST /
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-62 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource to which you want to add or update tags.
  tags: record # The key-value pair to use when tagging this repository.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceArn, var: resource_arn}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test sends data from the last commit. If no data is available, sample data is generated.
#
# POST /
# Returns: record<successfulExecutions: list<string>, failedExecutions: table<trigger: string, failureMessage: string>>
# operationId: TestRepositoryTriggers
export def "test-repository-triggers" [
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
  --x-amz-target: string@x-amz-target-completer-63 # required
  repository_name: string # The name of the repository in which to test the triggers.
  triggers: list # The list of triggers to test. — item shape: {name: string, destinationArn: string, customData?: string, branches?: list<string>, events: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.TestRepositoryTriggers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: triggers, var: triggers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, triggers: $triggers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see CodeCommit Resources and Operations (https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats) in the AWS CodeCommit User Guide.
#
# POST /
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-64 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource to which you want to remove tags.
  tag_keys: list<string> # The tag key for each tag that you want to remove from the resource.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceArn, var: resource_arn}, {name: tagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the content of an approval rule template. You can change the number of required approvals, the membership of the approval rule, and whether an approval pool is defined.
#
# POST /
# Returns: record<approvalRuleTemplate: record<approvalRuleTemplateId: string, approvalRuleTemplateName: string, approvalRuleTemplateDescription: string, approvalRuleTemplateContent: string, ruleContentSha256: string, lastModifiedDate: string, creationDate: string, lastModifiedUser: string>>
# operationId: UpdateApprovalRuleTemplateContent
export def "update-approval-rule-template-content" [
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
  --x-amz-target: string@x-amz-target-completer-65 # required
  approval_rule_template_name: string # The name of the approval rule template where you want to update the content of the rule.
  new_rule_content: string # The content that replaces the existing content of the rule. Content statements must be complete. You cannot provide only the changes.
  --existing-rule-content-sha256: string # The SHA-256 hash signature for the content of the approval rule. You can retrieve this information by using GetPullRequest.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.UpdateApprovalRuleTemplateContent"}]
    body: {content_type: "application/json", kind: json, fields: [{name: approvalRuleTemplateName, var: approval_rule_template_name}, {name: newRuleContent, var: new_rule_content}, {name: existingRuleContentSha256, var: existing_rule_content_sha256}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, approval_rule_template_name: $approval_rule_template_name, new_rule_content: $new_rule_content, existing_rule_content_sha256: $existing_rule_content_sha256
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the description for a specified approval rule template.
#
# POST /
# Returns: record<approvalRuleTemplate: record<approvalRuleTemplateId: string, approvalRuleTemplateName: string, approvalRuleTemplateDescription: string, approvalRuleTemplateContent: string, ruleContentSha256: string, lastModifiedDate: string, creationDate: string, lastModifiedUser: string>>
# operationId: UpdateApprovalRuleTemplateDescription
export def "update-approval-rule-template-description" [
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
  --x-amz-target: string@x-amz-target-completer-66 # required
  approval_rule_template_name: string # The name of the template for which you want to update the description.
  approval_rule_template_description: string # The updated description of the approval rule template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.UpdateApprovalRuleTemplateDescription"}]
    body: {content_type: "application/json", kind: json, fields: [{name: approvalRuleTemplateName, var: approval_rule_template_name}, {name: approvalRuleTemplateDescription, var: approval_rule_template_description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, approval_rule_template_name: $approval_rule_template_name, approval_rule_template_description: $approval_rule_template_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the name of a specified approval rule template.
#
# POST /
# Returns: record<approvalRuleTemplate: record<approvalRuleTemplateId: string, approvalRuleTemplateName: string, approvalRuleTemplateDescription: string, approvalRuleTemplateContent: string, ruleContentSha256: string, lastModifiedDate: string, creationDate: string, lastModifiedUser: string>>
# operationId: UpdateApprovalRuleTemplateName
export def "update-approval-rule-template-name" [
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
  --x-amz-target: string@x-amz-target-completer-67 # required
  old_approval_rule_template_name: string # The current name of the approval rule template.
  new_approval_rule_template_name: string # The new name you want to apply to the approval rule template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.UpdateApprovalRuleTemplateName"}]
    body: {content_type: "application/json", kind: json, fields: [{name: oldApprovalRuleTemplateName, var: old_approval_rule_template_name}, {name: newApprovalRuleTemplateName, var: new_approval_rule_template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, old_approval_rule_template_name: $old_approval_rule_template_name, new_approval_rule_template_name: $new_approval_rule_template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replaces the contents of a comment.
#
# POST /
# Returns: record<comment: record<commentId: string, content: string, inReplyTo: string, creationDate: string, lastModifiedDate: string, authorArn: string, deleted: bool, clientRequestToken: string, callerReactions: list<string>, reactionCounts: record>>
# operationId: UpdateComment
export def "update-comment" [
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
  --x-amz-target: string@x-amz-target-completer-68 # required
  comment_id: string # The system-generated ID of the comment you want to update. To get this ID, use GetCommentsForComparedCommit or GetCommentsForPullRequest.
  content: string # The updated content to replace the existing content of the comment.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.UpdateComment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: commentId, var: comment_id}, {name: content, var: content}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, comment_id: $comment_id, content: $content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets or changes the default branch name for the specified repository. If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.
#
# POST /
# operationId: UpdateDefaultBranch
export def "update-default-branch" [
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
  --x-amz-target: string@x-amz-target-completer-69 # required
  repository_name: string # The name of the repository to set or change the default branch for.
  default_branch_name: string # The name of the branch to set as the default.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.UpdateDefaultBranch"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: defaultBranchName, var: default_branch_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, default_branch_name: $default_branch_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the structure of an approval rule created specifically for a pull request. For example, you can change the number of required approvers and the approval pool for approvers.
#
# POST /
# Returns: record<approvalRule: record<approvalRuleId: string, approvalRuleName: string, approvalRuleContent: string, ruleContentSha256: string, lastModifiedDate: string, creationDate: string, lastModifiedUser: string, originApprovalRuleTemplate: record<approvalRuleTemplateId: string, approvalRuleTemplateName: string>>>
# operationId: UpdatePullRequestApprovalRuleContent
export def "update-pull-request-approval-rule-content" [
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
  --x-amz-target: string@x-amz-target-completer-70 # required
  pull_request_id: string # The system-generated ID of the pull request.
  approval_rule_name: string # The name of the approval rule you want to update.
  --existing-rule-content-sha256: string # The SHA-256 hash signature for the content of the approval rule. You can retrieve this information by using GetPullRequest.
  new_rule_content: string # The updated content for the approval rule. When you update the content of the approval rule, you can specify approvers in an approval pool in one of two ways: CodeCommitApprovers: This option only requires an AWS account and a resource. It can be used for both IAM users and federated access users whose name matches the provided resource name. This is a very powerful option that offers a great deal of flexibility. For example, if you specify the AWS account 123456789012 and Mary_Major, all of the following are counted as approvals coming from that user: An IAM user in the account (arn:aws:iam::123456789012:user/Mary_Major) A federated user identified in IAM as Mary_Major (arn:aws:sts::123456789012:federated-user/Mary_Major) This option does not recognize an active session of someone assuming the role of CodeCommitReview with a role session name of Mary_Major (arn:aws:sts::123456789012:assumed-role/CodeCommitReview/Mary_Major) unless you include a wildcard (*Mary_Major). Fully qualified ARN: This option allows you to specify the fully qualified Amazon Resource Name (ARN) of the IAM user or role. For more information about IAM ARNs, wildcards, and formats, see IAM Identifiers (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html) in the IAM User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.UpdatePullRequestApprovalRuleContent"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}, {name: approvalRuleName, var: approval_rule_name}, {name: existingRuleContentSha256, var: existing_rule_content_sha256}, {name: newRuleContent, var: new_rule_content}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id, approval_rule_name: $approval_rule_name, existing_rule_content_sha256: $existing_rule_content_sha256, new_rule_content: $new_rule_content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the state of a user's approval on a pull request. The user is derived from the signed-in account when the request is made.
#
# POST /
# operationId: UpdatePullRequestApprovalState
export def "update-pull-request-approval-state" [
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
  --x-amz-target: string@x-amz-target-completer-71 # required
  pull_request_id: string # The system-generated ID of the pull request.
  revision_id: string # The system-generated ID of the revision.
  approval_state: string@approval-state-completer # The approval state to associate with the user on the pull request.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.UpdatePullRequestApprovalState"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}, {name: revisionId, var: revision_id}, {name: approvalState, var: approval_state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id, revision_id: $revision_id, approval_state: $approval_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replaces the contents of the description of a pull request.
#
# POST /
# Returns: record<pullRequest: record<pullRequestId: string, title: string, description: string, lastActivityDate: string, creationDate: string, pullRequestStatus: string, authorArn: string, pullRequestTargets: list<record>, clientRequestToken: string, revisionId: string, approvalRules: list<record>>>
# operationId: UpdatePullRequestDescription
export def "update-pull-request-description" [
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
  --x-amz-target: string@x-amz-target-completer-72 # required
  pull_request_id: string # The system-generated ID of the pull request. To get this ID, use ListPullRequests.
  description: string # The updated content of the description for the pull request. This content replaces the existing description.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.UpdatePullRequestDescription"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}, {name: description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the status of a pull request.
#
# POST /
# Returns: record<pullRequest: record<pullRequestId: string, title: string, description: string, lastActivityDate: string, creationDate: string, pullRequestStatus: string, authorArn: string, pullRequestTargets: list<record>, clientRequestToken: string, revisionId: string, approvalRules: list<record>>>
# operationId: UpdatePullRequestStatus
export def "update-pull-request-status" [
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
  --x-amz-target: string@x-amz-target-completer-73 # required
  pull_request_id: string # The system-generated ID of the pull request. To get this ID, use ListPullRequests.
  pull_request_status: string@pull-request-status-completer # The status of the pull request. The only valid operations are to update the status from OPEN to OPEN, OPEN to CLOSED or from CLOSED to CLOSED.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.UpdatePullRequestStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}, {name: pullRequestStatus, var: pull_request_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id, pull_request_status: $pull_request_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replaces the title of a pull request.
#
# POST /
# Returns: record<pullRequest: record<pullRequestId: string, title: string, description: string, lastActivityDate: string, creationDate: string, pullRequestStatus: string, authorArn: string, pullRequestTargets: list<record>, clientRequestToken: string, revisionId: string, approvalRules: list<record>>>
# operationId: UpdatePullRequestTitle
export def "update-pull-request-title" [
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
  --x-amz-target: string@x-amz-target-completer-74 # required
  pull_request_id: string # The system-generated ID of the pull request. To get this ID, use ListPullRequests.
  title: string # The updated title of the pull request. This replaces the existing title.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.UpdatePullRequestTitle"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pullRequestId, var: pull_request_id}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pull_request_id: $pull_request_id, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets or changes the comment or description for a repository. The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.
#
# POST /
# operationId: UpdateRepositoryDescription
export def "update-repository-description" [
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
  --x-amz-target: string@x-amz-target-completer-75 # required
  repository_name: string # The name of the repository to set or change the comment or description for.
  --repository-description: string # The new comment or description for the specified repository. Repository descriptions are limited to 1,000 characters.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.UpdateRepositoryDescription"}]
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryName, var: repository_name}, {name: repositoryDescription, var: repository_description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, repository_name: $repository_name, repository_description: $repository_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Renames a repository. The repository name must be unique across the calling AWS account. Repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix .git is prohibited. For more information about the limits on repository names, see Limits (https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html) in the AWS CodeCommit User Guide.
#
# POST /
# operationId: UpdateRepositoryName
export def "update-repository-name" [
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
  --x-amz-target: string@x-amz-target-completer-76 # required
  old_name: string # The current name of the repository.
  new_name: string # The new name for the repository.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeCommit_20150413.UpdateRepositoryName"}]
    body: {content_type: "application/json", kind: json, fields: [{name: oldName, var: old_name}, {name: newName, var: new_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, old_name: $old_name, new_name: $new_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
