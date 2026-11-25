# Auto-generated client for Amazon CloudHSM v2014-05-30
# Source: https://api.apis.guru/v2/specs/amazonaws.com/cloudhsm/2014-05-30/openapi.json
# Auth: --token flag or $env.AMAZON_CLOUDHSM_TOKEN

const CLIENT = {
  base_url: "http://cloudhsm.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_CLOUDHSM_TOKEN"
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

def base-url-completer [] { ["http://cloudhsm.us-east-1.amazonaws.com" "http://cloudhsm.us-east-2.amazonaws.com" "http://cloudhsm.us-west-1.amazonaws.com" "http://cloudhsm.us-west-2.amazonaws.com" "http://cloudhsm.us-gov-west-1.amazonaws.com" "http://cloudhsm.us-gov-east-1.amazonaws.com" "http://cloudhsm.ca-central-1.amazonaws.com" "http://cloudhsm.eu-north-1.amazonaws.com" "http://cloudhsm.eu-west-1.amazonaws.com" "http://cloudhsm.eu-west-2.amazonaws.com" "http://cloudhsm.eu-west-3.amazonaws.com" "http://cloudhsm.eu-central-1.amazonaws.com" "http://cloudhsm.eu-south-1.amazonaws.com" "http://cloudhsm.af-south-1.amazonaws.com" "http://cloudhsm.ap-northeast-1.amazonaws.com" "http://cloudhsm.ap-northeast-2.amazonaws.com" "http://cloudhsm.ap-northeast-3.amazonaws.com" "http://cloudhsm.ap-southeast-1.amazonaws.com" "http://cloudhsm.ap-southeast-2.amazonaws.com" "http://cloudhsm.ap-east-1.amazonaws.com" "http://cloudhsm.ap-south-1.amazonaws.com" "http://cloudhsm.sa-east-1.amazonaws.com" "http://cloudhsm.me-south-1.amazonaws.com" "https://cloudhsm.us-east-1.amazonaws.com" "https://cloudhsm.us-east-2.amazonaws.com" "https://cloudhsm.us-west-1.amazonaws.com" "https://cloudhsm.us-west-2.amazonaws.com" "https://cloudhsm.us-gov-west-1.amazonaws.com" "https://cloudhsm.us-gov-east-1.amazonaws.com" "https://cloudhsm.ca-central-1.amazonaws.com" "https://cloudhsm.eu-north-1.amazonaws.com" "https://cloudhsm.eu-west-1.amazonaws.com" "https://cloudhsm.eu-west-2.amazonaws.com" "https://cloudhsm.eu-west-3.amazonaws.com" "https://cloudhsm.eu-central-1.amazonaws.com" "https://cloudhsm.eu-south-1.amazonaws.com" "https://cloudhsm.af-south-1.amazonaws.com" "https://cloudhsm.ap-northeast-1.amazonaws.com" "https://cloudhsm.ap-northeast-2.amazonaws.com" "https://cloudhsm.ap-northeast-3.amazonaws.com" "https://cloudhsm.ap-southeast-1.amazonaws.com" "https://cloudhsm.ap-southeast-2.amazonaws.com" "https://cloudhsm.ap-east-1.amazonaws.com" "https://cloudhsm.ap-south-1.amazonaws.com" "https://cloudhsm.sa-east-1.amazonaws.com" "https://cloudhsm.me-south-1.amazonaws.com" "http://cloudhsm.cn-north-1.amazonaws.com.cn" "http://cloudhsm.cn-northwest-1.amazonaws.com.cn" "https://cloudhsm.cn-north-1.amazonaws.com.cn" "https://cloudhsm.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["CloudHsmFrontendService.AddTagsToResource"] }
def x-amz-target-completer-1 [] { ["CloudHsmFrontendService.CreateHapg"] }
def subscription-type-completer [] { ["PRODUCTION"] }
def x-amz-target-completer-2 [] { ["CloudHsmFrontendService.CreateHsm"] }
def x-amz-target-completer-3 [] { ["CloudHsmFrontendService.CreateLunaClient"] }
def x-amz-target-completer-4 [] { ["CloudHsmFrontendService.DeleteHapg"] }
def x-amz-target-completer-5 [] { ["CloudHsmFrontendService.DeleteHsm"] }
def x-amz-target-completer-6 [] { ["CloudHsmFrontendService.DeleteLunaClient"] }
def x-amz-target-completer-7 [] { ["CloudHsmFrontendService.DescribeHapg"] }
def x-amz-target-completer-8 [] { ["CloudHsmFrontendService.DescribeHsm"] }
def x-amz-target-completer-9 [] { ["CloudHsmFrontendService.DescribeLunaClient"] }
def client-version-completer [] { ["5.1" "5.3"] }
def x-amz-target-completer-10 [] { ["CloudHsmFrontendService.GetConfig"] }
def x-amz-target-completer-11 [] { ["CloudHsmFrontendService.ListAvailableZones"] }
def x-amz-target-completer-12 [] { ["CloudHsmFrontendService.ListHapgs"] }
def x-amz-target-completer-13 [] { ["CloudHsmFrontendService.ListHsms"] }
def x-amz-target-completer-14 [] { ["CloudHsmFrontendService.ListLunaClients"] }
def x-amz-target-completer-15 [] { ["CloudHsmFrontendService.ListTagsForResource"] }
def x-amz-target-completer-16 [] { ["CloudHsmFrontendService.ModifyHapg"] }
def x-amz-target-completer-17 [] { ["CloudHsmFrontendService.ModifyHsm"] }
def x-amz-target-completer-18 [] { ["CloudHsmFrontendService.ModifyLunaClient"] }
def x-amz-target-completer-19 [] { ["CloudHsmFrontendService.RemoveTagsFromResource"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    add-tags-to-resource: "record<Status: string>"
    create-hapg: "record<HapgArn: string>"
    create-hsm: "record<HsmArn: string>"
    create-luna-client: "record<ClientArn: string>"
    delete-hapg: "record<Status: string>"
    delete-hsm: "record<Status: string>"
    delete-luna-client: "record<Status: string>"
    describe-hapg: "record<HapgArn: string, HapgSerial: string, HsmsLastActionFailed: list<string>, HsmsPendingDeletion: list<string>, HsmsPendingRegistration: list<string>, Label: string, LastModifiedTimestamp: string, PartitionSerialList: list<string>, State: string>"
    describe-hsm: "record<HsmArn: string, Status: string, StatusDetails: string, AvailabilityZone: string, EniId: string, EniIp: string, SubscriptionType: string, SubscriptionStartDate: string, SubscriptionEndDate: string, VpcId: string, SubnetId: string, IamRoleArn: string, SerialNumber: string, VendorName: string, HsmType: string, SoftwareVersion: string, SshPublicKey: string, SshKeyLastUpdated: string, ServerCertUri: string, ServerCertLastUpdated: string, Partitions: list<string>>"
    describe-luna-client: "record<ClientArn: string, Certificate: string, CertificateFingerprint: string, LastModifiedTimestamp: string, Label: string>"
    get-config: "record<ConfigType: string, ConfigFile: string, ConfigCred: string>"
    list-available-zones: "record<AZList: list<string>>"
    list-hapgs: "record<HapgList: list<string>, NextToken: string>"
    list-hsms: "record<HsmList: list<string>, NextToken: string>"
    list-luna-clients: "record<ClientList: list<string>, NextToken: string>"
    list-tags-for-resource: "record<TagList: table<Key: string, Value: string>>"
    modify-hapg: "record<HapgArn: string>"
    modify-hsm: "record<HsmArn: string>"
    modify-luna-client: "record<ClientArn: string>"
    remove-tags-from-resource: "record<Status: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["add-tags-to-resource" "create-hapg" "create-hsm" "create-luna-client" "delete-hapg" "delete-hsm" "delete-luna-client" "describe-hapg" "describe-hsm" "describe-luna-client" "get-config" "list-available-zones" "list-hapgs" "list-hsms" "list-luna-clients" "list-tags-for-resource" "modify-hapg" "modify-hsm" "modify-luna-client" "remove-tags-from-resource" "commands"] | sort) } | get name | first)
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

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Adds or overwrites one or more tags for the specified AWS CloudHSM resource. Each tag consists of a key and a value. Tag keys must be unique to each resource.
#
# POST /
# Returns: record<Status: string>
# operationId: AddTagsToResource
export def "add-tags-to-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_arn: string # The Amazon Resource Name (ARN) of the AWS CloudHSM resource to tag.
  tag_list: list # One or more tags. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.AddTagsToResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: TagList, var: tag_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_list: $tag_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Creates a high-availability partition group. A high-availability partition group is a group of partitions that spans multiple physical HSMs.
#
# POST /
# Returns: record<HapgArn: string>
# operationId: CreateHapg
export def "create-hapg" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  label: string # The label of the new high-availability partition group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.CreateHapg"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Label, var: label}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Creates an uninitialized HSM instance. There is an upfront fee charged for each HSM instance that you create with the CreateHsm operation. If you accidentally provision an HSM and want to request a refund, delete the instance using the DeleteHsm operation, go to the AWS Support Center (https://console.aws.amazon.com/support/home), create a new case, and select Account and Billing Support. It can take up to 20 minutes to create and provision an HSM. You can monitor the status of the HSM with the DescribeHsm operation. The HSM is ready to be initialized when the status changes to RUNNING.
#
# POST /
# Returns: record<HsmArn: string>
# operationId: CreateHsm
export def "create-hsm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  subnet_id: string # The identifier of the subnet in your VPC in which to place the HSM.
  ssh_key: string # The SSH public key to install on the HSM.
  --eni-ip: string # The IP address to assign to the HSM's ENI. If an IP address is not specified, an IP address will be randomly chosen from the CIDR range of the subnet.
  iam_role_arn: string # The ARN of an IAM role to enable the AWS CloudHSM service to allocate an ENI on your behalf.
  --external-id: string # The external ID from IamRoleArn, if present.
  subscription_type: string@subscription-type-completer # Specifies the type of subscription for the HSM. PRODUCTION - The HSM is being used in a production environment. TRIAL - The HSM is being used in a product trial.
  --client-token: string # A user-defined token to ensure idempotence. Subsequent calls to this operation with the same token will be ignored.
  --syslog-ip: string # The IP address for the syslog monitoring server. The AWS CloudHSM service only supports one syslog monitoring server.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.CreateHsm"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SubnetId, var: subnet_id}, {name: SshKey, var: ssh_key}, {name: EniIp, var: eni_ip}, {name: IamRoleArn, var: iam_role_arn}, {name: ExternalId, var: external_id}, {name: SubscriptionType, var: subscription_type}, {name: ClientToken, var: client_token}, {name: SyslogIp, var: syslog_ip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subnet_id: $subnet_id, ssh_key: $ssh_key, eni_ip: $eni_ip, iam_role_arn: $iam_role_arn, external_id: $external_id, subscription_type: $subscription_type, client_token: $client_token, syslog_ip: $syslog_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Creates an HSM client.
#
# POST /
# Returns: record<ClientArn: string>
# operationId: CreateLunaClient
export def "create-luna-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --label: string # The label for the client.
  certificate: string # The contents of a Base64-Encoded X.509 v3 certificate to be installed on the HSMs used by this client.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.CreateLunaClient"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Label, var: label}, {name: Certificate, var: certificate}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, label: $label, certificate: $certificate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Deletes a high-availability partition group.
#
# POST /
# Returns: record<Status: string>
# operationId: DeleteHapg
export def "delete-hapg" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  hapg_arn: string # The ARN of the high-availability partition group to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.DeleteHapg"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HapgArn, var: hapg_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hapg_arn: $hapg_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Deletes an HSM. After completion, this operation cannot be undone and your key material cannot be recovered.
#
# POST /
# Returns: record<Status: string>
# operationId: DeleteHsm
export def "delete-hsm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  hsm_arn: string # An ARN that identifies an HSM.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.DeleteHsm"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HsmArn, var: hsm_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hsm_arn: $hsm_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Deletes a client.
#
# POST /
# Returns: record<Status: string>
# operationId: DeleteLunaClient
export def "delete-luna-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  client_arn: string # The ARN of the client to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.DeleteLunaClient"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientArn, var: client_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_arn: $client_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Retrieves information about a high-availability partition group.
#
# POST /
# Returns: record<HapgArn: string, HapgSerial: string, HsmsLastActionFailed: list<string>, HsmsPendingDeletion: list<string>, HsmsPendingRegistration: list<string>, Label: string, LastModifiedTimestamp: string, PartitionSerialList: list<string>, State: string>
# operationId: DescribeHapg
export def "describe-hapg" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  hapg_arn: string # The ARN of the high-availability partition group to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.DescribeHapg"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HapgArn, var: hapg_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hapg_arn: $hapg_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Retrieves information about an HSM. You can identify the HSM by its ARN or its serial number.
#
# POST /
# Returns: record<HsmArn: string, Status: string, StatusDetails: string, AvailabilityZone: string, EniId: string, EniIp: string, SubscriptionType: string, SubscriptionStartDate: string, SubscriptionEndDate: string, VpcId: string, SubnetId: string, IamRoleArn: string, SerialNumber: string, VendorName: string, HsmType: string, SoftwareVersion: string, SshPublicKey: string, SshKeyLastUpdated: string, ServerCertUri: string, ServerCertLastUpdated: string, Partitions: list<string>>
# operationId: DescribeHsm
export def "describe-hsm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --hsm-arn: string # An ARN that identifies an HSM.
  --hsm-serial-number: string # The serial number of the HSM. Either the HsmArn or the HsmSerialNumber parameter must be specified.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.DescribeHsm"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HsmArn, var: hsm_arn}, {name: HsmSerialNumber, var: hsm_serial_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hsm_arn: $hsm_arn, hsm_serial_number: $hsm_serial_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Retrieves information about an HSM client.
#
# POST /
# Returns: record<ClientArn: string, Certificate: string, CertificateFingerprint: string, LastModifiedTimestamp: string, Label: string>
# operationId: DescribeLunaClient
export def "describe-luna-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --client-arn: string # The ARN of the client.
  --certificate-fingerprint: string # The certificate fingerprint.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.DescribeLunaClient"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientArn, var: client_arn}, {name: CertificateFingerprint, var: certificate_fingerprint}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_arn: $client_arn, certificate_fingerprint: $certificate_fingerprint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Gets the configuration files necessary to connect to all high availability partition groups the client is associated with.
#
# POST /
# Returns: record<ConfigType: string, ConfigFile: string, ConfigCred: string>
# operationId: GetConfig
export def "get-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  client_arn: string # The ARN of the client.
  client_version: string@client-version-completer # The client version.
  hapg_list: list<string> # A list of ARNs that identify the high-availability partition groups that are associated with the client.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.GetConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientArn, var: client_arn}, {name: ClientVersion, var: client_version}, {name: HapgList, var: hapg_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_arn: $client_arn, client_version: $client_version, hapg_list: $hapg_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Lists the Availability Zones that have available AWS CloudHSM capacity.
#
# POST /
# Returns: record<AZList: list<string>>
# operationId: ListAvailableZones
export def "list-available-zones" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.ListAvailableZones"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Lists the high-availability partition groups for the account. This operation supports pagination with the use of the NextToken member. If more results are available, the NextToken member of the response contains a token that you pass in the next call to ListHapgs to retrieve the next set of items.
#
# POST /
# Returns: record<HapgList: list<string>, NextToken: string>
# operationId: ListHapgs
export def "list-hapgs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --next-token: string # The NextToken value from a previous call to ListHapgs. Pass null if this is the first call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.ListHapgs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Retrieves the identifiers of all of the HSMs provisioned for the current customer. This operation supports pagination with the use of the NextToken member. If more results are available, the NextToken member of the response contains a token that you pass in the next call to ListHsms to retrieve the next set of items.
#
# POST /
# Returns: record<HsmList: list<string>, NextToken: string>
# operationId: ListHsms
export def "list-hsms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --next-token: string # The NextToken value from a previous call to ListHsms. Pass null if this is the first call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.ListHsms"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Lists all of the clients. This operation supports pagination with the use of the NextToken member. If more results are available, the NextToken member of the response contains a token that you pass in the next call to ListLunaClients to retrieve the next set of items.
#
# POST /
# Returns: record<ClientList: list<string>, NextToken: string>
# operationId: ListLunaClients
export def "list-luna-clients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --next-token: string # The NextToken value from a previous call to ListLunaClients. Pass null if this is the first call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.ListLunaClients"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Returns a list of all tags for the specified AWS CloudHSM resource.
#
# POST /
# Returns: record<TagList: table<Key: string, Value: string>>
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the AWS CloudHSM resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Modifies an existing high-availability partition group.
#
# POST /
# Returns: record<HapgArn: string>
# operationId: ModifyHapg
export def "modify-hapg" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  hapg_arn: string # The ARN of the high-availability partition group to modify.
  --label: string # The new label for the high-availability partition group.
  --partition-serial-list: list<string> # The list of partition serial numbers to make members of the high-availability partition group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.ModifyHapg"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HapgArn, var: hapg_arn}, {name: Label, var: label}, {name: PartitionSerialList, var: partition_serial_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hapg_arn: $hapg_arn, label: $label, partition_serial_list: $partition_serial_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Modifies an HSM. This operation can result in the HSM being offline for up to 15 minutes while the AWS CloudHSM service is reconfigured. If you are modifying a production HSM, you should ensure that your AWS CloudHSM service is configured for high availability, and consider executing this operation during a maintenance window.
#
# POST /
# Returns: record<HsmArn: string>
# operationId: ModifyHsm
export def "modify-hsm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  hsm_arn: string # An ARN that identifies an HSM.
  --subnet-id: string # The new identifier of the subnet that the HSM is in. The new subnet must be in the same Availability Zone as the current subnet.
  --eni-ip: string # The new IP address for the elastic network interface (ENI) attached to the HSM. If the HSM is moved to a different subnet, and an IP address is not specified, an IP address will be randomly chosen from the CIDR range of the new subnet.
  --iam-role-arn: string # The new IAM role ARN.
  --external-id: string # The new external ID.
  --syslog-ip: string # The new IP address for the syslog monitoring server. The AWS CloudHSM service only supports one syslog monitoring server.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.ModifyHsm"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HsmArn, var: hsm_arn}, {name: SubnetId, var: subnet_id}, {name: EniIp, var: eni_ip}, {name: IamRoleArn, var: iam_role_arn}, {name: ExternalId, var: external_id}, {name: SyslogIp, var: syslog_ip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hsm_arn: $hsm_arn, subnet_id: $subnet_id, eni_ip: $eni_ip, iam_role_arn: $iam_role_arn, external_id: $external_id, syslog_ip: $syslog_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Modifies the certificate used by the client. This action can potentially start a workflow to install the new certificate on the client's HSMs.
#
# POST /
# Returns: record<ClientArn: string>
# operationId: ModifyLunaClient
export def "modify-luna-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  client_arn: string # The ARN of the client.
  certificate: string # The new certificate for the client.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.ModifyLunaClient"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientArn, var: client_arn}, {name: Certificate, var: certificate}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_arn: $client_arn, certificate: $certificate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Removes one or more tags from the specified AWS CloudHSM resource. To remove a tag, specify only the tag key to remove (not the value). To overwrite the value for an existing tag, use AddTagsToResource.
#
# POST /
# Returns: record<Status: string>
# operationId: RemoveTagsFromResource
export def "remove-tags-from-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_arn: string # The Amazon Resource Name (ARN) of the AWS CloudHSM resource.
  tag_key_list: list<string> # The tag key or keys to remove. Specify only the tag key to remove (not the value). To overwrite the value for an existing tag, use AddTagsToResource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CloudHsmFrontendService.RemoveTagsFromResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: TagKeyList, var: tag_key_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_key_list: $tag_key_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
